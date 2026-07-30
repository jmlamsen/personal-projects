BEGIN;

SET LOCAL TIME ZONE 'Asia/Manila';

-- Re-running this file reproduces the same operational dataset.
TRUNCATE TABLE
    oltp.transaction_items,
    oltp.transactions,
    oltp.products,
    oltp.categories,
    oltp.payment_methods
RESTART IDENTITY CASCADE;

INSERT INTO oltp.categories (
    category_name,
    description
)
VALUES
    ('Breakfast', 'Morning meals and breakfast combinations'),
    ('Rice Meals', 'Prepared meals served with rice'),
    ('Snacks', 'Quick savory or sweet snacks'),
    ('Beverages', 'Hot and cold drinks'),
    ('Desserts', 'Ready-to-serve sweet items'),
    ('School Supplies', 'Small school essentials sold at the counter');

INSERT INTO oltp.products (
    category_id,
    product_name,
    current_price
)
SELECT
    c.category_id,
    product.product_name,
    product.current_price
FROM (
    VALUES
        ('Breakfast', 'Pandesal Combo', 45.00::NUMERIC),
        ('Breakfast', 'Egg Sandwich', 55.00::NUMERIC),
        ('Breakfast', 'Champorado', 50.00::NUMERIC),
        ('Rice Meals', 'Chicken Adobo Rice', 85.00::NUMERIC),
        ('Rice Meals', 'Pork Tocino Rice', 90.00::NUMERIC),
        ('Rice Meals', 'Fried Chicken Rice', 95.00::NUMERIC),
        ('Rice Meals', 'Vegetable Meal', 75.00::NUMERIC),
        ('Snacks', 'Banana Cue', 20.00::NUMERIC),
        ('Snacks', 'Turon', 20.00::NUMERIC),
        ('Snacks', 'Siomai', 35.00::NUMERIC),
        ('Snacks', 'French Fries', 45.00::NUMERIC),
        ('Beverages', 'Bottled Water', 20.00::NUMERIC),
        ('Beverages', 'Iced Tea', 30.00::NUMERIC),
        ('Beverages', 'Calamansi Juice', 35.00::NUMERIC),
        ('Beverages', 'Coffee', 25.00::NUMERIC),
        ('Desserts', 'Leche Flan Slice', 40.00::NUMERIC),
        ('Desserts', 'Fruit Cup', 45.00::NUMERIC),
        ('School Supplies', 'Ballpen', 12.00::NUMERIC),
        ('School Supplies', 'Notebook', 35.00::NUMERIC)
) AS product (
    category_name,
    product_name,
    current_price
)
JOIN oltp.categories AS c
    ON c.category_name = product.category_name
ORDER BY
    c.category_id,
    product.product_name;

INSERT INTO oltp.payment_methods (
    payment_method_name,
    payment_group
)
VALUES
    ('Cash', 'CASH'),
    ('GCash', 'DIGITAL'),
    ('Maya', 'DIGITAL'),
    ('Debit Card', 'DIGITAL');

