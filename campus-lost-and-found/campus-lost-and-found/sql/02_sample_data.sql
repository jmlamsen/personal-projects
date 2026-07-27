/*
    Campus Lost-and-Found Database
    File: 02_sample_data.sql

    Every person and event below is fictional.
    This file is rerunnable: it clears and reloads the project tables.
*/

BEGIN;

TRUNCATE TABLE
    claims,
    claimants,
    reports,
    items,
    campus_locations,
    item_categories
RESTART IDENTITY;

-- Category IDs are generated as 1 through 9 in this order.
INSERT INTO item_categories (category_name)
VALUES
    ('Electronics'),
    ('Identification Cards'),
    ('Keys'),
    ('Bags'),
    ('Books'),
    ('Clothing'),
    ('Drinkware'),
    ('School Supplies'),
    ('Umbrellas');

-- Location IDs are generated as 1 through 6 in this order.
INSERT INTO campus_locations (
    location_name,
    building_name,
    floor_label,
    location_description
)
VALUES
    (
        'Main Library',
        'Academic Resource Center',
        'Ground Floor',
        'Reading rooms, circulation desk, and study tables'
    ),
    (
        'Engineering Laboratory',
        'Engineering Building',
        'Second Floor',
        'Computer, electronics, and fabrication laboratories'
    ),
    (
        'Student Cafeteria',
        'Student Center',
        'Ground Floor',
        'Dining area and nearby outdoor tables'
    ),
    (
        'University Gymnasium',
        'Sports Complex',
        'Ground Floor',
        'Bleachers, court, and changing-room entrance'
    ),
    (
        'Registrar Lobby',
        'Administration Building',
        'Ground Floor',
        'Waiting area outside the registrar counters'
    ),
    (
        'Campus Chapel',
        'Chapel Building',
        NULL,
        'Nave, entrance, and covered walkway'
    );

/*
    Items 1-7 describe LOST reports.
    Items 8-16 describe FOUND reports.
    distinguishing_feature is private verification data and should not appear
    in public-facing query results.
*/
INSERT INTO items (
    category_id,
    item_name,
    primary_color,
    brand,
    public_description,
    distinguishing_feature,
    created_at
)
VALUES
    (
        7,
        'Insulated water bottle',
        'Blue',
        'AquaPeak',
        'A 750 mL stainless-steel bottle',
        'Small crescent-shaped dent near the base',
        '2026-06-28 18:30:00+08'
    ),
    (
        1,
        'Scientific calculator',
        'Black',
        'CalcuPro',
        'A scientific calculator with a protective cover',
        'Owner initials written under the battery cover',
        '2026-07-02 15:30:00+08'
    ),
    (
        9,
        'Folding umbrella',
        'Red',
        'RainGuard',
        'A compact automatic umbrella',
        'One spoke repaired with black thread',
        '2026-07-03 16:00:00+08'
    ),
    (
        4,
        'Backpack',
        'Black',
        'TrailBox',
        'A medium backpack with a laptop compartment',
        'Green keychain inside the front pocket',
        '2026-07-05 18:00:00+08'
    ),
    (
        1,
        'USB flash drive',
        'Silver',
        'DataKey',
        'A 32 GB metal flash drive',
        'Tiny blue sticker on the reverse side',
        '2026-07-07 15:00:00+08'
    ),
    (
        2,
        'Student identification card',
        'White',
        NULL,
        'A plastic campus identification card',
        'Fictional institutional ID 2026-0417',
        '2026-07-08 10:15:00+08'
    ),
    (
        3,
        'Key ring',
        'Silver',
        NULL,
        'Three keys attached to a round ring',
        'Small wooden chapel charm',
        '2026-07-10 20:00:00+08'
    ),
    (
        7,
        'Insulated water bottle',
        'Blue',
        'AquaPeak',
        'A blue 750 mL bottle recovered near a table',
        'Crescent-shaped dent near the base',
        '2026-06-29 09:00:00+08'
    ),
    (
        1,
        'Scientific calculator',
        'Black',
        'CalcuPro',
        'A black calculator with a sliding cover',
        'Faded initials under the battery cover',
        '2026-07-02 17:30:00+08'
    ),
    (
        9,
        'Folding umbrella',
        'Red',
        'StormMate',
        'A red compact umbrella',
        'White tape around one section of the handle',
        '2026-07-04 08:00:00+08'
    ),
    (
        4,
        'Laptop backpack',
        'Black',
        'UrbanCarry',
        'A black backpack with two main compartments',
        'Orange lining inside the main compartment',
        '2026-07-06 14:00:00+08'
    ),
    (
        1,
        'Wireless mouse',
        'Silver',
        'ClickGo',
        'A compact wireless mouse without its receiver',
        'Scratch shaped like the letter V',
        '2026-07-08 09:30:00+08'
    ),
    (
        1,
        'Wireless earphones',
        'White',
        'SoundPod',
        'White earphones inside a charging case',
        'Blue ink mark underneath the case',
        '2026-07-09 11:30:00+08'
    ),
    (
        8,
        'Spiral notebook',
        'Yellow',
        'NoteWorks',
        'An A5 ruled notebook',
        'Small astronomy drawing on the first page',
        '2026-07-11 16:00:00+08'
    ),
    (
        6,
        'Hooded jacket',
        'Gray',
        'Northline',
        'A light gray zip-up hoodie',
        'Loose stitch on the right cuff',
        '2026-07-13 08:00:00+08'
    ),
    (
        3,
        'Key ring',
        'Silver',
        NULL,
        'Two keys attached to a rectangular ring',
        'Small metal number 18 tag',
        '2026-07-10 19:00:00+08'
    );

