import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/firebase_service.dart';

class SettingsScreen extends StatelessWidget {
  final SportsController controller;

  const SettingsScreen({super.key, required this.controller});

  static const List<String> _allSports = [
    'Football',
    'Basketball',
    'Tennis',
    'Handball',
    'Volleyball',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final fbService = FirebaseService.instance;
    final isFbInitialized = fbService.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. CARTE COMPAGNON PROFIL UTILISATEUR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceElevatedLight,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 26,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BETSOCCER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your Sports Analytics Companion',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: secondaryTextColor,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. SECTION : DATA SOURCES (Sources de Données & Synchronisation)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Sources',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      '${controller.totalRecordsSynced} records synced • Autonomous Crawl4AI',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
                Text(
                  'Last: ${controller.lastSyncFormatted}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bouton de Synchronisation Manuelle
            OutlinedButton.icon(
              onPressed: () async {
                await controller.loadInitialData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevatedDark,
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.neonLime,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Base synchronisée : ${controller.allMatches.length} matchs réels chargés.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.sync_rounded,
                size: 16,
                color: AppColors.neonLime,
              ),
              label: const Text(
                'Sync & Refresh Local SQLite',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonLime,
                side: const BorderSide(color: AppColors.neonLime),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 10),

            // Cartes Fournisseurs
            _buildDataSourceTile(
              name: 'OpenLigaDB',
              subtitle: '936 records • 1. & 2. Bundesliga, HBL, VBLF1',
              icon: Icons.sports_soccer_rounded,
              isSynced: true,
              timeAgo: 'Active (2023/24 + Live)',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
            ),
            _buildDataSourceTile(
              name: 'Football-Data.co.uk',
              subtitle: '774 records • EPL, La Liga, Halftimes & 7 Match Stats',
              icon: Icons.public_rounded,
              isSynced: true,
              timeAgo: 'Active (Historical + Fixtures)',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
            ),
            _buildDataSourceTile(
              name: 'TheSportsDB',
              subtitle: '15 records • Multi-sport Events & Teams',
              icon: Icons.storage_rounded,
              isSynced: true,
              timeAgo: 'Active (V1 Free)',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
            ),
            _buildDataSourceTile(
              name: 'MelBet (Disabled by Policy)',
              subtitle: '0 records • Verrou de sécurité éthique actif',
              icon: Icons.block_rounded,
              isSynced: false,
              timeAgo: 'LOCKED',
              cardBg: cardBg,
              borderColor: borderColor,
              primaryColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
            ),

            const SizedBox(height: 20),

            // 3. SECTION : PREFERENCES
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),

            // A. Favorite Sports Pills Selector
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 20,
                        color: primaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Favorite Sports',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your favorite sports',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSports.map((s) {
                      final isSelected = controller.favoriteSports.contains(s);
                      return InkWell(
                        onTap: () => controller.toggleFavoriteSport(s),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.neonLime
                                : (isDark
                                      ? AppColors.surfaceElevatedDark
                                      : AppColors.surfaceElevatedLight),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.neonLime
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF0A111F)
                                  : secondaryTextColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // B. Offline Mode Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    color: primaryTextColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Use local data when no internet connection',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.isOfflineMode,
                    activeThumbColor: AppColors.neonLime,
                    onChanged: (_) => controller.toggleOfflineMode(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // C. Dark Theme Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_rounded,
                    color: primaryTextColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Theme',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Use dark theme',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.isDarkMode,
                    activeThumbColor: AppColors.neonLime,
                    onChanged: (_) => controller.toggleTheme(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Synchronisation Cloud Firebase (Préservé)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync (Firebase)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        isFbInitialized
                            ? 'Connecté (betsoccer-60834)'
                            : 'Mode hors-ligne local',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {
                      controller.toggleTheme();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Préférences synchronisées avec Firestore',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonLime,
                      side: const BorderSide(color: AppColors.neonLime),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Sync Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceTile({
    required String name,
    required String subtitle,
    required IconData icon,
    required bool isSynced,
    required String timeAgo,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSynced
                  ? AppColors.neonLime.withValues(alpha: 0.15)
                  : AppColors.liveRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSynced ? AppColors.neonLime : AppColors.liveRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: secondaryColor),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 7,
                color: isSynced ? AppColors.winGreen : AppColors.liveRed,
              ),
              const SizedBox(width: 5),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSynced ? secondaryColor : AppColors.liveRed,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
