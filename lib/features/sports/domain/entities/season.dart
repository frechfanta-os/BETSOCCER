/// Entité représentant une saison sportive
class SeasonEntity {
  final String id;
  final String competitionId;
  final String yearLabel;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;

  const SeasonEntity({
    required this.id,
    required this.competitionId,
    required this.yearLabel,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'competition_id': competitionId,
    'year_label': yearLabel,
    'start_date': startDate,
    'end_date': endDate,
    'is_current': isCurrent ? 1 : 0,
  };

  factory SeasonEntity.fromMap(Map<String, dynamic> map) => SeasonEntity(
    id: map['id'] as String,
    competitionId: map['competition_id'] as String,
    yearLabel: map['year_label'] as String,
    startDate: map['start_date'] as String?,
    endDate: map['end_date'] as String?,
    isCurrent: (map['is_current'] as int? ?? 0) == 1,
  );
}
