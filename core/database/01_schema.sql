-- ============================================================
-- APO-SAAS — SCHÉMA BASE DE DONNÉES
-- Fichier 01 : Tables & structure
-- Exécuter en premier dans Supabase > SQL Editor
-- ============================================================

-- ── EXTENSIONS ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ── ÉNUMÉRATIONS ────────────────────────────────────────────
CREATE TYPE user_role AS ENUM (
  'directeur',
  'responsable_exploitation',
  'agent_maitrise',
  'chef_equipe',
  'agent_proprete',
  'commercial'
);

CREATE TYPE statut_site AS ENUM ('actif', 'inactif', 'suspendu');

CREATE TYPE statut_contrat AS ENUM (
  'actif', 'suspendu', 'resilie', 'en_cours_renouvellement'
);

CREATE TYPE statut_commande AS ENUM (
  'brouillon', 'envoyee', 'livree', 'annulee'
);

CREATE TYPE statut_pointage AS ENUM ('present', 'absent', 'retard');

CREATE TYPE type_document AS ENUM (
  'contrat_travail', 'fiche_paie', 'avenant', 'autre'
);

CREATE TYPE statut_audit AS ENUM ('planifie', 'realise', 'non_conforme');


-- ── TENANTS (multi-client) ──────────────────────────────────
CREATE TABLE tenants (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom         TEXT NOT NULL,
  sigle       TEXT,
  ville       TEXT,
  couleur_primaire TEXT DEFAULT '#2A8FA8',
  couleur_secondaire TEXT DEFAULT '#1A6B80',
  couleur_accent TEXT DEFAULT '#D4A017',
  actif       BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);


-- ── USERS (complète auth.users de Supabase) ─────────────────
CREATE TABLE users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  role        user_role NOT NULL,
  nom         TEXT NOT NULL,
  prenom      TEXT NOT NULL,
  email       TEXT NOT NULL,
  telephone   TEXT,
  actif       BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);


-- ── SITES ───────────────────────────────────────────────────
CREATE TABLE sites (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            UUID NOT NULL REFERENCES tenants(id),
  nom                  TEXT NOT NULL,
  adresse              TEXT,
  ville                TEXT,
  code_postal          TEXT,
  client_nom           TEXT NOT NULL,
  agent_maitrise_id    UUID REFERENCES users(id),
  statut               statut_site DEFAULT 'actif',
  -- Chiffres pour calcul marge
  ca_mensuel           NUMERIC(10,2) DEFAULT 0,
  cout_main_oeuvre     NUMERIC(10,2) DEFAULT 0,
  cout_produits        NUMERIC(10,2) DEFAULT 0,
  cout_divers          NUMERIC(10,2) DEFAULT 0,
  -- Marge calculée automatiquement
  marge_pct            NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN ca_mensuel > 0
    THEN ROUND(((ca_mensuel - cout_main_oeuvre - cout_produits - cout_divers)
         / ca_mensuel * 100)::NUMERIC, 2)
    ELSE 0 END
  ) STORED,
  alerte_marge         BOOLEAN GENERATED ALWAYS AS (
    CASE WHEN ca_mensuel > 0
    THEN ((ca_mensuel - cout_main_oeuvre - cout_produits - cout_divers)
         / ca_mensuel * 100) < 30
    ELSE false END
  ) STORED,
  created_at           TIMESTAMPTZ DEFAULT now()
);


-- ── CONTRATS CLIENTS ────────────────────────────────────────
CREATE TABLE contrats (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            UUID NOT NULL REFERENCES tenants(id),
  site_id              UUID REFERENCES sites(id),
  reference            TEXT,
  client_nom           TEXT NOT NULL,
  date_debut           DATE,
  date_fin             DATE,
  reconductible        BOOLEAN DEFAULT true,
  montant_mensuel_ht   NUMERIC(10,2),
  statut               statut_contrat DEFAULT 'actif',
  created_at           TIMESTAMPTZ DEFAULT now()
);

-- Lien inverse site → contrat
ALTER TABLE sites ADD COLUMN contrat_id UUID REFERENCES contrats(id);


