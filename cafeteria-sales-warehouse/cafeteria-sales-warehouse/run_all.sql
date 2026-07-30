\set ON_ERROR_STOP on

\echo 'Resetting the project schemas...'
\ir sql/00_reset_project.sql

\echo 'Creating schemas and operational tables...'
\ir sql/01_create_schemas.sql
\ir sql/02_create_oltp_tables.sql

\echo 'Generating deterministic operational data...'
\ir sql/03_insert_sample_data.sql

\echo 'Creating and loading the warehouse...'
\ir sql/04_create_dw_tables.sql
\ir sql/05_load_dimensions.sql
\ir sql/06_load_fact_table.sql

\echo 'Running portfolio queries...'
\ir sql/07_analysis_queries.sql
\ir sql/08_data_quality_checks.sql
\ir sql/09_compare_oltp_and_olap.sql

\echo 'Build complete.'
