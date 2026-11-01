CREATE TABLE IF NOT EXISTS agents_sites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  site_id     UUID NOT NULL REFERENCES sites(id)  ON DELETE CASCADE,
  jour_passage TEXT,
  heure_debut  TIME,
  heure_fin    TIME,
  duree_agent  NUMERIC(4,1),
  created_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(agent_id, site_id)
);

GRANT ALL ON agents_sites TO anon, authenticated, service_role;
