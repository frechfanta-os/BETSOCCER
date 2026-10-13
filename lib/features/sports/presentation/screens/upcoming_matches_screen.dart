import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/brand_header.dart';
import '../widgets/sports_selector_bar.dart';
import '../widgets/match_card.dart';
import '../../../../core/theme/app_colors.dart';

class UpcomingMatchesScreen extends StatelessWidget {
  final SportsController controller;

  const UpcomingMatchesScreen({super.key, required this.controller});

  static const List<Map<String, dynamic>> _dateItems = [
    {'day': 'Mon', 'date': '12 Oct', 'year': 2026, 'month': 10, 'd': 12},
    {'day': 'Tue', 'date': '13 Oct', 'year': 2026, 'month': 10, 'd': 13},
    {'day': 'Wed', 'date': '14 Oct', 'year': 2026, 'month': 10, 'd': 14},
    {'day': 'Thu', 'date': '15 Oct', 'year': 2026, 'month': 10, 'd': 15},
    {'day': 'Fri', 'date': '16 Oct', 'year': 2026, 'month': 10, 'd': 16},
    {'day': 'Sat', 'date': '17 Oct', 'year': 2026, 'month': 10, 'd': 17},
    {'day': 'Sun', 'date': '18 Oct', 'year': 2026, 'month': 10, 'd': 18},
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
    final fixtures = controller.filteredUpcomingMatches;

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
              // 1. En-tête : BETSOCCER Fixtures
              SliverToBoxAdapter(
                child: BrandHeader(
                  customTitle: 'BETSOCCER Fixtures',
                  subtitle: 'Calendrier des rencontres & cotes',
                  onSearchTap: () {},
                  onNotificationTap: () {},
                ),
              ),

              // 2. Ruban horizontal de sélection de dates (Mon 12 .. Sun 18)
              SliverToBoxAdapter(
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _dateItems.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _dateItems[index];
                      final d = item['d'] as int;
                      final isSelected = controller.selectedDate.day == d;

                      return InkWell(
                        onTap: () {
                          controller.selectDate(
                            DateTime.utc(
                              item['year'] as int,
                              item['month'] as int,
                              d,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.neonLime
                                : (isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.neonLime
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.neonLime.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['day'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF0A111F)
                                      : secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item['d']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? const Color(0xFF0A111F)
                                      : primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. Sélecteur de Sports (Pills)
              SliverToBoxAdapter(
                child: SportsSelectorBar(
                  selectedSport: controller.selectedSportFilter,
                  onSportSelected: (sport) => controller.setSportFilter(sport),
                ),
              ),

              // 4. Section : Upcoming Matches + Dropdown Compétitions
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
                        'Upcoming Matches',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.selectedCompetitionFilter,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Liste des Fixtures
              if (fixtures.isEmpty)
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
                          Icons.calendar_today_rounded,
                          size: 40,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Aucune rencontre prévue pour cette date',
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
                    final match = fixtures[index];
                    return MatchCard(
                      match: match,
                      variant: MatchCardVariant.fixtureRow,
                      isFavorite: controller.isFavoriteMatch(match.id),
                      onFavoriteToggle: () =>
                          controller.toggleFavoriteMatch(match.id),
                      allMatches: controller.allMatches,
                    );
                  }, childCount: fixtures.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
