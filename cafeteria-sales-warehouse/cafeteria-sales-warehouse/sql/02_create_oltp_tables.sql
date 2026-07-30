BEGIN;

CREATE TABLE oltp.categories (
    category_id     INTEGER GENERATED ALWAYS AS IDENTITY,
    category_name   VARCHAR(50) NOT NULL,
    description     VARCHAR(200),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_name UNIQUE (category_name),
    CONSTRAINT chk_categories_name_not_blank
        CHECK (btrim(category_name) <> '')
);

CREATE TABLE oltp.products (
    product_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    category_id     INTEGER NOT NULL,
    product_name    VARCHAR(100) NOT NULL,
    current_price   NUMERIC(10, 2) NOT NULL,
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES oltp.categories (category_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT uq_products_category_name
        UNIQUE (category_id, product_name),
    CONSTRAINT chk_products_name_not_blank
        CHECK (btrim(product_name) <> ''),
    CONSTRAINT chk_products_price_positive
        CHECK (current_price > 0)
);

CREATE TABLE oltp.payment_methods (
    payment_method_id     INTEGER GENERATED ALWAYS AS IDENTITY,
    payment_method_name   VARCHAR(40) NOT NULL,
    payment_group         VARCHAR(10) NOT NULL,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_payment_methods PRIMARY KEY (payment_method_id),
    CONSTRAINT uq_payment_methods_name UNIQUE (payment_method_name),
    CONSTRAINT chk_payment_methods_name_not_blank
        CHECK (btrim(payment_method_name) <> ''),
    CONSTRAINT chk_payment_methods_group
        CHECK (payment_group IN ('CASH', 'DIGITAL'))
);

CREATE TABLE oltp.transactions (
    transaction_id       BIGINT GENERATED ALWAYS AS IDENTITY,
    receipt_number       VARCHAR(20) NOT NULL,
    sold_at              TIMESTAMPTZ NOT NULL,
    payment_method_id    INTEGER NOT NULL,
    transaction_status   VARCHAR(12) NOT NULL DEFAULT 'COMPLETED',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT uq_transactions_receipt UNIQUE (receipt_number),
    CONSTRAINT fk_transactions_payment_method
        FOREIGN KEY (payment_method_id)
        REFERENCES oltp.payment_methods (payment_method_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT chk_transactions_receipt_not_blank
        CHECK (btrim(receipt_number) <> ''),
    CONSTRAINT chk_transactions_status
        CHECK (transaction_status IN ('COMPLETED', 'CANCELLED'))
);

CREATE TABLE oltp.transaction_items (
    transaction_item_id   BIGINT GENERATED ALWAYS AS IDENTITY,
    transaction_id        BIGINT NOT NULL,
    product_id            INTEGER NOT NULL,
    quantity              SMALLINT NOT NULL,
    unit_price            NUMERIC(10, 2) NOT NULL,
    discount_amount       NUMERIC(10, 2) NOT NULL DEFAULT 0.00,

    CONSTRAINT pk_transaction_items PRIMARY KEY (transaction_item_id),
    CONSTRAINT fk_transaction_items_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES oltp.transactions (transaction_id)
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT fk_transaction_items_product
        FOREIGN KEY (product_id)
        REFERENCES oltp.products (product_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT uq_transaction_items_product
        UNIQUE (transaction_id, product_id),
    CONSTRAINT chk_transaction_items_quantity
        CHECK (quantity > 0),
    CONSTRAINT chk_transaction_items_unit_price
        CHECK (unit_price >= 0),
    CONSTRAINT chk_transaction_items_discount_nonnegative
        CHECK (discount_amount >= 0),
    CONSTRAINT chk_transaction_items_discount_not_excessive
        CHECK (discount_amount <= quantity * unit_price)
);

-- PostgreSQL indexes primary keys and UNIQUE constraints automatically,
-- but it does not automatically index every foreign key.
CREATE INDEX idx_products_category_id
    ON oltp.products (category_id);

CREATE INDEX idx_transactions_sold_at
    ON oltp.transactions (sold_at);

CREATE INDEX idx_transactions_payment_method_id
    ON oltp.transactions (payment_method_id);

CREATE INDEX idx_transactions_status_sold_at
    ON oltp.transactions (transaction_status, sold_at);

CREATE INDEX idx_transaction_items_transaction_id
    ON oltp.transaction_items (transaction_id);

CREATE INDEX idx_transaction_items_product_id
    ON oltp.transaction_items (product_id);

COMMENT ON TABLE oltp.transactions IS
    'One row represents one cafeteria checkout.';

COMMENT ON TABLE oltp.transaction_items IS
    'One row represents one product line within a checkout.';

COMMENT ON COLUMN oltp.transaction_items.unit_price IS
    'Price charged at the time of sale; it is independent of the current product price.';

COMMIT;
