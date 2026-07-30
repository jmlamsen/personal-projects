-- CAUTION:
-- This script removes only the two schemas owned by this project.
-- Run it when you want a completely clean rebuild.

BEGIN;

DROP SCHEMA IF EXISTS dw CASCADE;
DROP SCHEMA IF EXISTS oltp CASCADE;

COMMIT;
