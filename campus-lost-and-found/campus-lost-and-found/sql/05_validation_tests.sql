/*
    Campus Lost-and-Found Database
    File: 05_validation_tests.sql

    Run after 01_schema.sql and 02_sample_data.sql.
    Successful tests print PostgreSQL NOTICE messages beginning with "PASS".
    The transaction is rolled back, so the sample database is unchanged.
*/

BEGIN;

-- Test 1: Invalid report types must fail.
INSERT INTO items (
    item_id,
    category_id,
    item_name,
    primary_color
)
VALUES (9001, 1, 'Constraint test item 1', 'Black');

DO $test$
BEGIN
    BEGIN
        INSERT INTO reports (
            item_id,
            location_id,
            report_type,
            incident_date,
            reported_at
        )
        VALUES (
            9001,
            1,
            'OTHER',
            DATE '2026-07-20',
            TIMESTAMPTZ '2026-07-20 10:00:00+08'
        );

        RAISE EXCEPTION 'FAIL: invalid report type was accepted';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: invalid report type was rejected';
    END;
END
$test$;


-- Test 2: Reports cannot reference a nonexistent location.
INSERT INTO items (
    item_id,
    category_id,
    item_name,
    primary_color
)
VALUES (9002, 1, 'Constraint test item 2', 'Black');

DO $test$
BEGIN
    BEGIN
        INSERT INTO reports (
            item_id,
            location_id,
            report_type,
            incident_date,
            reported_at
        )
        VALUES (
            9002,
            999999,
            'LOST',
            DATE '2026-07-20',
            TIMESTAMPTZ '2026-07-20 10:00:00+08'
        );

        RAISE EXCEPTION 'FAIL: nonexistent location was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: nonexistent location was rejected';
    END;
END
$test$;


-- Test 3: Institutional IDs must be unique.
DO $test$
BEGIN
    BEGIN
        INSERT INTO claimants (
            claimant_name,
            institutional_id,
            contact_email
        )
        VALUES (
            'Duplicate ID Test',
            '2026-0001',
            'duplicate.id@example.edu'
        );

        RAISE EXCEPTION 'FAIL: duplicate institutional ID was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASS: duplicate institutional ID was rejected';
    END;
END
$test$;


-- Test 4: One person cannot claim the same report twice.
DO $test$
BEGIN
    BEGIN
        INSERT INTO claims (
            found_report_id,
            claimant_id,
            filed_at,
            claim_status
        )
        VALUES (
            9,
            2,
            TIMESTAMPTZ '2026-07-04 09:00:00+08',
            'PENDING'
        );

        RAISE EXCEPTION 'FAIL: duplicate person-report claim was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASS: duplicate person-report claim was rejected';
    END;
END
$test$;


-- Test 5: A found report cannot have two approved claims.
DO $test$
BEGIN
    BEGIN
        INSERT INTO claims (
            found_report_id,
            claimant_id,
            filed_at,
            claim_status,
            decided_at
        )
        VALUES (
            8,
            2,
            TIMESTAMPTZ '2026-07-02 09:00:00+08',
            'APPROVED',
            TIMESTAMPTZ '2026-07-02 10:00:00+08'
        );

        RAISE EXCEPTION 'FAIL: second approved claim was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASS: second approved claim was rejected';
    END;
END
$test$;


-- Test 6: Claims cannot point to LOST reports.
DO $test$
BEGIN
    BEGIN
        INSERT INTO claims (
            found_report_id,
            claimant_id,
            filed_at,
            claim_status
        )
        VALUES (
            2,
            4,
            TIMESTAMPTZ '2026-07-04 09:00:00+08',
            'PENDING'
        );

        RAISE EXCEPTION 'FAIL: a claim against a LOST report was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'PASS: a claim against a LOST report was rejected';
    END;
END
$test$;


-- Test 7: Approved claims require a decision timestamp.
DO $test$
BEGIN
    BEGIN
        INSERT INTO claims (
            found_report_id,
            claimant_id,
            filed_at,
            claim_status,
            decided_at
        )
        VALUES (
            11,
            5,
            TIMESTAMPTZ '2026-07-07 09:00:00+08',
            'APPROVED',
            NULL
        );

        RAISE EXCEPTION 'FAIL: approval without a decision time was accepted';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: approval without a decision time was rejected';
    END;
END
$test$;


-- Test 8: Pending and rejected claims must remain unclaimed.
DO $test$
DECLARE
    unclaimed_test_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO unclaimed_test_count
    FROM reports AS r
    WHERE r.report_id IN (9, 10, 12, 16)
      AND NOT EXISTS (
          SELECT 1
          FROM claims AS cl
          WHERE cl.found_report_id = r.report_id
            AND cl.claim_status = 'APPROVED'
      );

    IF unclaimed_test_count <> 4 THEN
        RAISE EXCEPTION
            'FAIL: expected 4 pending/rejected reports to remain unclaimed, found %',
            unclaimed_test_count;
    END IF;

    RAISE NOTICE
        'PASS: pending and rejected claims remain unclaimed';
END
$test$;


-- Test 9: The highest LOST-report count must have two tied locations.
DO $test$
DECLARE
    tied_location_count INTEGER;
BEGIN
    WITH lost_counts AS (
        SELECT
            l.location_id,
            COUNT(r.report_id) AS lost_item_count
        FROM campus_locations AS l
        LEFT JOIN reports AS r
            ON r.location_id = l.location_id
           AND r.report_type = 'LOST'
        GROUP BY l.location_id
    )
    SELECT COUNT(*)
    INTO tied_location_count
    FROM lost_counts
    WHERE lost_item_count = (
        SELECT MAX(lost_item_count)
        FROM lost_counts
    );

    IF tied_location_count <> 2 THEN
        RAISE EXCEPTION
            'FAIL: expected 2 locations tied for most LOST reports, found %',
            tied_location_count;
    END IF;

    RAISE NOTICE
        'PASS: both locations tied for most LOST reports are retained';
END
$test$;


-- Test 10: The sample data must produce exactly five candidate matches.
DO $test$
DECLARE
    candidate_match_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO candidate_match_count
    FROM reports AS lr
    JOIN items AS li
        ON li.item_id = lr.item_id
    JOIN items AS fi
        ON fi.category_id = li.category_id
       AND LOWER(BTRIM(fi.primary_color)) =
           LOWER(BTRIM(li.primary_color))
    JOIN reports AS fr
        ON fr.item_id = fi.item_id
       AND fr.report_type = 'FOUND'
       AND fr.report_status IN ('OPEN', 'MATCHED')
       AND fr.incident_date BETWEEN
           lr.incident_date AND lr.incident_date + 30
    WHERE lr.report_type = 'LOST'
      AND lr.report_status IN ('OPEN', 'MATCHED');

    IF candidate_match_count <> 5 THEN
        RAISE EXCEPTION
            'FAIL: expected 5 candidate matches, found %',
            candidate_match_count;
    END IF;

    RAISE NOTICE
        'PASS: sample data produces exactly 5 candidate matches';
END
$test$;

ROLLBACK;

