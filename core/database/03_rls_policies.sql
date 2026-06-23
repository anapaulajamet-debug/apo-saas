-- ============================================================
-- APO-SAAS — ROW LEVEL SECURITY (RLS)
-- Fichier 03 : Isolation par rôle et tenant
-- Exécuter après 02_fonctions.sql
-- ============================================================


-- ══════════════════════════════════════════════════════════════
-- TENANTS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_select" ON tenants
  FOR SELECT USING (id = get_my_tenant());

-- Seul un super-admin (rôle Supabase service_role) peut créer des tenants


-- ══════════════════════════════════════════════════════════════
-- USERS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Chaque utilisateur voit tous les users de son tenant
CREATE POLICY "users_select" ON users
  FOR SELECT USING (tenant_id = get_my_tenant());

-- Seule la direction peut créer / modifier des users
CREATE POLICY "users_insert" ON users
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant() AND is_direction()
  );

CREATE POLICY "users_update" ON users
  FOR UPDATE USING (
    tenant_id = get_my_tenant() AND is_direction()
  );


-- ══════════════════════════════════════════════════════════════
-- SITES
-- ══════════════════════════════════════════════════════════════
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sites_select" ON sites
  FOR SELECT USING (id IN (SELECT mes_sites()));

-- AM et direction peuvent modifier les chiffres du site (marge)
CREATE POLICY "sites_update" ON sites
  FOR UPDATE USING (
    id IN (SELECT mes_sites())
    AND get_my_role() IN ('directeur','responsable_exploitation','agent_maitrise')
  );

-- Seule la direction crée / supprime des sites
CREATE POLICY "sites_insert" ON sites
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant() AND is_direction()
  );


-- ══════════════════════════════════════════════════════════════
-- CONTRATS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE contrats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contrats_select" ON contrats
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR site_id IN (SELECT mes_sites())
    )
  );

CREATE POLICY "contrats_insert_update" ON contrats
  FOR ALL USING (tenant_id = get_my_tenant() AND is_direction());


-- ══════════════════════════════════════════════════════════════
-- ATTRIBUTIONS CHEF D'ÉQUIPE
-- ══════════════════════════════════════════════════════════════
ALTER TABLE attributions_ce ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attr_ce_select" ON attributions_ce
  FOR SELECT USING (tenant_id = get_my_tenant());

-- AM peut attribuer les sites dont il est responsable
CREATE POLICY "attr_ce_insert" ON attributions_ce
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR (
        get_my_role() = 'agent_maitrise'
        AND site_id IN (SELECT mes_sites())
      )
    )
  );

CREATE POLICY "attr_ce_delete" ON attributions_ce
  FOR DELETE USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR get_my_role() = 'agent_maitrise'
    )
  );


-- ══════════════════════════════════════════════════════════════
-- DÉLÉGATIONS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE delegations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "deleg_select" ON delegations
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR am_absent_id    = auth.uid()
      OR am_remplacant_id = auth.uid()
    )
  );

-- Seule la direction crée et valide les délégations
CREATE POLICY "deleg_insert" ON delegations
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant() AND is_direction()
  );

CREATE POLICY "deleg_update" ON delegations
  FOR UPDATE USING (
    tenant_id = get_my_tenant() AND is_direction()
  );


-- ══════════════════════════════════════════════════════════════
-- AGENTS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Direction : tous les agents du tenant
-- AM        : ses agents (agent_maitrise_id = moi) + agents délégués
-- CE        : agents des sites attribués (lecture)
-- Agent     : lui-même uniquement
CREATE POLICY "agents_select" ON agents
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR agent_maitrise_id = auth.uid()
      OR site_principal_id IN (SELECT mes_sites())
      OR user_id = auth.uid()
    )
  );

CREATE POLICY "agents_insert" ON agents
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR get_my_role() = 'agent_maitrise'
    )
  );

CREATE POLICY "agents_update" ON agents
  FOR UPDATE USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR agent_maitrise_id = auth.uid()
    )
  );


-- ══════════════════════════════════════════════════════════════
-- PLANNING
-- ══════════════════════════════════════════════════════════════
ALTER TABLE planning ENABLE ROW LEVEL SECURITY;

CREATE POLICY "planning_select" ON planning
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
  );

CREATE POLICY "planning_insert_update" ON planning
  FOR ALL USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR get_my_role() = 'agent_maitrise'
    )
    AND site_id IN (SELECT mes_sites())
  );


