-- Query 1: daily revenue
SELECT
    date_dimension.full_date,
    COUNT(DISTINCT fact.transaction_id) AS completed_transactions,
    SUM(fact.quantity) AS units_sold,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_date AS date_dimension
    ON date_dimension.date_key = fact.date_key
GROUP BY date_dimension.full_date
ORDER BY date_dimension.full_date;

-- Query 2: monthly revenue
SELECT
    date_dimension.year_number,
    date_dimension.month_number,
    date_dimension.month_name,
    COUNT(DISTINCT fact.transaction_id) AS completed_transactions,
    SUM(fact.quantity) AS units_sold,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_date AS date_dimension
    ON date_dimension.date_key = fact.date_key
GROUP BY
    date_dimension.year_number,
    date_dimension.month_number,
    date_dimension.month_name
ORDER BY
    date_dimension.year_number,
    date_dimension.month_number;

-- Query 3: most frequently purchased category
-- SUM(quantity) measures units. COUNT(*) would only count product lines.
SELECT
    category.category_name,
    SUM(fact.quantity) AS units_sold,
    COUNT(DISTINCT fact.transaction_id) AS transactions_containing_category,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_product AS product
    ON product.product_key = fact.product_key
JOIN dw.dim_category AS category
    ON category.category_key = product.category_key
GROUP BY category.category_name
ORDER BY
    units_sold DESC,
    category.category_name;

-- Query 4: cash versus digital payments
WITH payment_summary AS (
    SELECT
        payment.payment_group,
        COUNT(DISTINCT fact.transaction_id) AS completed_transactions,
        SUM(fact.quantity) AS units_sold,
        SUM(fact.net_sales_amount) AS net_revenue
    FROM dw.fact_cafeteria_sales AS fact
    JOIN dw.dim_payment_method AS payment
        ON payment.payment_method_key = fact.payment_method_key
    GROUP BY payment.payment_group
)
SELECT
    payment_group,
    completed_transactions,
    units_sold,
    net_revenue,
    ROUND(
        100.0 * net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0),
        2
    ) AS revenue_percentage
FROM payment_summary
ORDER BY net_revenue DESC;

-- Query 5: average units sold per completed transaction
-- The fact table is at line-item grain, so AVG(quantity) is not the answer.
SELECT
    SUM(quantity) AS total_units,
    COUNT(DISTINCT transaction_id) AS completed_transactions,
    ROUND(
        SUM(quantity)::NUMERIC
        / NULLIF(COUNT(DISTINCT transaction_id), 0),
        2
    ) AS average_units_per_transaction
FROM dw.fact_cafeteria_sales;

-- Query 6: sales trends by weekday
SELECT
    date_dimension.day_of_week_number,
    date_dimension.day_name,
    COUNT(DISTINCT fact.transaction_id) AS completed_transactions,
    SUM(fact.quantity) AS units_sold,
    SUM(fact.net_sales_amount) AS net_revenue,
    ROUND(
        SUM(fact.net_sales_amount)
        / NULLIF(COUNT(DISTINCT fact.transaction_id), 0),
        2
    ) AS average_transaction_value
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_date AS date_dimension
    ON date_dimension.date_key = fact.date_key
GROUP BY
    date_dimension.day_of_week_number,
    date_dimension.day_name
ORDER BY date_dimension.day_of_week_number;

-- Bonus query: top five products by revenue
SELECT
    product.product_name,
    category.category_name,
    SUM(fact.quantity) AS units_sold,
    SUM(fact.net_sales_amount) AS net_revenue
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_product AS product
    ON product.product_key = fact.product_key
JOIN dw.dim_category AS category
    ON category.category_key = product.category_key
GROUP BY
    product.product_name,
    category.category_name
ORDER BY
    net_revenue DESC,
    product.product_name
LIMIT 5;
