# Campus Lost-and-Found Database

A small PostgreSQL portfolio project for recording lost and found property across a campus. It tracks item descriptions, report locations, ownership claims, claim decisions, and possible lost-and-found matches.

The database suggests candidate matches using category and color. It does **not** treat those matches as proof of ownership; a person must still verify private item details before approving a claim.

## Questions answered

The analysis queries answer:

1. Which found items are still unclaimed?
2. How many lost and found reports came from each campus location?
3. Which location has the highest number of lost-item reports?
4. Which open lost and found reports may describe the same item?
5. How many days did a found item remain unclaimed?
6. How are claims distributed by status?
7. Which items were approved and returned?

## Database design

| Table | Purpose |
|---|---|
| `item_categories` | Provides consistent categories such as Electronics and Keys |
| `campus_locations` | Stores buildings and campus areas |
| `items` | Stores public descriptions and private distinguishing features |
| `reports` | Records whether an item was lost or found, where, and when |
| `claimants` | Stores fictional people who submit ownership claims |
| `claims` | Connects claimants to found reports and records claim decisions |

See the [entity-relationship diagram](docs/ER_DIAGRAM.md) and [data dictionary](docs/DATA_DICTIONARY.md) for details.

## Important business rules

- A report is either `LOST` or `FOUND`.
- Each item record can belong to at most one report.
- A claim can reference only a `FOUND` report.
- The same claimant cannot claim the same report twice.
- A found report can have several claims, but only one can be `APPROVED`.
- An approved claim must include a decision timestamp.
- Only approved claims can include a return timestamp.
- A pending or rejected claim does not make an item claimed.
- Category-and-color matches are suggestions, not ownership decisions.

The database enforces these rules with primary keys, foreign keys, `UNIQUE` constraints, `CHECK` constraints, a composite foreign key, and a PostgreSQL partial unique index.

## Repository structure

```text
campus-lost-and-found/
├── README.md
├── LICENSE
├── docs/
│   ├── DATA_DICTIONARY.md
│   ├── ER_DIAGRAM.md
│   └── EXPECTED_RESULTS.md
└── sql/
    ├── 01_schema.sql
    ├── 02_sample_data.sql
    ├── 03_analysis_queries.sql
    ├── 04_indexes.sql
    └── 05_validation_tests.sql
```

## Requirements

- PostgreSQL 12 or newer
- A PostgreSQL client such as `psql`, pgAdmin, DBeaver, or an online PostgreSQL IDE

The SQL uses PostgreSQL features such as `FILTER`, window functions, expression indexes, and partial indexes. It is not intended for MySQL or SQLite without changes.

## How to run the project

Create a dedicated database:

```sql
CREATE DATABASE campus_lost_found;
```

Run these files in numerical order:

1. `sql/01_schema.sql`
2. `sql/02_sample_data.sql`
3. `sql/03_analysis_queries.sql`
4. `sql/04_indexes.sql`

Run `sql/05_validation_tests.sql` last. Its intentional invalid inserts confirm that the constraints work. The file uses a transaction and ends with `ROLLBACK`, so it does not change the sample data.

With `psql`, run:

```bash
psql -U postgres -d campus_lost_found -f sql/01_schema.sql
psql -U postgres -d campus_lost_found -f sql/02_sample_data.sql
psql -U postgres -d campus_lost_found -f sql/03_analysis_queries.sql
psql -U postgres -d campus_lost_found -f sql/04_indexes.sql
psql -U postgres -d campus_lost_found -f sql/05_validation_tests.sql
```

In an online PostgreSQL IDE, copy and run each file separately in the same database session. The sample-data file clears and reloads the six project tables so its results stay reproducible.

## Sample-data coverage

The fictional dataset contains:

- 9 item categories
- 6 campus locations
- 16 items and reports
- 7 lost reports and 9 found reports
- 5 claimants
- 2 approved, 2 pending, and 2 rejected claims
- 7 currently unclaimed found reports
- 5 category-and-color candidate matches
- A tie between two locations for the most lost reports

The expected outputs are documented in [docs/EXPECTED_RESULTS.md](docs/EXPECTED_RESULTS.md).

## PostgreSQL skills demonstrated

- Relational database design
- Primary and foreign keys
- Composite foreign keys
- `CHECK` and `UNIQUE` constraints
- One-to-many relationships
- Inner and outer joins
- Correlated `NOT EXISTS`
- Conditional aggregation with `FILTER`
- Common table expressions
- `DENSE_RANK()` for tied results
- Date arithmetic
- Expression and partial indexes
- Transaction-based integrity testing

## Privacy and responsible use

All names, institutional IDs, email addresses, brands, item details, and events in this repository are fictional.

In a real deployment:

- Do not expose `distinguishing_feature` or `verification_notes` in public results.
- Restrict access to claimant contact details.
- Define a retention policy for personal information.
- Verify ownership manually before approving a claim.
- Do not publish exact private evidence supplied by a claimant.

## Limitations

The matching query uses only category, normalized color, and a 30-day date window. Two unrelated items can satisfy those conditions, while the same item can be missed if a reporter enters a different color or category. The output should therefore be called a **candidate match**, never a confirmed match.

Possible future improvements include staff accounts, an audit log, image storage, configurable matching weights, claim evidence records, and automatic notifications.

