import '../../../../core/database/daos/sports_dao.dart';
import '../entities/sport.dart';
import '../entities/competition.dart';
import '../entities/season.dart';
import '../entities/team.dart';
import '../entities/match.dart';
import '../entities/match_result.dart';
import '../interfaces/sports_data_source.dart';
import '../../data/parsers/openfootball_parser.dart';

/// Repository orchestrant l'accès aux données sportives (Offline-First via SQLite)
class SportsRepository {
  final SportsDao sportsDao;
  final List<SportsDataSource> dataSources;

  SportsRepository({required this.sportsDao, required this.dataSources});

  /// Récupère la liste des sports (SQLite d'abord, puis synchronisation)
  Future<List<SportEntity>> getSports({bool forceRefresh = false}) async {
    final cached = await sportsDao.getAllSports();
    if (cached.isNotEmpty && !forceRefresh) {
      return cached;
    }

    for (final source in dataSources.where(
      (s) => s.isEnabled && s.supportsSportsDiscovery,
    )) {
      try {
        final remoteSports = await source.fetchSports();
        if (remoteSports.isNotEmpty) {
          await sportsDao.upsertSports(remoteSports);
          return await sportsDao.getAllSports();
        }
      } catch (_) {
        // En cas d'échec du connecteur, continuer vers le suivant
      }
    }

    return cached;
  }

  /// Récupère les compétitions d'un sport donné
  Future<List<CompetitionEntity>> getCompetitions(
    String sportId, {
    bool forceRefresh = false,
  }) async {
    final cached = await sportsDao.getCompetitionsBySport(sportId);
    if (cached.isNotEmpty && !forceRefresh) {
      return cached;
    }

    for (final source in dataSources.where(
      (s) => s.isEnabled && s.supportsCompetitions,
    )) {
      try {
        final remote = await source.fetchCompetitions(sportId: sportId);
        if (remote.isNotEmpty) {
          await sportsDao.upsertCompetitions(remote);
          return await sportsDao.getCompetitionsBySport(sportId);
        }
      } catch (_) {
        // Fallback gracieux
      }
    }

    return cached;
  }

  /// Récupère les matchs à venir (Fixtures)
  Future<List<MatchEntity>> getUpcomingMatches({
    String? competitionId,
    bool forceRefresh = false,
  }) async {
    final cached = await sportsDao.getMatches(
      competitionId: competitionId,
      status: MatchStatus.upcoming.name,
      from: DateTime.now().toUtc(),
    );
    if (cached.isNotEmpty && !forceRefresh) {
      return cached;
    }

    if (competitionId != null) {
      for (final source in dataSources.where(
        (s) => s.isEnabled && s.supportsUpcomingMatches,
      )) {
        try {
          final remote = await source.fetchUpcomingMatches(
            competitionId: competitionId,
          );
          if (remote.isNotEmpty) {
            await sportsDao.upsertMatches(remote);
            return await sportsDao.getMatches(
              competitionId: competitionId,
              status: MatchStatus.upcoming.name,
            );
          }
        } catch (_) {}
      }
    }

    return cached;
  }

  /// Récupère les matchs en direct (Live)
  Future<List<MatchEntity>> getLiveMatches({
    String? sportId,
    bool forceRefresh = false,
  }) async {
    final cached = await sportsDao.getMatches(status: MatchStatus.live.name);
    if (!forceRefresh && cached.isNotEmpty) {
      return cached;
    }

    for (final source in dataSources.where(
      (s) => s.isEnabled && s.supportsLiveMatches,
    )) {
      try {
        final remote = await source.fetchLiveMatches(sportId: sportId);
        if (remote.isNotEmpty) {
          await sportsDao.upsertMatches(remote);
          return await sportsDao.getMatches(status: MatchStatus.live.name);
        }
      } catch (_) {}
    }

    return cached;
  }

  /// Récupère l'historique d'une saison
  Future<List<MatchEntity>> getHistoricalMatches({
    required String competitionId,
    required String season,
    bool forceRefresh = false,
  }) async {
    final cached = await sportsDao.getMatches(
      competitionId: competitionId,
      status: MatchStatus.finished.name,
    );
    if (cached.isNotEmpty && !forceRefresh) {
      return cached;
    }

    for (final source in dataSources.where(
      (s) => s.isEnabled && s.supportsHistoricalMatches,
    )) {
      try {
        final remote = await source.fetchHistoricalMatches(
          competitionId: competitionId,
          season: season,
        );
        if (remote.isNotEmpty) {
          await sportsDao.upsertMatches(remote);
          return await sportsDao.getMatches(
            competitionId: competitionId,
            status: MatchStatus.finished.name,
          );
        }
      } catch (_) {}
    }

    return cached;
  }

