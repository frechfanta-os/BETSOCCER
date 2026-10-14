import '../entities/sport.dart';
import '../entities/competition.dart';
import '../entities/match.dart';

/// Statut d'accessibilité et de conformité d'un connecteur de données sportives
enum ConnectorAccessStatus {
  /// Connecteur actif et pleinement disponible
  available,

  /// Désactivé via la configuration de l'application
  disabledByConfig,

  /// Restreint par les directives robots.txt du fournisseur
  restrictedByRobotsTxt,

  /// Bloqué par les défenses anti-bot (Cloudflare, firewall, timeout)
  antiBotBlocked,

  /// Strictement désactivé par politique interne du projet (ex: CGU, paris/cotes)
  disabledByPolicy,

  /// Clé d'API ou authentification requise mais manquante
  authenticationRequired,

  /// Quota d'appels temporairement dépassé
  rateLimited,
}

/// Interface commune et contrat universel des fournisseurs de données sportives
abstract interface class SportsDataSource {
  /// Identifiant unique du fournisseur (ex: "openfootball", "thesportsdb", "football_data_org", "melbet_restricted")
  String get providerId;

  /// Nom d'affichage lisible
  String get displayName;

  /// Indique si le connecteur est activé selon les règles de gouvernance
  bool get isEnabled;

  /// Statut détaillé d'accès et d'observabilité
  ConnectorAccessStatus get accessStatus;

  /// Horodatage de la dernière vérification d'accès
  DateTime? get lastCheckedAt;

  /// Dernier message d'erreur ou motif de restriction
  String? get lastError;

  /// Types de données pris en charge (ex: 'sports', 'competitions', 'matches')
  List<String> get supportedDataTypes;

  /// Capacités déclarées par le connecteur
  bool get supportsSportsDiscovery;
  bool get supportsCompetitions;
  bool get supportsUpcomingMatches;
  bool get supportsLiveMatches;
  bool get supportsHistoricalMatches;
  bool get supportsMatchDetails;

  /// 1. Découverte de la liste des sports proposés
  Future<List<SportEntity>> fetchSports();

  /// 2. Consultation des compétitions pour une discipline donnée
  Future<List<CompetitionEntity>> fetchCompetitions({required String sportId});

  /// 3. Consultation du calendrier des rencontres à venir
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  });

  /// 4. Consultation des matchs en direct (scores, état de jeu)
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId});

  /// 5. Consultation des résultats historiques d'une saison
  Future<List<MatchEntity>> fetchHistoricalMatches({
    required String competitionId,
    required String season,
  });

  /// 6. Récupération des détails complets d'une rencontre
  Future<MatchEntity?> fetchMatchDetails({required String matchId});
}
