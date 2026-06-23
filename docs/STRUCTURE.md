# APO-SAAS — Structure du projet

## Arborescence

```
APO-SAAS/
├── clients/
│   └── aphs/                    # Client pilote : APHS (Fos-sur-Mer)
│       ├── assets/              # Logo, images propres au client
│       ├── config/              # Config tenant : couleurs, modules actifs, champs
│       └── *.html               # Pages de l'application APHS
│
├── core/
│   ├── auth/                    # Connexion, sessions, rôles
│   ├── database/                # Schémas Supabase, migrations, policies RLS
│   └── api/                     # Appels Supabase côté client (JS)
│
├── modules/
│   ├── contrats/                # Contrats clients, avenants
│   ├── sites/                   # Sites de prestation, calcul marge 30 %
│   ├── agents/                  # Agents de propreté, CCN Propreté Col. A
│   ├── planning/                # Plannings hebdo / mensuel
│   ├── pointage/                # Pointage (QR code, GPS, manuel)
│   ├── qualite/                 # Audits, cahiers des charges, non-conformités
│   ├── facturation/             # Facturation, export Pennylane
│   ├── paie/                    # Export Silae, heures CCN
│   └── documents/               # GED — bon de commande, rapports
│
├── shared/
│   ├── components/              # Composants HTML réutilisables
│   ├── styles/                  # CSS global, variables couleurs par tenant
│   └── utils/                   # Fonctions JS communes (dates, formatage…)
│
├── admin/                       # Back-office APO Solutions (multi-tenant)
└── docs/                        # Documentation projet
```

## Stack technique
| Couche | Outil |
|---|---|
| Front | HTML · CSS · JS vanilla |
| Base de données | Supabase (PostgreSQL · EU) |
| Hébergement | Vercel (phase pilote) |
| Versioning | GitHub |
| Automatisations | Make |
| Signature | YouSign |
| Paie | Silae (CCN Propreté Col. A) |
| Comptabilité | Pennylane |

## Règles métier clés
- Alerte marge < 30 % par site
- Multi-tenant : isolation par `tenant_id`
- CCN Propreté Colonne A uniquement
- Chaque client : logo, couleurs, modules actifs configurables
