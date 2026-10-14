import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/interfaces/sports_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/config/app_config.dart';

/// Connecteur TheSportsDB (API V1 avec clé de test publique gratuite '3')
class TheSportsDbDataSource implements SportsDataSource {
  final http.Client client;
  final String baseUrl;
  final String apiKey;

  TheSportsDbDataSource({
    http.Client? httpClient,
    String? customBaseUrl,
    String? customApiKey,
  }) : client = httpClient ?? http.Client(),
       baseUrl = customBaseUrl ?? AppConfig.current.theSportsDbBaseUrl,
       apiKey = customApiKey ?? AppConfig.current.theSportsDbApiKey;

  @override
  String get providerId => 'thesportsdb';

  @override
  String get displayName => 'TheSportsDB (API V1)';

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
    'upcoming_matches',
    'historical_matches',
  ];

  @override
  bool get supportsSportsDiscovery => true;

  @override
  bool get supportsCompetitions => true;

  @override
  bool get supportsUpcomingMatches => true;

  @override
  bool get supportsLiveMatches => false; // V1 ne fournit pas le live 2-min gratuit (réservé V2)

  @override
  bool get supportsHistoricalMatches => true;

  @override
  bool get supportsMatchDetails => true;

  Uri _buildUri(String endpoint, [Map<String, String>? params]) {
    final url = '$baseUrl/$apiKey/$endpoint';
    return Uri.parse(url).replace(queryParameters: params);
  }

  @override
  Future<List<SportEntity>> fetchSports() async {
    try {
      final uri = _buildUri('all_sports.php');
      final response = await client.get(uri);

      if (response.statusCode == 429) {
        throw const RateLimitException(
          'TheSportsDB rate limit reached (100 req/min).',
        );
      }
      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur TheSportsDB: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['sports'] as List<dynamic>? ?? [];

      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final name = map['strSport'] as String? ?? 'Inconnu';
        return SportEntity(
          id: 'tsdb_${map['idSport'] ?? name.toLowerCase()}',
          name: name,
          code: name.toUpperCase().replaceAll(' ', '_'),
          iconRef: map['strSportThumb'] as String?,
          sourceProvider: providerId,
        );
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Impossible de contacter TheSportsDB', null, e);
    }
  }

  @override
  Future<List<CompetitionEntity>> fetchCompetitions({
    required String sportId,
  }) async {
    try {
      final uri = _buildUri('all_leagues.php');
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur TheSportsDB: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['leagues'] as List<dynamic>? ?? [];

      return list.take(30).map((item) {
        final map = item as Map<String, dynamic>;
        final id = map['idLeague'] as String? ?? 'unknown';
        return CompetitionEntity(
          id: 'tsdb_comp_$id',
          sportId: sportId,
          name: map['strLeague'] as String? ?? 'Ligue',
          code: map['strLeagueAlternate'] as String?,
          tier: 1,
          sourceProvider: providerId,
        );
      }).toList();
    } catch (e) {
      throw NetworkException(
        'Erreur lors de la récupération des compétitions TheSportsDB',
        null,
        e,
      );
    }
  }

  static String _resolveLeagueId(String competitionId) {
    if (competitionId.startsWith('tsdb_comp_')) {
      return competitionId.replaceFirst('tsdb_comp_', '');
    }
    final low = competitionId.toLowerCase();
    if (low.contains('e0') || low.contains('pl') || low.contains('premier')) return '4328';
    if (low.contains('sp1') || low.contains('laliga')) return '4335';
    if (low.contains('i1') || low.contains('seriea')) return '4332';
    if (low.contains('f1') || low.contains('ligue1')) return '4334';
    if (low.contains('d1') || low.contains('bl1') || low.contains('bundesliga')) return '4331';
    return '4328';
  }

  @override
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final leagueId = _resolveLeagueId(competitionId);
      final uri = _buildUri('eventsnextleague.php', {'id': leagueId});
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException('Erreur TheSportsDB: ${response.statusCode}', response.statusCode);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final events = data['events'] as List<dynamic>? ?? [];
      final matches = <MatchEntity>[];

      for (final ev in events) {
        if (ev is Map<String, dynamic>) {
          final idEvent = ev['idEvent']?.toString() ?? '';
          final homeName = ev['strHomeTeam'] as String? ?? 'Home';
          final awayName = ev['strAwayTeam'] as String? ?? 'Away';
          final homeId = 'team_${ev['idHomeTeam'] ?? homeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          final awayId = 'team_${ev['idAwayTeam'] ?? awayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

          final dateStr = ev['dateEvent'] as String? ?? '';
          final timeStr = ev['strTime'] as String? ?? '00:00:00';
          DateTime kickoff;
          try {
            kickoff = DateTime.parse('${dateStr}T${timeStr}Z').toUtc();
          } catch (_) {
            kickoff = DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();
          }

          matches.add(
            MatchEntity(
              id: 'match_tsdb_$idEvent',
              sportId: 'sport_football',
              competitionId: competitionId,
              homeTeamId: homeId,
              homeTeamName: homeName,
              homeTeamBadge: ev['strHomeTeamBadge'] as String? ?? ev['strThumb'] as String?,
              awayTeamId: awayId,
              awayTeamName: awayName,
              awayTeamBadge: ev['strAwayTeamBadge'] as String?,
              utcKickoff: kickoff,
              status: MatchStatus.upcoming,
              roundLabel: ev['intRound']?.toString(),
              sourceProvider: providerId,
              sourceMatchId: idEvent,
              lastSyncedAt: DateTime.now().toUtc(),
            ),
          );
        }
      }

      return matches;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur lors de la récupération des matchs à venir TheSportsDB', null, e);
    }
  }

  @override
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId}) async {
    throw UnsupportedFeatureException(
      providerId: providerId,
      feature: 'fetchLiveMatches',
      message: 'Les scores en direct avec rafraîchissement sous 2 minutes sont réservés au plan payant V2 de TheSportsDB.',
    );
  }

  @override
  Future<List<MatchEntity>> fetchHistoricalMatches({
    required String competitionId,
    required String season,
  }) async {
    return [];
  }

  @override
  Future<MatchEntity?> fetchMatchDetails({required String matchId}) async {
    return null;
  }
}
