/// Entité représentant un indicateur statistique d'une rencontre
class MatchStatisticEntity {
  final String id;
  final String matchId;
  final String
  metricName; // ex: xG, possession, shots_on_target, dangerous_attacks
  final double? homeValue;
  final double? awayValue;
  final String? rawUnit; // ex: "%", "count", "metric"

  const MatchStatisticEntity({
    required this.id,
    required this.matchId,
    required this.metricName,
    this.homeValue,
    this.awayValue,
    this.rawUnit,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'match_id': matchId,
    'metric_name': metricName,
    'home_value': homeValue,
    'away_value': awayValue,
    'raw_unit': rawUnit,
  };

  factory MatchStatisticEntity.fromMap(Map<String, dynamic> map) =>
      MatchStatisticEntity(
        id: map['id'] as String,
        matchId: map['match_id'] as String,
        metricName: map['metric_name'] as String,
        homeValue: (map['home_value'] as num?)?.toDouble(),
        awayValue: (map['away_value'] as num?)?.toDouble(),
        rawUnit: map['raw_unit'] as String?,
      );
}
