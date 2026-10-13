# BETSOCCER — AUDIT DES REPLICA SKILLS ET ALIGNEMENT MÉTHODOLOGIQUE (PHASE 0)

**Date d'audit :** 13 Octobre 2026  
**Auteur :** Architecte Logiciel Senior & Spécialiste Replica Skills  
**Projet :** BETSOCCER — Multisport Analytics AI  
**Statut :** AUDIT RÉALISÉ ET VALIDÉ (Conforme aux directives `/root/AGENTS.md`)

---

## 1. INVENTAIRE DES REPLICA SKILLS DÉTECTÉES

L'inspection de l'environnement Antigravity confirme la présence du référentiel complet de la suite **Replica Skill** dans `/root/.gemini/replica-skill`, avec des liens symboliques opérationnels dans `/root/.agents/skills/` et `/root/.gemini/config/skills/`.

Chaque compétence a été identifiée, et ses fichiers d'instructions `SKILL.md` ont été analysés pour déterminer son applicabilité au projet BETSOCCER.

| Compétence | Chemin d'accès | Rôle & Utilité dans le cadre de BETSOCCER | Statut d'audit |
| :--- | :--- | :--- | :--- |
| **`replica-recon`** | `/root/.agents/skills/replica-recon/SKILL.md` | Rétro-ingénierie des besoins, cartographie des flux utilisateurs (Live, Fixtures, Historique, Analyse), inventaire des écrans et matrice de fonctionnalités. | **ACTIF (Phase 0 / Phase 1)** |
| **`replica-architect`**| `/root/.agents/skills/replica-architect/SKILL.md` | Conception de la pile technique, du schéma relationnel SQL (Drift/SQLite) et des contrats d'API / repositories. | **ACTIF (Phase 0 / Phase 1)** |
| **`replica-design`** | `/root/.agents/skills/replica-design/SKILL.md` | Établissement du design system mobile : tokens de couleurs (thèmes sombre/clair contrastés), échelle typographique, espacements, états visuels des composants. | **ACTIF (Phase 2)** |
| **`replica-build`** | `/root/.agents/skills/replica-build/SKILL.md` | Construction incrémentale écran par écran en mode « Clean Room », du squelette applicatif à la tranche verticale complète, avec gestion stricte de tous les états (chargement, vide, erreur, succès). | **ACTIF (Phase 2 / Phase 3)** |
| **`replica-test`** | `/root/.agents/skills/replica-test/SKILL.md` | Planification et automatisation des tests unitaires, d'intégration, de non-régression et de robustesse hors-ligne. | **ACTIF (Transverse / Phase 4)** |
| **`replica-backend`** | `/root/.agents/skills/replica-backend/SKILL.md` | Implémentation de la couche d'accès aux données, des migrations de schémas locaux et de l'orchestration des connecteurs d'API sportives. | **ACTIF (Phase 1 / Phase 2)** |
| **`replica-diff`** | `/root/.agents/skills/replica-diff/SKILL.md` | Suivi de conformité par rapport à la matrice des exigences et aux spécifications cibles. | **ACTIF (Phase 4)** |
| **`replica-brand`** | `/root/.agents/skills/replica-brand/SKILL.md` | Identité visuelle, charte graphique et vérification de la pureté du code (absence de traces ou assets tiers indésirables). | **SUPPORT (Phase 2)** |
| **`replica-deploy`** | `/root/.agents/skills/replica-deploy/SKILL.md` | Automatisation CI/CD sur GitHub Actions, génération d'APK et conformité OTA selon `/root/AGENTS.md`. | **ACTIF (Phase 5)** |
| **`replica-entrepreneur`**| `/root/.agents/skills/replica-entrepreneur/SKILL.md`| Analyse des retours utilisateurs sur les applications d'analyse sportive pour identifier les lacunes du marché. | **OPTIONNEL (Veille)** |
| **`replica-launch`** | `/root/.agents/skills/replica-launch/SKILL.md` | Préparation de la fiche de publication et notes de version. | **SUPPORT (Phase 5)** |

---

## 2. ORDRE D'ENCHAÎNEMENT MÉTHODOLOGIQUE (WORKFLOW PAR PHASES)

Conformément à la directive impérative énoncée dans `/root/AGENTS.md`, le cycle de développement du projet BETSOCCER doit strictement respecter le flux séquentiel suivant :

