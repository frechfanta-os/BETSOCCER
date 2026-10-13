# BETSOCCER — INVENTAIRE DÉTAILLÉ DES SOURCES SPORTIVES (PHASE 1.5)

**Date d'audit :** 13 octobre 2026  
**Auditeurs :** Équipe Senior Data Engineering, API, Sécurité & Conformité Juridique  
**Projet :** BETSOCCER — Multisport Analytics AI (`com.ghdinteractivestudio.betsoccer`)

---

## 1. Méthodologie d'Audit

Chaque source sportive a été examinée selon un protocole strict :
1. Analyse documentaire officielle (documentation de l'API, licence, conditions générales d'utilisation, robots.txt).
2. Sonde technique réelle (requête HTTP/REST ou téléchargement d'archive, mesure de latence, format de réponse, codes HTTP, politique de mise en cache et d'en-têtes).
3. Contrôle de conformité juridique (droits *sui generis* sur les bases de données, autorisations d'extraction automatisée, exigences d'attribution).
4. Évaluation de l'adéquation avec l'architecture Android Offline-First SQLite de BETSOCCER.

---

## 2. Fiches Détaillées par Fournisseur

### Fiche 01 : OpenFootball
- **Nom officiel :** OpenFootball (Football Data Archive)
- **URL officielle :** https://github.com/openfootball
- **Type :** Dépôts publics GitHub, fichiers structurés en texte brut (`Football.TXT`), CSV et bases SQLite générées.
- **Sports couverts :** Football (Soccer) exclusivement.
- **Pays & Compétitions :** Couverture mondiale étendue (Premier League anglaise, Ligue 1, Liga, Serie A, Bundesliga, Coupes d'Europe UEFA, Coupes du Monde FIFA).
- **Profondeur de l'historique :** Exceptionnelle (de la saison 1888/89 jusqu'aux saisons récentes).
- **Calendriers & Matchs à venir :** Oui (programmations de saisons complètes disponibles dans les fichiers annuels).
- **Scores en direct :** **NON** (données statiques mises à jour après les rencontres).
- **Statistiques disponibles :** Scores finaux, scores à la mi-temps, journées, dates, horaires UTC, clubs, éventuels buteurs sur certains jeux.
- **Format de données :** Texte tabulaire standard (`Football.TXT`), CSV, SQLite.
- **Authentification :** Aucune (accès libre par téléchargement direct ou submodule Git).
- **Quota gratuit & Limites de fréquence :** Illimité en local (assets embarqués) ; soumis aux quotas standard de GitHub (5 000 req/h si interrogation API GitHub).
- **Licence & Conditions d'utilisation :** **Domaine Public — Creative Commons Zero (CC0 1.0 Universal)**.
- **Autorisation de réutilisation & Stockage local :** **TOTALE ET SANS RESTRICTION**. Réutilisation commerciale, modification, stockage SQLite local et redistribution autorisés.
- **Attribution requise :** Non obligatoire légalement (CC0), mais maintenue par courtoisie dans l'application.
- **Restrictions techniques & Robots.txt :** Aucune restriction pour les fichiers clonés ou téléchargés.
- **Fiabilité & Fraîcheur :** Très haute fiabilité pour les archives historiques ; latence de mise à jour de quelques jours pour les matchs récents.
- **Facilité d'intégration Flutter / SQLite :** **Excellente** (connecteur `OpenFootballDataSource` et parser `OpenFootballParser` déjà opérationnels dans BETSOCCER).
- **Coût estimé :** **0,00 €**.
- **Risques :** Arrêt des mises à jour manuelles par la communauté sur certaines ligues secondaires.
- **Verdict :** **RECOMMENDED** (Source d'archives historiques de référence).

---

### Fiche 02 : OpenLigaDB
- **Nom officiel :** OpenLigaDB
- **URL officielle :** https://www.openligadb.de / API : https://api.openligadb.de
- **Type :** API REST publique JSON.
- **Sports couverts :** Multisport (Football majeur, Handball, Volleyball, Basketball féminin, Hockey sur gazon).
- **Pays & Compétitions :** Spécialisé sur l'Allemagne et les compétitions européennes (Bundesliga 1, 2, 3, DFB-Pokal, Ligue des Champions UEFA, Handball Bundesliga `HBL`, Volleyball Bundesliga `vblf1`).
- **Profondeur de l'historique :** Depuis la saison 2005/2006 (20+ saisons disponibles).
- **Calendriers & Matchs à venir :** Oui (calendrier complet par saison et par journée).
- **Scores en direct :** **OUI** (temps réel communautaire avec indicateur `matchIsFinished: false` et mise à jour minute par minute).
- **Statistiques disponibles :** Scores par période, buteurs, minutes de but, penaltys, cartons jaunes/rouges, prolongations, arrêts de jeu, logos d'équipes en haute résolution.
- **Format de données :** JSON UTF-8.
- **Authentification :** **Aucune clé requise** (accès totalement ouvert).
- **Quota gratuit & Limites de fréquence :** Aucun quota strict documenté ; respect des bonnes pratiques HTTP requis (politique de temporisation de 10-30s recommandée pour le direct).
- **Licence & Conditions d'utilisation :** Données ouvertes collaboratives (Open Data, CC BY 4.0 / Open Government Licence).
- **Autorisation de réutilisation & Stockage local :** Autorisée avec mention de la source.
- **Attribution requise :** Oui ("Données fournies par OpenLigaDB.de").
- **Restrictions techniques & Robots.txt :** Serveur IIS / ASP.NET stable ; en-têtes CORS ouverts.
- **Fiabilité & Fraîcheur :** Excellente fraîcheur pour la Bundesliga et le handball allemand ; modérée pour les ligues tierces.
- **Facilité d'intégration Flutter / SQLite :** **Excellente** (JSON direct, `matchDateTimeUTC` normalisé).
- **Coût estimé :** **0,00 €**.
- **Risques :** Dépendance à une infrastructure communautaire bénévole hébergée en Allemagne.
- **Verdict :** **RECOMMENDED** (Meilleure source gratuite pour le direct et les sports alternatifs en Europe germanophone).

---

### Fiche 03 : Football-Data.co.uk
- **Nom officiel :** Football-Data.co.uk (Joseph Buchdahl)
- **URL officielle :** https://www.football-data.co.uk
- **Type :** Archives téléchargeables CSV organisées par pays et par saison.
- **Sports couverts :** Football (Soccer) exclusivement.
- **Pays & Compétitions :** Angleterre (Premier League, Championship, League 1, League 2, National League), Écosse, Allemagne, Espagne, Italie, France (Ligue 1, Ligue 2), Pays-Bas, Belgique, Portugal, Turquie, Grèce.
- **Profondeur de l'historique :** De la saison 1993/94 à la saison courante (30+ ans d'archives).
- **Calendriers & Matchs à venir :** Fichiers de rencontres à venir mis à jour hebdomadairement (`fixtures.csv`).
- **Scores en direct :** **NON** (fichiers mis à jour à J+1 après chaque journée de championnat).
- **Statistiques disponibles :** **Les plus riches pour la modélisation statistique** :
  - Scores finaux (FTHG, FTAG) et mi-temps (HTHG, HTAG).
  - Tirs totaux (HS, AS) et tirs cadrés (HST, AST).
  - Fautes commises (HF, AF) et corners (HC, AC).
  - Cartons jaunes (HY, AY) et cartons rouges (HR, AR).
  - Arbitre de la rencontre.
  - Cotes de clôture des bookmakers historiques (Bet365, Pinnacle, William Hill, etc.) utiles pour le calibrage des probabilités Dixon-Coles / Poisson.
