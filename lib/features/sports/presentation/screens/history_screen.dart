import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../../../../core/theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  final SportsController controller;

  const HistoryScreen({super.key, required this.controller});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final summary = controller.statsAnalyticsSummary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. En-tête : Stats & Analytics + Menu déroulant de Compétition
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stats & Analytics',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.selectedCompetition?.name ??
                                'Premier League',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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

              // 2. Tab Bar sous-jacente : Overview, Teams, Players, Trends
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 40,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: AppColors.neonLime,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelColor: const Color(0xFF0A111F),
                  unselectedLabelColor: secondaryTextColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Teams'),
                    Tab(text: 'Players'),
                    Tab(text: 'Trends'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. Cartes KPI (Horizontal Scroll : 5 cartes statistiques)
              SizedBox(
                height: 96,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildKpiCard(
                      icon: Icons.bar_chart_rounded,
                      value: '${summary['matchesAnalysed']}',
                      label: 'Matches Analysed',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      icon: Icons.sports_soccer_rounded,
                      value: '${summary['avgGoals']}',
                      label: 'Avg Goals / Match',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      icon: Icons.home_rounded,
                      value: '${summary['homeWinPct']}%',
                      label: 'Home Wins',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      icon: Icons.drag_handle_rounded,
                      value: '${summary['drawPct']}%',
                      label: 'Draws',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                    const SizedBox(width: 10),
                    _buildKpiCard(
                      icon: Icons.flight_takeoff_rounded,
                      value: '${summary['awayWinPct']}%',
                      label: 'Away Wins',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Graphique 1 : Tendance de buts (Goals Trend - Last 10 Matches)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goals Trend',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Last 10 Matches',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Légende Home Goals / Away Goals
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.neonLime,
                          size: 8,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Home Goals',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.circle,
                          color: AppColors.statBlue,
                          size: 8,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Away Goals',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Canvas du graphique linéaire multi-courbes
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: GoalsTrendPainter(
                          homeGoals:
                              (summary['homeGoalsTrend'] as List<int>?) ??
                              [2, 1, 3, 2, 4, 1, 2, 3, 1, 2],
                          awayGoals:
                              (summary['awayGoalsTrend'] as List<int>?) ??
                              [1, 2, 1, 2, 2, 3, 1, 1, 2, 1],
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Graphique 2 : Répartition des résultats (Donut Chart)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result Distribution',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Donut Painter avec compteur central
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CustomPaint(
                            painter: ResultDonutPainter(
                              homeWinPct: (summary['homeWinPct'] as int)
                                  .toDouble(),
                              drawPct: (summary['drawPct'] as int).toDouble(),
                              awayWinPct: (summary['awayWinPct'] as int)
                                  .toDouble(),
                              totalMatches: '${summary['matchesAnalysed']}',
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Légende et pourcentages
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDonutLegendRow(
                                color: AppColors.neonLime,
                                label: 'Home Win',
                                pct: '${summary['homeWinPct']}%',
                                primaryColor: primaryTextColor,
                              ),
                              const SizedBox(height: 10),
                              _buildDonutLegendRow(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1),
                                label: 'Draw',
                                pct: '${summary['drawPct']}%',
                                primaryColor: primaryTextColor,
                              ),
                              const SizedBox(height: 10),
                              _buildDonutLegendRow(
                                color: AppColors.statBlue,
                                label: 'Away Win',
                                pct: '${summary['awayWinPct']}%',
                                primaryColor: primaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Classements & Meilleurs joueurs (Top Scorers & Top Assists)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLeaderboardCard(
                        title: 'Top Scorers',
                        playerName: 'Erling Haaland',
                        teamName: 'Manchester City',
                        statValue: '14',
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryColor: primaryTextColor,
                        secondaryColor: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLeaderboardCard(
                        title: 'Top Assists',
                        playerName: 'Kevin De Bruyne',
                        teamName: 'Manchester City',
                        statValue: '10',
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryColor: primaryTextColor,
                        secondaryColor: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 7. Validation Scientifique & Moteur Statistique (Phase 2)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                        const Icon(
                          Icons.science_rounded,
                          size: 18,
                          color: AppColors.neonLime,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Moteur Statistique & Validation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Évaluation chronologique sans fuite temporelle sur les 34 rencontres réelles (walk-forward) :',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 10),
                    _buildScientificRow(
                      'Poisson Dixon-Coles',
                      'Brier : 0.664',
                      'Log-Loss : 1.116',
                      'ECE : 0.064',
                      primaryTextColor,
                      secondaryTextColor,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildScientificRow(
                      'Multi-Sport Elo',
                      'Brier : 0.648',
                      'Log-Loss : 1.072',
                      'BSS : +0.029',
                      primaryTextColor,
                      secondaryTextColor,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildScientificRow(
                      'Référence Uniforme',
                      'Brier : 0.667',
                      'Log-Loss : 1.099',
                      'Hit : 33.3%',
                      primaryTextColor,
                      secondaryTextColor,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Régularisation active par shrinkage bayésien vers la moyenne de la ligue pour prévenir le surapprentissage sur les équipes avec peu de matchs historiques.',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String value,
    required String label,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.neonLime),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required String pct,
    required Color primaryColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        Text(
          pct,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard({
    required String title,
    required String playerName,
    required String teamName,
    required String statValue,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const Text(
                'View all >',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '1',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonLime,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 20, color: Color(0xFF0A111F)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      teamName,
                      style: TextStyle(fontSize: 9, color: secondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                statValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonLime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScientificRow(
    String modelName,
    String brierText,
    String logLossText,
    String secondaryMetric,
    Color primaryColor,
    Color secondaryColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              modelName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonLime.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  brierText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonLime,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                logLossText,
                style: TextStyle(fontSize: 10, color: secondaryColor),
              ),
              const SizedBox(width: 6),
              Text(
                secondaryMetric,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour la tendance de buts (Line Chart)
class GoalsTrendPainter extends CustomPainter {
  final List<int> homeGoals;
  final List<int> awayGoals;
  final bool isDark;

  GoalsTrendPainter({
    required this.homeGoals,
    required this.awayGoals,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    // Lignes de repère horizontales
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = math.max(homeGoals.length, awayGoals.length);
    if (n < 2) return;

    final stepX = size.width / (n - 1);
    const maxVal = 6.0;

    Offset getPoint(int idx, int val) {
      final x = idx * stepX;
      final y =
          size.height - (val / maxVal * size.height).clamp(0.0, size.height);
      return Offset(x, y);
    }

    // Tracer Home Goals (Neon Lime)
    final homePath = Path();
    final homePaint = Paint()
      ..color = AppColors.neonLime
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaintHome = Paint()..color = AppColors.neonLime;

    for (int i = 0; i < homeGoals.length; i++) {
      final p = getPoint(i, homeGoals[i]);
      if (i == 0) {
        homePath.moveTo(p.dx, p.dy);
      } else {
        homePath.lineTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 3.5, dotPaintHome);
    }
    canvas.drawPath(homePath, homePaint);

    // Tracer Away Goals (Blue)
    final awayPath = Path();
    final awayPaint = Paint()
      ..color = AppColors.statBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaintAway = Paint()..color = AppColors.statBlue;

    for (int i = 0; i < awayGoals.length; i++) {
      final p = getPoint(i, awayGoals[i]);
      if (i == 0) {
        awayPath.moveTo(p.dx, p.dy);
      } else {
        awayPath.lineTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 3.5, dotPaintAway);
    }
    canvas.drawPath(awayPath, awayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// CustomPainter pour le Donut Chart de répartition des victoires
class ResultDonutPainter extends CustomPainter {
  final double homeWinPct;
  final double drawPct;
  final double awayWinPct;
  final String totalMatches;
  final bool isDark;

  ResultDonutPainter({
    required this.homeWinPct,
    required this.drawPct,
    required this.awayWinPct,
    required this.totalMatches,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - (strokeWidth / 2),
    );

    double startAngle = -math.pi / 2;

    void drawSegment(double pct, Color color) {
      final sweepAngle = (pct / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    drawSegment(homeWinPct, AppColors.neonLime);
    drawSegment(
      drawPct,
      isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
    );
    drawSegment(awayWinPct, AppColors.statBlue);

    // Texte central : totalMatches + 'Matches'
    final textPainterVal = TextPainter(
      text: TextSpan(
        text: totalMatches,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0A111F),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainterSub = TextPainter(
      text: TextSpan(
        text: 'Matches',
        style: TextStyle(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainterVal.paint(
      canvas,
      Offset(
        center.dx - (textPainterVal.width / 2),
        center.dy - textPainterVal.height + 2,
      ),
    );
    textPainterSub.paint(
      canvas,
      Offset(center.dx - (textPainterSub.width / 2), center.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
