-- 1. Fallið <teymi>.get_kingdom_size(int kingdom_id)
-- Býr til eða uppfærir function martell.get_kingdom_size sem reiknar flatarmál konungsríkis
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


  -- 2. Lausn við ólöglegu gildi á kingdom_id
  -- Athugar hvort breytan 'area_sq_km' sé NULL (þ.e. engin niðurstaða fannst fyrir gefið 'kingdom_id').
  IF area_sq_km IS NULL THEN
    -- Ef 'kingdom_id' er ekki gilt, kasta villu með skilaboðum á íslensku.
    RAISE EXCEPTION 'Ógilt kingdom_id: %', kingdom_id;
  END IF;

  -- Skilar flatarmáli konungsríkisins í km².
  RETURN area_sq_km;
END;
$$ LANGUAGE plpgsql;

-- 3. Finna þriðja stærsta konungsríkið 
-- Notar fallið martell.get_kingdom_size til að reikna flatarmál og finnur síðan þriðja stærsta konungsríkið.
SELECT name, gid, martell.get_kingdom_size(gid) AS area -- Bætti við að hægt er að sjá hvert konúngsríkið er.
FROM atlas.kingdoms 
ORDER BY area DESC -- Raðar eftir flatarmáli í lækkandi röð
LIMIT 1 OFFSET 2;  -- Sækir þriðja stærsta ríkið (OFFSET 2 sleppir fyrstu tveimur niðurstöðum)
