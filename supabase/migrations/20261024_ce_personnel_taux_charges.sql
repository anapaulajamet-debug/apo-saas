-- Ajout du taux de charges patronales par ligne de personnel
-- (déplacé depuis le header comptes_exploitation vers chaque personne)
ALTER TABLE ce_personnel
  ADD COLUMN IF NOT EXISTS taux_charges NUMERIC(6,2) DEFAULT 57.46;

GRANT ALL ON ce_personnel TO anon, authenticated, service_role;
