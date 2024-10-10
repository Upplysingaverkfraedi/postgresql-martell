CREATE OR REPLACE VIEW martell.v_pov_characters_human_readable AS
WITH pov_characters AS (
    SELECT DISTINCT cb.character_id
    FROM got.character_books cb
    WHERE cb.pov = TRUE
),
character_details AS (
    SELECT
        c.id AS character_id,
        COALESCE(NULLIF(split_part(array_to_string(c.titles, ','), ',', 1), ''), c.name) || ' ' || c.name AS full_name,
        substr(c.gender, 1, 1) as gender,
        c.father AS father_id,
        c.mother AS mother_id,
        c.spouse AS spouse_id,
        regexp_match(c.born, '(\d+) (AC|BC)') AS birth_info,
        regexp_match(c.died, '(\d+) (AC|BC)') AS death_info
    FROM got.characters c
    INNER JOIN pov_characters pc ON c.id = pc.character_id
),
family_connections AS (
    SELECT
        cd.character_id,
        cd.full_name,
        cd.gender,
        f.name AS father_name,
        m.name AS mother_name,
        s.name AS spouse_name,
        cd.birth_info,
        cd.death_info
    FROM character_details cd
    LEFT JOIN got.characters f ON cd.father_id = f.id
    LEFT JOIN got.characters m ON cd.mother_id = m.id
    LEFT JOIN got.characters s ON cd.spouse_id = s.id

),

character_dates AS (
    SELECT
        fc.character_id,
        fc.full_name,
        fc.gender,
        fc.father_name,
        fc.mother_name,
        fc.spouse_name,
        CASE
            WHEN fc.birth_info[2] = 'AC' THEN fc.birth_info[1]::int WHEN fc.birth_info[2] = 'BC' THEN -fc.birth_info[1]::int
            ELSE NULL
        END AS year_of_birth,
        CASE
            WHEN fc.death_info[2] = 'AC' THEN fc.death_info[1]::int WHEN fc.death_info[2] = 'BC' THEN -fc.death_info[1]::int
            ELSE NULL
        END AS year_of_death
    FROM family_connections fc
),

age_and_status AS (
    SELECT
        cd.character_id,
        cd.full_name,
        cd.gender,
        cd.father_name,
        cd.mother_name,
        cd.spouse_name,
        cd.year_of_birth,
        cd.year_of_death,
        CASE
            WHEN cd.year_of_birth IS NOT NULL THEN COALESCE(cd.year_of_death, 300) - cd.year_of_birth
            ELSE NULL
        END AS character_age,
        CASE
            WHEN cd.year_of_death IS NULL THEN TRUE
            ELSE FALSE
        END AS is_alive
    FROM character_dates cd
),

book_entries AS (
    SELECT
        cb.character_id,
        ARRAY_AGG(b.name ORDER BY b.released) AS book_list
    FROM got.character_books cb
    INNER JOIN got.books b ON b.id = cb.book_id
    WHERE cb.character_id IN (SELECT character_id FROM pov_characters)
    GROUP BY cb.character_id
)


SELECT
    as_info.character_id,
    as_info.full_name,
    as_info.gender,
    as_info.father_name AS father,
    as_info.mother_name AS mother,
    as_info.spouse_name AS spouse,
    as_info.year_of_birth AS born,
    as_info.year_of_death AS died,
    as_info.character_age AS age,
    as_info.is_alive AS alive,
    COALESCE(be.book_list, ARRAY[]::TEXT[]) AS books
FROM age_and_status as_info
LEFT JOIN book_entries be ON as_info.character_id = be.character_id;



-- POV VIEW SELECT SKIPUN

SELECT
    full_name,
    gender,
    father,
    mother,
    spouse,
    born,
    died,
    age,
    alive,
    books
FROM
    martell.v_pov_characters_human_readable
ORDER BY
    alive DESC,
    age DESC;