-- The sample covers 12 complete weeks: 2026-04-06 through 2026-06-28.
-- Weekdays have four checkout slots, while weekends have two.
WITH calendar_slots AS (
    SELECT
        day_number,
        slot_number,
        DATE '2026-04-06' + day_number AS sale_date,
        CASE slot_number
            WHEN 1 THEN TIME '07:30'
            WHEN 2 THEN TIME '11:30'
            WHEN 3 THEN TIME '12:45'
            WHEN 4 THEN TIME '16:15'
        END AS sale_time
    FROM generate_series(0, 83) AS day_series (day_number)
    CROSS JOIN generate_series(1, 4) AS slot_series (slot_number)
    WHERE
        EXTRACT(ISODOW FROM DATE '2026-04-06' + day_number) <= 5
        OR slot_number <= 2
),
numbered_transactions AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY sale_date, slot_number
        )::INTEGER AS transaction_number,
        sale_date,
        sale_time
    FROM calendar_slots
),
prepared_transactions AS (
    SELECT
        transaction_number,
        format(
            'CAF-2026-%s',
            lpad(transaction_number::TEXT, 4, '0')
        ) AS receipt_number,
        (sale_date + sale_time) AT TIME ZONE 'Asia/Manila' AS sold_at,
        CASE
            -- Early period: cash is used in about 60% of checkouts.
            WHEN transaction_number <= 96 THEN
                CASE transaction_number % 5
                    WHEN 0 THEN 'Cash'
                    WHEN 1 THEN 'Cash'
                    WHEN 2 THEN 'Cash'
                    WHEN 3 THEN 'GCash'
                    ELSE 'Maya'
                END

            -- Middle period: cash and digital methods are roughly balanced.
            WHEN transaction_number <= 192 THEN
                CASE transaction_number % 4
                    WHEN 0 THEN 'Cash'
                    WHEN 1 THEN 'GCash'
                    WHEN 2 THEN 'Cash'
                    ELSE 'Maya'
                END

            -- Late period: digital methods are used in about 70% of checkouts.
            ELSE
                CASE transaction_number % 10
                    WHEN 0 THEN 'Cash'
                    WHEN 1 THEN 'Cash'
                    WHEN 2 THEN 'Cash'
                    WHEN 3 THEN 'GCash'
                    WHEN 4 THEN 'GCash'
                    WHEN 5 THEN 'GCash'
                    WHEN 6 THEN 'GCash'
                    WHEN 7 THEN 'Maya'
                    WHEN 8 THEN 'Maya'
                    ELSE 'Debit Card'
                END
        END AS payment_method_name,
        CASE
            WHEN transaction_number % 19 = 0 THEN 'CANCELLED'
            ELSE 'COMPLETED'
        END AS transaction_status
    FROM numbered_transactions
)
INSERT INTO oltp.transactions (
    receipt_number,
    sold_at,
    payment_method_id,
    transaction_status,
    created_at
)
SELECT
    prepared.receipt_number,
    prepared.sold_at,
    payment.payment_method_id,
    prepared.transaction_status,
    prepared.sold_at + INTERVAL '20 seconds'
FROM prepared_transactions AS prepared
JOIN oltp.payment_methods AS payment
    ON payment.payment_method_name = prepared.payment_method_name
ORDER BY prepared.transaction_number;

