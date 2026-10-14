import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/interfaces/sports_data_source.dart';
import '../../../../core/errors/app_exception.dart';

/// Connecteur MelBet — STRICTEMENT DÉSACTIVÉ PAR POLITIQUE (DISABLED_BY_POLICY)
///
/// Conformément au rapport d'audit "docs/phase-0/melbet-data-access-audit.md" :
/// - Aucune API publique autorisée n'est disponible.
/// - Les conditions générales d'utilisation interdisent formellement les robots et le scraping.
/// - Tout appel aux endpoints internes non documentés est proscrit.
class MelbetDataSource implements SportsDataSource {
  final bool enabled;
  final ConnectorAccessStatus configuredAccessStatus;
  final String? customReason;
  final DateTime? lastChecked;
  final String? lastErrorMessage;

  MelbetDataSource({
    this.enabled = false,
    this.configuredAccessStatus = ConnectorAccessStatus.disabledByPolicy,
    this.customReason,
    this.lastChecked,
    this.lastErrorMessage,
  });

  static const String policyReason =
      'DISABLED_BY_POLICY : Le scraping et l\'accès aux flux internes MelBet sont interdits par les CGU du site et la politique de sécurité du projet BETSOCCER.';

  @override
  String get providerId => 'melbet_restricted';

  @override
  String get displayName => 'MelBet (Désactivé par politique)';

  @override
  bool get isEnabled => enabled;

  @override
  ConnectorAccessStatus get accessStatus => configuredAccessStatus;

  @override
  DateTime? get lastCheckedAt => lastChecked;

  @override
  String? get lastError =>
      lastErrorMessage ?? (enabled ? null : (customReason ?? policyReason));

  @override
  List<String> get supportedDataTypes => const [];

  @override
  bool get supportsSportsDiscovery => false;

  @override
  bool get supportsCompetitions => false;

  @override
  bool get supportsUpcomingMatches => false;

  @override
  bool get supportsLiveMatches => false;

  @override
  bool get supportsHistoricalMatches => false;

  @override
  bool get supportsMatchDetails => false;

  Never _throwDisabled() {
    throw ConnectorDisabledException(
      providerId: 'melbet_restricted',
      reason: customReason ?? policyReason,
    );
  }

  @override
  Future<List<SportEntity>> fetchSports() async {
    _throwDisabled();
  }

  @override
  Future<List<CompetitionEntity>> fetchCompetitions({
    required String sportId,
  }) async {
    _throwDisabled();
  }

  @override
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  }) async {
    _throwDisabled();
  }

  @override
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId}) async {
    _throwDisabled();
  }

  @override
  Future<List<MatchEntity>> fetchHistoricalMatches({
    required String competitionId,
    required String season,
  }) async {
    _throwDisabled();
  }

  @override
  Future<MatchEntity?> fetchMatchDetails({required String matchId}) async {
    _throwDisabled();
  }
}
