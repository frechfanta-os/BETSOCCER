import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/main.dart';
import 'package:betsoccer/core/database/daos/sports_dao.dart';
import 'package:betsoccer/core/services/firebase_sync_adapter.dart';
import 'package:betsoccer/features/sports/domain/entities/sport.dart';
import 'package:betsoccer/features/sports/domain/entities/competition.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';
import 'package:betsoccer/features/sports/domain/interfaces/sports_data_source.dart';
import 'package:betsoccer/features/sports/domain/repositories/sports_repository.dart';
import 'package:betsoccer/features/sports/presentation/controllers/sports_controller.dart';

class FakeSportsRepository implements SportsRepository {
  @override
  SportsDao get sportsDao => throw UnimplementedError();

  @override
  List<SportsDataSource> get dataSources => const [];

  @override
  Future<List<SportEntity>> getSports({bool forceRefresh = false}) async {
    return const [
      SportEntity(
        id: 'sport_football',
        name: 'Football',
        code: 'SOCCER',
        sourceProvider: 'fake',
      ),
    ];
  }

  @override
  Future<List<CompetitionEntity>> getCompetitions(
    String sportId, {
    bool forceRefresh = false,
  }) async {
    return const [
      CompetitionEntity(
        id: 'comp_epl',
        sportId: 'sport_football',
        name: 'Premier League',
        sourceProvider: 'fake',
      ),
    ];
  }

  @override
  Future<List<MatchEntity>> getUpcomingMatches({
    String? competitionId,
    bool forceRefresh = false,
  }) async => [];

  @override
  Future<List<MatchEntity>> getLiveMatches({
    String? sportId,
    bool forceRefresh = false,
  }) async => [];

  @override
  Future<List<MatchEntity>> getHistoricalMatches({
    required String competitionId,
    required String season,
    bool forceRefresh = false,
  }) async => [];

  @override
  Future<MatchEntity?> getMatchDetails(String matchId) async => null;

  @override
  Future<int> importOpenFootballDataset(String rawContent) async => 0;
}

class FakeFirebaseSyncAdapter extends FirebaseSyncAdapter {
  @override
  Future<bool> syncUserPreferences({
    required List<String> favoriteSports,
    required List<String> favoriteCompetitions,
    required bool isDarkMode,
    required DateTime lastLocalSync,
  }) async => true;

  @override
  Future<Map<String, dynamic>?> fetchCloudPreferences() async => null;
}

void main() {
  testWidgets(
    'BetSoccerApp renders scaffold, displays tabs, and toggles theme',
    (WidgetTester tester) async {
      final fakeRepo = FakeSportsRepository();
      final fakeSync = FakeFirebaseSyncAdapter();

      final controller = SportsController(
        repository: fakeRepo,
        syncAdapter: fakeSync,
      );
      await controller.loadInitialData();

      await tester.pumpWidget(BetSoccerApp(controller: controller));
      await tester.pump();

      // 1. En-tête et navigation principale
      expect(find.text('BETSOCCER'), findsNWidgets(2));
      final bottomNav = find.byType(BottomNavigationBar);
      expect(
        find.descendant(of: bottomNav, matching: find.text('Accueil')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNav, matching: find.text('Direct')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNav, matching: find.text('À venir')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNav, matching: find.text('Historique')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNav, matching: find.text('Paramètres')),
        findsOneWidget,
      );

      // 2. Navigation vers l'onglet Direct
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Direct')),
      );
      await tester.pump();
      expect(find.text('Matchs en Direct'), findsOneWidget);

      // 3. Navigation vers l'onglet À venir
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('À venir')),
      );
      await tester.pump();
      expect(find.text('Matchs à Venir'), findsOneWidget);

      // 4. Navigation vers l'onglet Historique
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Historique')),
      );
      await tester.pump();
      expect(find.text('Historique Sportif'), findsOneWidget);

      // 5. Navigation vers l'onglet Paramètres
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Paramètres')),
      );
      await tester.pump();
      expect(find.text('Paramètres & Sources'), findsOneWidget);

      // 6. Test du basculement du mode sombre / clair
      expect(controller.isDarkMode, isTrue);
      final themeToggle = find.byTooltip('Changer de thème');
      expect(themeToggle, findsOneWidget);
      await tester.tap(themeToggle);
      await tester.pump();
      expect(controller.isDarkMode, isFalse);
    },
  );
}
