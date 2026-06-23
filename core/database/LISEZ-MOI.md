# Guide d'installation Supabase — APO-SAAS

## Ordre d'exécution dans Supabase > SQL Editor

| Ordre | Fichier | Contenu |
|---|---|---|
| 1 | `01_schema.sql` | Tables, énumérations, index |
| 2 | `02_fonctions.sql` | Fonctions RLS + triggers |
| 3 | `03_rls_policies.sql` | Politiques d'accès par rôle |
| 4 | `04_donnees_test_aphs.sql` | Données pilote APHS |

## Avant le fichier 04

1. Aller dans **Supabase > Authentication > Users**
2. Créer les utilisateurs (directeur, AM1, AM2, CE1…)
3. Copier leurs **UUID**
4. Remplacer les `'REMPLACER-PAR-UUID-...'` dans le fichier 04
5. Exécuter

## Storage (coffre-fort agents)

Dans Supabase > Storage, créer un bucket privé nommé **`documents-agents`**

## Variables à noter pour le frontend

```
SUPABASE_URL = https://VOTRE-PROJET.supabase.co
SUPABASE_ANON_KEY = votre-clé-anon
```
