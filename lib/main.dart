import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/database/app_database.dart';
import 'core/database/daos/sports_dao.dart';
import 'core/services/firebase_service.dart';
import 'core/services/firebase_sync_adapter.dart';
import 'core/theme/app_theme.dart';
import 'features/sports/data/sources/openfootball_data_source.dart';
import 'features/sports/data/sources/openligadb_data_source.dart';
import 'features/sports/data/sources/thesportsdb_data_source.dart';
import 'features/sports/data/sources/football_data_org_data_source.dart';
import 'features/sports/data/sources/melbet_data_source.dart';
import 'features/sports/domain/entities/sport.dart';
import 'features/sports/domain/repositories/sports_repository.dart';
import 'features/sports/presentation/controllers/sports_controller.dart';
import 'features/sports/presentation/widgets/app_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de la base de données locale SQLite (priorité absolue)
  final appDatabase = AppDatabase();
  await appDatabase.init();
  final sportsDao = SportsDao(appDatabase);

  // 2. Initialisation non-bloquante de Firebase (tolérance totale aux pannes hors-ligne)
  final fbService = FirebaseService.instance;
  try {
    await fbService.initialize();
  } catch (_) {
    // Mode hors-ligne automatique si Firebase ou le réseau est indisponible
  }
  final syncAdapter = FirebaseSyncAdapter(service: fbService);

  // 3. Configuration des connecteurs de données sportives
  final openFootballSource = OpenFootballDataSource();
  final openLigaDbSource = OpenLigaDbDataSource();
  final theSportsDbSource = TheSportsDbDataSource();
  final footballDataOrgSource = FootballDataOrgDataSource();
  final melbetSource = MelbetDataSource(); // Strictement DISABLED_BY_POLICY

  final repository = SportsRepository(
    sportsDao: sportsDao,
    dataSources: [
      openFootballSource,
      openLigaDbSource,
      theSportsDbSource,
      footballDataOrgSource,
      melbetSource,
    ],
  );

  // 4. Préchargement de l'archive historique OpenFootball (CC0) si la base est vide
  final existingSports = await sportsDao.getAllSports();
  if (existingSports.isEmpty) {
    try {
      final sampleRaw = await rootBundle.loadString(
        'assets/data/historical/premier_league_2023_24.txt',
      );
      await repository.importOpenFootballDataset(sampleRaw);
    } catch (_) {
      // Ignorer si l'asset n'est pas encore accessible au premier build
    }
  }

  // Assurer la présence des 5 sports officiels (Football, Basketball, Tennis, Handball, Volleyball)
  final sportsList = await sportsDao.getAllSports();
  final sportIds = sportsList.map((s) => s.id).toSet();
  final missingSports = [
    if (!sportIds.contains('sport_football'))
      const SportEntity(
        id: 'sport_football',
        name: 'Football',
        code: 'SOCCER',
        iconRef: 'sports_soccer',
        sourceProvider: 'system',
      ),
    if (!sportIds.contains('sport_basketball'))
      const SportEntity(
        id: 'sport_basketball',
        name: 'Basketball',
        code: 'BASKETBALL',
        iconRef: 'sports_basketball',
        sourceProvider: 'thesportsdb',
      ),
    if (!sportIds.contains('sport_tennis'))
      const SportEntity(
        id: 'sport_tennis',
        name: 'Tennis',
        code: 'TENNIS',
        iconRef: 'sports_tennis',
        sourceProvider: 'thesportsdb',
      ),
    if (!sportIds.contains('sport_handball'))
      const SportEntity(
        id: 'sport_handball',
        name: 'Handball',
        code: 'HANDBALL',
        iconRef: 'sports_handball',
        sourceProvider: 'openligadb',
      ),
    if (!sportIds.contains('sport_volleyball'))
      const SportEntity(
        id: 'sport_volleyball',
        name: 'Volleyball',
        code: 'VOLLEYBALL',
        iconRef: 'sports_volleyball',
        sourceProvider: 'openligadb',
      ),
  ];
  if (missingSports.isNotEmpty) {
    await sportsDao.upsertSports(missingSports);
  }

  // 5. Contrôleur d'état principal
  final controller = SportsController(
    repository: repository,
    syncAdapter: syncAdapter,
  );
  await controller.loadInitialData();

  runApp(BetSoccerApp(controller: controller));
}

class BetSoccerApp extends StatelessWidget {
  final SportsController controller;

  const BetSoccerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'BETSOCCER',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AppScaffold(controller: controller),
        );
      },
    );
  }
}
