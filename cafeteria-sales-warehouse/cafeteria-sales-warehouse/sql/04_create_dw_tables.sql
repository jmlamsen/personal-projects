BEGIN;

CREATE TABLE dw.dim_category (
    category_key        INTEGER GENERATED ALWAYS AS IDENTITY,
    source_category_id  INTEGER NOT NULL,
    category_name       VARCHAR(50) NOT NULL,
    description         VARCHAR(200),
    is_active           BOOLEAN NOT NULL,

    CONSTRAINT pk_dim_category PRIMARY KEY (category_key),
    CONSTRAINT uq_dim_category_source_id UNIQUE (source_category_id),
    CONSTRAINT uq_dim_category_name UNIQUE (category_name),
    CONSTRAINT chk_dim_category_name_not_blank
        CHECK (btrim(category_name) <> '')
);

CREATE TABLE dw.dim_product (
    product_key        INTEGER GENERATED ALWAYS AS IDENTITY,
    source_product_id  INTEGER NOT NULL,
    category_key       INTEGER NOT NULL,
    product_name       VARCHAR(100) NOT NULL,
    current_price      NUMERIC(10, 2) NOT NULL,
    is_available       BOOLEAN NOT NULL,

    CONSTRAINT pk_dim_product PRIMARY KEY (product_key),
    CONSTRAINT uq_dim_product_source_id UNIQUE (source_product_id),
    CONSTRAINT fk_dim_product_category
        FOREIGN KEY (category_key)
        REFERENCES dw.dim_category (category_key)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT chk_dim_product_name_not_blank
        CHECK (btrim(product_name) <> ''),
    CONSTRAINT chk_dim_product_price_positive
        CHECK (current_price > 0)
);

CREATE TABLE dw.dim_payment_method (
    payment_method_key        INTEGER GENERATED ALWAYS AS IDENTITY,
    source_payment_method_id  INTEGER NOT NULL,
    payment_method_name       VARCHAR(40) NOT NULL,
    payment_group             VARCHAR(10) NOT NULL,

    CONSTRAINT pk_dim_payment_method PRIMARY KEY (payment_method_key),
    CONSTRAINT uq_dim_payment_method_source_id
        UNIQUE (source_payment_method_id),
    CONSTRAINT uq_dim_payment_method_name
        UNIQUE (payment_method_name),
    CONSTRAINT chk_dim_payment_method_group
        CHECK (payment_group IN ('CASH', 'DIGITAL'))
);

CREATE TABLE dw.dim_date (
    date_key            INTEGER NOT NULL,
    full_date           DATE NOT NULL,
    day_of_month        SMALLINT NOT NULL,
    day_of_week_number  SMALLINT NOT NULL,
    day_name            VARCHAR(9) NOT NULL,
    week_of_year        SMALLINT NOT NULL,
    month_number        SMALLINT NOT NULL,
    month_name          VARCHAR(9) NOT NULL,
    quarter_number      SMALLINT NOT NULL,
    year_number         SMALLINT NOT NULL,
    is_weekend          BOOLEAN NOT NULL,

    CONSTRAINT pk_dim_date PRIMARY KEY (date_key),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date),
    CONSTRAINT chk_dim_date_day_of_month
        CHECK (day_of_month BETWEEN 1 AND 31),
    CONSTRAINT chk_dim_date_day_of_week
        CHECK (day_of_week_number BETWEEN 1 AND 7),
    CONSTRAINT chk_dim_date_week
        CHECK (week_of_year BETWEEN 1 AND 53),
    CONSTRAINT chk_dim_date_month
        CHECK (month_number BETWEEN 1 AND 12),
    CONSTRAINT chk_dim_date_quarter
        CHECK (quarter_number BETWEEN 1 AND 4)
);

