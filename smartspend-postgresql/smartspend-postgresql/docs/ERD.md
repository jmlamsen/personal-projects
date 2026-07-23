# Entity-Relationship Diagram

```mermaid
erDiagram
    CATEGORIES ||--o{ EXPENSES : contains

    CATEGORIES {
        integer category_id PK
        varchar category_name UK
        varchar category_type
        numeric monthly_budget
    }

    EXPENSES {
        integer expense_id PK
        integer category_id FK
        date expense_date
        varchar description
        numeric amount
        varchar payment_method
    }
```

## Relationship explanation

- One category can contain zero or many expenses.
- Every expense must belong to exactly one valid category.
- `expenses.category_id` references `categories.category_id`.
- A category cannot be deleted while expenses still reference it because the
  foreign key uses `ON DELETE RESTRICT`.
