import 'dart:math' as math;

import '../../../features/sports/domain/entities/match.dart';
import '../models/prediction_result.dart';

/// Modèle bivarié de Poisson avec ajustement de Dixon-Coles pour le football
class PoissonDixonColesModel {
  // Paramètre d'ajustement Dixon-Coles pour corrélation des scores bas (0-0, 1-0, 0-1, 1-1)
  final double rho;
  // Facteur de shrinkage pseudo-counts pour les petits échantillons
  final double shrinkageC;

  const PoissonDixonColesModel({
    this.rho = -0.06, // Valeur empirique standard pour les ligues européennes
    this.shrinkageC = 5.0, // Constante de régularisation bayésienne
  });

  /// Précalcule le logarithme des factorielles jusqu'à 15
  static final List<double> _logFactorials = _initLogFactorials();

  static List<double> _initLogFactorials() {
    final list = List<double>.filled(16, 0.0);
    double accum = 0.0;
    for (int i = 1; i <= 15; i++) {
      accum += math.log(i);
      list[i] = accum;
    }
    return list;
  }

  /// Probabilité Poisson calculée en espace logarithmique pour la stabilité numérique
  double _poissonPmf(int k, double lambda) {
    if (lambda <= 0.0) return k == 0 ? 1.0 : 0.0;
    if (k > 15) return 0.0;
    final logP = (k * math.log(lambda)) - lambda - _logFactorials[k];
    return math.exp(logP);
  }

  /// Facteur de correction tau de Dixon-Coles
  double _dixonColesTau(int x, int y, double lambda, double mu) {
    if (x == 0 && y == 0) {
      return 1.0 - (lambda * mu * rho);
    } else if (x == 0 && y == 1) {
      return 1.0 + (lambda * rho);
    } else if (x == 1 && y == 0) {
      return 1.0 + (mu * rho);
    } else if (x == 1 && y == 1) {
      return 1.0 - rho;
    }
    return 1.0;
  }

