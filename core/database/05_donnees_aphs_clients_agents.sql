-- ═══════════════════════════════════════════════════════════════════
-- DONNÉES RÉELLES APHS — Clients, Agents de propreté, Responsables secteur
-- À exécuter dans Supabase SQL Editor (menu Databases > SQL Editor)
-- ═══════════════════════════════════════════════════════════════════

-- ── 0. AJOUT COLONNES CONTACT DANS LA TABLE SITES ────────────────
-- (à exécuter une seule fois)
ALTER TABLE sites
  ADD COLUMN IF NOT EXISTS contact_nom       TEXT,
  ADD COLUMN IF NOT EXISTS contact_prenom    TEXT,
  ADD COLUMN IF NOT EXISTS contact_tel       TEXT,
  ADD COLUMN IF NOT EXISTS contact_fonction  TEXT;

-- ── 1. CRÉATION DES 4 RESPONSABLES DE SECTEUR (agents de maîtrise) ─
-- ÉTAPE PRÉALABLE : créez d'abord leurs comptes dans Supabase Auth
-- (Authentication > Users > Add user) avec les emails ci-dessous,
-- puis remplacez les UUID 'xxxxxxxx-...' par les vrais UUID générés.

-- Une fois les 4 comptes Auth créés, exécutez ce bloc :

/*
INSERT INTO users (id, tenant_id, role, nom, prenom, email, telephone)
VALUES
  (
    'REMPLACER_PAR_UUID_AUTH_CADRE',     -- Pierre Cadre
    'aaaaaaaa-0000-0000-0000-000000000001',
    'agent_maitrise',
    'Cadre', 'Pierre',
    'pierre.cadre@aphs.fr',
    '06 04 11 22 33'
  ),
  (
    'REMPLACER_PAR_UUID_AUTH_BENGER',    -- Ali Benger
    'aaaaaaaa-0000-0000-0000-000000000001',
    'agent_maitrise',
    'Benger', 'Ali',
    'ali.benger@aphs.fr',
    '06 04 11 22 44'
  ),
  (
    'REMPLACER_PAR_UUID_AUTH_RONALDO',   -- Anna Ronaldo
    'aaaaaaaa-0000-0000-0000-000000000001',
    'agent_maitrise',
    'Ronaldo', 'Anna',
    'anna.ronaldo@aphs.fr',
    '06 04 11 22 55'
  ),
  (
    'REMPLACER_PAR_UUID_AUTH_POURIOU',   -- Jocelyne Pouriou
    'aaaaaaaa-0000-0000-0000-000000000001',
    'agent_maitrise',
    'Pouriou', 'Jocelyne',
    'jocelyne.pouriou@aphs.fr',
    '06 04 11 22 66'
  );
*/

-- ── 2. INSERTION DES CLIENTS (SITES) ─────────────────────────────
-- agent_maitrise_id = NULL pour l'instant (à lier après création des AM)
-- Remplacez NULL par l'UUID de chaque AM une fois leurs comptes créés.

INSERT INTO sites (tenant_id, nom, adresse, client_nom, contact_nom, contact_prenom, contact_tel, contact_fonction)
VALUES

-- Secteur Pierre CADRE
('aaaaaaaa-0000-0000-0000-000000000001',
 'Cabinet dentaire pierre',
 '24 boulevard de compostelle, 13012 Marseille',
 'Cabinet dentaire pierre',
 'Valomont', 'Elias', '06 20 63 20 74', 'Secrétaire'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Magasin Brickbrock',
 '12 Rue Alexandre Dumas, 13220 Châteauneuf-les-Martigues',
 'Magasin Brickbrock',
 'Felacour', 'Lucien', '06 20 63 20 78', 'Secrétaire'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Magasin Shopi Marignane',
 '17 Boulevard Georges Clemenceau, 13700 Marignane',
 'Magasin Shopi Marignane',
 'Lormier', 'Lina', '06 20 63 20 82', 'Secrétaire'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Real Photo',
 '95 Route de la Diote, 13850 Gréasque',
 'Real Photo',
 'Tarton', 'Léon', '06 20 63 20 90', 'Secrétaire'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'St Macla Lambesc',
 '45 Allée de Boismeau, 13410 Lambesc',
 'St Macla',
 'Bellacier', 'Théo', '06 20 63 20 86', 'Secrétaire'),

-- Secteur Ali BENGER
('aaaaaaaa-0000-0000-0000-000000000001',
 'Déchetterie Lugam',
 '324 Impasse Eugène Delacroix, 13320 Bouc-bel-Air',
 'Déchetterie Lugam',
 'Doreval', 'Mael', '06 20 63 20 75', 'Responsable logistique'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Horquidé Fuveau',
 '15 route des Michels, 13710 Fuveau',
 'Horquidé',
 'Sauvage', 'Tom', '06 20 63 20 91', 'Responsable logistique'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Lim Marignane',
 '17 Avenue Jean Mermoz, 13700 Marignane',
 'Lim',
 'Castelain', 'Jade', '06 20 63 20 83', 'Responsable logistique'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'St Macla Rognes 1',
 '1 lotissement Saint-Denis, 13840 Rognes',
 'St Macla',
 'Corvinel', 'Théa', '06 20 63 20 87', 'Responsable logistique'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Stade Olijam',
 '265 avenue de Mazargues, 13008 Marseille',
 'Stade Olijam',
 'Arvens', 'Jacques', '06 20 63 20 79', 'Responsable logistique'),

