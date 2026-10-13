import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firebase_options.dart';

/// Service centralisé de gestion du cycle de vie Firebase
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth? _auth;
  FirebaseAuth? get auth => _auth;

  User? get currentUser => _auth?.currentUser;
  String? get currentUserId => _auth?.currentUser?.uid;

  /// Initialise Firebase sans jamais bloquer l'application en cas d'erreur ou d'absence réseau
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _isInitialized = true;
      return true;
    } catch (e) {
      // Échec gracieux : l'application bascule en mode 100% local / hors ligne
      _isInitialized = false;
      return false;
    }
  }

  /// Connexion anonyme optionnelle pour synchroniser les préférences
  Future<User?> signInAnonymously() async {
    if (!_isInitialized || _auth == null) return null;
    try {
      final credential = await _auth!.signInAnonymously();
      return credential.user;
    } catch (_) {
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    if (_isInitialized && _auth != null) {
      await _auth!.signOut();
    }
  }
}
