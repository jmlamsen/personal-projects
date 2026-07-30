BEGIN;

-- Remove facts whose source line was deleted or whose transaction is no
-- longer completed. This makes the script a full synchronization, not only
-- an insert-only load.
DELETE FROM dw.fact_cafeteria_sales AS fact
WHERE NOT EXISTS (
    SELECT 1
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE item.transaction_item_id = fact.source_transaction_item_id
      AND transaction.transaction_status = 'COMPLETED'
);

WITH completed_lines AS (
    SELECT
        item.transaction_item_id,
        transaction.transaction_id,
        (transaction.sold_at AT TIME ZONE 'Asia/Manila')::DATE AS sale_date,
        item.product_id,
        transaction.payment_method_id,
        item.quantity,
        item.unit_price,
        item.discount_amount
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'COMPLETED'
)
INSERT INTO dw.fact_cafeteria_sales (
    source_transaction_item_id,
    transaction_id,
    date_key,
    product_key,
    payment_method_key,
    quantity,
    unit_price,
    discount_amount,
    gross_sales_amount,
    net_sales_amount,
    loaded_at
)
SELECT
    line.transaction_item_id,
    line.transaction_id,
    date_dimension.date_key,
    product_dimension.product_key,
    payment_dimension.payment_method_key,
    line.quantity,
    line.unit_price,
    line.discount_amount,
    (line.quantity * line.unit_price)::NUMERIC(12, 2),
    (
        (line.quantity * line.unit_price) - line.discount_amount
    )::NUMERIC(12, 2),
    CURRENT_TIMESTAMP
FROM completed_lines AS line
JOIN dw.dim_date AS date_dimension
    ON date_dimension.full_date = line.sale_date
JOIN dw.dim_product AS product_dimension
    ON product_dimension.source_product_id = line.product_id
JOIN dw.dim_payment_method AS payment_dimension
    ON payment_dimension.source_payment_method_id = line.payment_method_id
ON CONFLICT (source_transaction_item_id)
DO UPDATE SET
    transaction_id = EXCLUDED.transaction_id,
    date_key = EXCLUDED.date_key,
    product_key = EXCLUDED.product_key,
    payment_method_key = EXCLUDED.payment_method_key,
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price,
    discount_amount = EXCLUDED.discount_amount,
    gross_sales_amount = EXCLUDED.gross_sales_amount,
    net_sales_amount = EXCLUDED.net_sales_amount,
    loaded_at = EXCLUDED.loaded_at;

-- Fail the load if row counts or revenue do not reconcile.
DO $$
DECLARE
    source_row_count   BIGINT;
    fact_row_count     BIGINT;
    source_net_revenue NUMERIC(14, 2);
    fact_net_revenue   NUMERIC(14, 2);
BEGIN
    SELECT
        COUNT(*),
        COALESCE(
            SUM(item.quantity * item.unit_price - item.discount_amount),
            0
        )
    INTO
        source_row_count,
        source_net_revenue
    FROM oltp.transaction_items AS item
    JOIN oltp.transactions AS transaction
        ON transaction.transaction_id = item.transaction_id
    WHERE transaction.transaction_status = 'COMPLETED';

    SELECT
        COUNT(*),
        COALESCE(SUM(net_sales_amount), 0)
    INTO
        fact_row_count,
        fact_net_revenue
    FROM dw.fact_cafeteria_sales;

    IF source_row_count <> fact_row_count THEN
        RAISE EXCEPTION
            'Fact load row mismatch: source %, warehouse %.',
            source_row_count,
            fact_row_count;
    END IF;

    IF source_net_revenue <> fact_net_revenue THEN
        RAISE EXCEPTION
            'Fact load revenue mismatch: source %, warehouse %.',
            source_net_revenue,
            fact_net_revenue;
    END IF;
END
$$;

COMMIT;
