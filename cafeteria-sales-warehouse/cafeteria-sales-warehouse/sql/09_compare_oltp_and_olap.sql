-- The same monthly revenue question answered from both database designs.
WITH oltp_monthly AS (
    SELECT
        date_trunc(
            'month',
            transaction.sold_at AT TIME ZONE 'Asia/Manila'
        )::DATE AS month_start,
        SUM(
            item.quantity * item.unit_price - item.discount_amount
        )::NUMERIC(14, 2) AS oltp_net_revenue
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'COMPLETED'
    GROUP BY month_start
),
warehouse_monthly AS (
    SELECT
        make_date(
            date_dimension.year_number,
            date_dimension.month_number,
            1
        ) AS month_start,
        SUM(fact.net_sales_amount)::NUMERIC(14, 2)
            AS warehouse_net_revenue
    FROM dw.fact_cafeteria_sales AS fact
    JOIN dw.dim_date AS date_dimension
        ON date_dimension.date_key = fact.date_key
    GROUP BY
        date_dimension.year_number,
        date_dimension.month_number
)
SELECT
    COALESCE(oltp.month_start, warehouse.month_start) AS month_start,
    oltp.oltp_net_revenue,
    warehouse.warehouse_net_revenue,
    CASE
        WHEN oltp.oltp_net_revenue = warehouse.warehouse_net_revenue
        THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS reconciliation_status
FROM oltp_monthly AS oltp
FULL OUTER JOIN warehouse_monthly AS warehouse
    ON warehouse.month_start = oltp.month_start
ORDER BY month_start;

-- Grain demonstration:
-- fact_rows is not the transaction count because a transaction can contain
-- multiple product lines.
SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT transaction_id) AS completed_transactions,
    COUNT(*) - COUNT(DISTINCT transaction_id)
        AS additional_rows_caused_by_line_item_grain
FROM dw.fact_cafeteria_sales;
