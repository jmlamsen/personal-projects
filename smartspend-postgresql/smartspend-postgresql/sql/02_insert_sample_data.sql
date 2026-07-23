-- ============================================================
-- SmartSpend: Personal Expense Tracker
-- File: 02_insert_sample_data.sql
-- Purpose: Insert categories and fictional expense records.
-- Currency: Philippine pesos (PHP)
-- ============================================================

BEGIN;

INSERT INTO categories (
    category_name,
    category_type,
    monthly_budget
)
VALUES
    ('Food', 'Need', 4500.00),
    ('Transportation', 'Need', 2200.00),
    ('School', 'Need', 3000.00),
    ('Internet', 'Need', 1600.00),
    ('Entertainment', 'Want', 1200.00);

-- Category names are joined to their generated IDs.
-- This avoids hard-coding category_id values in the expense data.
INSERT INTO expenses (
    category_id,
    expense_date,
    description,
    amount,
    payment_method
)
SELECT
    c.category_id,
    v.expense_date,
    v.description,
    v.amount,
    v.payment_method
FROM (
    VALUES
        -- January 2026
        ('Food', DATE '2026-01-03', 'Weekly groceries', 850.00, 'E-Wallet'),
        ('Food', DATE '2026-01-08', 'Lunch after class', 135.00, 'Cash'),
        ('Transportation', DATE '2026-01-10', 'Jeepney fares', 320.00, 'Cash'),
        ('Transportation', DATE '2026-01-18', 'Bus trip', 280.00, 'E-Wallet'),
        ('School', DATE '2026-01-12', 'Printing and photocopying', 160.00, 'Cash'),
        ('School', DATE '2026-01-22', 'Laboratory materials', 420.00, 'E-Wallet'),
        ('Internet', DATE '2026-01-05', 'Mobile data package', 350.00, 'E-Wallet'),
        ('Entertainment', DATE '2026-01-25', 'Streaming subscription', 249.00, 'Card'),

        -- February 2026
        ('Food', DATE '2026-02-02', 'Weekly groceries', 920.00, 'E-Wallet'),
        ('Food', DATE '2026-02-09', 'Lunch with classmates', 150.00, 'Cash'),
        ('Transportation', DATE '2026-02-06', 'Jeepney fares', 340.00, 'Cash'),
        ('Transportation', DATE '2026-02-17', 'Tricycle fares', 180.00, 'Cash'),
        ('School', DATE '2026-02-11', 'Reference textbooks', 1250.00, 'Bank Transfer'),
        ('School', DATE '2026-02-20', 'Printing school reports', 140.00, 'Cash'),
        ('Internet', DATE '2026-02-04', 'Home internet contribution', 700.00, 'Bank Transfer'),
        ('Entertainment', DATE '2026-02-24', 'Video game purchase', 450.00, 'Card'),

        -- March 2026
        ('Food', DATE '2026-03-03', 'Weekly groceries', 980.00, 'E-Wallet'),
        ('Food', DATE '2026-03-14', 'Meals during project week', 420.00, 'Cash'),
        ('Transportation', DATE '2026-03-07', 'Jeepney fares', 360.00, 'Cash'),
        ('Transportation', DATE '2026-03-19', 'Provincial bus fare', 300.00, 'E-Wallet'),
        ('School', DATE '2026-03-09', 'Electronics project components', 1850.00, 'Bank Transfer'),
        ('School', DATE '2026-03-21', 'Photocopying and binding', 210.00, 'Cash'),
        ('Internet', DATE '2026-03-05', 'Monthly internet bill', 1499.00, 'Bank Transfer'),
        ('Entertainment', DATE '2026-03-28', 'Music festival ticket', 1380.00, 'Card'),

        -- April 2026
        ('Food', DATE '2026-04-01', 'Weekly groceries', 1020.00, 'E-Wallet'),
        ('Food', DATE '2026-04-13', 'Snacks during review', 260.00, 'Cash'),
        ('Transportation', DATE '2026-04-05', 'Jeepney fares', 380.00, 'Cash'),
        ('Transportation', DATE '2026-04-16', 'Ride-share trip', 420.00, 'E-Wallet'),
        ('School', DATE '2026-04-08', 'Enrollment documents', 300.00, 'Cash'),
        ('School', DATE '2026-04-22', 'Laboratory materials', 760.00, 'Card'),
        ('Internet', DATE '2026-04-04', 'Mobile data package', 400.00, 'E-Wallet'),
        ('Entertainment', DATE '2026-04-27', 'Community event ticket', 850.00, 'Card'),

        -- May 2026
        ('Food', DATE '2026-05-02', 'Weekly groceries', 1100.00, 'E-Wallet'),
        ('Food', DATE '2026-05-12', 'Lunch during examinations', 480.00, 'Cash'),
        ('Transportation', DATE '2026-05-06', 'Jeepney fares', 400.00, 'Cash'),
        ('Transportation', DATE '2026-05-18', 'Bus transportation', 350.00, 'E-Wallet'),
        ('School', DATE '2026-05-09', 'Educational software subscription', 500.00, 'Card'),
        ('School', DATE '2026-05-23', 'Printing examination notes', 180.00, 'Cash'),
        ('Internet', DATE '2026-05-05', 'Monthly internet bill', 1499.00, 'Bank Transfer'),
        ('Entertainment', DATE '2026-05-29', 'Online game credits', 600.00, 'Card'),

        -- June 2026
        ('Food', DATE '2026-06-02', 'Weekly groceries', 1150.00, 'E-Wallet'),
        ('Food', DATE '2026-06-15', 'Meals during final project', 520.00, 'Cash'),
        ('Transportation', DATE '2026-06-07', 'Jeepney fares', 420.00, 'Cash'),
        ('Transportation', DATE '2026-06-20', 'Bus transportation', 380.00, 'E-Wallet'),
        ('School', DATE '2026-06-10', 'Capstone project materials', 2200.00, 'Bank Transfer'),
        ('School', DATE '2026-06-24', 'Printing and binding', 260.00, 'Cash'),
        ('Internet', DATE '2026-06-05', 'Monthly internet bill', 1499.00, 'Bank Transfer'),
        ('Entertainment', DATE '2026-06-28', 'Class outing contribution', 950.00, 'E-Wallet')
) AS v (
    category_name,
    expense_date,
    description,
    amount,
    payment_method
)
INNER JOIN categories AS c
    ON c.category_name = v.category_name;

COMMIT;

-- Confirm that the correct number of records was inserted.
SELECT COUNT(*) AS category_count
FROM categories;

SELECT COUNT(*) AS expense_count
FROM expenses;
