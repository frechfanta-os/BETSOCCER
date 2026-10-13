import 'package:flutter_test/flutter_test.dart';
import 'package:betsoccer/core/services/firebase_service.dart';
import 'package:betsoccer/core/services/firebase_sync_adapter.dart';

void main() {
  group('Firebase Service & Sync Adapter (Offline-First Resilience) Tests', () {
    test('FirebaseService defaults to uninitialized offline state', () {
      final service = FirebaseService.instance;
      // In local test environments without Google Services runtime
      expect(service.isInitialized, isFalse);
      expect(service.currentUser, isNull);
      expect(service.currentUserId, isNull);
    });

    test('FirebaseService safe operations when offline', () async {
      final service = FirebaseService.instance;
      final user = await service.signInAnonymously();
      expect(user, isNull);

      // signOut must not throw
      await expectLater(service.signOut(), completes);
    });

    test(
      'FirebaseSyncAdapter handles offline mode without throwing exceptions',
      () async {
        final service = FirebaseService.instance;
        final adapter = FirebaseSyncAdapter(service: service);

        final syncResult = await adapter.syncUserPreferences(
          favoriteSports: ['sport_football'],
          favoriteCompetitions: ['comp_epl'],
          isDarkMode: true,
          lastLocalSync: DateTime.now().toUtc(),
        );

        expect(
          syncResult,
          isFalse,
          reason: 'Sync should return false gracefully when offline',
        );

        final cloudPrefs = await adapter.fetchCloudPreferences();
        expect(
          cloudPrefs,
          isNull,
          reason: 'Fetching prefs should return null gracefully when offline',
        );
      },
    );
  });
}
