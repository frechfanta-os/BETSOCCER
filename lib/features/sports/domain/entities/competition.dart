/// Entité représentant une compétition / championnat
class CompetitionEntity {
  final String id;
  final String sportId;
  final String name;
  final String? code;
  final String? country;
  final String? countryCode;
  final String? badgeUrl;
  final int? tier;
  final String sourceProvider;

  const CompetitionEntity({
    required this.id,
    required this.sportId,
    required this.name,
    this.code,
    this.country,
    this.countryCode,
    this.badgeUrl,
    this.tier,
    required this.sourceProvider,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sport_id': sportId,
    'name': name,
    'code': code,
    'country': country,
    'country_code': countryCode,
    'badge_url': badgeUrl,
    'tier': tier,
    'source_provider': sourceProvider,
  };

  factory CompetitionEntity.fromMap(Map<String, dynamic> map) =>
      CompetitionEntity(
        id: map['id'] as String,
        sportId: map['sport_id'] as String,
        name: map['name'] as String,
        code: map['code'] as String?,
        country: map['country'] as String?,
        countryCode: map['country_code'] as String?,
        badgeUrl: map['badge_url'] as String?,
        tier: map['tier'] as int?,
        sourceProvider: map['source_provider'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
