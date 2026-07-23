-- ============================================================
-- SmartSpend: Personal Expense Tracker
-- File: 04_advanced_analysis.sql
-- Purpose: Monthly, budget, conditional, and trend analysis.
-- ============================================================

-- 1. Calculate total spending for each month.
SELECT
    DATE_TRUNC('month', expense_date)::DATE AS expense_month,
    ROUND(SUM(amount), 2) AS monthly_total
FROM expenses
GROUP BY
    DATE_TRUNC('month', expense_date)
ORDER BY
    expense_month;

-- 2. Calculate spending by category and month.
SELECT
    DATE_TRUNC('month', e.expense_date)::DATE AS expense_month,
    c.category_name,
    ROUND(SUM(e.amount), 2) AS total_spent
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
GROUP BY
    DATE_TRUNC('month', e.expense_date),
    c.category_id,
    c.category_name
ORDER BY
    expense_month,
    total_spent DESC;

-- 3. Compare spending on needs and wants.
SELECT
    c.category_type,
    ROUND(SUM(e.amount), 2) AS total_spent,
    ROUND(
        SUM(e.amount) * 100.0 / SUM(SUM(e.amount)) OVER (),
        2
    ) AS percentage_of_total
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
GROUP BY
    c.category_type
ORDER BY
    total_spent DESC;

-- 4. Summarize spending and transaction count by payment method.
SELECT
    payment_method,
    ROUND(SUM(amount), 2) AS total_spent,
    COUNT(*) AS transaction_count,
    ROUND(AVG(amount), 2) AS average_transaction
FROM expenses
GROUP BY
    payment_method
ORDER BY
    total_spent DESC,
    payment_method;

-- 5. Create a budget report for March 2026.
-- LEFT JOIN keeps categories even when they have no expenses that month.
WITH selected_month AS (
    SELECT
        DATE '2026-03-01' AS month_start,
        DATE '2026-04-01' AS next_month_start
)
SELECT
    c.category_name,
    c.monthly_budget,
    ROUND(COALESCE(SUM(e.amount), 0), 2) AS amount_spent,
    ROUND(
        c.monthly_budget - COALESCE(SUM(e.amount), 0),
        2
    ) AS remaining_budget,
    CASE
        WHEN COALESCE(SUM(e.amount), 0) > c.monthly_budget
            THEN 'Over Budget'
        ELSE 'Within Budget'
    END AS budget_status
FROM categories AS c
CROSS JOIN selected_month AS sm
LEFT JOIN expenses AS e
    ON e.category_id = c.category_id
    AND e.expense_date >= sm.month_start
    AND e.expense_date < sm.next_month_start
GROUP BY
    c.category_id,
    c.category_name,
    c.monthly_budget
ORDER BY
    amount_spent DESC,
    c.category_name;

-- 6. Classify each transaction by expense size.
SELECT
    e.expense_date,
    e.description,
    c.category_name,
    e.amount,
    CASE
        WHEN e.amount < 200 THEN 'Small Expense'
        WHEN e.amount < 1000 THEN 'Medium Expense'
        ELSE 'Large Expense'
    END AS spending_level
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
ORDER BY
    e.amount DESC,
    e.expense_date;

-- 7. Calculate month-over-month changes in total spending.
WITH monthly_spending AS (
    SELECT
        DATE_TRUNC('month', expense_date)::DATE AS expense_month,
        SUM(amount) AS monthly_total
    FROM expenses
    GROUP BY
        DATE_TRUNC('month', expense_date)
),
monthly_changes AS (
    SELECT
        expense_month,
        monthly_total,
        LAG(monthly_total) OVER (
            ORDER BY expense_month
        ) AS previous_month_total
    FROM monthly_spending
)
SELECT
    expense_month,
    ROUND(monthly_total, 2) AS monthly_total,
    ROUND(previous_month_total, 2) AS previous_month_total,
    ROUND(monthly_total - previous_month_total, 2) AS amount_change,
    ROUND(
        (monthly_total - previous_month_total) * 100.0
        / NULLIF(previous_month_total, 0),
        2
    ) AS percentage_change
FROM monthly_changes
ORDER BY
    expense_month;

-- 8. Compare every category's spending with its budget for every month.
WITH months AS (
    SELECT DISTINCT
        DATE_TRUNC('month', expense_date)::DATE AS expense_month
    FROM expenses
),
category_month_totals AS (
    SELECT
        m.expense_month,
        c.category_id,
        c.category_name,
        c.monthly_budget,
        COALESCE(SUM(e.amount), 0) AS amount_spent
    FROM months AS m
    CROSS JOIN categories AS c
    LEFT JOIN expenses AS e
        ON e.category_id = c.category_id
        AND e.expense_date >= m.expense_month
        AND e.expense_date < (m.expense_month + INTERVAL '1 month')
    GROUP BY
        m.expense_month,
        c.category_id,
        c.category_name,
        c.monthly_budget
)
SELECT
    expense_month,
    category_name,
    monthly_budget,
    ROUND(amount_spent, 2) AS amount_spent,
    ROUND(monthly_budget - amount_spent, 2) AS remaining_budget,
    CASE
        WHEN amount_spent > monthly_budget THEN 'Over Budget'
        ELSE 'Within Budget'
    END AS budget_status
FROM category_month_totals
ORDER BY
    expense_month,
    category_name;

-- 9. Show only category-month combinations that exceeded the budget.
WITH category_month_totals AS (
    SELECT
        DATE_TRUNC('month', e.expense_date)::DATE AS expense_month,
        c.category_name,
        c.monthly_budget,
        SUM(e.amount) AS amount_spent
    FROM expenses AS e
    INNER JOIN categories AS c
        ON c.category_id = e.category_id
    GROUP BY
        DATE_TRUNC('month', e.expense_date),
        c.category_id,
        c.category_name,
        c.monthly_budget
)
SELECT
    expense_month,
    category_name,
    monthly_budget,
    ROUND(amount_spent, 2) AS amount_spent,
    ROUND(amount_spent - monthly_budget, 2) AS amount_over_budget
FROM category_month_totals
WHERE
    amount_spent > monthly_budget
ORDER BY
    expense_month,
    amount_over_budget DESC;
