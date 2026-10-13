import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/match_details_screen.dart';

enum MatchCardVariant {
  todayRow, // Ligne compacte avec badge et favori (Écran 1 : Home)
  liveMetrics, // Carte complète avec tirs, possession, tirs cadrés (Écran 2 : Live)
  fixtureRow, // Carte de calendrier avec heure et "vs" (Écran 3 : Fixtures)
}

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final MatchCardVariant variant;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.variant = MatchCardVariant.todayRow,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchDetailsScreen(match: match),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: switch (variant) {
              MatchCardVariant.fixtureRow => _buildFixtureRow(
                primaryTextColor,
                secondaryTextColor,
                isDark,
              ),
              MatchCardVariant.liveMetrics => _buildLiveMetricsCard(
                primaryTextColor,
                secondaryTextColor,
                isDark,
              ),
              MatchCardVariant.todayRow => _buildTodayRow(
                primaryTextColor,
                secondaryTextColor,
                isDark,
              ),
            },
          ),
        ),
      ),
    );
  }

  // --- 1. VARIANT TODAY ROW (Home Screen) ---
  Widget _buildTodayRow(Color primaryColor, Color secondaryColor, bool isDark) {
    final timeStr = _formatShortTime(match.utcKickoff);
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live;

    final scoreStr = match.result != null
        ? '${match.result!.homeScore ?? 0} - ${match.result!.awayScore ?? 0}'
        : 'vs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne Compétition
        Row(
          children: [
            _buildMiniBadge(match.competitionName ?? 'Football', isDark),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                match.competitionName ?? 'Compétition',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Ligne Heure - Équipes - Score - Badge Minute - Étoile
        Row(
          children: [
            // Heure / Statut
            SizedBox(
              width: 44,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
            ),

            // Équipe Domicile
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  _buildTeamCircle(match.homeTeamName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.homeTeamName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Score central
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                scoreStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isLive ? AppColors.neonLime : primaryColor,
                ),
              ),
            ),

            // Équipe Extérieur
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  _buildTeamCircle(match.awayTeamName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.awayTeamName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Badge de minute ou statut
            _buildMinuteOrStatusBadge(isFinished, isLive),

            // Bouton Favori
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? AppColors.warningAmber : secondaryColor,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onFavoriteToggle,
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. VARIANT LIVE METRICS (Live Center) ---
  Widget _buildLiveMetricsCard(
    Color primaryColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final scoreStr = match.result != null
        ? '${match.result!.homeScore ?? 0} - ${match.result!.awayScore ?? 0}'
        : '0 - 0';

    final isLive = match.status == MatchStatus.live;

    return Column(
      children: [
        // En-tête : Compétition, minute néon, étoile
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildMiniBadge(match.competitionName ?? 'League', isDark),
                const SizedBox(width: 6),
                Text(
                  match.competitionName ?? 'Premier League',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildMinuteBadge(
                  match.currentMinute ?? (isLive ? '67\'' : 'FT'),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? AppColors.warningAmber : secondaryColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Ligne Équipes & Gros score central
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Équipe Domicile
            Expanded(
              child: Row(
                children: [
                  _buildTeamCircle(match.homeTeamName, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      match.homeTeamName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Score central
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                scoreStr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            ),

            // Équipe Extérieur
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      match.awayTeamName,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTeamCircle(match.awayTeamName, size: 28),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Barre des métriques en direct (Tirs, Possession, Tirs cadrés)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceElevatedDark
                : AppColors.surfaceElevatedLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLiveStatColumn(
                'Tirs',
                '12 - 6',
                secondaryColor,
                primaryColor,
              ),
              _buildLiveStatColumn(
                'Possession',
                '58% - 42%',
                secondaryColor,
                primaryColor,
              ),
              _buildLiveStatColumn(
                'Cadrés',
                '5 - 2',
                secondaryColor,
                primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. VARIANT FIXTURE ROW (Calendrier des Matchs) ---
  Widget _buildFixtureRow(
    Color primaryColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final timeStr = _formatShortTime(match.utcKickoff);

    return Row(
      children: [
        // Horaire
        SizedBox(
          width: 44,
          child: Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: secondaryColor,
            ),
          ),
        ),

        // Équipe 1 (Domicile)
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildTeamCircle(match.homeTeamName),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.homeTeamName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // "vs"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'vs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: secondaryColor,
            ),
          ),
        ),

        // Équipe 2 (Extérieur)
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildTeamCircle(match.awayTeamName),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.awayTeamName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Étoile de favori
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFavorite ? AppColors.warningAmber : secondaryColor,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onFavoriteToggle,
        ),
      ],
    );
  }

  Widget _buildLiveStatColumn(
    String label,
    String value,
    Color secondaryColor,
    Color primaryColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMinuteOrStatusBadge(bool isFinished, bool isLive) {
    if (isLive) {
      return _buildMinuteBadge(match.currentMinute ?? '67\'');
    }
    if (isFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'FT',
          style: TextStyle(
            color: AppColors.warningAmber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'À VENIR',
        style: TextStyle(
          color: AppColors.statBlue,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMinuteBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neonLime,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0A111F),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTeamCircle(String teamName, {double size = 22}) {
    final initials = teamName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neonLime.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.neonLime, width: 0.8),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'T',
          style: TextStyle(
            color: AppColors.neonLime,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, bool isDark) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 9, color: AppColors.neonLime),
      ),
    );
  }

  String _formatShortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