- **Format de données :** CSV structuré.
- **Authentification :** Aucune.
- **Quota gratuit & Limites de fréquence :** 1 000 requêtes / tranche horaire signalées dans l'en-tête `x-ws-ratelimit-limit`.
- **Licence & Conditions d'utilisation :** Utilisation libre pour la recherche personnelle, académique ou commerciale sous réserve de mention de source.
- **Autorisation de réutilisation & Stockage local :** Autorisée (stockage SQLite local idéal).
- **Attribution requise :** Oui ("Données historiques issues de Football-Data.co.uk").
- **Restrictions techniques & Robots.txt :** Redirection HTTP 302 vers le domaine nu ; pas de blocage bot.
- **Fiabilité & Fraîcheur :** Fiabilité exceptionnelle, référence mondiale pour les chercheurs en statistiques sportives.
- **Facilité d'intégration Flutter / SQLite :** **Très bonne** via parser CSV en batch.
- **Coût estimé :** **0,00 €**.
- **Risques :** Format CSV sujet à de légères variations d'en-têtes selon les années (nécessite une validation robuste des colonnes).
- **Verdict :** **RECOMMENDED** (Source indispensable pour le moteur mathématique de la Phase 2 : tirs, corners, fautes).

---

### Fiche 04 : TheSportsDB
- **Nom officiel :** TheSportsDB
- **URL officielle :** https://www.thesportsdb.com / API : https://www.thesportsdb.com/api/v1/json/3/
- **Type :** API REST JSON communautaire.
- **Sports couverts :** Multisport complet (Football, Basketball, Tennis, Motorsport, Baseball, Rugby, Hockey, Volleyball, etc.).
- **Pays & Compétitions :** Mondial (plus de 800 ligues répertoriées).
- **Profondeur de l'historique :** Variable selon les compétitions (très bon sur les 10 dernières années en football, NBA, F1).
- **Calendriers & Matchs à venir :** Oui (endpoints `eventsseason.php`, `eventsnext.php`).
- **Scores en direct :** **NON** en version gratuite V1 (réservé aux abonnés Patreon V2).
- **Statistiques disponibles :** Métadonnées riches (logos vectoriels, maillots, stades, compositions de base, scores finaux et mi-temps).
- **Format de données :** JSON UTF-8.
- **Authentification :** Clé publique gratuite officielle `'3'` pour l'API V1.
- **Quota gratuit & Limites de fréquence :** Gratuit sans limite stricte par minute, mais limité aux endpoints V1.
- **Licence & Conditions d'utilisation :** Base de données collaborative sous licence Creative Commons (CC BY-NC 4.0 pour les textes / logos sous fair use éditorial).
- **Autorisation de réutilisation & Stockage local :** Autorisée pour le cache local.
- **Attribution requise :** Oui.
- **Restrictions techniques & Robots.txt :** CDN Cloudflare avec en-têtes CORS permissifs (`*`).
- **Fiabilité & Fraîcheur :** Bonne pour les ligues majeures ; plus faible pour les divisions inférieures.
- **Facilité d'intégration Flutter / SQLite :** **Excellente** (déjà intégré dans BETSOCCER via `TheSportsDbDataSource`).
- **Coût estimé :** **0,00 €** (API V1 test key `3`).
- **Risques :** Dépréciation progressive des endpoints V1 au profit de la V2 payante (Patreon).
- **Verdict :** **RECOMMENDED** (Idéal pour la découverte des sports, ligues, blasons et calendrier récent).

