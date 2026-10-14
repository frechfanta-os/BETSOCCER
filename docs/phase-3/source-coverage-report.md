# BETSOCCER — Phase 3 : Rapport de Couverture des Sources de Données

**Date :** 14 Octobre 2026  
**Auteur :** Équipe Data Engineering BETSOCCER  
**Dépôt officiel :** `https://github.com/frechfanta-os/BETSOCCER`  

---

## 1. Vue d'Ensemble des Connecteurs

BETSOCCER repose sur une architecture d'agrégation multi-fournisseurs conçue pour concilier **ouverture légale**, **gratuité des flux**, **richesse statistique** et **fraîcheur temporelle**.

Toutes les sources actives sont exploitées dans le respect le plus strict des licences d'utilisation, des limites de débit (*rate limiting*) et des conditions d'accès, avec un **verrou éthique absolu** interdisant les plateformes de paris sportifs commerciales (MelBet).

---

## 2. Analyse Détaillée des Fournisseurs

### 2.1 OpenLigaDB (Open REST API)
- **Fournisseur :** OpenLigaDB e.V. (Allemagne)
- **Licence :** Creative Commons Attribution 4.0 International ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr)). Réutilisation et redistribution libres sous réserve d'attribution.
- **Modèle économique & Coûts :** 100% gratuit, aucun compte requis, aucune clé API obligatoire.
- **Quotas & Limites :** Accès libre. Le collecteur BETSOCCER s'impose un délai de courtoisie de 1,0 seconde entre requêtes.
- **Sports & Compétitions Couverts :**
  - Football : 1. Bundesliga (`bl1`), 2. Bundesliga (`bl2`)
  - Handball : Handball Bundesliga (`hbl`)
  - Volleyball : 1. Volleyball Bundesliga Frauen (`vblf1`)
- **Profondeur Historique :** Archives complètes depuis la création des ligues.
  - Saisons 2023/24 ingérées : 306 matchs (`bl1`) + 306 matchs (`bl2`) + 278 matchs (`hbl`) + 18 matchs (`vblf1`) = **908 matchs historiques vérifiés**.
- **Calendriers et Fraîcheur :**
  - Endpoint `/getmatchdata/{league}` retournant le matchday dynamique actuel (en direct ou prochaines rencontres). 28 matchs actuels collectés.
- **Dernier Test Réel :** 14 Octobre 2026 à 07:21 UTC — **936 enregistrements collectés avec succès** en 17,5 secondes.

---

### 2.2 Football-Data.co.uk (Archives CSV & Calendriers Futurs)
- **Fournisseur :** Joseph Buchdahl / Football-Data.co.uk (Royaume-Uni)
- **Licence :** Open Data à usage libre pour la recherche, les projets personnels, académiques et d'analyse statistique sportive.
- **Modèle économique & Coûts :** Gratuit, hébergement sur serveur public en fichiers CSV statiques.
- **Quotas & Limites :** Téléchargement direct sans limite contraignante. Accès via flux HTTP streaming avec User-Agent identifié.
- **Sports & Compétitions Couverts :**
  - English Premier League (`E0`)
  - La Liga Espagnole (`SP1`)
  - Championship Anglais (`E1`)
  - League 1 Anglaise (`E2`)
  - Scottish Division 1 (`SC1`)
- **Profondeur Historique :** Plus de 30 années d'archives (1993 à 2024).
  - Saisons 2023/24 ingérées : 380 matchs (`E0`) + 380 matchs (`SP1`) = **760 matchs historiques complets**.
- **Détail des Données Incluses :**
  - Scores finaux (FTHG, FTAG) et scores à la mi-temps (HTHG, HTAG).
  - 7 statistiques de match normalisées : tirs totaux, tirs cadrés, corners, fautes, cartons jaunes, cartons rouges, et arbitre officiel assigné.
- **Calendriers Futurs :**
  - Fichier `fixtures.csv` mis à jour hebdomadairement (14 matchs à venir collectés pour la journée du week-end).
- **Dernier Test Réel :** 14 Octobre 2026 à 07:21 UTC — **774 enregistrements collectés avec succès** (760 historiques + 14 fixtures) en 12,8 secondes.

---

