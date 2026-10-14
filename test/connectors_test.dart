import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/core/errors/app_exception.dart';
import 'package:betsoccer/features/sports/data/sources/melbet_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/openfootball_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/openligadb_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/thesportsdb_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/football_data_org_data_source.dart';
import 'package:betsoccer/features/sports/domain/interfaces/sports_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Data Connectors Architecture & Policy Compliance Tests', () {
    group('MelbetDataSource Policy Enforcement', () {
      final melbet = MelbetDataSource();

      test('is strictly disabled by policy', () {
        expect(melbet.isEnabled, isFalse);
        expect(
          melbet.accessStatus,
          equals(ConnectorAccessStatus.disabledByPolicy),
        );
        expect(melbet.lastError, contains('DISABLED_BY_POLICY'));
        expect(melbet.supportedDataTypes, isEmpty);
        expect(melbet.supportsSportsDiscovery, isFalse);
        expect(melbet.supportsCompetitions, isFalse);
        expect(melbet.supportsUpcomingMatches, isFalse);
        expect(melbet.supportsLiveMatches, isFalse);
        expect(melbet.supportsHistoricalMatches, isFalse);
        expect(melbet.supportsMatchDetails, isFalse);
        expect(melbet.providerId, equals('melbet_restricted'));
      });

      test('supports configurable status and custom reason', () {
        final customMelbet = MelbetDataSource(
          configuredAccessStatus: ConnectorAccessStatus.restrictedByRobotsTxt,
          customReason: 'RESTRICTED_BY_ROBOTS_TXT: Disallow /statistic/*',
          lastErrorMessage: 'HTTP 403 Forbidden',
        );
        expect(customMelbet.isEnabled, isFalse);
        expect(
          customMelbet.accessStatus,
          equals(ConnectorAccessStatus.restrictedByRobotsTxt),
        );
        expect(customMelbet.lastError, equals('HTTP 403 Forbidden'));
        expect(
          () => customMelbet.fetchSports(),
          throwsA(
            isA<ConnectorDisabledException>().having(
              (e) => e.reason,
              'reason',
              contains('RESTRICTED_BY_ROBOTS_TXT'),
            ),
          ),
        );
      });

      test(
        'fetchSports throws ConnectorDisabledException with DISABLED_BY_POLICY',
        () async {
          expect(
            () => melbet.fetchSports(),
            throwsA(
              isA<ConnectorDisabledException>().having(
                (e) => e.reason,
                'reason',
                contains('DISABLED_BY_POLICY'),
              ),
            ),
          );
        },
      );

      test('fetchCompetitions throws ConnectorDisabledException', () async {
        expect(
          () => melbet.fetchCompetitions(sportId: 'sport_football'),
          throwsA(isA<ConnectorDisabledException>()),
        );
      });

      test('fetchUpcomingMatches throws ConnectorDisabledException', () async {
        expect(
          () => melbet.fetchUpcomingMatches(competitionId: 'comp_1'),
          throwsA(isA<ConnectorDisabledException>()),
        );
      });

      test('fetchLiveMatches throws ConnectorDisabledException', () async {
        expect(
          () => melbet.fetchLiveMatches(),
          throwsA(isA<ConnectorDisabledException>()),
        );
      });

      test(
        'fetchHistoricalMatches throws ConnectorDisabledException',
        () async {
          expect(
            () => melbet.fetchHistoricalMatches(
              competitionId: 'comp_1',
              season: '2023/24',
            ),
            throwsA(isA<ConnectorDisabledException>()),
          );
        },
      );

      test('fetchMatchDetails throws ConnectorDisabledException', () async {
        expect(
          () => melbet.fetchMatchDetails(matchId: 'match_1'),
          throwsA(isA<ConnectorDisabledException>()),
        );
      });
    });

    group('OpenFootballDataSource Compliance', () {
      final openFootball = OpenFootballDataSource();

      test('capabilities and metadata', () {
        expect(openFootball.isEnabled, isTrue);
        expect(openFootball.supportsSportsDiscovery, isTrue);
        expect(openFootball.supportsCompetitions, isTrue);
        expect(openFootball.supportsHistoricalMatches, isTrue);
        expect(openFootball.supportsLiveMatches, isFalse);
      });

      test('fetchSports returns Football', () async {
        final sports = await openFootball.fetchSports();
        expect(sports.length, equals(1));
        expect(sports.first.code, equals('SOCCER'));
      });

      test('fetchLiveMatches throws UnsupportedFeatureException', () async {
        expect(
          () => openFootball.fetchLiveMatches(),
          throwsA(isA<UnsupportedFeatureException>()),
        );
      });
    });

    group('TheSportsDbDataSource Compliance', () {
      final theSportsDb = TheSportsDbDataSource();

      test('capabilities and metadata', () {
        expect(theSportsDb.isEnabled, isTrue);
        expect(theSportsDb.providerId, equals('thesportsdb'));
        expect(theSportsDb.supportsSportsDiscovery, isTrue);
        expect(theSportsDb.supportsCompetitions, isTrue);
      });
    });

    group('FootballDataOrgDataSource Compliance', () {
      test(
        'disabled without API key and throws AuthenticationException',
        () async {
          final fdo = FootballDataOrgDataSource(apiKey: null);
          expect(fdo.isEnabled, isFalse);
          expect(fdo.providerId, equals('football_data_org'));

          expect(
            () => fdo.fetchCompetitions(sportId: 'sport_football'),
            throwsA(isA<AuthenticationException>()),
          );
        },
      );

      test('enabled when API key is provided', () {
        final fdo = FootballDataOrgDataSource(apiKey: 'dummy_api_key_test');
        expect(fdo.isEnabled, isTrue);
      });
    });

    group('OpenLigaDbDataSource Compliance & Live/Upcoming Capabilities', () {
      final oldb = OpenLigaDbDataSource();

      test('capabilities and metadata', () {
        expect(oldb.isEnabled, isTrue);
        expect(oldb.providerId, equals('openligadb'));
        expect(oldb.accessStatus, equals(ConnectorAccessStatus.available));
        expect(oldb.supportsSportsDiscovery, isTrue);
        expect(oldb.supportsCompetitions, isTrue);
        expect(oldb.supportsUpcomingMatches, isTrue);
        expect(oldb.supportsLiveMatches, isTrue);
        expect(oldb.supportsHistoricalMatches, isTrue);
        expect(oldb.supportsMatchDetails, isTrue);
      });

      test('fetchSports returns Football, Handball, Volleyball', () async {
        final sports = await oldb.fetchSports();
        expect(sports.length, equals(3));
        expect(
          sports.map((s) => s.code),
          containsAll(['SOCCER', 'HANDBALL', 'VOLLEYBALL']),
        );
      });

      test('fetchUpcomingMatches parses upcoming matches correctly', () async {
        final mockClient = MockClient((request) async {
          final jsonResponse = '''
          [
            {
              "matchID": 9901,
              "matchDateTimeUTC": "2026-10-17T13:30:00Z",
              "team1": {"teamId": 40, "teamName": "FC Bayern München"},
              "team2": {"teamId": 7, "teamName": "Borussia Dortmund"},
              "matchIsFinished": false,
              "matchResults": [],
              "group": {"groupOrderID": 8, "groupName": "8. Spieltag"}
            }
          ]
          ''';
          return http.Response(
            jsonResponse,
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final source = OpenLigaDbDataSource(httpClient: mockClient);
        final matches = await source.fetchUpcomingMatches(
          competitionId: 'comp_old_bl1',
        );

        expect(matches.length, equals(1));
        final m = matches.first;
        expect(m.homeTeamName, equals('FC Bayern München'));
        expect(m.awayTeamName, equals('Borussia Dortmund'));
        expect(m.status.name, equals('upcoming'));
        expect(m.matchday, equals(8));
      });

      test('fetchLiveMatches extracts live matches correctly', () async {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final mockClient = MockClient((request) async {
          final jsonResponse =
              '''
          [
            {
              "matchID": 9902,
              "matchDateTimeUTC": "$nowIso",
              "team1": {"teamId": 10, "teamName": "Leverkusen"},
              "team2": {"teamId": 20, "teamName": "Stuttgart"},
              "matchIsFinished": false,
              "matchResults": [
                {"resultName": "Halbzeitergebnis", "pointsTeam1": 1, "pointsTeam2": 0, "resultOrderID": 1}
              ],
              "group": {"groupOrderID": 8, "groupName": "8. Spieltag"}
            }
          ]
          ''';
          return http.Response(
            jsonResponse,
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final source = OpenLigaDbDataSource(httpClient: mockClient);
        final liveMatches = await source.fetchLiveMatches();

        expect(liveMatches.length, equals(1));
        final m = liveMatches.first;
        expect(m.homeTeamName, equals('Leverkusen'));
        expect(m.awayTeamName, equals('Stuttgart'));
        expect(m.status.name, equals('live'));
      });
    });

    group('TheSportsDbDataSource Upcoming Matches Integration', () {
      test('fetchUpcomingMatches parses eventsnextleague response', () async {
        final mockClient = MockClient((request) async {
          final jsonResponse = '''
          {
            "events": [
              {
                "idEvent": "100200",
                "strEvent": "Arsenal vs Chelsea",
                "strHomeTeam": "Arsenal",
                "strAwayTeam": "Chelsea",
                "dateEvent": "2026-10-18",
                "strTime": "16:30:00",
                "intRound": "9"
              }
            ]
          }
          ''';
          return http.Response(
            jsonResponse,
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final source = TheSportsDbDataSource(httpClient: mockClient);
        final matches = await source.fetchUpcomingMatches(
          competitionId: 'comp_fduk_e0',
        );

        expect(matches.length, equals(1));
        final m = matches.first;
        expect(m.homeTeamName, equals('Arsenal'));
        expect(m.awayTeamName, equals('Chelsea'));
        expect(m.status.name, equals('upcoming'));
        expect(m.sourceMatchId, equals('100200'));
      });
    });
  });
}
