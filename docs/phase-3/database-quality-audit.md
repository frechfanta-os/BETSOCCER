# BETSOCCER — Phase 3 : Audit de Qualité de la Base de Données Sportive

**Date de validation :** 14 Octobre 2026  
**Environnement :** Linux / Ubuntu PRoot / SQLite 3  
**Base de données auditée :** `betsoccer.db`  
**Dépôt officiel :** `https://github.com/frechfanta-os/BETSOCCER`  

---

## 1. Contexte & Objectifs de l'Audit

À l'issue de la Phase 2.1, l'audit scientifique avait démontré la validité mathématique du Moteur Statistique (Dixon-Coles Poisson et Elo dynamique), mais avait mis en évidence la **taille restreinte de l'échantillon historique** présent dans `betsoccer.db` (57 matchs au total, dont seulement 34 matchs terminés avec score valide).

La mission de la Phase 3 consiste à auditer rigoureusement l'intégrité relationnelle de `betsoccer.db`, à éradiquer tout risque de collision ou de rupture de clé étrangère, et à enrichir massivement la couverture historique sur des sources ouvertes et officielles vérifiées, sans jamais fabriquer la moindre donnée ni compromettre la stricte causalité temporelle (`kickoff < target_match`).

---

## 2. Audit Préalable de l'État Initial (Avant Ingestion Phase 3)

### 2.1 Inventaire Quantitatif Initial
- **Matchs au total :** 57 (34 terminés, 23 à venir)
- **Compétitions :** 8
- **Équipes :** 103
- **Sports :** 4 (Football, Handball, Volleyball, Basketball)
- **Résultats enregistrés :** 34
- **Statistiques de match :** 32

### 2.2 Répartition Initiale par Compétition
| Compétition | Sport | Statut | Nombre de Matchs |
| :--- | :--- | :--- | :--- |
| `comp_old_bl1` (1. Bundesliga) | Football | finished | 9 (1 seule journée) |
| `comp_old_bl2` (2. Bundesliga) | Football | finished | 9 (1 seule journée) |
| `comp_tsdb_4328` (Premier League) | Football | finished | 15 |
| `comp_old_vblf1` (Volleyball Bundesliga) | Volleyball | finished | 1 |
| `comp_old_hbl` (Handball Bundesliga) | Handball | upcoming | 9 |
| `comp_fduk_e1` (Championship) | Football | upcoming | 12 |
| `comp_fduk_e2` (League 1) | Football | upcoming | 1 |
| `comp_fduk_sc1` (Division SC1) | Football | upcoming | 1 |

### 2.3 Vulnérabilités et Anomalies Détectées
1. **Risque critique de collision sur l'unicité des équipes (`UNIQUE(sport_id, name)`) :**
   Dans SQLite, la table `teams` impose une contrainte d'unicité sur `(sport_id, name)`. Si une source externe tente d'insérer une équipe (ex: `team_arsenal`) alors qu'elle existe déjà sous une autre clé (ex: `team_arsenal_fc`), un simple `INSERT OR IGNORE` échoue silencieusement. Dès lors, le `home_team_id` référencé dans `matches` ne pointe vers aucune ligne existante, provoquant une violation fatale de clé étrangère (`FOREIGN KEY constraint failed`).
2. **Profondeur historique insuffisante pour l'apprentissage statistique :**
   Avec seulement 33 matchs de football terminés, le modèle de Poisson Dixon-Coles devait s'appuyer quasi-exclusivement sur le shrinkage bayésien vers la moyenne de la ligue en raison du manque de confrontations passées.
3. **Statistiques détaillées restreintes :**
   Seuls les matchs de TheSportsDB disposaient de quelques métriques de buts ; aucune statistique avancée (tirs, tirs cadrés, corners, fautes, cartons, arbitre) n'était disponible pour les autres ligues.

---

## 3. Mesures de Correction et Améliorations Apportées

### 3.1 Résolution Canonique des Équipes (`_resolve_team_id`)
Une fonction de résolution d'équipe idempotente et tolérante aux multi-sources a été intégrée dans `collector/db.py` :
```python
def _resolve_team_id(self, conn, sport_id, team_id, team_name, source_provider, now_iso) -> str:
    # 1. Vérifie si le nom d'équipe existe déjà pour ce sport
    row = conn.execute("SELECT id FROM teams WHERE sport_id = ? AND name = ?;", (sport_id, team_name)).fetchone()
    if row:
        return row["id"]
    # 2. Vérifie si l'ID d'équipe existe déjà
    row_by_id = conn.execute("SELECT id FROM teams WHERE id = ?;", (team_id,)).fetchone()
    if row_by_id:
        return row_by_id["id"]
    # 3. Insertion sûre
    conn.execute("INSERT INTO teams (id, sport_id, name, source_provider, created_at) VALUES (?, ?, ?, ?, ?);",
                 (team_id, sport_id, team_name, source_provider, now_iso))
    return team_id
```
Cette résolution garantit que toutes les clés étrangères (`matches.home_team_id`, `matches.away_team_id`, `results.winner_team_id`) pointent vers un enregistrement réel et unique.