### 2.3 TheSportsDB (Community Sports API V1)
- **Fournisseur :** TheSportsDB.com
- **Licence :** Creative Commons Attribution-NonCommercial 4.0 ([CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/)).
- **Modèle économique & Coûts :** Clé de test publique `3` gratuite.
- **Quotas & Limites :** 100 requêtes par minute maximum.
- **Sports & Compétitions Couverts :**
  - Découverte multisport (Football, Basketball NBA, Tennis, Motorsport).
  - Événements récents de la Premier League (`comp_tsdb_4328`).
- **Profondeur Historique :** Saison courante (15 matchs récents collectés).
- **Dernier Test Réel :** 14 Octobre 2026 à 07:21 UTC — **15 événements collectés avec succès** en 4,6 secondes.

---

### 2.4 OpenFootball (football.csv / Github Archives)
- **Fournisseur :** Projet OpenFootball (Gerald Bauer)
- **Licence :** Domaine Public / Creative Commons Zero ([CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/deed.fr)). Aucune restriction de réutilisation, modification ou distribution.
- **Modèle économique & Coûts :** 100% gratuit, dépôts Git ouverts.
- **Intégration dans BETSOCCER :** Parser autonome `OpenFootballParser` intégré dans Flutter (`lib/features/sports/data/parsers/openfootball_parser.dart`) permettant l'import direct de formats texte/markdown sans dépendance réseau externe.

---

### 2.5 MelBet (Fournisseur Verrouillé par Politique de Sécurité)
- **Statut dans BETSOCCER :** `DISABLED_BY_POLICY` (is_enabled = 0).
- **Justification Légale & Éthique :**
  1. Les Conditions Générales d'Utilisation des opérateurs de paris commerciaux interdisent formellement l'extraction automatisée non autorisée de données.
  2. BETSOCCER est une application d'analyse sportive scientifique, et non un outil de courtage de paris.
  3. L'intégration de cotes bookmakers dans le moteur statistique introduirait un biais d'endogénéité commercial, corrompant la mesure objective des probabilités intrinsèques de jeu.
- **Implémentation Technique :**
  - Variable `melbet_enabled = False` verrouillée dans `collector/config.py`.
  - Enregistrement SQL dans `data_sources` avec statut `policy_status = 'DISABLED_BY_POLICY'`.
  - Aucun flux réseau, 0 requête, 0 donnée collectée.

---

## 3. Matrice Récapitulative des Sources

| Source | Licence | Coût | Quota | Sports | Matchs Historiques | Calendriers Futurs | Statut BETSOCCER |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OpenLigaDB** | CC BY 4.0 | Gratuit | Libre (1 req/s) | Football, Handball, Volleyball | Oui (saisons 2023/24 complètes) | Oui (matchday dynamique) | **ACTIF (936 rec)** |
| **Football-Data.co.uk** | Open Data | Gratuit | Libre (HTTP) | Football (EPL, La Liga, etc.) | Oui (30+ ans, 7 stats par match) | Oui (fixtures.csv hebdo) | **ACTIF (774 rec)** |
| **TheSportsDB** | CC BY-NC 4.0 | Gratuit (Clé 3) | 100 req/min | Multisport (Foot, Basket, etc.) | Événements récents | Saisons courantes | **ACTIF (15 rec)** |
| **OpenFootball** | CC0 (Domaine Public) | Gratuit | Illimité | Football mondial | Oui (archives Git) | Oui | **ACTIF (In-App Parser)** |
| **MelBet** | Restreinte | N/A | Interdit | Cotes de paris | Non | Non | **VERROUILLÉ (0 rec)** |

---

## 4. Politique de Rafraîchissement et Stratégie Temporelle

Pour optimiser les ressources réseau et préserver l'intégrité de la base de données, la politique de mise à jour suivante est appliquée :

1. **Résultats Historiques Terminés :**  
   - Fréquence : Synchronisation ponctuelle ou mensuelle.
   - Propriété : Immuables une fois le résultat officialisé.
2. **Calendriers et Matchs à Venir (Fixtures) :**  
   - Fréquence : Synchronisation quotidienne ou hebdomadaire.
   - Propriété : Mise à jour des dates/heures de coup d'envoi en cas de report.
3. **Matchs en Direct (Live) :**  
   - Fréquence : Rafraîchissement dynamique à la demande de l'utilisateur sur l'écran Live Center.
