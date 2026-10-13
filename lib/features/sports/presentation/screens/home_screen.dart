import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/match_card.dart';
import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final SportsController controller;
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final liveCount = controller.liveMatches.length;
    final upcomingCount = controller.upcomingMatches.length;
    final historyCount = controller.historicalMatches.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière de bienvenue
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'BETSOCCER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Plateforme d\'analyse statistique multisport déterministe (Loi de Poisson, Dixon-Coles, Elo). Données certifiées sans hallucination.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPill('Offline-First', AppColors.primary),
                      _buildPill('SQLite Local', AppColors.secondary),
                      _buildPill('CC0 OpenFootball', AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Métriques rapides
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'En Direct',
                    value: '$liveCount',
                    icon: Icons.sensors_rounded,
                    color: AppColors.liveRed,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'À Venir',
                    value: '$upcomingCount',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.upcomingBlue,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Historique',
                    value: '$historyCount',
                    icon: Icons.history_rounded,
                    color: AppColors.finishedGrey,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section : Matchs en direct (si disponibles)
          if (controller.liveMatches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: AppColors.liveRed,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Rencontres en Direct',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(1),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
            ...controller.liveMatches.take(3).map((m) => MatchCard(match: m)),
            const SizedBox(height: 16),
          ],

          // Section : Derniers résultats historiques analysés
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Résultats Récents (Historique)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(3),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),
          if (controller.historicalMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Aucun match enregistré. Importez l\'échantillon dans Paramètres.',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...controller.historicalMatches
                .take(4)
                .map((m) => MatchCard(match: m)),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
