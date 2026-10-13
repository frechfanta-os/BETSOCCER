/// Entité représentant une équipe ou un club
class TeamEntity {
  final String id;
  final String sportId;
  final String name;
  final String? shortName;
  final String? tla;
  final String? badgeUrl;
  final String? country;
  final double? eloRating;
  final String sourceProvider;

  const TeamEntity({
    required this.id,
    required this.sportId,
    required this.name,
    this.shortName,
    this.tla,
    this.badgeUrl,
    this.country,
    this.eloRating = 1500.0,
    required this.sourceProvider,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sport_id': sportId,
    'name': name,
    'short_name': shortName,
    'tla': tla,
    'badge_url': badgeUrl,
    'country': country,
    'elo_rating': eloRating,
    'source_provider': sourceProvider,
  };

  factory TeamEntity.fromMap(Map<String, dynamic> map) => TeamEntity(
    id: map['id'] as String,
    sportId: map['sport_id'] as String,
    name: map['name'] as String,
    shortName: map['short_name'] as String?,
    tla: map['tla'] as String?,
    badgeUrl: map['badge_url'] as String?,
    country: map['country'] as String?,
    eloRating: (map['elo_rating'] as num?)?.toDouble() ?? 1500.0,
    sourceProvider: map['source_provider'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
