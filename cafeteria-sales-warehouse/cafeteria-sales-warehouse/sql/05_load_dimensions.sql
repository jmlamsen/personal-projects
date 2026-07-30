BEGIN;

INSERT INTO dw.dim_category (
    source_category_id,
    category_name,
    description,
    is_active
)
SELECT
    category_id,
    category_name,
    description,
    is_active
FROM oltp.categories
ON CONFLICT (source_category_id)
DO UPDATE SET
    category_name = EXCLUDED.category_name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;

INSERT INTO dw.dim_product (
    source_product_id,
    category_key,
    product_name,
    current_price,
    is_available
)
SELECT
    product.product_id,
    category_dimension.category_key,
    product.product_name,
    product.current_price,
    product.is_available
FROM oltp.products AS product
JOIN dw.dim_category AS category_dimension
    ON category_dimension.source_category_id = product.category_id
ON CONFLICT (source_product_id)
DO UPDATE SET
    category_key = EXCLUDED.category_key,
    product_name = EXCLUDED.product_name,
    current_price = EXCLUDED.current_price,
    is_available = EXCLUDED.is_available;

INSERT INTO dw.dim_payment_method (
    source_payment_method_id,
    payment_method_name,
    payment_group
)
SELECT
    payment_method_id,
    payment_method_name,
    payment_group
FROM oltp.payment_methods
ON CONFLICT (source_payment_method_id)
DO UPDATE SET
    payment_method_name = EXCLUDED.payment_method_name,
    payment_group = EXCLUDED.payment_group;

WITH generated_dates AS (
    SELECT
        day_value::DATE AS full_date
    FROM generate_series(
        DATE '2026-01-01',
        DATE '2026-12-31',
        INTERVAL '1 day'
    ) AS date_series (day_value)
)
INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day_of_month,
    day_of_week_number,
    day_name,
    week_of_year,
    month_number,
    month_name,
    quarter_number,
    year_number,
    is_weekend
)
SELECT
    to_char(full_date, 'YYYYMMDD')::INTEGER,
    full_date,
    EXTRACT(DAY FROM full_date)::SMALLINT,
    EXTRACT(ISODOW FROM full_date)::SMALLINT,
    to_char(full_date, 'FMDay'),
    EXTRACT(WEEK FROM full_date)::SMALLINT,
    EXTRACT(MONTH FROM full_date)::SMALLINT,
    to_char(full_date, 'FMMonth'),
    EXTRACT(QUARTER FROM full_date)::SMALLINT,
    EXTRACT(YEAR FROM full_date)::SMALLINT,
    EXTRACT(ISODOW FROM full_date) IN (6, 7)
FROM generated_dates
ON CONFLICT (full_date)
DO UPDATE SET
    day_of_month = EXCLUDED.day_of_month,
    day_of_week_number = EXCLUDED.day_of_week_number,
    day_name = EXCLUDED.day_name,
    week_of_year = EXCLUDED.week_of_year,
    month_number = EXCLUDED.month_number,
    month_name = EXCLUDED.month_name,
    quarter_number = EXCLUDED.quarter_number,
    year_number = EXCLUDED.year_number,
    is_weekend = EXCLUDED.is_weekend;

COMMIT;
