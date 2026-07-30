# Verified Query Results

These results come from the deterministic synthetic dataset supplied with the
repository. They are reproducible after a clean build.

## Overall totals

| Fact rows | Completed transactions | Units sold | Net revenue |
|---:|---:|---:|---:|
| 681 | 273 | 766 | PHP 34,815.00 |

The 681 fact rows are product lines, not transactions. There are 408 additional
rows because many transactions contain more than one product.

## Revenue by month

| Year | Month | Completed transactions | Units sold | Net revenue |
|---:|---|---:|---:|---:|
| 2026 | April | 84 | 234 | PHP 10,575.00 |
| 2026 | May | 98 | 275 | PHP 12,570.00 |
| 2026 | June | 91 | 257 | PHP 11,670.00 |

May has the highest revenue and transaction count. The source period includes
only April 6 through April 30 and June 1 through June 28, so this comparison is
descriptive rather than a like-for-like full-month performance test.

## Category performance

| Category | Units sold | Transactions containing category | Net revenue |
|---|---:|---:|---:|
| Beverages | 217 | 204 | PHP 6,405.00 |
| Desserts | 158 | 136 | PHP 6,715.00 |
| Rice Meals | 156 | 137 | PHP 13,315.00 |
| Breakfast | 90 | 79 | PHP 4,475.00 |
| Snacks | 77 | 57 | PHP 1,525.00 |
| School Supplies | 68 | 68 | PHP 2,380.00 |

Beverages have the highest unit volume, while Rice Meals produce the most
revenue. This distinction shows why "most purchased" must be defined before
writing the query.

## Cash versus digital payments

| Payment group | Completed transactions | Units sold | Net revenue | Revenue share |
|---|---:|---:|---:|---:|
| Digital | 146 | 425 | PHP 18,820.00 | 54.06% |
| Cash | 127 | 341 | PHP 15,995.00 | 45.94% |

Payment counts use `COUNT(DISTINCT transaction_id)`. Counting fact rows would
overstate the number of checkouts.

## Average units per transaction

| Total units | Completed transactions | Average units |
|---:|---:|---:|
| 766 | 273 | 2.81 |

The result is calculated as total units divided by distinct completed
transactions.

## Sales by weekday

| ISO day | Weekday | Completed transactions | Units sold | Net revenue | Average transaction value |
|---:|---|---:|---:|---:|---:|
| 1 | Monday | 45 | 120 | PHP 5,450.00 | PHP 121.11 |
| 2 | Tuesday | 46 | 125 | PHP 5,660.00 | PHP 123.04 |
| 3 | Wednesday | 46 | 127 | PHP 5,695.00 | PHP 123.80 |
| 4 | Thursday | 46 | 123 | PHP 5,610.00 | PHP 121.96 |
| 5 | Friday | 45 | 152 | PHP 6,555.00 | PHP 145.67 |
| 6 | Saturday | 22 | 60 | PHP 2,970.00 | PHP 135.00 |
| 7 | Sunday | 23 | 59 | PHP 2,875.00 | PHP 125.00 |

Friday has the highest revenue, unit volume, and average transaction value in
the generated dataset.

## Top five products by revenue

| Product | Category | Units sold | Net revenue |
|---|---|---:|---:|
| Fried Chicken Rice | Rice Meals | 77 | PHP 7,300.00 |
| Vegetable Meal | Rice Meals | 66 | PHP 4,940.00 |
| Fruit Cup | Desserts | 79 | PHP 3,555.00 |
| Leche Flan Slice | Desserts | 79 | PHP 3,160.00 |
| Calamansi Juice | Beverages | 81 | PHP 2,835.00 |

## OLTP-to-warehouse reconciliation

| Month | OLTP net revenue | Warehouse net revenue | Status |
|---|---:|---:|---|
| 2026-04-01 | PHP 10,575.00 | PHP 10,575.00 | MATCH |
| 2026-05-01 | PHP 12,570.00 | PHP 12,570.00 | MATCH |
| 2026-06-01 | PHP 11,670.00 | PHP 11,670.00 | MATCH |

## Data-quality report

| Check | Actual | Expected | Status |
|---|---:|---:|---|
| Completed row reconciliation | 681 | 681 | PASS |
| Net revenue reconciliation | 34,815.00 | 34,815.00 | PASS |
| Duplicate source lines | 0 | 0 | PASS |
| Missing dimension lookups | 0 | 0 | PASS |
| Invalid fact measures | 0 | 0 | PASS |
| Cancelled lines loaded | 0 | 0 | PASS |
| Deterministic transaction count | 288 | 288 | PASS |
| Deterministic item count | 720 | 720 | PASS |
| Deterministic cancellation count | 15 | 15 | PASS |
| Complete 2026 calendar dimension | 365 | 365 | PASS |
