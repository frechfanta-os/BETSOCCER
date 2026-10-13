import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/match.dart';
import '../screens/match_details_screen.dart';

class FeaturedMatchCard extends StatelessWidget {
  final MatchEntity? match;

  const FeaturedMatchCard({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final homeTeam = match?.homeTeamName ?? 'Real Madrid';
    final awayTeam = match?.awayTeamName ?? 'Barcelona';
    final compName = match?.competitionName ?? 'Champions League';
    final homeScore = match?.result?.homeScore ?? 2;
    final awayScore = match?.result?.awayScore ?? 1;
    final minuteText = match?.currentMinute ?? '67\'';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: InkWell(
        onTap: () {
          if (match != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchDetailsScreen(match: match!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF132A4F),
                      Color(0xFF0D1B33),
                      Color(0xFF091325),
                    ]
                  : const [
                      Color(0xFF1A3868),
                      Color(0xFF12284C),
                      Color(0xFF0A1933),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFF1E3A68),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Ligne supérieure : Statut LIVE NOW + Compétition
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: AppColors.liveRed, size: 8),
                        SizedBox(width: 5),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    compName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Zone Centrale : Équipe Domicile - Score & Minute - Équipe Extérieur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Équipe 1 (Domicile)
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamBadge(homeTeam, Colors.amber),
                        const SizedBox(height: 8),
                        Text(
                          homeTeam,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score central & Pastille de minute
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Text(
                          '$homeScore - $awayScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonLime,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            minuteText,
                            style: const TextStyle(
                              color: Color(0xFF0A111F),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Équipe 2 (Extérieur)
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamBadge(awayTeam, Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          awayTeam,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Points indicateurs de carrousel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCarouselDot(isActive: true),
                  _buildCarouselDot(isActive: false),
                  _buildCarouselDot(isActive: false),
                  _buildCarouselDot(isActive: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String teamName, Color accentColor) {
    final initials = teamName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'T',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 16 : 6,
      height: 5,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.neonLime
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
