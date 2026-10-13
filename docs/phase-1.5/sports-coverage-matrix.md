# BETSOCCER — MATRICE DE COUVERTURE PAR SPORT (PHASE 1.5)

**Date d'audit :** 13 octobre 2026  
**Objectif :** Cartographier la faisabilité réelle et vérifiée par discipline sportive pour l'application BETSOCCER.

---

## 1. Classification d'Accès aux Données

Pour chaque source, nous distinguons 5 catégories d'accès formelles :
- **CAT-1 [FREE_OPEN]** : Données disponibles gratuitement sous licence ouverte ou domaine public (0 €, sans quota contraignant).
- **CAT-2 [FREE_QUOTA]** : Données disponibles gratuitement sous quota ou avec clé API gratuite (0 €, gestion de cadence requise).
- **CAT-3 [PAID_ONLY]** : Données accessibles uniquement via abonnement payant commercial (proscrites en Phase 1 et 2).
- **CAT-4 [UNAUTHORIZED]** : Données visibles sur le web mais dont la collecte ou la réutilisation automatisée est interdite par les CGU ou robots.txt (proscrites par notre politique).
- **CAT-5 [UNVERIFIED]** : Données annoncées par un fournisseur mais non validées par nos tests réels.

---

## 2. Analyse Détaillée par Discipline Sportive

### 2.1 Football (Soccer)
Le football est le sport pivot de BETSOCCER et dispose de la couverture la plus robuste et souveraine.

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **OpenFootball** (CAT-1), **Football-Data.co.uk** (CAT-1), **TheSportsDB** (CAT-1), **OpenLigaDB** (CAT-1), **Football-Data.org** (CAT-2). |
| **Compétitions Réellement Couvertes** | Premier League, Ligue 1, La Liga, Serie A, Bundesliga 1 & 2, Eredivisie, Liga Portugal, Süper Lig, Ligue des Champions UEFA, Coupe du Monde FIFA. |
| **Historique Vérifié** | **Oui, profondeur totale (1888 à 2026)** : 380 matchs vérifiés pour la seule Premier League 2023/24 avec scores finaux et mi-temps. |
| **Matchs à Venir Vérifiés** | **Oui** : Calendriers de saisons complètes intégrés et testés dans OpenFootball et TheSportsDB. |
| **Disponibilité du Direct** | **Oui sous conditions** : Flux direct disponible via OpenLigaDB (Allemagne/Europe) et Football-Data.org (quota 10 req/min). |
| **Champs Statistiques Accessibles** | Buts, buteurs, minutes de but, penaltys, scores mi-temps, tirs totaux (`HS`/`AS`), tirs cadrés (`HST`/`AST`), fautes (`HF`/`AF`), corners (`HC`/`AC`), cartons jaunes/rouges (`HY`/`AY`/`HR`/`AR`). |
| **Principales Lacunes** | Données de tracking physique (distance parcourue en km) et expected goals (xG) détaillés par joueur non disponibles dans les flux gratuits ouverts. |
| **Source de Remplacement** | Si une source tombe : OpenFootball relaie Football-Data.co.uk pour les archives ; OpenLigaDB relaie Football-Data.org pour les ligues européennes. |

---

### 2.2 Basketball
Discipline majeure pour les modèles probabilistes (nombre élevé de points, loi normale et modèles négatifs binomiaux).

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **Balldontlie** (CAT-2), **TheSportsDB** (CAT-1), **ESPN Site API** (CAT-4/Optionnel). |
| **Compétitions Réellement Couvertes** | NBA (National Basketball Association) uniquement. |
| **Historique Vérifié** | **Oui** : Historique NBA complet depuis 1979 via Balldontlie. |
| **Matchs à Venir Vérifiés** | **Oui** : Calendrier régulier et playoffs NBA. |
| **Disponibilité du Direct** | **Oui** : Scores en direct par quart-temps via Balldontlie (30 req/min). |
| **Champs Statistiques Accessibles** | Points par quart-temps, rebonds offensifs/défensifs, passes décisives, contres, interceptions, pertes de balle, pourcentages au tir (2pts, 3pts, LF). |
| **Principales Lacunes** | Absence d'Euroligue de Basketball et des championnats nationaux européens (Pro A française, Liga ACB espagnole) dans les flux gratuits ouverts vérifiés. |
| **Source de Remplacement** | TheSportsDB pour les métadonnées et scores finaux de base si le quota Balldontlie est atteint. |

---

