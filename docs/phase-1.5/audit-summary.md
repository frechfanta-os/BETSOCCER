# BETSOCCER — SYNTHÈSE DE L'AUDIT GLOBAL DES SOURCES SPORTIVES (PHASE 1.5)

**Date d'achèvement :** 13 octobre 2026  
**Équipe senior d'audit :** Ingénierie des données, Flutter/Dart, API REST, Scraping responsable, Cybersécurité et Conformité juridique  
**Projet :** BETSOCCER — Multisport Analytics AI  
**Dépôt officiel :** https://github.com/frechfanta-os/BETSOCCER  
**Branche :** `main`

---

## 1. Réponses aux 11 Questions Fondamentales de l'Audit

### 1. Combien de sources ont été identifiées ?
**12 sources distinctes** ont été répertoriées et analysées :
1. OpenFootball (GitHub CC0)
2. OpenLigaDB (REST API Open Data)
3. Football-Data.co.uk (Archives CSV Joseph Buchdahl)
4. TheSportsDB (API V1 Free)
5. Football-Data.org (API V4 Freemium)
6. API-SPORTS / API-Football (REST API Freemium)
7. Jolpica-F1 (Successeur open-source d'Ergast F1)
8. Balldontlie (REST API NBA)
9. Jeff Sackmann / Tennis Match Charting Project (GitHub Open Data)
10. ESPN Hidden Site API / Scoreboard (BFF interne public)
11. FlashScore / SofaScore (Web Scraping direct grand public)
12. MelBet (Opérateur de paris sportifs)

### 2. Combien ont été testées réellement ?
**11 sources ont été testées techniquement** par des requêtes HTTP/REST réelles, des téléchargements d'échantillons ou des contrôles de sécurité réseau depuis l'environnement de développement Linux PRoot. La 12e source (MelBet) a été évaluée par son audit de conformité contractuelle sans émission de requêtes intrusives.

### 3. Combien ont fourni des données valides ?
**7 sources ont fourni des données réelles, exploitables et validées** :
- **OpenFootball** : 380 matchs (Premier League 2023/24) analysés sans aucune erreur.
- **Football-Data.co.uk** : 380 matchs complets avec tirs, tirs cadrés, fautes, corners et cartons.
- **OpenLigaDB** : 9 matchs Bundesliga football, 9 matchs Handball HBL, 5 matchs Volleyball VBL.
- **TheSportsDB** : 380 événements complets avec scores et blasons CDN d'équipes.
- **Football-Data.org** : 12 compétitions majeures et endpoints de calendrier validés.
- **Jolpica-F1** : 440 résultats de Grands Prix de Formule 1 validés.
- **ESPN Site API** : Scoreboards réels validés (Football, NBA, ATP).

### 4. Combien sont utilisables sous conditions ?
**3 sources sont classées CONDITIONNELLES (CONDITIONAL)** :
- **Balldontlie** : Requiert la déclaration d'une clé API gratuite suite à la migration v1 (HTTP 401 vérifié sans clé).
- **API-SPORTS** : Quota gratuit restreint à 100 requêtes/jour (imposant une synchronisation batch très espacée).
- **ESPN Site API** : Données complètes, mais risque juridique lié aux CGU Disney et risque technique de rupture de service sans préavis.

### 5. Combien sont rejetées ou non vérifiées ?
**2 sources sont formellement REJETÉES (REJECTED)** :
- **MelBet** : Rejeté par politique de sécurité et conformité légale (**DISABLED_BY_POLICY**).
- **FlashScore & SofaScore (Scraping HTML direct)** : Rejetés en raison des protections anti-bot (SofaScore renvoie HTTP 403 Forbidden immédiat via Cloudflare/DataDome) et des interdictions explicites dans `robots.txt` (`Disallow: /live/`, `/finished/`).

### 6. Quels sports et quelles compétitions sont réellement couverts ?
- **Football (Soccer)** : Mondial (Angleterre, France, Espagne, Italie, Allemagne, Pays-Bas, Portugal, Coupes d'Europe UEFA, Coupe du Monde FIFA).
- **Basketball** : NBA (National Basketball Association).
- **Handball** : LIQUI MOLY HBL (Handball Bundesliga allemande, n°1 mondiale).
- **Volleyball** : Bundesliga féminine et masculine.
- **Motorsport (Formule 1)** : Championnat du Monde FIA de Formule 1 (1950 à aujourd'hui).
- **Tennis** : Archives historiques de tournois du Grand Chelem et Masters 1000 (mode statique uniquement).

### 7. Quelles sources sont recommandées pour les données historiques ?
1. **Football-Data.co.uk** : Indispensable pour la Phase 2 car elle fournit les **métriques avancées de tir et d'engagement** (tirs cadrés, corners, fautes, cartons) nécessaires à l'affinement du modèle Dixon-Coles.
2. **OpenFootball (CC0)** : Socle d'archives déconnecté 100% souverain et libre de droits.
3. **Jolpica-F1** : Pour les sports mécaniques.
4. **OpenLigaDB** : Pour les archives de football, handball et volleyball allemands.

### 8. Quelles sources sont recommandées pour les calendriers et résultats récents ?
1. **OpenLigaDB** : Gratuité totale, sans clé, temps réel et statut `matchIsFinished`.
2. **TheSportsDB (V1 Free Key 3)** : Calendrier multisport et blasons vectoriels d'équipes.
3. **Football-Data.org (Plan Gratuit)** : Résultats récents des 12 ligues majeures sous quota de 10 req/min.

### 9. Ce qui manque pour disposer de résultats en direct fiables à 0 €
Les flux de direct professionnels (push WebSocket à latence sub-seconde avec positions de balle en temps réel) sont un marché commercial fermé, verrouillé par des contrats d'exclusivité (Sportradar, Genius Sports, Stats Perform) facturés plusieurs milliers d'euros par mois.  
Dans un cadre **100% gratuit (0 €)** :
- Le direct repose sur du **polling périodique raisonnable** (ex: rafraîchissement manuel initié par l'utilisateur ou toutes les 60 secondes en arrière-plan) sur OpenLigaDB et Football-Data.org.
- Il est impossible de garantir une couverture en direct sub-seconde pour le tennis ou les sports mineurs sans dépendance payante ou violation de CGU.

### 10. Les coûts ou limites susceptibles d’apparaître à terme
- **Limites de débit (Rate Limits)** : Les API gratuites imposent des plafonds (10 req/min sur Football-Data.org, 30 req/min sur Balldontlie, 100 req/jour sur API-Sports). L'application doit impérativement utiliser un cache SQLite local pour ne jamais saturer ces quotas.
- **Volatilité des sources non contractuelles** : L'API V1 de TheSportsDB pourrait être restreinte à l'avenir au profit de la V2 Patreon payante. La multiplicité des connecteurs protège BETSOCCER contre ce risque.

### 11. Les prochaines étapes recommandées avant la Phase 2
1. **Validation formelle de l'audit Phase 1.5** par l'utilisateur.
2. **Démarrage de la Phase 2 — Statistical Engine** :
   - Implémentation du moteur de calcul mathématique déterministe en Dart pur :
     - Loi de Poisson bivariée (calcul des espérances de buts $\lambda$ et $\mu$).
     - Modèle de Dixon & Coles (ajustement des probabilités pour les scores faibles 0-0, 1-0, 0-1, 1-1).
     - Classement Elo dynamique pour estimer la force relative des équipes.
   - Validation du moteur mathématique par des tests unitaires de convergence statistique sur les données réelles vérifiées de Football-Data.co.uk et OpenFootball.

---

## 2. Inventaire des Livrables Produits (Répertoire `docs/phase-1.5/`)

- [**docs/phase-1.5/source-inventory.md**](docs/phase-1.5/source-inventory.md) : Fiches d'identité détaillées pour les 12 sources analysées.
- [**docs/phase-1.5/source-comparison.md**](docs/phase-1.5/source-comparison.md) : Matrice comparative globale et 3 classements ciblés (historique, calendrier/récent, multisport).
- [**docs/phase-1.5/scraping-test-results.md**](docs/phase-1.5/scraping-test-results.md) : Rapports d'essais techniques et relevés de mesures empiriques.
- [**docs/phase-1.5/sports-coverage-matrix.md**](docs/phase-1.5/sports-coverage-matrix.md) : Cartographie vérifiée par discipline sportive et typologie d'accès.
- [**docs/phase-1.5/legal-and-licensing-review.md**](docs/phase-1.5/legal-and-licensing-review.md) : Analyse juridique approfondie (droit d'auteur, droit *sui generis*, jurisprudence et RGPD).
- [**docs/phase-1.5/recommended-data-architecture.md**](docs/phase-1.5/recommended-data-architecture.md) : Schéma d'ingestion cible, normalisation, déduplication et stabilité du schéma SQLite V1.
- [**docs/phase-1.5/audit-summary.md**](docs/phase-1.5/audit-summary.md) : Synthèse décisionnelle exécutive.
