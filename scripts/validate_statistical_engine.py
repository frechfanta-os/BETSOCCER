#!/usr/bin/env python3
"""
Validation scientifique et backtesting chronologique du Moteur Statistique de BETSOCCER.
Phase 2.1 — Audit et Correction du Moteur Statistique.

Prouve formellement l'absence de fuite temporelle (zéro data leakage, ni future ni contemporaine).
Calcule et compare :
- Mode 'strict' (corrigé) : historique STRICTEMENT antérieur (< target.kickoff), N = 28.
- Mode 'slice' (Phase 2 précédent) : historique découpé sans contrôle d'horaire simultané, N = 30.
- Accuracy avec Intervalle de Wilson à 95%
- Multiclass Brier Score [0, 2] standardisé non divisé par 3 (Référence uniforme = 2/3 = 0.6667)
- Écart-type et Intervalle de confiance à 95% pour le Brier Score
- Multiclass Log-Loss (cross-entropy, Référence uniforme = ln(3) = 1.0986)
- Expected Calibration Error (ECE) sur 5 intervalles
- Brier Skill Score (BSS) vs référence naïve uniforme
"""

import sqlite3
import math
import json
import os
from datetime import datetime

def wilson_score_interval(successes, total, z=1.95996):
    """Calcule l'intervalle de confiance bilatéral de Wilson à 95% pour une proportion."""
    if total == 0:
        return (0.0, 0.0)
    p = successes / total
    z2 = z * z
    denom = 1.0 + (z2 / total)
    center = (p + (z2 / (2.0 * total))) / denom
    margin = (z * math.sqrt((p * (1.0 - p) / total) + (z2 / (4.0 * total * total)))) / denom
    return (max(0.0, center - margin), min(1.0, center + margin))

