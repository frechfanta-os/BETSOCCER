# BETSOCCER — RÉSULTATS DÉTAILLÉS DES TESTS TECHNIQUES ET DU SCRAPING (PHASE 1.5)

**Date d'exécution :** 13 octobre 2026  
**Environnement de test :** Linux (PRoot Ubuntu) / curl 7.88+ / Dart 3.13 / Flutter 3.47  
**Projet :** BETSOCCER (`com.ghdinteractivestudio.betsoccer`)

---

## 1. Protocole de Mesure et Critères d'Évaluation

Pour chaque source testée, nous avons évalué :
- **Disponibilité (Status HTTP)** : Réponse réseau 200 OK ou code d'erreur explicite.
- **Temps de réponse (Latence)** : Mesuré en millisecondes depuis l'environnement PRoot.
- **Validité des champs structurels** : Présence obligatoire de l'identifiant, de la compétition, des équipes, de la date UTC, du statut et du score.
- **Détection des anomalies** : Valeurs nulles inattendues, doublons de clés primaires, dates non conformes ISO-8601.
- **Comportement sous quota & en-têtes** : Détection des limitations de débit et politiques CORS.

---

## 2. Rapports de Tests Individuels

### Test T01 : OpenLigaDB (Matchs Bundesliga 1 & Sports Allemands)
- **Endpoint testé :** `https://api.openligadb.de/getmatchdata/bl1/2023/1`
- **Date & Heure :** 2026-10-13 16:10:44 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~290 ms
- **Enregistrements reçus :** 9 matchs
- **Enregistrements valides :** 9 matchs (100%)
- **Doublons détectés :** 0
- **Validation des champs essentiels :**
  - Identifiant : `matchID` (ex: `66638`, entier unique).
  - Date & Heure : `matchDateTimeUTC` (ex: `2023-08-19T13:30:00Z`).
  - Équipes : `team1.teamName` ("VfB Stuttgart"), `team2.teamName` ("VfL Bochum").
  - Statut : `matchIsFinished: true`.
  - Résultat : `matchResults` contenant `Halbzeitergebnis` (2-0) et `Endergebnis` (5-0).
  - Détail des buts : `goals` avec `goalGetterName`, `matchMinute`, `isPenalty`.
- **Extrait réel anonymisé :**
```json
{
  "matchID": 66638,
  "matchDateTimeUTC": "2023-08-19T13:30:00Z",
  "leagueShortcut": "bl1",
  "team1": { "teamId": 16, "teamName": "VfB Stuttgart" },
  "team2": { "teamId": 129, "teamName": "VfL Bochum" },
  "matchIsFinished": true,
  "matchResults": [
    { "resultName": "Halbzeitergebnis", "pointsTeam1": 2, "pointsTeam2": 0 },
    { "resultName": "Endergebnis", "pointsTeam1": 5, "pointsTeam2": 0 }
  ]
}
```

---

### Test T02 : OpenLigaDB (Handball & Volleyball)
- **Endpoints testés :**  
  - Handball : `https://api.openligadb.de/getmatchdata/hbl/2023/1`
  - Volleyball : `https://api.openligadb.de/getmatchdata/vblf1/2023/1`
- **Date & Heure :** 2026-10-13 16:19:36 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~320 ms
- **Enregistrements reçus :** 9 matchs Handball (`HBL`), 5 matchs Volleyball (`vblf1`)
- **Enregistrements valides :** 14 matchs (100%)
- **Validation multisport :**
  - En Handball, les scores de mi-temps et finaux sont renseignés (ex: TSV Hannover-Burgdorf).
  - En Volleyball féminin, les scores par set sont structurés dans `matchResults`.

---

### Test T03 : Football-Data.co.uk (Archive CSV Premier League)
- **URL testée :** `https://football-data.co.uk/mmz4281/2324/E0.csv`
- **Date & Heure :** 2026-10-13 16:13:34 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK` (après redirection HTTP 302 depuis le sous-domaine www)
- **Temps de réponse :** ~410 ms
- **Taille de l'archive :** ~170 Ko
- **Enregistrements reçus :** 380 matchs (saison complète Premier League 2023/24)
- **Enregistrements valides :** 380 matchs (100%)
- **Champs statistiques avancés validés :**
  - Tirs totaux : `HS` (Burnley: 6), `AS` (Man City: 17).
  - Tirs cadrés : `HST` (Burnley: 1), `AST` (Man City: 8).
  - Fautes : `HF` (11), `AF` (8).
  - Corners : `HC` (6), `AC` (5).
  - Cartons : `HY` (0), `AY` (0), `HR` (1), `AR` (0).
- **Extrait réel anonymisé :**
```csv
Div,Date,Time,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HTHG,HTAG,HTR,Referee,HS,AS,HST,AST,HF,AF,HC,AC,HY,AY,HR,AR
E0,11/08/2023,20:00,Burnley,Man City,0,3,A,0,2,A,C Pawson,6,17,1,8,11,8,6,5,0,0,1,0
E0,12/08/2023,12:30,Arsenal,Nott'm Forest,2,1,H,2,0,H,M Oliver,15,6,7,2,12,12,8,3,2,2,0,0
```

---

### Test T04 : TheSportsDB (API V1 Clé Publique 3)
- **Endpoint testé :** `https://www.thesportsdb.com/api/v1/json/3/eventsseason.php?id=4328&s=2023-2024`
- **Date & Heure :** 2026-10-13 16:11:08 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~380 ms (Cache Cloudflare `HIT`)
- **Enregistrements reçus :** 380 événements
- **Enregistrements valides :** 380 (100%)
- **Champs essentiels validés :**
  - `idEvent`: "1818395"
  - `strEvent`: "Burnley vs Manchester City"
  - `intHomeScore`: "0", `intAwayScore`: "3"
  - `strTimestamp`: "2023-08-11T19:00:00"
  - `strHomeTeamBadge` & `strAwayTeamBadge` : URLs CDN Cloudflare R2 d'images valides.