---

### Fiche 05 : Football-Data.org
- **Nom officiel :** Football-Data.org
- **URL officielle :** https://www.football-data.org / API : https://api.football-data.org/v4/
- **Type :** API REST JSON professionnelle avec plan freemium.
- **Sports couverts :** Football exclusivement.
- **Pays & Compétitions :** 12 compétitions majeures dans le plan gratuit (Premier League, Ligue 1, Liga, Serie A, Bundesliga, Eredivisie, Primeira Liga, Campeonato Brasileiro, Ligue des Champions, Coupe du Monde, Championship, Copa Libertadores).
- **Profondeur de l'historique :** Jusqu'à 10 saisons selon les compétitions.
- **Calendriers & Matchs à venir :** Oui (`/matches?status=SCHEDULED`).
- **Scores en direct :** **OUI** (`/matches?status=IN_PLAY,PAUSED`).
- **Statistiques disponibles :** Scores complets (temps réglementaire, mi-temps, prolongations, tirs au but), buteurs, classements en direct.
- **Format de données :** JSON.
- **Authentification :** Jeton d'authentification personnel (`X-Auth-Token`) gratuit après inscription ; mode anonyme toléré avec quota très réduit (détecté lors de l'audit technique).
- **Quota gratuit & Limites de fréquence :** **10 requêtes par minute** sur le niveau gratuit.
- **Licence & Conditions d'utilisation :** Propriétaire avec licence d'utilisation gratuite non-commerciale/développeur.
- **Autorisation de réutilisation & Stockage local :** Stockage local en cache autorisé.
- **Attribution requise :** Oui ("Powered by Football-Data.org").
- **Restrictions techniques & Robots.txt :** En-têtes stricts de rate-limiting (`X-Requests-Available`, `X-RequestCounter-Reset`).
- **Fiabilité & Fraîcheur :** Excellente fiabilité et temps de réponse ultra-rapide (~180ms).
- **Facilité d'intégration Flutter / SQLite :** **Excellente** (connecteur `FootballDataOrgDataSource` opérationnel).
- **Coût estimé :** **0,00 €** (dans la limite des 10 req/min).
- **Risques :** Dépassement de quota en cas de requêtes trop fréquentes sans circuit breaker.
- **Verdict :** **RECOMMENDED (AVEC GESTION STRICTE DE QUOTA)**.