def run_scientific_validation(db_path='betsoccer.db'):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute("""
        SELECT m.id, m.sport_id, m.competition_id, m.home_team_id, m.away_team_id,
               ht.name as home_name, at.name as away_name,
               m.utc_kickoff, r.home_score, r.away_score
        FROM matches m
        JOIN results r ON r.match_id = m.id
        JOIN teams ht ON ht.id = m.home_team_id
        JOIN teams at ON at.id = m.away_team_id
        WHERE m.status = 'finished' AND r.home_score IS NOT NULL AND r.away_score IS NOT NULL
        ORDER BY m.utc_kickoff ASC, m.id ASC
    """)
    finished_matches = c.fetchall()
    conn.close()

    total_finished = len(finished_matches)
    football_matches = [m for m in finished_matches if 'football' in m[1].lower() or 'soccer' in m[1].lower()]

    print(f"Total finished matches extracted: {total_finished}")
    print(f"Total football finished matches: {len(football_matches)}")

    # Paramètres mathématiques du modèle
    min_history = 3
    rho = -0.06 # Dixon & Coles (1997) corrélation des scores faibles
    shrinkage_c = 5.0 # Régularisation bayésienne pseudo-counts (5 matchs de ligue)
    home_adv_rating = 65.0 # Avantage domicile Elo standard
    eps = 1e-6 # Stabilité numérique Log-Loss

    # Précalcul des factorielles logarithmiques pour Poisson
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

    def evaluate_pipeline(mode='strict'):
        eval_count = 0
        p_brier_tot = 0.0
        p_logloss_tot = 0.0
        p_correct = 0
        p_briers = []

        e_brier_tot = 0.0
        e_logloss_tot = 0.0
        elo_correct = 0
        e_briers = []

        u_brier_tot = 0.0
        u_logloss_tot = 0.0

        calib_bins_p = [{"sum_p": 0.0, "sum_y": 0.0, "count": 0} for _ in range(5)]
        detailed_evaluations = []

        for i in range(len(football_matches)):
            target = football_matches[i]
            if mode == 'slice':
                if i < min_history:
                    continue
                history = football_matches[:i]
            else: # mode == 'strict'
                # Coupure temporelle causale stricte : kickoff strictement antérieur et exclusion du match cible
                history = [h for h in football_matches if h[0] != target[0] and h[7] < target[7]]
                if len(history) < min_history:
                    continue

            t_id, t_sport, t_comp, t_home, t_away, t_hname, t_aname, t_kickoff, t_hs, t_as = target

            # Vérité terrain
            y1 = 1.0 if t_hs > t_as else 0.0
            yX = 1.0 if t_hs == t_as else 0.0
            y2 = 1.0 if t_hs < t_as else 0.0

            # --- A. POISSON DIXON-COLES (avec Shrinkage) ---
            total_home_goals = sum(h[8] for h in history)
            total_away_goals = sum(h[9] for h in history)
            comp_home_avg = max(0.5, total_home_goals / len(history))
            comp_away_avg = max(0.5, total_away_goals / len(history))

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

            # --- C. UNIFORM BASELINE ---
            u1, uX, u2 = 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0

            eval_count += 1

            # Brier Score & Log-Loss
            bs_p = (p1_p - y1)**2 + (pX_p - yX)**2 + (p2_p - y2)**2
            ll_p = -(y1 * math.log(max(eps, p1_p)) + yX * math.log(max(eps, pX_p)) + y2 * math.log(max(eps, p2_p)))
            p_brier_tot += bs_p
            p_logloss_tot += ll_p
            p_briers.append(bs_p)
            if (p1_p >= pX_p and p1_p >= p2_p and y1 == 1.0) or \
               (pX_p >= p1_p and pX_p >= p2_p and yX == 1.0) or \
               (p2_p >= p1_p and p2_p >= pX_p and y2 == 1.0):
                p_correct += 1

            bs_e = (p1_e - y1)**2 + (pX_e - yX)**2 + (p2_e - y2)**2
            ll_e = -(y1 * math.log(max(eps, p1_e)) + yX * math.log(max(eps, pX_e)) + y2 * math.log(max(eps, p2_e)))
            e_brier_tot += bs_e
            e_logloss_tot += ll_e
            e_briers.append(bs_e)
            if (p1_e >= pX_e and p1_e >= p2_e and y1 == 1.0) or \
               (pX_e >= p1_e and pX_e >= p2_e and yX == 1.0) or \
               (p2_e >= p1_e and p2_e >= pX_e and y2 == 1.0):
                elo_correct += 1

            bs_u = (u1 - y1)**2 + (uX - yX)**2 + (u2 - y2)**2
            ll_u = math.log(3.0)
            u_brier_tot += bs_u
            u_logloss_tot += ll_u

            # Calibration bins Poisson
            for p_val, y_val in [(p1_p, y1), (pX_p, yX), (p2_p, y2)]:
                b_idx = min(4, max(0, int(p_val * 5)))
                calib_bins_p[b_idx]["count"] += 1
                calib_bins_p[b_idx]["sum_p"] += p_val
                calib_bins_p[b_idx]["sum_y"] += y_val

            outcome_str = "1" if y1 == 1.0 else ("X" if yX == 1.0 else "2")
            detailed_evaluations.append({
                "match_id": t_id,
                "kickoff": t_kickoff,
                "home": t_hname,
                "away": t_aname,
                "actual_score": f"{t_hs}-{t_as}",
                "outcome": outcome_str,
                "prior_matches_count": len(history),
                "poisson_probs": [round(p1_p, 4), round(pX_p, 4), round(p2_p, 4)],
                "elo_probs": [round(p1_e, 4), round(pX_e, 4), round(p2_e, 4)],
                "poisson_brier": round(bs_p, 4),
                "elo_brier": round(bs_e, 4),
                "poisson_hit": (p1_p >= pX_p and p1_p >= p2_p and y1 == 1.0) or (pX_p >= p1_p and pX_p >= p2_p and yX == 1.0) or (p2_p >= p1_p and p2_p >= pX_p and y2 == 1.0),
                "elo_hit": (p1_e >= pX_e and p1_e >= p2_e and y1 == 1.0) or (pX_e >= p1_e and pX_e >= p2_e and yX == 1.0) or (p2_e >= p1_e and p2_e >= pX_e and y2 == 1.0),
            })

        mean_p_brier = p_brier_tot / eval_count
        mean_p_logloss = p_logloss_tot / eval_count
        p_acc = p_correct / eval_count
        p_wilson = wilson_score_interval(p_correct, eval_count)

        mean_e_brier = e_brier_tot / eval_count
        mean_e_logloss = e_logloss_tot / eval_count
        e_acc = elo_correct / eval_count
        e_wilson = wilson_score_interval(elo_correct, eval_count)

        mean_u_brier = u_brier_tot / eval_count
        mean_u_logloss = u_logloss_tot / eval_count

        bss_p = 1.0 - (mean_p_brier / mean_u_brier)
        bss_e = 1.0 - (mean_e_brier / mean_u_brier)

        # Variance et erreur type pour le Brier Score
        p_brier_var = sum((x - mean_p_brier)**2 for x in p_briers) / (eval_count - 1) if eval_count > 1 else 0.0
        p_brier_se = math.sqrt(p_brier_var) / math.sqrt(eval_count)
        p_brier_ci = (max(0.0, mean_p_brier - 1.95996 * p_brier_se), min(2.0, mean_p_brier + 1.95996 * p_brier_se))

        e_brier_var = sum((x - mean_e_brier)**2 for x in e_briers) / (eval_count - 1) if eval_count > 1 else 0.0
        e_brier_se = math.sqrt(e_brier_var) / math.sqrt(eval_count)
        e_brier_ci = (max(0.0, mean_e_brier - 1.95996 * e_brier_se), min(2.0, mean_e_brier + 1.95996 * e_brier_se))

        # ECE
        total_calib_samples = sum(b["count"] for b in calib_bins_p)
        ece = 0.0
        for b in calib_bins_p:
            if b["count"] > 0:
                mean_pred = b["sum_p"] / b["count"]
                emp_acc = b["sum_y"] / b["count"]
                ece += (b["count"] / total_calib_samples) * abs(mean_pred - emp_acc)

        return {
            "mode": mode,
            "evaluated_count": eval_count,
            "poisson": {
                "correct": p_correct,
                "accuracy": round(p_acc, 4),
                "wilson_ci_95": [round(p_wilson[0], 4), round(p_wilson[1], 4)],
                "brier_score": round(mean_p_brier, 4),
                "brier_se": round(p_brier_se, 4),
                "brier_ci_95": [round(p_brier_ci[0], 4), round(p_brier_ci[1], 4)],
                "log_loss": round(mean_p_logloss, 4),
                "brier_skill_score": round(bss_p, 4),
                "ece": round(ece, 4),
            },
            "elo": {
                "correct": elo_correct,
                "accuracy": round(e_acc, 4),
                "wilson_ci_95": [round(e_wilson[0], 4), round(e_wilson[1], 4)],
                "brier_score": round(mean_e_brier, 4),
                "brier_se": round(e_brier_se, 4),
                "brier_ci_95": [round(e_brier_ci[0], 4), round(e_brier_ci[1], 4)],
                "log_loss": round(mean_e_logloss, 4),
                "brier_skill_score": round(bss_e, 4),
            },
            "uniform_baseline": {
                "accuracy": round(1.0 / 3.0, 4),
                "brier_score": round(mean_u_brier, 4),
                "log_loss": round(mean_u_logloss, 4),
            },
            "calibration_bins": [
                {
                    "bin": f"[{i*0.2:.1f} - {(i+1)*0.2:.1f}]",
                    "count": b["count"],
                    "mean_pred": round(b["sum_p"] / b["count"], 4) if b["count"] > 0 else 0.0,
                    "emp_acc": round(b["sum_y"] / b["count"], 4) if b["count"] > 0 else 0.0,
                }
                for i, b in enumerate(calib_bins_p)
            ],
            "evaluations": detailed_evaluations
        }

    res_strict = evaluate_pipeline(mode='strict')
    res_slice = evaluate_pipeline(mode='slice')

    print("\n" + "="*70)
    print("           RÉSULTATS DU BACKTESTING SCIENTIFIQUE (PHASE 2.1)")
    print("="*70)
    print(f"\n1. MODE STRICT (Sans aucune fuite temporelle, N = {res_strict['evaluated_count']}) :")
    print(f"   Poisson Dixon-Coles :")
    print(f"     - Précision (Hit rate) : {res_strict['poisson']['accuracy']*100:.2f}% ({res_strict['poisson']['correct']}/{res_strict['evaluated_count']}) | IC 95% Wilson: [{res_strict['poisson']['wilson_ci_95'][0]*100:.1f}%, {res_strict['poisson']['wilson_ci_95'][1]*100:.1f}%]")
    print(f"     - Brier Score multiclasses : {res_strict['poisson']['brier_score']:.4f} +/- {1.95996*res_strict['poisson']['brier_se']:.4f} (IC 95%: [{res_strict['poisson']['brier_ci_95'][0]:.4f}, {res_strict['poisson']['brier_ci_95'][1]:.4f}])")
    print(f"     - Log-Loss (cross-entropy) : {res_strict['poisson']['log_loss']:.4f}")
    print(f"     - Brier Skill Score (BSS)  : +{res_strict['poisson']['brier_skill_score']*100:.2f}% vs Uniforme (0.6667)")
    print(f"     - Calibration ECE          : {res_strict['poisson']['ece']:.4f}")
    print(f"   Multi-Sport Dynamic Elo :")
    print(f"     - Précision (Hit rate) : {res_strict['elo']['accuracy']*100:.2f}% ({res_strict['elo']['correct']}/{res_strict['evaluated_count']}) | IC 95% Wilson: [{res_strict['elo']['wilson_ci_95'][0]*100:.1f}%, {res_strict['elo']['wilson_ci_95'][1]*100:.1f}%]")
    print(f"     - Brier Score multiclasses : {res_strict['elo']['brier_score']:.4f} +/- {1.95996*res_strict['elo']['brier_se']:.4f} (IC 95%: [{res_strict['elo']['brier_ci_95'][0]:.4f}, {res_strict['elo']['brier_ci_95'][1]:.4f}])")
    print(f"     - Log-Loss (cross-entropy) : {res_strict['elo']['log_loss']:.4f}")
    print(f"     - Brier Skill Score (BSS)  : +{res_strict['elo']['brier_skill_score']*100:.2f}% vs Uniforme (0.6667)")
    print(f"   Référence Uniforme Naïve :")
    print(f"     - Précision : 33.33% | Brier Score: {res_strict['uniform_baseline']['brier_score']:.4f} | Log-Loss: {res_strict['uniform_baseline']['log_loss']:.4f}")

    print(f"\n2. COMPARAISON AVEC ANCIEN MODE SLICE (Avec fuite simultanée, N = {res_slice['evaluated_count']}) :")
    print(f"   - Poisson Hit rate : {res_slice['poisson']['accuracy']*100:.2f}% ({res_slice['poisson']['correct']}/{res_slice['evaluated_count']}) -> Strict: {res_strict['poisson']['accuracy']*100:.2f}% ({res_strict['poisson']['correct']}/{res_strict['evaluated_count']})")
    print(f"   - Poisson Brier    : {res_slice['poisson']['brier_score']:.4f} -> Strict: {res_strict['poisson']['brier_score']:.4f}")
    print(f"   - Poisson LogLoss  : {res_slice['poisson']['log_loss']:.4f} -> Strict: {res_strict['poisson']['log_loss']:.4f}")
    print(f"   - Elo Brier        : {res_slice['elo']['brier_score']:.4f} -> Strict: {res_strict['elo']['brier_score']:.4f}")

    return {
        "strict": res_strict,
        "slice": res_slice,
    }

if __name__ == '__main__':
    run_scientific_validation()
