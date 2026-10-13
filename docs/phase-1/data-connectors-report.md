# BETSOCCER — RAPPORT D'ARCHITECTURE DES CONNECTEURS SPORTIFS

## 1. Interface Commune : `SportsDataSource`

Pour garantir l'interchangeabilité des sources et isoler la logique métier des formats hétérogènes des API externes, le contrat `SportsDataSource` (`lib/features/sports/domain/interfaces/sports_data_source.dart`) a été défini avec des indicateurs de capacité explicites :

```dart
abstract interface class SportsDataSource {
  String get providerId;
  String get displayName;
  bool get isEnabled;

  // Drapeaux de capacités (Capabilities)
  bool get supportsSportsDiscovery;
  bool get supportsCompetitions;
  bool get supportsUpcomingMatches;
  bool get supportsLiveMatches;
  bool get supportsHistoricalMatches;
  bool get supportsMatchDetails;

  // Méthodes d'ingestion normalisées
  Future<List<SportEntity>> fetchSports();
  Future<List<CompetitionEntity>> fetchCompetitions({required String sportId});
  Future<List<MatchEntity>> fetchUpcomingMatches({required String competitionId, DateTime? from, DateTime? to});
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId});
  Future<List<MatchEntity>> fetchHistoricalMatches({required String competitionId, required String season});
  Future<MatchEntity?> fetchMatchDetails({required String matchId});
}
```

Règle impérative : lorsqu'une opération n'est pas supportée par un fournisseur, elle retourne une liste vide ou lève une exception typée `UnsupportedFeatureException`. **Aucune donnée n'est jamais inventée ou extrapolée**.

---

## 2. Inventaire et Statut des Connecteurs Réalisés

| Connecteur | Fichier d'Implémentation | Statut | Coût | Capacité Principale |
| :--- | :--- | :---: | :---: | :--- |
| **OpenFootball** | `openfootball_data_source.dart` | **Actif** | 0 € (CC0) | Archives historiques locales / Premier League |
| **TheSportsDB** | `thesportsdb_data_source.dart` | **Actif** | 0 € (V1 Free) | Découverte sports, ligues, badges équipes |
| **Football-Data.org**| `football_data_org_data_source.dart`| **Configurable** | 0 € (Free Tier)| Matchs en direct & calendrier (10 req/min) |
| **MelBet** | `melbet_data_source.dart` | **DISABLED_BY_POLICY** | - | **Strictement bloqué par politique** |

---

## 3. Détails des Connecteurs

### 3.1 OpenFootball (`openfootball_data_source.dart` & `openfootball_parser.dart`)
- **Licence & Domaine** : Domaine Public (Creative Commons Zero CC0).
- **Format** : Fichiers texte tabulaires standard `Football.TXT`.
- **Archive intégrée** : `assets/data/historical/premier_league_2023_24.txt` (26 Ko, 20 équipes, 38 journées, 380 matchs complets avec scores finaux et mi-temps).
- **Particularités** :
  - Supporte `initialRawContent` pour une exécution ultra-rapide en mémoire sans dépendance d'accès système lors des tests unitaires.
  - Absence intentionnelle de flux live (lève `UnsupportedFeatureException`).

### 3.2 TheSportsDB (`thesportsdb_data_source.dart`)
- **Clé utilisée** : Clé publique de test officielle `'3'` (aucun abonnement payant requis).
- **Rôle** : Fourniture des métadonnées riches (logos, drapeaux de pays, descriptions de compétitions).
- **Endpoints** : `all_sports.php`, `all_leagues.php`, `searchteams.php`.

### 3.3 Football-Data.org (`football_data_org_data_source.dart`)
- **Quota gratuit** : 10 requêtes par minute, 12 compétitions majeures.
- **Gestion des erreurs** : Traduction automatique du code HTTP 429 en `RateLimitException`.
- **Sécurité** : Si aucune clé n'est fournie, le connecteur reste désactivé (`isEnabled: false`) et lève `AuthenticationException` sans dégrader le reste de l'application.

### 3.4 MelBet (`melbet_data_source.dart`)
- **Statut de conformité** : `DISABLED_BY_POLICY` immuable.
- **Raison technique et juridique** : Les conditions d'utilisation interdisent tout robot ou scraping, et aucune API publique autorisée n'existe.
- **Comportement logiciel** : Toutes les méthodes lèvent immédiatement `ConnectorDisabledException(reason: 'DISABLED_BY_POLICY')`. Aucun appel réseau n'est effectué.

---

## 4. Orchestration dans `SportsRepository`

`SportsRepository` applique la stratégie **Cache-Aside Offline-First** :
1. Recherche prioritaire dans la base locale SQLite via `SportsDao`.
2. Si les données sont absentes (ou en cas de `forceRefresh`), parcours des connecteurs actifs (`isEnabled == true` et drapeau de capacité vérifié).
3. Insertion en lot (batch) et transactionnelle dans SQLite.
4. Tolérance totale aux pannes : l'échec ou le rejet d'un connecteur n'interrompt pas la chaîne de traitement et n'affecte pas les données déjà en cache.
