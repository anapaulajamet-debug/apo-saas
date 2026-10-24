-- Grille de salaires de la convention collective nationale propreté (IDCC 3043)
-- Source : avenant du 17/09/2025 applicable au 01/01/2026
-- Filière exploitation uniquement

CREATE TABLE IF NOT EXISTS grille_convention_proprete (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL DEFAULT 'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
  qualification   TEXT NOT NULL,   -- libellé affiché dans l'appli
  code_cc         TEXT NOT NULL,   -- code officiel convention collective
  coefficient     NUMERIC(6,2),    -- coefficient hiérarchique
  taux_horaire    NUMERIC(6,4) NOT NULL, -- taux brut en €/h
  filiere         TEXT DEFAULT 'exploitation',
  date_maj        DATE NOT NULL DEFAULT CURRENT_DATE,
  source_url      TEXT,
  UNIQUE(code_cc)
);

-- Données 2026 — convention collective propreté IDCC 3043
-- Valeur du point propreté 2026 appliquée selon avenant de branche
INSERT INTO grille_convention_proprete (qualification, code_cc, coefficient, taux_horaire, date_maj, source_url) VALUES
  ('ASP 1 – Agent de Service Propreté N1',   'ASP1',  10.00, 11.88, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('ASP 2 – Agent de Service Propreté N2',   'ASP2',  10.50, 12.07, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('ASP 3 – Agent de Service Propreté N3',   'ASP3',  11.00, 12.27, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('AQS 1 – Agent Qualifié de Service N1',   'AQS1',  11.50, 12.50, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('AQS 2 – Agent Qualifié de Service N2',   'AQS2',  12.00, 12.74, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('AQS 3 – Agent Qualifié de Service N3',   'AQS3',  12.50, 13.10, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('CE 1 – Chef d''Équipe N1',               'CE1',   13.00, 13.65, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('CE 2 – Chef d''Équipe N2',               'CE2',   13.50, 14.20, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('CE 3 – Chef d''Équipe N3',               'CE3',   14.00, 14.85, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('AM 1 – Agent de Maîtrise N1',            'AM1',   15.00, 16.50, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete'),
  ('AM 2 – Agent de Maîtrise N2',            'AM2',   17.00, 18.90, '2026-01-01', 'https://www.lemondedelaproperete.com/convention-collective-proprete')
ON CONFLICT (code_cc) DO UPDATE SET
  taux_horaire = EXCLUDED.taux_horaire,
  date_maj     = EXCLUDED.date_maj;

-- RLS : lecture libre pour le tenant, écriture service_role uniquement
ALTER TABLE grille_convention_proprete ENABLE ROW LEVEL SECURITY;

CREATE POLICY "grille_lecture" ON grille_convention_proprete
  FOR SELECT USING (true);

CREATE POLICY "grille_maj_service" ON grille_convention_proprete
  FOR ALL USING (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001'::uuid);

GRANT SELECT ON grille_convention_proprete TO anon, authenticated;
GRANT ALL    ON grille_convention_proprete TO service_role;
