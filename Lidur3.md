## 3 Liður

### 1. Flatarmál konungsríkja `Flatarmal.sql`

Markmið verkefnisinns er: 
1. Búa til fallið `<teymi>.get_kingdom_size(int kingdom_id)` sem að tekur inn `kingdom_id` og skilar flatarmáli konungsríkis út frá landfræðilegum gögnum í ferkílómetrum
2. Finna lausn á ólöglegum gildum `kingdom_id` með því að kasta villu.
3. Gera SQL fyrirspurn sem að finnur heildarflatarmál þriðja stærsta konungsríkisinns.

#### 1. Fallið `<teymi>.get_kingdom_size(int kingdom_id)`

Þessi hluti býr til eða uppfærir fall sem reiknar flatarmál konungsríkis út frá gefnum kingdom_id. Fallið skilar niðurstöðunni í ferkílómetrum með því að nota PostGIS föll til að reikna flatarmál landfræðilegra gagna.

```sql
CREATE OR REPLACE FUNCTION martell.get_kingdom_size(kingdom_id integer)
RETURNS integer AS $$
DECLARE
  -- Yfirlýsing á breytunni 'area_sq_km' sem geymir flatarmál í ferkílómetrum
  area_sq_km integer;
BEGIN
  -- Reikna flatarmál konungsríkisins í ferkílómetrum.
  -- Hér er landfræðileg gögn (geog) fengin úr dálkinum 'geog' í töflunni atlas.kingdoms.
  -- ST_Area reiknar flatarmál í fermetrum, deilt með 1.000.000 til að fá niðurstöðuna í km².
  -- ROUND er notað til að rúna niðurstöðuna og fjarlægja aukastafi.
  SELECT ROUND(ST_Area(geog::geography) / 1000000)
  INTO area_sq_km
  FROM atlas.kingdoms
  WHERE gid = kingdom_id; -- Leitar að konungsríkinu eftir 'gid' sem samsvarar gefnu 'kingdom_id'.
```
- **`CREATE OR REPLACE FUNCTION martell.get_kingdom_size`**: Þetta býr til eða uppfærir fall sem heitir `get_kingdom_size` í schema `martell`. Það tekur einn k`ingdom_id` af tegundinni `integer (heiltölu)` og skilar útkomunni sem `integer`.
- **`DECLARE`**: Yfirlýsing á breytunni `area_sq_km`, sem mun geyma flatarmálið í ferkílómetrum.
- **`SELECT ROUND(ST_Area(geog::geography) / 1000000) INTO area_sq_km`**: Þetta sækir flatarmálið úr dálkinum `geog` í töflunni `atlas.kingdoms` fyrir gefið `kingdom_id`. Flatarmálið er reiknað með PostGIS fallinu `ST_Area`, sem reiknar flatarmál út frá landfræðilegum gögnunum. Útkoman er í fermetrum, þannig að við deilum með 1.000.000 til að fá flatarmálið í ferkílómetrum. `ROUND` er notað til að rúna niðurstöðuna og fjarlægja aukastafi.

#### 2. Lausn við ólöglegum gildum á `kingdom_id`
```sql
-- 2. Lausn við ólöglegu gildi á kingdom_id
-- Athugar hvort breytan 'area_sq_km' sé NULL (þ.e. engin niðurstaða fannst fyrir gefið 'kingdom_id').
IF area_sq_km IS NULL THEN
    -- Ef 'kingdom_id' er ekki gilt, kasta villu með skilaboðum á íslensku.
    RAISE EXCEPTION 'Ógilt kingdom_id: %', kingdom_id;
END IF;
```
- `IF area_sq_km IS NULL THEN`: Þetta athugar hvort að engin niðurstaða fannst fyrir gefið `kingdom_id`(þ.e. konungsríkið er ekki til eða hefur ekki landfræðileg gögn)
- `RAISE EXCEPTION`: Ef `area_sq_km` er `NULL`, kastar fallið villu með skilaboðunum „Ógilt kingdom_id: %“, þar sem `%` er `kingdom_id` sem var sett inn.

#### Skilar niðurstöðum (flatarmáli)
```sql
  -- Skilar flatarmáli konungsríkisins í km².
  RETURN area_sq_km;
END;
$$ LANGUAGE plpgsql;
```
- `RETURN area_sq_km`: Fallið skilar niðurstöðunni, sem er flatarmálið í ferkílómetrum, ef það fannst.