-- Secteur Anna RONALDO
('aaaaaaaa-0000-0000-0000-000000000001',
 'Cabinet Jacqueline Psy',
 '17 Avenue des Grillons, 13170 Les Pennes-Mirabeau',
 'Cabinet Jacqueline Psy',
 'Solane', 'Camille', '06 20 63 20 80', 'Comptable'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Carrosserie Mouragian',
 '232 Avenue Etienne Rabattu, 13170 Les Pennes-Mirabeau',
 'Carrosserie Mouragian',
 'Clairmeon', 'Noolan', '06 20 63 20 76', 'Comptable'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Equidia Fuveau',
 '331 chemin de Rousset, 13710 Fuveau',
 'Equidia',
 'Idial', 'Ilias', '06 20 63 20 92', 'Comptable'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'HBO Châteauneuf',
 '4 avenue du 14 Juillet, 13220 Châteauneuf-les-Martigues',
 'HBO',
 'Mirandel', 'Elena', '06 20 63 20 84', 'Comptable'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'St Macla Rognes 2',
 '75 Chemin de Pataconit, 13840 Rognes',
 'St Macla',
 'Aurelac', 'Ambre', '06 20 63 20 88', 'Comptable'),

-- Secteur Jocelyne POURIOU
('aaaaaaaa-0000-0000-0000-000000000001',
 'Magasin Shopi Vitrolles',
 '4 Rue Ernest Reyer, 13127 Vitrolles',
 'Magasin Shopi Vitrolles',
 'Vernier', 'Alya', '06 20 63 20 81', 'Assistante de direction'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Santo Pélissane',
 '974 Avenue du Général de Gaulle, 13330 Pélissane',
 'Santo',
 'Faurel', 'Milo', '06 20 63 20 85', 'Assistante de direction'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Super Achat Éguilles',
 '75 route des Milles, 13510 Éguilles',
 'Super Achat',
 'Jouflu', 'Valentin', '06 20 63 20 89', 'Assistante de direction'),

('aaaaaaaa-0000-0000-0000-000000000001',
 'Transport Jacki',
 '22 rue Boris Vian, 13730 Saint-Victoret',
 'Transport Jacki',
 'Noirel', 'Soren', '06 20 63 20 77', 'Assistante de direction');


-- ── 3. INSERTION DES AGENTS DE PROPRETÉ ──────────────────────────
-- site_principal_id sera lié après insertion des sites
-- Utilisez les UUID des sites depuis : SELECT id, nom FROM sites WHERE tenant_id = 'aaaaaaaa-...';

INSERT INTO agents (tenant_id, nom, prenom)
VALUES

-- Secteur Pierre CADRE
('aaaaaaaa-0000-0000-0000-000000000001', 'Silla',          'Fatou'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Alice',          'Giselle'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Dulac',          'Cloé'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Paz',            'Nicolas'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Jouque',         'Claire'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Nobi',           'Olivier'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Zidar',          'Zizane'),

-- Secteur Ali BENGER
('aaaaaaaa-0000-0000-0000-000000000001', 'El Zeri',        'Mariam'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Hernandes',      'Jacques'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Le Gros',        'Justin'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Origami',        'Paul'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Bourne',         'Jason'),
('aaaaaaaa-0000-0000-0000-000000000001', 'El Comri',       'Fleur'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Dos Santos',     'Ana'),

-- Secteur Anna RONALDO
('aaaaaaaa-0000-0000-0000-000000000001', 'Prereira',       'Luisa'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Poupou',         'Oli'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Coreia',         'Manuel'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Cancel',         'Lili'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Dupuis',         'Sylvie'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Brown',          'Jackie'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Diesel',         'Parfait'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Magrain',        'Élise'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Larou',          'Fatou'),

-- Secteur Jocelyne POURIOU
('aaaaaaaa-0000-0000-0000-000000000001', 'Dupont',         'Marc'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Montero',        'Manuel'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Repp',           'Jony'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Bonnaventure',   'Christ'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Jouan',          'Fabrice'),
('aaaaaaaa-0000-0000-0000-000000000001', 'Dubow',          'Elya');


-- ── 4. MISE À JOUR ADRESSE AGENCE APHS ───────────────────────────
UPDATE tenants
SET
  adresse   = '30 allée André-Marie Ampère, 13270 Fos-sur-Mer',
  telephone = '04 42 05 11 87'
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- Vérification
-- SELECT nom, adresse, telephone FROM tenants WHERE id = 'aaaaaaaa-0000-0000-0000-000000000001';
-- SELECT nom, contact_nom, contact_prenom, contact_tel FROM sites WHERE tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';
-- SELECT nom, prenom FROM agents WHERE tenant_id = 'aaaaaaaa-0000-0000-0000-000000000001';
