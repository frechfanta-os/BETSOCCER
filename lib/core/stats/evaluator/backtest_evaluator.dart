import 'dart:math' as math;

import '../../../features/sports/domain/entities/match.dart';
import '../models/prediction_result.dart';
import '../models_impl/poisson_dixon_coles_model.dart';
import '../models_impl/elo_rating_engine.dart';

/// Résultats d'évaluation scientifique de backtesting chronologique
class BacktestEvaluationMetrics {
  final String modelName;
  final int totalEvaluatedMatches;
  final int correctPredictionsCount;
  final double accuracy; // Hit rate %
  final double brierScore; // [0.0 (parfait) à 2.0]
  final double logLoss; // Cross-entropy
  final double
  baselineUniformBrierScore; // Référence naïve uniforme (1/3, 1/3, 1/3)
  final double baselineUniformLogLoss;
  final double brierSkillScore; // BSS: 1 - (BS_model / BS_baseline)
  final double expectedCalibrationError; // ECE
  final List<CalibrationBin> calibrationBins;

  const BacktestEvaluationMetrics({
    required this.modelName,
    required this.totalEvaluatedMatches,
    required this.correctPredictionsCount,
    required this.accuracy,
    required this.brierScore,
    required this.logLoss,
    required this.baselineUniformBrierScore,
    required this.baselineUniformLogLoss,
    required this.brierSkillScore,
    required this.expectedCalibrationError,
    required this.calibrationBins,
  });
}

class CalibrationBin {
  final double lowerBound;
  final double upperBound;
  final int sampleCount;
  final double meanPredictedProb;
  final double empiricalAccuracy;

  const CalibrationBin({
    required this.lowerBound,
    required this.upperBound,
    required this.sampleCount,
    required this.meanPredictedProb,
    required this.empiricalAccuracy,
  });
}

