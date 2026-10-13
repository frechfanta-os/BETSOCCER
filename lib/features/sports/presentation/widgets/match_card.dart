import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

/// Carte visuelle présentant une rencontre sportive
class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback? onTap;

  const MatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : Compétition, Statut et Badge échantillon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.competitionName ?? match.roundLabel ?? 'Rencontre',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (match.isSampleData) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.sampleAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.sampleAmber,
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'ÉCHANTILLON',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sampleAmber,
                            ),
                          ),
                        ),
                      ],
                      _buildStatusBadge(match.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ligne centrale : Équipes et Score / Heure
              Row(
                children: [
                  // Équipe domicile
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.homeTeamName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Score ou Horaire central
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: match.result != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: match.status == MatchStatus.live
                                    ? AppColors.liveRed.withValues(alpha: 0.15)
                                    : Colors.black26,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                match.result!.formatScore(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: match.status == MatchStatus.live
                                      ? AppColors.liveRed
                                      : null,
                                ),
                              ),
                            )
                          : Text(
                              AppDateUtils.formatDisplay(match.utcKickoff),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.upcomingBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),

                  // Équipe extérieur
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          match.awayTeamName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Ligne inférieure : Source de données et mi-temps si disponible
              if (match.result?.homeHalftimeScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Source: ${match.sourceProvider}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    Text(
                      'MT: ${match.result!.homeHalftimeScore} - ${match.result!.awayHalftimeScore}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MatchStatus status) {
    final (label, color) = switch (status) {
      MatchStatus.live => ('EN DIRECT', AppColors.liveRed),
      MatchStatus.upcoming => ('À VENIR', AppColors.upcomingBlue),
      MatchStatus.finished => ('TERMINÉ', AppColors.finishedGrey),
      MatchStatus.postponed => ('REPORTÉ', AppColors.sampleAmber),
      MatchStatus.cancelled => ('ANNULÉ', Colors.redAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
