import 'package:sqflite/sqflite.dart';

import 'migration.dart';

/// Migration V1 : Schéma relationnel initial complet pour BETSOCCER
class V1InitialSchema implements Migration {
  @override
  int get version => 1;

  @override
  String get description =>
      'Création initiale des 10 tables du modèle sportif, statistiques et synchronisation';

  @override
  Future<void> up(Database db) async {
    // 1. Table: sports
    await db.execute('''
      CREATE TABLE sports (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        icon_ref TEXT,
        source_provider TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_sports_code ON sports (code);');

    // 2. Table: competitions
    await db.execute('''
      CREATE TABLE competitions (
        id TEXT PRIMARY KEY,
        sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        code TEXT,
        country TEXT,
        country_code TEXT,
        badge_url TEXT,
        tier INTEGER,
        source_provider TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_competitions_sport ON competitions (sport_id);',
    );

    // 3. Table: seasons
    await db.execute('''
      CREATE TABLE seasons (
        id TEXT PRIMARY KEY,
        competition_id TEXT NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
        year_label TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        is_current INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE(competition_id, year_label)
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_seasons_comp ON seasons (competition_id);',
    );

    // 4. Table: teams
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        short_name TEXT,
        tla TEXT,
        badge_url TEXT,
        country TEXT,
        elo_rating REAL NOT NULL DEFAULT 1500.0,
        source_provider TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(sport_id, name)
      );
    ''');
    await db.execute('CREATE INDEX idx_teams_name ON teams (name);');

    // 5. Table: players
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        team_id TEXT REFERENCES teams(id) ON DELETE SET NULL,
        name TEXT NOT NULL,
        position TEXT,
        nationality TEXT,
        photo_url TEXT,
        source_provider TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // 6. Table: matches
    await db.execute('''
      CREATE TABLE matches (
        id TEXT PRIMARY KEY,
        sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
        competition_id TEXT NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
        season_id TEXT REFERENCES seasons(id) ON DELETE SET NULL,
        home_team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
        away_team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
        utc_kickoff TEXT NOT NULL,
        status TEXT NOT NULL,
        matchday INTEGER,
        round_label TEXT,
        current_minute TEXT,
        is_sample_data INTEGER NOT NULL DEFAULT 0,
        source_provider TEXT NOT NULL,
        source_match_id TEXT,
        last_synced_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(competition_id, home_team_id, away_team_id, utc_kickoff)
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_matches_kickoff ON matches (utc_kickoff);',
    );
    await db.execute('CREATE INDEX idx_matches_status ON matches (status);');
    await db.execute(
      'CREATE INDEX idx_matches_comp ON matches (competition_id);',
    );

    // 7. Table: results
    await db.execute('''
      CREATE TABLE results (
        id TEXT PRIMARY KEY,
        match_id TEXT NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
        home_score INTEGER,
        away_score INTEGER,
        home_halftime_score INTEGER,
        away_halftime_score INTEGER,
        home_extratime_score INTEGER,
        away_extratime_score INTEGER,
        home_penalties_score INTEGER,
        away_penalties_score INTEGER,
        winner_team_id TEXT REFERENCES teams(id) ON DELETE SET NULL,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_results_match ON results (match_id);');

    // 8. Table: match_statistics
    await db.execute('''
      CREATE TABLE match_statistics (
        id TEXT PRIMARY KEY,
        match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
        metric_name TEXT NOT NULL,
        home_value REAL,
        away_value REAL,
        raw_unit TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(match_id, metric_name)
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_stats_match ON match_statistics (match_id);',
    );

    // 9. Table: data_sources
    await db.execute('''
      CREATE TABLE data_sources (
        provider_id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        policy_status TEXT NOT NULL DEFAULT 'ACTIVE',
        rate_limit_per_minute INTEGER,
        created_at TEXT NOT NULL
      );
    ''');

    // 10. Table: sync_state
    await db.execute('''
      CREATE TABLE sync_state (
        key TEXT PRIMARY KEY,
        provider_id TEXT NOT NULL REFERENCES data_sources(provider_id),
        last_synced_at TEXT NOT NULL,
        records_synced INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        error_message TEXT
      );
    ''');

    // Insertion des sources configurées par défaut
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.execute('''
      INSERT INTO data_sources (provider_id, display_name, is_enabled, policy_status, rate_limit_per_minute, created_at)
      VALUES 
        ('openfootball', 'OpenFootball (Domaine Public CC0)', 1, 'ACTIVE', NULL, '$nowIso'),
        ('thesportsdb', 'TheSportsDB API (V1 Test)', 1, 'ACTIVE', 100, '$nowIso'),
        ('football_data_org', 'Football-Data.org (Plan Gratuit)', 1, 'ACTIVE', 10, '$nowIso'),
        ('melbet_restricted', 'MelBet (Désactivé par politique)', 0, 'DISABLED_BY_POLICY', NULL, '$nowIso');
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS sync_state;');
    await db.execute('DROP TABLE IF EXISTS data_sources;');
    await db.execute('DROP TABLE IF EXISTS match_statistics;');
    await db.execute('DROP TABLE IF EXISTS results;');
    await db.execute('DROP TABLE IF EXISTS matches;');
    await db.execute('DROP TABLE IF EXISTS players;');
    await db.execute('DROP TABLE IF EXISTS teams;');
    await db.execute('DROP TABLE IF EXISTS seasons;');
    await db.execute('DROP TABLE IF EXISTS competitions;');
    await db.execute('DROP TABLE IF EXISTS sports;');
  }
}
