/// Entité représentant un joueur / athlète
class PlayerEntity {
  final String id;
  final String? teamId;
  final String name;
  final String? position;
  final String? nationality;
  final String? photoUrl;
  final String sourceProvider;

  const PlayerEntity({
    required this.id,
    this.teamId,
    required this.name,
    this.position,
    this.nationality,
    this.photoUrl,
    required this.sourceProvider,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'team_id': teamId,
    'name': name,
    'position': position,
    'nationality': nationality,
    'photo_url': photoUrl,
    'source_provider': sourceProvider,
  };

  factory PlayerEntity.fromMap(Map<String, dynamic> map) => PlayerEntity(
    id: map['id'] as String,
    teamId: map['team_id'] as String?,
    name: map['name'] as String,
    position: map['position'] as String?,
    nationality: map['nationality'] as String?,
    photoUrl: map['photo_url'] as String?,
    sourceProvider: map['source_provider'] as String,
  );
}
