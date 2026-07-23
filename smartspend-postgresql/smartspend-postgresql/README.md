# SmartSpend: Personal Expense Tracker

SmartSpend is a small PostgreSQL portfolio project that stores personal expenses,
organizes them into categories, and analyzes spending patterns using SQL.

The sample records use fictional amounts in Philippine pesos (PHP). No real
financial information is included.

## Project objectives

This project answers the following questions:

- How much was spent in total?
- What was the average expense?
- Which category had the highest spending?
- How much was spent each month?
- How much was spent on needs compared with wants?
- Which payment method was used most often?
- Did spending exceed the monthly category budget?
- How did monthly spending change over time?

## Main features

- Normalized two-table relational design
- Primary-key and foreign-key constraints
- Data validation with `NOT NULL`, `UNIQUE`, and `CHECK`
- Date filtering
- Category joins
- Aggregation with `SUM()`, `AVG()`, and `COUNT()`
- Grouping and sorting
- Monthly analysis with `DATE_TRUNC()`
- Conditional labels with `CASE`
- Missing-value handling with `COALESCE()`
- Monthly budget comparison
- Optional window-function analysis with `LAG()`
- Indexes for commonly filtered columns

## Repository structure

```text
smartspend-postgresql/
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_basic_analysis.sql
│   ├── 04_advanced_analysis.sql
│   └── 05_validation_tests.sql
├── docs/
│   └── ERD.md
├── results/
│   └── expected_results.md
├── .gitignore
├── LICENSE
└── README.md
```

## Database design

### `categories`

Stores each expense category, whether it is a need or want, and its monthly
budget.

| Column | Type | Description |
|---|---|---|
| `category_id` | Integer identity | Primary key |
| `category_name` | `VARCHAR(50)` | Unique category name |
| `category_type` | `VARCHAR(10)` | `Need` or `Want` |
| `monthly_budget` | `NUMERIC(10,2)` | Planned monthly limit |

### `expenses`

Stores individual expense transactions.

| Column | Type | Description |
|---|---|---|
| `expense_id` | Integer identity | Primary key |
| `category_id` | `INTEGER` | Foreign key to `categories` |
| `expense_date` | `DATE` | Transaction date |
| `description` | `VARCHAR(150)` | Expense description |
| `amount` | `NUMERIC(10,2)` | Positive expense amount |
| `payment_method` | `VARCHAR(20)` | How the expense was paid |

One category can have many expenses, while each expense belongs to one category.

See [docs/ERD.md](docs/ERD.md) for the entity-relationship diagram.

## Sample-data scope

The project includes:

- 5 categories
- 48 fictional transactions
- 6 months of data, from January through June 2026
- 4 payment methods
- Needs-versus-wants classification
- Monthly budgets for every category

## How to run the project

Use a PostgreSQL-compatible local installation or online SQL editor.

Run the files in this order:

1. `sql/01_create_tables.sql`
2. `sql/02_insert_sample_data.sql`
3. `sql/03_basic_analysis.sql`
4. `sql/04_advanced_analysis.sql`

The first file drops the project tables before recreating them, so running it
again resets the project.

The validation file contains intentionally invalid statements. They are
commented out by default:

5. `sql/05_validation_tests.sql`

Uncomment and run one validation test at a time. Each test should fail because
the database constraints are working.

## Important analysis queries

The project includes queries for:

- Complete joined transaction history
- Total and average spending
- Largest individual expense
- Date-range filtering
- Category-specific filtering
- Spending totals by category
- Highest-spending category
- Monthly spending totals
- Category spending by month
- Needs-versus-wants comparison
- Payment-method summary
- March 2026 budget report
- Expense-size classification
- Month-over-month spending change
- Category budget performance across all months

## Verified sample results

After loading the provided data, some expected results are:

| Metric | Result |
|---|---:|
| Total expenses | 48 |
| Total spending | PHP 30,771.00 |
| Average expense | PHP 641.06 |
| Highest-spending category | School |
| School spending | PHP 8,230.00 |
| Highest-spending month | June 2026 |
| June spending | PHP 7,379.00 |

More results are documented in
[results/expected_results.md](results/expected_results.md).

## Skills demonstrated

```sql
CREATE TABLE
DROP TABLE
INSERT INTO
SELECT
WHERE
BETWEEN
INNER JOIN
LEFT JOIN
SUM()
AVG()
COUNT()
ROUND()
GROUP BY
HAVING
ORDER BY
LIMIT
DATE_TRUNC()
TO_CHAR()
CASE
COALESCE()
NULLIF()
LAG()
```

Database concepts demonstrated:

- Primary keys
- Foreign keys
- One-to-many relationships
- Referential integrity
- Check constraints
- Unique constraints
- Transactions
- Indexes
- Common table expressions
- Window functions

## Suggested screenshots for the GitHub repository

Add a `screenshots` folder after running the project and include:

1. Successfully created tables
2. Joined expense records
3. Total-spending result
4. Spending by category
5. Monthly-spending result
6. Needs-versus-wants comparison
7. Budget-status report
8. Month-over-month analysis

Do not upload screenshots containing real financial information or account
details.

## Possible future improvements

- Add an `income` table
- Add savings goals
- Support multiple users
- Add recurring expenses
- Add merchant names
- Import transactions from CSV
- Add yearly budget reports
- Connect the database to a dashboard
- Build a small Python or web interface

## Portfolio explanation

> SmartSpend is a PostgreSQL personal expense tracker that organizes fictional
> transactions into spending categories. It uses relational tables, joins,
> date filtering, aggregation, grouping, conditional logic, and monthly budget
> comparisons to summarize spending and identify financial patterns.

## Limitations

- The dataset is fictional and intentionally small.
- Only one currency is used.
- Budgets are fixed and do not change by month.
- The project does not include authentication or multiple users.

## License

This project is available under the MIT License.
