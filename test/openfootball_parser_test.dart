import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/features/sports/data/parsers/openfootball_parser.dart';
import 'package:betsoccer/features/sports/domain/entities/match.dart';

void main() {
  group('OpenFootballParser Tests', () {
    const sampleTxt = '''
# Football Data Archive
= English Premier League 2023/24

▪ Matchday 1
Fri Aug 11
  20:00  Burnley              0-3 (0-2)  Manchester City

Sat Aug 12
  12:30  Arsenal              2-1 (2-0)  Nottingham Forest
  15:00  Bournemouth          1-1 (0-0)  West Ham United
  15:00  Brighton             4-1 (1-0)  Luton Town
  15:00  Everton              0-1 (0-0)  Fulham
  15:00  Sheffield United     0-1 (0-0)  Crystal Palace
  17:30  Newcastle United     5-1 (2-1)  Aston Villa

Sun Aug 13
  14:00  Brentford            2-2 (2-2)  Tottenham Hotspur
  16:30  Chelsea              1-1 (1-1)  Liverpool

Mon Aug 14
  20:00  Manchester United    1-0 (0-0)  Wolverhampton Wanderers

▪ Matchday 2
Sat Aug 19
  15:00  Liverpool            v          Bournemouth
''';

    test('parse sample Football.TXT content correctly', () {
      final dataset = OpenFootballParser.parse(sampleTxt);

      expect(dataset.competitionName, equals('English Premier League'));
      expect(dataset.seasonLabel, equals('2023/24'));
      expect(dataset.startYear, equals(2023));
      expect(dataset.endYear, equals(2024));

      // 20 distinct teams in the sample
      expect(dataset.teams.length, equals(20));
      expect(dataset.teams.contains('Manchester City'), isTrue);
      expect(dataset.teams.contains('Burnley'), isTrue);
      expect(dataset.teams.contains('Arsenal'), isTrue);

      // 11 matches total (10 finished + 1 upcoming)
      expect(dataset.matches.length, equals(11));

      // Match 1: Burnley vs Man City
      final m1 = dataset.matches.first;
      expect(m1.homeTeam, equals('Burnley'));
      expect(m1.awayTeam, equals('Manchester City'));
      expect(m1.homeScore, equals(0));
      expect(m1.awayScore, equals(3));
      expect(m1.homeHalftimeScore, equals(0));
      expect(m1.awayHalftimeScore, equals(2));
      expect(m1.matchday, equals(1));
      expect(m1.roundLabel, equals('Journée 1'));
      expect(m1.status, equals(MatchStatus.finished));
      expect(m1.utcKickoff, equals(DateTime.utc(2023, 8, 11, 20, 0)));

      // Match 11: Upcoming match
      final m11 = dataset.matches.last;
      expect(m11.homeTeam, equals('Liverpool'));
      expect(m11.awayTeam, equals('Bournemouth'));
      expect(m11.homeScore, isNull);
      expect(m11.awayScore, isNull);
      expect(m11.matchday, equals(2));
      expect(m11.status, equals(MatchStatus.upcoming));
      expect(m11.utcKickoff, equals(DateTime.utc(2023, 8, 19, 15, 0)));
    });

    test('parse real Premier League 2023/24 asset file', () {
      final file = File('assets/data/historical/premier_league_2023_24.txt');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'L\'archive historique CC0 doit être présente.',
      );

      final content = file.readAsStringSync();
      final dataset = OpenFootballParser.parse(content);

      expect(dataset.competitionName, contains('Premier League'));
      expect(dataset.teams.length, equals(20));
      // In Premier League 20 teams play 38 matchdays = 380 matches
      expect(dataset.matches.length, equals(380));

      final allFinished = dataset.matches.every(
        (m) => m.status == MatchStatus.finished,
      );
      expect(allFinished, isTrue);

      // Verify all matches have valid kickoff dates
      for (final m in dataset.matches) {
        expect(m.utcKickoff.year, anyOf(2023, 2024));
        expect(m.homeScore, isNotNull);
        expect(m.awayScore, isNotNull);
        expect(m.homeTeam.isNotEmpty, isTrue);
        expect(m.awayTeam.isNotEmpty, isTrue);
      }
    });

    test('handle empty or comments-only content gracefully', () {
      final dataset = OpenFootballParser.parse(
        '# Only comments\n\n# Another comment\n',
      );
      expect(dataset.matches, isEmpty);
      expect(dataset.teams, isEmpty);
    });
  });
}
