-- Colonnes gestion compte agent
ALTER TABLE agents
  ADD COLUMN IF NOT EXISTS demande_affiliation BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS contrat_signe       BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS compte_cree         BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS auth_user_id        UUID;

GRANT ALL ON agents TO anon, authenticated, service_role;
