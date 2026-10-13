# BETSOCCER — REVUE JURIDIQUE, LICENCES ET CONFORMITÉ DES DONNÉES (PHASE 1.5)

**Date d'audit :** 13 octobre 2026  
**Domaine :** Droit de la propriété intellectuelle, droit *sui generis* des bases de données, conformité RGPD et jurisprudence relative aux données sportives.  
**Projet :** BETSOCCER (`com.ghdinteractivestudio.betsoccer`)

---

## 1. Cadre Juridique Applicable aux Données Sportives

### 1.1 Droit d'Auteur et Faits Bruts (Idée vs Expression)
Dans toutes les juridictions majeures (Union Européenne, États-Unis, Royaume-Uni), **les faits bruts, les événements sportifs et les scores ne sont pas protégeables par le droit d'auteur classique** :
- Un résultat de match (ex: "Arsenal 2 - 1 Chelsea"), le nom des joueurs, la minute d'un but ou le nombre de corners constituent des **faits historiques du monde réel** insusceptibles d'appropriation exclusive.
- En droit américain, la doctrine *Hot News Misappropriation* et l'arrêt historique de la Cour Suprême (*Feist Publications v. Rural Telephone Service*, 1991) confirment que le simple fait de compiler des données sans originalité créative ne crée pas de copyright sur les données elles-mêmes.
- En Europe, la Cour de Justice de l'Union Européenne (CJUE) a confirmé dans l'affaire de référence **Football Dataco Ltd v. Yahoo! UK Ltd (C-604/10, 2012)** qu'un calendrier de rencontres de football (fixture list) ne bénéficie pas de la protection du droit d'auteur si sa confection est dictée par des contraintes techniques, logiques ou réglementaires dépourvues d'expression créative originale.

### 1.2 Droit *Sui Generis* sur les Bases de Données (Directive Européenne 96/9/CE)
La directive européenne 96/9/CE accorde aux fabricants de bases de données un droit d'interdire l'extraction ou la réutilisation substantielle de leur contenu s'ils justifient d'un **investissement substantiel dans l'obtention, la vérification ou la présentation** des données :
- Dans les arrêts fondateurs **Fixtures Marketing / British Horseracing Board (CJUE C-203/02 et C-338/02, 2004)**, la CJUE a posé une distinction fondamentale :
  - **L'investissement lié à la création des données** (ex: organiser la compétition, planifier le match, payer les arbitres) n'est **PAS** protégé par le droit *sui generis*.
  - Seul l'investissement consacré à la **recherche et à la collecte d'éléments existants** pour constituer la base est protégé.
- **Conséquence pour BETSOCCER :** Une ligue sportive officielle ne peut pas revendiquer un droit *sui generis* sur les résultats de ses propres matchs qu'elle a elle-même créés. En revanche, un agrégateur commercial (ex: Sportradar, FlashScore, Opta) qui investit des millions d'euros pour vérifier et centraliser les données bénéficie d'un droit *sui generis* opposable.

---

## 2. Analyse des Licences des Sources Retenues

### 2.1 Creative Commons Zero (CC0 1.0 Universal) — OpenFootball
- **Nature :** Renonciation volontaire à tous les droits d'auteur et droits voisins dans la limite permise par la loi.
- **Droits conférés :** Copie, modification, distribution, intégration dans du code propriétaire et exploitation commerciale sans aucune redevance ni obligation de partage à l'identique.
- **Conformité BETSOCCER :** **100% CONFORME**. C'est le niveau de sécurité juridique le plus élevé possible pour le projet.

### 2.2 Creative Commons Attribution (CC BY 4.0) — OpenLigaDB & Jolpica-F1
- **Nature :** Licence libre de diffusion avec condition unique de paternité.
- **Droits conférés :** Utilisation et adaptation libres pour tout usage (y compris commercial et applicatif mobile).
- **Obligations :** Mentionner la source et la licence, et indiquer si des modifications ont été apportées.
- **Conformité BETSOCCER :** **100% CONFORME**. L'application intègre ces mentions dans l'écran *À Propos & Conformité* (`showAboutDialog` et `settings_screen.dart`).

### 2.3 Licences Non-Commerciales (CC BY-NC / CC BY-NC-SA) — Jeff Sackmann Tennis
- **Restrictions :** Interdiction d'exploitation commerciale directe.
- **Conformité BETSOCCER :** Acceptable tant que l'application reste entièrement gratuite et sans monétisation directe pour cette section. En cas de commercialisation future, ce jeu de données devrait être isolé ou remplacé.

---

## 3. Jurisprudence du Scraping Web et Conditions Générales (CGU)

### 3.1 Statut Juridique des Fichiers `robots.txt`
- Le standard `robots.txt` constitue une directive d'exclusion technique universellement reconnue.
- Si le non-respect d'un `robots.txt` ne constitue pas en soi une infraction pénale dans certaines juridictions, il est retenu par les tribunaux comme **la preuve manifeste du refus d'accès de l'éditeur**, qualifiant la violation délibérée des conditions d'utilisation contractuelles (breach of contract).
- Dans l'Union Européenne, la Directive Droit d'Auteur dans le Marché Unique Numérique (Directive 2019/790, article 4 sur la fouille de textes et de données — TDM) dispose que l'extraction est autorisée **sauf si le titulaire de droits a expressément réservé l'utilisation par des moyens appropriés, tels que des procédés lisibles par machine (ex: robots.txt)**.
- **Décision d'audit :** L'interdiction explicite dans `robots.txt` (ex: FlashScore sur `/live/`, `/finished/`) constitue une opposition légale formelle au sens de l'article 4 de la Directive 2019/790. Le scraping automatisé est donc juridiquement proscrit.

### 3.2 Cas Particulier MelBet
- Les opérateurs de paris sportifs intègrent des clauses de protection strictes contre l'arbitrage (*value betting* / *sure betting*) et l'aspiration de cotes en temps réel.
- L'utilisation de robots sur leurs plateformes enfreint directement leurs CGU et expose l'utilisateur ou l'éditeur à des sanctions civiles, au blocage de compte et au signalement de l'application auprès des magasins d'applications (Google Play / Apple App Store).
- **Confirmation :** Le maintien de `MelbetDataSource` sous l'état **DISABLED_BY_POLICY** est une obligation de sécurité juridique impérative.

---

## 4. Conformité RGPD et Données Personnelles

- Les données traitées par BETSOCCER relatives aux sportifs (noms, prénoms, nationalités, clubs, performances publiques) constituent des données à caractère personnel au sens de l'article 4(1) du RGPD.
- **Base légale du traitement :** **Intérêt légitime (Article 6(1)(f) RGPD)** pour le traitement de faits sportifs publics dans le cadre d'analyses statistiques.
- **Minimisation des données (Article 5(1)(c) RGPD) :** BETSOCCER ne collecte et ne stocke **aucune donnée sensible** (données médicales privées, salaires, vie privée des athlètes). Seules les performances publiques en compétition sont modélisées.
- **Données utilisateurs :** Strictement cloisonnées dans SQLite local sur le terminal Android. Aucune donnée d'identification personnelle de l'utilisateur n'est téléversée, préservant la souveraineté et la vie privée totale des utilisateurs.
