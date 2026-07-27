/*
    Campus Lost-and-Found Database
    File: 03_analysis_queries.sql

    These queries intentionally exclude private verification details.
*/

-- ---------------------------------------------------------------------------
-- Query 1: List found items that do not have an approved claim.
-- Pending and rejected claims do not remove an item from this list.
-- ---------------------------------------------------------------------------
SELECT
    r.report_id,
    i.item_name,
    c.category_name,
    i.primary_color,
    l.location_name,
    r.incident_date,
    r.report_status
FROM reports AS r
JOIN items AS i
    ON i.item_id = r.item_id
JOIN item_categories AS c
    ON c.category_id = i.category_id
JOIN campus_locations AS l
    ON l.location_id = r.location_id
WHERE r.report_type = 'FOUND'
  AND r.report_status IN ('OPEN', 'MATCHED')
  AND NOT EXISTS (
      SELECT 1
      FROM claims AS cl
      WHERE cl.found_report_id = r.report_id
        AND cl.claim_status = 'APPROVED'
  )
ORDER BY r.incident_date, r.report_id;


-- ---------------------------------------------------------------------------
-- Query 2: Count all, lost, and found reports at every campus location.
-- LEFT JOIN keeps locations that currently have zero reports.
-- ---------------------------------------------------------------------------
SELECT
    l.location_name,
    COUNT(r.report_id) AS total_reports,
    COUNT(r.report_id) FILTER (
        WHERE r.report_type = 'LOST'
    ) AS lost_reports,
    COUNT(r.report_id) FILTER (
        WHERE r.report_type = 'FOUND'
    ) AS found_reports
FROM campus_locations AS l
LEFT JOIN reports AS r
    ON r.location_id = l.location_id
GROUP BY l.location_id, l.location_name
ORDER BY total_reports DESC, l.location_name;


-- ---------------------------------------------------------------------------
-- Query 3: Return every location tied for the most LOST reports.
-- DENSE_RANK avoids hiding a tied first-place location.
-- ---------------------------------------------------------------------------
WITH lost_counts AS (
    SELECT
        l.location_id,
        l.location_name,
        COUNT(r.report_id) AS lost_item_count
    FROM campus_locations AS l
    LEFT JOIN reports AS r
        ON r.location_id = l.location_id
       AND r.report_type = 'LOST'
    GROUP BY l.location_id, l.location_name
),
ranked_locations AS (
    SELECT
        location_name,
        lost_item_count,
        DENSE_RANK() OVER (
            ORDER BY lost_item_count DESC
        ) AS location_rank
    FROM lost_counts
)
SELECT
    location_name,
    lost_item_count
FROM ranked_locations
WHERE location_rank = 1
ORDER BY location_name;


-- ---------------------------------------------------------------------------
-- Query 4: Generate candidate matches using:
--   1. the same category,
--   2. the same normalized color, and
--   3. a FOUND date from zero to 30 days after the LOST date.
--
-- A row from this query is not proof that the records describe the same item.
-- ---------------------------------------------------------------------------
SELECT
    lr.report_id AS lost_report_id,
    fr.report_id AS found_report_id,
    li.item_name AS lost_item,
    fi.item_name AS found_item,
    c.category_name,
    li.primary_color,
    lr.incident_date AS lost_date,
    fr.incident_date AS found_date,
    COALESCE(
        LOWER(BTRIM(li.brand)) = LOWER(BTRIM(fi.brand)),
        FALSE
    ) AS same_brand
FROM reports AS lr
JOIN items AS li
    ON li.item_id = lr.item_id
JOIN item_categories AS c
    ON c.category_id = li.category_id
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
  AND lr.report_status IN ('OPEN', 'MATCHED')
ORDER BY lr.report_id, fr.report_id;


-- ---------------------------------------------------------------------------
-- Query 5: Calculate how long each FOUND item remained unclaimed.
-- For an approved claim, counting stops on the approval date.
-- Otherwise, counting continues through the date on which the query is run.
-- ---------------------------------------------------------------------------
WITH approved_claims AS (
    SELECT
        found_report_id,
        decided_at
    FROM claims
    WHERE claim_status = 'APPROVED'
)
SELECT
    r.report_id,
    i.item_name,
    r.incident_date,
    CASE
        WHEN ac.found_report_id IS NULL THEN 'UNCLAIMED'
        ELSE 'CLAIMED'
    END AS ownership_status,
    CASE
        WHEN ac.found_report_id IS NULL
            THEN CURRENT_DATE - r.incident_date
        ELSE ac.decided_at::DATE - r.incident_date
    END AS days_unclaimed
FROM reports AS r
JOIN items AS i
    ON i.item_id = r.item_id
LEFT JOIN approved_claims AS ac
    ON ac.found_report_id = r.report_id
WHERE r.report_type = 'FOUND'
ORDER BY days_unclaimed DESC, r.report_id;


-- ---------------------------------------------------------------------------
-- Query 6: Summarize the number of claims in each status.
-- The status list makes zero-count statuses visible.
-- ---------------------------------------------------------------------------
WITH claim_statuses (claim_status, display_order) AS (
    VALUES
        ('PENDING', 1),
        ('APPROVED', 2),
        ('REJECTED', 3),
        ('CANCELLED', 4)
)
SELECT
    cs.claim_status,
    COUNT(cl.claim_id) AS claim_count
FROM claim_statuses AS cs
LEFT JOIN claims AS cl
    ON cl.claim_status = cs.claim_status
GROUP BY cs.claim_status, cs.display_order
ORDER BY cs.display_order;


-- ---------------------------------------------------------------------------
-- Query 7: Show approved claims and completed returns.
-- Private verification notes are deliberately omitted.
-- ---------------------------------------------------------------------------
SELECT
    cl.claim_id,
    r.report_id AS found_report_id,
    i.item_name,
    ct.claimant_name,
    cl.decided_at::DATE AS approved_date,
    cl.returned_at::DATE AS returned_date
FROM claims AS cl
JOIN reports AS r
    ON r.report_id = cl.found_report_id
JOIN items AS i
    ON i.item_id = r.item_id
JOIN claimants AS ct
    ON ct.claimant_id = cl.claimant_id
WHERE cl.claim_status = 'APPROVED'
ORDER BY cl.decided_at, cl.claim_id;

