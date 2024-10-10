+Setning 1:
CREATE or replace VIEW martell.v_pov_characters_human_readable as
-Útskýring 1:
Býr til eða skiptir um útsýni (View) í gagnagrunni. Þetta verkefni er líka unnið sem CTE.

+Setning 2:
WITH pov_characters AS (
    SELECT DISTINCT cb.character_id
    FROM got.character_books cb
    WHERE cb.pov = TRUE
)

-Útskýring 2:
Skýrir CTE pov_characters svo það er bara tekið upplýsingar frá sjónarhorni hverns character í bókunum.

+Setning 3:
character_details AS (
    SELECT
        c.id AS character_id,
        COALESCE(NULLIF(split_part(array_to_string(c.titles, ','), ',', 1), ''), c.name) || ' ' || c.name AS full_name

-Útskýring 3:
Þetta notar gagnagrunnin "characters" til að finna upplýsingar. Þetta velur id dálki í characters og fer svo að nota COALESCE(NULLIF(...),c.name) til að gæta þess að þótt sumir eru ekki með titil þá mun nafnið þeirra koma í staðin.
NULLIF(split_part(...),'') kíkir hvort fyrsta titil hjá hverjum character er tómur strengur, ef svo gefur þetta NULL sem svar.
Split_part(array_to_string(c.titles,','),',',1): tekur fyrsta titil já character og bætir honum við nafnið á characterinum.
array_to_string(c.titles,',') breitir titles í string svo að fyrir kóðinn virki.
"|| ' ' || c.name AS full_name" Velur annaðhvort fyrir kóðan eða tóman streng og setir nafnið á characterinum fyrir aftan titil og skýrir það full_name.

+Setning 4:
substr(c.gender, 1, 1) as gender
-Útskýring 4: 
Tekur fyrsta stafin í gender sem er F eða M.

+Setning 5:
regexp_match(c.born, '(\d+) (AC|BC)') AS birth_info,
regexp_match(c.died, '(\d+) (AC|BC)') AS death_info
FROM got.characters c
-Útskýring 5:
Báðar setningarnar gera það sama nema fyrir fæðingu eða dauða.
Finnur einhverja tölur í born sem er fæðinar eða dauðadagur characterinar ár í dálkinum og tekur annaðhvor AC eða BC með.

+Setning 6:
c.father AS father_id,
c.mother AS mother_id,
c.spouse AS spouse_id,
((Með))
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
)
-Útskýring 6:
Nær í id á móður/faðir/maka characterana og breitir því í nafn á móður/faðir/maka þeirra.
"got.characters c" Þetta tekur allt úr characters töfluni og gefur því stittingu c
Svo er líka sýnt í view dálkum "character_id","full_name" og "gender" á hverjum character.

+Setning 7:
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
)
-Útskýring 7:
Hér er gert CTE character_dates þar sem skirfað er upp upplýsingar í 6 missmunandi dálkúm, character_id, full_name, gender, .father_name, mother_name, spouse_name.
Eftir það er "reiknað" út hvenær characterarnir voru fæddir og dóu út frá AC eða BC þar sem AC eru jákvæðar tölur og BC eru neikvæðar tölur.

+Setning 8:
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
)
-Útskýring 8:
Hér er gert CTE age_and_status og aftur teiknað upp margar mismunadi upplýsingar.
Annas er verið að reikna hversu gamal allir POV eru í bókinni, ef þeir dóu ekki er reikanð út frá að árið sé nú 300 AC.
Svo er skráð hvort characteranir eru lifandi eða dauðir með True lifandi og False Dauðir.

+Setning 9:
book_entries AS (
    SELECT
        cb.character_id,
        ARRAY_AGG(b.name ORDER BY b.released) AS book_list
    FROM got.character_books cb
    INNER JOIN got.books b ON b.id = cb.book_id
    WHERE cb.character_id IN (SELECT character_id FROM pov_characters)
    GROUP BY cb.character_id
)
-Útskýring 9:
Býr til CTE book_entries sem notar ARRAY_AGG() til að safna saman bókunum game-of-thorne og sorterar þeim eftir hvenær þær komu út með ORDER by b.released og nefnir það book_list.
Svo er gert From got.character_books til að setja charactera saman við bækurnar sýnar og Innerjoin til að setja saman id við bækurnar sem hjálpar til að leita að upplýsingum um characterana.
Að lokum er groupað saman alla POV_characterana..

+Setning 10:
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
-Útskýring 10:
Þetta setur saman allar upplýsingar sem hafa verið set saman í kóðanum og skírir hvern dálk lýsandi nafni.
Svo endar fyrsti partur kóðans með ;

+Setning 11:
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
-Útskýring 11:
Setir allar upplýsingar fram í töflu sem sérst þegar kóðin er keyrður fá martell.v_pov_characters_human_readable og raðar upplýingunum þannig að þeir sem eru lifandi eru efst í röð frá elsta til yngsta.
