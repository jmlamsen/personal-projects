# Expected Results

These results are based on the fictional sample records in
`sql/02_insert_sample_data.sql`.

## Dataset checks

| Check | Expected value |
|---|---:|
| Number of categories | 5 |
| Number of expenses | 48 |
| Total spending | PHP 30,771.00 |
| Average expense | PHP 641.06 |
| Largest individual expense | PHP 2,200.00 |
| Largest expense description | Capstone project materials |

## Spending by category

| Rank | Category | Total |
|---:|---|---:|
| 1 | School | PHP 8,230.00 |
| 2 | Food | PHP 7,985.00 |
| 3 | Internet | PHP 5,947.00 |
| 4 | Entertainment | PHP 4,479.00 |
| 5 | Transportation | PHP 4,130.00 |

## Spending by month

| Month | Total |
|---|---:|
| January 2026 | PHP 2,764.00 |
| February 2026 | PHP 4,130.00 |
| March 2026 | PHP 6,999.00 |
| April 2026 | PHP 4,390.00 |
| May 2026 | PHP 5,109.00 |
| June 2026 | PHP 7,379.00 |

June 2026 has the highest monthly spending.

## Needs versus wants

| Category type | Total | Percentage |
|---|---:|---:|
| Need | PHP 26,292.00 | 85.44% |
| Want | PHP 4,479.00 | 14.56% |

## Payment-method summary

| Payment method | Total | Transactions |
|---|---:|---:|
| Bank Transfer | PHP 10,497.00 | 7 |
| E-Wallet | PHP 9,870.00 | 15 |
| Cash | PHP 5,615.00 | 19 |
| Card | PHP 4,789.00 | 7 |

Cash has the highest transaction count, while bank transfers account for the
highest total amount.

## March 2026 budget report

| Category | Budget | Spent | Remaining | Status |
|---|---:|---:|---:|---|
| Entertainment | PHP 1,200.00 | PHP 1,380.00 | PHP -180.00 | Over Budget |
| School | PHP 3,000.00 | PHP 2,060.00 | PHP 940.00 | Within Budget |
| Internet | PHP 1,600.00 | PHP 1,499.00 | PHP 101.00 | Within Budget |
| Food | PHP 4,500.00 | PHP 1,400.00 | PHP 3,100.00 | Within Budget |
| Transportation | PHP 2,200.00 | PHP 660.00 | PHP 1,540.00 | Within Budget |

The Entertainment category exceeded its March budget by PHP 180.00.

## Example findings

1. School was the highest-spending category because of textbooks, electronics
   components, and capstone materials.
2. June had the highest monthly spending at PHP 7,379.00.
3. Needs represented 85.44% of all spending.
4. Cash was used for the largest number of transactions, but bank transfers
   had the highest total value.
5. Entertainment exceeded its budget in March because of the music festival
   ticket.
