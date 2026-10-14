import 'package:flutter/services.dart';

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/interfaces/sports_data_source.dart';
import '../parsers/openfootball_parser.dart';
import '../../../../core/errors/app_exception.dart';

/// Connecteur de données pour les archives OpenFootball (Domaine Public CC0)
class OpenFootballDataSource implements SportsDataSource {
  final String assetPath;
  ParsedOpenFootballDataset? _cachedDataset;

  OpenFootballDataSource({
    this.assetPath = 'assets/data/historical/premier_league_2023_24.txt',
    String? initialRawContent,
  }) {
    if (initialRawContent != null) {
      _cachedDataset = OpenFootballParser.parse(initialRawContent);
    }
  }

  @override
  String get providerId => 'openfootball';

  @override
  String get displayName => 'OpenFootball (Domaine Public CC0)';

  @override
  bool get isEnabled => true;

  @override
  ConnectorAccessStatus get accessStatus => ConnectorAccessStatus.available;

  @override
  DateTime? get lastCheckedAt => null;

  @override
  String? get lastError => null;

  @override
  List<String> get supportedDataTypes => const [
    'sports',
    'competitions',
    'matches',
    'historical_matches',
  ];

  @override
  bool get supportsSportsDiscovery => true;

  @override
  bool get supportsCompetitions => true;

  @override
  bool get supportsUpcomingMatches => true;

  @override
  bool get supportsLiveMatches => false; // Fichiers statiques, pas de flux temps réel direct

  @override
  bool get supportsHistoricalMatches => true;

  @override
  bool get supportsMatchDetails => true;

  Future<ParsedOpenFootballDataset> loadDataset({
    String? customRawContent,
  }) async {
    if (_cachedDataset != null && customRawContent == null) {
      return _cachedDataset!;
    }

    String content;
    if (customRawContent != null) {
      content = customRawContent;
    } else {
      try {
        content = await rootBundle.loadString(assetPath);
      } catch (e) {
        throw ParsingException(
          'Impossible de charger le fichier asset "$assetPath"',
          e,
        );
      }
    }

    _cachedDataset = OpenFootballParser.parse(content);
    return _cachedDataset!;
  }

  @override
  Future<List<SportEntity>> fetchSports() async {
    return const [
      SportEntity(
        id: 'sport_football',
        name: 'Football (Soccer)',
        code: 'SOCCER',
        iconRef: 'sports_soccer',
        sourceProvider: 'openfootball',
      ),
    ];
  }

  @override
  Future<List<CompetitionEntity>> fetchCompetitions({
    required String sportId,
  }) async {
    final dataset = await loadDataset();
    return [
      CompetitionEntity(
        id: 'comp_openfootball_epl',
        sportId: sportId,
        name: dataset.competitionName,
        code: 'EPL',
        country: 'Angleterre',
        countryCode: 'GB',
        tier: 1,
        sourceProvider: providerId,
      ),
    ];
  }

  @override
  Future<List<MatchEntity>> fetchHistoricalMatches({
    required String competitionId,
    required String season,
  }) async {
    final dataset = await loadDataset();
    final now = DateTime.now().toUtc();

    return dataset.matches.map((m) {
      final matchId =
          'of_${m.homeTeam.replaceAll(' ', '_')}_${m.awayTeam.replaceAll(' ', '_')}_${m.utcKickoff.millisecondsSinceEpoch}';

      MatchResultEntity? result;
      if (m.homeScore != null && m.awayScore != null) {
        result = MatchResultEntity(
          id: 'res_$matchId',
          matchId: matchId,
          homeScore: m.homeScore,
          awayScore: m.awayScore,
          homeHalftimeScore: m.homeHalftimeScore,
          awayHalftimeScore: m.awayHalftimeScore,
        );
      }

      return MatchEntity(
        id: matchId,
        sportId: 'sport_football',
        competitionId: competitionId,
        competitionName: dataset.competitionName,
        seasonId: dataset.seasonLabel,
        homeTeamId: 'team_${m.homeTeam.replaceAll(' ', '_')}',
        homeTeamName: m.homeTeam,
        awayTeamId: 'team_${m.awayTeam.replaceAll(' ', '_')}',
        awayTeamName: m.awayTeam,
        utcKickoff: m.utcKickoff,
        status: m.status,
        matchday: m.matchday,
        roundLabel: m.roundLabel,
        isSampleData: false,
        sourceProvider: providerId,
        sourceMatchId: matchId,
        lastSyncedAt: now,
        result: result,
      );
    }).toList();
  }

  @override
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fetchHistoricalMatches(
      competitionId: competitionId,
      season: '',
    );
    return all.where((m) => m.status == MatchStatus.upcoming).toList();
  }

  @override
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId}) async {
    // Règle impérative : Ne jamais inventer de données de direct
    throw UnsupportedFeatureException(
      providerId: providerId,
      feature: 'fetchLiveMatches',
      message: 'OpenFootball est un référentiel d\'archives historiques et ne fournit pas de flux live en temps réel.',
    );
  }

  @override
  Future<MatchEntity?> fetchMatchDetails({required String matchId}) async {
    final dataset = await loadDataset();
    final all = await fetchHistoricalMatches(
      competitionId: 'comp_openfootball_epl',
      season: dataset.seasonLabel,
    );
    try {
      return all.firstWhere((m) => m.id == matchId);
    } catch (_) {
      return null;
    }
  }
}
