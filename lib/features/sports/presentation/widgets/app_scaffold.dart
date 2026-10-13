import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../screens/home_screen.dart';
import '../screens/live_matches_screen.dart';
import '../screens/upcoming_matches_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(controller: controller, onNavigateTab: _onNavigateTab),
      LiveMatchesScreen(controller: controller),
      UpcomingMatchesScreen(controller: controller),
      HistoryScreen(controller: controller),
      SettingsScreen(controller: controller),
    ];

    final bottomNavBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderTopColor = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavBg,
          border: Border(top: BorderSide(color: borderTopColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavigateTab,
          backgroundColor: bottomNavBg,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: isDark
              ? AppColors.neonLime
              : const Color(0xFF0A111F),
          unselectedItemColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors_rounded),
              label: 'Live',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Fixtures',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
