CREATE TABLE IF NOT EXISTS contacts_site (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL DEFAULT 'aaaaaaaa-0000-0000-0000-000000000001',
  site_id     UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  nom         TEXT NOT NULL,
  role        TEXT,
  telephone   TEXT,
  email       TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

GRANT ALL ON contacts_site TO anon, authenticated, service_role;

-- RLS
ALTER TABLE contacts_site ENABLE ROW LEVEL SECURITY;
CREATE POLICY "contacts_site_select" ON contacts_site FOR SELECT USING (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001');
CREATE POLICY "contacts_site_insert" ON contacts_site FOR INSERT WITH CHECK (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001');
CREATE POLICY "contacts_site_update" ON contacts_site FOR UPDATE USING (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001');
CREATE POLICY "contacts_site_delete" ON contacts_site FOR DELETE USING (tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001');

-- Migrer le contact existant (contact_nom) vers la nouvelle table
INSERT INTO contacts_site (tenant_id, site_id, nom, telephone, email)
SELECT
  'aaaaaaaa-0000-0000-0000-000000000001',
  id,
  contact_nom,
  telephone,
  email_contact
FROM sites
WHERE contact_nom IS NOT NULL AND contact_nom != ''
ON CONFLICT DO NOTHING;
