import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/brand_header.dart';
import '../widgets/sports_selector_bar.dart';
import '../widgets/featured_match_card.dart';
import '../widgets/match_card.dart';
import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final SportsController controller;
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, required this.controller, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final todayMatches = controller.todayMatches;

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
              // 1. En-tête de marque BETSOCCER
              SliverToBoxAdapter(
                child: BrandHeader(
                  onSearchTap: () {},
                  onNotificationTap: () {},
                ),
              ),

              // 2. Sélecteur de Sports (Pills horizontales)
              SliverToBoxAdapter(
                child: SportsSelectorBar(
                  selectedSport: controller.selectedSportFilter,
                  onSportSelected: (sport) => controller.setSportFilter(sport),
                ),
              ),

              // 3. Match à la une (Hero Banner Card)
              SliverToBoxAdapter(
                child: FeaturedMatchCard(match: controller.featuredMatch),
              ),

              // 4. En-tête de section "Today's Matches"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Matches",
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      InkWell(
                        onTap: () => onNavigateTab?.call(
                          1,
                        ), // Navigue vers Direct / Live
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'See all',
                                style: TextStyle(
                                  color: AppColors.neonLime,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.neonLime,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Liste des Matchs du Jour
              if (todayMatches.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_soccer_rounded,
                          size: 40,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Aucun match pour ${controller.selectedSportFilter}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
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
                    final match = todayMatches[index];
                    return MatchCard(
                      match: match,
                      variant: MatchCardVariant.todayRow,
                      isFavorite: controller.isFavoriteMatch(match.id),
                      onFavoriteToggle: () =>
                          controller.toggleFavoriteMatch(match.id),
                    );
                  }, childCount: todayMatches.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
