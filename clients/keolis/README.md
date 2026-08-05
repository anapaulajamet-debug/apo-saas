# Keolis – Suivi Nettoyage

Appli de suivi du nettoyage des arrêts de bus Keolis. Fichier HTML autonome + Firebase.

## Récupération

Application créée dans une conversation (hors Claude Code), hébergée sur **Netlify**,
données sur **Firebase Realtime Database**. Récupérée le 2026-08-05 depuis une copie locale
(`~/Downloads/keolis.html`) et remise sous Git dans `clients/keolis/index.html`.

## Rôles (login codé en dur dans `index.html`, objet `USERS`)

| Rôle    | Utilisateur | Fonctions |
|---------|-------------|-----------|
| admin   | Ana Paula   | Import Excel des sites, gestion des fréquences de nettoyage |
| agent   | Cyril       | Pointage sur site avec GPS + signalement d'anomalies |
| manager | Marvin      | Supervision : carte des pointages, stats du jour, export CSV |

## Technique

- **Firebase Realtime Database** — projet `keolis-nettoyage` (région europe-west1).
  Deux collections : `sites` et `pointages`.
- **Leaflet** + OpenStreetMap pour la carte des pointages (vue manager).
- **SheetJS (xlsx)** pour l'import Excel des sites (vue admin).
- Hébergement : **Netlify**.

## ⚠️ Points d'attention connus

1. **Pas d'auth Firebase réelle.** Le login est purement côté client (comparaison à `USERS`).
   L'appli lit/écrit dans la base sans s'authentifier → nécessite des **règles Firebase publiques**.
   Firebase verrouille automatiquement les règles « mode test » après 30 jours : si l'appli
   affiche des données vides ou ne sauvegarde plus, vérifier les règles dans la console.
2. **Mots de passe en clair** dans le code source (visibles par quiconque ouvre le fichier).
3. Config Firebase (clé API) exposée dans le HTML — normal pour Firebase web, mais la
   sécurité repose alors entièrement sur les règles de la base.

## Pistes d'évolution

- Authentification Firebase réelle + fermeture des règles.
- Sortir les identifiants du code source.
