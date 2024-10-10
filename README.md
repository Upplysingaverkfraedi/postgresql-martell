# README

## 1. Flatarmál konungsríkja `Flatarmal.sql`

Markmið verkefnisinns er: 
1. Búa til fallið `<teymi>.get_kingdom_size(int kingdom_id)` sem að tekur inn `kingdom_id` og skilar flatarmáli konungsríkis út frá landfræðilegum gögnum í ferkílómetrum
2. Finna lausn á ólöglegum gildum `kingdom_id` með því að kasta villu.
3. Gera SQL fyrirspurn sem að finnur heildarflatarmál þriðja stærsta konungsríkisinns.

## Keyrsla
Keyra þessa skipun í skel til að tengjast við gagnagrunninn.
```bash
psql -h junction.proxy.rlwy.net -p 55303 -U martell -d railway
```
Þá mun skelin biðja um passwordið sem við notuðum til að komast inn í gagnagrunninn. Setjið það rétt inn til að tengjast.

Keyrið **skipun**:

```sql
SELECT name, gid, martell.get_kingdom_size(gid) AS area 
FROM atlas.kingdoms
ORDER BY area DESC 
LIMIT 1 OFFSET 2;
```
Þetta kallar á fallið `martell.get_kingdom_size(kingdom_id integer)` sem að teiknar flatarmál konúngsríkis. Skipunin finnur þriðja stærsta konúngsríkið og flatarmálið á því.

Ætti að skila:
```bash
 name  | gid |  area  
-------+-----+--------
 Dorne |   6 | 901071
```
ef að keyrt er í skel.

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

## 2. Fjöldi staðsetninga og staðsetningar af ákveðnum tegundum `Stadsetning.sql`
Markmiðið með fyrirspurninni er að finna allar staðsetningar sem eru sjaldgæfastar og eru utan "The Seven Kingdoms".

### Keyrsla
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
