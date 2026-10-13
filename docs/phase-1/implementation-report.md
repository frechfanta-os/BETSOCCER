# BETSOCCER — RAPPORT D'IMPLÉMENTATION DE LA PHASE 1

## 1. Vue d'Ensemble du Projet

- **Projet** : BETSOCCER — Multisport Analytics AI
- **Plateforme Prioritaire** : Android-First
- **Package ID** : `com.ghdinteractivestudio.betsoccer`
- **Cadre Technique** : Flutter 3.47 / Dart 3.13 / SQLite / Firebase
- **Objectif de la Phase 1** : Établir la fondation logicielle, le stockage local SQLite Offline-First, l'architecture modulaire de connecteurs interchangeables et l'interface utilisateur initiale.

---

## 2. Architecture Logicielle Réalisée

L'application repose sur les principes de la **Clean Architecture** et du paradigme **Offline-First** :

```
lib/
├── core/
│   ├── config/             # Configuration globale et URLs des fournisseurs
│   ├── database/           # Gestionnaire SQLite, migrations et DAOs
│   │   ├── daos/           # SportsDao (accès typé et transactions)
│   │   └── migrations/     # Schéma relationnel versionné V1
│   ├── errors/             # Hiérarchie scellée AppException et Failure UI
│   ├── services/           # FirebaseService et FirebaseSyncAdapter
│   ├── theme/              # Design tokens (AppColors, AppTheme clair/sombre)
│   └── utils/              # Formats de date UTC et utilitaires
├── features/
│   └── sports/
│       ├── data/
│       │   ├── parsers/    # OpenFootballParser (standard Football.TXT CC0)
│       │   └── sources/    # Connecteurs de données (OpenFootball, TheSportsDB, FootballDataOrg, MelBet)
│       ├── domain/
│       │   ├── entities/   # SportEntity, CompetitionEntity, MatchEntity, etc.
│       │   ├── interfaces/ # SportsDataSource (contrat unique d'ingestion)
│       │   └── repositories/ # SportsRepository (orchestration SQLite/Connecteurs)
│       └── presentation/
│           ├── controllers/# SportsController (ChangeNotifier réactif)
│           ├── screens/    # HomeScreen, LiveMatches, Upcoming, History, Settings
│           └── widgets/    # AppScaffold, MatchCard, StateViews (Loading, Empty, Error)
├── firebase_options.dart   # Configuration multiplateforme Firebase
└── main.dart               # Bootstrap et injection des dépendances
```

---

## 3. Modèle de Données & Schéma SQLite V1

Le fichier de migration `lib/core/database/migrations/v1_initial_schema.dart` crée 10 tables relationnelles normalisées avec contraintes de clés étrangères et index de performance :

1. `sports` : Disciplines sportives (Football, Basketball, Tennis, etc.).
2. `competitions` : Ligues et coupes (ex: Premier League).
3. `seasons` : Saisons temporelles rattachées aux compétitions.
4. `teams` : Équipes participantes.
5. `players` : Effectifs et joueurs.
6. `matches` : Rencontres sportives avec contrainte d'unicité `(competition_id, season_id, home_team_id, away_team_id, utc_kickoff)` pour éliminer tout risque de doublon.
7. `results` : Scores finaux, mi-temps et prolongations.
8. `match_statistics` : Statistiques détaillées de jeu (tirs, possession, fautes, corners).
9. `data_sources` : Registre des fournisseurs de données et état d'activation.
10. `sync_state` : Journalisation d'horodatage et volumétrie par source.

Toutes les dates sont stockées au format normalisé UTC ISO-8601.

---

## 4. Gestion d'État et Interface Utilisateur

- **Gestion d'État** : `SportsController` étend `ChangeNotifier` pour une réactivité fine sans dépendance superflue.
- **États d'Interface Normalisés** :
  - Écran de chargement (`LoadingView`).
  - Écran vide explicite avec bouton d'action contextuel (`EmptyStateView`).
  - Écran d'erreur sécurisé avec diagnostic technique (`ErrorView`).
  - Badge `ÉCHANTILLON` explicite sur toute donnée issue d'un jeu de démonstration ou d'archive locale afin de garantir la transparence pour l'utilisateur.
- **Navigation** : `BottomNavigationBar` fluide avec 5 destinations majeures :
  1. *Accueil* : Indicateurs métriques en direct, à venir et récents.
  2. *Direct* : Rencontres en direct avec rafraîchissement manuel.
  3. *À venir* : Calendrier des matchs programmés.
  4. *Historique* : Base de résultats passés avec scores mi-temps et finaux.
  5. *Paramètres* : État des sources, importation de jeux CC0, gouvernance de données et bascule de thème.

---

## 5. Gouvernance et Respect du Package ID

- **Package Android** : `com.ghdinteractivestudio.betsoccer` configuré rigoureusement dans `build.gradle.kts`, `AndroidManifest.xml` et vérifié par script d'analyse.
- **CI / Actions** : Workflows `.github/workflows/ci.yml` (qualité et tests automatiques) et `.github/workflows/build_apk.yml` (génération d'APK release, calcul SHA-256 et contrôle d'intégrité de l'application).
