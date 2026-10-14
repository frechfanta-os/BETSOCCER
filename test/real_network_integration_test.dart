import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:betsoccer/core/database/app_database.dart';
import 'package:betsoccer/core/database/daos/sports_dao.dart';
import 'package:betsoccer/features/sports/data/sources/openligadb_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/thesportsdb_data_source.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';
import 'package:betsoccer/features/sports/domain/repositories/sports_repository.dart';
import 'package:betsoccer/features/sports/presentation/controllers/sports_controller.dart';
import 'package:betsoccer/core/services/firebase_service.dart';
import 'package:betsoccer/core/services/firebase_sync_adapter.dart';

void main() {
  // Allow real HTTP requests in flutter test environment
  HttpOverrides.global = null;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 4.2 — Real-World Live & Fixtures Network Integration Tests', () {
    test('OpenLigaDB live public API returns real upcoming fixtures', () async {
      final source = OpenLigaDbDataSource();
      List<MatchEntity> matches;
      try {
        matches = await source.fetchUpcomingMatches(
          competitionId: 'comp_old_bl1',
        );
      } catch (e) {
        // If network is completely unreachable in a sandboxed CI, skip
        markTestSkipped('Network call failed: $e');
        return;
      }

      expect(matches, isNotEmpty);
      expect(matches.length, greaterThanOrEqualTo(1));

      for (final m in matches) {
        expect(m.homeTeamName, isNotEmpty);
        expect(m.awayTeamName, isNotEmpty);
        expect(m.status, equals(MatchStatus.upcoming));
        expect(m.utcKickoff.isUtc, isTrue);
        expect(m.sourceProvider, equals('openligadb'));
      }
    });

    test('OpenLigaDB live matches returns empty list cleanly when no match is active', () async {
      final source = OpenLigaDbDataSource();
      List<MatchEntity> liveMatches;
      try {
        liveMatches = await source.fetchLiveMatches(sportId: 'sport_football');
      } catch (e) {
        markTestSkipped('Network call failed: $e');
        return;
      }

      // No match should be falsely invented or converted from finished
      for (final m in liveMatches) {
        expect(m.status, equals(MatchStatus.live));
      }
    });

    test(
      'TheSportsDB public API returns real upcoming events for Premier League',
      () async {
        final source = TheSportsDbDataSource();
        List<MatchEntity> matches;
        try {
          matches = await source.fetchUpcomingMatches(
            competitionId: 'comp_fduk_e0',
          );
        } catch (e) {
          markTestSkipped('Network call failed: $e');
          return;
        }

        expect(matches, isNotEmpty);
        final first = matches.first;
        expect(first.homeTeamName, isNotEmpty);
        expect(first.awayTeamName, isNotEmpty);
        expect(first.status, equals(MatchStatus.upcoming));
        expect(first.sourceProvider, equals('thesportsdb'));
      },
    );

    test('End-to-End: Real API -> SportsRepository -> SQLite Persistence -> SportsController', () async {
      final db = AppDatabase();
      await db.init(customPath: inMemoryDatabasePath);
      final dao = SportsDao(db);

      final openLigaSource = OpenLigaDbDataSource();
      final theSportsDbSource = TheSportsDbDataSource();

      final repository = SportsRepository(
        sportsDao: dao,
        dataSources: [openLigaSource, theSportsDbSource],
      );

      final controller = SportsController(
        repository: repository,
        syncAdapter: FirebaseSyncAdapter(service: FirebaseService.instance),
      );

      // 1. Charger les données initiales
      await controller.loadInitialData();

      // 2. Vérifier que les matchs en direct ne contiennent AUCUN faux match historique
      expect(
        controller.filteredLiveMatches.every(
          (m) => m.status == MatchStatus.live,
        ),
        isTrue,
        reason: 'Live Center must never contain non-live matches!',
      );

      // 3. Forcer la synchronisation des rencontres à venir depuis OpenLigaDB vers SQLite
      final upcoming = await repository.getUpcomingMatches(
        competitionId: 'comp_old_bl1',
        forceRefresh: true,
      );

      if (upcoming.isNotEmpty) {
        // Confirmer la persistance en base SQLite
        final stored = await dao.getMatches(status: MatchStatus.upcoming.name);
        expect(stored, isNotEmpty);
        expect(stored.first.status, equals(MatchStatus.upcoming));

        // Recharger le controller et vérifier l'affichage des Fixtures
        await controller.loadInitialData();
        expect(controller.filteredUpcomingMatches, isNotEmpty);
        expect(
          controller.filteredUpcomingMatches.every(
            (m) => m.status == MatchStatus.upcoming,
          ),
          isTrue,
        );
      }

      await db.close();
    });
  });
}
