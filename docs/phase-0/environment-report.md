# BETSOCCER — RAPPORT D'AUDIT DE L'ENVIRONNEMENT (PHASE 0)

**Date d'audit :** 13 Octobre 2026  
**Auteur :** Ingénieur DevOps & Sécurité  
**Projet :** BETSOCCER — Multisport Analytics AI  
**Statut :** AUDIT RÉALISÉ ET VALIDÉ (Aucune modification système superflue requise)

---

## 1. VUE D'ENSEMBLE DU SYSTÈME

L'environnement de travail a été inspecté sans altération des configurations sous-jacentes. Il s'agit d'un système Linux conteneurisé s'exécutant sur un terminal mobile via Termux et PRoot.

| Composant | Détails techniques constatés | Statut |
| :--- | :--- | :--- |
| **Système hôte** | Android (Termux) | Opérationnel |
| **Distribution conteneur**| Ubuntu 26.04.1 LTS (Resolute Raccoon) | Vérifié |
| **Noyau Linux** | `6.17.0-PRoot-Distro #1 SMP PREEMPT_DYNAMIC` | Vérifié |
| **Architecture CPU** | `aarch64` (ARM 64-bit) | Vérifié |
| **Emplacement de travail**| `/root/BETSOCCER` | Vérifié |

---

## 2. OUTILS DE DÉVELOPPEMENT FLUTTER ET DART

L'environnement dispose de la pile Flutter/Dart stable à jour.

```bash
flutter --version
Dart SDK version: 3.13.5 (stable) (Tue Sep 29 01:00:52 2026 -0700) on "linux_arm64"
Flutter 3.47.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision abaf9c5237 (5 days ago) • 2026-10-08 09:51:21 -0700
Engine • hash d8a2d6c768c334d53e16277f837970ffa1e2de81 (revision deb287481e)
```

- **Flutter SDK :** 3.47.7 (Channel stable) installé dans `/opt/flutter`.
- **Dart SDK :** 3.13.5 (linux_arm64).
- **Capacité de test local :** `flutter test` et `dart analyze` sont 100% fonctionnels et ne requièrent aucun émulateur ni SDK graphique.
- **Drapeaux de fonctionnalités :** Support natif web, linux desktop, et compilation AOT Dart.

---

## 3. CHAÎNE ANDROID, JAVA ET GRADLE

- **Java Development Kit (JDK) :**
  - Version : `openjdk 17.0.20.1 2026-08-18` (Ubuntu build 17.0.20.1+1-1-26.04-Ubuntu).
  - Compilateur : `javac 17.0.20.1`.
  - Variable `JAVA_HOME` : `/usr/lib/jvm/java-17-openjdk-arm64` (configurée et valide).
- **Gradle :**
  - Non installé sous forme de paquet global autonome (`which gradle` -> absent).
  - *Conséquence :* Conforme aux bonnes pratiques Flutter, où le `gradle-wrapper` (`gradlew`) est autogénéré par le template Flutter ou exécuté dans le pipeline CI.
- **Android SDK (Local) :**
  - `ANDROID_HOME` et `ANDROID_SDK_ROOT` : non définis dans l'environnement PRoot.
  - Outil `adb` : accessible depuis l'hôte Termux (`/data/data/com.termux/files/usr/bin/adb`).
  - *Diagnostic & Décision :* L'environnement PRoot sous aarch64 présente des contraintes de mémoire et de virtualisation qui rendent l'installation d'un Android SDK lourd et instable. **Conformément aux règles du projet, aucun SDK Android complet n'est installé localement.** La compilation des binaires APK et AAB est expressément déléguée au runner GitHub Actions (`ubuntu-latest`).

---

## 4. CONTRÔLE DE VERSION ET OUTILS CLI GITHUB

- **Git :**
  - Version : `/usr/bin/git` opérationnel.
  - Identité globale : `user.name = Anisghd-lab`, `user.email = M_ghediri@yahoo.com`.
  - Branche par défaut : `main`.
- **GitHub CLI (`gh`) :**
  - Binaire : `/data/data/com.termux/files/usr/bin/gh` (version 2.100.0).
  - Authentification : Compte actif `frechfanta-os` configuré dans `/root/.config/gh/hosts.yml`.
  - Jeton OAuth : Vérifié, actif, doté de tous les scopes requis sur le dépôt `frechfanta-os/BETSOCCER`.
  - Droits sur le dépôt : `admin: true`, `push: true`, `pull: true`.

