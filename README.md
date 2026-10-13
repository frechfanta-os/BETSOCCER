# BETSOCCER — Multisport Analytics AI

> **Application Android d'analyse statistique sportive multi-sports propulsée par un moteur mathématique déterministe et enrichie par une assistance IA explicative.**

---

## 1. Vue d'ensemble du Projet

- **Organisation :** `com.ghdinteractivestudio`
- **Application ID :** `com.ghdinteractivestudio.betsoccer`
- **Dépôt officiel :** [https://github.com/frechfanta-os/BETSOCCER](https://github.com/frechfanta-os/BETSOCCER)
- **Framework :** Flutter / Dart (Android-first)
- **Persistance :** SQLite local (Drift) — Approche *Offline-First*
- **Intelligence Artificielle :** OpenRouter (Fournisseurs multiples, modèles gratuits avec fallback)
- **Données sportives :** OpenFootball (CC0 1.0 Universal), TheSportsDB, Football-Data.org

---

## 2. Documentation de la Phase 0 (Audit & Faisabilité)

La Phase 0 a produit un audit exhaustif et validé de faisabilité logicielle et d'architecture. L'ensemble des livrables est consultable dans le répertoire [`docs/phase-0/`](docs/phase-0/) :

- [**audit-report.md**](docs/phase-0/audit-report.md) : Audit du dépôt distant GitHub et conformité.
- [**environment-report.md**](docs/phase-0/environment-report.md) : Audit de l'environnement matériel, PRoot, Flutter, Dart et vérification des accès.
- [**replica-skills-report.md**](docs/phase-0/replica-skills-report.md) : Inventaire des compétences Replica et méthode de développement Clean Room.
- [**data-sources-report.md**](docs/phase-0/data-sources-report.md) : Étude comparative des sources de données et statuts de qualification.
- [**backend-comparison.md**](docs/phase-0/backend-comparison.md) : Comparaison des architectures backends et justification du choix Offline-First hybride.
- [**architecture-proposal.md**](docs/phase-0/architecture-proposal.md) : Architecture logicielle cible Clean Architecture / Feature-First.
- [**security-review.md**](docs/phase-0/security-review.md) : Revue de sécurité, cycle de vie des secrets et standard OTA.
- [**implementation-roadmap.md**](docs/phase-0/implementation-roadmap.md) : Feuille de route détaillée pour la Phase 1 et les phases suivantes.
- [**decisions.md**](docs/phase-0/decisions.md) : Registre des décisions d'architecture (ADR-001 à ADR-007).

---

## 3. Statut du Projet

- [x] **Phase 0 :** Audit complet, faisabilité et validation architecturale (Terminée).
- [ ] **Phase 1 :** Socle technique Flutter, SQLite local & pipeline CI GitHub Actions.
- [ ] **Phase 2 :** Moteur statistique déterministe (Poisson, Dixon-Coles, Elo) & Design Tokens.
- [ ] **Phase 3 :** Tranche verticale & Écrans métiers (D1 Live, D2 Fixtures, D3 Historique, D4 Stats, D5 IA).
- [ ] **Phase 4 :** Orchestration IA OpenRouter, Backtesting temporel & QA.
- [ ] **Phase 5 :** Automatisation CI/CD, Compilation APK Release & Intégrité OTA.
