-- ============================================================
-- SmartSpend: Personal Expense Tracker
-- File: 03_basic_analysis.sql
-- Purpose: Basic filtering, joins, aggregation, and sorting.
-- ============================================================

-- 1. Display all expenses with their category information.
SELECT
    e.expense_id,
    e.expense_date,
    e.description,
    c.category_name,
    c.category_type,
    e.amount,
    e.payment_method
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
ORDER BY
    e.expense_date,
    e.expense_id;

-- 2. Calculate the total amount spent.
SELECT
    ROUND(SUM(amount), 2) AS total_spent
FROM expenses;

-- 3. Calculate the average transaction amount.
SELECT
    ROUND(AVG(amount), 2) AS average_expense
FROM expenses;

-- 4. Count the number of expense transactions.
SELECT
    COUNT(*) AS number_of_expenses
FROM expenses;

-- 5. Display the largest individual expense.
SELECT
    e.expense_date,
    e.description,
    c.category_name,
    e.amount
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
ORDER BY
    e.amount DESC,
    e.expense_date
LIMIT 1;

-- 6. Display all expenses from February 2026.
-- An exclusive upper boundary safely handles any future timestamp conversion.
SELECT
    e.expense_date,
    e.description,
    c.category_name,
    e.amount,
    e.payment_method
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
WHERE
    e.expense_date >= DATE '2026-02-01'
    AND e.expense_date < DATE '2026-03-01'
ORDER BY
    e.expense_date,
    e.expense_id;

-- 7. Display all Food expenses without depending on a numeric category ID.
SELECT
    e.expense_date,
    e.description,
    e.amount,
    e.payment_method
FROM expenses AS e
INNER JOIN categories AS c
    ON c.category_id = e.category_id
WHERE
    c.category_name = 'Food'
ORDER BY
    e.expense_date;

-- 8. Calculate total spending for each category.
SELECT
    c.category_name,
    ROUND(SUM(e.amount), 2) AS total_spent
FROM categories AS c
INNER JOIN expenses AS e
    ON e.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY
    total_spent DESC,
    c.category_name;

-- 9. Return only the category with the highest spending.
SELECT
    c.category_name,
    ROUND(SUM(e.amount), 2) AS total_spent
FROM categories AS c
INNER JOIN expenses AS e
    ON e.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY
    total_spent DESC
LIMIT 1;

-- 10. Calculate the average transaction amount for each category.
SELECT
    c.category_name,
    ROUND(AVG(e.amount), 2) AS average_expense
FROM categories AS c
INNER JOIN expenses AS e
    ON e.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY
    average_expense DESC,
    c.category_name;

-- 11. Count the number of transactions in each category.
SELECT
    c.category_name,
    COUNT(e.expense_id) AS transaction_count
FROM categories AS c
LEFT JOIN expenses AS e
    ON e.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY
    transaction_count DESC,
    c.category_name;
