-- Table de paramètres globaux Cappolia (assurance, config...)
CREATE TABLE IF NOT EXISTS parametres_cappolia (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id                UUID NOT NULL DEFAULT 'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
  assurance_assureur       TEXT    DEFAULT 'MATMUT / Inter Mutuelles Entreprises',
  assurance_num_contrat    TEXT    DEFAULT '971000306548T',
  assurance_echeance       DATE    DEFAULT '2026-12-31',
  assurance_alerte_60j     BOOLEAN DEFAULT FALSE, -- email 60j envoyé
  assurance_alerte_30j     BOOLEAN DEFAULT FALSE, -- email 30j envoyé
  updated_at               TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id)
);

-- Insérer la ligne initiale
INSERT INTO parametres_cappolia (tenant_id, assurance_echeance)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001'::uuid, '2026-12-31')
ON CONFLICT (tenant_id) DO NOTHING;

-- RLS
ALTER TABLE parametres_cappolia ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_params" ON parametres_cappolia FOR ALL
  USING (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001'::uuid);

GRANT ALL ON parametres_cappolia TO anon, authenticated, service_role;
