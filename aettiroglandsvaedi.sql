-- Spurning 1
WITH kingdoms_houses AS (
    SELECT
        k.gid AS kingdom_id,
        h.id AS house_id,
        k.name AS kingdom_name,
        h.name AS house_name
    FROM
        got.houses h
    LEFT JOIN
        atlas.kingdoms k
    ON
        k.name = h.region
)
-- upserta
INSERT INTO martell.tables_mapping (kingdom_id, house_id)
SELECT kingdom_id, house_id
FROM kingdoms_houses
ON CONFLICT (house_id)
DO UPDATE
SET kingdom_id = EXCLUDED.kingdom_id;








-- Spurning 2
WITH location_house_mapping AS (
    SELECT
        l.gid AS location_id,
        h.id AS house_id,
        l.name AS location_name,  --ýta hér á kóðann til að fá upp réttu statement skipanir í keyrsluhnapp
        h.name AS house_name,
        h.region AS house_region,
        h.seats,
        h.titles,
        l.summary AS location_summary,
        CASE
            WHEN h.name ILIKE '%' || l.name || '%' AND
                 h.name ~* ('\m' || l.name || '\M') THEN 1
            WHEN EXISTS (
                SELECT 1
                FROM UNNEST(h.seats) AS seat
                WHERE seat ILIKE '%' || l.name || '%'
                AND seat ~* ('\m' || l.name || '\M')
            ) THEN 2
            WHEN EXISTS (
                SELECT 1
                FROM UNNEST(h.titles) AS title
                WHERE title ILIKE '%' || l.name || '%'
                AND title ~* ('\m' || l.name || '\M')
            ) THEN 3
            WHEN l.summary ILIKE '%' || h.name || '%' AND
                 l.summary ~* ('\m' || h.name || '\M') THEN 4
            ELSE 5
        END AS match_priority,
        COALESCE(
            (SELECT seat FROM UNNEST(h.seats) AS seat
             WHERE seat ILIKE '%' || l.name || '%'
             AND seat ~* ('\m' || l.name || '\M') LIMIT 1),
            (SELECT title FROM UNNEST(h.titles) AS title
             WHERE title ILIKE '%' || l.name || '%'
             AND title ~* ('\m' || l.name || '\M') LIMIT 1),
            h.name
        ) AS matched_detail
    FROM
        atlas.locations l
    LEFT JOIN
        got.houses h
    ON
        (h.name ILIKE '%' || l.name || '%' AND h.name ~* ('\m' || l.name || '\M'))
        OR EXISTS (
            SELECT 1
            FROM UNNEST(h.seats) AS seat
            WHERE seat ILIKE '%' || l.name || '%'
            AND seat ~* ('\m' || l.name || '\M')
        )
        OR EXISTS (
            SELECT 1
            FROM UNNEST(h.titles) AS title
            WHERE title ILIKE '%' || l.name || '%'
            AND title ~* ('\m' || l.name || '\M')
        )
        OR (l.summary ILIKE '%' || h.name || '%' AND l.summary ~* ('\m' || h.name || '\M'))
),
filterum AS (
    SELECT
        location_id,
        house_id,
        ROW_NUMBER() OVER (PARTITION BY location_id ORDER BY match_priority, house_name) AS row_num,
        ROW_NUMBER() OVER (PARTITION BY house_id ORDER BY match_priority, location_name) AS house_row_num
    FROM
        location_house_mapping
    WHERE match_priority < 5
)
-- Upsertum í töfluna
INSERT INTO martell.tables_mapping (house_id, location_id)
SELECT house_id, location_id
FROM filterum
WHERE row_num = 1 AND house_row_num = 1
ON CONFLICT (house_id)
DO UPDATE
SET location_id = EXCLUDED.location_id;


