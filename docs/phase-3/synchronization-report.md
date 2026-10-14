# BETSOCCER — Phase 3 : Rapport de Synchronisation Automatisée & Preuve d'Idempotence

**Date de synchronisation :** 14 Octobre 2026  
**Moteur d'orchestration :** Crawl4AI (`AsyncWebCrawler`) + Python 3.14 venv  
**Base cible :** SQLite `betsoccer.db`  
**Dépôt officiel :** `https://github.com/frechfanta-os/BETSOCCER`  

---

## 1. Architecture du Collecteur Crawl4AI

Le collecteur autonome de BETSOCCER est conçu pour s'exécuter soit ponctuellement en tâche de fond (CLI / cron / bouton in-app), soit en boucle continue avec intervalle paramétrable.

```
       ┌─────────────────────────────────────────────────────────────┐
       │             BETSOCCER Autonomous Collector                  │
       │                   (collector/main.py)                       │
       └──────────────────────────────┬──────────────────────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            ▼                                                   ▼
┌───────────────────────────────┐               ┌───────────────────────────────┐
│     Crawl4AI Asynchronous     │               │    Direct Streaming HTTP      │
│   WebCrawler (HTML/JSON/JS)   │               │   (Large Open CSV Archives)   │
└───────────────┬───────────────┘               └───────────────┬───────────────┘
                │                                               │
        ┌───────┴───────────────────────┬───────────────────────┴───────┐
        ▼                               ▼                               ▼
┌───────────────┐               ┌───────────────┐               ┌───────────────┐
│  OpenLigaDB   │               │ Football-Data │               │  TheSportsDB  │
│  REST API     │               │  CSV Feeds    │               │  V1 API       │
└───────┬───────┘               └───────┬───────┘               └───────┬───────┘
        │                               │                               │
        └───────────────────────┬───────┴───────────────────────────────┘
                                ▼
            ┌───────────────────────────────────────┐
            │       Data Normalization Pipeline     │
            │   - Team Canonical Resolution         │
            │   - Zero-Lookahead Causal Validation  │
            │   - Multi-Sport Result Typing         │
            └───────────────────┬───────────────────┘
                                ▼
            ┌───────────────────────────────────────┐
            │    SQLite Idempotent Transaction      │
            │       ON CONFLICT DO UPDATE           │
            │   (matches, results, statistics)      │
            └───────────────────┬───────────────────┘
                                ▼
            ┌───────────────────────────────────────┐
            │          betsoccer.db (10 Tables)     │
            └───────────────────────────────────────┘
```

---

## 2. Robustesse Réseau et Tolérance aux Pannes

Le module `BaseSource` encapsule les mécanismes garantissant une haute fiabilité opérationnelle :
- **Nombre de tentatives maximal :** 3 essais automatiques par URL.
- **Backoff exponentiel :** Délai progressif calculé via $T_{sleep} = \text{delay} \times (\text{factor})^{attempt - 1}$ (facteur de temporisation = 1.5).
- **Limitation de débit (*Rate Limiting*) :** Pause minimale de 1,0 seconde entre les appels vers une même source pour respecter les serveurs hôtes.
- **Streaming haute performance :** Les fichiers CSV de grande taille (ex: saisons de 380 matchs) sont décodés en mémoire via un flux HTTP direct sans chargement de moteur Chromium superflu.

---

## 3. Dédoublonnage et Clés Composites

L'intégrité relationnelle et l'idempotence reposent sur 3 niveaux de contraintes SQL :

1. **Table `matches` :**
   ```sql
   UNIQUE(competition_id, home_team_id, away_team_id, utc_kickoff)
   ```
   Un match est identifié de façon univoque par sa compétition, ses deux adversaires et son heure de coup d'envoi en UTC. Tout ré-import met à jour le statut, les scores et la minute de jeu sans jamais créer de doublon.

2. **Table `teams` :**
   ```sql
   UNIQUE(sport_id, name)
   ```
   Résolution dynamique via `_resolve_team_id` : si une équipe existe déjà, son identifiant canonique primaire est conservé pour lier les rencontres et prévenir toute violation de clé étrangère.

3. **Tables `results` et `match_statistics` :**
   - `results` : `UNIQUE(match_id)`
   - `match_statistics` : `UNIQUE(match_id, metric_name)`

---

## 4. Preuve Expérimentale de Double Synchronisation & Idempotence

Conformément au protocole d'audit, deux cycles complets de synchronisation ont été consécutivement exécutés sur la même base `betsoccer.db`.

### 4.1 Chronogramme d'Exécution Réel
- **Cycle 1 (Enrichissement & Ingestion) :**  
  - Démarrage : 14 Octobre 2026 à 07:20:44 UTC  
  - Fin : 14 Octobre 2026 à 07:21:23 UTC  
  - Durée totale : **38,29 secondes**  
  - Enregistrements traités : 1 725  
- **Cycle 2 (Vérification formelle d'idempotence) :**  
  - Démarrage : 14 Octobre 2026 à 07:21:39 UTC  
  - Fin : 14 Octobre 2026 à 07:22:08 UTC  
  - Durée totale : **29,43 secondes**  
  - Enregistrements traités : 1 725  

### 4.2 Tableau Comparatif Avant / Après Cycle 1 / Après Cycle 2

| Métrique de la Base | État Initial (Phase 2.1) | Post-Cycle 1 (Phase 3) | Post-Cycle 2 (Idempotence) | Évolution Nette Cycle 2 vs Cycle 1 |
| :--- | :--- | :--- | :--- | :--- |
| **Sports** | 4 | 4 | 4 | **0 (Inchangé)** |
| **Compétitions** | 8 | 10 | 10 | **0 (Inchangé)** |
| **Équipes** | 103 | 142 | 142 | **0 (Inchangé)** |
| **Matchs au total** | 57 | 1 724 | 1 724 | **0 doublon (+0)** |
| **Matchs terminés** | 34 | 1 643 | 1 643 | **0 doublon (+0)** |
| **Résultats détaillés** | 34 | 1 643 | 1 643 | **0 doublon (+0)** |
| **Statistiques de match** | 32 | 5 794 | 5 794 | **0 doublon (+0)** |
| **Fournisseur : openligadb** | 28 | 935 | 935 | **0 doublon (+0)** |
| **Fournisseur : football_data** | 14 | 774 | 774 | **0 doublon (+0)** |
| **Fournisseur : thesportsdb** | 15 | 15 | 15 | **0 doublon (+0)** |
| **PRAGMA integrity_check** | `ok` | `ok` | `ok` | **Parfait** |
| **PRAGMA foreign_key_check** | `[]` | `[]` | `[]` | **0 violation** |

### 4.3 Conclusion sur l'Idempotence
Le second cycle s'est exécuté sans lever la moindre exception, avec un temps de traitement accéléré (29,4s contre 38,3s) grâce au cache d'adresses et à la mise à jour transactionnelle ciblée. Le delta net d'enregistrements est de **strictement zéro**, confirmant l'idempotence mathématique et structurelle du collecteur.
