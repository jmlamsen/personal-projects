-- Update planner statistics before inspecting plans.
ANALYZE oltp.transactions;
ANALYZE oltp.transaction_items;
ANALYZE dw.fact_cafeteria_sales;
ANALYZE dw.dim_date;
ANALYZE dw.dim_payment_method;

-- A sequential scan can be the correct plan for this intentionally small
-- dataset. The purpose is to learn how to read the plan, not to force an index.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    date_dimension.full_date,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_date AS date_dimension
    ON date_dimension.date_key = fact.date_key
GROUP BY date_dimension.full_date
ORDER BY date_dimension.full_date;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    payment.payment_group,
    COUNT(DISTINCT fact.transaction_id) AS completed_transactions,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_payment_method AS payment
    ON payment.payment_method_key = fact.payment_method_key
GROUP BY payment.payment_group;
