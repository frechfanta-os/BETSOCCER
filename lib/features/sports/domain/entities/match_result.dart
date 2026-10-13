/// Entité représentant le score d'une rencontre
class MatchResultEntity {
  final String id;
  final String matchId;
  final int? homeScore;
  final int? awayScore;
  final int? homeHalftimeScore;
  final int? awayHalftimeScore;
  final int? homeExtraTimeScore;
  final int? awayExtraTimeScore;
  final int? homePenaltiesScore;
  final int? awayPenaltiesScore;
  final String? winnerTeamId; // null si match nul ou non terminé

  const MatchResultEntity({
    required this.id,
    required this.matchId,
    this.homeScore,
    this.awayScore,
    this.homeHalftimeScore,
    this.awayHalftimeScore,
    this.homeExtraTimeScore,
    this.awayExtraTimeScore,
    this.homePenaltiesScore,
    this.awayPenaltiesScore,
    this.winnerTeamId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'match_id': matchId,
    'home_score': homeScore,
    'away_score': awayScore,
    'home_halftime_score': homeHalftimeScore,
    'away_halftime_score': awayHalftimeScore,
    'home_extratime_score': homeExtraTimeScore,
    'away_extratime_score': awayExtraTimeScore,
    'home_penalties_score': homePenaltiesScore,
    'away_penalties_score': awayPenaltiesScore,
    'winner_team_id': winnerTeamId,
  };

  factory MatchResultEntity.fromMap(Map<String, dynamic> map) =>
      MatchResultEntity(
        id: map['id'] as String,
        matchId: map['match_id'] as String,
        homeScore: map['home_score'] as int?,
        awayScore: map['away_score'] as int?,
        homeHalftimeScore: map['home_halftime_score'] as int?,
        awayHalftimeScore: map['away_halftime_score'] as int?,
        homeExtraTimeScore: map['home_extratime_score'] as int?,
        awayExtraTimeScore: map['away_extratime_score'] as int?,
        homePenaltiesScore: map['home_penalties_score'] as int?,
        awayPenaltiesScore: map['away_penalties_score'] as int?,
        winnerTeamId: map['winner_team_id'] as String?,
      );

  String formatScore() {
    if (homeScore == null || awayScore == null) return '-';
    return '$homeScore - $awayScore';
  }
}
