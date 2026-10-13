import '../../features/sports/domain/entities/match.dart';
import 'models/prediction_result.dart';
import 'models/statistical_metrics.dart';
import 'descriptive/descriptive_stats_calculator.dart';
import 'models_impl/poisson_dixon_coles_model.dart';
import 'models_impl/elo_rating_engine.dart';
import 'evaluator/backtest_evaluator.dart';

/// Façade unifiée du Moteur Statistique indépendant de BETSOCCER
class StatisticalEngine {
  final PoissonDixonColesModel poissonModel;
  final EloRatingEngine eloEngine;

  const StatisticalEngine({
    this.poissonModel = const PoissonDixonColesModel(),
    this.eloEngine = const EloRatingEngine(),
  });

  /// Estime les probabilités d'un match selon son sport et l'historique disponible
  MatchPredictionResult predictMatch({
    required MatchEntity match,
    required List<MatchEntity> allMatches,
    DateTime? cutoffDate,
  }) {
    final sportId = match.sportId.toLowerCase();
    final isFootball =
        sportId.contains('football') || sportId.contains('soccer');

    // 1. Pour le football, utiliser le modèle bivarié de Poisson Dixon-Coles
    if (isFootball) {
      final poissonResult = poissonModel.predictMatch(
        match: match,
        historicalMatches: allMatches,
        cutoffDate: cutoffDate,
      );

      // Si le modèle Poisson a pu calculer une estimation (confirmée ou shrinkage)
      if (poissonResult.status == EstimationStatus.confirmed ||
          poissonResult.status == EstimationStatus.shrinkageEstimation) {
        return poissonResult;
      }

      // En cas de données insuffisantes pour Poisson, tenter Elo avec shrinkage
      final eloResult = eloEngine.predictMatch(
        match: match,
        historicalMatches: allMatches,
        cutoffDate: cutoffDate,
      );

      if (eloResult.status != EstimationStatus.insufficientData) {
        return eloResult;
      }

      // Si les deux modèles refusent, renvoyer le refus formel avec métadonnées
      return poissonResult;
    }

    // 2. Pour les autres sports (Tennis, Basketball, Volleyball, Handball)
    // Utiliser le moteur Elo adapté sans présumer des règles du football
    return eloEngine.predictMatch(
      match: match,
      historicalMatches: allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Analyse complète de la forme et des performances d'une équipe
  TeamRecentForm getTeamRecentForm({
    required String teamId,
    required String teamName,
    required List<MatchEntity> allMatches,
    int limit = 5,
    DateTime? cutoffDate,
  }) {
    return DescriptiveStatsCalculator.computeRecentForm(
      teamId: teamId,
      teamName: teamName,
      matches: allMatches,
      limit: limit,
      cutoffDate: cutoffDate,
    );
  }

  /// Statistiques comparatives Domicile vs Extérieur
  VenueSplitStats getVenueSplitStats({
    required String teamId,
    required List<MatchEntity> allMatches,
    DateTime? cutoffDate,
  }) {
    return DescriptiveStatsCalculator.computeVenueSplits(
      teamId: teamId,
      matches: allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Historique des confrontations directes
  HeadToHeadSummary getHeadToHeadSummary({
    required String teamAId,
    required String teamAName,
    required String teamBId,
    required String teamBName,
    required List<MatchEntity> allMatches,
    DateTime? cutoffDate,
  }) {
    return DescriptiveStatsCalculator.computeHeadToHead(
      teamAId: teamAId,
      teamAName: teamAName,
      teamBId: teamBId,
      teamBName: teamBName,
      matches: allMatches,
      cutoffDate: cutoffDate,
    );
  }

  /// Lance le benchmark de backtesting scientifique chronologique
  Map<String, BacktestEvaluationMetrics> runBacktest(
    List<MatchEntity> matches,
  ) {
    return BacktestEvaluator.runFullBenchmark(matches);
  }
}
