import 'match_result.dart';
import 'match_statistic.dart';

/// Statut normalisé d'une rencontre sportive
enum MatchStatus {
  upcoming,
  live,
  finished,
  postponed,
  cancelled;

  static MatchStatus fromString(String val) {
    return switch (val.toLowerCase().trim()) {
      'live' ||
      'in_play' ||
      'playing' ||
      '1h' ||
      '2h' ||
      'ht' => MatchStatus.live,
      'finished' ||
      'ft' ||
      'aet' ||
      'pen' ||
      'completed' => MatchStatus.finished,
      'postponed' => MatchStatus.postponed,
      'cancelled' || 'canceled' => MatchStatus.cancelled,
      _ => MatchStatus.upcoming,
    };
  }
}

/// Entité représentant une rencontre sportive
class MatchEntity {
  final String id;
  final String sportId;
  final String competitionId;
  final String? competitionName;
  final String? seasonId;
  final String homeTeamId;
  final String homeTeamName;
  final String? homeTeamBadge;
  final String awayTeamId;
  final String awayTeamName;
  final String? awayTeamBadge;
  final DateTime utcKickoff;
  final MatchStatus status;
  final int? matchday;
  final String? roundLabel;
  final String? currentMinute;
  final bool isSampleData;
  final String sourceProvider;
  final String? sourceMatchId;
  final DateTime lastSyncedAt;

  // Données associées facultatives
  final MatchResultEntity? result;
  final List<MatchStatisticEntity> statistics;

  const MatchEntity({
    required this.id,
    required this.sportId,
    required this.competitionId,
    this.competitionName,
    this.seasonId,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamBadge,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamBadge,
    required this.utcKickoff,
    required this.status,
    this.matchday,
    this.roundLabel,
    this.currentMinute,
    this.isSampleData = false,
    required this.sourceProvider,
    this.sourceMatchId,
    required this.lastSyncedAt,
    this.result,
    this.statistics = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sport_id': sportId,
    'competition_id': competitionId,
    'season_id': seasonId,
    'home_team_id': homeTeamId,
    'away_team_id': awayTeamId,
    'utc_kickoff': utcKickoff.toUtc().toIso8601String(),
    'status': status.name,
    'matchday': matchday,
    'round_label': roundLabel,
    'current_minute': currentMinute,
    'is_sample_data': isSampleData ? 1 : 0,
    'source_provider': sourceProvider,
    'source_match_id': sourceMatchId,
    'last_synced_at': lastSyncedAt.toUtc().toIso8601String(),
  };

  factory MatchEntity.fromMap(
    Map<String, dynamic> map, {
    String? homeTeamName,
    String? awayTeamName,
    String? compName,
    MatchResultEntity? result,
    List<MatchStatisticEntity> stats = const [],
  }) => MatchEntity(
    id: map['id'] as String,
    sportId: map['sport_id'] as String,
    competitionId: map['competition_id'] as String,
    competitionName: compName ?? map['competition_name'] as String?,
    seasonId: map['season_id'] as String?,
    homeTeamId: map['home_team_id'] as String,
    homeTeamName:
        homeTeamName ?? map['home_team_name'] as String? ?? 'Équipe Domicile',
    homeTeamBadge: map['home_team_badge'] as String?,
    awayTeamId: map['away_team_id'] as String,
    awayTeamName:
        awayTeamName ?? map['away_team_name'] as String? ?? 'Équipe Extérieur',
    awayTeamBadge: map['away_team_badge'] as String?,
    utcKickoff: DateTime.parse(map['utc_kickoff'] as String).toUtc(),
    status: MatchStatus.fromString(map['status'] as String),
    matchday: map['matchday'] as int?,
    roundLabel: map['round_label'] as String?,
    currentMinute: map['current_minute'] as String?,
    isSampleData: (map['is_sample_data'] as int? ?? 0) == 1,
    sourceProvider: map['source_provider'] as String,
    sourceMatchId: map['source_match_id'] as String?,
    lastSyncedAt: DateTime.parse(map['last_synced_at'] as String).toUtc(),
    result: result,
    statistics: stats,
  );
}