  /// Estime les probabilités d'un match de football
  MatchPredictionResult predictMatch({
    required MatchEntity match,
    required List<MatchEntity> historicalMatches,
    DateTime? cutoffDate,
  }) {
    // 1. Vérification du sport : FOOTBALL UNIQUEMENT
    final sportId = match.sportId.toLowerCase();
    final isFootball =
        sportId.contains('football') || sportId.contains('soccer');
    if (!isFootball) {
      return MatchPredictionResult.unsupportedSport(
        matchId: match.id,
        homeTeamName: match.homeTeamName,
        awayTeamName: match.awayTeamName,
        sportId: match.sportId,
        reason: 'Le modèle Poisson Dixon-Coles est strictement conçu pour le football à score bas et ne peut pas être transposé à ce sport.',
      );
    }

    // 2. Filtrer l'historique valide (antérieur à la date de coupure pour éviter tout data leakage)
    final validHistory = historicalMatches.where((m) {
      if (m.status != MatchStatus.finished || m.result == null) {
        return false;
      }
      if (m.result!.homeScore == null || m.result!.awayScore == null) {
        return false;
      }
      if (cutoffDate != null && m.utcKickoff.isAfter(cutoffDate)) {
        return false;
      }
      return true;
    }).toList();

    // 3. Calculer les statistiques globales de la compétition / ligue
    int totalHomeGoals = 0;
    int totalAwayGoals = 0;
    int totalCompMatches = 0;

    for (final m in validHistory) {
      totalHomeGoals += m.result!.homeScore!;
      totalAwayGoals += m.result!.awayScore!;
      totalCompMatches++;
    }

    if (totalCompMatches == 0) {
      return MatchPredictionResult.insufficientData(
        matchId: match.id,
        homeTeamName: match.homeTeamName,
        awayTeamName: match.awayTeamName,
        sportId: match.sportId,
        totalMatchesAnalyzed: 0,
        homeTeamCount: 0,
        awayTeamCount: 0,
      );
    }

    final compAvgHomeGoals = totalHomeGoals / totalCompMatches;
    final compAvgAwayGoals = totalAwayGoals / totalCompMatches;
    // Avantage domicile empirique (ratio buts marqués domicile vs extérieur)
    final homeAdvantage = compAvgAwayGoals > 0
        ? math.max(1.0, math.min(2.0, compAvgHomeGoals / compAvgAwayGoals))
        : 1.25;

    // 4. Statistiques des équipes
    int homeMatchesCount = 0;
    int homeGoalsScored = 0;
    int homeGoalsConceded = 0;

    int awayMatchesCount = 0;
    int awayGoalsScored = 0;
    int awayGoalsConceded = 0;

    for (final m in validHistory) {
      if (m.homeTeamId == match.homeTeamId) {
        homeMatchesCount++;
        homeGoalsScored += m.result!.homeScore!;
        homeGoalsConceded += m.result!.awayScore!;
      } else if (m.awayTeamId == match.homeTeamId) {
        homeMatchesCount++;
        homeGoalsScored += m.result!.awayScore!;
        homeGoalsConceded += m.result!.homeScore!;
      }

      if (m.homeTeamId == match.awayTeamId) {
        awayMatchesCount++;
        awayGoalsScored += m.result!.homeScore!;
        awayGoalsConceded += m.result!.awayScore!;
      } else if (m.awayTeamId == match.awayTeamId) {
        awayMatchesCount++;
        awayGoalsScored += m.result!.awayScore!;
        awayGoalsConceded += m.result!.homeScore!;
      }
    }

    // Détection de statut
    final minTeamMatches = math.min(homeMatchesCount, awayMatchesCount);
    EstimationStatus status;
    if (minTeamMatches >= 5) {
      status = EstimationStatus.confirmed;
    } else if (minTeamMatches >= 1 ||
        (homeMatchesCount + awayMatchesCount >= 2)) {
      status = EstimationStatus.shrinkageEstimation;
    } else {
      status = EstimationStatus.insufficientData;
    }

    // 5. Régularisation bayésienne (Shrinkage vers la moyenne de la ligue)
    final wHome = homeMatchesCount / (homeMatchesCount + shrinkageC);
    final wAway = awayMatchesCount / (awayMatchesCount + shrinkageC);

    final rawHomeAtt = homeMatchesCount > 0
        ? (homeGoalsScored / homeMatchesCount) / math.max(0.5, compAvgHomeGoals)
        : 1.0;
    final rawHomeDef = homeMatchesCount > 0
        ? (homeGoalsConceded / homeMatchesCount) /
              math.max(0.5, compAvgAwayGoals)
        : 1.0;

    final rawAwayAtt = awayMatchesCount > 0
        ? (awayGoalsScored / awayMatchesCount) / math.max(0.5, compAvgAwayGoals)
        : 1.0;
    final rawAwayDef = awayMatchesCount > 0
        ? (awayGoalsConceded / awayMatchesCount) /
              math.max(0.5, compAvgHomeGoals)
        : 1.0;

    // Paramètres régularisés
    final homeAttack = (wHome * rawHomeAtt) + ((1.0 - wHome) * 1.0);
    final homeDefense = (wHome * rawHomeDef) + ((1.0 - wHome) * 1.0);
    final awayAttack = (wAway * rawAwayAtt) + ((1.0 - wAway) * 1.0);
    final awayDefense = (wAway * rawAwayDef) + ((1.0 - wAway) * 1.0);

    // Espérances de buts lambda et mu
    final lambda = math.max(
      0.2,
      math.min(
        5.0,
        homeAttack *
            awayDefense *
            compAvgHomeGoals *
            (homeAdvantage > 1.0 ? 1.05 : 1.0),
      ),
    );
    final mu = math.max(
      0.2,
      math.min(5.0, awayAttack * homeDefense * compAvgAwayGoals),
    );

    // 6. Construction de la matrice des probabilités bivariée (0..10 buts)
    double pHomeWin = 0.0;
    double pDraw = 0.0;
    double pAwayWin = 0.0;
    double totalProb = 0.0;

    double maxScoreProb = -1.0;
    String mostLikelyScore = '1-1';

    const maxGoals = 10;
    for (int x = 0; x <= maxGoals; x++) {
      for (int y = 0; y <= maxGoals; y++) {
        final tau = math.max(0.0, _dixonColesTau(x, y, lambda, mu));
        final prob = tau * _poissonPmf(x, lambda) * _poissonPmf(y, mu);
        totalProb += prob;

        if (prob > maxScoreProb) {
          maxScoreProb = prob;
          mostLikelyScore = '$x-$y';
        }

        if (x > y) {
          pHomeWin += prob;
        } else if (x == y) {
          pDraw += prob;
        } else {
          pAwayWin += prob;
        }
      }
    }

    // 7. Normalisation stricte de la somme des probabilités à 1.0
    if (totalProb > 0.0) {
      pHomeWin /= totalProb;
      pDraw /= totalProb;
      pAwayWin /= totalProb;
    } else {
      pHomeWin = 0.45;
      pDraw = 0.27;
      pAwayWin = 0.28;
    }

    // 8. Calcul de l'entropie de Shannon normalisée H / ln(3)
    final h =
        -((pHomeWin > 0 ? pHomeWin * math.log(pHomeWin) : 0.0) +
            (pDraw > 0 ? pDraw * math.log(pDraw) : 0.0) +
            (pAwayWin > 0 ? pAwayWin * math.log(pAwayWin) : 0.0)) /
        math.log(3);

    // 9. Score de confiance fonction de l'échantillon et de la certitude
    final sampleWeight = math.min(
      1.0,
      (homeMatchesCount + awayMatchesCount) / 10.0,
    );
    final confidenceScore = math.max(0.1, sampleWeight * 0.8 + (1.0 - h) * 0.2);

    return MatchPredictionResult(
      matchId: match.id,
      homeTeamName: match.homeTeamName,
      awayTeamName: match.awayTeamName,
      sportId: match.sportId,
      status: status,
      method: status == EstimationStatus.confirmed
          ? 'Dixon-Coles Bivariate Poisson v1'
          : 'Dixon-Coles Shrinkage Regularized v1',
      homeWinProb: double.parse(pHomeWin.toStringAsFixed(4)),
      drawProb: double.parse(pDraw.toStringAsFixed(4)),
      awayWinProb: double.parse(pAwayWin.toStringAsFixed(4)),
      expectedHomeScore: double.parse(lambda.toStringAsFixed(2)),
      expectedAwayScore: double.parse(mu.toStringAsFixed(2)),
      mostLikelyScore: mostLikelyScore,
      totalMatchesAnalyzed: totalCompMatches,
      homeTeamMatchesCount: homeMatchesCount,
      awayTeamMatchesCount: awayMatchesCount,
      temporalCutoff: cutoffDate ?? match.utcKickoff,
      confidenceScore: double.parse(confidenceScore.toStringAsFixed(3)),
      entropy: double.parse(h.toStringAsFixed(3)),
      disclaimer: status == EstimationStatus.shrinkageEstimation
          ? 'Échantillon faible ($homeMatchesCount et $awayMatchesCount matchs) : modèle régularisé par shrinkage bayésien vers la moyenne de la ligue.'
          : 'Estimation probabiliste Poisson Dixon-Coles fondée sur $totalCompMatches matchs historiques.',
    );
  }
}
