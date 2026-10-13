# BETSOCCER — Phase 2 : Statistical Engine Architecture & Specification Report

**Date :** 13 Octobre 2026  
**Auteur :** Antigravity Senior Statistical & Data Engineer  
**Statut :** Livré & Validé  
**Dépôt :** https://github.com/frechfanta-os/BETSOCCER  
**Commit de base :** `ea1d327`

---

## 1. Contexte & Audit Préalable des Données Disponibles

Un audit d'intégrité exhaustif de la base locale [`betsoccer.db`](file:///root/BETSOCCER/betsoccer.db) a été conduit avant tout développement mathématique :

### 1.1 Inventaire Précis
- **Total des matchs :** 57 rencontres
  - **Matchs terminés avec résultats vérifiés (`finished`) :** 34
  - **Matchs à venir (`upcoming`) :** 23
- **Répartition par sport :**
  - **Football (`sport_football`) :** 47 matchs (33 terminés, 14 à venir).
  - **Handball (`sport_handball`) :** 9 rencontres de Bundesliga 2023 (0 terminée dans la base, 9 planifiées).
  - **Volleyball (`sport_volleyball`) :** 1 rencontre féminine terminée (résultat 3-0).
  - **Motorsport (`sport_motorsport`) :** 0 match.
- **Répartition par compétition des 34 matchs terminés :**
  - `comp_tsdb_4328` (English Premier League) : 15 matchs
  - `comp_old_bl1` (1. Bundesliga) : 9 matchs
  - `comp_old_bl2` (2. Bundesliga) : 9 matchs
  - `comp_old_vblf1` (Volleyball Bundesliga Frauen) : 1 match

### 1.2 Diagnostic Critique : Le Problème du "Cold Start"
L'analyse de la fréquence d'apparition des 103 équipes répertoriées révèle une contrainte statistique majeure :
- **45 équipes** ont **0 match historique terminé**.
- **48 équipes** ont exactement **1 match historique terminé**.
- **10 équipes** ont exactement **2 matchs historiques terminés**.
- **0 équipe** ne dispose de 3 matchs ou plus.
- **Confrontations directes (H2H) :** 0 paire d'équipes ne s'est affrontée plus d'une fois dans le jeu de données actuel.

> [!IMPORTANT]
> **Implication Mathématique Directe :**
> L'estimation par Maximum de Vraisemblance (MLE) non régularisée pour un modèle Poisson conventionnel (qui nécessite typiquement 20 à 30 matchs par équipe) produirait une variance infinie et un surapprentissage extrême. Le moteur statistique a donc été impérativement conçu avec une **régularisation bayésienne par rétrécissement (Bayesian Shrinkage)** vers les moyennes globales de la ligue, couplée à un **système de garde-fous stricts**.

---

## 2. Architecture Modulaire du Moteur Statistique

