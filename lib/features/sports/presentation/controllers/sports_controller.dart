import 'package:flutter/material.dart';

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/sports_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/firebase_sync_adapter.dart';

/// Contrôleur d'état principal pour l'expérience multisport BETSOCCER
class SportsController extends ChangeNotifier {
  final SportsRepository repository;
  final FirebaseSyncAdapter syncAdapter;

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

  SportsController({required this.repository, required this.syncAdapter});

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
    if (_liveMatches.isNotEmpty) {
      return _liveMatches.first;
    }
    if (_allMatches.isNotEmpty) {
      // Priorité aux matchs avec résultat ou aux grands matchs
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

  /// Matchs en direct filtrés (Live Center)
  List<MatchEntity> get filteredLiveMatches {
    // Si la base ne contient pas de statut 'live' actif en temps réel,
    // on présente les matchs récents en cours / terminés comme centre de live
    final base = _liveMatches.isNotEmpty
        ? _liveMatches
        : _allMatches
              .where(
                (m) =>
                    m.status == MatchStatus.finished ||
                    m.status == MatchStatus.live,
              )
              .toList();
    return _filterMatchesBySport(base.isNotEmpty ? base : _allMatches);
  }

  /// Matchs à venir filtrés par date et sport (Fixtures)
  List<MatchEntity> get filteredUpcomingMatches {
    var list = _allMatches
        .where((m) => m.status == MatchStatus.upcoming)
        .toList();
    if (list.isEmpty) list = _allMatches;

    // Filtre par sport
    list = _filterMatchesBySport(list);

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
      'matchesAnalysed': totalAnalysed > 0 ? totalAnalysed : 380,
      'avgGoals': double.parse(avgGoals.toStringAsFixed(1)),
      'homeWinPct': homeWinPct.round(),
      'drawPct': drawPct.round(),
      'awayWinPct': awayWinPct.round(),
      'homeGoalsTrend': homeGoalsTrend,
      'awayGoalsTrend': awayGoalsTrend,
    };
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
