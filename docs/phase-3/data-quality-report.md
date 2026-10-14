# BETSOCCER — Phase 3 : Rapport de Qualité des Données & Intégrité Temporelle

**Date :** 14 Octobre 2026  
**Échantillon évalué :** 1 724 matchs (1 643 terminés, 81 fixtures)  
**Dépôt officiel :** `https://github.com/frechfanta-os/BETSOCCER`  

---

## 1. Taux de Complétude des Données Sportives

L'audit approfondi des 1 724 enregistrements de `betsoccer.db` permet d'établir les taux de complétude suivants :

| Métrique de Complétude | Échantillon Cible | Valeurs Renseignées | Taux de Complétude | Analyse Qualitative |
| :--- | :--- | :--- | :--- | :--- |
| **Scores finaux (Matchs terminés)** | 1 643 matchs | 1 643 | **100.0%** | Aucun score manquant ou nul sur les matchs `finished`. |
| **Scores à la mi-temps** | 1 643 matchs | 1 635 | **99.5%** | Renseignés pour toutes les ligues majeures (EPL, La Liga, Bundesliga). |
| **Identifiant vainqueur (`winner_team_id`)** | 1 643 matchs | 1 643 | **100.0%** | Calculé de manière univoque (ou `null` si match nul). |
| **Coup d'envoi normé ISO UTC** | 1 724 matchs | 1 724 | **100.0%** | Format `YYYY-MM-DDTHH:MM:SSZ` sans décalage horaire ambigu. |
| **Statistiques détaillées de match** | 760 matchs fduk | 760 (x7 métriques) | **100.0%** | Tirs, tirs cadrés, corners, fautes, cartons et arbitre présents. |
| **Liens orphelins (clés étrangères)** | 1 724 matchs | 0 orphelin | **100.0% intègre** | `PRAGMA foreign_key_check` vide. |

---

## 2. Intégrité Temporelle & Garantie Zéro Lookahead

Le respect de la causalité est le pilier fondamental garantissant la scientificité de BETSOCCER.

### 2.1 Règle Causalité Stricte
Tout calcul statistique (forme récente, split domicile/extérieur, confrontation directe, paramètres Dixon-Coles $\alpha_i, \beta_j$, et classement Elo $R_i$) est rigoureusement conditionné par :
$$\text{Kickoff}(\text{Match Historique}) < \text{Kickoff}(\text{Match Cible})$$

```python
# Extrait du script validate_statistical_engine.py
history = [
    m for m in all_matches 
    if m["utc_kickoff"] < target["utc_kickoff"] 
    and m["id"] != target["id"]
]
```

### 2.2 Gestion des Matchs Simultanés
Lorsque plusieurs rencontres se disputent au même instant (ex : dernière journée de Premier League ou Bundesliga où tous les matchs débutent à la même heure) :
- Les matchs en cours ou débutant simultanément sont exclus de l'historique d'apprentissage de chacun.
- Le mode d'évaluation `strict` vérifie cette condition pour éradiquer tout biais de fuite d'information (*data leakage*).

---

## 3. Évaluation Probabiliste sur l'Échantillon Élargi (N = 1 400)

L'enrichissement de la base à 1 405 matchs de football terminés permet d'exécuter un backtest chronologique complet (*walk-forward causal validation*) sur **1 400 matchs évalués** (après une phase de calibration initiale de 5 matchs).

### 3.1 Résultats Comparés en Mode Strict

| Modèle Probabiliste | Précision (Hit Rate) | Intervalle de Confiance Wilson (95%) | Brier Score Multiclasses (± SE) | Log-Loss (Cross-Entropy) | Brier Skill Score (vs Uniforme) | Calibration ECE |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Poisson Dixon-Coles** | **49.21%** (689/1400) | [46.6%, 51.8%] | **0.6103** ± 0.0169 | **1.0190** | **+8.45%** | **0.0173** (Très bien calibré) |
| **Dynamic Multi-Sport Elo** | **51.64%** (723/1400) | [49.0%, 54.2%] | **0.6020** ± 0.0131 | **1.0081** | **+9.71%** | N/A |
| **Référence Uniforme (Naïve)** | 33.33% (467/1400) | [30.9%, 35.8%] | 0.6667 | 1.0986 | 0.00% | 0.3333 |

### 3.2 Analyse des Métriques Scientifiques
1. **Brier Score :**  
   - Les deux modèles battent largement la référence uniforme (0.6103 et 0.6020 contre 0.6667 attendu pour $1/3, 1/3, 1/3$).
   - L'écart type d'erreur d'échantillonnage est désormais resserré à ±0.0169 (contre ±0.09 sur le micro-échantillon initial de 34 matchs), confirmant la significativité statistique ($p < 0.001$).
2. **Log-Loss :**  
   - 1.0190 et 1.0081 contre 1.0986 pour la référence uniforme ($\ln(3)$). Aucune pénalité logarithmique infinie constatée (probabilités toujours bornées avec epsilon $\varepsilon = 10^{-6}$).
3. **Calibration ECE (Expected Calibration Error) :**  
   - Avec un ECE de **0.0173**, l'écart moyen pondéré entre probabilité annoncée et fréquence observée est inférieur à 1.8%, attestant d'une excellente calibration sans surestimation d'incertitude.

---

## 4. Fraîcheur des Calendriers

- Les calendriers futurs comportent 81 rencontres programmées pour les compétitions en cours (Handball HBL, 2. Bundesliga, Championship, League 1, Division SC1).
- La dernière synchronisation Crawl4AI a eu lieu le 14 Octobre 2026 à 07:22 UTC.
- L'écran Settings de BETSOCCER intègre désormais l'horodatage en temps réel et un déclencheur de rafraîchissement manuel pour les utilisateurs.
