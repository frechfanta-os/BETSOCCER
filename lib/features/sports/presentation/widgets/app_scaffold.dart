import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../screens/home_screen.dart';
import '../screens/live_matches_screen.dart';
import '../screens/upcoming_matches_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sports_screen.dart';
import '../screens/competitions_screen.dart';
import '../../../../core/theme/app_colors.dart';

class AppScaffold extends StatefulWidget {
  final SportsController controller;

  const AppScaffold({super.key, required this.controller});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final titles = [
      'BETSOCCER',
      'Matchs en Direct',
      'Matchs à Venir',
      'Historique Sportif',
      'Paramètres & Sources',
    ];

    final screens = [
      HomeScreen(controller: controller, onNavigateTab: _onNavigateTab),
      LiveMatchesScreen(controller: controller),
      UpcomingMatchesScreen(controller: controller),
      HistoryScreen(controller: controller),
      SettingsScreen(controller: controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(
              controller.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Changer de thème',
            onPressed: () => controller.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => controller.loadInitialData(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'BETSOCCER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Multisport Analytics AI',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sport actif: ${controller.selectedSport?.name ?? "Football"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.sports_soccer_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Sélectionner un Sport'),
              subtitle: Text(
                controller.selectedSport?.name ?? 'Non sélectionné',
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SizedBox(
                    height: 400,
                    child: SportsScreen(
                      controller: controller,
                      onSelectDone: () => Navigator.pop(ctx),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.secondary,
              ),
              title: const Text('Sélectionner une Compétition'),
              subtitle: Text(
                controller.selectedCompetition?.name ?? 'Non sélectionné',
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SizedBox(
                    height: 400,
                    child: CompetitionsScreen(
                      controller: controller,
                      onSelectDone: () => Navigator.pop(ctx),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Paramètres & Gouvernance'),
              onTap: () {
                Navigator.pop(context);
                _onNavigateTab(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('À Propos & Conformité'),
              subtitle: const Text('com.ghdinteractivestudio.betsoccer'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'BETSOCCER',
                  applicationVersion: '1.0.0+1',
                  applicationLegalese: '© 2026 GHD Interactive Studio. Licence CC0 pour OpenFootball.',
                );
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigateTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors_rounded),
            label: 'Direct',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'À venir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