CREATE TABLE dw.fact_cafeteria_sales (
    cafeteria_sales_key       BIGINT GENERATED ALWAYS AS IDENTITY,
    source_transaction_item_id BIGINT NOT NULL,
    transaction_id            BIGINT NOT NULL,
    date_key                  INTEGER NOT NULL,
    product_key               INTEGER NOT NULL,
    payment_method_key        INTEGER NOT NULL,
    quantity                  SMALLINT NOT NULL,
    unit_price                NUMERIC(10, 2) NOT NULL,
    discount_amount           NUMERIC(10, 2) NOT NULL,
    gross_sales_amount        NUMERIC(12, 2) NOT NULL,
    net_sales_amount          NUMERIC(12, 2) NOT NULL,
    loaded_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_fact_cafeteria_sales
        PRIMARY KEY (cafeteria_sales_key),
    CONSTRAINT uq_fact_cafeteria_sales_source_item
        UNIQUE (source_transaction_item_id),
    CONSTRAINT fk_fact_cafeteria_sales_date
        FOREIGN KEY (date_key)
        REFERENCES dw.dim_date (date_key)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_fact_cafeteria_sales_product
        FOREIGN KEY (product_key)
        REFERENCES dw.dim_product (product_key)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_fact_cafeteria_sales_payment_method
        FOREIGN KEY (payment_method_key)
        REFERENCES dw.dim_payment_method (payment_method_key)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT chk_fact_cafeteria_sales_quantity
        CHECK (quantity > 0),
    CONSTRAINT chk_fact_cafeteria_sales_unit_price
        CHECK (unit_price >= 0),
    CONSTRAINT chk_fact_cafeteria_sales_discount
        CHECK (
            discount_amount >= 0
            AND discount_amount <= gross_sales_amount
        ),
    CONSTRAINT chk_fact_cafeteria_sales_gross
        CHECK (
            gross_sales_amount = quantity * unit_price
            AND gross_sales_amount >= 0
        ),
    CONSTRAINT chk_fact_cafeteria_sales_net
        CHECK (
            net_sales_amount = gross_sales_amount - discount_amount
            AND net_sales_amount >= 0
        )
);

CREATE INDEX idx_dim_product_category_key
    ON dw.dim_product (category_key);

CREATE INDEX idx_fact_cafeteria_sales_date_key
    ON dw.fact_cafeteria_sales (date_key);

CREATE INDEX idx_fact_cafeteria_sales_product_key
    ON dw.fact_cafeteria_sales (product_key);

CREATE INDEX idx_fact_cafeteria_sales_payment_method_key
    ON dw.fact_cafeteria_sales (payment_method_key);

CREATE INDEX idx_fact_cafeteria_sales_transaction_id
    ON dw.fact_cafeteria_sales (transaction_id);

COMMENT ON TABLE dw.fact_cafeteria_sales IS
    'Grain: one product line from one completed cafeteria transaction.';

COMMENT ON COLUMN dw.fact_cafeteria_sales.transaction_id IS
    'Degenerate dimension used to count complete transactions without a separate dimension table.';

CREATE VIEW dw.vw_cafeteria_sales AS
SELECT
    fact.cafeteria_sales_key,
    fact.transaction_id,
    date_dimension.full_date,
    date_dimension.day_of_week_number,
    date_dimension.day_name,
    date_dimension.month_number,
    date_dimension.month_name,
    date_dimension.year_number,
    category.category_name,
    product.product_name,
    payment.payment_method_name,
    payment.payment_group,
    fact.quantity,
    fact.unit_price,
    fact.discount_amount,
    fact.gross_sales_amount,
    fact.net_sales_amount
FROM dw.fact_cafeteria_sales AS fact
JOIN dw.dim_date AS date_dimension
    ON date_dimension.date_key = fact.date_key
JOIN dw.dim_product AS product
    ON product.product_key = fact.product_key
JOIN dw.dim_category AS category
    ON category.category_key = product.category_key
JOIN dw.dim_payment_method AS payment
    ON payment.payment_method_key = fact.payment_method_key;

COMMIT;
