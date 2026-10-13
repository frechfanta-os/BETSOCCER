import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

/// Adaptateur de synchronisation Cloud Firestore pour les préférences utilisateur
class FirebaseSyncAdapter {
  final FirebaseService firebaseService;
  final FirebaseFirestore? firestore;

  FirebaseSyncAdapter({FirebaseService? service, this.firestore})
    : firebaseService = service ?? FirebaseService.instance;

  FirebaseFirestore? get _db {
    if (firestore != null) return firestore;
    if (firebaseService.isInitialized) {
      return FirebaseFirestore.instance;
    }
    return null;
  }

  /// Synchronise les préférences utilisateur vers Cloud Firestore (idempotent)
  Future<bool> syncUserPreferences({
    required List<String> favoriteSports,
    required List<String> favoriteCompetitions,
    required bool isDarkMode,
    required DateTime lastLocalSync,
  }) async {
    final firestore = _db;
    final uid = firebaseService.currentUserId;

    if (firestore == null || uid == null) {
      // Mode hors-ligne ou utilisateur non authentifié : opération silencieuse
      return false;
    }

    try {
      final docRef = firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences');
      await docRef.set({
        'favorite_sports': favoriteSports,
        'favorite_competitions': favoriteCompetitions,
        'is_dark_mode': isDarkMode,
        'last_local_sync_utc': lastLocalSync.toUtc().toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      // En cas d'erreur réseau, ne bloque jamais l'application
      return false;
    }
  }

  /// Récupère les préférences depuis le Cloud Firestore si disponibles
  Future<Map<String, dynamic>?> fetchCloudPreferences() async {
    final firestore = _db;
    final uid = firebaseService.currentUserId;

    if (firestore == null || uid == null) return null;

    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
