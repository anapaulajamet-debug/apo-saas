-- ============================================================
-- APO-SAAS — FONCTIONS UTILITAIRES
-- Fichier 02 : Fonctions RLS & helpers
-- Exécuter après 01_schema.sql
-- ============================================================


-- ── Rôle de l'utilisateur connecté ──────────────────────────
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM users WHERE id =  auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;


-- ── Tenant de l'utilisateur connecté ────────────────────────
CREATE OR REPLACE FUNCTION get_my_tenant()
RETURNS UUID AS $$
  SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;


-- ── Est directeur ou responsable exploitation ? ──────────────
CREATE OR REPLACE FUNCTION is_direction()
RETURNS BOOLEAN AS $$
  SELECT role IN ('directeur', 'responsable_exploitation')
  FROM users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;


-- ── Sites visibles par l'utilisateur connecté ───────────────
-- Directeur/RE : tous les sites du tenant
-- AM           : ses sites + sites délégués actifs
-- CE           : sites attribués par son AM
-- Agent        : son site principal
CREATE OR REPLACE FUNCTION mes_sites()
RETURNS SETOF UUID AS $$
DECLARE
  v_role      user_role;
  v_tenant    UUID;
  v_user      UUID;
BEGIN
  v_user   := auth.uid();
  v_role   := get_my_role();
  v_tenant := get_my_tenant();

  IF v_role IN ('directeur', 'responsable_exploitation', 'commercial') THEN
    RETURN QUERY SELECT id FROM sites WHERE tenant_id = v_tenant;

  ELSIF v_role = 'agent_maitrise' THEN
    -- Ses propres sites
    RETURN QUERY SELECT id FROM sites
      WHERE tenant_id = v_tenant AND agent_maitrise_id = v_user;
    -- Sites délégués (collègue absent, délégation active)
    RETURN QUERY
      SELECT s.id FROM sites s
      JOIN delegations d ON d.am_absent_id = s.agent_maitrise_id
      WHERE s.tenant_id = v_tenant
        AND d.am_remplacant_id = v_user
        AND d.active = true
        AND CURRENT_DATE BETWEEN d.date_debut AND d.date_fin;

  ELSIF v_role = 'chef_equipe' THEN
    RETURN QUERY
      SELECT site_id FROM attributions_ce WHERE chef_equipe_id = v_user;

  ELSIF v_role = 'agent_proprete' THEN
    RETURN QUERY
      SELECT site_principal_id FROM agents
      WHERE user_id = v_user AND site_principal_id IS NOT NULL;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ── Trigger : recalcul montant commande après modif lignes ──
CREATE OR REPLACE FUNCTION maj_montant_commande()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE commandes
  SET montant_ht = (
    SELECT COALESCE(SUM(montant_ht), 0)
    FROM commandes_lignes
    WHERE commande_id = COALESCE(NEW.commande_id, OLD.commande_id)
  )
  WHERE id = COALESCE(NEW.commande_id, OLD.commande_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_maj_montant_commande
AFTER INSERT OR UPDATE OR DELETE ON commandes_lignes
FOR EACH ROW EXECUTE FUNCTION maj_montant_commande();


-- ── Trigger : alerte marge dans les logs ────────────────────
-- (optionnel — pour notifier via Make/webhook)
CREATE TABLE IF NOT EXISTS alertes_marge_log (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id    UUID REFERENCES sites(id),
  marge_pct  NUMERIC(5,2),
  logged_at  TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION log_alerte_marge()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.alerte_marge = true AND (OLD.alerte_marge = false OR OLD.alerte_marge IS NULL) THEN
    INSERT INTO alertes_marge_log(site_id, marge_pct)
    VALUES (NEW.id, NEW.marge_pct);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alerte_marge
AFTER UPDATE ON sites
FOR EACH ROW EXECUTE FUNCTION log_alerte_marge();
