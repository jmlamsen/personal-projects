-- ============================================================
-- SmartSpend: Personal Expense Tracker
-- File: 01_create_tables.sql
-- Purpose: Reset and create the project tables.
-- ============================================================

-- Drop the child table first because it depends on categories.
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    category_type VARCHAR(10) NOT NULL
        CHECK (category_type IN ('Need', 'Want')),
    monthly_budget NUMERIC(10, 2) NOT NULL
        CHECK (monthly_budget >= 0)
);

CREATE TABLE expenses (
    expense_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INTEGER NOT NULL,
    expense_date DATE NOT NULL,
    description VARCHAR(150) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
        CHECK (amount > 0),
    payment_method VARCHAR(20) NOT NULL
        CHECK (
            payment_method IN (
                'Cash',
                'E-Wallet',
                'Card',
                'Bank Transfer'
            )
        ),

    CONSTRAINT fk_expense_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- These indexes support common date and category filters.
CREATE INDEX idx_expenses_date
    ON expenses(expense_date);

CREATE INDEX idx_expenses_category_id
    ON expenses(category_id);
