# BETSOCCER — Multisport Analytics AI

> **Application Android d'analyse statistique sportive multi-sports propulsée par un moteur mathématique déterministe et enrichie par une assistance IA explicative.**

---

## 1. Vue d'ensemble du Projet

- **Organisation :** `com.ghdinteractivestudio`
- **Application ID :** `com.ghdinteractivestudio.betsoccer`
- **Dépôt officiel :** [https://github.com/frechfanta-os/BETSOCCER](https://github.com/frechfanta-os/BETSOCCER)
- **Framework :** Flutter 3.47 / Dart 3.13 (Android-first)
- **Persistance :** SQLite local (`sqflite`) — Approche *Offline-First* souveraine
- **Cloud & Sync :** Firebase (`betsoccer-60834`) — Préférences utilisateur & Thème (0 €)
- **Données sportives :** OpenFootball (CC0 1.0 Universal), TheSportsDB, Football-Data.org
- **Politique MelBet :** `DISABLED_BY_POLICY` (Scraping interdit)

---

## 2. Documentation du Projet

### Phase 0 — Audit & Faisabilité
L'ensemble des livrables de Phase 0 est consultable dans [`docs/phase-0/`](docs/phase-0/) :
- [**audit-report.md**](docs/phase-0/audit-report.md) : Audit du dépôt distant GitHub et conformité.
- [**environment-report.md**](docs/phase-0/environment-report.md) : Audit de l'environnement matériel, PRoot, Flutter, Dart.
- [**replica-skills-report.md**](docs/phase-0/replica-skills-report.md) : Inventaire des compétences Replica et méthode Clean Room.
- [**data-sources-report.md**](docs/phase-0/data-sources-report.md) : Qualification des sources de données.
- [**backend-comparison.md**](docs/phase-0/backend-comparison.md) : Justification de l'approche hybride Offline-First.
- [**architecture-proposal.md**](docs/phase-0/architecture-proposal.md) : Architecture cible Clean Architecture / Feature-First.
- [**security-review.md**](docs/phase-0/security-review.md) : Revue de sécurité, secrets et OTA.
- [**implementation-roadmap.md**](docs/phase-0/implementation-roadmap.md) : Feuille de route d'implémentation.
- [**decisions.md**](docs/phase-0/decisions.md) : Registre des décisions d'architecture (ADR-001 à ADR-007).
- [**melbet-data-access-audit.md**](docs/phase-0/melbet-data-access-audit.md) : Audit prioritaire de non-faisabilité MelBet.

### Phase 1 — Fondation & Connecteurs Sportifs
Les rapports de Phase 1 et de l'intégration Firebase sont consultables dans [`docs/phase-1/`](docs/phase-1/) et [`docs/`](docs/) :
- [**implementation-report.md**](docs/phase-1/implementation-report.md) : Implémentation du socle Flutter, SQLite V1 et contrôleur réactif.
- [**data-connectors-report.md**](docs/phase-1/data-connectors-report.md) : Spécification de `SportsDataSource` et des connecteurs.
- [**testing-report.md**](docs/phase-1/testing-report.md) : Rapport complet des tests (25 tests passés avec 100% de réussite).
### Phase 1.5 — Audit Global des Sources Sportives & Scraping
L'ensemble des livrables de l'audit approfondi des 12 sources sportives est consultable dans [`docs/phase-1.5/`](docs/phase-1.5/) :
- [**source-inventory.md**](docs/phase-1.5/source-inventory.md) : Fiches d'identité détaillées des 12 sources analysées.
- [**source-comparison.md**](docs/phase-1.5/source-comparison.md) : Matrice comparative globale et 3 classements spécialisés.
- [**scraping-test-results.md**](docs/phase-1.5/scraping-test-results.md) : Relevés de mesures empiriques, tests REST et analyse anti-bot.
- [**sports-coverage-matrix.md**](docs/phase-1.5/sports-coverage-matrix.md) : Matrice de couverture vérifiée par discipline sportive.
- [**legal-and-licensing-review.md**](docs/phase-1.5/legal-and-licensing-review.md) : Analyse juridique (droit d'auteur, droit *sui generis*, jurisprudence et RGPD).
- [**recommended-data-architecture.md**](docs/phase-1.5/recommended-data-architecture.md) : Architecture de collecte, déduplication et stabilité du schéma SQLite V1.
- [**audit-summary.md**](docs/phase-1.5/audit-summary.md) : Synthèse décisionnelle exécutive répondant aux 11 questions clés.

---

## 3. Statut d'Avancement des Phases

- [x] **Phase 0 :** Audit complet, faisabilité et validation architecturale (Terminée).
- [x] **Phase 1 :** Socle technique Flutter Android-First, base SQLite V1, connecteurs de données, intégration Firebase & CI GitHub Actions (Terminée).
- [x] **Phase 1.5 :** Audit global des sources sportives, du scraping et des résultats (Terminée).
- [ ] **Phase 2 :** Moteur statistique déterministe (Loi de Poisson, Dixon-Coles, Elo) & Design Tokens.
- [ ] **Phase 3 :** Tranche verticale & Écrans métiers complets (Live, Fixtures, Historique, Filtres).
- [ ] **Phase 4 :** Orchestration IA OpenRouter, Backtesting temporel & QA.
- [ ] **Phase 5 :** Automatisation CI/CD, Compilation APK Release & Intégrité OTA.

---

## 4. Commandes de Développement & Validation

```bash
# Formater le code Dart
dart format .

# Analyse statique (0 erreur requise)
flutter analyze

# Exécuter les tests automatisés
flutter test
```