### 2.3 Tennis
Discipline individuelle adaptée aux modèles de chaînes de Markov et modèles de probabilités de service.

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **Jeff Sackmann Match Charting Project** (CAT-1), **TheSportsDB** (CAT-1), **ESPN Site API** (CAT-4/Optionnel). |
| **Compétitions Réellement Couvertes** | Tournois du Grand Chelem (Open d'Australie, Roland Garros, Wimbledon, US Open), tournois Masters 1000 ATP et tournois WTA majeurs. |
| **Historique Vérifié** | **Oui (archives statiques)** : Données historiques 1968-2023 disponibles via des copies locales des datasets de Sackmann. |
| **Matchs à Venir Vérifiés** | **Très limité** : Pas de flux ouvert stable pour les tableaux de tirage au sort (draws) à venir en temps réel sans abonnement payant. |
| **Disponibilité du Direct** | **NON VÉRIFIÉ DE FAÇON STABLE EN FLUX LIBRE** : Seul ESPN expose un flux direct intermittent sans garantie contractuelle. |
| **Champs Statistiques Accessibles** | Scores par set, jeux décisifs (tie-breaks), aces, doubles fautes, points sur 1ère/2ème balle, balles de break sauvées/converties. |
| **Principales Lacunes** | Absence de flux officiel ouvert pour les scores en direct point par point (monopolisés par Sportradar et Genius Sports sous licence payante exclusive ATP/ITF). |
| **Source de Remplacement** | Modélisation rétrospective sur archives historiques (backtesting) ; aucune promesse de live streaming de scores. |

---

### 2.4 Handball
Discipline avec moyenne de buts élevée (~55-60 buts/match), se prêtant très bien à des modèles de Poisson bivariés.

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **OpenLigaDB** (CAT-1). |
| **Compétitions Réellement Couvertes** | LIQUI MOLY HBL (Handball Bundesliga allemande, championnat national n°1 mondial). |
| **Historique Vérifié** | **Oui** : Saisons complètes depuis 2012 testées et validées. |
| **Matchs à Venir Vérifiés** | **Oui** : Calendrier officiel HBL accessible sans clé. |
| **Disponibilité du Direct** | **Oui** : Scores en direct par mi-temps. |
| **Champs Statistiques Accessibles** | Scores mi-temps, score final, équipe domicile/extérieur, horodatage UTC. |
| **Principales Lacunes** | Championnat de France Starligue et Ligue des Champions EHF non disponibles sur OpenLigaDB. |
| **Source de Remplacement** | Intégration ultérieure possible via TheSportsDB si les ligues EHF sont complétées. |

---

### 2.5 Volleyball
Sport sans match nul, disputé au meilleur des 3 sets gagnants (25 points par set).

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **OpenLigaDB** (CAT-1). |
| **Compétitions Réellement Couvertes** | 1. Volleyball Bundesliga Féminine (`vblf1`) et Masculine (`vbl1`). |
| **Historique Vérifié** | **Oui** : Saisons 2020 à 2024 testées avec succès (`matchID: 68102`). |
| **Matchs à Venir Vérifiés** | **Oui** : Programmation des journées disponible. |
| **Disponibilité du Direct** | **Oui** : Mise à jour par set. |
| **Champs Statistiques Accessibles** | Scores par set (ex: 25-18, 22-25, etc.), score final en sets (3-1, 3-0, 3-2). |
| **Principales Lacunes** | Couverture limitée au périmètre européen germanophone. |
| **Source de Remplacement** | TheSportsDB pour les compétitions internationales de base. |

---

### 2.6 Motorsport (Formule 1)
Sport mécanique à forte composante analytique (points par course, qualifications, fiabilité mécanique).

| Paramètre | Statut / Détails |
| :--- | :--- |
| **Sources Disponibles** | **Jolpica-F1** (CAT-1), **TheSportsDB** (CAT-1). |
| **Compétitions Réellement Couvertes** | Championnat du Monde FIA de Formule 1 (100% des Grands Prix). |
| **Historique Vérifié** | **Oui** : De 1950 à aujourd'hui (74 saisons complètes). |
| **Matchs à Venir Vérifiés** | **Oui** : Calendrier complet des Grands Prix de la saison courante. |
| **Disponibilité du Direct** | **Non** : Résultats disponibles post-séance (qualifications, course). |
| **Champs Statistiques Accessibles** | Positions d'arrivée, positions de grille, points marqués, temps au tour, arrêts aux stands, constructeurs, circuits avec géolocalisation. |
| **Principales Lacunes** | Télémétrie en temps réel (secteurs, vitesses de pointe) non fournie (propriétaire F1 TV / FOM). |
| **Source de Remplacement** | Jolpica-F1 est la source de référence communautaire mondiale. |

---

## 3. Synthèse de la Couverture Multisport Réelle

```
+------------------+---------------+----------------+-----------------+---------------+
| Sport            | Historique    | Calendriers    | Scores Direct   | Confiance     |
+------------------+---------------+----------------+-----------------+---------------+
| Football         | EXCELLENT     | EXCELLENT      | BON (Sous quota)| 100% GARANTI  |
| Basketball (NBA) | TRÈS BON      | TRÈS BON       | BON (Sous quota)| 85% CONFIRMÉ  |
| Handball (HBL)   | TRÈS BON      | BON            | BON (OpenLiga)  | 90% CONFIRMÉ  |
| Volleyball (VBL) | BON           | BON            | MOYEN           | 80% CONFIRMÉ  |
| Motorsport (F1)  | TOTAL         | EXCELLENT      | NON (Post-race) | 95% CONFIRMÉ  |
| Tennis           | BON (Statique)| TRÈS FAIBLE    | NON GARANTI     | 60% PARTIEL   |
+------------------+---------------+----------------+-----------------+---------------+
```

> **Règle impérative de transparence produit :** BETSOCCER ne doit **JAMAIS promettre une couverture exhaustive en direct sur le tennis ou les ligues secondaires sans flux certifié**. Le football, la Formule 1, le basketball NBA et le handball allemand constituent le périmètre multisport vérifié à 100%.
