import '../../../features/sports/domain/entities/match.dart';
import '../models/statistical_metrics.dart';

/// Calculateur indépendant de statistiques descriptives et d'analyse de forme
class DescriptiveStatsCalculator {
  /// Calcule la forme récente d'une équipe sur une fenêtre glissante de N matchs
  /// [cutoffDate] garantit l'absence de fuite temporelle si spécifié.
  static TeamRecentForm computeRecentForm({
    required String teamId,
    required String teamName,
    required List<MatchEntity> matches,
    int limit = 5,
    DateTime? cutoffDate,
  }) {
    // 1. Filtrer les matchs terminés valides avec résultat
    var teamMatches = matches.where((m) {
      if (m.status != MatchStatus.finished || m.result == null) {
        return false;
      }
      if (m.result!.homeScore == null || m.result!.awayScore == null) {
        return false;
      }
      if (cutoffDate != null && m.utcKickoff.isAfter(cutoffDate)) {
        return false;
      }
      return m.homeTeamId == teamId || m.awayTeamId == teamId;
    }).toList();

    // 2. Trier chronologiquement par date de coup d'envoi croissant
    teamMatches.sort((a, b) => a.utcKickoff.compareTo(b.utcKickoff));

    // 3. Prendre les N derniers matchs
    if (teamMatches.length > limit) {
      teamMatches = teamMatches.sublist(teamMatches.length - limit);
    }

    final outcomes = <MatchOutcome>[];
    int wins = 0;
    int draws = 0;
    int losses = 0;
    int goalsScored = 0;
    int goalsConceded = 0;

    for (final m in teamMatches) {
      final isHome = m.homeTeamId == teamId;
      final scored = isHome ? m.result!.homeScore! : m.result!.awayScore!;
      final conceded = isHome ? m.result!.awayScore! : m.result!.homeScore!;

      goalsScored += scored;
      goalsConceded += conceded;

      if (scored > conceded) {
        wins++;
        outcomes.add(MatchOutcome.win);
      } else if (scored == conceded) {
        draws++;
        outcomes.add(MatchOutcome.draw);
      } else {
        losses++;
        outcomes.add(MatchOutcome.loss);
      }
    }

    final played = teamMatches.length;
    final points = (wins * 3) + draws;
    final pointsPerMatch = played > 0 ? points / played : 0.0;
    final winRate = played > 0 ? wins / played : 0.0;

    return TeamRecentForm(
      teamId: teamId,
      teamName: teamName,
      outcomes: outcomes,
      matchesPlayed: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsScored: goalsScored,
      goalsConceded: goalsConceded,
      points: points,
      pointsPerMatch: pointsPerMatch,
      winRate: winRate,
      hasSufficientData: played >= 3,
    );
  }

  /// Calcule les statistiques scindées Domicile vs Extérieur
  static VenueSplitStats computeVenueSplits({
    required String teamId,
    required List<MatchEntity> matches,
    DateTime? cutoffDate,
  }) {
    int homeMatches = 0;
    int homeWins = 0;
    int homeDraws = 0;
    int homeLosses = 0;
    int homeScored = 0;
    int homeConceded = 0;

    int awayMatches = 0;
    int awayWins = 0;
    int awayDraws = 0;
    int awayLosses = 0;
    int awayScored = 0;
    int awayConceded = 0;

    for (final m in matches) {
      if (m.status != MatchStatus.finished || m.result == null) {
        continue;
      }
      if (m.result!.homeScore == null || m.result!.awayScore == null) {
        continue;
      }
      if (cutoffDate != null && m.utcKickoff.isAfter(cutoffDate)) {
        continue;
      }

      if (m.homeTeamId == teamId) {
        homeMatches++;
        final s = m.result!.homeScore!;
        final c = m.result!.awayScore!;
        homeScored += s;
        homeConceded += c;
        if (s > c) {
          homeWins++;
        } else if (s == c) {
          homeDraws++;
        } else {
          homeLosses++;
        }
      } else if (m.awayTeamId == teamId) {
        awayMatches++;
        final s = m.result!.awayScore!;
        final c = m.result!.homeScore!;
        awayScored += s;
        awayConceded += c;
        if (s > c) {
          awayWins++;
        } else if (s == c) {
          awayDraws++;
        } else {
          awayLosses++;
        }
      }
    }

    return VenueSplitStats(
      teamId: teamId,
      homeMatchesPlayed: homeMatches,
      homeWins: homeWins,
      homeDraws: homeDraws,
      homeLosses: homeLosses,
      homeGoalsScored: homeScored,
      homeGoalsConceded: homeConceded,
      awayMatchesPlayed: awayMatches,
      awayWins: awayWins,
      awayDraws: awayDraws,
      awayLosses: awayLosses,
      awayGoalsScored: awayScored,
      awayGoalsConceded: awayConceded,
    );
  }

  /// Calcule l'historique des confrontations directes (H2H)
  static HeadToHeadSummary computeHeadToHead({
    required String teamAId,
    required String teamAName,
    required String teamBId,
    required String teamBName,
    required List<MatchEntity> matches,
    DateTime? cutoffDate,
  }) {
    int total = 0;
    int aWins = 0;
    int draws = 0;
    int bWins = 0;
    int aGoals = 0;
    int bGoals = 0;

    for (final m in matches) {
      if (m.status != MatchStatus.finished || m.result == null) {
        continue;
      }
      if (m.result!.homeScore == null || m.result!.awayScore == null) {
        continue;
      }
      if (cutoffDate != null && m.utcKickoff.isAfter(cutoffDate)) {
        continue;
      }

      final isHomeA = m.homeTeamId == teamAId && m.awayTeamId == teamBId;
      final isHomeB = m.homeTeamId == teamBId && m.awayTeamId == teamAId;

      if (!isHomeA && !isHomeB) {
        continue;
      }

      total++;
      if (isHomeA) {
        final hs = m.result!.homeScore!;
        final as_ = m.result!.awayScore!;
        aGoals += hs;
        bGoals += as_;
        if (hs > as_) {
          aWins++;
        } else if (hs == as_) {
          draws++;
        } else {
          bWins++;
        }
      } else {
        final hs = m.result!.homeScore!;
        final as_ = m.result!.awayScore!;
        bGoals += hs;
        aGoals += as_;
        if (hs > as_) {
          bWins++;
        } else if (hs == as_) {
          draws++;
        } else {
          aWins++;
        }
      }
    }

    return HeadToHeadSummary(
      teamAId: teamAId,
      teamAName: teamAName,
      teamBId: teamBId,
      teamBName: teamBName,
      totalMatches: total,
      teamAWins: aWins,
      draws: draws,
      teamBWins: bWins,
      teamAGoals: aGoals,
      teamBGoals: bGoals,
      hasSufficientHistory: total >= 2,
    );
  }
}
