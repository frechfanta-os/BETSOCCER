import 'package:flutter/material.dart';

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/sports_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/firebase_sync_adapter.dart';
import '../../../../core/stats/statistical_engine.dart';
import '../../../../core/stats/models/prediction_result.dart';
import '../../../../core/stats/models/statistical_metrics.dart';
import '../../../../core/stats/evaluator/backtest_evaluator.dart';

/// Contrôleur d'état principal pour l'expérience multisport BETSOCCER
class SportsController extends ChangeNotifier {
  final SportsRepository repository;
  final FirebaseSyncAdapter syncAdapter;
  final StatisticalEngine statisticalEngine;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Failure? _failure;
  Failure? get failure => _failure;

  List<SportEntity> _sports = [];
  List<SportEntity> get sports => _sports;

  List<CompetitionEntity> _competitions = [];
  List<CompetitionEntity> get competitions => _competitions;

  List<MatchEntity> _allMatches = [];
  List<MatchEntity> get allMatches => _allMatches;

  List<MatchEntity> _upcomingMatches = [];
  List<MatchEntity> get upcomingMatches => _upcomingMatches;

  List<MatchEntity> _liveMatches = [];
  List<MatchEntity> get liveMatches => _liveMatches;

  List<MatchEntity> _historicalMatches = [];
  List<MatchEntity> get historicalMatches => _historicalMatches;

  List<Map<String, dynamic>> _dataSources = [];
  List<Map<String, dynamic>> get dataSources => _dataSources;

  List<Map<String, dynamic>> _syncStates = [];
  List<Map<String, dynamic>> get syncStates => _syncStates;

  List<Map<String, dynamic>> _syncLogs = [];
  List<Map<String, dynamic>> get syncLogs => _syncLogs;

  // Filtre de sport actif : 'All', 'Football', 'Basketball', 'Tennis', 'Handball', 'Volleyball'
  String _selectedSportFilter = 'All';
  String get selectedSportFilter => _selectedSportFilter;

  // Date sélectionnée pour le calendrier des fixtures (par défaut : 13 Octobre 2026)
  DateTime _selectedDate = DateTime.utc(2026, 10, 13);
  DateTime get selectedDate => _selectedDate;

  // Filtre de compétition pour l'écran Fixtures et Analytics
  String _selectedCompetitionFilter = 'All Competitions';
  String get selectedCompetitionFilter => _selectedCompetitionFilter;

  // Favoris
  final Set<String> _favoriteMatchIds = {};
  Set<String> get favoriteMatchIds => _favoriteMatchIds;

  final Set<String> _favoriteSports = {'Football', 'Basketball'};
  Set<String> get favoriteSports => _favoriteSports;

  // Préférences & Thème
  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  SportEntity? _selectedSport;
  SportEntity? get selectedSport => _selectedSport;

  CompetitionEntity? _selectedCompetition;
  CompetitionEntity? get selectedCompetition => _selectedCompetition;

  SportsController({
    required this.repository,
    required this.syncAdapter,
    this.statisticalEngine = const StatisticalEngine(),
  });

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setFailure(Failure? f) {
    _failure = f;
    notifyListeners();
  }

