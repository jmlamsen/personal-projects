# Data Dictionary

## `item_categories`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `category_id` | `INTEGER` | Primary key, identity | Category identifier |
| `category_name` | `VARCHAR(80)` | Required, unique, nonblank | Controlled item category |

## `campus_locations`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `location_id` | `INTEGER` | Primary key, identity | Location identifier |
| `location_name` | `VARCHAR(120)` | Required, unique, nonblank | Public location name |
| `building_name` | `VARCHAR(120)` | Optional, nonblank when supplied | Building containing the location |
| `floor_label` | `VARCHAR(40)` | Optional, nonblank when supplied | Floor or level |
| `location_description` | `VARCHAR(300)` | Optional | Short description of the area |

## `items`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `item_id` | `INTEGER` | Primary key, identity | Item identifier |
| `category_id` | `INTEGER` | Required foreign key | Item category |
| `item_name` | `VARCHAR(120)` | Required, nonblank | General item name |
| `primary_color` | `VARCHAR(50)` | Required, nonblank | Main reported color |
| `brand` | `VARCHAR(80)` | Optional, nonblank when supplied | Reported brand |
| `public_description` | `VARCHAR(500)` | Optional | Description safe to show publicly |
| `distinguishing_feature` | `VARCHAR(500)` | Optional, private | Detail used during ownership verification |
| `created_at` | `TIMESTAMPTZ` | Required, current timestamp by default | Record creation time |

## `reports`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `report_id` | `INTEGER` | Primary key, identity | Report identifier |
| `item_id` | `INTEGER` | Required, unique foreign key | Item described by the report |
| `location_id` | `INTEGER` | Required foreign key | Campus location connected to the incident |
| `report_type` | `VARCHAR(5)` | Required; `LOST` or `FOUND` | Report direction |
| `incident_date` | `DATE` | Required, not later than report date | Date the loss or discovery occurred |
| `reported_at` | `TIMESTAMPTZ` | Required, current timestamp by default | Time entered into the database |
| `report_status` | `VARCHAR(10)` | `OPEN`, `MATCHED`, `RESOLVED`, or `CLOSED` | Report workflow state |
| `report_notes` | `VARCHAR(500)` | Optional, nonblank when supplied | Staff or reporting context |

`UNIQUE (report_id, report_type)` is a candidate key used by the claims composite foreign key.

## `claimants`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `claimant_id` | `INTEGER` | Primary key, identity | Claimant identifier |
| `claimant_name` | `VARCHAR(120)` | Required, nonblank | Claimant name |
| `institutional_id` | `VARCHAR(40)` | Required, unique, nonblank | Campus identifier |
| `contact_email` | `VARCHAR(160)` | Required, unique, contains `@` | Contact address |
| `created_at` | `TIMESTAMPTZ` | Required, current timestamp by default | Record creation time |

## `claims`

| Column | Type | Rules | Meaning |
|---|---|---|---|
| `claim_id` | `INTEGER` | Primary key, identity | Claim identifier |
| `found_report_id` | `INTEGER` | Required composite foreign key | Report being claimed |
| `found_report_type` | `VARCHAR(5)` | Required, fixed to `FOUND` | Discriminator that blocks claims against lost reports |
| `claimant_id` | `INTEGER` | Required foreign key | Person filing the claim |
| `filed_at` | `TIMESTAMPTZ` | Required, current timestamp by default | Claim submission time |
| `claim_status` | `VARCHAR(10)` | `PENDING`, `APPROVED`, `REJECTED`, or `CANCELLED` | Claim workflow state |
| `decided_at` | `TIMESTAMPTZ` | Required after a decision | Decision time |
| `verification_notes` | `VARCHAR(500)` | Optional, private | Staff verification record |
| `returned_at` | `TIMESTAMPTZ` | Optional; approved claims only | Item return time |

The pair `(found_report_id, claimant_id)` is unique. A partial unique index allows only one `APPROVED` row for each `found_report_id`.

