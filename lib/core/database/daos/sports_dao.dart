import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../../../features/sports/domain/entities/sport.dart';
import '../../../features/sports/domain/entities/competition.dart';
import '../../../features/sports/domain/entities/season.dart';
import '../../../features/sports/domain/entities/team.dart';
import '../../../features/sports/domain/entities/match.dart';
import '../../../features/sports/domain/entities/match_result.dart';
import '../../../features/sports/domain/entities/match_statistic.dart';

/// DAO pour les entités sportives, rencontres et synchronisation
class SportsDao {
  final AppDatabase appDatabase;

  SportsDao(this.appDatabase);

  Database get _db => appDatabase.db;

  // --- SPORTS ---

  Future<void> upsertSport(SportEntity sport) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert('sports', {
      ...sport.toMap(),
      'created_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertSports(List<SportEntity> sports) async {
    final batch = _db.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    for (final sport in sports) {
      batch.insert('sports', {
        ...sport.toMap(),
        'created_at': nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<SportEntity>> getAllSports() async {
    final rows = await _db.query('sports', orderBy: 'name ASC');
    return rows.map(SportEntity.fromMap).toList();
  }

  Future<SportEntity?> getSportById(String id) async {
    final rows = await _db.query(
      'sports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SportEntity.fromMap(rows.first);
  }

  // --- COMPETITIONS ---

  Future<void> upsertCompetition(CompetitionEntity comp) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert('competitions', {
      ...comp.toMap(),
      'created_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertCompetitions(List<CompetitionEntity> comps) async {
    final batch = _db.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    for (final comp in comps) {
      batch.insert('competitions', {
        ...comp.toMap(),
        'created_at': nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CompetitionEntity>> getCompetitionsBySport(String sportId) async {
    final rows = await _db.query(
      'competitions',
      where: 'sport_id = ?',
      whereArgs: [sportId],
      orderBy: 'name ASC',
    );
    return rows.map(CompetitionEntity.fromMap).toList();
  }

  Future<CompetitionEntity?> getCompetitionById(String id) async {
    final rows = await _db.query(
      'competitions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CompetitionEntity.fromMap(rows.first);
  }

  // --- SEASONS ---

  Future<void> upsertSeason(SeasonEntity season) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert('seasons', {
      ...season.toMap(),
      'created_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SeasonEntity>> getSeasonsByCompetition(
    String competitionId,
  ) async {
    final rows = await _db.query(
      'seasons',
      where: 'competition_id = ?',
      whereArgs: [competitionId],
      orderBy: 'year_label DESC',
    );
    return rows.map(SeasonEntity.fromMap).toList();
  }

  // --- TEAMS ---

  Future<void> upsertTeam(TeamEntity team) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert('teams', {
      ...team.toMap(),
      'created_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertTeams(List<TeamEntity> teams) async {
    final batch = _db.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    for (final team in teams) {
      batch.insert('teams', {
        ...team.toMap(),
        'created_at': nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<TeamEntity?> getTeamByName(String sportId, String name) async {
    final rows = await _db.query(
      'teams',
      where: 'sport_id = ? AND name = ?',
      whereArgs: [sportId, name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TeamEntity.fromMap(rows.first);
  }

  Future<TeamEntity?> getTeamById(String id) async {
    final rows = await _db.query(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TeamEntity.fromMap(rows.first);
  }

  // --- MATCHES, RESULTS & STATS ---

  Future<void> upsertMatch(MatchEntity match) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.transaction((txn) async {
      await txn.insert('matches', {
        ...match.toMap(),
        'created_at': nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (match.result != null) {
        await txn.insert('results', {
          ...match.result!.toMap(),
          'created_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final stat in match.statistics) {
        await txn.insert('match_statistics', {
          ...stat.toMap(),
          'created_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertMatches(List<MatchEntity> matches) async {
    for (final match in matches) {
      await upsertMatch(match);
    }
  }

  Future<List<MatchEntity>> getMatches({
    String? sportId,
    String? competitionId,
    String? status,
    String? seasonId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (sportId != null) {
      whereClauses.add('m.sport_id = ?');
      whereArgs.add(sportId);
    }
    if (competitionId != null) {
      whereClauses.add('m.competition_id = ?');
      whereArgs.add(competitionId);
    }
    if (status != null) {
      whereClauses.add('m.status = ?');
      whereArgs.add(status);
    }
    if (seasonId != null) {
      whereClauses.add('m.season_id = ?');
      whereArgs.add(seasonId);
    }
    if (from != null) {
      whereClauses.add('m.utc_kickoff >= ?');
      whereArgs.add(from.toUtc().toIso8601String());
    }
    if (to != null) {
      whereClauses.add('m.utc_kickoff <= ?');
      whereArgs.add(to.toUtc().toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';
    final limitString = limit != null ? 'LIMIT $limit' : '';

    final query =
        '''
      SELECT 
        m.*,
        ht.name AS home_team_name,
        ht.badge_url AS home_team_badge,
        at.name AS away_team_name,
        at.badge_url AS away_team_badge,
        c.name AS competition_name,
        r.id AS result_id,
        r.home_score,
        r.away_score,
        r.home_halftime_score,
        r.away_halftime_score,
        r.winner_team_id
      FROM matches m
      LEFT JOIN teams ht ON m.home_team_id = ht.id
      LEFT JOIN teams at ON m.away_team_id = at.id
      LEFT JOIN competitions c ON m.competition_id = c.id
      LEFT JOIN results r ON m.id = r.match_id
      $whereString
      ORDER BY m.utc_kickoff ASC
      $limitString;
    ''';

    final rows = await _db.rawQuery(query, whereArgs);

    return rows.map((row) {
      MatchResultEntity? result;
      if (row['result_id'] != null) {
        result = MatchResultEntity(
          id: row['result_id'] as String,
          matchId: row['id'] as String,
          homeScore: row['home_score'] as int?,
          awayScore: row['away_score'] as int?,
          homeHalftimeScore: row['home_halftime_score'] as int?,
          awayHalftimeScore: row['away_halftime_score'] as int?,
          winnerTeamId: row['winner_team_id'] as String?,
        );
      }

      return MatchEntity.fromMap(
        row,
        homeTeamName: row['home_team_name'] as String?,
        awayTeamName: row['away_team_name'] as String?,
        compName: row['competition_name'] as String?,
        result: result,
      );
    }).toList();
  }

  Future<MatchEntity?> getMatchById(String matchId) async {
    final filtered = await _db.rawQuery(
      '''
      SELECT 
        m.*,
        ht.name AS home_team_name,
        ht.badge_url AS home_team_badge,
        at.name AS away_team_name,
        at.badge_url AS away_team_badge,
        c.name AS competition_name,
        r.id AS result_id,
        r.home_score,
        r.away_score,
        r.home_halftime_score,
        r.away_halftime_score,
        r.winner_team_id
      FROM matches m
      LEFT JOIN teams ht ON m.home_team_id = ht.id
      LEFT JOIN teams at ON m.away_team_id = at.id
      LEFT JOIN competitions c ON m.competition_id = c.id
      LEFT JOIN results r ON m.id = r.match_id
      WHERE m.id = ?
      LIMIT 1;
    ''',
      [matchId],
    );

    if (filtered.isEmpty) return null;
    final row = filtered.first;

    // Charger statistiques
    final statRows = await _db.query(
      'match_statistics',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
    final stats = statRows.map(MatchStatisticEntity.fromMap).toList();

    MatchResultEntity? result;
    if (row['result_id'] != null) {
      result = MatchResultEntity(
        id: row['result_id'] as String,
        matchId: row['id'] as String,
        homeScore: row['home_score'] as int?,
        awayScore: row['away_score'] as int?,
        homeHalftimeScore: row['home_halftime_score'] as int?,
        awayHalftimeScore: row['away_halftime_score'] as int?,
        winnerTeamId: row['winner_team_id'] as String?,
      );
    }

    return MatchEntity.fromMap(
      row,
      homeTeamName: row['home_team_name'] as String?,
      awayTeamName: row['away_team_name'] as String?,
      compName: row['competition_name'] as String?,
      result: result,
      stats: stats,
    );
  }

  // --- SOURCES & SYNC ---

  Future<List<Map<String, dynamic>>> getDataSources() async {
    return _db.query('data_sources');
  }

  Future<void> updateSyncState({
    required String key,
    required String providerId,
    required int recordsSynced,
    required String status,
    String? errorMessage,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert('sync_state', {
      'key': key,
      'provider_id': providerId,
      'last_synced_at': nowIso,
      'records_synced': recordsSynced,
      'status': status,
      'error_message': errorMessage,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getSyncState(String key) async {
    final rows = await _db.query(
      'sync_state',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllSyncStates() async {
    return _db.query('sync_state', orderBy: 'last_synced_at DESC');
  }

  Future<List<Map<String, dynamic>>> getSyncLogs({int limit = 20}) async {
    try {
      return await _db.query(
        'sync_logs',
        orderBy: 'started_at DESC',
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }
}
