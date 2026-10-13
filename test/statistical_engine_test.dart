import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/core/stats/statistical_engine.dart';
import 'package:betsoccer/core/stats/models/prediction_result.dart';
import 'package:betsoccer/core/stats/descriptive/descriptive_stats_calculator.dart';
import 'package:betsoccer/core/stats/models_impl/poisson_dixon_coles_model.dart';
import 'package:betsoccer/core/stats/models_impl/elo_rating_engine.dart';
import 'package:betsoccer/core/stats/evaluator/backtest_evaluator.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';
import 'package:betsoccer/features/sports/domain/entities/match_result.dart';

void main() {
  group('Phase 2 — Statistical Engine Tests', () {
    // Jeu de test synthétique chronologique
    final baseTime = DateTime.utc(2026, 10, 1, 12, 0);

    MatchEntity makeMatch({
      required String id,
      required String sportId,
      required String homeTeamId,
      required String homeTeamName,
      required String awayTeamId,
      required String awayTeamName,
      required DateTime kickoff,
      int? homeScore,
      int? awayScore,
    }) {
      return MatchEntity(
        id: id,
        sportId: sportId,
        competitionId: 'comp_test',
        homeTeamId: homeTeamId,
        homeTeamName: homeTeamName,
        awayTeamId: awayTeamId,
        awayTeamName: awayTeamName,
        utcKickoff: kickoff,
        status: homeScore != null ? MatchStatus.finished : MatchStatus.upcoming,
        sourceProvider: 'test_provider',
        lastSyncedAt: kickoff,
        result: homeScore != null
            ? MatchResultEntity(
                id: 'res_$id',
                matchId: id,
                homeScore: homeScore,
                awayScore: awayScore,
              )
            : null,
      );
    }

    final history = [
      makeMatch(
        id: 'm1',
        sportId: 'sport_football',
        homeTeamId: 'team_a',
        homeTeamName: 'Team A',
        awayTeamId: 'team_b',
        awayTeamName: 'Team B',
        kickoff: baseTime,
        homeScore: 2,
        awayScore: 1,
      ),
      makeMatch(
        id: 'm2',
        sportId: 'sport_football',
        homeTeamId: 'team_c',
        homeTeamName: 'Team C',
        awayTeamId: 'team_a',
        awayTeamName: 'Team A',
        kickoff: baseTime.add(const Duration(days: 2)),
        homeScore: 1,
        awayScore: 1,
      ),
      makeMatch(
        id: 'm3',
        sportId: 'sport_football',
        homeTeamId: 'team_b',
        homeTeamName: 'Team B',
        awayTeamId: 'team_c',
        awayTeamName: 'Team C',
        kickoff: baseTime.add(const Duration(days: 4)),
        homeScore: 0,
        awayScore: 2,
      ),
      makeMatch(
        id: 'm4',
        sportId: 'sport_football',
        homeTeamId: 'team_a',
        homeTeamName: 'Team A',
        awayTeamId: 'team_d',
        awayTeamName: 'Team D',
        kickoff: baseTime.add(const Duration(days: 6)),
        homeScore: 3,
        awayScore: 0,
      ),
    ];

    test(
      'DescriptiveStatsCalculator computes form and prevents data leakage',
      () {
        // Évaluation pour Team A avant le match m4
        final formBeforeM4 = DescriptiveStatsCalculator.computeRecentForm(
          teamId: 'team_a',
          teamName: 'Team A',
          matches: history,
          limit: 5,
          cutoffDate: baseTime.add(const Duration(days: 5)),
        );

        // Avant jour 5 : uniquement m1 (W, 2-1) et m2 (D, 1-1)
        expect(formBeforeM4.matchesPlayed, equals(2));
        expect(formBeforeM4.wins, equals(1));
        expect(formBeforeM4.draws, equals(1));
        expect(formBeforeM4.losses, equals(0));
        expect(formBeforeM4.goalsScored, equals(3));
        expect(formBeforeM4.goalsConceded, equals(2));
        expect(formBeforeM4.points, equals(4)); // 3 + 1
        expect(formBeforeM4.formString, equals('W,D'));

        // Cold start pour une équipe sans match
        final coldStartForm = DescriptiveStatsCalculator.computeRecentForm(
          teamId: 'team_unknown',
          teamName: 'Unknown',
          matches: history,
        );
        expect(coldStartForm.matchesPlayed, equals(0));
        expect(coldStartForm.hasSufficientData, isFalse);
      },
    );

    test(
      'DescriptiveStatsCalculator computes venue splits and H2H accurately',
      () {
        final splits = DescriptiveStatsCalculator.computeVenueSplits(
          teamId: 'team_a',
          matches: history,
        );
        // Team A joue à domicile dans m1 (2-1) et m4 (3-0) -> 2 matchs, 2 victoires
        expect(splits.homeMatchesPlayed, equals(2));
        expect(splits.homeWins, equals(2));
        expect(splits.homeGoalsScored, equals(5));
        expect(splits.homeGoalsConceded, equals(1));

        // Team A joue à l'extérieur dans m2 (1-1) -> 1 match, 1 nul
        expect(splits.awayMatchesPlayed, equals(1));
        expect(splits.awayDraws, equals(1));

        // H2H entre Team A et Team B
        final h2h = DescriptiveStatsCalculator.computeHeadToHead(
          teamAId: 'team_a',
          teamAName: 'Team A',
          teamBId: 'team_b',
          teamBName: 'Team B',
          matches: history,
        );
        expect(h2h.totalMatches, equals(1));
        expect(h2h.teamAWins, equals(1));
        expect(h2h.teamBWins, equals(0));
      },
    );

    test('PoissonDixonColesModel predicts soccer match with normalized probabilities', () {
      const model = PoissonDixonColesModel();
      final target = makeMatch(
        id: 'target_match',
        sportId: 'sport_football',
        homeTeamId: 'team_a',
        homeTeamName: 'Team A',
        awayTeamId: 'team_b',
        awayTeamName: 'Team B',
        kickoff: baseTime.add(const Duration(days: 10)),
      );

      final pred = model.predictMatch(
        match: target,
        historicalMatches: history,
      );

      expect(pred.status, equals(EstimationStatus.shrinkageEstimation));
      expect(pred.homeWinProb, greaterThan(0.0));
      expect(pred.drawProb, greaterThan(0.0));
      expect(pred.awayWinProb, greaterThan(0.0));

      // Somme strictement normalisée à 1.0 (tolérance d'arrondi)
      final sum = pred.homeWinProb + pred.drawProb + pred.awayWinProb;
      expect((sum - 1.0).abs(), lessThan(0.005));

      // Buts attendus calculés
      expect(pred.expectedHomeScore, isNotNull);
      expect(pred.expectedAwayScore, isNotNull);
      expect(pred.mostLikelyScore, isNotNull);

      // Rejet formel pour sport incompatible
      final tennisMatch = makeMatch(
        id: 'tennis_m',
        sportId: 'sport_tennis',
        homeTeamId: 'player_1',
        homeTeamName: 'Player 1',
        awayTeamId: 'player_2',
        awayTeamName: 'Player 2',
        kickoff: baseTime,
      );
      final tennisPred = model.predictMatch(
        match: tennisMatch,
        historicalMatches: history,
      );
      expect(tennisPred.status, equals(EstimationStatus.unsupportedSportModel));
    });

    test(
      'EloRatingEngine handles multi-sport rules and 2-way vs 3-way outcomes',
      () {
        const elo = EloRatingEngine();

        // Football : 3 issues possibles
        final footballTarget = makeMatch(
          id: 'fb_target',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_b',
          awayTeamName: 'Team B',
          kickoff: baseTime.add(const Duration(days: 10)),
        );
        final fbPred = elo.predictMatch(
          match: footballTarget,
          historicalMatches: history,
        );
        expect(fbPred.drawProb, greaterThan(0.0));
        final fbSum = fbPred.homeWinProb + fbPred.drawProb + fbPred.awayWinProb;
        expect((fbSum - 1.0).abs(), lessThan(0.005));

        // Tennis : strictement 2 issues (drawProb = 0.0)
        final tennisTarget = makeMatch(
          id: 'tn_target',
          sportId: 'sport_tennis',
          homeTeamId: 'p1',
          homeTeamName: 'Player 1',
          awayTeamId: 'p2',
          awayTeamName: 'Player 2',
          kickoff: baseTime.add(const Duration(days: 10)),
        );
        final tnPred = elo.predictMatch(
          match: tennisTarget,
          historicalMatches: const [],
        );
        expect(tnPred.drawProb, equals(0.0));
        final tnSum = tnPred.homeWinProb + tnPred.awayWinProb;
        expect((tnSum - 1.0).abs(), lessThan(0.005));
      },
    );

    test('BacktestEvaluator performs chronological walk-forward benchmark', () {
      final benchmark = BacktestEvaluator.runFullBenchmark(history);
      expect(benchmark.containsKey('poisson'), isTrue);
      expect(benchmark.containsKey('elo'), isTrue);

      final poissonMetrics = benchmark['poisson']!;
      expect(poissonMetrics.modelName, equals('Poisson Dixon-Coles'));
      expect(poissonMetrics.totalEvaluatedMatches, greaterThanOrEqualTo(0));
    });

    test('StatisticalEngine facade provides complete analytical profile', () {
      const engine = StatisticalEngine();

      final target = makeMatch(
        id: 'target_match',
        sportId: 'sport_football',
        homeTeamId: 'team_a',
        homeTeamName: 'Team A',
        awayTeamId: 'team_b',
        awayTeamName: 'Team B',
        kickoff: baseTime.add(const Duration(days: 10)),
      );

      final pred = engine.predictMatch(match: target, allMatches: history);
      expect(pred.isReliable, isTrue);
      expect(pred.disclaimer.isNotEmpty, isTrue);

      final form = engine.getTeamRecentForm(
        teamId: 'team_a',
        teamName: 'Team A',
        allMatches: history,
      );
      expect(form.teamName, equals('Team A'));
    });

    group('Phase 2.1 — Scientific Integrity & Non-Regression', () {
      test('Manual verification of multiclass Brier Score calculation', () {
        // Cas 1 : Prédiction [0.8, 0.1, 0.1], résultat réel Home Win (y = [1, 0, 0])
        // Brier = (0.8 - 1)^2 + (0.1 - 0)^2 + (0.1 - 0)^2 = (-0.2)^2 + 0.01 + 0.01 = 0.04 + 0.01 + 0.01 = 0.06
        const p1 = [0.8, 0.1, 0.1];
        const y1 = [1.0, 0.0, 0.0];
        final brier1 =
            math.pow(p1[0] - y1[0], 2) +
            math.pow(p1[1] - y1[1], 2) +
            math.pow(p1[2] - y1[2], 2);
        expect(brier1, closeTo(0.06, 1e-6));

        // Cas 2 : Prédiction [0.2, 0.5, 0.3], résultat réel Nul (y = [0, 1, 0])
        // Brier = 0.2^2 + (0.5 - 1)^2 + 0.3^2 = 0.04 + 0.25 + 0.09 = 0.38
        const p2 = [0.2, 0.5, 0.3];
        const y2 = [0.0, 1.0, 0.0];
        final brier2 =
            math.pow(p2[0] - y2[0], 2) +
            math.pow(p2[1] - y2[1], 2) +
            math.pow(p2[2] - y2[2], 2);
        expect(brier2, closeTo(0.38, 1e-6));

        // Cas 3 : Référence uniforme naïve [1/3, 1/3, 1/3] pour toute issue
        // (1/3 - 1)^2 + (1/3)^2 + (1/3)^2 = 4/9 + 1/9 + 1/9 = 6/9 = 2/3 ≈ 0.666667
        const u = 1.0 / 3.0;
        final uniformBrier =
            math.pow(u - 1.0, 2) + math.pow(u - 0.0, 2) + math.pow(u - 0.0, 2);
        expect(uniformBrier, closeTo(2.0 / 3.0, 1e-6));
      });

      test('Manual verification of multiclass Log-Loss calculation', () {
        const eps = 1e-6;
        // Cas 1 : Prédiction [0.8, 0.1, 0.1], résultat 1 -> -ln(0.8) ≈ 0.22314
        final ll1 = -(1.0 * math.log(math.max(eps, 0.8)));
        expect(ll1, closeTo(0.223143, 1e-4));

        // Cas 2 : Référence uniforme [1/3, 1/3, 1/3] -> -ln(1/3) = ln(3) ≈ 1.09861
        final llUniform = -(1.0 * math.log(1.0 / 3.0));
        expect(llUniform, closeTo(math.log(3.0), 1e-6));
        expect(llUniform, closeTo(1.098612, 1e-4));
      });

      test('Anti-lookahead test: future and simultaneous matches are strictly rejected', () {
        const poisson = PoissonDixonColesModel();
        const elo = EloRatingEngine();

        final targetTime = baseTime.add(const Duration(days: 5));
        final targetMatch = makeMatch(
          id: 'target_match_eval',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_b',
          awayTeamName: 'Team B',
          kickoff: targetTime,
        );

        // 1. Prédiction de référence avec historique antérieur valide (jour 0, jour 2, jour 4)
        final refHistory = history
            .where((m) => m.utcKickoff.isBefore(targetTime))
            .toList();
        final refPoisson = poisson.predictMatch(
          match: targetMatch,
          historicalMatches: refHistory,
        );
        final refElo = elo.predictMatch(
          match: targetMatch,
          historicalMatches: refHistory,
        );

        // 2. Polluer l'historique avec :
        // a) Un match futur avec score extrême (15-0)
        final futureMatch = makeMatch(
          id: 'future_leak_match',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_b',
          awayTeamName: 'Team B',
          kickoff: targetTime.add(const Duration(days: 10)),
          homeScore: 15,
          awayScore: 0,
        );
        // b) Un match simultané (même coup d'envoi exact) avec score extrême (20-0)
        final simultaneousMatch = makeMatch(
          id: 'simultaneous_match',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_c',
          awayTeamName: 'Team C',
          kickoff: targetTime, // Même instant !
          homeScore: 20,
          awayScore: 0,
        );
        // c) Le match cible lui-même marqué terminé (10-0)
        final selfMatchFinished = makeMatch(
          id: 'target_match_eval',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_b',
          awayTeamName: 'Team B',
          kickoff: targetTime,
          homeScore: 10,
          awayScore: 0,
        );

        final pollutedHistory = [
          ...refHistory,
          futureMatch,
          simultaneousMatch,
          selfMatchFinished,
        ];

        // 3. Calculer les prédictions sur l'historique pollué
        final pollutedPoisson = poisson.predictMatch(
          match: targetMatch,
          historicalMatches: pollutedHistory,
        );
        final pollutedElo = elo.predictMatch(
          match: targetMatch,
          historicalMatches: pollutedHistory,
        );

        // 4. Affirmation formelle : AUCUNE fuite temporelle, probabilités identiques
        expect(pollutedPoisson.homeWinProb, equals(refPoisson.homeWinProb));
        expect(pollutedPoisson.drawProb, equals(refPoisson.drawProb));
        expect(pollutedPoisson.awayWinProb, equals(refPoisson.awayWinProb));
        expect(
          pollutedPoisson.expectedHomeScore,
          equals(refPoisson.expectedHomeScore),
        );

        expect(pollutedElo.homeWinProb, equals(refElo.homeWinProb));
        expect(pollutedElo.drawProb, equals(refElo.drawProb));
        expect(pollutedElo.awayWinProb, equals(refElo.awayWinProb));
      });

      test('Extreme distributions and numerical stability test', () {
        const poisson = PoissonDixonColesModel();
        final target = makeMatch(
          id: 'target_m',
          sportId: 'sport_football',
          homeTeamId: 'team_a',
          homeTeamName: 'Team A',
          awayTeamId: 'team_b',
          awayTeamName: 'Team B',
          kickoff: baseTime.add(const Duration(days: 10)),
        );

        // Tester avec historique où une équipe n'a marqué aucun but
        final zeroGoalHistory = [
          makeMatch(
            id: 'm_zero_1',
            sportId: 'sport_football',
            homeTeamId: 'team_a',
            homeTeamName: 'Team A',
            awayTeamId: 'team_b',
            awayTeamName: 'Team B',
            kickoff: baseTime,
            homeScore: 0,
            awayScore: 0,
          ),
          makeMatch(
            id: 'm_zero_2',
            sportId: 'sport_football',
            homeTeamId: 'team_b',
            homeTeamName: 'Team B',
            awayTeamId: 'team_a',
            awayTeamName: 'Team A',
            kickoff: baseTime.add(const Duration(days: 1)),
            homeScore: 0,
            awayScore: 0,
          ),
          makeMatch(
            id: 'm_zero_3',
            sportId: 'sport_football',
            homeTeamId: 'team_a',
            homeTeamName: 'Team A',
            awayTeamId: 'team_c',
            awayTeamName: 'Team C',
            kickoff: baseTime.add(const Duration(days: 2)),
            homeScore: 0,
            awayScore: 0,
          ),
        ];

        final pred = poisson.predictMatch(
          match: target,
          historicalMatches: zeroGoalHistory,
        );

        // Aucune probabilité n'est NaN ni Infinite
        expect(pred.homeWinProb.isNaN, isFalse);
        expect(pred.drawProb.isNaN, isFalse);
        expect(pred.awayWinProb.isNaN, isFalse);
        expect(pred.homeWinProb.isInfinite, isFalse);
        expect(pred.entropy.isNaN, isFalse);
        expect(pred.confidenceScore.isNaN, isFalse);

        // Normalisation préservée
        final sum = pred.homeWinProb + pred.drawProb + pred.awayWinProb;
        expect((sum - 1.0).abs(), lessThan(0.005));
      });

      test('Cold start behavior with empty or unknown data', () {
        const poisson = PoissonDixonColesModel();
        const elo = EloRatingEngine();

        final coldMatch = makeMatch(
          id: 'cold_m',
          sportId: 'sport_football',
          homeTeamId: 'new_team_1',
          homeTeamName: 'New Team 1',
          awayTeamId: 'new_team_2',
          awayTeamName: 'New Team 2',
          kickoff: baseTime,
        );

        // Historique vide
        final pCold = poisson.predictMatch(
          match: coldMatch,
          historicalMatches: const [],
        );
        expect(pCold.status, equals(EstimationStatus.insufficientData));
        expect(pCold.homeWinProb, equals(0.0));

        final eCold = elo.predictMatch(
          match: coldMatch,
          historicalMatches: const [],
        );
        expect(eCold.status, equals(EstimationStatus.insufficientData));
        expect(
          eCold.homeWinProb,
          greaterThan(0.0),
        ); // Elo 1500 avec avantage domicile par défaut
        expect(eCold.disclaimer, contains('1500'));
      });

      test('Wilson score interval computation accuracy', () {
        // N = 28, k = 13 (Poisson sur betsoccer.db)
        final (pLower, pUpper) = BacktestEvaluator.computeWilsonScoreInterval(
          13,
          28,
        );
        expect(pLower, closeTo(0.2954, 0.005));
        expect(pUpper, closeTo(0.6418, 0.005));

        // N = 28, k = 12 (Elo sur betsoccer.db)
        final (eLower, eUpper) = BacktestEvaluator.computeWilsonScoreInterval(
          12,
          28,
        );
        expect(eLower, closeTo(0.2651, 0.005));
        expect(eUpper, closeTo(0.6094, 0.005));

        // N = 0
        final (zeroLower, zeroUpper) =
            BacktestEvaluator.computeWilsonScoreInterval(0, 0);
        expect(zeroLower, equals(0.0));
        expect(zeroUpper, equals(0.0));
      });
    });
  });
}
