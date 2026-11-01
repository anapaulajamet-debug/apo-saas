-- Ajout colonne qualification / poste dans agents
ALTER TABLE agents
  ADD COLUMN IF NOT EXISTS qualification TEXT,
  ADD COLUMN IF NOT EXISTS taux_horaire  NUMERIC(8,2),
  ADD COLUMN IF NOT EXISTS coefficient   NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS filiere_ccn   TEXT,
  ADD COLUMN IF NOT EXISTS num_securite_sociale TEXT,
  ADD COLUMN IF NOT EXISTS solde_cp      NUMERIC(5,1) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS date_embauche DATE,
  ADD COLUMN IF NOT EXISTS type_contrat  TEXT;

GRANT ALL ON agents TO anon, authenticated, service_role;