-- ── ATTRIBUTIONS CHEF D'ÉQUIPE ───────────────────────────────
-- L'AM attribue des sites à ses chefs d'équipe
CREATE TABLE attributions_ce (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        UUID NOT NULL REFERENCES tenants(id),
  chef_equipe_id   UUID NOT NULL REFERENCES users(id),
  site_id          UUID NOT NULL REFERENCES sites(id),
  attribue_par     UUID NOT NULL REFERENCES users(id), -- AM
  created_at       TIMESTAMPTZ DEFAULT now(),
  UNIQUE(chef_equipe_id, site_id)
);


-- ── DÉLÉGATIONS AM ──────────────────────────────────────────
-- AM absent → AM remplaçant, validé par direction
CREATE TABLE delegations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  am_absent_id        UUID NOT NULL REFERENCES users(id),
  am_remplacant_id    UUID NOT NULL REFERENCES users(id),
  valide_par          UUID NOT NULL REFERENCES users(id), -- direction
  date_debut          DATE NOT NULL,
  date_fin            DATE NOT NULL,
  motif               TEXT,
  active              BOOLEAN DEFAULT true,
  created_at          TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT dates_valides CHECK (date_fin >= date_debut)
);


-- ── AGENTS DE PROPRETÉ ──────────────────────────────────────
CREATE TABLE agents (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            UUID NOT NULL REFERENCES tenants(id),
  user_id              UUID REFERENCES users(id), -- accès app optionnel
  nom                  TEXT NOT NULL,
  prenom               TEXT NOT NULL,
  email                TEXT,
  telephone            TEXT,
  date_naissance       DATE,
  date_entree          DATE,
  numero_ss            TEXT,            -- chiffré côté app
  type_contrat         TEXT,            -- CDI, CDD, temps partiel…
  volume_horaire       NUMERIC(5,2),    -- heures/semaine
  taux_horaire         NUMERIC(6,2),    -- CCN Propreté Col. A
  coefficient          TEXT,            -- coefficient CCN
  site_principal_id    UUID REFERENCES sites(id),
  agent_maitrise_id    UUID REFERENCES users(id),
  actif                BOOLEAN DEFAULT true,
  created_at           TIMESTAMPTZ DEFAULT now()
);


-- ── PLANNING ────────────────────────────────────────────────
CREATE TABLE planning (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  agent_id      UUID NOT NULL REFERENCES agents(id),
  site_id       UUID NOT NULL REFERENCES sites(id),
  date          DATE NOT NULL,
  heure_debut   TIME NOT NULL,
  heure_fin     TIME NOT NULL,
  pause_minutes INT DEFAULT 0,
  note          TEXT,
  created_by    UUID REFERENCES users(id),
  created_at    TIMESTAMPTZ DEFAULT now()
);


-- ── POINTAGE ────────────────────────────────────────────────
CREATE TABLE pointage (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL REFERENCES tenants(id),
  agent_id       UUID NOT NULL REFERENCES agents(id),
  site_id        UUID NOT NULL REFERENCES sites(id),
  date           DATE NOT NULL,
  heure_entree   TIMESTAMPTZ,
  heure_sortie   TIMESTAMPTZ,
  statut         statut_pointage DEFAULT 'present',
  mode           TEXT DEFAULT 'manuel', -- manuel | qr_code | gps
  note           TEXT,
  created_at     TIMESTAMPTZ DEFAULT now()
);


-- ── COMMANDES FOURNISSEURS ──────────────────────────────────
CREATE TABLE commandes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        UUID NOT NULL REFERENCES tenants(id),
  site_id          UUID NOT NULL REFERENCES sites(id),
  reference        TEXT,
  fournisseur      TEXT,
  date_commande    DATE DEFAULT CURRENT_DATE,
  montant_ht       NUMERIC(10,2) DEFAULT 0,
  statut           statut_commande DEFAULT 'brouillon',
  cree_par         UUID REFERENCES users(id),
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE commandes_lignes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  commande_id     UUID NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
  designation     TEXT NOT NULL,
  quantite        NUMERIC(8,2) DEFAULT 1,
  prix_unitaire   NUMERIC(8,2) DEFAULT 0,
  montant_ht      NUMERIC(10,2) GENERATED ALWAYS AS
                  (ROUND((quantite * prix_unitaire)::NUMERIC, 2)) STORED
);


