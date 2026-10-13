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
  final double accuracyWilsonLower; // Borne inférieure Wilson 95%
  final double accuracyWilsonUpper; // Borne supérieure Wilson 95%
  final double brierScore; // [0.0 (parfait) à 2.0]
  final double brierStandardError; // Erreur type de l'estimateur de Brier
  final double brierConfidenceIntervalLower; // Borne inf IC 95% Brier
  final double brierConfidenceIntervalUpper; // Borne sup IC 95% Brier
  final double logLoss; // Cross-entropy
  final double
  baselineUniformBrierScore; // Référence naïve uniforme (1/3, 1/3, 1/3) = 2/3
  final double baselineUniformLogLoss; // ln(3) = 1.0986
  final double brierSkillScore; // BSS: 1 - (BS_model / BS_baseline)
  final double expectedCalibrationError; // ECE
  final List<CalibrationBin> calibrationBins;

  const BacktestEvaluationMetrics({
    required this.modelName,
    required this.totalEvaluatedMatches,
    required this.correctPredictionsCount,
    required this.accuracy,
    this.accuracyWilsonLower = 0.0,
    this.accuracyWilsonUpper = 1.0,
    required this.brierScore,
    this.brierStandardError = 0.0,
    this.brierConfidenceIntervalLower = 0.0,
    this.brierConfidenceIntervalUpper = 2.0,
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
  /// Calcule l'intervalle de confiance de Wilson à 95% pour une proportion
  static (double, double) computeWilsonScoreInterval(
    int successes,
    int total, {
    double z = 1.95996, // Seuil bilatéral 95%
  }) {
    if (total == 0) return (0.0, 0.0);
    final p = successes / total;
    final z2 = z * z;
    final denominator = 1.0 + (z2 / total);
    final center = (p + (z2 / (2.0 * total))) / denominator;
    final margin =
        (z *
            math.sqrt((p * (1.0 - p) / total) + (z2 / (4.0 * total * total)))) /
        denominator;
    return (
      double.parse(math.max(0.0, center - margin).toStringAsFixed(4)),
      double.parse(math.min(1.0, center + margin).toStringAsFixed(4)),
    );
  }

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
    final individualBriers = <double>[];

    // Structure pour les bins de calibration (5 bins : 0-0.2, 0.2-0.4, 0.4-0.6, 0.6-0.8, 0.8-1.0)
    final binSampleCounts = List<int>.filled(5, 0);
    final binSumPredicted = List<double>.filled(5, 0.0);
    final binSumActual = List<double>.filled(5, 0.0);

    const eps = 1e-6;

    // 3. Boucle walk-forward causale stricte (zéro fuite temporelle, ni future ni contemporaine)
    for (int i = 0; i < finishedMatches.length; i++) {
      final targetMatch = finishedMatches[i];
      // Tout l'historique STRICTEMENT antérieur au coup d'envoi du match cible
      // Élimine formellement toute contamination par des matchs simultanés (même date et heure)
      final historyBefore = finishedMatches
          .where(
            (m) =>
                m.id != targetMatch.id &&
                m.utcKickoff.isBefore(targetMatch.utcKickoff),
          )
          .toList();

      if (historyBefore.length < minHistoryBeforeEvaluation) {
        continue;
      }

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
      individualBriers.add(brierInstance.toDouble());

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
        accuracyWilsonLower: 0.0,
        accuracyWilsonUpper: 0.0,
        brierScore: 0.0,
        brierStandardError: 0.0,
        brierConfidenceIntervalLower: 0.0,
        brierConfidenceIntervalUpper: 0.0,
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

    // Intervalles analytiques d'incertitude
    final (wilsonLower, wilsonUpper) = computeWilsonScoreInterval(
      correctPredictions,
      evaluatedMatches,
    );

    // Variance et écart-type empirique pour le Brier Score
    double brierVariance = 0.0;
    if (evaluatedMatches > 1) {
      for (final bs in individualBriers) {
        brierVariance += math.pow(bs - meanBrier, 2);
      }
      brierVariance /= (evaluatedMatches - 1);
    }
    final brierStd = math.sqrt(brierVariance);
    final brierSe = evaluatedMatches > 0
        ? brierStd / math.sqrt(evaluatedMatches)
        : 0.0;
    final brierCiLower = math.max(0.0, meanBrier - (1.95996 * brierSe));
    final brierCiUpper = math.min(2.0, meanBrier + (1.95996 * brierSe));

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
      accuracyWilsonLower: wilsonLower,
      accuracyWilsonUpper: wilsonUpper,
      brierScore: double.parse(meanBrier.toStringAsFixed(4)),
      brierStandardError: double.parse(brierSe.toStringAsFixed(4)),
      brierConfidenceIntervalLower: double.parse(
        brierCiLower.toStringAsFixed(4),
      ),
      brierConfidenceIntervalUpper: double.parse(
        brierCiUpper.toStringAsFixed(4),
      ),
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
