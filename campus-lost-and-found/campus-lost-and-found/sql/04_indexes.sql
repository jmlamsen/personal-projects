/*
    Campus Lost-and-Found Database
    File: 04_indexes.sql

    The dataset is intentionally small, so these indexes are included to
    demonstrate access-path design rather than to produce a visible speedup.
*/

-- Helps queries that filter reports by type and workflow status.
CREATE INDEX IF NOT EXISTS idx_reports_type_status
    ON reports (report_type, report_status);

-- Helps location summaries that separate LOST and FOUND reports.
CREATE INDEX IF NOT EXISTS idx_reports_location_type
    ON reports (location_id, report_type);

-- Helps date-window filtering in the candidate-match query.
CREATE INDEX IF NOT EXISTS idx_reports_incident_date
    ON reports (incident_date);

-- Matches the normalized category-and-color expressions used by Query 4.
CREATE INDEX IF NOT EXISTS idx_items_category_normalized_color
    ON items (
        category_id,
        LOWER(BTRIM(primary_color))
    );

-- Helps claim lookups by report and status.
CREATE INDEX IF NOT EXISTS idx_claims_report_status
    ON claims (found_report_id, claim_status);

