import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/sports_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/firebase_service.dart';

class SettingsScreen extends StatelessWidget {
  final SportsController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fbService = FirebaseService.instance;
    final isFbInitialized = fbService.isInitialized;
    final fbUserId = fbService.currentUserId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. SECTION : SOURCES DE DONNÉES & GOUVERNANCE
        _buildSectionHeader('Sources de Données Sportives'),
        _buildSourceTile(
          name: 'OpenFootball',
          description: 'Archives historiques & backtesting',
          statusLabel: 'ACTIF (CC0)',
          statusColor: AppColors.primary,
          icon: Icons.folder_zip_rounded,
        ),
        _buildSourceTile(
          name: 'TheSportsDB',
          description: 'Métadonnées multi-sports (Clé test V1)',
          statusLabel: 'ACTIF (V1)',
          statusColor: AppColors.secondary,
          icon: Icons.public_rounded,
        ),
        _buildSourceTile(
          name: 'Football-Data.org',
          description: 'Calendriers et 12 ligues majeures',
          statusLabel: 'ACTIF (Gratuit)',
          statusColor: AppColors.upcomingBlue,
          icon: Icons.sports_soccer_rounded,
        ),
        _buildSourceTile(
          name: 'MelBet',
          description: 'Scraping et flux internes non autorisés',
          statusLabel: 'DISABLED_BY_POLICY',
          statusColor: AppColors.liveRed,
          icon: Icons.block_rounded,
        ),
        const SizedBox(height: 20),

        // 2. SECTION : SYNCHRONISATION FIREBASE CLOUD
        _buildSectionHeader('Synchronisation Cloud Firebase'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Projet Firebase :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'betsoccer-60834',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isFbInitialized
                            ? AppColors.primary
                            : AppColors.sampleAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statut Cloud :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isFbInitialized
                                    ? AppColors.primary
                                    : AppColors.sampleAmber)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isFbInitialized ? 'CONNECTÉ' : 'MODE HORS-LIGNE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isFbInitialized
                              ? AppColors.primary
                              : AppColors.sampleAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                if (fbUserId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'UID: ${fbUserId.substring(0, 12)}...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Note : Cloud Firestore synchronise uniquement les préférences utilisateur. La base sportive reste 100% locale dans SQLite.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (!isFbInitialized) {
                      await fbService.initialize();
                    }
                    if (fbService.currentUser == null) {
                      await fbService.signInAnonymously();
                    }
                    controller.toggleTheme(); // déclenche sync
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Préférences utilisateur synchronisées avec Firebase',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text('Synchroniser les préférences'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 3. SECTION : APPARENCE & THÈME
        _buildSectionHeader('Apparence & Interface'),
        Card(
          child: SwitchListTile(
            title: const Text('Mode Sombre (Dark Mode)'),
            subtitle: const Text(
              'Palette contrastée adaptée à la lecture de statistiques',
            ),
            value: controller.isDarkMode,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => controller.toggleTheme(),
          ),
        ),
        const SizedBox(height: 20),

        // 4. SECTION : BASE DE DONNÉES LOCALE
        _buildSectionHeader('Stockage Local SQLite'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Fichier SQLite'),
                subtitle: const Text(
                  'betsoccer.db (Version 1, 10 tables actives)',
                ),
                trailing: const Icon(
                  Icons.storage_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final raw = await rootBundle.loadString(
                          'assets/data/historical/premier_league_2023_24.txt',
                        );
                        final count = await controller.importOpenFootball(raw);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$count matchs importés depuis Premier League 2023/24 (CC0)',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text(
                      'Recharger l\'échantillon Premier League (CC0)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required String name,
    required String description,
    required String statusLabel,
    required Color statusColor,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          foregroundColor: statusColor,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
