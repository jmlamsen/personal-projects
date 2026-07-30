# Data Dictionary

## Grain summary

| Table | One row represents |
|---|---|
| `oltp.categories` | One cafeteria product category |
| `oltp.products` | One sellable product |
| `oltp.payment_methods` | One accepted payment method |
| `oltp.transactions` | One customer checkout |
| `oltp.transaction_items` | One product line within a checkout |
| `dw.dim_category` | One source category prepared for analytics |
| `dw.dim_product` | One source product prepared for analytics |
| `dw.dim_payment_method` | One source payment method prepared for analytics |
| `dw.dim_date` | One calendar date |
| `dw.fact_cafeteria_sales` | One completed checkout product line |

## Operational schema

### `oltp.categories`

| Column | Type | Rules and meaning |
|---|---|---|
| `category_id` | `INTEGER` identity | Primary key |
| `category_name` | `VARCHAR(50)` | Required, unique, and not blank |
| `description` | `VARCHAR(200)` | Optional category explanation |
| `is_active` | `BOOLEAN` | Defaults to `TRUE` |

### `oltp.products`

| Column | Type | Rules and meaning |
|---|---|---|
| `product_id` | `INTEGER` identity | Primary key |
| `category_id` | `INTEGER` | Required foreign key to `categories` |
| `product_name` | `VARCHAR(100)` | Required and unique inside its category |
| `current_price` | `NUMERIC(10,2)` | Current menu price; must be positive |
| `is_available` | `BOOLEAN` | Current selling status |
| `created_at` | `TIMESTAMPTZ` | Record creation timestamp |

`current_price` is not used to recalculate an old sale. Historical revenue uses
`transaction_items.unit_price`.

### `oltp.payment_methods`

| Column | Type | Rules and meaning |
|---|---|---|
| `payment_method_id` | `INTEGER` identity | Primary key |
| `payment_method_name` | `VARCHAR(40)` | Required and unique |
| `payment_group` | `VARCHAR(10)` | Restricted to `CASH` or `DIGITAL` |
| `is_active` | `BOOLEAN` | Current acceptance status |

### `oltp.transactions`

| Column | Type | Rules and meaning |
|---|---|---|
| `transaction_id` | `BIGINT` identity | Primary key |
| `receipt_number` | `VARCHAR(20)` | Required unique business identifier |
| `sold_at` | `TIMESTAMPTZ` | Checkout timestamp |
| `payment_method_id` | `INTEGER` | Required foreign key to `payment_methods` |
| `transaction_status` | `VARCHAR(12)` | `COMPLETED` or `CANCELLED` |
| `created_at` | `TIMESTAMPTZ` | Record creation timestamp |

### `oltp.transaction_items`

| Column | Type | Rules and meaning |
|---|---|---|
| `transaction_item_id` | `BIGINT` identity | Primary key |
| `transaction_id` | `BIGINT` | Required foreign key to `transactions` |
| `product_id` | `INTEGER` | Required foreign key to `products` |
| `quantity` | `SMALLINT` | Must be greater than zero |
| `unit_price` | `NUMERIC(10,2)` | Price charged when the checkout occurred |
| `discount_amount` | `NUMERIC(10,2)` | Nonnegative line discount |

The pair `(transaction_id, product_id)` is unique. A discount cannot exceed
`quantity * unit_price`.

## Warehouse schema

Warehouse dimensions use surrogate keys for analytical joins and retain source
IDs for repeatable loading.

### `dw.dim_category`

| Column | Type | Rules and meaning |
|---|---|---|
| `category_key` | `INTEGER` identity | Warehouse primary key |
| `source_category_id` | `INTEGER` | Unique operational category ID |
| `category_name` | `VARCHAR(50)` | Analytical category label |
| `description` | `VARCHAR(200)` | Category explanation |
| `is_active` | `BOOLEAN` | Source activity status at load time |

### `dw.dim_product`

| Column | Type | Rules and meaning |
|---|---|---|
| `product_key` | `INTEGER` identity | Warehouse primary key |
| `source_product_id` | `INTEGER` | Unique operational product ID |
| `category_key` | `INTEGER` | Foreign key to `dim_category` |
| `product_name` | `VARCHAR(100)` | Analytical product label |
| `current_price` | `NUMERIC(10,2)` | Current source price at load time |
| `is_available` | `BOOLEAN` | Source availability at load time |

### `dw.dim_payment_method`

| Column | Type | Rules and meaning |
|---|---|---|
| `payment_method_key` | `INTEGER` identity | Warehouse primary key |
| `source_payment_method_id` | `INTEGER` | Unique operational payment ID |
| `payment_method_name` | `VARCHAR(40)` | Cash, GCash, Maya, or Debit Card |
| `payment_group` | `VARCHAR(10)` | `CASH` or `DIGITAL` |

### `dw.dim_date`

| Column | Type | Example or meaning |
|---|---|---|
| `date_key` | `INTEGER` | `20260731` in `YYYYMMDD` form |
| `full_date` | `DATE` | `2026-07-31` |
| `day_of_month` | `SMALLINT` | `31` |
| `day_of_week_number` | `SMALLINT` | ISO weekday: Monday `1`, Sunday `7` |
| `day_name` | `VARCHAR(9)` | `Friday` |
| `week_of_year` | `SMALLINT` | ISO week number |
| `month_number` | `SMALLINT` | `7` |
| `month_name` | `VARCHAR(9)` | `July` |
| `quarter_number` | `SMALLINT` | `3` |
| `year_number` | `SMALLINT` | `2026` |
| `is_weekend` | `BOOLEAN` | `TRUE` for Saturday or Sunday |

### `dw.fact_cafeteria_sales`

| Column | Type | Rules and meaning |
|---|---|---|
| `cafeteria_sales_key` | `BIGINT` identity | Warehouse primary key |
| `source_transaction_item_id` | `BIGINT` | Unique source line; prevents duplicate loading |
| `transaction_id` | `BIGINT` | Degenerate transaction identifier |
| `date_key` | `INTEGER` | Foreign key to `dim_date` |
| `product_key` | `INTEGER` | Foreign key to `dim_product` |
| `payment_method_key` | `INTEGER` | Foreign key to `dim_payment_method` |
| `quantity` | `SMALLINT` | Units on the completed sale line |
| `unit_price` | `NUMERIC(10,2)` | Historical charged price |
| `discount_amount` | `NUMERIC(10,2)` | Historical line discount |
| `gross_sales_amount` | `NUMERIC(12,2)` | `quantity * unit_price` |
| `net_sales_amount` | `NUMERIC(12,2)` | Gross amount minus discount |
| `loaded_at` | `TIMESTAMPTZ` | Most recent load timestamp |

The fact table intentionally has no foreign key to the operational transaction
table. A warehouse should retain its analytical identity independently of the
source system; `transaction_id` is kept as a degenerate identifier for distinct
checkout counts.

## Flat reporting view

`dw.vw_cafeteria_sales` joins the fact to every dimension and exposes readable
date, category, product, and payment labels. It is useful for exploration, but
the portfolio queries retain explicit joins so the model remains visible.
