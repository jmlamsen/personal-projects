WITH completed_lines AS (
    SELECT
        item.transaction_item_id,
        item.product_id,
        transaction.payment_method_id,
        (transaction.sold_at AT TIME ZONE 'Asia/Manila')::DATE AS sale_date,
        item.quantity,
        item.unit_price,
        item.discount_amount
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'COMPLETED'
),
source_totals AS (
    SELECT
        COUNT(*) AS row_count,
        COALESCE(
            SUM(quantity * unit_price - discount_amount),
            0
        )::NUMERIC(14, 2) AS net_revenue
    FROM completed_lines
),
warehouse_totals AS (
    SELECT
        COUNT(*) AS row_count,
        COALESCE(SUM(net_sales_amount), 0)::NUMERIC(14, 2)
            AS net_revenue
    FROM dw.fact_cafeteria_sales
),
duplicate_facts AS (
    SELECT
        COUNT(*) - COUNT(DISTINCT source_transaction_item_id)
            AS duplicate_count
    FROM dw.fact_cafeteria_sales
),
missing_dimensions AS (
    SELECT COUNT(*) AS missing_count
    FROM completed_lines AS line
    LEFT JOIN dw.dim_product AS product
        ON product.source_product_id = line.product_id
    LEFT JOIN dw.dim_payment_method AS payment
        ON payment.source_payment_method_id = line.payment_method_id
    LEFT JOIN dw.dim_date AS date_dimension
        ON date_dimension.full_date = line.sale_date
    WHERE
        product.product_key IS NULL
        OR payment.payment_method_key IS NULL
        OR date_dimension.date_key IS NULL
),
invalid_facts AS (
    SELECT COUNT(*) AS invalid_count
    FROM dw.fact_cafeteria_sales
    WHERE
        quantity <= 0
        OR unit_price < 0
        OR discount_amount < 0
        OR discount_amount > gross_sales_amount
        OR gross_sales_amount <> quantity * unit_price
        OR net_sales_amount <> gross_sales_amount - discount_amount
        OR net_sales_amount < 0
),
cancelled_facts AS (
    SELECT COUNT(*) AS cancelled_fact_count
    FROM dw.fact_cafeteria_sales AS fact
    JOIN oltp.transaction_items AS item
        ON item.transaction_item_id = fact.source_transaction_item_id
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'CANCELLED'
),
fixed_sample_totals AS (
    SELECT
        (SELECT COUNT(*) FROM oltp.transactions) AS transaction_count,
        (SELECT COUNT(*) FROM oltp.transaction_items) AS item_count,
        (
            SELECT COUNT(*)
            FROM oltp.transactions
            WHERE transaction_status = 'CANCELLED'
        ) AS cancelled_transaction_count,
        (
            SELECT COUNT(*)
            FROM dw.dim_date
            WHERE year_number = 2026
        ) AS calendar_date_count
),
checks AS (
    SELECT
        1 AS check_order,
        'Completed row reconciliation' AS check_name,
        CASE
            WHEN source.row_count = warehouse.row_count
            THEN 'PASS'
            ELSE 'FAIL'
        END AS status,
        warehouse.row_count::TEXT AS actual_value,
        source.row_count::TEXT AS expected_value,
        'Each completed OLTP line should appear once in the fact table.'
            AS details
    FROM source_totals AS source
    CROSS JOIN warehouse_totals AS warehouse

    UNION ALL

    SELECT
        2,
        'Net revenue reconciliation',
        CASE
            WHEN source.net_revenue = warehouse.net_revenue
            THEN 'PASS'
            ELSE 'FAIL'
        END,
        warehouse.net_revenue::TEXT,
        source.net_revenue::TEXT,
        'OLTP and warehouse net revenue should match exactly.'
    FROM source_totals AS source
    CROSS JOIN warehouse_totals AS warehouse

    UNION ALL

    SELECT
        3,
        'Duplicate source lines',
        CASE WHEN duplicate_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        duplicate_count::TEXT,
        '0',
        'A source transaction item must not be loaded more than once.'
    FROM duplicate_facts

    UNION ALL

    SELECT
        4,
        'Missing dimension lookups',
        CASE WHEN missing_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        missing_count::TEXT,
        '0',
        'Every completed line needs date, product, and payment dimensions.'
    FROM missing_dimensions

    UNION ALL

    SELECT
        5,
        'Invalid fact measures',
        CASE WHEN invalid_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        invalid_count::TEXT,
        '0',
        'Quantities and monetary measures must obey the fact rules.'
    FROM invalid_facts

    UNION ALL

    SELECT
        6,
        'Cancelled lines loaded',
        CASE
            WHEN cancelled_fact_count = 0
            THEN 'PASS'
            ELSE 'FAIL'
        END,
        cancelled_fact_count::TEXT,
        '0',
        'Cancelled transactions must be excluded from the warehouse.'
    FROM cancelled_facts

    UNION ALL

    SELECT
        7,
        'Deterministic transaction count',
        CASE WHEN transaction_count = 288 THEN 'PASS' ELSE 'FAIL' END,
        transaction_count::TEXT,
        '288',
        'The supplied generator should create 288 checkouts.'
    FROM fixed_sample_totals

    UNION ALL

    SELECT
        8,
        'Deterministic item count',
        CASE WHEN item_count = 720 THEN 'PASS' ELSE 'FAIL' END,
        item_count::TEXT,
        '720',
        'The supplied generator should create 720 checkout lines.'
    FROM fixed_sample_totals

    UNION ALL

    SELECT
        9,
        'Deterministic cancellation count',
        CASE
            WHEN cancelled_transaction_count = 15
            THEN 'PASS'
            ELSE 'FAIL'
        END,
        cancelled_transaction_count::TEXT,
        '15',
        'The supplied generator should create 15 cancelled checkouts.'
    FROM fixed_sample_totals

    UNION ALL

    SELECT
        10,
        'Complete 2026 calendar dimension',
        CASE
            WHEN calendar_date_count = 365
            THEN 'PASS'
            ELSE 'FAIL'
        END,
        calendar_date_count::TEXT,
        '365',
        'The date dimension should contain every date in 2026.'
    FROM fixed_sample_totals
)
SELECT
    check_name,
    status,
    actual_value,
    expected_value,
    details
FROM checks
ORDER BY check_order;
