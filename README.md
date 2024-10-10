# README

# Liður 1: Ættir og Landsvæði
!!!!
Það koma mjög mikið af NULL í father,mother and spouse.
!!!

Fyrst var downloadað DataGrip 2024.2.2 svo var gefið fram staðsetningu á password á Tengingu við PostgreSQL á canvas TBL: PostgreSQL. Ég notaði Visual Studio Code til að gera git add . git commit -m "XXX" og git push fyrir þetta verkefni sem var tengt við DataGrip 2024.2.2.

Annars var allur kóðin keyrður á sama hátt það var ýtt á kóða bútinn og ýtt svo á keyrsluhnappann.

Útskýringar í kóðanum í file ""AdalpersonurTextiSp2.md"

Þegar kóðin er keyrður á að koma fram 10 dálkar sem sýna upplýsingar á full_name, gender, father, mother, spouse, born, died, age, alive, books. Þetta sýnir allskonar upplýsingar eins og nafn með tilit, hvort þeir lifa og hvaða bók characteranir koma fram í.

# Liður 2: Aðalpersónur
Hér er liður 1 tilbúinn til yfirferðar. Skrefin til keyrslu eru eftirfarandi:

Þið opnið fileið "Hluti 1: Ættir og landsvæði í Norður Konungsríkinu"
Downloadið IDE s.s. Datagrip og keyrið kóðann inn í réttum gagnagrunn. Frekari upplýsingar um hvernig á að komast inn í þann gagnagrunn má sjá á Canvas.
Keyrsla á spurningu 1:
Fyrstu spurninguna keyriði einfaldlega þegar þið smellið á kóða bútinn og ýtið á keyrsluhnapp:
"Select k_gid AS kingdom_id, h.id AS house_id , k.name..."
Þá fáiði upp rétta töflu þar sem útkomann ætti að vera 444 raðir með kingdom_id, house_id, kingdom_name og house_name dálkunum.
Eftir það getiði keyrt:
"WITH kingdoms_houses AS (SELECT k.gid AS kingdom_id....."
til að upserta möppunina inn í töfluna. Útkoman á því ætti að vera engin sýnileg.

Keyrsla á spurningu 2:
Fyrir spurningu tvö er svipað fyrirkomulag en hún skiptist í tvo parta/kóða.

Fyrsti partur:
keyriru líkt og áðan SELECT skipunina með því að smella á kóða bútinn og keyrslu hnapp og ýta á:
"SELECT l.gid AS location_id, h_id AS house_id...."
Þá fáiði upp töflu þar sem útkomann ætti að vera 339 raðir með dálkunum location_id, house_id, location_name, house_name, house_region, seats titles og framvegis. Þessi tafla finnur samanburð á location nöfnum miðað við houses nöfnum og leitar þar eftir samanburð í mismunandi dálkum.
Þaðan af getiði keyrt líkt og áðan allan bútinn með:
"WITH location_house_mapping AS ( SELECT l_gid AS location_id....."
Þá upsertið þið heildar möppunina í töfluna. Útkoman ætti ekki að vera sýnileg þ.e. engin tafla.

Seinni partur:
Til að keyra seinni partinn sem er aðskilin frá fyrri partinum með commentinu, -- Sýnir einungis niðurstöður fyrir norðrið (e. The North) smelliru á kóðabútinn og keyrsluhnapp og ýtir á:
"WITH location_house_mapping AS ( SELECT l.gid AS l..."
Þá kemur tafla sem inniheldur einungis fundnar samsvaranir þar sem Region dálkurinn er "The North" þetta þýðir að húsin í Norðrinu hafa farið í gegnum margar athuganir í mismunandi dálkum t.d. athugað eftir hvort nafnið á húsinu hafi komið fram í summary dálknum í atlas.locations.
Útkoman hér ætti að vera tafla með 18 röðum með dálkunum location_id, house_id, location_name, house_name, house_region og framvegis.

Keyrsla á spurningu 3:
Hér viljiði smella á kóða bútinn fyrir spurningu 3 og keyra með statement skipuninni:
"WITH northern_houses AS ( SELECT id AS house_id, n..."
Þá ætti að koma tafla með 8 röðum sem inniheldur ýmis fjölskyldu nöfn í norðrinu. Fjöldinn ætti að vera lækkandi (35, 10, 8, 7, 6, 6, 6, 6, 6) og nöfnin í stafrófsröð (Stark, Karstark, Mormont, Manderly, Glover, Ryswell, Tallhart, Umber)

# Liður 3
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