-- Sýnir einungis niðurstöður fyrir norðrið (e. The North)
WITH location_house_mapping AS (
    SELECT
        l.gid AS location_id, --ýta hér á kóðann til að fá upp réttu statement skipanir í keyrsluhnapp
        h.id AS house_id,
        l.name AS location_name,
        h.name AS house_name,
        h.region AS house_region,
        h.seats,
        h.titles,
        l.summary AS location_summary,
        CASE
            WHEN h.name ILIKE '%' || l.name || '%' AND
                 h.name ~* ('\m' || l.name || '\M') THEN 1
            WHEN EXISTS (
                SELECT 1
                FROM UNNEST(h.seats) AS seat
                WHERE seat ILIKE '%' || l.name || '%'
                AND seat ~* ('\m' || l.name || '\M')
            ) THEN 2
            WHEN EXISTS (
                SELECT 1
                FROM UNNEST(h.titles) AS title
                WHERE title ILIKE '%' || l.name || '%'
                AND title ~* ('\m' || l.name || '\M')
            ) THEN 3
            WHEN l.summary ILIKE '%' || h.name || '%' AND
                 l.summary ~* ('\m' || h.name || '\M') THEN 4
            ELSE 5
        END AS match_priority,
        COALESCE(
            (SELECT seat FROM UNNEST(h.seats) AS seat
             WHERE seat ILIKE '%' || l.name || '%'
             AND seat ~* ('\m' || l.name || '\M') LIMIT 1),
            (SELECT title FROM UNNEST(h.titles) AS title
             WHERE title ILIKE '%' || l.name || '%'
             AND title ~* ('\m' || l.name || '\M') LIMIT 1),
            h.name
        ) AS matched_detail
    FROM
        atlas.locations l
    LEFT JOIN
        got.houses h
    ON
        (h.name ILIKE '%' || l.name || '%' AND h.name ~* ('\m' || l.name || '\M'))
        OR EXISTS (
            SELECT 1
            FROM UNNEST(h.seats) AS seat
            WHERE seat ILIKE '%' || l.name || '%'
            AND seat ~* ('\m' || l.name || '\M')
        )
        OR EXISTS (
            SELECT 1
            FROM UNNEST(h.titles) AS title
            WHERE title ILIKE '%' || l.name || '%'
            AND title ~* ('\m' || l.name || '\M')
        )
        OR (l.summary ILIKE '%' || h.name || '%' AND l.summary ~* ('\m' || h.name || '\M'))
),
filterum AS (
    SELECT
        location_id,
        house_id,
        ROW_NUMBER() OVER (PARTITION BY location_id ORDER BY match_priority, house_name) AS row_num,
        ROW_NUMBER() OVER (PARTITION BY house_id ORDER BY match_priority, location_name) AS house_row_num
    FROM
        location_house_mapping
    WHERE match_priority < 5
)
SELECT *
FROM location_house_mapping
WHERE match_priority < 4
AND house_region = 'The North';







--Spurning 3
WITH northern_houses AS (
    SELECT
        id AS house_id,
        name AS house_name,
        UNNEST(sworn_members) AS member_id
    FROM
        got.houses
    WHERE
        region = 'The North'
),
northern_characters AS (
    SELECT
        nh.house_name,
        c.id AS character_id,
        c.name AS character_name,
        SPLIT_PART(c.name, ' ', ARRAY_LENGTH(REGEXP_SPLIT_TO_ARRAY(c.name, ' '), 1)) AS family
    FROM
        northern_houses nh
    LEFT JOIN
        got.characters c
    ON
        nh.member_id = c.id
),
missing_characters
    AS (
    SELECT
        nh.house_name,
        nh.member_id
    FROM
        northern_houses nh
    LEFT JOIN
        got.characters c
    ON
        nh.member_id = c.id
    WHERE
        c.id IS NULL
),
family_count AS (
    SELECT
        family,
        COUNT(DISTINCT character_id) AS member_count
    FROM
        northern_characters
    WHERE
        character_id IS NOT NULL
    GROUP BY
        family
    HAVING
        COUNT(DISTINCT character_id) > 5
)

SELECT
    family,
    member_count
FROM
    family_count
ORDER BY
    member_count DESC,
    family ASC;