```
[Phase 0] Audit, faisabilité, validation architecturale (ÉTAPE ACTUELLE)
    │
    ▼
[Phase 1] Reconnaissance & Architecture technique (`replica-recon` & `replica-architect`)
    - Initialisation du projet Flutter avec Application ID com.ghdinteractivestudio.betsoccer
    - Définition du schéma relationnel SQLite (Drift) et matrice des fonctionnalités
    - Mise en place du socle CI GitHub Actions (format, analyse, tests)
    │
    ▼
[Phase 2] Design Tokens & Infrastructure Données (`replica-design` & `replica-backend`)
    - Tokens de design, thèmes sombre/clair optimisés pour la lecture de statistiques
    - Couche data : Repositories, connecteurs openfootball / TheSportsDB
    - Moteur déterministe en Dart pur (Poisson, Dixon-Coles, Elo)
    │
    ▼
[Phase 3] Construction Clean Room Écran par Écran (`replica-build`)
    - Tranche verticale F01 (Matchs du jour -> Analyse prédictive -> Explication IA)
    - Écrans D1 (Live), D2 (À venir), D3 (Historique), D4 (Analyses statistiques), D5 (Assistant IA)
    - Gestion des 5 états obligatoires par composant : initial, loading, empty, error, filled
    │
    ▼
[Phase 4] Tests, Évaluation Statistique & Parité (`replica-test` & `replica-diff`)
    - Tests unitaires et backtesting sans fuite temporelle
    - Tests de résilience hors ligne et gestion des quotas 429
    - Validation de la couverture des fonctionnalités
    │
    ▼
[Phase 5] Déploiement & Intégrité OTA (`replica-deploy`)
    - Pipeline GitHub Actions de compilation Release APK avec SHA-256
    - Respect strict des mécanismes de mise à jour in-app v1.0.11
```

---

## 3. RÈGLES CLEAN ROOM APPLIQUÉES À BETSOCCER

Les principes directeurs de la suite Replica s'appliquent avec la plus haute rigueur au code source de BETSOCCER :
1. **Zéro copie de code propriétaire ou scraping clandestin :** Tout le code Flutter et Dart est écrit ex nihilo. Aucune ressource graphique, aucun logo protégé, aucun bundle JavaScript tiers n'est extrait ou injecté.
2. **Indépendance des données :** Utilisation exclusive de données ouvertes (domaine public CC0 pour `openfootball`) ou d'API ouvertes et dûment documentées.
3. **Moteur algorithmique maison :** Les formules mathématiques (loi de Poisson bivariée, correction de dépendance Dixon-Coles, notation Elo) sont implémentées en code Dart pur documenté, sans boîte noire.
4. **Pas d'hallucination IA :** L'intelligence artificielle est cantonnée à un rôle d'exégète et de vulgarisation : elle ne produit aucun chiffre ou cote, mais verbalise les conclusions du moteur déterministe.

---

## 4. RISQUES ET CRITÈRES D'ACCEPTATION

| Module Replica | Risques identifiés | Stratégie d'atténuation |
| :--- | :--- | :--- |
| `replica-recon` | Dispersion fonctionnelle sur trop de sports d'un coup | Focaliser la tranche verticale initiale sur le Football (Soccer), avec architecture extensible (Tennis, Basketball en Phase 2+). |
| `replica-architect` | Complexité excessive d'un backend distribué | Adoption du paradigme Offline-First avec base locale SQLite, annulant la dépendance à un serveur payant. |
| `replica-design` | Densité d'information illisible sur écran mobile | Hiérarchisation visuelle stricte : probabilités majeures (1N2) en haut, détails sous forme d'accordéons et onglets. |
| `replica-build` | Dégradation de fluidité lors des calculs statistiques | Exécution des calculs matriciels complexes dans des `Isolates` Dart d'arrière-plan pour maintenir 60/120 FPS constants. |
| `replica-test` | Biais de prédiction rétrospective (Data leakage) | Conception de tests de backtesting temporellement hermétiques ($t < t_{match}$). |

---

## 5. CONCLUSION DE L'ÉTAPE C

Les compétences de la suite Replica sont **intégralement opérationnelles**, parfaitement documentées dans l'environnement local et immédiatement mobilisables. Aucune réinstallation n'est requise.
