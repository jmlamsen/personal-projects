# Expected Results

These reference results use the fictional sample data in `sql/02_sample_data.sql`.

## Dataset checks

| Measure | Expected value |
|---|---:|
| Categories | 9 |
| Locations | 6 |
| Items | 16 |
| Reports | 16 |
| Lost reports | 7 |
| Found reports | 9 |
| Claimants | 5 |
| Claims | 6 |
| Unclaimed found reports | 7 |
| Candidate matches | 5 |

## Query 1: Unclaimed found reports

Expected report IDs:

```text
9, 10, 11, 12, 14, 15, 16
```

Reports 9 and 16 have pending claims. Reports 10 and 12 have rejected claims. They remain unclaimed because none has an approved claim.

## Query 2: Reports by location

| Location | Total | Lost | Found |
|---|---:|---:|---:|
| Main Library | 4 | 2 | 2 |
| Student Cafeteria | 4 | 2 | 2 |
| Campus Chapel | 2 | 1 | 1 |
| Engineering Laboratory | 2 | 1 | 1 |
| Registrar Lobby | 2 | 1 | 1 |
| University Gymnasium | 2 | 0 | 2 |

## Query 3: Location with the most lost reports

Both tied locations must appear:

| Location | Lost-item count |
|---|---:|
| Main Library | 2 |
| Student Cafeteria | 2 |

## Query 4: Candidate matches

| Lost report | Found report | Basis |
|---:|---:|---|
| 2 | 9 | Electronics + Black |
| 3 | 10 | Umbrellas + Red |
| 4 | 11 | Bags + Black |
| 5 | 12 | Electronics + Silver |
| 7 | 16 | Keys + Silver |

The pair `5 → 12` compares a USB flash drive with a wireless mouse. Its presence is intentional: it proves that category and color can produce a false candidate.

## Query 5: Days unclaimed

This query uses `CURRENT_DATE`, so unclaimed values increase over time. On **2026-07-27**, the expected values are:

| Found report | Ownership status | Days unclaimed |
|---:|---|---:|
| 9 | UNCLAIMED | 25 |
| 10 | UNCLAIMED | 23 |
| 11 | UNCLAIMED | 21 |
| 12 | UNCLAIMED | 19 |
| 16 | UNCLAIMED | 17 |
| 14 | UNCLAIMED | 16 |
| 15 | UNCLAIMED | 15 |
| 8 | CLAIMED | 2 |
| 13 | CLAIMED | 2 |

For claimed items, the count stops on the approval date.

## Query 6: Claim status summary

| Status | Count |
|---|---:|
| PENDING | 2 |
| APPROVED | 2 |
| REJECTED | 2 |
| CANCELLED | 0 |

## Validation file

`sql/05_validation_tests.sql` should print ten `PASS` notices and finish with `ROLLBACK`.

