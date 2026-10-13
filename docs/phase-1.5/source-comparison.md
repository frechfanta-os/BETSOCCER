# BETSOCCER — MATRICE COMPARATIVE DES SOURCES SPORTIVES (PHASE 1.5)

**Date d'évaluation :** 13 octobre 2026  
**Équipe d'audit :** Architecture des données, conformité & cybersécurité  
**Projet :** BETSOCCER — Multisport Analytics AI

---

## 1. Matrice Comparative Globale

Le tableau ci-dessous récapitule les 12 sources examinées, avec leurs indicateurs mesurés et leur statut d'intégration dans l'application BETSOCCER :

| # | Source | Sports Couverts | Historique | Calendriers | Live | Qualité Données | Quota Gratuit | Licence / Réutilisation | Test Réel | Enregistrements Validés | État Intégration | Niveau Confiance | Verdict |
| :-: | :--- | :--- | :-: | :-: | :-: | :---: | :---: | :---: | :-: | :-: | :---: | :---: | :---: |
| **01** | **OpenFootball** | Football | **Très Profond** (1888-2024) | Oui (annuel) | Non | Excellente | **Illimité** (Local CC0) | **CC0 1.0 (Domaine Public)** | **PASS** | **380 matchs (PL 23/24)** | **Actif** (`OpenFootballDataSource`) | **100% (Souverain)** | **RECOMMENDED** |
| **02** | **OpenLigaDB** | Multisport (Foot, Handball, Volley) | 20+ ans (2005+) | Oui | **Oui** | Haute (buteurs, périodes) | **Illimité** (Fair use) | **Open Data / CC BY 4.0** | **PASS** | **18 matchs testés (BL1, HBL, VBL)** | Non intégré | **95% (Très élevé)** | **RECOMMENDED** |
| **03** | **Football-Data.co.uk** | Football | **Très Profond** (1993-2026) | Hebdomadaire | Non | **Maximale** (Tirs, fautes, corners) | **1000 req/tranche** | Utilisation libre / Attribution | **PASS** | **380 matchs testés** | Non intégré | **98% (Très élevé)** | **RECOMMENDED** |
| **04** | **TheSportsDB** | Multisport (>10 sports) | 10+ ans | Oui | Non (V1) | Haute (Métadonnées & badges) | **Gratuit V1** (Clé `'3'`) | Creative Commons / Fair use | **PASS** | **20 sports, 380 matchs** | **Actif** (`TheSportsDbDataSource`) | **90% (Élevé)** | **RECOMMENDED** |
| **05** | **Football-Data.org** | Football (12 ligues) | Jusqu'à 10 ans | Oui | **Oui** | Excellente (temps réel) | **10 req / min** | Gratuit non-commercial | **PASS** | **12 ligues majeures** | **Actif** (`FootballDataOrgDataSource`)| **85% (Quota strict)** | **RECOMMENDED** |
| **06** | **Jolpica-F1** | Motorsport (Formule 1) | **Total** (1950-2026) | Oui | Non | Haute (Tours, arrêts) | **Gratuit** (~4 req/s) | **CC BY 4.0 (Open Data)** | **PASS** | **440 résultats (2023)** | Non intégré | **95% (Très élevé)** | **RECOMMENDED** |
| **07** | **Balldontlie** | Basketball (NBA) | 45 ans (1979+) | Oui | **Oui** | Maximale NBA | **30 req / min** | Gratuit développeur | **PASS (401 sans clé)** | Spécification vérifiée | Non intégré | **80% (Clé requise)** | **CONDITIONAL** |
| **08** | **API-SPORTS** | Multisport complet | 15 ans (2010+) | Oui | **Oui** | Industrielle (xG, arbitres) | **100 req / jour** | Commerciale avec plan free | **PASS (403 sans clé)** | Spécification vérifiée | Non intégré | **75% (Quota journalier)** | **CONDITIONAL** |
| **09** | **Jeff Sackmann Tennis** | Tennis (ATP/WTA) | 50+ ans (1968+) | Non | Non | Maximale (point par point) | **Illimité** (GitHub local) | CC BY-NC-SA 4.0 | **PARTIAL** (Dépôt maître 404, fork actif) | Échantillon local | Non intégré | **70% (Dépôt instable)** | **CONDITIONAL** |
| **10** | **ESPN Site API** | Multisport | 2 à 5 ans | Oui | **Oui** | Complète avec horloge | Non documenté (7s cache) | Propriétaire Disney | **PASS** | Scoreboards réels obtenus | Non intégré | **45% (Risque légal/rupture)**| **CONDITIONAL** |
| **11** | **FlashScore / SofaScore** | Multisport | 15+ ans | Oui | Oui | Bonne | Aucune API | Propriétaire fermée | **FAIL** (403 anti-bot / robots.txt) | 0 (Collecte bloquée) | Proscrit | **0% (Inexploitable)** | **REJECTED** |
| **12** | **MelBet** | Multisport / Cotes | Variable | Non autorisé| Non autorisé| Non qualifié | Inexistant | Aucune licence tierce | **EXCLU PAR POLITIQUE**| 0 (Scraping interdit) | **Verrouillé** (`MelbetDataSource`)| **0% (Interdit)** | **REJECTED** |

