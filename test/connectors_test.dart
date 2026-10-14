import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/core/errors/app_exception.dart';
import 'package:betsoccer/features/sports/data/sources/melbet_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/openfootball_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/thesportsdb_data_source.dart';
import 'package:betsoccer/features/sports/data/sources/football_data_org_data_source.dart';
import 'package:betsoccer/features/sports/domain/interfaces/sports_data_source.dart';

void main() {
  group('Data Connectors Architecture & Policy Compliance Tests', () {
    group('MelbetDataSource Policy Enforcement', () {
      final melbet = MelbetDataSource();

      test('is strictly disabled by policy', () {
        expect(melbet.isEnabled, isFalse);
        expect(melbet.accessStatus, equals(ConnectorAccessStatus.disabledByPolicy));
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
  });
}