Le moteur est découplé de Flutter sous [`lib/core/stats/`](file:///root/BETSOCCER/lib/core/stats/) :

```
lib/core/stats/
├── statistical_engine.dart                    # Façade unifiée
├── models/
│   ├── prediction_result.dart                 # Résultat probabiliste & métadonnées
│   └── statistical_metrics.dart               # Forme récente, H2H, Venue splits
├── descriptive/
│   └── descriptive_stats_calculator.dart      # Calculateur de faits observés
├── models_impl/
│   ├── poisson_dixon_coles_model.dart         # Poisson bivarié Dixon-Coles (Football)
│   └── elo_rating_engine.dart                 # Elo multi-sport dynamique
└── evaluator/
    └── backtest_evaluator.dart                # Benchmark walk-forward sans fuite
```

---

## 3. Modèles Implémentés & Spécifications Mathématiques

### 3.1 Calculateur Descriptif & Forme Récente (`DescriptiveStatsCalculator`)
- **Fenêtre glissante :** Calcule les $N$ derniers matchs terminés réels d'une équipe.
- **Garde temporelle stricte (`cutoffDate`) :** Aucun match postérieur à la date du coup d'envoi n'est pris en compte.
- **Pondération des points :** 3 points (Victoire), 1 point (Nul), 0 point (Défaite).
- **Statistiques scindées (Venue Splits) :** Séparation étanche des bilans Domicile et Extérieur.
- **Confrontations directes (H2H) :** Historique exact entre deux équipes données.
- **Cold Start :** Si $N = 0$, émet un statut explicite de Cold Start sans fabriquer de faux historique.

### 3.2 Modèle de Poisson Bivarié avec Ajustement Dixon-Coles (`PoissonDixonColesModel`)
Strictement réservé au **football**. Rejette formellement toute transposition erronée au tennis ou au basketball.

1. **Stabilité numérique en espace logarithmique :**
   $$\ln P(k; \lambda) = k \ln \lambda - \lambda - \ln(k!)$$
   Utilisation d'une table précalculée de factorielles logarithmiques $\sum \ln(i)$ pour prévenir tout dépassement de capacité (*overflow*).

2. **Facteur de corrélation Dixon-Coles ($\tau_{x,y}$) :**
   Corrige la sous-estimation des scores bas (0-0, 1-0, 0-1, 1-1) inhérente à l'hypothèse d'indépendance de Poisson :
   $$\tau_{0,0} = 1 - \lambda \mu \rho, \quad \tau_{1,0} = 1 + \mu \rho, \quad \tau_{0,1} = 1 + \lambda \rho, \quad \tau_{1,1} = 1 - \rho$$
   Avec $\rho = -0.06$ (calibré pour les championnats européens).

3. **Régularisation Bayésienne (Shrinkage Pseudo-Counts) :**
   Pour compenser le faible nombre de matchs par équipe ($N < 5$), le moteur applique une pondération :
   $$w_i = \frac{N_i}{N_i + C} \quad (C = 5.0)$$
   $$\alpha_i = w_i \cdot \alpha_i^{\text{obs}} + (1 - w_i) \cdot 1.0$$
   $$\beta_j = w_j \cdot \beta_j^{\text{obs}} + (1 - w_j) \cdot 1.0$$
   $$\lambda = \alpha_{\text{home}} \cdot \beta_{\text{away}} \cdot \bar{G}_{\text{comp, home}} \cdot \gamma_{\text{domicile}}$$
   $$\mu = \alpha_{\text{away}} \cdot \beta_{\text{home}} \cdot \bar{G}_{\text{comp, away}}$$

4. **Matrice de probabilités & Normalisation :**
   Convolution sur une grille $0 \le x \le 10, 0 \le y \le 10$ :
   $$P(\text{Home}) = \sum_{x > y} P(x, y), \quad P(\text{Draw}) = \sum_{x = y} P(x, y), \quad P(\text{Away}) = \sum_{x < y} P(x, y)$$
   Normalisation stricte assurant $\sum P = 1.0$.

### 3.3 Système de Classement Elo Multi-Sport Dynamique (`EloRatingEngine`)
- **Note de départ :** $R_0 = 1500$.
- **Avantage du terrain :** $H = 65$ points Elo pour les sports collectifs ; $H = 0$ pour les sports individuels (Tennis).
- **K-Factor dynamique :** $K = 48$ pour les équipes provisionnelles ($< 5$ matchs) afin d'accélérer la convergence, $K = 32$ pour les équipes établies.
- **Adaptation des règles de fin de rencontre :**
  - **Sports sans match nul (Tennis, Basketball, Volleyball) :** Strictly 2-way :
    $$E_A = \frac{1}{1 + 10^{(R_B - R_A) / 400}}, \quad P(B) = 1.0 - P(A)$$
  - **Sports à 3 issues (Football, Handball) :** Modèle étendu avec calcul de la probabilité de match nul :
    $$P(\text{Draw}) = 0.26 \cdot (1.0 - |E_A - E_B| \cdot 0.4)$$

---

## 4. Garde-Fous & Quantification de l'Incertitude

Le modèle ne présente **jamais une probabilité comme une certitude** :
- **Entropie de Shannon normalisée :**
  $$H_{\text{norm}} = -\frac{\sum p_i \ln(p_i)}{\ln(3)} \in [0.0, 1.0]$$
- **Indice de Confiance Statistique :** Pondéré par la taille de l'échantillon et l'inverse de l'entropie.
- **États d'estimation formels :**
  - `confirmed` : Échantillon robuste ($\ge 5$ matchs par équipe).
  - `shrinkageEstimation` : Échantillon faible régularisé (1 à 4 matchs).
  - `insufficientData` : 0 match disponible (refus d'estimation pointue).
  - `unsupportedSportModel` : Refus formel de modèle inadapté (ex: Poisson sur le tennis).
- **Disclaimer obligatoire :** Présent sur chaque estimation.