-- ══════════════════════════════════════════════════════════════
-- POINTAGE
-- ══════════════════════════════════════════════════════════════
ALTER TABLE pointage ENABLE ROW LEVEL SECURITY;

-- Agent voit uniquement son propre pointage
-- AM / CE / direction voient les pointages de leurs sites
CREATE POLICY "pointage_select" ON pointage
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      site_id IN (SELECT mes_sites())
      OR agent_id IN (SELECT id FROM agents WHERE user_id = auth.uid())
    )
  );

-- L'agent peut pointer lui-même
CREATE POLICY "pointage_insert_agent" ON pointage
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND agent_id IN (SELECT id FROM agents WHERE user_id = auth.uid())
  );

-- AM et direction peuvent modifier le pointage
CREATE POLICY "pointage_update_am" ON pointage
  FOR UPDATE USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR (get_my_role() = 'agent_maitrise' AND site_id IN (SELECT mes_sites()))
    )
  );


-- ══════════════════════════════════════════════════════════════
-- COMMANDES
-- ══════════════════════════════════════════════════════════════
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "commandes_select" ON commandes
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
  );

CREATE POLICY "commandes_insert" ON commandes
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
    AND get_my_role() IN ('directeur','responsable_exploitation','agent_maitrise','chef_equipe')
  );

CREATE POLICY "commandes_update" ON commandes
  FOR UPDATE USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
    AND get_my_role() IN ('directeur','responsable_exploitation','agent_maitrise')
  );

ALTER TABLE commandes_lignes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lignes_all" ON commandes_lignes
  FOR ALL USING (
    commande_id IN (SELECT id FROM commandes)
  );


-- ══════════════════════════════════════════════════════════════
-- LIVRAISONS
-- ══════════════════════════════════════════════════════════════
ALTER TABLE livraisons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "livraisons_select" ON livraisons
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
  );

CREATE POLICY "livraisons_insert" ON livraisons
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
    AND get_my_role() IN ('directeur','responsable_exploitation','agent_maitrise','chef_equipe')
  );


-- ══════════════════════════════════════════════════════════════
-- AUDITS QUALITÉ
-- ══════════════════════════════════════════════════════════════
ALTER TABLE audits_qualite ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audits_select" ON audits_qualite
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
  );

-- AM, CE et direction peuvent saisir des audits
CREATE POLICY "audits_insert" ON audits_qualite
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
    AND get_my_role() IN ('directeur','responsable_exploitation','agent_maitrise','chef_equipe')
  );

CREATE POLICY "audits_update" ON audits_qualite
  FOR UPDATE USING (
    tenant_id = get_my_tenant()
    AND site_id IN (SELECT mes_sites())
  );


-- ══════════════════════════════════════════════════════════════
-- SAISIE PAIE
-- ══════════════════════════════════════════════════════════════
ALTER TABLE saisie_paie ENABLE ROW LEVEL SECURITY;

-- Direction et AM voient la paie de leurs agents
CREATE POLICY "paie_select" ON saisie_paie
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR agent_id IN (
        SELECT id FROM agents WHERE agent_maitrise_id = auth.uid()
      )
    )
  );

CREATE POLICY "paie_insert_update" ON saisie_paie
  FOR ALL USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR (
        get_my_role() = 'agent_maitrise'
        AND agent_id IN (
          SELECT id FROM agents WHERE agent_maitrise_id = auth.uid()
        )
      )
    )
  );


-- ══════════════════════════════════════════════════════════════
-- DOCUMENTS — COFFRE-FORT
-- ══════════════════════════════════════════════════════════════
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Agent voit uniquement ses propres documents
-- AM voit les documents de ses agents
-- Direction voit tout
CREATE POLICY "docs_select" ON documents
  FOR SELECT USING (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR agent_id IN (SELECT id FROM agents WHERE agent_maitrise_id = auth.uid())
      OR agent_id IN (SELECT id FROM agents WHERE user_id = auth.uid())
    )
  );

-- Seule la direction et l'AM déposent des documents
CREATE POLICY "docs_insert" ON documents
  FOR INSERT WITH CHECK (
    tenant_id = get_my_tenant()
    AND (
      is_direction()
      OR get_my_role() = 'agent_maitrise'
    )
  );


-- ══════════════════════════════════════════════════════════════
-- ALERTES MARGE LOG
-- ══════════════════════════════════════════════════════════════
ALTER TABLE alertes_marge_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "alertes_select" ON alertes_marge_log
  FOR SELECT USING (
    site_id IN (SELECT mes_sites())
  );
