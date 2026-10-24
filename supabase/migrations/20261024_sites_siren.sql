-- Ajout champ SIREN client dans sites (pour pré-remplissage contrat)
ALTER TABLE sites ADD COLUMN IF NOT EXISTS siren TEXT;

GRANT ALL ON sites TO anon, authenticated, service_role;
