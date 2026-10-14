import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/interfaces/sports_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/config/app_config.dart';

/// Connecteur officiel OpenLigaDB (API Ouverte Gratuite sans clé)
/// Fournit les rencontres en direct (Live), l'avant-match (Fixtures) et l'historique
class OpenLigaDbDataSource implements SportsDataSource {
  final http.Client client;
  final String baseUrl;

  OpenLigaDbDataSource({http.Client? httpClient, String? customBaseUrl})
    : client = httpClient ?? http.Client(),
      baseUrl = customBaseUrl ?? AppConfig.current.openLigaDbBaseUrl;

  @override
  String get providerId => 'openligadb';

  @override
  String get displayName => 'OpenLigaDB (API Ouverte Gratuite)';

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
    'live_matches',
    'historical_matches',
    'match_details',
  ];

  @override
  bool get supportsSportsDiscovery => true;

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

  // Compétitions configurées par défaut
  static const Map<String, Map<String, String>> defaultLeagues = {
    'bl1': {
      'id': 'comp_old_bl1',
      'name': '1. Bundesliga',
      'code': 'BL1',
      'sportId': 'sport_football',
      'sportName': 'Football',
    },
    'bl2': {
      'id': 'comp_old_bl2',
      'name': '2. Bundesliga',
      'code': 'BL2',
      'sportId': 'sport_football',
      'sportName': 'Football',
    },
    'hbl': {
      'id': 'comp_old_hbl',
      'name': 'Handball Bundesliga',
      'code': 'HBL',
      'sportId': 'sport_handball',
      'sportName': 'Handball',
    },
    'vblf1': {
      'id': 'comp_old_vblf1',
      'name': 'Volleyball Bundesliga Frauen',
      'code': 'VBLF1',
      'sportId': 'sport_volleyball',
      'sportName': 'Volleyball',
    },
  };

  String _resolveLeagueShortcut(String competitionId) {
    for (final entry in defaultLeagues.entries) {
      if (entry.value['id'] == competitionId ||
          entry.key == competitionId.toLowerCase()) {
        return entry.key;
      }
    }
    // Si contient 'bl2', 'hbl', 'vblf1' sinon défaut bl1
    final low = competitionId.toLowerCase();
    if (low.contains('bl2')) return 'bl2';
    if (low.contains('hbl')) return 'hbl';
    if (low.contains('vblf1')) return 'vblf1';
    return 'bl1';
  }

  @override
  Future<List<SportEntity>> fetchSports() async {
    return const [
      SportEntity(
        id: 'sport_football',
        name: 'Football',
        code: 'SOCCER',
        sourceProvider: 'openligadb',
      ),
      SportEntity(
        id: 'sport_handball',
        name: 'Handball',
        code: 'HANDBALL',
        sourceProvider: 'openligadb',
      ),
      SportEntity(
        id: 'sport_volleyball',
        name: 'Volleyball',
        code: 'VOLLEYBALL',
        sourceProvider: 'openligadb',
      ),
    ];
  }

  @override
  Future<List<CompetitionEntity>> fetchCompetitions({
    required String sportId,
  }) async {
    final filtered = defaultLeagues.values.where(
      (l) => l['sportId'] == sportId,
    );
    return filtered.map((l) {
      return CompetitionEntity(
        id: l['id']!,
        sportId: l['sportId']!,
        name: l['name']!,
        code: l['code'],
        tier: 1,
        sourceProvider: providerId,
      );
    }).toList();
  }

  @override
  Future<List<MatchEntity>> fetchUpcomingMatches({
    required String competitionId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final shortcut = _resolveLeagueShortcut(competitionId);
      final uri = Uri.parse('$baseUrl/getmatchdata/$shortcut');
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur OpenLigaDB: ${response.statusCode}',
          response.statusCode,
        );
      }

      final list = jsonDecode(response.body) as List<dynamic>? ?? [];
      final matches = <MatchEntity>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final isFinished = map['matchIsFinished'] as bool? ?? false;

        // Seuls les matchs non terminés correspondent aux rencontres à venir
        if (!isFinished) {
          final m = _parseMatch(map, competitionId, MatchStatus.upcoming);
          if (m != null) matches.add(m);
        }
      }

      return matches;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        'Impossible de récupérer les matchs à venir OpenLigaDB',
        null,
        e,
      );
    }
  }

  @override
  Future<List<MatchEntity>> fetchLiveMatches({String? sportId}) async {
    try {
      final shortcut = sportId == 'sport_handball' ? 'hbl' : 'bl1';
      final uri = Uri.parse('$baseUrl/getmatchdata/$shortcut');
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur OpenLigaDB: ${response.statusCode}',
          response.statusCode,
        );
      }

      final list = jsonDecode(response.body) as List<dynamic>? ?? [];
      final matches = <MatchEntity>[];
      final now = DateTime.now().toUtc();

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final isFinished = map['matchIsFinished'] as bool? ?? false;
        final kickoffStr = map['matchDateTimeUTC'] as String?;
        if (kickoffStr == null) continue;

        final kickoff = DateTime.tryParse(kickoffStr)?.toUtc() ?? now;
        final diffHours = now.difference(kickoff).inHours;

        // Si non terminé et commencé depuis moins de 3 heures -> en direct
        if (!isFinished && diffHours >= 0 && diffHours <= 3) {
          final m = _parseMatch(
            map,
            defaultLeagues[shortcut]!['id']!,
            MatchStatus.live,
          );
          if (m != null) matches.add(m);
        }
      }

      return matches;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        'Impossible de récupérer les matchs en direct OpenLigaDB',
        null,
        e,
      );
    }
  }

  @override
  Future<List<MatchEntity>> fetchHistoricalMatches({
    required String competitionId,
    required String season,
  }) async {
    try {
      final shortcut = _resolveLeagueShortcut(competitionId);
      final seasonYear = season.contains('/') ? season.split('/')[0] : season;
      final uri = Uri.parse('$baseUrl/getmatchdata/$shortcut/$seasonYear');
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Erreur OpenLigaDB: ${response.statusCode}',
          response.statusCode,
        );
      }

      final list = jsonDecode(response.body) as List<dynamic>? ?? [];
      final matches = <MatchEntity>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final isFinished = map['matchIsFinished'] as bool? ?? false;
        if (isFinished) {
          final m = _parseMatch(map, competitionId, MatchStatus.finished);
          if (m != null) matches.add(m);
        }
      }

      return matches;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        'Impossible de récupérer l\'historique OpenLigaDB',
        null,
        e,
      );
    }
  }

  @override
  Future<MatchEntity?> fetchMatchDetails({required String matchId}) async {
    try {
      final cleanId = matchId.replaceAll('match_old_', '');
      final uri = Uri.parse('$baseUrl/getmatchdata/$cleanId');
      final response = await client.get(uri);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final isFinished = data['matchIsFinished'] as bool? ?? false;
        return _parseMatch(
          data,
          'comp_old_bl1',
          isFinished ? MatchStatus.finished : MatchStatus.upcoming,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  MatchEntity? _parseMatch(
    Map<String, dynamic> item,
    String competitionId,
    MatchStatus fallbackStatus,
  ) {
    try {
      final matchIdNum = item['matchID']?.toString() ?? '';
      final t1 = item['team1'] as Map<String, dynamic>? ?? {};
      final t2 = item['team2'] as Map<String, dynamic>? ?? {};

      final homeName = (t1['teamName'] as String?)?.trim() ?? 'Équipe Domicile';
      final awayName =
          (t2['teamName'] as String?)?.trim() ?? 'Équipe Extérieur';
      final homeId =
          'team_${t1['teamId'] ?? homeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      final awayId =
          'team_${t2['teamId'] ?? awayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

      final kickoffStr =
          item['matchDateTimeUTC'] as String? ??
          item['matchDateTime'] as String?;
      final utcKickoff = kickoffStr != null
          ? (DateTime.tryParse(kickoffStr)?.toUtc() ?? DateTime.now().toUtc())
          : DateTime.now().toUtc();

      final isFinished = item['matchIsFinished'] as bool? ?? false;
      final status = isFinished ? MatchStatus.finished : fallbackStatus;

      // Extraction des résultats
      MatchResultEntity? result;
      final resultsList = item['matchResults'] as List<dynamic>? ?? [];
      int? homeScore;
      int? awayScore;
      int? homeHtScore;
      int? awayHtScore;

      for (final r in resultsList) {
        if (r is Map<String, dynamic>) {
          final orderId = r['resultOrderID'] as int? ?? 0;
          final rName = (r['resultName'] as String? ?? '').toLowerCase();
          final p1 = r['pointsTeam1'] as int?;
          final p2 = r['pointsTeam2'] as int?;

          if (orderId == 2 || rName.contains('endergebnis')) {
            homeScore = p1;
            awayScore = p2;
          } else if (orderId == 1 || rName.contains('halbzeit')) {
            homeHtScore = p1;
            awayHtScore = p2;
          }
        }
      }

      if (homeScore != null && awayScore != null) {
        String? winnerId;
        if (homeScore > awayScore) {
          winnerId = homeId;
        } else if (awayScore > homeScore) {
          winnerId = awayId;
        }

        result = MatchResultEntity(
          id: 'res_old_$matchIdNum',
          matchId: 'match_old_$matchIdNum',
          homeScore: homeScore,
          awayScore: awayScore,
          homeHalftimeScore: homeHtScore,
          awayHalftimeScore: awayHtScore,
          winnerTeamId: winnerId,
        );
      }

      final group = item['group'] as Map<String, dynamic>? ?? {};
      final matchday = group['groupOrderID'] as int?;
      final roundLabel = group['groupName'] as String?;

      return MatchEntity(
        id: 'match_old_$matchIdNum',
        sportId: 'sport_football',
        competitionId: competitionId,
        homeTeamId: homeId,
        homeTeamName: homeName,
        homeTeamBadge: t1['teamIconUrl'] as String?,
        awayTeamId: awayId,
        awayTeamName: awayName,
        awayTeamBadge: t2['teamIconUrl'] as String?,
        utcKickoff: utcKickoff,
        status: status,
        matchday: matchday,
        roundLabel: roundLabel,
        sourceProvider: providerId,
        sourceMatchId: matchIdNum,
        lastSyncedAt: DateTime.now().toUtc(),
        result: result,
      );
    } catch (_) {
      return null;
    }
  }
}
