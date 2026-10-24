-- Ajout des champs documents / données personnelles agents
ALTER TABLE agents
  ADD COLUMN IF NOT EXISTS num_ss       TEXT,   -- N° sécurité sociale (15 chiffres)
  ADD COLUMN IF NOT EXISTS num_cni      TEXT,   -- N° carte d'identité
  ADD COLUMN IF NOT EXISTS num_permis   TEXT,   -- N° permis de conduire
  ADD COLUMN IF NOT EXISTS iban         TEXT,   -- IBAN (RIB)
  ADD COLUMN IF NOT EXISTS bic          TEXT,   -- BIC (RIB)
  ADD COLUMN IF NOT EXISTS adresse      TEXT,   -- Adresse domicile
  ADD COLUMN IF NOT EXISTS code_postal  TEXT,
  ADD COLUMN IF NOT EXISTS ville        TEXT,
  ADD COLUMN IF NOT EXISTS nationalite  TEXT;

GRANT ALL ON agents TO anon, authenticated, service_role;