---

### Test T05 : Football-Data.org (Endpoint Compétitions & Matches V4)
- **Endpoints testés :**
  - `https://api.football-data.org/v4/competitions`
  - `https://api.football-data.org/v4/matches`
- **Date & Heure :** 2026-10-13 16:11:18 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~185 ms
- **En-têtes de limitation observés :**
  - `X-Requests-Available: 48`
  - `X-RequestCounter-Reset: 78301`
  - `X-Authenticated-Client: anonymous`
- **Comportement :** L'endpoint retourne la liste des compétitions sans jeton, mais verrouille les données de détail des ligues non couvertes par le plan gratuit.

---

### Test T06 : Jolpica-F1 (Formule 1 Open Data)
- **Endpoint testé :** `https://api.jolpi.ca/ergast/f1/2023/results.json?limit=2`
- **Date & Heure :** 2026-10-13 16:19:30 UTC
- **Résultat :** **PASS**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~240 ms
- **Enregistrements reçus :** 2 courses (sur 440 résultats totaux)
- **Enregistrements valides :** 100%
- **Champs validés :** `raceName`, `Circuit`, `date`, `time`, `Driver` (`max_verstappen`), `position: 1`, `points: 25`.
- **Extrait réel anonymisé :**
```json
{
  "MRData": {
    "series": "f1",
    "total": "440",
    "RaceTable": {
      "season": "2023",
      "Races": [{
        "round": "1",
        "raceName": "Bahrain Grand Prix",
        "date": "2023-03-05",
        "time": "15:00:00Z",
        "Results": [{ "position": "1", "points": "25", "Driver": { "driverId": "max_verstappen" } }]
      }]
    }
  }
}
```

---

### Test T07 : Balldontlie API (Basketball NBA)
- **Endpoint testé :** `https://api.balldontlie.io/v1/teams`
- **Date & Heure :** 2026-10-13 16:18:42 UTC
- **Résultat :** **PASS (AUTHENTICATION ENFORCED)**
- **Code HTTP :** `401 Unauthorized`
- **Temps de réponse :** ~210 ms
- **Analyse :** Confirme la spécification technique de Balldontlie v1 imposant l'en-tête `Authorization: <api_key>`. Le service est opérationnel et répond immédiatement avec le message `Unauthorized`.

---

### Test T08 : API-SPORTS / API-Football
- **Endpoint testé :** `https://v3.football.api-sports.io/status`
- **Date & Heure :** 2026-10-13 16:11:27 UTC
- **Résultat :** **PASS (AUTHENTICATION ENFORCED)**
- **Code HTTP :** `403 Forbidden`
- **Corps de réponse :** `{"errors": {"token": "Missing application key"}}`
- **Analyse :** Confirme le verrouillage strict sans clé `x-apisports-key`. Le service est réactif et opérationnel sous réserve de déclaration du secret.

---

### Test T09 : ESPN Site Scoreboard API
- **Endpoints testés :**
  - Soccer : `https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard`
  - Basketball : `https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard`
  - Tennis : `https://site.api.espn.com/apis/site/v2/sports/tennis/atp/scoreboard`
- **Date & Heure :** 2026-10-13 16:13:02 UTC
- **Résultat :** **PASS (TECHNIQUE) / RESTRICTED (JURIDIQUE)**
- **Code HTTP :** `200 OK`
- **Temps de réponse :** ~310 ms
- **En-têtes observés :** `cache-control: max-age=7`, `access-control-allow-origin: *`.
- **Champs récupérés :** Scores en direct, possession, tirs cadrés, cartons, buts horodatés, compositions, cotes DraftKings associées.
- **Limites observées :** Absence totale de documentation d'API publique, risque de blocage arbitraire, CGU Disney interdisant l'utilisation automatisée non expressément autorisée.

---

### Test T10 : Scraping HTML FlashScore & SofaScore
- **Tests exécutés :**
  - `curl -s -I https://www.flashscore.com/` (HTTP 200, mais robots.txt interdit `/live/`, `/finished/`, `/scheduled/`).
  - `curl -s https://www.sofascore.com/robots.txt`
- **Date & Heure :** 2026-10-13 16:18:59 UTC
- **Résultat :** **FAIL (BLOCAGE ANTI-BOT ET RESTRICTIONS LÉGALES)**
- **Code HTTP SofaScore :** `403 Forbidden` (`{"error": {"code": 403, "reason": "Forbidden"}}`).
- **Analyse d'échec :**
  - SofaScore bloque activement toute requête sans empreinte de navigateur légitime au niveau du reverse-proxy Cloudflare / DataDome.
  - FlashScore interdit expressément l'accès automatique à ses flux de résultats dans son fichier `robots.txt`.
  - **Verdict sans appel :** Tout scraping automatisé de ces plateformes est **techniquement instable et juridiquement interdit**.

---

### Test T11 : Tennis-Data.co.uk
- **URL testée :** `https://tennis-data.co.uk/alldata.php`
- **Date & Heure :** 2026-10-13 16:18:37 UTC
- **Résultat :** **FAIL (NETWORK TIMEOUT)**
- **Code d'erreur curl :** `28 (Connection timed out)`
- **Analyse d'échec :** Le serveur Cloudflare devant `tennis-data.co.uk` rejette ou laisse expirer les connexions TLS/HTTPS provenant de certaines plages d'adresses IP de centres de données. La source n'est pas fiable pour une synchronisation directe automatisée.