#### 3. Finna þriðja stærsta konungsríkið
Nú er fallið notað til að finna flatarmál konungsríkja og raða þeim í lækkandi röð eftir flatarmáli. Fyrirspurnin finnur þriðja stærsta konungsríkið.
```sql
-- 3. Finna þriðja stærsta konungsríkið 
-- Notar fallið martell.get_kingdom_size til að reikna flatarmál og finnur síðan þriðja stærsta konungsríkið.
SELECT name, gid, martell.get_kingdom_size(gid) AS area -- Bætti við að hægt er að sjá hvert konúngsríkið er.
FROM atlas.kingdoms 
ORDER BY area DESC -- Raðar eftir flatarmáli í lækkandi röð
LIMIT 1 OFFSET 2;  -- Sækir þriðja stærsta ríkið (OFFSET 2 sleppir fyrstu tveimur niðurstöðum)
```
- `SELECT name, gid, martell.get_kingdom_size(gid) AS area`: Þetta sækir nafn konungsríkisins, `gid` þess (id), og reiknar flatarmálið með fallinu `martell.get_kingdom_size` fyrir hvert konungsríki.
- ORDER BY area DESC: Raðar niðurstöðunum í lækkandi röð eftir flatarmálinu, þannig að stærstu konungsríkin eru efst.
- `LIMIT 1 OFFSET 2`: Takmarkar niðurstöðurnar við eitt konungsríki (þriðja stærsta). `OFFSET 2` sleppir fyrstu tveimur niðurstöðunum, þannig að þriðja stærsta ríkið er valið.

### Keyrsla
Ef þú ert að keyra í skel (*e. Terminal í mac*)

Keyraðu þessa skipun til að tengjast við gagnagrunninn.
```bash
psql -h junction.proxy.rlwy.net -p 55303 -U martell -d railway
```
Þá mun skelin biðja um passwordið sem við notuðum til að komast inn í gagnagrunninn. Setjið það rétt inn til að tengjast.

Keyrðu síðan þessa skipun:
```sql
SELECT name, gid, martell.get_kingdom_size(gid) AS area 
FROM atlas.kingdoms 
ORDER BY area DESC 
LIMIT 1 OFFSET 2;
```

Þá ættiru að fá þetta:
```bash
 name  | gid |  area  
-------+-----+--------
 Dorne |   6 | 901071
```

Ef ekki er keyrt í skel, þá virkar líka að tengjast gagnagrunninum í gégnum t.d. **DataGrid** eða **VScode** og keyra sömu **skipun**. Þá ætti að koma alveg eins tafla.

Ef þú ert ekki tengdur gagnagrunninum í gégnum martell þarftu að keyra þessa skipun á undan svo að þú getir notað fallið:
```sql
CREATE OR REPLACE FUNCTION martell.get_kingdom_size(kingdom_id integer)
RETURNS integer AS $$
DECLARE
  area_sq_km integer;
BEGIN
  SELECT ROUND(ST_Area(geog::geography) / 1000000)
  INTO area_sq_km
  FROM atlas.kingdoms
  WHERE gid = kingdom_id;
  IF area_sq_km IS NULL THEN
    RAISE EXCEPTION 'Ógilt kingdom_id: %', kingdom_id;
  END IF;

  RETURN area_sq_km;
END;
$$ LANGUAGE plpgsql;
```

Þú getur einnig keyrt beint með skránnum. Þú þarft að vera tengdur við gagnagrunninn í gégnm skelina eins og ég sýndi fyrir ofan og keyra þessa skipun þar sem þú hefur `Flatarmal.sql` skjalið í tölvunni:
```bash
\i Flatarmal.sql
```

### 2. Fjöldi staðsetninga og staðsetningar af ákveðnum tegundum `Stadsetning.sql`

Markmiðið með fyrirspurninni er að finna allar staðsetningar sem eru sjaldgæfastar (þær sem hafa fæstar staðsetningar) og eru utan "The Seven Kingdoms".

#### **`WITH type_counts AS (...)`**

```sql
WITH type_counts AS (
    -- Finna fjölda staðsetninga eftir staðsetningategund utan "The Seven Kingdoms"
    SELECT l.type, COUNT(l.gid) AS location_count
    FROM atlas.locations l
    JOIN atlas.kingdoms k ON l.gid = k.gid
    WHERE k.claimedby != 'The Seven Kingdoms'
    GROUP BY l.type
)
```

