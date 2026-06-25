-- ═══════════════════════════════════════════════════════════════════
-- GÉOLOCALISATION DES POINTAGES + NOTIFICATIONS DÉPART
-- À exécuter dans Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. COORDONNÉES GPS DES SITES (clients) ───────────────────────
-- Rayon de vérification : 150 mètres autour du site
ALTER TABLE sites
  ADD COLUMN IF NOT EXISTS latitude        NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS longitude       NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS rayon_metres    INT DEFAULT 150;

-- ── 2. GÉOLOCALISATION SUR LE POINTAGE ───────────────────────────
ALTER TABLE pointage
  ADD COLUMN IF NOT EXISTS lat_entree         NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS lon_entree         NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS geo_entree_ok      BOOLEAN,          -- dans le rayon ?
  ADD COLUMN IF NOT EXISTS distance_entree_m  INT,              -- distance réelle en mètres
  ADD COLUMN IF NOT EXISTS lat_sortie         NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS lon_sortie         NUMERIC(10, 7),
  ADD COLUMN IF NOT EXISTS geo_sortie_ok      BOOLEAN,
  ADD COLUMN IF NOT EXISTS distance_sortie_m  INT,
  ADD COLUMN IF NOT EXISTS notif_depart_envoyee BOOLEAN DEFAULT false;

-- ── 3. COORDONNÉES GPS DES CLIENTS APHS (exemples) ───────────────
-- À compléter avec les vraies coordonnées GPS de chaque site

UPDATE sites SET latitude = 43.2965, longitude = 5.3698
WHERE nom = 'Cabinet dentaire pierre' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4505, longitude = 5.1019
WHERE nom = 'Magasin Brickbrock' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4154, longitude = 5.2148
WHERE nom = 'Magasin Shopi Marignane' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4521, longitude = 5.5634
WHERE nom = 'Real Photo' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.6432, longitude = 5.2601
WHERE nom = 'St Macla Lambesc' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4537, longitude = 5.5711
WHERE nom = 'Déchetterie Lugam' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4489, longitude = 5.5698
WHERE nom = 'Horquidé Fuveau' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4167, longitude = 5.2145
WHERE nom = 'Lim Marignane' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.6691, longitude = 5.3497
WHERE nom = 'St Macla Rognes 1' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.2987, longitude = 5.3974
WHERE nom = 'Stade Olijam' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.3871, longitude = 5.2543
WHERE nom = 'Cabinet Jacqueline Psy' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.3854, longitude = 5.2601
WHERE nom = 'Carrosserie Mouragian' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4512, longitude = 5.5712
WHERE nom = 'Equidia Fuveau' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4432, longitude = 5.1354
WHERE nom = 'HBO Châteauneuf' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.6698, longitude = 5.3512
WHERE nom = 'St Macla Rognes 2' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4601, longitude = 5.1201
WHERE nom = 'Magasin Shopi Vitrolles' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.6321, longitude = 5.1548
WHERE nom = 'Santo Pélissane' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.5398, longitude = 5.3521
WHERE nom = 'Super Achat Éguilles' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE sites SET latitude = 43.4021, longitude = 5.2387
WHERE nom = 'Transport Jacki' AND tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- ── 4. VÉRIFICATION ──────────────────────────────────────────────
-- SELECT nom, latitude, longitude, rayon_metres
-- FROM sites WHERE tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001'
-- ORDER BY nom;