  /// Récupère les détails complets d'un match par ID
  Future<MatchEntity?> getMatchDetails(String matchId) async {
    final local = await sportsDao.getMatchById(matchId);
    if (local != null) return local;

    for (final source in dataSources.where(
      (s) => s.isEnabled && s.supportsMatchDetails,
    )) {
      try {
        final remote = await source.fetchMatchDetails(matchId: matchId);
        if (remote != null) {
          await sportsDao.upsertMatch(remote);
          return await sportsDao.getMatchById(matchId);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Importation et persistance directe d'un jeu de données OpenFootball (CC0) dans SQLite
  Future<int> importOpenFootballDataset(String rawContent) async {
    final dataset = OpenFootballParser.parse(rawContent);
    final nowIso = DateTime.now().toUtc();

    // 1. Enregistrer le sport
    const sport = SportEntity(
      id: 'sport_football',
      name: 'Football (Soccer)',
      code: 'SOCCER',
      iconRef: 'sports_soccer',
      sourceProvider: 'openfootball',
    );
    await sportsDao.upsertSport(sport);

    // 2. Enregistrer la compétition
    final compId =
        'comp_${dataset.competitionName.replaceAll(' ', '_').toLowerCase()}';
    final competition = CompetitionEntity(
      id: compId,
      sportId: sport.id,
      name: dataset.competitionName,
      code: 'EPL',
      country: 'Angleterre',
      countryCode: 'GB',
      tier: 1,
      sourceProvider: 'openfootball',
    );
    await sportsDao.upsertCompetition(competition);

    // 3. Enregistrer la saison
    final seasonId =
        'season_${compId}_${dataset.seasonLabel.replaceAll('/', '_')}';
    final season = SeasonEntity(
      id: seasonId,
      competitionId: compId,
      yearLabel: dataset.seasonLabel,
      isCurrent: true,
    );
    await sportsDao.upsertSeason(season);

    // 4. Enregistrer les équipes
    final teams = dataset.teams
        .map(
          (tName) => TeamEntity(
            id: 'team_${tName.replaceAll(' ', '_')}',
            sportId: sport.id,
            name: tName,
            sourceProvider: 'openfootball',
          ),
        )
        .toList();
    await sportsDao.upsertTeams(teams);

    // 5. Enregistrer les matchs
    final matches = dataset.matches.map((m) {
      final matchId =
          'of_${m.homeTeam.replaceAll(' ', '_')}_${m.awayTeam.replaceAll(' ', '_')}_${m.utcKickoff.millisecondsSinceEpoch}';
      return MatchEntity(
        id: matchId,
        sportId: sport.id,
        competitionId: compId,
        competitionName: dataset.competitionName,
        seasonId: seasonId,
        homeTeamId: 'team_${m.homeTeam.replaceAll(' ', '_')}',
        homeTeamName: m.homeTeam,
        awayTeamId: 'team_${m.awayTeam.replaceAll(' ', '_')}',
        awayTeamName: m.awayTeam,
        utcKickoff: m.utcKickoff,
        status: m.status,
        matchday: m.matchday,
        roundLabel: m.roundLabel,
        isSampleData: false,
        sourceProvider: 'openfootball',
        sourceMatchId: matchId,
        lastSyncedAt: nowIso,
        result: m.homeScore != null && m.awayScore != null
            ? MatchResultEntity(
                id: 'res_$matchId',
                matchId: matchId,
                homeScore: m.homeScore,
                awayScore: m.awayScore,
                homeHalftimeScore: m.homeHalftimeScore,
                awayHalftimeScore: m.awayHalftimeScore,
              )
            : null,
      );
    }).toList();

    await sportsDao.upsertMatches(matches);

    // Mettre à jour l'état de synchronisation
    await sportsDao.updateSyncState(
      key: 'sync_openfootball_$compId',
      providerId: 'openfootball',
      recordsSynced: matches.length,
      status: 'SUCCESS',
    );

    return matches.length;
  }

  /// Récupère l'ensemble des matchs stockés localement
  Future<List<MatchEntity>> getAllMatches({
    String? sportId,
    String? competitionId,
    String? status,
  }) async {
    return sportsDao.getMatches(
      sportId: sportId,
      competitionId: competitionId,
      status: status,
    );
  }

  /// Récupère la liste des sources de données
  Future<List<Map<String, dynamic>>> getDataSources() async {
    return sportsDao.getDataSources();
  }

  /// Récupère l'historique des synchronisations
  Future<List<Map<String, dynamic>>> getAllSyncStates() async {
    return sportsDao.getAllSyncStates();
  }
}
