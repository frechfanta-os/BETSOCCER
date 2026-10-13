// Modèles de données pour les métriques statistiques descriptives et de forme.

/// Représentation du résultat d'un match sous forme de lettre de forme
enum MatchOutcome {
  win, // 'W'
  draw, // 'D'
  loss, // 'L'
}

/// Statistique descriptive de la forme récente d'une équipe
class TeamRecentForm {
  final String teamId;
  final String teamName;
  final List<MatchOutcome> outcomes; // Du plus ancien au plus récent
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsScored;
  final int goalsConceded;
  final int points; // 3 pts victoire, 1 pt nul (football)
  final double pointsPerMatch;
  final double winRate;
  final bool hasSufficientData;

  const TeamRecentForm({
    required this.teamId,
    required this.teamName,
    required this.outcomes,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsScored,
    required this.goalsConceded,
    required this.points,
    required this.pointsPerMatch,
    required this.winRate,
    required this.hasSufficientData,
  });

  /// Chaîne de forme ex: "W,D,L,W,W"
  String get formString => outcomes
      .map((o) {
        switch (o) {
          case MatchOutcome.win:
            return 'W';
          case MatchOutcome.draw:
            return 'D';
          case MatchOutcome.loss:
            return 'L';
        }
      })
      .join(',');

  int get goalDifference => goalsScored - goalsConceded;

  double get averageGoalsScored =>
      matchesPlayed > 0 ? goalsScored / matchesPlayed : 0.0;

  double get averageGoalsConceded =>
      matchesPlayed > 0 ? goalsConceded / matchesPlayed : 0.0;
}

/// Statistiques scindées domicile / extérieur
class VenueSplitStats {
  final String teamId;
  final int homeMatchesPlayed;
  final int homeWins;
  final int homeDraws;
  final int homeLosses;
  final int homeGoalsScored;
  final int homeGoalsConceded;

  final int awayMatchesPlayed;
  final int awayWins;
  final int awayDraws;
  final int awayLosses;
  final int awayGoalsScored;
  final int awayGoalsConceded;

  const VenueSplitStats({
    required this.teamId,
    required this.homeMatchesPlayed,
    required this.homeWins,
    required this.homeDraws,
    required this.homeLosses,
    required this.homeGoalsScored,
    required this.homeGoalsConceded,
    required this.awayMatchesPlayed,
    required this.awayWins,
    required this.awayDraws,
    required this.awayLosses,
    required this.awayGoalsScored,
    required this.awayGoalsConceded,
  });

  double get homeWinRate =>
      homeMatchesPlayed > 0 ? homeWins / homeMatchesPlayed : 0.0;

  double get awayWinRate =>
      awayMatchesPlayed > 0 ? awayWins / awayMatchesPlayed : 0.0;

  double get homeAvgGoalsScored =>
      homeMatchesPlayed > 0 ? homeGoalsScored / homeMatchesPlayed : 0.0;

  double get awayAvgGoalsScored =>
      awayMatchesPlayed > 0 ? awayGoalsScored / awayMatchesPlayed : 0.0;
}

/// Bilan historique des confrontations directes (Head-to-Head)
class HeadToHeadSummary {
  final String teamAId;
  final String teamAName;
  final String teamBId;
  final String teamBName;
  final int totalMatches;
  final int teamAWins;
  final int draws;
  final int teamBWins;
  final int teamAGoals;
  final int teamBGoals;
  final bool hasSufficientHistory; // true si >= 2 confrontations

  const HeadToHeadSummary({
    required this.teamAId,
    required this.teamAName,
    required this.teamBId,
    required this.teamBName,
    required this.totalMatches,
    required this.teamAWins,
    required this.draws,
    required this.teamBWins,
    required this.teamAGoals,
    required this.teamBGoals,
    required this.hasSufficientHistory,
  });

  factory HeadToHeadSummary.empty({
    required String teamAId,
    required String teamAName,
    required String teamBId,
    required String teamBName,
  }) {
    return HeadToHeadSummary(
      teamAId: teamAId,
      teamAName: teamAName,
      teamBId: teamBId,
      teamBName: teamBName,
      totalMatches: 0,
      teamAWins: 0,
      draws: 0,
      teamBWins: 0,
      teamAGoals: 0,
      teamBGoals: 0,
      hasSufficientHistory: false,
    );
  }
}
