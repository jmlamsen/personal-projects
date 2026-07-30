BEGIN;

CREATE SCHEMA oltp;
CREATE SCHEMA dw;

COMMENT ON SCHEMA oltp IS
    'Normalized operational tables used to record cafeteria checkouts.';

COMMENT ON SCHEMA dw IS
    'Dimensional warehouse used to analyze completed cafeteria sales.';

COMMIT;
