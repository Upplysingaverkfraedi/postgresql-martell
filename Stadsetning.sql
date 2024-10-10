-- Finna allar staðsetningar sem tilheyra sjaldgæfustu staðsetningategundunum utan "The Seven Kingdoms"
WITH type_counts AS (
    -- Finna fjölda staðsetninga eftir staðsetningategund utan "The Seven Kingdoms"
    SELECT l.type, COUNT(l.gid) AS location_count
    FROM atlas.locations l
    JOIN atlas.kingdoms k ON l.gid = k.gid
    WHERE k.claimedby != 'The Seven Kingdoms'
    GROUP BY l.type
),
min_count AS (
    -- Finna minnsta fjölda staðsetninga fyrir staðsetningategundir
    SELECT MIN(location_count) AS min_count
    FROM type_counts
)
-- Sækja allar staðsetningar sem tilheyra tegundum með minnsta fjölda staðsetninga
SELECT l.name, l.type
FROM atlas.locations l
JOIN atlas.kingdoms k ON l.gid = k.gid
WHERE k.claimedby != 'The Seven Kingdoms'
AND l.type IN (
    -- Finna allar tegundir með fjölda sem er jafnt minnsta fjöldanum
    SELECT tc.type
    FROM type_counts tc
    JOIN min_count mc ON tc.location_count = mc.min_count
);
