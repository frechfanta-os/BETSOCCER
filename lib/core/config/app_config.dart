enum Environment { development, staging, production }

/// Configuration globale de l'application BETSOCCER
class AppConfig {
  final Environment environment;
  final String appTitle;
  final String applicationId;
  final bool melbetEnabled;
  final String theSportsDbBaseUrl;
  final String theSportsDbApiKey;
  final String footballDataOrgBaseUrl;
  final String? footballDataOrgApiKey;

  const AppConfig({
    required this.environment,
    this.appTitle = 'BETSOCCER — Multisport Analytics AI',
    this.applicationId = 'com.ghdinteractivestudio.betsoccer',
    this.melbetEnabled =
        false, // STRICTEMENT DÉSACTIVÉ PAR POLITIQUE (DISABLED_BY_POLICY)
    this.theSportsDbBaseUrl = 'https://www.thesportsdb.com/api/v1/json',
    this.theSportsDbApiKey = '3', // Clé de test publique gratuite officielle
    this.footballDataOrgBaseUrl = 'https://api.football-data.org/v4',
    this.footballDataOrgApiKey,
  });

  static AppConfig current = const AppConfig(
    environment: Environment.development,
  );
}
