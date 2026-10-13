import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/brand_header.dart';
import '../widgets/sports_selector_bar.dart';
import '../widgets/match_card.dart';
import '../../../../core/theme/app_colors.dart';

class LiveMatchesScreen extends StatelessWidget {
  final SportsController controller;

  const LiveMatchesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final liveMatches = controller.filteredLiveMatches;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonLime,
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          onRefresh: () => controller.loadInitialData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. En-tête : BETSOCCER • Live Center
              SliverToBoxAdapter(
                child: BrandHeader(
                  trailingBadge: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppColors.liveRed,
                        size: 8,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live Center',
                        style: const TextStyle(
                          color: AppColors.liveRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  onSearchTap: () {},
                  onNotificationTap: () {},
                ),
              ),

              // 2. Sélecteur de Sports (Pills)
              SliverToBoxAdapter(
                child: SportsSelectorBar(
                  selectedSport: controller.selectedSportFilter,
                  onSportSelected: (sport) => controller.setSportFilter(sport),
                ),
              ),

              // 3. Barre de titre : Live Matches (12) + Sort >
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Matches (${liveMatches.length})',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Text(
                              'Sort',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Liste des Matchs en direct avec statistiques avancées
              if (liveMatches.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sensors_off_rounded,
                          size: 40,
                          color: AppColors.liveRed,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Aucune rencontre en direct pour ${controller.selectedSportFilter}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final match = liveMatches[index];
                    return MatchCard(
                      match: match,
                      variant: MatchCardVariant.liveMetrics,
                      isFavorite: controller.isFavoriteMatch(match.id),
                      onFavoriteToggle: () =>
                          controller.toggleFavoriteMatch(match.id),
                    );
                  }, childCount: liveMatches.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
