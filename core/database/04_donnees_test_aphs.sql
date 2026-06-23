-- ============================================================
-- APO-SAAS — DONNÉES DE TEST APHS
-- Fichier 04 : Jeu de données pilote
-- ============================================================

-- ── 1. TENANT APHS ──────────────────────────────────────────
INSERT INTO tenants (id, nom, sigle, ville, couleur_primaire, couleur_secondaire, couleur_accent)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Azur Propreté Hygiène et Services',
  'APHS',
  'Fos-sur-Mer',
  '#2A8FA8',
  '#1A6B80',
  '#D4A017'
);

-- ── 2. UTILISATEURS ─────────────────────────────────────────

-- Directeur
INSERT INTO users (id, tenant_id, role, nom, prenom, email)
VALUES (
  '4f62ed57-7d60-495f-b043-8bc707424863',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'directeur', 'Dupont', 'Jean', 'directeur@aphs.fr'
);

-- Agent de maîtrise 1
INSERT INTO users (id, tenant_id, role, nom, prenom, email)
VALUES (
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'agent_maitrise', 'Martin', 'Sophie', 'sophie.martin@aphs.fr'
);

-- Chef d'équipe 1
INSERT INTO users (id, tenant_id, role, nom, prenom, email)
VALUES (
  '5ad9a379-fc2e-4101-b1cb-3791439d3117',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'chef_equipe', 'Leroy', 'Marc', 'marc.leroy@aphs.fr'
);

-- ── 3. SITES ────────────────────────────────────────────────
INSERT INTO sites (id, tenant_id, nom, client_nom, ville, agent_maitrise_id,
                   ca_mensuel, cout_main_oeuvre, cout_produits, cout_divers)
VALUES
(
  'bbbbbbbb-0001-0000-0000-000000000001',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Port de Fos', 'Grand Port Maritime', 'Fos-sur-Mer',
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace',
  8500, 4200, 800, 700
),
(
  'bbbbbbbb-0002-0000-0000-000000000002',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Zone Industrielle Est', 'TOTAL Raffinerie', 'Fos-sur-Mer',
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace',
  12000, 7500, 1400, 200
),
(
  'bbbbbbbb-0003-0000-0000-000000000003',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Résidence Les Pins', 'OPH Habitat', 'Istres',
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace',
  4200, 2200, 600, 350
),
(
  'bbbbbbbb-0004-0000-0000-000000000004',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Centre Commercial', 'Klepierre', 'Martigues',
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace',
  9800, 4000, 900, 600
);

-- ── 4. ATTRIBUTION CHEF D'ÉQUIPE ────────────────────────────
INSERT INTO attributions_ce (tenant_id, chef_equipe_id, site_id, attribue_par)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  '5ad9a379-fc2e-4101-b1cb-3791439d3117',
  'bbbbbbbb-0001-0000-0000-000000000001',
  '7a53555f-a812-4f55-9cf7-8ca5ee238ace'
);