/*
    Main Library and Student Cafeteria each receive two LOST reports. This
    intentional tie tests whether the ranking query returns both locations.
*/
INSERT INTO reports (
    item_id,
    location_id,
    report_type,
    incident_date,
    reported_at,
    report_status,
    report_notes
)
VALUES
    (
        1, 1, 'LOST', '2026-06-28', '2026-06-28 18:30:00+08',
        'RESOLVED', 'Last seen at study table L-14.'
    ),
    (
        2, 1, 'LOST', '2026-07-02', '2026-07-02 15:30:00+08',
        'MATCHED', 'Last used in the quiet study area.'
    ),
    (
        3, 3, 'LOST', '2026-07-03', '2026-07-03 16:00:00+08',
        'OPEN', 'Left near the east-side lunch tables.'
    ),
    (
        4, 3, 'LOST', '2026-07-05', '2026-07-05 18:00:00+08',
        'OPEN', 'Last seen under a dining table.'
    ),
    (
        5, 2, 'LOST', '2026-07-07', '2026-07-07 15:00:00+08',
        'OPEN', 'Possibly left beside workstation E-06.'
    ),
    (
        6, 5, 'LOST', '2026-07-08', '2026-07-08 10:15:00+08',
        'OPEN', 'Missing after a visit to the registrar.'
    ),
    (
        7, 6, 'LOST', '2026-07-10', '2026-07-10 20:00:00+08',
        'MATCHED', 'Last used near the covered walkway.'
    ),
    (
        8, 3, 'FOUND', '2026-06-29', '2026-06-29 09:00:00+08',
        'RESOLVED', 'Turned in by cafeteria staff.'
    ),
    (
        9, 1, 'FOUND', '2026-07-02', '2026-07-02 17:30:00+08',
        'MATCHED', 'Found beneath a library chair.'
    ),
    (
        10, 4, 'FOUND', '2026-07-04', '2026-07-04 08:00:00+08',
        'OPEN', 'Found beside the west bleachers.'
    ),
    (
        11, 3, 'FOUND', '2026-07-06', '2026-07-06 14:00:00+08',
        'OPEN', 'Submitted to the cafeteria service desk.'
    ),
    (
        12, 2, 'FOUND', '2026-07-08', '2026-07-08 09:30:00+08',
        'OPEN', 'Found near a laboratory computer.'
    ),
    (
        13, 5, 'FOUND', '2026-07-09', '2026-07-09 11:30:00+08',
        'RESOLVED', 'Turned in at the registrar information desk.'
    ),
    (
        14, 1, 'FOUND', '2026-07-11', '2026-07-11 16:00:00+08',
        'OPEN', 'Found in the periodicals section.'
    ),
    (
        15, 4, 'FOUND', '2026-07-12', '2026-07-13 08:00:00+08',
        'OPEN', 'Found after an evening sports event.'
    ),
    (
        16, 6, 'FOUND', '2026-07-10', '2026-07-10 19:00:00+08',
        'MATCHED', 'Found on a bench near the chapel entrance.'
    );

INSERT INTO claimants (
    claimant_name,
    institutional_id,
    contact_email,
    created_at
)
VALUES
    (
        'Ana Reyes',
        '2026-0001',
        'ana.reyes@example.edu',
        '2026-06-30 08:30:00+08'
    ),
    (
        'Marco Santos',
        '2026-0002',
        'marco.santos@example.edu',
        '2026-07-03 08:45:00+08'
    ),
    (
        'Liza Cruz',
        '2025-0148',
        'liza.cruz@example.edu',
        '2026-07-05 09:30:00+08'
    ),
    (
        'Paolo Garcia',
        '2024-0203',
        'paolo.garcia@example.edu',
        '2026-07-09 09:00:00+08'
    ),
    (
        'Nina Flores',
        '2026-0112',
        'nina.flores@example.edu',
        '2026-07-10 13:00:00+08'
    );

/*
    Claim status mix:
    - APPROVED: found reports 8 and 13
    - PENDING: found reports 9 and 16
    - REJECTED: found reports 10 and 12
*/
INSERT INTO claims (
    found_report_id,
    claimant_id,
    filed_at,
    claim_status,
    decided_at,
    verification_notes,
    returned_at
)
VALUES
    (
        8,
        1,
        '2026-06-30 08:30:00+08',
        'APPROVED',
        '2026-07-01 10:00:00+08',
        'Private description agreed with the item record.',
        '2026-07-01 11:00:00+08'
    ),
    (
        9,
        2,
        '2026-07-03 08:45:00+08',
        'PENDING',
        NULL,
        'Waiting for staff review.',
        NULL
    ),
    (
        10,
        3,
        '2026-07-05 09:30:00+08',
        'REJECTED',
        '2026-07-05 15:00:00+08',
        'Private description did not match.',
        NULL
    ),
    (
        12,
        4,
        '2026-07-09 09:00:00+08',
        'REJECTED',
        '2026-07-10 10:00:00+08',
        'Claimant described a different device.',
        NULL
    ),
    (
        13,
        5,
        '2026-07-10 13:00:00+08',
        'APPROVED',
        '2026-07-11 09:00:00+08',
        'Pairing name and private case marking were verified.',
        '2026-07-11 09:30:00+08'
    ),
    (
        16,
        4,
        '2026-07-11 10:30:00+08',
        'PENDING',
        NULL,
        'Waiting for a complete description of the keys.',
        NULL
    );

COMMIT;

