/// Entité représentant une discipline sportive
class SportEntity {
  final String id;
  final String name;
  final String code;
  final String? iconRef;
  final String sourceProvider;

  const SportEntity({
    required this.id,
    required this.name,
    required this.code,
    this.iconRef,
    required this.sourceProvider,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'code': code,
    'icon_ref': iconRef,
    'source_provider': sourceProvider,
  };

  factory SportEntity.fromMap(Map<String, dynamic> map) => SportEntity(
    id: map['id'] as String,
    name: map['name'] as String,
    code: map['code'] as String,
    iconRef: map['icon_ref'] as String?,
    sourceProvider: map['source_provider'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SportEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