---

## 2. Classements Spécialisés

### Classement A : Meilleures Sources Historiques
*Critères de sélection : Profondeur des archives, fiabilité des scores, présence de métriques avancées pour le moteur mathématique (Phase 2), licence ouverte et gratuité.*

1. **Football-Data.co.uk** :  
   - **Pourquoi :** Fournit les statistiques indispensables pour modéliser la performance au-delà des seuls buts (tirs cadrés `HST`/`AST`, corners `HC`/`AC`, fautes, cartons) sur plus de 30 saisons européennes.
   - **Licence :** Libre d'utilisation avec attribution.
2. **OpenFootball (CC0)** :  
   - **Pourquoi :** Domaine public pur (CC0 1.0), stockage local embarqué immédiat, structure lisible en texte brut, déduplication native, aucun risque de rupture réseau ou de quota.
   - **Licence :** Domaine Public (CC0).
3. **Jolpica-F1 (Motorsport)** :  
   - **Pourquoi :** Archive intégrale de tous les Grands Prix de Formule 1 depuis 1950, libre et gratuite.
   - **Licence :** CC BY 4.0.
4. **OpenLigaDB** :  
   - **Pourquoi :** 20 ans d'historique allemand pour le football, le handball et le volleyball avec le détail des buteurs et des mi-temps.
   - **Licence :** Open Data.

---

### Classement B : Meilleures Sources pour Calendriers et Résultats Récents
*Critères de sélection : Fraîcheur des données, respect du budget 0 €, stabilité de l'API et absence de blocage.*

1. **OpenLigaDB** :  
   - **Pourquoi :** Gratuité totale sans clé d'authentification, gestion du statut `matchIsFinished`, horaires UTC fiables, scores en direct communautaires.
2. **TheSportsDB (V1 Free Key 3)** :  
   - **Pourquoi :** Calendrier multisport mondial à venir et résultats récents complets avec blasons d'équipes et métadonnées de stade, sans contrainte de quota serré.
3. **Football-Data.org (Plan Gratuit)** :  
   - **Pourquoi :** 12 ligues majeures mises à jour en quasi temps réel avec scores en direct, mais soumise à la contrainte stricte des 10 requêtes/minute.

---

### Classement C : Meilleures Sources Multisports
*Critères de sélection : Diversité réelle des disciplines sportives, qualité des métadonnées et pérennité.*

1. **TheSportsDB** :  
   - **Sports :** Football, Basketball, Tennis, Motorsport, Baseball, Rugby, Volleyball, Hockey sur glace.
   - **Points forts :** Identifiants uniques pérennes, taxonomie claire des sports, blasons graphiques.
2. **OpenLigaDB** :  
   - **Sports :** Football, Handball (`hbl`), Volleyball féminin (`vblf1`), Volleyball masculin.
   - **Points forts :** Données structurées par set ou par mi-temps, aucune authentification requise.
3. **Balldontlie (Spécialisé Basketball)** :  
   - **Sports :** Basketball NBA complet (boîte de score, quart-temps, statistiques joueurs).
   - **Points forts :** Gratuit 30 req/min avec token gratuit.

---

## 3. Justification des Sources Rejetées ou Conditionnelles

### Sources Rejetées (REJECTED)
- **MelBet** : Rejeté formellement en vertu du principe de précaution juridique et des CGU du site. Aucun collecteur de données ou de cotes bookmaker ne sera implémenté.
- **FlashScore & SofaScore (Scraping HTML direct)** : Rejetés en raison des protections anti-bot (Cloudflare, DataDome, Cloudflare Turnstile), des directives explicites de `robots.txt` interdisant les endpoints de scores et des risques d'instabilité structurelle du code.

### Sources Conditionnelles (CONDITIONAL)
- **API-SPORTS** : Excellente qualité technique, mais le quota gratuit de 100 requêtes/jour impose un mode d'interrogation batch très espacé (interdiction de polling direct).
- **Balldontlie** : Requiert la création d'un compte gratuit pour obtenir un jeton d'accès suite à sa migration récente v1.
- **ESPN Site API** : Utilisable uniquement en mode expérimental non prioritaire du fait de l'absence de contrat formel et des restrictions Disney.
