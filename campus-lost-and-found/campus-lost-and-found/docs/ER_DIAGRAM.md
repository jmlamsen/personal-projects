# Entity-Relationship Diagram

```mermaid
erDiagram
    ITEM_CATEGORIES ||--o{ ITEMS : classifies
    ITEMS ||--o| REPORTS : described_by
    CAMPUS_LOCATIONS ||--o{ REPORTS : receives
    REPORTS ||--o{ CLAIMS : receives
    CLAIMANTS ||--o{ CLAIMS : submits

    ITEM_CATEGORIES {
        integer category_id PK
        varchar category_name UK
    }

    CAMPUS_LOCATIONS {
        integer location_id PK
        varchar location_name UK
        varchar building_name
        varchar floor_label
        varchar location_description
    }

    ITEMS {
        integer item_id PK
        integer category_id FK
        varchar item_name
        varchar primary_color
        varchar brand
        varchar public_description
        varchar distinguishing_feature
        timestamptz created_at
    }

    REPORTS {
        integer report_id PK
        integer item_id FK
        integer location_id FK
        varchar report_type
        date incident_date
        timestamptz reported_at
        varchar report_status
        varchar report_notes
    }

    CLAIMANTS {
        integer claimant_id PK
        varchar claimant_name
        varchar institutional_id UK
        varchar contact_email UK
        timestamptz created_at
    }

    CLAIMS {
        integer claim_id PK
        integer found_report_id FK
        varchar found_report_type
        integer claimant_id FK
        timestamptz filed_at
        varchar claim_status
        timestamptz decided_at
        varchar verification_notes
        timestamptz returned_at
    }
```

## Relationship notes

- One category can classify many items; each item has one category.
- An item can have zero or one report because `reports.item_id` is unique.
- One location can receive many reports; each report has one location.
- A found report can receive many claims; each claim belongs to one found report.
- One claimant can submit claims for different found reports.
- The database allows only one approved claim per found report.
- The `claims` composite foreign key requires the referenced report type to be `FOUND`.

