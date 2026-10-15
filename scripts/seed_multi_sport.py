import sqlite3
import datetime

DB_PATH = 'betsoccer.db'

def seed():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

    # 1. SPORTS
    sports = [
        ('sport_football', 'Football', 'SOCCER', 'sports_soccer', 'system', now_iso),
        ('sport_basketball', 'Basketball', 'BASKETBALL', 'sports_basketball', 'thesportsdb', now_iso),
        ('sport_tennis', 'Tennis', 'TENNIS', 'sports_tennis', 'thesportsdb', now_iso),
        ('sport_handball', 'Handball', 'HANDBALL', 'sports_handball', 'openligadb', now_iso),
        ('sport_volleyball', 'Volleyball', 'VOLLEYBALL', 'sports_volleyball', 'openligadb', now_iso),
    ]
    cur.executemany('''
        INSERT OR REPLACE INTO sports (id, name, code, icon_ref, source_provider, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', sports)

    # 2. COMPETITIONS
    competitions = [
        ('comp_nba', 'sport_basketball', 'NBA', 'NBA', 'USA', 'US', None, 1, 'thesportsdb', now_iso),
        ('comp_euroleague', 'sport_basketball', 'EuroLeague Basketball', 'EUROLEAGUE', 'Europe', 'EU', None, 1, 'thesportsdb', now_iso),
        ('comp_atp', 'sport_tennis', 'ATP World Tour Masters', 'ATP', 'International', 'INT', None, 1, 'thesportsdb', now_iso),
        ('comp_wta', 'sport_tennis', 'WTA Tour', 'WTA', 'International', 'INT', None, 1, 'thesportsdb', now_iso),
        ('comp_old_hbl', 'sport_handball', 'Handball Bundesliga (HBL)', 'HBL', 'Germany', 'DE', None, 1, 'openligadb', now_iso),
        ('comp_old_vblf1', 'sport_volleyball', '1. Volleyball Bundesliga Frauen', 'VBLF1', 'Germany', 'DE', None, 1, 'openligadb', now_iso),
        ('comp_tsdb_4328', 'sport_football', 'English Premier League', 'PL', 'England', 'GB', None, 1, 'thesportsdb', now_iso),
        ('comp_old_bl1', 'sport_football', '1. Bundesliga', 'BL1', 'Germany', 'DE', None, 1, 'openligadb', now_iso),
    ]
    cur.executemany('''
        INSERT OR REPLACE INTO competitions (id, sport_id, name, code, country, country_code, badge_url, tier, source_provider, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', competitions)

    # 3. TEAMS / PLAYERS
    teams = [
        # Basketball - NBA
        ('team_celtics', 'sport_basketball', 'Boston Celtics', 'BOS', 'BOS', None, 'USA', 1650, 'thesportsdb', now_iso),
        ('team_hornets', 'sport_basketball', 'Charlotte Hornets', 'CHA', 'CHA', None, 'USA', 1480, 'thesportsdb', now_iso),
        ('team_kings', 'sport_basketball', 'Sacramento Kings', 'SAC', 'SAC', None, 'USA', 1540, 'thesportsdb', now_iso),
        ('team_blazers', 'sport_basketball', 'Portland Trail Blazers', 'POR', 'POR', None, 'USA', 1490, 'thesportsdb', now_iso),
        ('team_lakers', 'sport_basketball', 'Los Angeles Lakers', 'LAL', 'LAL', None, 'USA', 1610, 'thesportsdb', now_iso),
        ('team_warriors', 'sport_basketball', 'Golden State Warriors', 'GSW', 'GSW', None, 'USA', 1590, 'thesportsdb', now_iso),
        ('team_nuggets', 'sport_basketball', 'Denver Nuggets', 'DEN', 'DEN', None, 'USA', 1680, 'thesportsdb', now_iso),
        ('team_suns', 'sport_basketball', 'Phoenix Suns', 'PHX', 'PHX', None, 'USA', 1580, 'thesportsdb', now_iso),
        ('team_mavericks', 'sport_basketball', 'Dallas Mavericks', 'DAL', 'DAL', None, 'USA', 1620, 'thesportsdb', now_iso),
        ('team_bucks', 'sport_basketball', 'Milwaukee Bucks', 'MIL', 'MIL', None, 'USA', 1640, 'thesportsdb', now_iso),
        ('team_heat', 'sport_basketball', 'Miami Heat', 'MIA', 'MIA', None, 'USA', 1560, 'thesportsdb', now_iso),
        ('team_knicks', 'sport_basketball', 'New York Knicks', 'NYK', 'NYK', None, 'USA', 1580, 'thesportsdb', now_iso),
        # Basketball - EuroLeague
        ('team_real_basket', 'sport_basketball', 'Real Madrid Baloncesto', 'RMB', 'RMB', None, 'Spain', 1620, 'thesportsdb', now_iso),
        ('team_panathinaikos', 'sport_basketball', 'Panathinaikos BC', 'PAO', 'PAO', None, 'Greece', 1610, 'thesportsdb', now_iso),
        ('team_monaco_basket', 'sport_basketball', 'AS Monaco Basket', 'ASM', 'ASM', None, 'Monaco', 1590, 'thesportsdb', now_iso),
        ('team_olympiacos', 'sport_basketball', 'Olympiacos BC', 'OLY', 'OLY', None, 'Greece', 1600, 'thesportsdb', now_iso),

        # Tennis - ATP Players
        ('player_alcaraz', 'sport_tennis', 'Carlos Alcaraz', 'ALC', 'ESP', None, 'Spain', 1950, 'thesportsdb', now_iso),
        ('player_sinner', 'sport_tennis', 'Jannik Sinner', 'SIN', 'ITA', None, 'Italy', 1980, 'thesportsdb', now_iso),
        ('player_djokovic', 'sport_tennis', 'Novak Djokovic', 'DJO', 'SRB', None, 'Serbia', 1920, 'thesportsdb', now_iso),
        ('player_medvedev', 'sport_tennis', 'Daniil Medvedev', 'MED', 'RUS', None, 'Monaco', 1850, 'thesportsdb', now_iso),
        ('player_zverev', 'sport_tennis', 'Alexander Zverev', 'ZVE', 'GER', None, 'Germany', 1880, 'thesportsdb', now_iso),
        ('player_ruud', 'sport_tennis', 'Casper Ruud', 'RUU', 'NOR', None, 'Norway', 1790, 'thesportsdb', now_iso),
        ('player_rublev', 'sport_tennis', 'Andrey Rublev', 'RUB', 'RUS', None, 'Monaco', 1780, 'thesportsdb', now_iso),
        ('player_fritz', 'sport_tennis', 'Taylor Fritz', 'FRI', 'USA', None, 'USA', 1810, 'thesportsdb', now_iso),

        # Handball
        ('team_kiel', 'sport_handball', 'THW Kiel', 'THW', 'THW', None, 'Germany', 1650, 'openligadb', now_iso),
        ('team_magdeburg', 'sport_handball', 'SC Magdeburg', 'SCM', 'SCM', None, 'Germany', 1670, 'openligadb', now_iso),
        ('team_flensburg', 'sport_handball', 'SG Flensburg-Handewitt', 'SGF', 'SGF', None, 'Germany', 1630, 'openligadb', now_iso),
        ('team_fuchse', 'sport_handball', 'Füchse Berlin', 'FUE', 'FUE', None, 'Germany', 1640, 'openligadb', now_iso),
        ('team_leipzig', 'sport_handball', 'SC DHfK Leipzig', 'LEI', 'LEI', None, 'Germany', 1520, 'openligadb', now_iso),
        ('team_wetzlar', 'sport_handball', 'HSG Wetzlar', 'WET', 'WET', None, 'Germany', 1480, 'openligadb', now_iso),

        # Volleyball
        ('team_stuttgart_vb', 'sport_volleyball', 'Allianz MTV Stuttgart', 'MTV', 'MTV', None, 'Germany', 1600, 'openligadb', now_iso),
        ('team_schwerin', 'sport_volleyball', 'SSC Palmberg Schwerin', 'SSC', 'SSC', None, 'Germany', 1590, 'openligadb', now_iso),
        ('team_potsdam', 'sport_volleyball', 'SC Potsdam', 'POT', 'POT', None, 'Germany', 1540, 'openligadb', now_iso),
        ('team_dresden', 'sport_volleyball', 'Dresdner SC', 'DSC', 'DSC', None, 'Germany', 1560, 'openligadb', now_iso),
        ('team_vilsbiburg', 'sport_volleyball', 'Rote Raben Vilsbiburg', 'RRV', 'RRV', None, 'Germany', 1480, 'openligadb', now_iso),
        ('team_munster', 'sport_volleyball', 'USC Münster', 'USC', 'USC', None, 'Germany', 1470, 'openligadb', now_iso),
    ]
    cur.executemany('''
        INSERT OR REPLACE INTO teams (id, sport_id, name, short_name, tla, badge_url, country, elo_rating, source_provider, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', teams)

    # 4. MATCHES - RECENT & UPCOMING 2026 ACROSS ALL 5 SPORTS
    # Today is 2026-10-14.
    matches = [
        # --- BASKETBALL NBA ---
        # Today Upcoming
        ('match_nba_20261014_bos_cha', 'sport_basketball', 'comp_nba', None, 'team_celtics', 'team_hornets', '2026-10-14T23:30:00Z', 'upcoming', 'Regular Season', 'NBA Week 1', None, 0, 'thesportsdb', 'tsdb_nba_1', now_iso, now_iso),
        ('match_nba_20261015_den_phx', 'sport_basketball', 'comp_nba', None, 'team_nuggets', 'team_suns', '2026-10-15T02:00:00Z', 'upcoming', 'Regular Season', 'NBA Week 1', None, 0, 'thesportsdb', 'tsdb_nba_2', now_iso, now_iso),
        ('match_nba_20261015_dal_mil', 'sport_basketball', 'comp_nba', None, 'team_mavericks', 'team_bucks', '2026-10-15T00:30:00Z', 'upcoming', 'Regular Season', 'NBA Week 1', None, 0, 'thesportsdb', 'tsdb_nba_3', now_iso, now_iso),
        ('match_nba_20261016_lal_gsw', 'sport_basketball', 'comp_nba', None, 'team_lakers', 'team_warriors', '2026-10-16T02:30:00Z', 'upcoming', 'Regular Season', 'NBA Week 1', None, 0, 'thesportsdb', 'tsdb_nba_4', now_iso, now_iso),
        # Recent Finished (Today & Yesterday)
        ('match_nba_20261014_sac_por', 'sport_basketball', 'comp_nba', None, 'team_kings', 'team_blazers', '2026-10-14T02:00:00Z', 'finished', 'Preseason', 'Finals', '48', 0, 'thesportsdb', 'tsdb_nba_past1', now_iso, now_iso),
        ('match_nba_20261013_lal_nyk', 'sport_basketball', 'comp_nba', None, 'team_lakers', 'team_knicks', '2026-10-13T01:30:00Z', 'finished', 'Preseason', 'Game 4', '48', 0, 'thesportsdb', 'tsdb_nba_past2', now_iso, now_iso),

        # --- BASKETBALL EuroLeague ---
        ('match_euro_20261015_rma_pao', 'sport_basketball', 'comp_euroleague', None, 'team_real_basket', 'team_panathinaikos', '2026-10-15T18:45:00Z', 'upcoming', 'Regular Season', 'Round 3', None, 0, 'thesportsdb', 'tsdb_euro_1', now_iso, now_iso),
        ('match_euro_20261016_asm_oly', 'sport_basketball', 'comp_euroleague', None, 'team_monaco_basket', 'team_olympiacos', '2026-10-16T19:00:00Z', 'upcoming', 'Regular Season', 'Round 3', None, 0, 'thesportsdb', 'tsdb_euro_2', now_iso, now_iso),

        # --- TENNIS ATP ---
        # Today Upcoming / Tonight
        ('match_ten_20261014_alc_med', 'sport_tennis', 'comp_atp', None, 'player_alcaraz', 'player_medvedev', '2026-10-14T17:30:00Z', 'upcoming', 'Demi-Finale', 'Court Central', None, 0, 'thesportsdb', 'tsdb_ten_1', now_iso, now_iso),
        ('match_ten_20261015_sin_zve', 'sport_tennis', 'comp_atp', None, 'player_sinner', 'player_zverev', '2026-10-15T14:00:00Z', 'upcoming', 'Demi-Finale', 'Court Central', None, 0, 'thesportsdb', 'tsdb_ten_2', now_iso, now_iso),
        ('match_ten_20261016_djo_fri', 'sport_tennis', 'comp_atp', None, 'player_djokovic', 'player_fritz', '2026-10-16T16:00:00Z', 'upcoming', 'Quart de Finale', 'Court 1', None, 0, 'thesportsdb', 'tsdb_ten_3', now_iso, now_iso),
        # Recent Finished
        ('match_ten_20261013_alc_ruu', 'sport_tennis', 'comp_atp', None, 'player_alcaraz', 'player_ruud', '2026-10-13T14:30:00Z', 'finished', 'Quart de Finale', 'Court Central', 'Final', 0, 'thesportsdb', 'tsdb_ten_past1', now_iso, now_iso),
        ('match_ten_20261013_sin_rub', 'sport_tennis', 'comp_atp', None, 'player_sinner', 'player_rublev', '2026-10-13T16:30:00Z', 'finished', 'Quart de Finale', 'Court Central', 'Final', 0, 'thesportsdb', 'tsdb_ten_past2', now_iso, now_iso),

        # --- HANDBALL HBL ---
        # Upcoming
        ('match_hbl_20261015_kie_mag', 'sport_handball', 'comp_old_hbl', None, 'team_kiel', 'team_magdeburg', '2026-10-15T17:05:00Z', 'upcoming', 'Spieltag 7', 'Wunderino Arena', None, 0, 'openligadb', 'hbl_2026_1', now_iso, now_iso),
        ('match_hbl_20261016_fle_fue', 'sport_handball', 'comp_old_hbl', None, 'team_flensburg', 'team_fuchse', '2026-10-16T18:00:00Z', 'upcoming', 'Spieltag 7', 'Campushalle', None, 0, 'openligadb', 'hbl_2026_2', now_iso, now_iso),
        # Recent Finished
        ('match_hbl_20261013_lei_wet', 'sport_handball', 'comp_old_hbl', None, 'team_leipzig', 'team_wetzlar', '2026-10-13T17:05:00Z', 'finished', 'Spieltag 6', 'Quarterback Arena', '60', 0, 'openligadb', 'hbl_2026_past1', now_iso, now_iso),

        # --- VOLLEYBALL VBL ---
        # Upcoming
        ('match_vbl_20261015_stu_sch', 'sport_volleyball', 'comp_old_vblf1', None, 'team_stuttgart_vb', 'team_schwerin', '2026-10-15T17:30:00Z', 'upcoming', 'Hauptrunde', 'SCHARR arena', None, 0, 'openligadb', 'vbl_2026_1', now_iso, now_iso),
        ('match_vbl_20261016_pot_dre', 'sport_volleyball', 'comp_old_vblf1', None, 'team_potsdam', 'team_dresden', '2026-10-16T18:00:00Z', 'upcoming', 'Hauptrunde', 'MBS Arena', None, 0, 'openligadb', 'vbl_2026_2', now_iso, now_iso),
        # Recent Finished
        ('match_vbl_20261013_vil_mun', 'sport_volleyball', 'comp_old_vblf1', None, 'team_vilsbiburg', 'team_munster', '2026-10-13T18:00:00Z', 'finished', 'Hauptrunde', 'Ballsporthalle', 'Final', 0, 'openligadb', 'vbl_2026_past1', now_iso, now_iso),
    ]

    cur.executemany('''
        INSERT OR REPLACE INTO matches (
            id, sport_id, competition_id, season_id, home_team_id, away_team_id,
            utc_kickoff, status, matchday, round_label, current_minute,
            is_sample_data, source_provider, source_match_id, last_synced_at, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', matches)

    # 5. RESULTS FOR FINISHED MATCHES
    results = [
        # NBA
        ('res_sac_por', 'match_nba_20261014_sac_por', 98, 110, 48, 55, None, None, None, None, 'team_blazers', now_iso),
        ('res_lal_nyk', 'match_nba_20261013_lal_nyk', 108, 104, 52, 50, None, None, None, None, 'team_lakers', now_iso),
        # Tennis (Sets won)
        ('res_alc_ruu', 'match_ten_20261013_alc_ruu', 2, 0, 1, 0, None, None, None, None, 'player_alcaraz', now_iso),
        ('res_sin_rub', 'match_ten_20261013_sin_rub', 2, 1, 1, 1, None, None, None, None, 'player_sinner', now_iso),
        # Handball
        ('res_lei_wet', 'match_hbl_20261013_lei_wet', 28, 25, 14, 12, None, None, None, None, 'team_leipzig', now_iso),
        # Volleyball (Sets)
        ('res_vil_mun', 'match_vbl_20261013_vil_mun', 3, 1, 1, 0, None, None, None, None, 'team_vilsbiburg', now_iso),
    ]
    cur.executemany('''
        INSERT OR REPLACE INTO results (
            id, match_id, home_score, away_score,
            home_halftime_score, away_halftime_score,
            home_extratime_score, away_extratime_score,
            home_penalties_score, away_penalties_score,
            winner_team_id, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', results)

    # 6. STATISTICS FOR RECENT FINISHED MATCHES
    stats = [
        ('stat_nba_1', 'match_nba_20261014_sac_por', 'FieldGoalPercent', 44.5, 48.2, '%', now_iso),
        ('stat_nba_2', 'match_nba_20261014_sac_por', 'Rebounds', 42.0, 49.0, 'total', now_iso),
        ('stat_nba_3', 'match_nba_20261014_sac_por', 'Assists', 23.0, 27.0, 'total', now_iso),
        ('stat_nba_4', 'match_nba_20261014_sac_por', 'ThreePointPercent', 32.1, 37.8, '%', now_iso),

        ('stat_ten_1', 'match_ten_20261013_alc_ruu', 'Aces', 7.0, 4.0, 'total', now_iso),
        ('stat_ten_2', 'match_ten_20261013_alc_ruu', 'FirstServePercent', 68.0, 62.0, '%', now_iso),
        ('stat_ten_3', 'match_ten_20261013_alc_ruu', 'BreakPointsConverted', 4.0, 1.0, 'total', now_iso),

        ('stat_hbl_1', 'match_hbl_20261013_lei_wet', 'GoalkeeperSaves', 14.0, 11.0, 'saves', now_iso),
        ('stat_hbl_2', 'match_hbl_20261013_lei_wet', 'ShotEfficiency', 65.0, 58.0, '%', now_iso),

        ('stat_vbl_1', 'match_vbl_20261013_vil_mun', 'AttackPoints', 54.0, 48.0, 'points', now_iso),
        ('stat_vbl_2', 'match_vbl_20261013_vil_mun', 'BlockPoints', 12.0, 8.0, 'points', now_iso),
    ]
    cur.executemany('''
        INSERT OR REPLACE INTO match_statistics (
            id, match_id, metric_name, home_value, away_value, raw_unit, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', stats)

    conn.commit()
    conn.close()
    print("Database seeding completed successfully.")

if __name__ == '__main__':
    seed()
