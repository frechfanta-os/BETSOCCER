import 'dart:math' as math;

import '../../../features/sports/domain/entities/match.dart';
import '../models/prediction_result.dart';

/// Système de classement et de prédiction Elo multi-sport
class EloRatingEngine {
  final double defaultRating;
  final double defaultHomeAdvantage;
  final double defaultK;
  final double provisionalK;

  const EloRatingEngine({
    this.defaultRating = 1500.0,
    this.defaultHomeAdvantage = 65.0,
    this.defaultK = 32.0,
    this.provisionalK = 48.0,
  });

  /// Indique si un sport autorise les matchs nuls
  static bool allowsDraws(String sportId) {
    final s = sportId.toLowerCase();
    // Football et Handball autorisent le nul
    if (s.contains('football') ||
        s.contains('soccer') ||
        s.contains('handball') ||
        s.contains('hbl')) {
      return true;
    }
    // Tennis, Basketball (prolongations), Volleyball (sets) n'ont pas de match nul
    return false;
  }

  /// Calcule l'historique des classements Elo chronologiquement jusqu'à [cutoffDate]
  Map<String, double> computeRatings({
    required List<MatchEntity> matches,
    DateTime? cutoffDate,
  }) {
    final ratings = <String, double>{};
    final matchCounts = <String, int>{};

    // 1. Filtrer et trier chronologiquement
    final sortedMatches = matches.where((m) {
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
    }).toList()..sort((a, b) => a.utcKickoff.compareTo(b.utcKickoff));

    // 2. Mettre à jour les notes après chaque match
    for (final m in sortedMatches) {
      final homeId = m.homeTeamId;
      final awayId = m.awayTeamId;

      final rHome = ratings[homeId] ?? defaultRating;
      final rAway = ratings[awayId] ?? defaultRating;

      final homeCount = matchCounts[homeId] ?? 0;
      final awayCount = matchCounts[awayId] ?? 0;

      final kHome = homeCount < 5 ? provisionalK : defaultK;
      final kAway = awayCount < 5 ? provisionalK : defaultK;

      final sportAllowsDraw = allowsDraws(m.sportId);
      final homeAdv = (m.sportId.toLowerCase().contains('tennis'))
          ? 0.0
          : defaultHomeAdvantage;

      // Espérance de gain standard Elo
      final diff = (rAway - (rHome + homeAdv)) / 400.0;
      final expectedHome = 1.0 / (1.0 + math.pow(10.0, diff));
      final expectedAway = 1.0 - expectedHome;

      // Score réel
      final hs = m.result!.homeScore!;
      final as_ = m.result!.awayScore!;

      double actualHome;
      double actualAway;
      if (hs > as_) {
        actualHome = 1.0;
        actualAway = 0.0;
      } else if (hs == as_ && sportAllowsDraw) {
        actualHome = 0.5;
        actualAway = 0.5;
      } else {
        actualHome = 0.0;
        actualAway = 1.0;
      }

      // Mise à jour
      ratings[homeId] = rHome + (kHome * (actualHome - expectedHome));
      ratings[awayId] = rAway + (kAway * (actualAway - expectedAway));

      matchCounts[homeId] = homeCount + 1;
      matchCounts[awayId] = awayCount + 1;
    }

    return ratings;
  }

