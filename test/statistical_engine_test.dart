import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/core/stats/statistical_engine.dart';
import 'package:betsoccer/core/stats/models/prediction_result.dart';
import 'package:betsoccer/core/stats/models/statistical_metrics.dart';
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
  });
}
