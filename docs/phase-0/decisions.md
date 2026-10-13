# BETSOCCER — REGISTRE DES DÉCISIONS D'ARCHITECTURE (ADR) (PHASE 0)

**Date d'audit :** 13 Octobre 2026  
**Auteur :** Collège d'Architecture Logicielle & DevOps  
**Projet :** BETSOCCER — Multisport Analytics AI  
**Statut :** DÉCISIONS FORMELLEMENT CONSIGNEES

---

## ADR-001 : APPLICATION FLUTTER OFFLINE-FIRST AVEC BASE SQLITE LOCALE (DRIFT)

### Contexte :
Le projet nécessite une haute disponibilité, une exécution fluide sur terminaux Android et un coût d'infrastructure nul. Un backend distant obligatoire introduirait des coûts d'hébergement, des risques de panne et des temps de latence réseau.

### Décision :
Concevoir l'application selon le modèle **Offline-First**. Toutes les données sont persistées localement dans une base de données relationnelle **SQLite** gérée via le framework Dart **Drift**. L'application démarre et fonctionne même en l'absence totale de réseau.

### Conséquences :
- **Positives :** Coût serveur nul (0 €), vitesse de chargement instantanée, fonctionnement hors ligne complet, indépendance vis-à-vis des pannes serveurs.
- **Négatives :** Les mises à jour de données dépendent de la synchronisation déclenchée par l'appareil mobile.

---

## ADR-002 : MOTEUR STATISTIQUE DÉTERMINISTE NATIF DART (INDÉPENDANCE DE L'IA)

### Contexte :
Les modèles de langage (LLM) sont probabilistes et sujets aux hallucinations numériques. Confier le calcul des probabilités de match (ex: cotes, pourcentages de victoire, expected goals) à un modèle IA provoquerait des incohérences graves, des probabilités ne sommant pas à 100% ou des données inventées.

### Décision :
Développer l'intégralité du moteur de prédiction statistique en **Dart pur déterministe** (Loi de Poisson bivariée, correction Dixon-Coles, pondération Elo dynamique, forme récente). L'algorithme calcule mathématiquement les valeurs exactes. L'IA n'est sollicitée que pour vulgariser et expliquer les résultats obtenus.

### Conséquences :
- **Positives :** Répétabilité absolue, rigueur scientifique, zéro hallucination sur les chiffres, rapidité de calcul en local.
- **Négatives :** Nécessite une implémentation soignée des algorithmes matriciels en Dart.

---

## ADR-003 : ORCHESTRATION IA VIA OPENROUTER AVEC FORMAT JSON STRICT ET REPLI LOCAL

### Contexte :
L'application doit proposer des explications analytiques enrichies sans obliger l'utilisateur à payer des abonnements coûteux à des modèles propriétaires. Une clé OpenRouter existante a été auditée avec succès dans l'environnement.

### Décision :
Utiliser l'API **OpenRouter** avec une interface commune `AiProviderInterface` et une chaîne de repli (*fallback chain*) ciblant les modèles gratuits (:free) tels que `nvidia/nemotron-3.5-lightning:free`. Les réponses sont contraintes au format JSON strict (`response_format: {"type": "json_object"}`). En cas d'indisponibilité réseau ou de quota dépassé, un générateur de synthèse déterministe local prend le relais sans bloquer l'interface.

### Conséquences :
- **Positives :** Zéro coût d'inférence obligatoire, diversité de modèles, résilience garantie par le fallback local.
- **Négatives :** Disponibilité variable des modèles gratuits tiers imposant une gestion rigoureuse des erreurs.

---

## ADR-004 : AGRÉGATION DE DONNÉES BASÉE SUR OPENFOOTBALL (CC0) ET THESPORTSDB / FOOTBALL-DATA.ORG

### Contexte :
L'accès aux données sportives professionnelles est souvent soumis à des licences onéreuses ou des quotas stricts. L'application doit disposer d'un historique profond sans violer de droits d'auteur.

### Décision :
1. Exploiter les jeux de données **OpenFootball (`football.db`)** sous licence Domaine Public (CC0 1.0) pour pré-embarquer l'historique complet des championnats.
2. Interroger **TheSportsDB (V1)** (clé publique de test `3`) pour les métadonnées (logos, stades, ligues).
3. Utiliser **Football-Data.org** (plan gratuit 10 req/min) pour les calendriers et résultats courants.

### Conséquences :
- **Positives :** Sécurité juridique totale, gratuité assurée, base de données immédiatement riche dès le premier lancement.
- **Négatives :** Nécessité d'adapter les schémas pour réconcilier les identifiants d'équipes entre les sources.

---

## ADR-005 : REJET FORMEL DU SCRAPING MELBET (INCOMPATIBILITÉ JURIDIQUE ET TECHNIQUE)

### Contexte :
La possibilité d'extraire des données de MelBet a été envisagée pour examen.

### Décision :
**Exclure et bloquer définitivement tout scraping ou tentative d'interrogation de MelBet.**
- Les CGU de MelBet interdisent expressément les robots et le scraping.
- La plateforme utilise des technologies anti-bot (Cloudflare Bot Management).
- MelBet est un opérateur de paris, alors que BETSOCCER a pour mandat exclusif l'analyse sportive statistique, excluant les marchés de cotes et paris.

### Conséquences :
- **Positives :** Respect irréprochable des lois et des CGU, élimination de tout risque de bannissement ou de code cassé lors des modifications web de MelBet.
- **Négatives :** Aucune (les données sportives sont fournies plus proprement par les API dédiées).

---

## ADR-006 : CI/CD ET COMPILATION APK SUR GITHUB ACTIONS (DÉCHARGE DU PROOT)

### Contexte :
L'environnement local fonctionne sur un système Android Termux avec conteneur Ubuntu PRoot aarch64. Cet environnement dispose de ressources limitées et ne contient pas de SDK Android complet.

### Décision :
- Réaliser localement les tâches légères : développement Dart/Flutter, formatage de code, analyse statique (`flutter analyze`) et tests unitaires (`flutter test`).
- Déléguer l'ensemble de la compilation binaire Android (`flutter build apk --release`) et de la génération des artefacts aux exécuteurs **GitHub Actions** (`ubuntu-latest`).

### Conséquences :
- **Positives :** Aucune surcharge mémoire ou disque sur le terminal mobile, builds propres, reproductibles et automatisés dans le cloud.
- **Négatives :** La génération d'un APK testable nécessite un push sur GitHub.

---

## ADR-007 : RESPECT IMPÉRATIF DE LA CONVENTION DE NOMMAGE ET STANDARD OTA DE `/root/AGENTS.md`

### Contexte :
Le projet doit respecter les règles d'organisation fixées dans `/root/AGENTS.md` :
1. Application ID sous le domaine de l'organisation : `com.ghdinteractivestudio.betsoccer`.
2. Standard de mise à jour in-app (OTA) conforme à la v1.0.11.

### Décision :
Appliquer strictement ces directives dès la Phase 1 :
- Commande Flutter : `flutter create --org com.ghdinteractivestudio --project-name betsoccer betsoccer`.
- Pipeline CI produisant obligatoirement `app-release.apk` et `BETSOCCER-v${PUBSPEC_VERSION_NAME}.apk`, accompagnés de leur condensat cryptographique `app-release.apk.sha256`.
- Validation in-app SHA-256 et vérification de compatibilité de package avant toute tentative d'installation.

### Conséquences :
- **Positives :** Conformité totale avec l'écosystème du studio, distribution sécurisée et fiabilité des futures mises à jour directes sans passer par le Play Store.