- `WITH`: Þetta er **CTE** (Common Table Expression), sem býr til tímabundna "töflu" sem hægt er að vísa í seinna í fyrirspurninni.
- `type_counts`: Þetta er nafnið á tímabundinni töflunni sem geymir niðurstöðurnar.
- 
Hvað gerist hér:
- `SELECT l.type, COUNT(l.gid) AS location_count`: Velur staðsetningategundina (l.type) og telur fjölda staðsetninga fyrir hverja tegund með því að nota `COUNT(l.gid)`.
- `JOIN atlas.kingdoms k ON l.gid = k.gid`: Tengir töflurnar `atlas.locations` (sem geymir staðsetningar) og atlas.kingdoms (sem geymir upplýsingar um konungsríki) með sameiginlega dálknum `gid`.
- `WHERE k.claimedby != 'The Seven Kingdoms'`: Þetta sía gögnin þannig að aðeins staðir sem eru utan "The Seven Kingdoms" eru teknir með.
- `GROUP BY l.type`: Hópar gögnin eftir staðsetningategund (`l.type`), þannig að við fáum fjölda staðsetninga fyrir hverja tegund.
Útkoman er tafla (`type_counts`) sem geymir fjölda staðsetninga eftir tegund utan "The Seven Kingdoms".

#### `min_count AS (...)`

```sql
min_count AS (
    -- Finna minnsta fjölda staðsetninga fyrir staðsetningategundir
    SELECT MIN(location_count) AS min_count
    FROM type_counts
)
```

- `min_count`: Þetta er önnur tímabundin tafla sem geymir aðeins eina tölu: minnsta fjölda staðsetninga fyrir staðsetningategundir.
Hvað gerist hér:
- `SELECT MIN(location_count) AS min_count FROM type_counts`: Þetta sækir minnsta fjölda staðsetninga úr tímabundnu töflunni type_counts sem var búin til í fyrri hlutanum.
Útkoman er tafla (min_count) sem geymir minnsta fjölda staðsetninga fyrir staðsetningategundir.

#### Endir
```sql
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
```
- `SELECT l.name, l.type`: Velur nöfn staðanna (`l.name`) og staðsetningategundir þeirra (`l.type`).
- `FROM atlas.locations l JOIN atlas.kingdoms k ON l.gid = k.gid`: Tengir töflurnar `locations` og `kingdoms` (eins og áður).
- `WHERE k.claimedby != 'The Seven Kingdoms'`: Þetta tryggir að aðeins staðir utan "The Seven Kingdoms" eru teknir með.
- `AND l.type IN (...)`: Hér er valið allar staðsetningategundir sem hafa fjölda staðsetninga sem er jafn minnsta fjöldanum.

Undirfyrirspurnin:

```sql
SELECT tc.type
FROM type_counts tc
JOIN min_count mc ON tc.location_count = mc.min_count
```
- `SELECT tc.type`: Velur allar staðsetningategundir úr tímabundnu töflunni type_counts þar sem fjöldi staðsetninga er jafnt minnsta fjöldanum (sem er geymdur í `min_count`).
- `JOIN min_count mc ON tc.location_count = mc.min_count`: Tengir `type_counts` við `min_count` til að tryggja að aðeins þær tegundir sem hafa minnsta fjölda staðsetninga séu valdar.

#### Keyrsla

Eins og áður ef þú ætlar að keyra skel vertu viss um að vera tengdur gagnagrunni og keyra
```sql
WITH type_counts AS (
    SELECT l.type, COUNT(l.gid) AS location_count
    FROM atlas.locations l
    JOIN atlas.kingdoms k ON l.gid = k.gid
    WHERE k.claimedby != 'The Seven Kingdoms'
    GROUP BY l.type
),
min_count AS (
    SELECT MIN(location_count) AS min_count
    FROM type_counts
)
SELECT l.name, l.type
FROM atlas.locations l
JOIN atlas.kingdoms k ON l.gid = k.gid
WHERE k.claimedby != 'The Seven Kingdoms'
AND l.type IN (
    SELECT tc.type
    FROM type_counts tc
    JOIN min_count mc ON tc.location_count = mc.min_count
);
```
Ætti að skila:
```bash
      name      | type 
----------------+------
 High Heart     | Ruin
 King's Landing | City
```
Ef ekki er keyrt í skel, þá virkar líka að tengjast gagnagrunninum í gégnum t.d. **DataGrid** eða **VScode** og keyra sömu **skipun**. Þá ætti að koma alveg eins tafla.

**Þú getur einnig keyrt beint með skránnum. Þú þarft að vera tengdur við gagnagrunninn í gégnm skelina eins og ég sýndi fyrir ofan og keyra þessa skipun þar sem þú hefur `Stadsetning.sql` skjalið í tölvunni:
```bash
\i Stadsetning.sql
```

