# BETSOCCER — RAPPORT D'INTÉGRATION FIREBASE (PROJET betsoccer-60834)

## 1. Contexte & Identité du Projet

Dans le cadre de BETSOCCER, Firebase a été intégré comme service auxiliaire non-bloquant, destiné exclusivement à la sauvegarde des préférences utilisateur et de l'état de synchronisation en ligne. L'architecture respecte scrupuleusement la règle du **budget 0 €** et le principe **Offline-First**.

### Métadonnées du Projet
- **Firebase Project ID** : `betsoccer-60834`
- **Project Number** : `561415224411`
- **Package Android** : `com.ghdinteractivestudio.betsoccer`
- **Storage Bucket** : `betsoccer-60834.firebasestorage.app`
- **Clé de service Web / Push intégrée** : Intégrée dans `google-services.json` et `firebase_options.dart` (aucun secret sensible n'est exposé en clair dans les logs publics).

---

## 2. Règle d'Or Architecturale : Rôle Strict de Firebase

Conformément aux directives de Phase 0 et à la contrainte budgétaire :
1. **SQLite (`sqflite`) reste la source de vérité unique et souveraine** pour tous les jeux de données sportifs (sports, championnats, équipes, matchs, scores, modèles prédictifs).
2. **Cloud Firestore n'est JAMAIS utilisé pour stocker ou répliquer les catalogues sportifs** :
   - Évite tout dépassement du quota gratuit Firestore (50 000 lectures / 20 000 écritures par jour).
   - Garantit une utilisation 100% fonctionnelle hors réseau (avion, métro, zone blanche).
3. **Périmètre exclusif de Firestore** :
   - Sauvegarde des préférences utilisateur : mode sombre (`is_dark_mode`), sports favoris (`favorite_sports`), compétitions suivies (`favorite_competitions`), horodatage de synchronisation (`last_local_sync_utc`).

---

## 3. Configuration Android & Flutter

### 3.1 Dépendances Gradle & Flutter
- **Plugin Gradle Google Services** : Version `4.4.2` configurée dans `android/settings.gradle.kts` et appliquée dans `android/app/build.gradle.kts`.
- **Packages FlutterFire** :
  - `firebase_core: ^4.15.0`
  - `cloud_firestore: ^6.10.0`
  - `firebase_auth: ^6.7.0`

### 3.2 Permissions & Visibilité Android
Dans `android/app/src/main/AndroidManifest.xml` :
- Permission Internet activée : `<uses-permission android:name="android.permission.INTERNET"/>`.
- Respect strict des directives OTA d'Antigravity : déclaration des filtres `<queries>` pour `packageinstaller` et suppression de tout attribut `taskAffinity=""` sur `MainActivity`.

### 3.3 Initialisation Non-Bloquante (`lib/core/services/firebase_service.dart`)
L'initialisation Firebase est encapsulée dans un bloc `try / catch` asynchrone :
```dart
try {
  await fbService.initialize();
} catch (_) {
  // Mode hors-ligne automatique immédiat : zéro plantage au lancement
}
```
Si Firebase est indisponible, si l'appareil est hors ligne ou si les services Google Play sont absents (ex: certains terminaux AOSP ou PRoot), l'application s'initialise instantanément et sans aucune interruption.

---

## 4. Règles de Sécurité Cloud Firestore (`firestore.rules`)

Des règles granulaires avec principe de moindre privilège ont été déployées :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 1. Isolation stricte des données utilisateurs
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /settings/{settingDoc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // 2. Refus absolu de stockage sportif dans Firestore (réservé à SQLite)
    match /sports/{document=**} {
      allow read, write: if false;
    }
    match /matches/{document=**} {
      allow read, write: if false;
    }
    
    // 3. Verrouillage par défaut
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 5. Validation et Tests

- **Test unitaire de résilience hors ligne (`test/firebase_test.dart`)** :
  - Vérification de l'état initial non initialisé.
  - Absence de levée d'exception lors de l'appel à `signInAnonymously()` ou `signOut()` hors ligne.
  - `FirebaseSyncAdapter.syncUserPreferences()` retourne gracieusement `false` sans bloquer le thread UI.
  - Résultat : **3 tests passés avec succès (0 échec)**.