  /// Estime les probabilités d'un match selon le modèle Elo adapté au sport
  MatchPredictionResult predictMatch({
    required MatchEntity match,
    required List<MatchEntity> historicalMatches,
    DateTime? cutoffDate,
  }) {
    final cutoff = cutoffDate ?? match.utcKickoff;
    final sportId = match.sportId.toLowerCase();
    final sportAllowsDraw = allowsDraws(sportId);

    // Calcul des classements à la date du match
    final ratings = computeRatings(
      matches: historicalMatches,
      cutoffDate: cutoff,
    );

    // Comptage des matchs préalables de chaque équipe
    int homeMatchesCount = 0;
    int awayMatchesCount = 0;
    for (final m in historicalMatches) {
      if (m.status != MatchStatus.finished || m.result == null) {
        continue;
      }
      if (m.utcKickoff.isAfter(cutoff)) {
        continue;
      }
      if (m.homeTeamId == match.homeTeamId ||
          m.awayTeamId == match.homeTeamId) {
        homeMatchesCount++;
      }
      if (m.homeTeamId == match.awayTeamId ||
          m.awayTeamId == match.awayTeamId) {
        awayMatchesCount++;
      }
    }

    final totalHistory = historicalMatches
        .where(
          (m) =>
              m.status == MatchStatus.finished && !m.utcKickoff.isAfter(cutoff),
        )
        .length;

    // Évaluation du statut
    EstimationStatus status;
    final minCount = math.min(homeMatchesCount, awayMatchesCount);
    if (minCount >= 5) {
      status = EstimationStatus.confirmed;
    } else if (homeMatchesCount >= 1 || awayMatchesCount >= 1) {
      status = EstimationStatus.shrinkageEstimation;
    } else {
      status = EstimationStatus.insufficientData;
    }

    final rHome = ratings[match.homeTeamId] ?? defaultRating;
    final rAway = ratings[match.awayTeamId] ?? defaultRating;

    final homeAdv = sportId.contains('tennis') ? 0.0 : defaultHomeAdvantage;
    final diff = (rAway - (rHome + homeAdv)) / 400.0;
    final baseExpectedHome = 1.0 / (1.0 + math.pow(10.0, diff));
    final baseExpectedAway = 1.0 - baseExpectedHome;

    double pHome;
    double pDraw;
    double pAway;

    if (!sportAllowsDraw) {
      // Sports sans nul (Tennis, Basket, Volley) : strictement 2 issues
      pHome = baseExpectedHome;
      pDraw = 0.0;
      pAway = baseExpectedAway;
    } else {
      // Sports à 3 issues (Football, Handball) : Modèle étendu avec probabilité de nul
      // Facteur de nul empirique selon la proximité des cotes Elo
      final drawFactor =
          0.26 * (1.0 - (baseExpectedHome - baseExpectedAway).abs() * 0.4);
      pDraw = math.max(0.12, math.min(0.35, drawFactor));

      final remaining = 1.0 - pDraw;
      final sumTwo = baseExpectedHome + baseExpectedAway;
      pHome = remaining * (baseExpectedHome / sumTwo);
      pAway = remaining * (baseExpectedAway / sumTwo);
    }

    // Normalisation
    final sum = pHome + pDraw + pAway;
    pHome /= sum;
    pDraw /= sum;
    pAway /= sum;

    // Entropie
    final double entropy;
    if (!sportAllowsDraw) {
      entropy =
          -((pHome > 0 ? pHome * math.log(pHome) : 0.0) +
              (pAway > 0 ? pAway * math.log(pAway) : 0.0)) /
          math.log(2);
    } else {
      entropy =
          -((pHome > 0 ? pHome * math.log(pHome) : 0.0) +
              (pDraw > 0 ? pDraw * math.log(pDraw) : 0.0) +
              (pAway > 0 ? pAway * math.log(pAway) : 0.0)) /
          math.log(3);
    }

    final sampleWeight = math.min(
      1.0,
      (homeMatchesCount + awayMatchesCount) / 10.0,
    );
    final confidence = math.max(
      0.1,
      sampleWeight * 0.75 + (1.0 - entropy) * 0.25,
    );

    return MatchPredictionResult(
      matchId: match.id,
      homeTeamName: match.homeTeamName,
      awayTeamName: match.awayTeamName,
      sportId: match.sportId,
      status: status,
      method:
          'Multi-Sport Elo Engine (Elo ${rHome.round()} vs ${rAway.round()})',
      homeWinProb: double.parse(pHome.toStringAsFixed(4)),
      drawProb: double.parse(pDraw.toStringAsFixed(4)),
      awayWinProb: double.parse(pAway.toStringAsFixed(4)),
      expectedHomeScore: null,
      expectedAwayScore: null,
      mostLikelyScore: null,
      totalMatchesAnalyzed: totalHistory,
      homeTeamMatchesCount: homeMatchesCount,
      awayTeamMatchesCount: awayMatchesCount,
      temporalCutoff: cutoff,
      confidenceScore: double.parse(confidence.toStringAsFixed(3)),
      entropy: double.parse(entropy.toStringAsFixed(3)),
      disclaimer: status == EstimationStatus.shrinkageEstimation
          ? 'Données limitées : les cotes Elo intègrent la valeur par défaut (${defaultRating.toInt()}) pour les équipes sans historique suffisant.'
          : 'Estimation probabiliste fondée sur le classement Elo dynamique (${rHome.round()} vs ${rAway.round()}).',
    );
  }
}
