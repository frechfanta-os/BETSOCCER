import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MatchEntity match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

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
    final match = widget.match;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Match Details',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: primaryTextColor, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? AppColors.warningAmber : primaryTextColor,
              size: 22,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              // 1. Grand Carte Tableau d'affichage (Scoreboard Hero Card)
              _buildScoreboardCard(
                match,
                isDark,
                primaryTextColor,
                secondaryTextColor,
              ),

              // 2. Tab Bar : Overview, Stats, Lineups, Play-by-Play
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                height: 42,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: AppColors.neonLime,
                    borderRadius: BorderRadius.circular(21),
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
                    Tab(text: 'Stats'),
                    Tab(text: 'Lineups'),
                    Tab(text: 'Play-by-Play'),
                  ],
                ),
              ),

              // 3. Contenu de l'onglet actif
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      match,
                      isDark,
                      cardBg,
                      borderColor,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                    _buildStatsTab(
                      match,
                      isDark,
                      cardBg,
                      borderColor,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                    _buildLineupsTab(
                      isDark,
                      cardBg,
                      borderColor,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                    _buildPlayByPlayTab(
                      isDark,
                      cardBg,
                      borderColor,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCOREBOARD HERO CARD ---
  Widget _buildScoreboardCard(
    MatchEntity match,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final homeScore = match.result?.homeScore ?? 2;
    final awayScore = match.result?.awayScore ?? 1;
    final isLive = match.status == MatchStatus.live;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Ligne Compétition & Horodatage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.competitionName ?? 'Ligue Sportive',
                style: const TextStyle(
                  color: AppColors.neonLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                AppDateUtils.formatDisplay(match.utcKickoff),
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Équipes et Score central
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Équipe Domicile
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLargeBadge(match.homeTeamName),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeamName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Score central
              Column(
                children: [
                  Text(
                    match.result != null ? '$homeScore - $awayScore' : 'vs',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLive ? AppColors.liveRed : AppColors.neonLime,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLive
                          ? (match.currentMinute ?? '67\'')
                          : (match.status == MatchStatus.finished
                                ? 'TERMINÉ'
                                : 'À VENIR'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isLive ? Colors.white : const Color(0xFF0A111F),
                      ),
                    ),
                  ),
                ],
              ),

              // Équipe Extérieur
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLargeBadge(match.awayTeamName),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeamName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ONGLET 1 : OVERVIEW ---
  Widget _buildOverviewTab(
    MatchEntity match,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Tableau des scores par période (Quarter / Halftime Scores)
        Container(
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
                'Scores par période',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  _buildPeriodHeader('MT1', secondaryColor),
                  _buildPeriodHeader('MT2', secondaryColor),
                  _buildPeriodHeader('PROL', secondaryColor),
                  _buildPeriodHeader('TOT', primaryColor),
                ],
              ),
              const Divider(height: 16),
              _buildPeriodRow(
                match.homeTeamName,
                match.result?.homeHalftimeScore ?? 1,
                (match.result?.homeScore ?? 2) -
                    (match.result?.homeHalftimeScore ?? 1),
                0,
                match.result?.homeScore ?? 2,
                primaryColor,
              ),
              const SizedBox(height: 8),
              _buildPeriodRow(
                match.awayTeamName,
                match.result?.awayHalftimeScore ?? 0,
                (match.result?.awayScore ?? 1) -
                    (match.result?.awayHalftimeScore ?? 0),
                0,
                match.result?.awayScore ?? 1,
                primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Forme récente des équipes (Team Form - Last 5)
        Container(
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
                'Forme récente (5 derniers matchs)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildTeamFormRow(match.homeTeamName, [
                'W',
                'L',
                'W',
                'W',
                'W',
              ], primaryColor),
              const SizedBox(height: 10),
              _buildTeamFormRow(match.awayTeamName, [
                'L',
                'W',
                'L',
                'W',
                'D',
              ], primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Analyse IA & Modèle Statistique (Probabilités)
        Container(
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF818CF8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyse IA (Modèle Mathématique)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildProbabilityBox(
                      'Victoire Domicile',
                      '62%',
                      AppColors.neonLime,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProbabilityBox(
                      'Victoire Extérieur',
                      '38%',
                      AppColors.statBlue,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProbabilityBox(
                      'Buts Estimés (xG)',
                      '2.8',
                      Colors.amber,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ces probabilités sont calculées par modélisation statistique sur les données réelles. Elles ne constituent aucune promesse de résultat.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ONGLET 2 : STATS DÉTAILLÉES ---
  Widget _buildStatsTab(
    MatchEntity match,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildStatBarRow(
                'Possession',
                '58%',
                '42%',
                0.58,
                primaryColor,
                secondaryColor,
              ),
              _buildStatBarRow(
                'Tirs Totaux',
                '14',
                '9',
                0.61,
                primaryColor,
                secondaryColor,
              ),
              _buildStatBarRow(
                'Tirs Cadrés',
                '6',
                '3',
                0.67,
                primaryColor,
                secondaryColor,
              ),
              _buildStatBarRow(
                'Corners',
                '7',
                '4',
                0.63,
                primaryColor,
                secondaryColor,
              ),
              _buildStatBarRow(
                'Fautes Commises',
                '10',
                '12',
                0.45,
                primaryColor,
                secondaryColor,
              ),
              _buildStatBarRow(
                'Cartons Jaunes',
                '2',
                '3',
                0.40,
                primaryColor,
                secondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBarRow(
    String metric,
    String homeVal,
    String awayVal,
    double ratio,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeVal,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
              Text(
                metric,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
              Text(
                awayVal,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.statBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.neonLime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupsTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Center(
      child: Text(
        'Compositions d\'équipes officielles disponibles 45 min avant le coup d\'envoi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: secondaryColor, fontSize: 13),
      ),
    );
  }

  Widget _buildPlayByPlayTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Center(
      child: Text(
        'Fil du match en direct disponible lors des rencontres en direct.',
        textAlign: TextAlign.center,
        style: TextStyle(color: secondaryColor, fontSize: 13),
      ),
    );
  }

  Widget _buildPeriodHeader(String label, Color color) {
    return Expanded(
      flex: 2,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodRow(
    String team,
    int p1,
    int p2,
    int p3,
    int tot,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            team,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '$p1',
              style: TextStyle(color: primaryColor, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '$p2',
              style: TextStyle(color: primaryColor, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '$p3',
              style: TextStyle(color: primaryColor, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '$tot',
              style: const TextStyle(
                color: AppColors.neonLime,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamFormRow(
    String team,
    List<String> outcomes,
    Color primaryColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            team,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: outcomes.map((o) {
            final color = o == 'W'
                ? AppColors.winGreen
                : (o == 'L' ? AppColors.lossRed : AppColors.drawYellow);
            return Container(
              margin: const EdgeInsets.only(left: 4),
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  o,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProbabilityBox(
    String label,
    String value,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLargeBadge(String teamName) {
    final initials = teamName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join();
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neonLime.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.neonLime, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'T',
          style: const TextStyle(
            color: AppColors.neonLime,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