---

### Fiche 06 : API-SPORTS / API-Football
- **Nom officiel :** API-SPORTS (API-Football, API-Basketball, API-NBA)
- **URL officielle :** https://www.api-football.com / API : https://v3.football.api-sports.io/
- **Type :** API REST JSON multi-sports industrielle.
- **Sports couverts :** Football, Basketball, Baseball, Formula 1, Hockey, Rugby, Handball, Volleyball, MMA.
- **Pays & Compétitions :** Couverture mondiale quasi exhaustive (> 1 000 ligues).
- **Profondeur de l'historique :** De 2010 à aujourd'hui.
- **Calendriers & Matchs à venir :** Oui (`/fixtures`).
- **Scores en direct :** **OUI** (`/fixtures?live=all`).
- **Statistiques disponibles :** Possession, tirs cadrés/non cadrés, passes réussies, fautes, expected goals (xG), compositions, arbitres, météo.
- **Format de données :** JSON.
- **Authentification :** En-tête obligatoire `x-apisports-key` (HTTP 403 constaté sans clé).
- **Quota gratuit & Limites de fréquence :** **100 requêtes par jour** (partagées ou par sport selon compte).
- **Licence & Conditions d'utilisation :** Propriétaire commerciale avec plan d'évaluation gratuit développeur.
- **Autorisation de réutilisation & Stockage local :** Cache autorisé, revente brute interdite.
- **Attribution requise :** Oui.
- **Restrictions techniques & Robots.txt :** Verrouillage strict Cloudflare ; quota journalier bloquant une fois atteint.
- **Fiabilité & Fraîcheur :** Temps réel de qualité industrielle.
- **Facilité d'intégration Flutter / SQLite :** Très bonne, mais nécessite une synchronisation ultra-ciblée (max 2 à 4 synchronisations/jour pour ne pas épuiser les 100 requêtes).
- **Coût estimé :** **0,00 €** en plan Free (devient 39 €/mois si upgrade nécessaire).
- **Risques :** 100 requêtes/jour est insuffisant pour un polling régulier de scores en direct.
- **Verdict :** **CONDITIONAL** (Utile pour une synchronisation quotidienne ciblée, inadapté au direct continu en budget 0 €).