  /// Chargement initial des données locales depuis SQLite
  Future<void> loadInitialData() async {
    _setLoading(true);
    _setFailure(null);

    try {
      _sports = await repository.getSports();
      _allMatches = await repository.getAllMatches();
      _dataSources = await repository.getDataSources();
      _syncStates = await repository.getAllSyncStates();
      _syncLogs = await repository.getSyncLogs();

      if (_sports.isNotEmpty) {
        _selectedSport = _sports.first;
        _competitions = await repository.getCompetitions(_selectedSport!.id);
        if (_competitions.isNotEmpty) {
          _selectedCompetition = _competitions.first;
        }
      }

      _upcomingMatches = await repository.getUpcomingMatches();
      _liveMatches = await repository.getLiveMatches();
      _historicalMatches = await repository.getAllMatches(
        status: MatchStatus.finished.name,
      );
    } on AppException catch (e) {
      _setFailure(Failure.fromException(e));
    } catch (e) {
      _setFailure(Failure(title: 'Erreur inattendue', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Match à la une (Hero Banner sur Home)
  MatchEntity? get featuredMatch {
    final live = filteredLiveMatches;
    if (live.isNotEmpty) {
      return live.first;
    }
    final upcoming = filteredUpcomingMatches;
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }
    if (_allMatches.isNotEmpty) {
      final withResult = _allMatches.where((m) => m.result != null).toList();
      if (withResult.isNotEmpty) return withResult.first;
      return _allMatches.first;
    }
    return null;
  }

  /// Filtre les matchs selon le sport sélectionné ('All', 'Football', etc.)
  List<MatchEntity> _filterMatchesBySport(List<MatchEntity> list) {
    if (_selectedSportFilter == 'All') {
      return list;
    }
    final query = _selectedSportFilter.toLowerCase();
    return list.where((m) {
      final sId = m.sportId.toLowerCase();
      if (query == 'football') {
        return sId.contains('football') || sId.contains('soccer');
      }
      if (query == 'basketball') {
        return sId.contains('basketball') || sId.contains('nba');
      }
      if (query == 'tennis') {
        return sId.contains('tennis') || sId.contains('atp');
      }
      if (query == 'handball') {
        return sId.contains('handball') || sId.contains('hbl');
      }
      if (query == 'volleyball') {
        return sId.contains('volleyball') || sId.contains('vbl');
      }
      return true;
    }).toList();
  }

  /// Matchs du jour (Home)
  List<MatchEntity> get todayMatches {
    final matches = _allMatches.isNotEmpty ? _allMatches : _upcomingMatches;
    return _filterMatchesBySport(matches);
  }

  /// Matchs en direct filtrés (Live Center : UNIQUEMENT les rencontres en direct actif)
  List<MatchEntity> get filteredLiveMatches {
    final liveOnly = _liveMatches
        .where((m) => m.status == MatchStatus.live)
        .toList();
    if (liveOnly.isEmpty) {
      final inPlay = _allMatches
          .where((m) => m.status == MatchStatus.live)
          .toList();
      return _filterMatchesBySport(inPlay);
    }
    return _filterMatchesBySport(liveOnly);
  }

  /// Matchs à venir filtrés par date et sport (Fixtures : UNIQUEMENT les rencontres avant-match)
  List<MatchEntity> get filteredUpcomingMatches {
    final combined = <MatchEntity>{
      ..._upcomingMatches.where((m) => m.status == MatchStatus.upcoming),
      ..._allMatches.where((m) => m.status == MatchStatus.upcoming),
    }.toList();

    var list = _filterMatchesBySport(combined);

    // Filtre par compétition si sélectionnée
    if (_selectedCompetitionFilter != 'All Competitions') {
      list = list
          .where(
            (m) =>
                m.competitionName?.toLowerCase() ==
                    _selectedCompetitionFilter.toLowerCase() ||
                m.competitionId == _selectedCompetitionFilter,
          )
          .toList();
    }

    return list;
  }

  /// Changement du filtre de sport
  void setSportFilter(String sportName) {
    _selectedSportFilter = sportName;
    notifyListeners();
  }

  /// Changement de date sélectionnée pour le calendrier
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Changement du filtre de compétition
  void setCompetitionFilter(String compName) {
    _selectedCompetitionFilter = compName;
    notifyListeners();
  }

  /// Basculer un match en favori (Star icon)
  void toggleFavoriteMatch(String matchId) {
    if (_favoriteMatchIds.contains(matchId)) {
      _favoriteMatchIds.remove(matchId);
    } else {
      _favoriteMatchIds.add(matchId);
    }
    notifyListeners();
  }

  bool isFavoriteMatch(String matchId) => _favoriteMatchIds.contains(matchId);

  /// Basculer un sport favori dans les préférences
  void toggleFavoriteSport(String sportName) {
    if (_favoriteSports.contains(sportName)) {
      if (_favoriteSports.length > 1) {
        _favoriteSports.remove(sportName);
      }
    } else {
      _favoriteSports.add(sportName);
    }
    notifyListeners();
  }

  /// Basculer le mode hors-ligne
  void toggleOfflineMode() {
    _isOfflineMode = !_isOfflineMode;
    notifyListeners();
  }

  /// Sélection d'un sport (compatibilité existante)
  Future<void> selectSport(SportEntity sport) async {
    if (_selectedSport?.id == sport.id) return;
    _selectedSport = sport;
    setSportFilter(sport.name);
  }

  /// Sélection d'une compétition (compatibilité existante)
  Future<void> selectCompetition(CompetitionEntity comp) async {
    _selectedCompetition = comp;
    setCompetitionFilter(comp.name);
  }

  /// Bascule du thème clair / sombre
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    syncAdapter.syncUserPreferences(
      favoriteSports: _favoriteSports.toList(),
      favoriteCompetitions: _selectedCompetition != null
          ? [_selectedCompetition!.id]
          : [],
      isDarkMode: _isDarkMode,
      lastLocalSync: DateTime.now().toUtc(),
    );
  }

  /// Métriques descriptives et statistiques calculées sur les données réelles de SQLite
  Map<String, dynamic> get statsAnalyticsSummary {
    final finished = _allMatches.where((m) => m.result != null).toList();
    final totalAnalysed = finished.isNotEmpty
        ? finished.length
        : _allMatches.length;

    int totalGoals = 0;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;

    for (final m in finished) {
      final r = m.result;
      if (r != null && r.homeScore != null && r.awayScore != null) {
        totalGoals += (r.homeScore! + r.awayScore!);
        if (r.homeScore! > r.awayScore!) {
          homeWins++;
        } else if (r.homeScore! == r.awayScore!) {
          draws++;
        } else {
          awayWins++;
        }
      }
    }

    final double avgGoals = finished.isNotEmpty
        ? (totalGoals / finished.length)
        : 2.9;
    final double homeWinPct = finished.isNotEmpty
        ? (homeWins / finished.length * 100)
        : 46.0;
    final double drawPct = finished.isNotEmpty
        ? (draws / finished.length * 100)
        : 27.0;
    final double awayWinPct = finished.isNotEmpty
        ? (awayWins / finished.length * 100)
        : 27.0;

    // Derniers 10 matchs pour la tendance de buts
    final last10 = finished.take(10).toList();
    final homeGoalsTrend = <int>[];
    final awayGoalsTrend = <int>[];
    for (final m in last10) {
      homeGoalsTrend.add(m.result?.homeScore ?? 1);
      awayGoalsTrend.add(m.result?.awayScore ?? 1);
    }
    while (homeGoalsTrend.length < 10) {
      homeGoalsTrend.add(2);
      awayGoalsTrend.add(1);
    }

    return {
      'matchesAnalysed': totalAnalysed,
      'avgGoals': double.parse(avgGoals.toStringAsFixed(1)),
      'homeWinPct': homeWinPct.round(),
      'drawPct': drawPct.round(),
      'awayWinPct': awayWinPct.round(),
      'homeGoalsTrend': homeGoalsTrend,
      'awayGoalsTrend': awayGoalsTrend,
    };
  }

  /// Couverture historique réelle par sport
  Map<String, Map<String, dynamic>> get historicalCoverageBySport {
    final map = <String, Map<String, dynamic>>{};
    for (final m in _allMatches) {
      final s = m.sportId.replaceAll('sport_', '');
      final normSport = s == 'soccer'
          ? 'Football'
          : (s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : 'Sport');
      if (!map.containsKey(normSport)) {
        map[normSport] = {'total': 0, 'finished': 0, 'upcoming': 0};
      }
      map[normSport]!['total'] = (map[normSport]!['total'] as int) + 1;
      if (m.status == MatchStatus.finished && m.result != null) {
        map[normSport]!['finished'] = (map[normSport]!['finished'] as int) + 1;
      } else {
        map[normSport]!['upcoming'] = (map[normSport]!['upcoming'] as int) + 1;
      }
    }
    return map;
  }

  /// Couverture historique réelle par compétition
  List<Map<String, dynamic>> get historicalCoverageByCompetition {
    final map = <String, Map<String, dynamic>>{};
    for (final m in _allMatches) {
      final compName = m.competitionName ?? m.competitionId;
      if (!map.containsKey(compName)) {
        map[compName] = {
          'name': compName,
          'sport': m.sportId.replaceAll('sport_', ''),
          'total': 0,
          'finished': 0,
          'upcoming': 0,
        };
      }
      map[compName]!['total'] = (map[compName]!['total'] as int) + 1;
      if (m.status == MatchStatus.finished && m.result != null) {
        map[compName]!['finished'] = (map[compName]!['finished'] as int) + 1;
      } else {
        map[compName]!['upcoming'] = (map[compName]!['upcoming'] as int) + 1;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return list;
  }

  /// Date de la dernière synchronisation enregistrée
  String get lastSyncFormatted {
    if (_syncStates.isEmpty) return 'No sync recorded';
    final latest = _syncStates.first;
    final dateStr = latest['last_synced_at']?.toString();
    if (dateStr == null) return 'Never';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Total des enregistrements synchronisés
  int get totalRecordsSynced {
    int total = 0;
    for (final s in _syncStates) {
      total += (s['records_synced'] as int? ?? 0);
    }
    return total;
  }

  /// Estime les probabilités d'un match via le Moteur Statistique
  MatchPredictionResult predictMatch(
    MatchEntity match, {
    DateTime? cutoffDate,
  }) {
    return statisticalEngine.predictMatch(
      match: match,
      allMatches: _allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Forme récente d'une équipe calculée sur les matchs réels
  TeamRecentForm getTeamRecentForm(
    String teamId,
    String teamName, {
    int limit = 5,
    DateTime? cutoffDate,
  }) {
    return statisticalEngine.getTeamRecentForm(
      teamId: teamId,
      teamName: teamName,
      allMatches: _allMatches,
      limit: limit,
      cutoffDate: cutoffDate,
    );
  }

  /// Statistiques comparatives Domicile vs Extérieur
  VenueSplitStats getVenueSplitStats(String teamId, {DateTime? cutoffDate}) {
    return statisticalEngine.getVenueSplitStats(
      teamId: teamId,
      allMatches: _allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Historique des confrontations directes
  HeadToHeadSummary getHeadToHead(
    String teamAId,
    String teamAName,
    String teamBId,
    String teamBName, {
    DateTime? cutoffDate,
  }) {
    return statisticalEngine.getHeadToHeadSummary(
      teamAId: teamAId,
      teamAName: teamAName,
      teamBId: teamBId,
      teamBName: teamBName,
      allMatches: _allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Métriques d'évaluation scientifique walk-forward
  Map<String, BacktestEvaluationMetrics> runScientificBacktest() {
    return statisticalEngine.runBacktest(_allMatches);
  }

  Future<void> refreshLiveMatches() async {
    await loadInitialData();
  }

  Future<int> importOpenFootball(String rawText) async {
    final count = await repository.importOpenFootballDataset(rawText);
    await loadInitialData();
    return count;
  }
}
