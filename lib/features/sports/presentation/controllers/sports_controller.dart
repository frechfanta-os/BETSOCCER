import 'package:flutter/material.dart';

import '../../domain/entities/sport.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/sports_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/firebase_sync_adapter.dart';

/// Contrôleur d'état principal pour le domaine sportif et l'interface utilisateur
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

  List<MatchEntity> _upcomingMatches = [];
  List<MatchEntity> get upcomingMatches => _upcomingMatches;

  List<MatchEntity> _liveMatches = [];
  List<MatchEntity> get liveMatches => _liveMatches;

  List<MatchEntity> _historicalMatches = [];
  List<MatchEntity> get historicalMatches => _historicalMatches;

  SportEntity? _selectedSport;
  SportEntity? get selectedSport => _selectedSport;

  CompetitionEntity? _selectedCompetition;
  CompetitionEntity? get selectedCompetition => _selectedCompetition;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  SportsController({required this.repository, required this.syncAdapter});

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setFailure(Failure? f) {
    _failure = f;
    notifyListeners();
  }

  /// Chargement initial des données locales
  Future<void> loadInitialData() async {
    _setLoading(true);
    _setFailure(null);

    try {
      _sports = await repository.getSports();
      if (_sports.isNotEmpty) {
        _selectedSport = _sports.first;
        _competitions = await repository.getCompetitions(_selectedSport!.id);
        if (_competitions.isNotEmpty) {
          _selectedCompetition = _competitions.first;
          _upcomingMatches = await repository.getUpcomingMatches(
            competitionId: _selectedCompetition!.id,
          );
          _historicalMatches = await repository.getHistoricalMatches(
            competitionId: _selectedCompetition!.id,
            season: '2023/24',
          );
        }
      }
      _liveMatches = await repository.getLiveMatches();
    } on AppException catch (e) {
      _setFailure(Failure.fromException(e));
    } catch (e) {
      _setFailure(Failure(title: 'Erreur inattendue', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Sélection d'un sport
  Future<void> selectSport(SportEntity sport) async {
    if (_selectedSport?.id == sport.id) return;
    _selectedSport = sport;
    _setLoading(true);

    try {
      _competitions = await repository.getCompetitions(sport.id);
      if (_competitions.isNotEmpty) {
        await selectCompetition(_competitions.first);
      } else {
        _selectedCompetition = null;
        _upcomingMatches = [];
        _historicalMatches = [];
      }
    } catch (e) {
      _setFailure(Failure(title: 'Erreur', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Sélection d'une compétition
  Future<void> selectCompetition(CompetitionEntity comp) async {
    _selectedCompetition = comp;
    _setLoading(true);

    try {
      _upcomingMatches = await repository.getUpcomingMatches(
        competitionId: comp.id,
      );
      _historicalMatches = await repository.getHistoricalMatches(
        competitionId: comp.id,
        season: '',
      );
    } catch (e) {
      _setFailure(Failure(title: 'Erreur', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchissement des matchs en direct
  Future<void> refreshLiveMatches() async {
    try {
      _liveMatches = await repository.getLiveMatches(forceRefresh: true);
      notifyListeners();
    } catch (_) {}
  }

  /// Importation manuelle de données historiques OpenFootball
  Future<int> importOpenFootball(String rawText) async {
    _setLoading(true);
    try {
      final count = await repository.importOpenFootballDataset(rawText);
      await loadInitialData();
      return count;
    } catch (e) {
      _setFailure(
        Failure(title: 'Erreur d\'importation', message: e.toString()),
      );
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  /// Bascule du thème clair / sombre avec synchronisation Firestore facultative
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Synchronisation vers Firestore en arrière-plan sans blocage
    syncAdapter.syncUserPreferences(
      favoriteSports: _selectedSport != null ? [_selectedSport!.id] : [],
      favoriteCompetitions: _selectedCompetition != null
          ? [_selectedCompetition!.id]
          : [],
      isDarkMode: _isDarkMode,
      lastLocalSync: DateTime.now().toUtc(),
    );
  }
}