/// Évaluateur de backtesting chronologique sans fuite temporelle
class BacktestEvaluator {
  /// Exécute une validation walk-forward stricte sur une série chronologique de matchs
  static BacktestEvaluationMetrics evaluateModel({
    required String modelName,
    required List<MatchEntity> matches,
    required MatchPredictionResult Function(
      MatchEntity target,
      List<MatchEntity> historyBeforeTarget,
    )
    predictFn,
    int minHistoryBeforeEvaluation = 3,
  }) {
    // 1. Filtrer les matchs terminés avec scores valides
    final finishedMatches = matches.where((m) {
      if (m.status != MatchStatus.finished || m.result == null) {
        return false;
      }
      return m.result!.homeScore != null && m.result!.awayScore != null;
    }).toList();

    // 2. Trier strictement par ordre chronologique
    finishedMatches.sort((a, b) => a.utcKickoff.compareTo(b.utcKickoff));

    if (finishedMatches.length <= minHistoryBeforeEvaluation) {
      return BacktestEvaluationMetrics(
        modelName: modelName,
        totalEvaluatedMatches: 0,
        correctPredictionsCount: 0,
        accuracy: 0.0,
        brierScore: 0.0,
        logLoss: 0.0,
        baselineUniformBrierScore: 0.0,
        baselineUniformLogLoss: 0.0,
        brierSkillScore: 0.0,
        expectedCalibrationError: 0.0,
        calibrationBins: const [],
      );
    }

    double totalModelBrier = 0.0;
    double totalModelLogLoss = 0.0;
    double totalUniformBrier = 0.0;
    double totalUniformLogLoss = 0.0;
    int correctPredictions = 0;
    int evaluatedMatches = 0;

    // Structure pour les bins de calibration (5 bins : 0-0.2, 0.2-0.4, 0.4-0.6, 0.6-0.8, 0.8-1.0)
    final binSampleCounts = List<int>.filled(5, 0);
    final binSumPredicted = List<double>.filled(5, 0.0);
    final binSumActual = List<double>.filled(5, 0.0);

    const eps = 1e-6;

    // 3. Boucle walk-forward (aucun regard vers le futur)
    for (int i = minHistoryBeforeEvaluation; i < finishedMatches.length; i++) {
      final targetMatch = finishedMatches[i];
      // Tout l'historique STRICTEMENT antérieur au match cible
      final historyBefore = finishedMatches.sublist(0, i);

      final prediction = predictFn(targetMatch, historyBefore);
      if (!prediction.isReliable && prediction.homeWinProb == 0.0) {
        continue;
      }

      final hs = targetMatch.result!.homeScore!;
      final as_ = targetMatch.result!.awayScore!;

      // Vecteur résultat réel one-hot : [HomeWin, Draw, AwayWin]
      double y1 = 0.0, yX = 0.0, y2 = 0.0;
      if (hs > as_) {
        y1 = 1.0;
      } else if (hs == as_) {
        yX = 1.0;
      } else {
        y2 = 1.0;
      }

      final p1 = prediction.homeWinProb;
      final pX = prediction.drawProb;
      final p2 = prediction.awayWinProb;

      // Vérifier le succès de la prédiction (argmax)
      if (p1 >= pX && p1 >= p2 && y1 == 1.0) {
        correctPredictions++;
      } else if (pX >= p1 && pX >= p2 && yX == 1.0) {
        correctPredictions++;
      } else if (p2 >= p1 && p2 >= pX && y2 == 1.0) {
        correctPredictions++;
      }

      // Calcul Brier Score
      final brierInstance =
          math.pow(p1 - y1, 2) + math.pow(pX - yX, 2) + math.pow(p2 - y2, 2);
      totalModelBrier += brierInstance;

      // Calcul Log-Loss
      final logLossInstance =
          -((y1 * math.log(math.max(eps, p1))) +
              (yX * math.log(math.max(eps, pX))) +
              (y2 * math.log(math.max(eps, p2))));
      totalModelLogLoss += logLossInstance;

      // Référence Naïve Uniforme (1/3, 1/3, 1/3)
      final uniformBrier =
          math.pow((1.0 / 3.0) - y1, 2) +
          math.pow((1.0 / 3.0) - yX, 2) +
          math.pow((1.0 / 3.0) - y2, 2);
      totalUniformBrier += uniformBrier;
      totalUniformLogLoss +=
          -((y1 * math.log(1.0 / 3.0)) +
              (yX * math.log(1.0 / 3.0)) +
              (y2 * math.log(1.0 / 3.0)));

      // Calibration pour chaque issue (p1, pX, p2)
      for (final pair in [
        MapEntry(p1, y1),
        MapEntry(pX, yX),
        MapEntry(p2, y2),
      ]) {
        final p = pair.key;
        final y = pair.value;
        int binIdx = (p * 5).floor();
        if (binIdx >= 5) binIdx = 4;
        if (binIdx < 0) binIdx = 0;
        binSampleCounts[binIdx]++;
        binSumPredicted[binIdx] += p;
        binSumActual[binIdx] += y;
      }

      evaluatedMatches++;
    }

    if (evaluatedMatches == 0) {
      return BacktestEvaluationMetrics(
        modelName: modelName,
        totalEvaluatedMatches: 0,
        correctPredictionsCount: 0,
        accuracy: 0.0,
        brierScore: 0.0,
        logLoss: 0.0,
        baselineUniformBrierScore: 0.0,
        baselineUniformLogLoss: 0.0,
        brierSkillScore: 0.0,
        expectedCalibrationError: 0.0,
        calibrationBins: const [],
      );
    }

    final meanBrier = totalModelBrier / evaluatedMatches;
    final meanLogLoss = totalModelLogLoss / evaluatedMatches;
    final meanUniformBrier = totalUniformBrier / evaluatedMatches;
    final meanUniformLogLoss = totalUniformLogLoss / evaluatedMatches;
    final accuracy = correctPredictions / evaluatedMatches;

    // Brier Skill Score : BSS = 1 - (BS_model / BS_ref)
    final bss = meanUniformBrier > 0
        ? 1.0 - (meanBrier / meanUniformBrier)
        : 0.0;

    // Calcul de l'Expected Calibration Error (ECE)
    final totalCalibrationSamples = binSampleCounts.reduce((a, b) => a + b);
    double totalEce = 0.0;
    final bins = <CalibrationBin>[];

    for (int b = 0; b < 5; b++) {
      final count = binSampleCounts[b];
      final lower = b * 0.2;
      final upper = (b + 1) * 0.2;
      if (count > 0) {
        final meanPred = binSumPredicted[b] / count;
        final empAcc = binSumActual[b] / count;
        final gap = (meanPred - empAcc).abs();
        totalEce += (count / totalCalibrationSamples) * gap;
        bins.add(
          CalibrationBin(
            lowerBound: lower,
            upperBound: upper,
            sampleCount: count,
            meanPredictedProb: double.parse(meanPred.toStringAsFixed(4)),
            empiricalAccuracy: double.parse(empAcc.toStringAsFixed(4)),
          ),
        );
      } else {
        bins.add(
          CalibrationBin(
            lowerBound: lower,
            upperBound: upper,
            sampleCount: 0,
            meanPredictedProb: (lower + upper) / 2.0,
            empiricalAccuracy: 0.0,
          ),
        );
      }
    }

    return BacktestEvaluationMetrics(
      modelName: modelName,
      totalEvaluatedMatches: evaluatedMatches,
      correctPredictionsCount: correctPredictions,
      accuracy: double.parse(accuracy.toStringAsFixed(4)),
      brierScore: double.parse(meanBrier.toStringAsFixed(4)),
      logLoss: double.parse(meanLogLoss.toStringAsFixed(4)),
      baselineUniformBrierScore: double.parse(
        meanUniformBrier.toStringAsFixed(4),
      ),
      baselineUniformLogLoss: double.parse(
        meanUniformLogLoss.toStringAsFixed(4),
      ),
      brierSkillScore: double.parse(bss.toStringAsFixed(4)),
      expectedCalibrationError: double.parse(totalEce.toStringAsFixed(4)),
      calibrationBins: bins,
    );
  }

  /// Exécute le benchmark comparatif automatique Poisson vs Elo
  static Map<String, BacktestEvaluationMetrics> runFullBenchmark(
    List<MatchEntity> matches,
  ) {
    const poisson = PoissonDixonColesModel();
    const elo = EloRatingEngine();

    final poissonMetrics = evaluateModel(
      modelName: 'Poisson Dixon-Coles',
      matches: matches,
      predictFn: (target, history) => poisson.predictMatch(
        match: target,
        historicalMatches: history,
        cutoffDate: target.utcKickoff,
      ),
    );

    final eloMetrics = evaluateModel(
      modelName: 'Multi-Sport Dynamic Elo',
      matches: matches,
      predictFn: (target, history) => elo.predictMatch(
        match: target,
        historicalMatches: history,
        cutoffDate: target.utcKickoff,
      ),
    );

    return {'poisson': poissonMetrics, 'elo': eloMetrics};
  }
}
