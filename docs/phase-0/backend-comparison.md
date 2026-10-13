# BETSOCCER — ÉTUDE COMPARATIVE DES SOLUTIONS BACKEND (PHASE 0)

**Date d'audit :** 13 Octobre 2026  
**Auteur :** Ingénieur Backend & Architecte Systèmes Distribués  
**Projet :** BETSOCCER — Multisport Analytics AI  
**Statut :** ANALYSE COMPARATIVE ET RECOMMANDATION VALIDÉE

---

## 1. CONTEXTE ET ENJEUX

La conception du système BETSOCCER soulève une question d'architecture critique : **faut-il déployer un backend serveur dédié dès le départ, ou concevoir une application mobile autonome (Offline-First) capable de tout traiter localement ?**

Pour répondre aux contraintes du projet (zéro coût obligatoire, respect de l'environnement PRoot/Android, robustesse sans maintenance serveur complexe), quatre options architecturales sont rigoureusement comparées.

---

## 2. COMPARAISON DÉTAILLÉE DES 4 OPTIONS ARCHITECTURALES

### Option 1 : Application locale autonome avec SQLite (Offline-First)
- **Description :** L'intégralité de la logique métier, du stockage des données (`drift` sur SQLite) et du moteur de calculs statistiques (Poisson, Dixon-Coles, Elo) tourne directement dans l'application Flutter sur l'appareil de l'utilisateur. L'application interroge directement les API de données et OpenRouter via ses connecteurs HTTP.
- **Avantages :**
  - **Coût serveur :** Strictement **0,00 €**.
  - **Maintenance serveur :** Nulle (aucun serveur à superviser, patcher ou redémarrer).
  - **Latence :** Immédiate pour les calculs statistiques et l'accès à l'historique.
  - **Mode hors-ligne :** Parfaitement opérationnel grâce au socle SQLite préchargé avec `openfootball`.
  - **Indépendance :** Aucun risque de fermeture de service backend externe.
- **Limites :**
  - Si l'utilisateur n'a pas de serveur proxy, la clé API OpenRouter ou Football-Data.org doit être soit configurée au build, soit saisie par l'utilisateur (mode BYOK - Bring Your Own Key).
  - Chaque client consomme son propre quota d'appels API auprès des fournisseurs tiers (pas de mutualisation du cache entre utilisateurs).

---

### Option 2 : Cloudflare Workers avec KV / D1 / R2 (Serverless Edge)
- **Description :** Un micro-service d'orchestration et de mise en cache déployé sur le réseau mondial Cloudflare (V8 isolates en JavaScript/TypeScript). Il centralise les appels aux API sportives, stocke les résultats en cache KV/D1, et protège les clés privées des API.
- **Avantages :**
  - **Quotas gratuits vérifiés :** 100 000 requêtes/jour gratuites sur Cloudflare Workers, 100 000 lectures/jour sur KV, 5 millions de lectures/jour sur Cloudflare D1.
  - **Sécurité des secrets :** Les clés OpenRouter et Football-Data.org restent enfermées dans les coffres de secrets Cloudflare (`wrangler secret`), sans jamais transiter dans l'APK client.
  - **Mutualisation du cache :** Une seule requête vers Football-Data.org sert à des milliers d'utilisateurs consultant le même match.
  - **Tâches planifiées :** Déclencheurs Cron natifs (Cloudflare Cron Triggers) pour rafraîchir les classements à intervalles réguliers.
- **Limites :**
  - Nécessite la configuration et le déploiement d'un projet Worker via le CLI `wrangler`.
  - Légère dépendance à l'écosystème Cloudflare.

---

### Option 3 : Backend Python dédié (FastAPI + Celery + PostgreSQL / SQLite)
- **Description :** Un serveur backend classique conteneurisé (Docker) exécutant une API Python (FastAPI) pour effectuer le scraping, les calculs matriciels (NumPy, SciPy) et la persistance dans PostgreSQL.
- **Avantages :**
  - Richesse de l'écosystème scientifique Python pour les modèles de machine learning avancés.
  - Tâches de fond puissantes via Celery/Redis.
- **Limites :**
  - **Coût d'hébergement :** Nécessite un VPS ou un PaaS actif 24h/24 (coût mensuel dès la sortie des petits paliers d'essai).
  - **Complexité DevOps :** Gestion de conteneurs, certificats SSL, reverse proxy Nginx, base de données managée, sauvegardes.
  - **Inadéquation PRoot :** L'hébergement local permanent sur un appareil mobile sous PRoot n'est pas viable pour un service de production.

---

### Option 4 : Architecture Hybride (Recommandée)
- **Description :**
  1. **Noyau Client Flutter (Socle Prioritaire du MVP) :** L'application mobile est conçue pour être **100% autonome et fonctionnelle par elle-même**. Elle embarque la base SQLite locale, son moteur statistique natif en Dart pur et ses repositories de données. Elle gère son propre cache local et fonctionne intégralement en mode déconnecté.
  2. **Passerelle Edge Cloudflare (Couche Optimale Facultative) :** Un Worker Cloudflare léger peut être déployé en complément pour jouer le rôle de proxy de cache partagé et de protection des clés d'API. L'application mobile sait basculer automatiquement entre le mode direct et le mode proxy.

---

## 3. MATRICE COMPARATIVE MULTICRITÈRES

| Critère d'évaluation | Option 1 : Local SQLite | Option 2 : Cloudflare Workers | Option 3 : Backend Python | Option 4 : Hybride (Recommandée) |
| :--- | :--- | :--- | :--- | :--- |
| **Coût d'infrastructure** | **0 € (Zéro)** | **0 € (Tier gratuit)** | 5 € à 20 € / mois | **0 € garanti** |
| **Persistance des données** | SQLite local (client) | D1 / KV (Edge) | PostgreSQL dédié | **SQLite local + Cache Edge** |
| **Fonctionnement hors-ligne** | **100% autonome** | Non (dépend de la connexion)| Non | **100% autonome** |
| **Calculs statistiques** | Local (Dart pur) | Edge (V8 JS) | Serveur (Python NumPy)| **Local en Dart pur** |
| **Gestion des secrets API** | BYOK ou Dart-define | Secret Vault distant | Fichier `.env` serveur | **Sécurisée (double mode)** |
| **Tâches planifiées (Cron)** | Tâches de fond locales | Cron Triggers natifs | Celery Beat / Cron | **Cron Edge optionnel** |
| **Effort de maintenance** | **Négligeable** | Faible | Élevé | **Très faible** |
| **Risque de Vendor Lock-in** | **Nul** | Modéré | Modéré | **Nul (client découplé)** |

---

## 4. RECOMMANDATION FINALE D'ARCHITECTURE

L'équipe d'architecture retient formellement l'**Option 4 (Architecture Hybride centrée sur le client Offline-First)** :

1. **Pour le MVP (Phase 1 à 3) :**
   - Aucune dépendance serveur obligatoire.
   - Le moteur statistique est développé en **Dart pur** (indépendant de tout framework ou serveur).
   - Le stockage repose sur **SQLite via Drift**.
   - Cela garantit une livraison rapide, robuste, économique et testable immédiatement sur PRoot et GitHub Actions.
2. **Pour le passage à l'échelle (Phase 4+) :**
   - Possibilité d'activer la passerelle Cloudflare Worker via une simple URL d'API de configuration pour masquer les quotas d'API et partager le cache entre utilisateurs, sans jamais modifier le code métier de l'application mobile.