---

## 5. OUTILS D'APPUI (NODE.JS, PYTHON, SQLITE)

- **Node.js & npm :**
  - Node.js : `v22.22.1`.
  - npm : `9.2.0`.
  - Utilité : Permet l'exécution éventuelle d'outils de formatage, de scripts de validation de schémas OpenAPI/JSON, ou du CLI Cloudflare `wrangler` si nécessaire.
- **Python :**
  - Version : `Python 3.14.4`.
  - Utilité : Scripts d'automatisation, parsing de jeux de données historiques, validation d'algorithmes statistiques.
- **SQLite :**
  - Module Python `sqlite3` : intégré et disponible.
  - Client binaire `sqlite3` CLI : non installé (non indispensable car géré via Dart/Drift).

---

## 6. AUDIT DES ACCÈS AUX SERVICES TIERS (INSTRUCTION PRIORITAIRE)

### 6.1. GitHub
- **Accès existant détecté :** **OUI**.
- **Authentification fonctionnelle :** **OUI** (Validée par appel `GET /user` -> `login: frechfanta-os`).
- **Permissions disponibles :** **Lecture et Écriture complètes** (admin, push, pull, triage).
- **Vérifications réellement exécutées :**
  - `gh auth status` (Authentification vérifiée sans divulgation).
  - Appel API REST sur `https://api.github.com/repos/frechfanta-os/BETSOCCER`.
  - Test de clonage distant dans `/root/BETSOCCER`.
- **Limites et blocages :** Aucun. Accès 100% nominal.

### 6.2. OpenRouter
- **Accès existant détecté :** **OUI** (Variable d'environnement `OPENROUTER_API_KEY` présente, longueur 73 caractères).
- **Authentification fonctionnelle :** **OUI** (Appel sécurisé `GET /api/v1/auth/key` -> statut HTTP 200).
- **Profil de compte et Quotas :**
  - Label de clé : `sk-or-v1-ca9...dea` (masqué).
  - Usage actuel : 0.
  - Limite de crédit : 50.
  - Type de compte : `is_free_tier = True`.
- **Modèles disponibles :**
  - 461 modèles au total recensés sur le catalogue.
  - **19 modèles gratuits (:free)** utilisables sans décompte de facturation.
- **Vérifications réellement exécutées :**
  - Test d'authentification sans journalisation de la clé.
  - Test d'inférence en direct avec retour JSON structuré sur le modèle `nvidia/nemotron-3.5-lightning:free`. Temps de réponse ~20s, sortie JSON valide respectant les contraintes statistiques.
- **Limites et blocages :** Taux de requêtes des modèles gratuits sujet à de potentielles files d'attente (nécessité de mettre en œuvre une chaîne de repli / fallback).

---

## 7. MATRICE DE FAISABILITÉ DANS CET ENVIRONNEMENT

| Tâche de développement | Environnement d'exécution | Statut de faisabilité | Justification |
| :--- | :--- | :--- | :--- |
| **Architecture & Modélisation Dart** | Local (PRoot) | VALIDÉ | Dart SDK 3.13.5 natif |
| **Développement UI Flutter** | Local (PRoot) | VALIDÉ | Flutter 3.47.7 stable |
| **Tests unitaires et domaine** | Local (PRoot) | VALIDÉ | `flutter test` fonctionne sans GUI |
| **Analyse statique et linter** | Local (PRoot) | VALIDÉ | `dart analyze` / `flutter analyze` |
| **Validation SQLite locale** | Local (PRoot) | VALIDÉ | Dart FFI / Drift test in-memory |
| **Validation des prompts IA** | Local (PRoot) | VALIDÉ | Clé OpenRouter active et testée |
| **Compilation de l'APK Release** | Distant (GitHub Actions)| VALIDÉ | Pas de SDK Android local requis |
| **Déploiement OTA / Releases** | Distant (GitHub Actions)| VALIDÉ | Conforme à la directive `/root/AGENTS.md` |

---

## 8. CONCLUSION DE L'ÉTAPE B

L'environnement de développement est parfaitement qualifié et dimensionné pour le projet BETSOCCER. La séparation claire entre les tests/analyses locaux (rapides, légers) et la compilation mobile sur GitHub Actions assure une stabilité absolue sans surcharger l'espace de stockage Termux.
