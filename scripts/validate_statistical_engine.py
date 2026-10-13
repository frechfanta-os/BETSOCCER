#!/usr/bin/env python3
"""
Validation scientifique et backtesting chronologique du Moteur Statistique de BETSOCCER.
Prouve formellement l'absence de fuite temporelle (walk-forward validation) et calcule :
- Brier Score
- Log-Loss (cross-entropy)
- Expected Calibration Error (ECE)
- Brier Skill Score (BSS) vs Référence uniforme
"""

import sqlite3
import math
import json
from datetime import datetime

def run_scientific_validation(db_path='betsoccer.db'):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    # 1. Extraction des matchs terminés avec scores
    c.execute("""
        SELECT m.id, m.sport_id, m.competition_id, m.home_team_id, m.away_team_id,
               ht.name as home_name, at.name as away_name,
               m.utc_kickoff, r.home_score, r.away_score
        FROM matches m
        JOIN results r ON r.match_id = m.id
        JOIN teams ht ON ht.id = m.home_team_id
        JOIN teams at ON at.id = m.away_team_id
        WHERE m.status = 'finished' AND r.home_score IS NOT NULL AND r.away_score IS NOT NULL
        ORDER BY m.utc_kickoff ASC
    """)
    finished_matches = c.fetchall()
    conn.close()

    total_finished = len(finished_matches)
    print(f"Total finished matches extracted: {total_finished}")

    # Filtrer par football
    football_matches = [m for m in finished_matches if 'football' in m[1].lower() or 'soccer' in m[1].lower()]
    print(f"Total football finished matches: {len(football_matches)}")

    # 2. Walk-forward backtest (Strictement sans regard vers le futur)
    # Paramètres
    min_history = 3
    rho = -0.06
    shrinkage_c = 5.0
    home_adv_rating = 65.0
    eps = 1e-6

    # Log factorials
    log_facts = [0.0] * 16
    for i in range(1, 16):
        log_facts[i] = log_facts[i-1] + math.log(i)

    def poisson_pmf(k, lam):
        if lam <= 0: return 1.0 if k == 0 else 0.0
        if k > 15: return 0.0
        return math.exp(k * math.log(lam) - lam - log_facts[k])

    def dixon_coles_tau(x, y, lam, mu):
        if x == 0 and y == 0: return 1.0 - (lam * mu * rho)
        if x == 0 and y == 1: return 1.0 + (lam * rho)
        if x == 1 and y == 0: return 1.0 + (mu * rho)
        if x == 1 and y == 1: return 1.0 - rho
        return 1.0

    # Accumulateurs pour métriques
    eval_count = 0
    poisson_brier = 0.0
    poisson_logloss = 0.0
    poisson_correct = 0

    elo_brier = 0.0
    elo_logloss = 0.0
    elo_correct = 0

    uniform_brier = 0.0
    uniform_logloss = 0.0

    # Calibration bins (5 bins)
    calib_bins = [{"sum_p": 0.0, "sum_y": 0.0, "count": 0} for _ in range(5)]

    detailed_evaluations = []

    for i in range(min_history, len(football_matches)):
        target = football_matches[i]
        history = football_matches[:i] # STRICTEMENT antérieures

        t_id, t_sport, t_comp, t_home, t_away, t_hname, t_aname, t_kickoff, t_hs, t_as = target

        # Vérité terrain
        y1 = 1.0 if t_hs > t_as else 0.0
        yX = 1.0 if t_hs == t_as else 0.0
        y2 = 1.0 if t_hs < t_as else 0.0

        # --- A. POISSON DIXON-COLES (avec shrinkage) ---
        total_home_goals = sum(h[8] for h in history)
        total_away_goals = sum(h[9] for h in history)
        comp_home_avg = max(0.5, total_home_goals / len(history))
        comp_away_avg = max(0.5, total_away_goals / len(history))
        home_adv = max(1.0, min(2.0, comp_home_avg / comp_away_avg))

        # Stats des équipes avant ce match
        h_scored = sum(h[8] if h[3] == t_home else h[9] for h in history if h[3] == t_home or h[4] == t_home)
        h_conceded = sum(h[9] if h[3] == t_home else h[8] for h in history if h[3] == t_home or h[4] == t_home)
        h_cnt = sum(1 for h in history if h[3] == t_home or h[4] == t_home)

        a_scored = sum(h[8] if h[3] == t_away else h[9] for h in history if h[3] == t_away or h[4] == t_away)
        a_conceded = sum(h[9] if h[3] == t_away else h[8] for h in history if h[3] == t_away or h[4] == t_away)
        a_cnt = sum(1 for h in history if h[3] == t_away or h[4] == t_away)

        w_h = h_cnt / (h_cnt + shrinkage_c)
        w_a = a_cnt / (a_cnt + shrinkage_c)

        raw_h_att = (h_scored / h_cnt) / comp_home_avg if h_cnt > 0 else 1.0
        raw_h_def = (h_conceded / h_cnt) / comp_away_avg if h_cnt > 0 else 1.0
        raw_a_att = (a_scored / a_cnt) / comp_away_avg if a_cnt > 0 else 1.0
        raw_a_def = (a_conceded / a_cnt) / comp_home_avg if a_cnt > 0 else 1.0

        h_att = (w_h * raw_h_att) + (1.0 - w_h)
        h_def = (w_h * raw_h_def) + (1.0 - w_h)
        a_att = (w_a * raw_a_att) + (1.0 - w_a)
        a_def = (w_a * raw_a_def) + (1.0 - w_a)

        lam = max(0.2, min(5.0, h_att * a_def * comp_home_avg * 1.05))
        mu = max(0.2, min(5.0, a_att * h_def * comp_away_avg))

        p1_p, pX_p, p2_p = 0.0, 0.0, 0.0
        tot_p = 0.0
        for x in range(11):
            for y in range(11):
                tau = max(0.0, dixon_coles_tau(x, y, lam, mu))
                p = tau * poisson_pmf(x, lam) * poisson_pmf(y, mu)
                tot_p += p
                if x > y: p1_p += p
                elif x == y: pX_p += p
                else: p2_p += p

        p1_p /= tot_p
        pX_p /= tot_p
        p2_p /= tot_p

        # --- B. ELO ENGINE ---
        # Calcul des cotes Elo jusqu'à ce match
        ratings = {}
        for h in history:
            rh = ratings.get(h[3], 1500.0)
            ra = ratings.get(h[4], 1500.0)
            diff = (ra - (rh + home_adv_rating)) / 400.0
            eh = 1.0 / (1.0 + math.pow(10.0, diff))
            sh = 1.0 if h[8] > h[9] else (0.5 if h[8] == h[9] else 0.0)
            ratings[h[3]] = rh + 32.0 * (sh - eh)
            ratings[h[4]] = ra + 32.0 * ((1.0 - sh) - (1.0 - eh))

        rh_t = ratings.get(t_home, 1500.0)
        ra_t = ratings.get(t_away, 1500.0)
        diff_t = (ra_t - (rh_t + home_adv_rating)) / 400.0
        eh_t = 1.0 / (1.0 + math.pow(10.0, diff_t))
        ea_t = 1.0 - eh_t
        draw_f = max(0.12, min(0.35, 0.26 * (1.0 - abs(eh_t - ea_t) * 0.4)))
        rem = 1.0 - draw_f
        p1_e = rem * (eh_t / (eh_t + ea_t))
        pX_e = draw_f
        p2_e = rem * (ea_t / (eh_t + ea_t))

        # Uniform baseline
        u1, uX, u2 = 1.0/3.0, 1.0/3.0, 1.0/3.0

        # Évaluation métriques
        eval_count += 1

        # Poisson Brier & Logloss
        bs_p = (p1_p - y1)**2 + (pX_p - yX)**2 + (p2_p - y2)**2
        ll_p = -(y1 * math.log(max(eps, p1_p)) + yX * math.log(max(eps, pX_p)) + y2 * math.log(max(eps, p2_p)))
        poisson_brier += bs_p
        poisson_logloss += ll_p
        if (p1_p >= pX_p and p1_p >= p2_p and y1 == 1.0) or \
           (pX_p >= p1_p and pX_p >= p2_p and yX == 1.0) or \
           (p2_p >= p1_p and p2_p >= pX_p and y2 == 1.0):
            poisson_correct += 1

        # Elo Brier & Logloss
        bs_e = (p1_e - y1)**2 + (pX_e - yX)**2 + (p2_e - y2)**2
        ll_e = -(y1 * math.log(max(eps, p1_e)) + yX * math.log(max(eps, pX_e)) + y2 * math.log(max(eps, p2_e)))
        elo_brier += bs_e
        elo_logloss += ll_e
        if (p1_e >= pX_e and p1_e >= p2_e and y1 == 1.0) or \
           (pX_e >= p1_e and pX_e >= p2_e and yX == 1.0) or \
           (p2_e >= p1_e and p2_e >= pX_e and y2 == 1.0):
            elo_correct += 1

        # Uniform baseline
        bs_u = (u1 - y1)**2 + (uX - yX)**2 + (u2 - y2)**2
        ll_u = math.log(3.0)
        uniform_brier += bs_u
        uniform_logloss += ll_u

        # Calibration pour Poisson
        for p_val, y_val in [(p1_p, y1), (pX_p, yX), (p2_p, y2)]:
            b_idx = min(4, max(0, int(p_val * 5)))
            calib_bins[b_idx]["count"] += 1
            calib_bins[b_idx]["sum_p"] += p_val
            calib_bins[b_idx]["sum_y"] += y_val

        detailed_evaluations.append({
            "match_id": t_id,
            "home": t_hname,
            "away": t_aname,
            "actual_score": f"{t_hs}-{t_as}",
            "poisson_probs": [round(p1_p, 3), round(pX_p, 3), round(p2_p, 3)],
            "elo_probs": [round(p1_e, 3), round(pX_e, 3), round(p2_e, 3)],
            "poisson_brier": round(bs_p, 4),
        })

    # Synthèse des moyennes
    mean_p_brier = poisson_brier / eval_count
    mean_p_logloss = poisson_logloss / eval_count
    p_acc = poisson_correct / eval_count

    mean_e_brier = elo_brier / eval_count
    mean_e_logloss = elo_logloss / eval_count
    e_acc = elo_correct / eval_count

    mean_u_brier = uniform_brier / eval_count
    mean_u_logloss = uniform_logloss / eval_count

    # Brier Skill Score
    bss_p = 1.0 - (mean_p_brier / mean_u_brier)
    bss_e = 1.0 - (mean_e_brier / mean_u_brier)

    # ECE
    total_calib_samples = sum(b["count"] for b in calib_bins)
    ece = 0.0
    for b in calib_bins:
        if b["count"] > 0:
            mean_pred = b["sum_p"] / b["count"]
            emp_acc = b["sum_y"] / b["count"]
            ece += (b["count"] / total_calib_samples) * abs(mean_pred - emp_acc)

    results = {
        "evaluated_matches_count": eval_count,
        "models": {
            "poisson_dixon_coles": {
                "accuracy": round(p_acc, 4),
                "brier_score": round(mean_p_brier, 4),
                "log_loss": round(mean_p_logloss, 4),
                "brier_skill_score": round(bss_p, 4),
                "ece": round(ece, 4)
            },
            "multi_sport_elo": {
                "accuracy": round(e_acc, 4),
                "brier_score": round(mean_e_brier, 4),
                "log_loss": round(mean_e_logloss, 4),
                "brier_skill_score": round(bss_e, 4)
            },
            "uniform_baseline": {
                "accuracy": round(1.0/3.0, 4),
                "brier_score": round(mean_u_brier, 4),
                "log_loss": round(mean_u_logloss, 4)
            }
        },
        "calibration_bins": [
            {
                "bin": f"[{i*0.2:.1f} - {(i+1)*0.2:.1f}]",
                "count": b["count"],
                "mean_pred": round(b["sum_p"] / b["count"], 4) if b["count"] > 0 else 0.0,
                "empirical_acc": round(b["sum_y"] / b["count"], 4) if b["count"] > 0 else 0.0
            }
            for i, b in enumerate(calib_bins)
        ],
        "sample_evaluations": detailed_evaluations[:5]
    }

    print("\n=== RÉSULTATS SCIENTIFIQUES BACKTESTING ===")
    print(json.dumps(results, indent=2))
    return results

if __name__ == '__main__':
    run_scientific_validation()