---

### Fiche 07 : ESPN Site API
- **Nom officiel :** ESPN Hidden Site API / Scoreboard
- **URL officielle :** https://site.api.espn.com/apis/site/v2/sports/...
- **Type :** API REST JSON interne (BFF - Backend For Frontend) publique non documentée.
- **Sports couverts :** Multisport (Football Soccer `eng.1`, `fra.1`, Basketball NBA `basketball/nba`, Tennis ATP `tennis/atp`, NFL, MLB, NHL).
- **Pays & Compétitions :** Ligues majeures mondiales.
- **Profondeur de l'historique :** Saisons récentes (2 à 5 ans accessibles par date).
- **Calendriers & Matchs à venir :** Oui (paramètre `?dates=YYYYMMDD`).
- **Scores en direct :** **OUI** (statut `in` avec chronomètre, quarts-temps, sets de tennis, buts, cartons).
- **Statistiques disponibles :** Possession, tirs, fautes, corners, buteurs, cartons, arrêts.
- **Format de données :** JSON volumineux.
- **Authentification :** Aucune clé requise (en-têtes CORS ouverts `*`).
- **Quota gratuit & Limites de fréquence :** Non documenté ; cache serveur de 7 secondes (`cache-control: max-age=7`).
- **Licence & Conditions d'utilisation :** **Propriétaire Disney / ESPN Interactive Media**. Les conditions d'utilisation interdisent tout robot ou scraping non autorisé.
- **Autorisation de réutilisation & Stockage local :** **NON GARANTIE JURIDIQUEMENT**.
- **Attribution requise :** N/A (service non ouvert publiquement aux tiers).
- **Restrictions techniques & Robots.txt :** `robots.txt` d'ESPN interdit expressément les crawlers IA (`GPTBot`, `CCBot`, `anthropic-ai`) et de nombreux chemins statistiques.
- **Fiabilité & Fraîcheur :** Excellente latence technique, mais risque permanent de modification de schéma d'URL ou de blocage IP par Akamai/Fastly.
- **Facilité d'intégration Flutter / SQLite :** Facile techniquement, mais format JSON lourd nécessitant un filtrage sévère.
- **Coût estimé :** **0,00 €** (aucun coût technique direct).
- **Risques :** Risque juridique de non-respect des CGU Disney et risque de rupture de service sans préavis.
- **Verdict :** **CONDITIONAL / HIGH-RISK** (À n'utiliser qu'en passerelle de secours optionnelle, jamais comme dépendance pivot).

---

