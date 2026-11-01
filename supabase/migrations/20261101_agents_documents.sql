ALTER TABLE agents ADD COLUMN IF NOT EXISTS documents_agent JSONB DEFAULT '[]'::jsonb;
