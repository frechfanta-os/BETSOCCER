import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/interfaces/sports_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/config/app_config.dart';

/// Connecteur Football-Data.org (Plan Gratuit: 10 req/min, 12 compétitions majeures)
class FootballDataOrgDataSource implements SportsDataSource {
  final http.Client client;
  final String baseUrl;
  final String? apiKey;

  FootballDataOrgDataSource({
    http.Client? httpClient,
    String? customBaseUrl,
    String? customApiKey,
    String? apiKey,
  }) : client = httpClient ?? http.Client(),
       baseUrl = customBaseUrl ?? AppConfig.current.footballDataOrgBaseUrl,
       apiKey =
           apiKey ?? customApiKey ?? AppConfig.current.footballDataOrgApiKey;

  @override
  String get providerId => 'football_data_org';

  @override
  String get displayName => 'Football-Data.org (Plan Gratuit)';

  @override
  bool get isEnabled => apiKey != null && apiKey!.isNotEmpty;

  @override
  ConnectorAccessStatus get accessStatus => isEnabled
      ? ConnectorAccessStatus.available
      : ConnectorAccessStatus.authenticationRequired;

  @override
  DateTime? get lastCheckedAt => null;

  @override
  String? get lastError => isEnabled
      ? null
      : 'API key missing (football-data.org requires an API token)';

  @override
  List<String> get supportedDataTypes => const [
    'competitions',
    'upcoming_matches',
    'historical_matches',
    'match_details',
  ];

  @override
  bool get supportsSportsDiscovery => false; // Strictement dédié au Football

  @override
  bool get supportsCompetitions => true;

  @override
  bool get supportsUpcomingMatches => true;

  @override
  bool get supportsLiveMatches => true;

  @override
  bool get supportsHistoricalMatches => true;

  @override
  bool get supportsMatchDetails => true;

  Map<String, String> get _headers {
    final headers = <String, String>{'User-Agent': 'BETSOCCER/1.0'};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-Auth-Token'] = apiKey!;
    }
    return headers;
  }

  @override
  Future<List<SportEntity>> fetchSports() async {
    return const [
      SportEntity(
        id: 'sport_football',
        name: 'Football (Soccer)',
        code: 'SOCCER',
        iconRef: 'sports_soccer',
        sourceProvider: 'football_data_org',
      ),
    ];
  }

  @override
  Future<List<CompetitionEntity>> fetchCompetitions({
    required String sportId,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw const AuthenticationException(
        'Une clé API Football-Data.org valide est requise.',
      );
    }
    try {
      final uri = Uri.parse('$baseUrl/competitions');
      final response = await client.get(uri, headers: _headers);

      if (response.statusCode == 429) {
        throw const RateLimitException(
          'Limite de débit Football-Data.org atteinte (10 req/min).',
        );
      }
      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur Football-Data.org: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['competitions'] as List<dynamic>? ?? [];

      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final code = map['code'] as String? ?? 'COMP';
        return CompetitionEntity(
          id: 'fdo_${map['id']}',
          sportId: sportId,
          name: map['name'] as String? ?? 'Compétition',
          code: code,
          country: (map['area'] as Map<String, dynamic>?)?['name'] as String?,
          countryCode:
              (map['area'] as Map<String, dynamic>?)?['code'] as String?,
          badgeUrl: map['emblem'] as String?,
          tier: 1,
          sourceProvider: providerId,
        );
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Impossible de contacter Football-Data.org',
        null,
        e,
      );
    }
  }

  @override
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId}) async {
    if (apiKey == null || apiKey!.isEmpty) {
      // Sans clé API, l'endpoint /matches n'est pas accessible
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/matches?status=IN_PLAY,PAUSED');
      final response = await client.get(uri, headers: _headers);

      if (response.statusCode == 429) {
        throw const RateLimitException(
          'Limite de débit Football-Data.org atteinte (10 req/min).',
        );
      }
      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur Football-Data.org: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['matches'] as List<dynamic>? ?? [];
      final now = DateTime.now().toUtc();

      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final home = (m['homeTeam'] as Map<String, dynamic>?) ?? {};
        final away = (m['awayTeam'] as Map<String, dynamic>?) ?? {};
        final score = (m['score'] as Map<String, dynamic>?) ?? {};
        final fullTime = (score['fullTime'] as Map<String, dynamic>?) ?? {};

        final matchId = 'fdo_match_${m['id']}';

        return MatchEntity(
          id: matchId,
          sportId: 'sport_football',
          competitionId:
              'fdo_${(m['competition'] as Map<String, dynamic>?)?['id'] ?? 'unknown'}',
          homeTeamId: 'fdo_team_${home['id']}',
          homeTeamName: home['name'] as String? ?? 'Domicile',
          homeTeamBadge: home['crest'] as String?,
          awayTeamId: 'fdo_team_${away['id']}',
          awayTeamName: away['name'] as String? ?? 'Extérieur',
          awayTeamBadge: away['crest'] as String?,
          utcKickoff: DateTime.parse(m['utcDate'] as String).toUtc(),
          status: MatchStatus.live,
          matchday: m['matchday'] as int?,
          sourceProvider: providerId,
          sourceMatchId: m['id']?.toString(),
          lastSyncedAt: now,
          result: MatchResultEntity(
            id: 'res_$matchId',
            matchId: matchId,
            homeScore: fullTime['home'] as int?,
            awayScore: fullTime['away'] as int?,
          ),
        );
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erreur lors de la récupération des matchs en direct Football-Data.org',
        null,
        e,
      );
    }
  }

  @override
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  }) async {
    return [];
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