### 3.2 Ingestion des Saisons Historiques Complètes
- **OpenLigaDB :** Collecte automatisée de la saison complète 2023/24 pour `bl1` (306 matchs), `bl2` (306 matchs), `hbl` (278 matchs de handball) et `vblf1` (18 matchs de volleyball).
- **Football-Data.co.uk :** Ingestion directe des archives CSV officielles 2023/24 pour la Premier League anglaise (`E0`, 380 matchs) et La Liga espagnole (`SP1`, 380 matchs).

---

## 4. Métriques de Santé et Audit Post-Synchronisation

L'inspection de la base `betsoccer.db` après exécution complète du collecteur donne les résultats probants suivants :

### 4.1 Contrôles d'Intégrité SQLite
```bash
sqlite3 betsoccer.db "PRAGMA integrity_check;"
--> [('ok',)]

sqlite3 betsoccer.db "PRAGMA foreign_key_check;"
--> [] (0 violation constatée sur l'ensemble des 1 724 matchs et tables associées)
```

### 4.2 Totaux Globaux après Ingestion Phase 3
| Entité Relationnelle | Quantité Initiale | Quantité Phase 3 | Facteur d'Augmentation |
| :--- | :--- | :--- | :--- |
| **Sports** | 4 | **4** | Identique (structure préservée) |
| **Compétitions** | 8 | **10** | +25% |
| **Équipes** | 103 | **142** | +37.8% |
| **Matchs au total** | 57 | **1 724** | **x30.2** |
| **Matchs terminés avec score** | 34 | **1 643** | **x48.3** |
| **Matchs à venir (Fixtures)** | 23 | **81** | **x3.5** |
| **Résultats détaillés (avec mi-temps)** | 34 | **1 643** | **x48.3** |
| **Statistiques avancées de match** | 32 | **5 794** | **x181.0** |

### 4.3 Répartition Précise par Sport & Statut
```
  Handball             | Status: finished   | Count: 220
  Handball             | Status: upcoming   | Count: 58
  Soccer (Football)    | Status: finished   | Count: 1405
  Soccer (Football)    | Status: upcoming   | Count: 23
  Volleyball           | Status: finished   | Count: 18
  Total                |                    | Count: 1 724
```

### 4.4 Répartition Précise par Compétition
| Compétition | Sport | Matchs Terminés | Matchs à Venir | Total Matchs | Source Principale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **English Premier League** | Football | **395** | 0 | 395 | Football-Data.co.uk + TSDB |
| **La Liga** | Football | **380** | 0 | 380 | Football-Data.co.uk |
| **1. Bundesliga** | Football | **315** | 0 | 315 | OpenLigaDB |
| **2. Bundesliga** | Football | **315** | 9 | 324 | OpenLigaDB |
| **Handball Bundesliga (HBL)** | Handball | **220** | 58 | 278 | OpenLigaDB |
| **Championship** | Football | 0 | 12 | 12 | Football-Data Fixtures |
| **1. Volleyball Bundesliga** | Volleyball | **18** | 0 | 18 | OpenLigaDB |
| **Division SC1** | Football | 0 | 1 | 1 | Football-Data Fixtures |
| **League 1** | Football | 0 | 1 | 1 | Football-Data Fixtures |
| **Total** | | **1 643** | **81** | **1 724** | Multi-connecteurs |

### 4.5 Statistiques Avancées Capturées (5 794 enregistrements)
- `shots` : tirs totaux domicile / extérieur
- `shots_on_target` : tirs cadrés domicile / extérieur
- `corners` : corners concédés et obtenus
- `fouls` : fautes commises
- `yellow_cards` : cartons jaunes
- `red_cards` : cartons rouges
- `referee_assigned` : arbitre officiel de la rencontre
- `total_goals` : détails des buteurs et minutes de jeu (OpenLigaDB)

---

## 5. Synthèse & Verdict

| Critère d'Évaluation | Exigence Phase 3 | Constat Réel | Statut |
| :--- | :--- | :--- | :--- |
| **Intégrité SQLite** | 0 erreur, foreign_keys actives | `ok`, 0 violation | **CONFORME** |
| **Absence de doublons** | Dédoublonnage composite strict | 0 doublon | **CONFORME** |
| **Volume de données réelles** | Augmentation significative | 1 643 terminés, 1 724 total | **CONFORME** |
| **Absence de données fabriquées** | 100% données vérifiées | Toutes issues des flux réels | **CONFORME** |
| **Verrou éthique MelBet** | Strictly DISABLED_BY_POLICY | Aucun flux, 0 enregistrement | **CONFORME** |

**Verdict de l'Audit : VALIDÉ (PASS)**. La base `betsoccer.db` est parfaitement saine, normalisée et prête à alimenter les modèles d'analyse descriptive et prédictive de BETSOCCER.
