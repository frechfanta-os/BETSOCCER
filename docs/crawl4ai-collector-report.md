# BETSOCCER — Rapport Technique : Collecteur Autonome Crawl4AI

Date d'audit et d'exécution : **13 Octobre 2026**  
Projet : **BETSOCCER — Multisport Analytics AI**  
Dépôt : `https://github.com/frechfanta-os/BETSOCCER`  
Moteur de collecte : **Crawl4AI v0.9.4** (`unclecode/crawl4ai`)  
Base de données : **SQLite local (`betsoccer.db`)**  
Statut : **Validé & Opérationnel**

---

## 1. Objectif & Périmètre

L'objectif de cette mission est de doter **BETSOCCER** d'un collecteur de données sportives autonome, robuste et conforme aux licences, s'exécutant dans l'environnement cible (**Termux + Ubuntu PRoot**), basé sur la bibliothèque open-source **Crawl4AI**.

### Principes Directeurs
1. **Zéro date codée en dur** : Tous les calculs de saison (`get_current_season_year`, `get_current_season_label`) et de fenêtres de matchs sont dynamiques et basés sur l'horloge système UTC (`datetime.now(timezone.utc)`).
2. **Alignement 100% avec le schéma Flutter** : Le collecteur utilise exactement le schéma relationnel de `V1InitialSchema.dart` (10 tables relationnelles), permettant à l'application mobile Flutter et au collecteur de partager la même base SQLite.
3. **Déduplication stricte** : Contrainte d'unicité composite `UNIQUE(competition_id, home_team_id, away_team_id, utc_kickoff)` empêchant toute duplication de rencontres lors des cycles successifs.
4. **Conformité & Politique d'accès** :
   - **MelBet** : Maintenu strictement à l'état `DISABLED_BY_POLICY` (aucun scraping non autorisé, respect des CGU et de la déontologie).
   - Aucune tentative de contournement anti-bot ou CAPTCHA sur des sources fermées.
   - Collecte concentrée sur les sources ouvertes et autorisées : **OpenLigaDB**, **Football-Data.co.uk (Fixtures)** et **TheSportsDB (V1 Test)**.

---

## 2. Architecture du Collecteur

Le sous-système de collecte autonome est organisé dans le dossier `collector/` :

```
collector/
├── config.py                          # Calculs dynamiques de dates/saisons, CollectorConfig
├── models.py                          # Dataclasses normalisées (Sport, Comp, Season, Team, Match, Result, Stat)
├── db.py                              # SQLite DatabaseManager (10 tables V1, FK ON, idempotence, stats)
├── collector.py                       # AutonomousCollector orchestrant AsyncWebCrawler & sources
├── main.py                            # CLI d'exécution (--once, --dry-run, --verify, --interval, --db)
├── sources/
│   ├── base.py                        # BaseSource avec retries exponentiels, rate limiting & file streaming
│   ├── openligadb_source.py           # Connecteur OpenLigaDB (BL1, BL2, Handball HBL, Volleyball VBLF1)
│   ├── footballdata_fixtures_source.py# Connecteur Football-Data.co.uk (Fixtures CSV en temps réel)
│   └── thesportsdb_source.py          # Connecteur TheSportsDB (Catalogues multisports & événements EPL)
└── tests/
    ├── __init__.py
    └── test_collector.py              # Suite de 11 tests unitaires automatisés
```

---

## 3. Procédure d'Installation (Termux + Ubuntu PRoot)

Dans l'environnement de développement PRoot (Python 3.14+ avec PEP 668), l'installation est isolée dans un environnement virtuel dédié :

### Commandes Exactes

```bash
# 1. Se positionner à la racine du dépôt BETSOCCER
cd /root/BETSOCCER

# 2. Créer l'environnement virtuel Python
python3 -m venv collector/.venv --system-site-packages

# 3. Activer l'environnement virtuel
source collector/.venv/bin/activate

# 4. Installer Crawl4AI et dépendances
pip install --no-cache-dir crawl4ai beautifulsoup4

# 5. Installer le navigateur Chromium pour Playwright (si requis)
python3 -m playwright install --with-deps chromium

# 6. Exécuter la suite de tests unitaires
python3 -m unittest discover -s collector/tests

# 7. Lancer un cycle de collecte unique
python3 -m collector.main --once --db /root/BETSOCCER/betsoccer.db

# 8. Vérifier les données ingérées dans la base SQLite
python3 -m collector.main --verify --db /root/BETSOCCER/betsoccer.db
```

