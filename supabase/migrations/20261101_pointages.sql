CREATE TABLE IF NOT EXISTS pointages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID NOT NULL DEFAULT 'aaaaaaaa-0000-0000-0000-000000000001',
  agent_id     UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  site_id      UUID NOT NULL REFERENCES sites(id)  ON DELETE CASCADE,
  heure_entree TIMESTAMPTZ NOT NULL DEFAULT now(),
  heure_sortie TIMESTAMPTZ,
  commentaire  TEXT,
  created_at   TIMESTAMPTZ DEFAULT now()
);

GRANT ALL ON pointages TO anon, authenticated, service_role;