-- Product choice depends on the checkout time:
-- breakfast in the morning, rice meals at lunch, and snacks after class.
-- Additional lines contain a beverage, dessert, or small school supply.
WITH transaction_base AS (
    SELECT
        transaction.transaction_id,
        right(transaction.receipt_number, 4)::INTEGER AS transaction_number,
        (transaction.sold_at AT TIME ZONE 'Asia/Manila')::DATE AS local_sale_date,
        (transaction.sold_at AT TIME ZONE 'Asia/Manila')::TIME AS local_sale_time,
        EXTRACT(
            ISODOW
            FROM (transaction.sold_at AT TIME ZONE 'Asia/Manila')::DATE
        )::INTEGER AS iso_weekday
    FROM oltp.transactions AS transaction
),
expanded_lines AS (
    SELECT
        base.*,
        line.line_number
    FROM transaction_base AS base
    CROSS JOIN LATERAL generate_series(
        1,
        1 + (base.transaction_number % 4)
    ) AS line (line_number)
),
chosen_products AS (
    SELECT
        line.*,
        CASE
            WHEN line.line_number = 1
                AND line.local_sale_time < TIME '10:00'
            THEN (
                ARRAY[
                    'Pandesal Combo',
                    'Egg Sandwich',
                    'Champorado'
                ]
            )[1 + (line.transaction_number % 3)]

            WHEN line.line_number = 1
                AND line.local_sale_time < TIME '14:00'
            THEN (
                ARRAY[
                    'Chicken Adobo Rice',
                    'Pork Tocino Rice',
                    'Fried Chicken Rice',
                    'Vegetable Meal'
                ]
            )[1 + (line.transaction_number % 4)]

            WHEN line.line_number = 1
            THEN (
                ARRAY[
                    'Banana Cue',
                    'Turon',
                    'Siomai',
                    'French Fries'
                ]
            )[1 + (line.transaction_number % 4)]

            WHEN line.line_number = 2
            THEN (
                ARRAY[
                    'Bottled Water',
                    'Iced Tea',
                    'Calamansi Juice',
                    'Coffee'
                ]
            )[1 + (line.transaction_number % 4)]

            WHEN line.line_number = 3
            THEN (
                ARRAY[
                    'Leche Flan Slice',
                    'Fruit Cup'
                ]
            )[1 + (line.transaction_number % 2)]

            ELSE (
                ARRAY[
                    'Ballpen',
                    'Notebook'
                ]
            )[1 + (line.transaction_number % 2)]
        END AS product_name
    FROM expanded_lines AS line
),
calculated_lines AS (
    SELECT
        chosen.*,
        CASE
            WHEN chosen.line_number = 1
                AND chosen.local_sale_time >= TIME '14:00'
                AND chosen.iso_weekday = 5
            THEN 2
            WHEN chosen.line_number = 1
                AND chosen.transaction_number % 7 = 0
            THEN 2
            WHEN chosen.line_number = 2
                AND chosen.transaction_number % 10 = 0
            THEN 2
            WHEN chosen.line_number = 3
                AND chosen.iso_weekday = 5
            THEN 2
            ELSE 1
        END::SMALLINT AS quantity
    FROM chosen_products AS chosen
)
INSERT INTO oltp.transaction_items (
    transaction_id,
    product_id,
    quantity,
    unit_price,
    discount_amount
)
SELECT
    line.transaction_id,
    product.product_id,
    line.quantity,
    (
        product.current_price
        - CASE
            -- These products had a five-peso price increase on 2026-05-18.
            WHEN line.local_sale_date < DATE '2026-05-18'
                AND line.product_name IN (
                    'Chicken Adobo Rice',
                    'Iced Tea',
                    'French Fries'
                )
            THEN 5.00
            ELSE 0.00
        END
    )::NUMERIC(10, 2) AS historical_unit_price,
    CASE
        WHEN line.line_number = 1
            AND line.transaction_number % 23 = 0
        THEN 5.00
        ELSE 0.00
    END::NUMERIC(10, 2) AS discount_amount
FROM calculated_lines AS line
JOIN oltp.products AS product
    ON product.product_name = line.product_name
ORDER BY
    line.transaction_id,
    line.line_number;

-- Stop immediately if the deterministic dataset was changed accidentally.
DO $$
DECLARE
    transaction_count           INTEGER;
    cancelled_transaction_count INTEGER;
    item_count                  INTEGER;
    completed_item_count        INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO transaction_count
    FROM oltp.transactions;

    SELECT COUNT(*)
    INTO cancelled_transaction_count
    FROM oltp.transactions
    WHERE transaction_status = 'CANCELLED';

    SELECT COUNT(*)
    INTO item_count
    FROM oltp.transaction_items;

    SELECT COUNT(*)
    INTO completed_item_count
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'COMPLETED';

    IF transaction_count <> 288 THEN
        RAISE EXCEPTION
            'Expected 288 transactions, found %.',
            transaction_count;
    END IF;

    IF cancelled_transaction_count <> 15 THEN
        RAISE EXCEPTION
            'Expected 15 cancelled transactions, found %.',
            cancelled_transaction_count;
    END IF;

    IF item_count <> 720 THEN
        RAISE EXCEPTION
            'Expected 720 transaction items, found %.',
            item_count;
    END IF;

    IF completed_item_count <> 681 THEN
        RAISE EXCEPTION
            'Expected 681 completed transaction items, found %.',
            completed_item_count;
    END IF;
END
$$;

COMMIT;
