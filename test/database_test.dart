import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:betsoccer/core/database/app_database.dart';
import 'package:betsoccer/core/database/daos/sports_dao.dart';
import 'package:betsoccer/features/sports/domain/entities/sport.dart';
import 'package:betsoccer/features/sports/domain/entities/competition.dart';
import 'package:betsoccer/features/sports/domain/entities/season.dart';
import 'package:betsoccer/features/sports/domain/entities/team.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';
import 'package:betsoccer/features/sports/domain/entities/match_result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SQLite Database & Schema V1 Tests', () {
    late AppDatabase appDatabase;
    late SportsDao dao;

    setUp(() async {
      appDatabase = AppDatabase(databaseFactory: databaseFactoryFfi);
      await appDatabase.initInMemory();
      dao = SportsDao(appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
    });

    test('initializes all 10 relational tables in SQLite', () async {
      final db = appDatabase.db;
      final tablesQuery = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tablesQuery
          .map((row) => row['name'] as String)
          .toSet();

      expect(
        tableNames,
        containsAll([
          'sports',
          'competitions',
          'seasons',
          'teams',
          'players',
          'matches',
          'results',
          'match_statistics',
          'data_sources',
          'sync_state',
        ]),
      );
    });

    test('verifies PRAGMA foreign_keys is enabled', () async {
      final res = await appDatabase.db.rawQuery('PRAGMA foreign_keys;');
      expect(res.first.values.first, equals(1));
    });

    test('CRUD for Sports and Competitions', () async {
      const sport = SportEntity(
        id: 'sport_football',
        name: 'Football',
        code: 'SOCCER',
        iconRef: 'sports_soccer',
        sourceProvider: 'openfootball',
      );
      await dao.upsertSport(sport);

      final sports = await dao.getAllSports();
      expect(sports.length, equals(1));
      expect(sports.first.id, equals('sport_football'));
      expect(sports.first.name, equals('Football'));

      const comp = CompetitionEntity(
        id: 'comp_premier_league',
        sportId: 'sport_football',
        name: 'Premier League',
        code: 'EPL',
        country: 'Angleterre',
        countryCode: 'GB',
        tier: 1,
        sourceProvider: 'openfootball',
      );
      await dao.upsertCompetition(comp);

      final comps = await dao.getCompetitionsBySport('sport_football');
      expect(comps.length, equals(1));
      expect(comps.first.name, equals('Premier League'));
    });

    test('upsert matches and verify deduplication constraint', () async {
      // 1. Préparation entités parentes
      await dao.upsertSport(
        const SportEntity(
          id: 'sport_football',
          name: 'Football',
          code: 'SOCCER',
          sourceProvider: 'openfootball',
        ),
      );
      await dao.upsertCompetition(
        const CompetitionEntity(
          id: 'comp_epl',
          sportId: 'sport_football',
          name: 'Premier League',
          sourceProvider: 'openfootball',
        ),
      );
      await dao.upsertSeason(
        const SeasonEntity(
          id: 'season_2023_24',
          competitionId: 'comp_epl',
          yearLabel: '2023/24',
          isCurrent: true,
        ),
      );
      await dao.upsertTeams([
        const TeamEntity(
          id: 'team_arsenal',
          sportId: 'sport_football',
          name: 'Arsenal',
          sourceProvider: 'openfootball',
        ),
        const TeamEntity(
          id: 'team_chelsea',
          sportId: 'sport_football',
          name: 'Chelsea',
          sourceProvider: 'openfootball',
        ),
      ]);

      final kickoff = DateTime.utc(2023, 10, 21, 16, 30);
      final match1 = MatchEntity(
        id: 'm_ars_che_01',
        sportId: 'sport_football',
        competitionId: 'comp_epl',
        seasonId: 'season_2023_24',
        homeTeamId: 'team_arsenal',
        homeTeamName: 'Arsenal',
        awayTeamId: 'team_chelsea',
        awayTeamName: 'Chelsea',
        utcKickoff: kickoff,
        status: MatchStatus.upcoming,
        matchday: 9,
        sourceProvider: 'openfootball',
        lastSyncedAt: kickoff,
      );

      await dao.upsertMatch(match1);

      var retrieved = await dao.getMatchById('m_ars_che_01');
      expect(retrieved, isNotNull);
      expect(retrieved!.status, equals(MatchStatus.upcoming));

      // 2. Mise à jour du même match avec score (idempotent / mise à jour sans doublon)
      final updatedMatch = MatchEntity(
        id: 'm_ars_che_01',
        sportId: 'sport_football',
        competitionId: 'comp_epl',
        seasonId: 'season_2023_24',
        homeTeamId: 'team_arsenal',
        homeTeamName: 'Arsenal',
        awayTeamId: 'team_chelsea',
        awayTeamName: 'Chelsea',
        utcKickoff: kickoff,
        status: MatchStatus.finished,
        matchday: 9,
        sourceProvider: 'openfootball',
        lastSyncedAt: kickoff,
        result: const MatchResultEntity(
          id: 'res_m_ars_che_01',
          matchId: 'm_ars_che_01',
          homeScore: 2,
          awayScore: 2,
        ),
      );

      await dao.upsertMatch(updatedMatch);

      final allMatches = await dao.getMatches(competitionId: 'comp_epl');
      expect(
        allMatches.length,
        equals(1),
        reason: 'L\'unicité doit empêcher la création de doublons',
      );
      expect(allMatches.first.status, equals(MatchStatus.finished));
      expect(allMatches.first.result?.homeScore, equals(2));
      expect(allMatches.first.result?.awayScore, equals(2));
    });

    test('Sync state update and tracking', () async {
      await dao.updateSyncState(
        key: 'sync_test_key',
        providerId: 'openfootball',
        recordsSynced: 42,
        status: 'SUCCESS',
      );

      final state = await dao.getSyncState('sync_test_key');
      expect(state, isNotNull);
      expect(state!['provider_id'], equals('openfootball'));
      expect(state['records_synced'], equals(42));
      expect(state['status'], equals('SUCCESS'));
    });
  });
}