### Fiche 08 : Balldontlie API
- **Nom officiel :** Balldontlie (NBA Analytics)
- **URL officielle :** https://www.balldontlie.io / API : https://api.balldontlie.io/v1/
- **Type :** API REST JSON dédiée au Basketball (NBA).
- **Sports couverts :** Basketball (NBA uniquement).
- **Pays & Compétitions :** NBA (Saisons régulières, playoffs, pré-saisons).
- **Profondeur de l'historique :** Depuis 1979 jusqu'à nos jours.
- **Calendriers & Matchs à venir :** Oui (`/games?dates[]=...`).
- **Scores en direct :** **OUI** (`/games` avec scores par quart-temps et temps restant).
- **Statistiques disponibles :** Statistiques de match complètes (rebonds, passes, interceptions, contres, pourcentages de tir, temps de jeu des joueurs).
- **Format de données :** JSON.
- **Authentification :** Clé API gratuite requise (`Authorization: <api_key>`) suite à la migration v1 (HTTP 401 vérifié sans clé lors de l'audit).
- **Quota gratuit & Limites de fréquence :** **30 requêtes par minute** sur le niveau gratuit.
- **Licence & Conditions d'utilisation :** Propriétaire avec niveau gratuit développeur.
- **Autorisation de réutilisation & Stockage local :** Cache autorisé.
- **Attribution requise :** Oui.
- **Restrictions techniques & Robots.txt :** Hébergé sur Render / Cloudflare, stable.
- **Fiabilité & Fraîcheur :** Très haute qualité pour la NBA.
- **Facilité d'intégration Flutter / SQLite :** Excellente.
- **Coût estimé :** **0,00 €** (plan gratuit suffisant pour une synchronisation NBA).
- **Risques :** Limité à la seule ligue NBA (pas d'Euroligue ni d'autres championnats).
- **Verdict :** **RECOMMENDED FOR BASKETBALL** (Source de référence si le basketball est activé).

---

### Fiche 09 : Jolpica-F1 (Successeur Ergast)
- **Nom officiel :** Jolpica-F1 (Ergast API Compatible)
- **URL officielle :** https://api.jolpi.ca/ergast/f1/
- **Type :** API REST JSON open-source pour le sport automobile (Formule 1).
- **Sports couverts :** Motorsport (Formule 1).
- **Pays & Compétitions :** Championnat du Monde de F1 FIA depuis 1950 jusqu'à aujourd'hui.
- **Profondeur de l'historique :** Historique complet de la F1 (74+ saisons).
- **Calendriers & Matchs à venir :** Oui (calendrier des Grands Prix de la saison).
- **Scores en direct :** Non (résultats après qualifications, sprints et courses).
- **Statistiques disponibles :** Temps au tour, arrêts aux stands, classements pilotes, classements constructeurs, positions de grille.
- **Format de données :** JSON.
- **Authentification :** **Aucune**.
- **Quota gratuit & Limites de fréquence :** Gratuit et ouvert (~4 requêtes par seconde recommandées).
- **Licence & Conditions d'utilisation :** Open Source / Open Data (CC BY 4.0).
- **Autorisation de réutilisation & Stockage local :** Totale avec attribution.
- **Attribution requise :** Oui ("Données F1 fournies par Jolpica-F1 / Ergast Archive").
- **Restrictions techniques & Robots.txt :** Aucune restriction bot constatée.
- **Fiabilité & Fraîcheur :** Haute qualité, projet communautaire actif sur GitHub.
- **Facilité d'intégration Flutter / SQLite :** Très bonne.
- **Coût estimé :** **0,00 €**.
- **Risques :** Aucun risque commercial ; charge serveur communautaire à respecter.
- **Verdict :** **RECOMMENDED FOR MOTORSPORT** (Source modèle pour les sports mécaniques).

---

### Fiche 10 : Jeff Sackmann / Tennis Match Charting Project
- **Nom officiel :** Tennis Match Charting Project & Tennis Analytics Repositories
- **URL officielle :** https://github.com/JeffSackmann/tennis_MatchChartingProject
- **Type :** Dépôts publics GitHub, fichiers CSV et points par points.
- **Sports couverts :** Tennis (ATP, WTA, Challengers).
- **Pays & Compétitions :** Tournois du Grand Chelem, Masters 1000, tournois ATP/WTA 500 et 250.
- **Profondeur de l'historique :** De 1968 aux années récentes.
- **Calendriers & Matchs à venir :** Non (strictement historique).
- **Scores en direct :** **NON**.
- **Statistiques disponibles :** Aces, doubles fautes, balles de break converties, pourcentages de premier service, points gagnés au retour.
- **Format de données :** CSV.
- **Authentification :** Aucune.
- **Quota gratuit & Limites de fréquence :** Illimité en local / quotas Git standards.
- **Licence & Conditions d'utilisation :** Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA 4.0).
- **Autorisation de réutilisation & Stockage local :** Autorisée pour usage non-commercial.
- **Attribution requise :** Oui (Mention expresse de Jeff Sackmann).
- **Restrictions techniques & Robots.txt :** Dépôts principaux périodiquement renommés ou basculés en privé (comme vérifié lors de l'audit technique avec le statut 404 sur `tennis_atp`), ce qui impose de s'appuyer sur des clones locaux archivés ou des forks communautaires stables.
- **Fiabilité & Fraîcheur :** Fiabilité statistique inégalée pour les modèles de tennis.
- **Facilité d'intégration Flutter / SQLite :** Bonne via import CSV local.
- **Coût estimé :** **0,00 €**.
- **Risques :** Volatilité des dépôts distants en ligne ; absence totale de flux de matchs programmés ou en direct.
- **Verdict :** **CONDITIONAL (ARCHIVE STATIQUE EXCLUSIVE)**.

---

### Fiche 11 : FlashScore / SofaScore (Web Scraping Direct)
- **Nom officiel :** FlashScore (Livesport Media) / SofaScore
- **URL officielle :** https://www.flashscore.com / https://www.sofascore.com
- **Type :** Portails web grand public et applications mobiles propriétaires.
- **Sports couverts :** Plus de 35 sports en temps réel.
- **Pays & Compétitions :** Quasi totalité des ligues mondiales.
- **Profondeur de l'historique :** 15+ ans.
- **Calendriers & Matchs à venir :** Oui.
- **Scores en direct :** Oui, temps réel instantané.
- **Statistiques disponibles :** Statistiques détaillées, cotes en direct, heatmaps.
- **Format de données :** HTML / WebSocket chiffré / Flux internes dynamiques.
- **Authentification :** N/A pour la navigation web publique.
- **Quota gratuit & Limites de fréquence :** Non applicable (aucune API publique mise à disposition).
- **Licence & Conditions d'utilisation :** **Strictement propriétaires et restrictives**.
- **Autorisation de réutilisation & Stockage local :** **FORMELLEMENT INTERDITE**. Les CGU interdisent explicitement l'extraction de données, le scraping, le reverse-engineering et le stockage local de leurs bases.
- **Attribution requise :** Non applicable (aucun contrat de redistribution grand public).
- **Restrictions techniques & Robots.txt :**
  - **FlashScore `robots.txt` :** Interdit explicitement tous les robots sur `/live/`, `/finished/`, `/scheduled/`, `/tennis/`, `/basketball/`, etc. (vérifié techniquement).
  - **SofaScore :** Protection Cloudflare / DataDome renvoyant **HTTP 403 Forbidden** immédiat sur toute tentative d'interrogation automatisée (vérifié techniquement).
- **Fiabilité & Fraîcheur :** Inexploitable de manière pérenne sans risquer un bannissement d'IP ou une action en justice.
- **Facilité d'intégration Flutter / SQLite :** Nulle (nécessiterait des parseurs HTML fragiles cassant à chaque mise à jour de l'interface).
- **Coût estimé :** 0 € au départ, mais coûts techniques élevés de contournement (proxies résidentiels, captcha solvers) proscrits par notre politique.
- **Risques :** Blocage IP immédiat, mise en demeure légale, instabilité absolue.
- **Verdict :** **REJECTED** (Scraping interdit par la politique du projet et techniquement bloqué).

---

### Fiche 12 : MelBet (Bookmaker)
- **Nom officiel :** MelBet
- **URL officielle :** https://melbet.com
- **Type :** Opérateur de paris sportifs en ligne.
- **Sports couverts :** Multisport avec marchés de paris.
- **Statut d'accès :** **DISABLED_BY_POLICY** (confirmé par l'audit Phase 0 et Phase 1).
- **Motif d'exclusion :**
  1. Aucune API publique autorisée ni documentation d'accès aux flux.
  2. Les CGU interdisent formellement l'utilisation de robots et la capture de données.
  3. Risque d'incitation aux jeux d'argent et non-conformité avec les politiques Google Play Store relatives aux applications intégrant des plateformes de paris non régulées.
  4. L'implémentation logicielle actuelle (`MelbetDataSource`) lève obligatoirement `ConnectorDisabledException`.
- **Verdict :** **REJECTED / STRICTLY DISABLED_BY_POLICY**.