---

## 4. Résultats Mesurés & Données Réelles

Deux cycles de collecte réels ont été exécutés avec succès contre les sources en direct le 13/10/2026 :

### 1. Synthèse du Cycle de Collecte en Direct

| Source / Provider | Sport / Périmètre | Protocole | Temps d'exécution | Statut | Enregistrements Synchronisés |
|---|---|---|---|---|---|
| **OpenLigaDB** | Football (BL1, BL2), Handball (HBL), Volleyball (VBLF1) | Crawl4AI REST | 8.23s | **SUCCESS** | 28 matchs |
| **Football-Data.co.uk** | Football européen (Rencontres du jour & cotes) | Crawl4AI Fixtures | 1.39s | **SUCCESS** | 14 matchs |
| **TheSportsDB** | Catalogue Multisport & Premier League | Crawl4AI V1 API | 3.82s - 23.2s | **SUCCESS** | 15 matchs |
| **MelBet** | Multisport propriétaire | Verrou politique | 0.00s | **DISABLED_BY_POLICY** | 0 (Désactivé) |

### 2. État Réel de la Base SQLite (`betsoccer.db`)

Après synchronisation et déduplication automatique :
- **Sports actifs** : **4** (Football, Handball, Volleyball, Basketball)
- **Compétitions** : **8** (1. Bundesliga, 2. Bundesliga, Handball HBL, 1. VBL Frauen, English Premier League, etc.)
- **Équipes enregistrées** : **103**
- **Matchs stockés** : **57**
- **Résultats détaillés** : **34** (scores finaux et scores mi-temps)
- **Statistiques de match** : **32** (cotes Bet365, arbitres, tirs cadrés)
- **Journalisation d'état (`sync_state`)** : 100% des runs audités avec horodatage ISO-8601 UTC et volume synchronisé.

### 3. Validation de l'Idempotence & Déduplication
Lors de la réexécution consécutive du cycle sur la même base `betsoccer.db` :
- Les 28 matchs OpenLigaDB ont été mis à jour sans créer aucun doublon.
- Les 14 matchs Football-Data ont été réconciliés sans aucun doublon.
- La contrainte `UNIQUE(competition_id, home_team_id, away_team_id, utc_kickoff)` a validé 100% des cas limites.

---

## 5. Validation Qualité & Non-Régression

1. **Tests unitaires du collecteur Python** :
   ```
   Ran 11 tests in 1.405s - OK (100% succès)
   ```
   - Validation du calcul dynamique des saisons et années UTC (octobre vs mars).
   - Validation de l'intégrité référentielle FK (`PRAGMA foreign_keys = ON;`).
   - Validation de la déduplication et mise à jour de statut (`upcoming` -> `finished`).
   - Validation du parsing OpenLigaDB et Football-Data CSV.

2. **Tests unitaires & widgets Flutter** :
   ```
   00:02 +25: All tests passed! (25/25 tests passés)
   ```
   - Respect absolu de l'architecture existante de BETSOCCER.
   - Aucun composant Flutter endommagé ou régressé.

3. **Analyse statique Dart/Flutter** :
   ```
   Analyzing BETSOCCER... No issues found! (0 lint errors)
   ```

---

## 6. Limites Documentées & Recommandations

1. **Quotas et délais de courtoisie** :
   - Un délai minimal de 1.0 seconde (`rate_limit_delay_seconds`) est imposé entre chaque requête pour respecter les serveurs des fournisseurs publics.
   - Un mécanisme de backoff exponentiel (1.5x) relance automatiquement les requêtes en cas de micro-coupure réseau.
2. **TheSportsDB V1 Test Key** :
   - La clé de test publique `"3"` est soumise à une latence occasionnelle plus élevée sur certains endpoints de métadonnées. L'extraction asynchrone Crawl4AI gère ce délai avec un timeout de 20s.
3. **Transition vers la Phase 2 (Moteur Statistique)** :
   - La base locale `betsoccer.db` contient désormais une source de données réelle et fraîche couvrant 4 sports avec calendriers, résultats et cotes, prête à alimenter les modèles statistiques (Poisson, Elo, xG).