-- ── LIVRAISONS ──────────────────────────────────────────────
CREATE TABLE livraisons (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  commande_id       UUID REFERENCES commandes(id),
  site_id           UUID NOT NULL REFERENCES sites(id),
  date_livraison    DATE DEFAULT CURRENT_DATE,
  receptionnee_par  UUID REFERENCES users(id),
  conforme          BOOLEAN DEFAULT true,
  note              TEXT,
  created_at        TIMESTAMPTZ DEFAULT now()
);


-- ── AUDITS QUALITÉ ──────────────────────────────────────────
CREATE TABLE audits_qualite (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            UUID NOT NULL REFERENCES tenants(id),
  site_id              UUID NOT NULL REFERENCES sites(id),
  date_audit           DATE DEFAULT CURRENT_DATE,
  auditeur_id          UUID REFERENCES users(id),
  note_globale         NUMERIC(4,1),       -- /20
  observations         TEXT,
  actions_correctives  TEXT,
  statut               statut_audit DEFAULT 'planifie',
  created_at           TIMESTAMPTZ DEFAULT now()
);


-- ── SAISIE PAIE (préparation export Silae) ──────────────────
CREATE TABLE saisie_paie (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  agent_id          UUID NOT NULL REFERENCES agents(id),
  periode           TEXT NOT NULL,         -- format : '2026-06'
  heures_normales   NUMERIC(6,2) DEFAULT 0,
  heures_sup_25     NUMERIC(6,2) DEFAULT 0,
  heures_sup_50     NUMERIC(6,2) DEFAULT 0,
  heures_nuit       NUMERIC(6,2) DEFAULT 0,
  heures_dimanche   NUMERIC(6,2) DEFAULT 0,
  heures_ferie      NUMERIC(6,2) DEFAULT 0,
  primes            NUMERIC(8,2) DEFAULT 0,
  absences_heures   NUMERIC(6,2) DEFAULT 0,
  motif_absence     TEXT,
  saisie_par        UUID REFERENCES users(id),
  valide            BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now(),
  UNIQUE(agent_id, periode)
);


-- ── DOCUMENTS — COFFRE-FORT ──────────────────────────────────
CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  agent_id        UUID REFERENCES agents(id),
  site_id         UUID REFERENCES sites(id),
  type_document   type_document NOT NULL,
  nom_fichier     TEXT NOT NULL,
  url_storage     TEXT NOT NULL,    -- Supabase Storage (URL signée)
  yousign_id      TEXT,             -- référence YouSign
  signe           BOOLEAN DEFAULT false,
  date_signature  TIMESTAMPTZ,
  periode         TEXT,             -- fiches de paie : '2026-06'
  created_at      TIMESTAMPTZ DEFAULT now()
);


-- ── INDEX PERFORMANCE ────────────────────────────────────────
CREATE INDEX idx_users_tenant      ON users(tenant_id);
CREATE INDEX idx_users_role        ON users(role);
CREATE INDEX idx_sites_tenant      ON sites(tenant_id);
CREATE INDEX idx_sites_am          ON sites(agent_maitrise_id);
CREATE INDEX idx_sites_alerte      ON sites(alerte_marge) WHERE alerte_marge = true;
CREATE INDEX idx_agents_tenant     ON agents(tenant_id);
CREATE INDEX idx_agents_am         ON agents(agent_maitrise_id);
CREATE INDEX idx_planning_date     ON planning(date);
CREATE INDEX idx_pointage_date     ON pointage(date);
CREATE INDEX idx_delegations_dates ON delegations(date_debut, date_fin);
CREATE INDEX idx_documents_agent   ON documents(agent_id);
