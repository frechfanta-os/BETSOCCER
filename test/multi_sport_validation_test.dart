import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:betsoccer/core/database/app_database.dart';
import 'package:betsoccer/core/database/daos/sports_dao.dart';
import 'package:betsoccer/features/sports/domain/entities/sport.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';
import 'package:betsoccer/features/sports/domain/repositories/sports_repository.dart';
import 'package:betsoccer/features/sports/presentation/controllers/sports_controller.dart';
import 'package:betsoccer/core/services/firebase_service.dart';
import 'package:betsoccer/core/services/firebase_sync_adapter.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Multi-Sport & Today Matches Realism Tests', () {
    late AppDatabase db;
    late SportsDao dao;
    late SportsRepository repository;
    late SportsController controller;

    setUp(() async {
      db = AppDatabase(databaseFactory: databaseFactoryFfi);
      await db.initInMemory();
      dao = SportsDao(db);

      repository = SportsRepository(sportsDao: dao, dataSources: []);
      controller = SportsController(
        repository: repository,
        syncAdapter: FirebaseSyncAdapter(service: FirebaseService.instance),
      );

      // Seed multi-sport database with 2026 matches
      final nowUtc = DateTime.utc(2026, 10, 14, 20, 0, 0);

      // 5 Sports
      await dao.upsertSports(const [
        SportEntity(
          id: 'sport_football',
          name: 'Football',
          code: 'SOCCER',
          sourceProvider: 'system',
        ),
        SportEntity(
          id: 'sport_basketball',
          name: 'Basketball',
          code: 'BASKETBALL',
          sourceProvider: 'thesportsdb',
        ),
        SportEntity(
          id: 'sport_tennis',
          name: 'Tennis',
          code: 'TENNIS',
          sourceProvider: 'thesportsdb',
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
      ]);

      // Ancient match from August 2023
      await dao.upsertMatch(
        MatchEntity(
          id: 'old_match_2023',
          sportId: 'sport_football',
          competitionId: 'comp_pl',
          homeTeamId: 'team_burnley',
          awayTeamId: 'team_mancity',
          homeTeamName: 'Burnley FC',
          awayTeamName: 'Manchester City FC',
          utcKickoff: DateTime.utc(2023, 8, 11, 20, 0, 0),
          status: MatchStatus.finished,
          sourceProvider: 'openfootball',
          lastSyncedAt: nowUtc,
        ),
      );

      // Current 2026 Football match
      await dao.upsertMatch(
        MatchEntity(
          id: 'football_2026',
          sportId: 'sport_football',
          competitionId: 'comp_pl',
          homeTeamId: 'team_arsenal',
          awayTeamId: 'team_chelsea',
          homeTeamName: 'Arsenal',
          awayTeamName: 'Chelsea',
          utcKickoff: nowUtc.add(const Duration(hours: 2)),
          status: MatchStatus.upcoming,
          sourceProvider: 'thesportsdb',
          lastSyncedAt: nowUtc,
        ),
      );

      // Current 2026 Basketball match
      await dao.upsertMatch(
        MatchEntity(
          id: 'bball_2026',
          sportId: 'sport_basketball',
          competitionId: 'comp_nba',
          homeTeamId: 'team_celtics',
          awayTeamId: 'team_hornets',
          homeTeamName: 'Boston Celtics',
          awayTeamName: 'Charlotte Hornets',
          utcKickoff: nowUtc.add(const Duration(hours: 3)),
          status: MatchStatus.upcoming,
          sourceProvider: 'thesportsdb',
          lastSyncedAt: nowUtc,
        ),
      );

      // Current 2026 Tennis match
      await dao.upsertMatch(
        MatchEntity(
          id: 'tennis_2026',
          sportId: 'sport_tennis',
          competitionId: 'comp_atp',
          homeTeamId: 'player_alcaraz',
          awayTeamId: 'player_medvedev',
          homeTeamName: 'Carlos Alcaraz',
          awayTeamName: 'Daniil Medvedev',
          utcKickoff: nowUtc.add(const Duration(hours: 1)),
          status: MatchStatus.upcoming,
          sourceProvider: 'thesportsdb',
          lastSyncedAt: nowUtc,
        ),
      );

      // Current 2026 Handball match
      await dao.upsertMatch(
        MatchEntity(
          id: 'handball_2026',
          sportId: 'sport_handball',
          competitionId: 'comp_hbl',
          homeTeamId: 'team_kiel',
          awayTeamId: 'team_magdeburg',
          homeTeamName: 'THW Kiel',
          awayTeamName: 'SC Magdeburg',
          utcKickoff: nowUtc.add(const Duration(hours: 4)),
          status: MatchStatus.upcoming,
          sourceProvider: 'openligadb',
          lastSyncedAt: nowUtc,
        ),
      );

      // Current 2026 Volleyball match
      await dao.upsertMatch(
        MatchEntity(
          id: 'volleyball_2026',
          sportId: 'sport_volleyball',
          competitionId: 'comp_vbl',
          homeTeamId: 'team_stuttgart',
          awayTeamId: 'team_schwerin',
          homeTeamName: 'MTV Stuttgart',
          awayTeamName: 'SSC Schwerin',
          utcKickoff: nowUtc.add(const Duration(hours: 5)),
          status: MatchStatus.upcoming,
          sourceProvider: 'openligadb',
          lastSyncedAt: nowUtc,
        ),
      );

      await controller.loadInitialData();
    });

    tearDown(() async {
      await db.close();
    });

    test('todayMatches prioritizes upcoming 2026 matches and never shows ancient 2023 matches when upcoming exist', () {
      final today = controller.todayMatches;
      expect(today, isNotEmpty);
      expect(today.any((m) => m.id == 'old_match_2023'), isFalse);
      expect(today.first.utcKickoff.year, equals(2026));
    });

    test(
      'featuredMatch selects the upcoming 2026 match, not the 2023 match',
      () {
        final featured = controller.featuredMatch;
        expect(featured, isNotNull);
        expect(featured!.id, isNot(equals('old_match_2023')));
        expect(featured.utcKickoff.year, equals(2026));
      },
    );

    test('each of the 5 sports returns non-empty matches when filtered', () {
      final sports = [
        'Football',
        'Basketball',
        'Tennis',
        'Handball',
        'Volleyball',
      ];

      for (final sport in sports) {
        controller.setSportFilter(sport);
        final matches = controller.todayMatches;
        expect(
          matches,
          isNotEmpty,
          reason: 'Sport $sport should not be empty!',
        );
        expect(
          matches.first.sportId.toLowerCase(),
          contains(sport.toLowerCase()),
          reason: 'Expected sport ID to contain $sport',
        );
      }
    });
  });
}
