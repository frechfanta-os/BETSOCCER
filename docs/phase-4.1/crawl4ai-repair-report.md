# BETSOCCER — Phase 4.1 : Crawl4AI Scraping Diagnostic, Repair & Data Recovery Report

**Repository**: `https://github.com/frechfanta-os/BETSOCCER`  
**Phase**: 4.1 (Crawl4AI Scraping Diagnostic & Data Recovery)  
**Date**: October 2026  
**Status**: **PASS (All Tests Green, Zero Regressions, Zero Odds Policy Preserved)**  

---

## 1. Executive Summary

Phase 4.1 focuses on auditing and strengthening the Crawl4AI sports data collection infrastructure of BETSOCCER. While Phase 4 successfully expanded coverage with Football-Data.co.uk and OpenLigaDB, public web sources often expose match fixtures, scores, and calendars formatted as HTML tables or embedded Schema.org JSON-LD scripts rather than clean REST endpoints or static CSV files.

This engineering intervention delivers:
1. **Root-Cause Scraping Diagnostic**: Systematic analysis of crawling fragility, identifying HTML schema variations, missing team class attributes, unstandardized kickoff timestamps, and lack of resilient fallback extraction.
2. **Resilient HTML & JSON-LD Parser Module (`collector/sources/html_scraper.py`)**: Built on `BeautifulSoup4` and `AsyncWebCrawler`, supporting dual-tier parsing:
   - **Schema.org JSON-LD** (`@type: SportsEvent`): Extraction of structured names, kickoff dates, home/away teams, and sub-event scores.
   - **HTML Table Engine**: Class-aware (`match-row`, `home-team`, `match-score`) and positional column fallback parser.
3. **Data Normalization & Validation Pipeline**: Strict conversion of kickoff dates to UTC ISO-8601, score extraction, and validation via `DataValidator.validate_match` to ensure zero negative scores, identical-team anomalies, or malformed records enter SQLite.
4. **Relational Integrity & Deduplication**: Canonical team resolution to eliminate foreign-key violations and composite key deduplication (`competition_id + home_team_id + away_team_id + utc_kickoff`) ensuring idempotent upserts.
5. **Observability & Network Resilience**: Configurable retry policies with exponential backoff and rate limiting in `BaseSource`.

---

## 2. Root-Cause Diagnostic

Prior to this phase, automated crawling encountered distinct failure modes when attempting to parse arbitrary public sports pages:

| Diagnostic Area | Previous Vulnerability | Phase 4.1 Resolution |
| :--- | :--- | :--- |
| **Document Structure** | Fragile selectors assumed fixed DOM trees; minor site redesigns threw unhandled parsing errors. | Resilient parser inspects semantic CSS class names first, falling back to positional table structures and Schema.org JSON-LD scripts. |
| **Empty / Malformed HTML** | Empty responses or corrupted HTML could raise unhandled exceptions during tag navigation. | Input sanitization checks for empty/whitespace payloads; invalid rows are skipped gracefully while preserving valid rows. |
| **Date & Time Discrepancies** | Local dates, relative formats, and inconsistent timezone offsets prevented reliable SQLite sorting. | Standardized `parse_kickoff` normalizer supporting ISO-8601 with offsets (`Z` or `+HH:MM`), `YYYY-MM-DD`, `DD/MM/YYYY`, and `DD.MM.YYYY`. |
| **Score Inconsistencies** | Non-standard score separators (`-`, `:`, `vs`, `TBD`, extra spaces) caused conversion failures. | Regex-based `parse_score` extracts integers cleanly; negative scores and malformed entries are rejected by `DataValidator`. |
| **Transient Network Errors** | Single HTTP timeouts failed entire ingestion batches. | Automatic retries with exponential backoff and rate-limiting delays in `BaseSource.fetch_with_crawl4ai`. |

---

## 3. Architecture & Implementation

### 3.1 Dual-Tier Scraper (`HtmlSportsParser`)

The new `collector/sources/html_scraper.py` provides modular extraction:

1. **`extract_from_json_ld(soup, ...)`**:
   - Locates `<script type="application/ld+json">`.
   - Traverses single objects or arrays where `@type == "SportsEvent"`.
   - Extracts `startDate`, `homeTeam`, `awayTeam`, and `subEvent` scores.
2. **`extract_from_tables(soup, ...)`**:
   - Identifies candidate match rows through regex-matched classes (`match-row`, `fixture-row`) or `<tbody>` children.
   - Queries semantic cells (`match-date`, `match-time`, `home-team`, `away-team`, `match-score`, `match-status`).
   - Falls back to standard positional columns (Date | Time | Home | Score | Away | Status) when classes are absent.
3. **`parse_html(html_content, ...)`**:
   - Integrates both extraction tiers and feeds all candidate matches into `DataValidator.validate_match(m)`.
   - Ensures only structurally valid, clean matches proceed to SQLite ingestion.

### 3.2 Autonomous Source Integration (`HtmlScraperSource`)

Subclasses `BaseSource` and integrates with `AsyncWebCrawler`:
- Supports batch URL ingestion.
- Automatically creates default sport, competition, and season records to preserve relational foreign keys.
- Records structured `SyncReport` with execution duration, record counts, and granular error details.

---

## 4. Test Verification Suite (10 Targeted Scenarios)

A dedicated test suite in `collector/tests/test_phase4_1.py` validates all 10 mandated scenarios:

| # | Scenario | Tested Component | Verification Result |
| :--- | :--- | :--- | :--- |
| **1** | HTML table extraction from valid fixture | `HtmlSportsParser.extract_from_tables` | **PASS** — Correctly parsed 3 matches from `sample_matches.html` (Manchester City vs Liverpool, Real Madrid vs Barcelona, Bayern vs Dortmund). |
| **2** | JSON-LD SportsEvent extraction from valid fixture | `HtmlSportsParser.extract_from_json_ld` | **PASS** — Extracted Arsenal vs Chelsea (3-1, finished, 2026-10-18T16:30:00Z). |
| **3** | Empty HTML content handling | `HtmlSportsParser.parse_html` | **PASS** — Safely returns empty list on empty or whitespace strings without throwing. |
| **4** | Corrupted HTML structure resilience | `HtmlSportsParser.parse_html` | **PASS** — Skips malformed rows and safely extracts valid rows (Inter Milan vs Juventus). |
| **5** | Network retry & timeout simulation | `HtmlScraperSource.collect` | **PASS** — Retries transient errors up to `max_retries` and records clean `ERROR` status report. |
| **6** | Kickoff date normalization | `HtmlSportsParser.parse_kickoff` | **PASS** — Normalizes ISO offsets, European slash format, dot notation, and defaults missing times. |
| **7** | Score parsing & negative score rejection | `HtmlSportsParser.parse_score` & `DataValidator` | **PASS** — Validates various score formats (`2 - 0`, `1:1`, `-`); negative scores rejected. |
| **8** | Team canonical resolution & FK integrity | `DatabaseManager.save_matches_batch` | **PASS** — Mapped `team_liverpool` to canonical `team_liverpool_fc`; 0 FK violations in SQLite. |
| **9** | Composite key deduplication & idempotence | `DatabaseManager.save_matches_batch` | **PASS** — Repeated ingestion of match updates status to `finished` without duplicate row creation. |
| **10** | MelBet connector audit & refusal behavior | `MelbetSource.collect` & `audit_status` | **PASS** — Refuses network access, emits `DISABLED` report, preserves zero-odds policy. |

---

## 5. Verification Results

- **Python Unit Tests**: **35 / 35 tests passed** (`Ran 35 tests in 4.011s - OK`).
- **Flutter Test Suite**: **39 / 39 tests passed** (`All tests passed!`).
- **Flutter Code Analysis**: **No issues found** (`flutter analyze` clean).
- **SQLite Database Integrity**:
  - `PRAGMA integrity_check` -> `[('ok',)]`
  - `PRAGMA foreign_key_check` -> `[]` (zero violations).

---

## 6. Recommendations & Next Steps

1. **Scraping Rule**: All future public scraping sources must route through `HtmlSportsParser` to guarantee Schema.org and table normalization.
2. **Transition to Phase 5**: Data ingestion and scraping diagnostics are completely stabilized. BETSOCCER is ready for Phase 5 upon user authorization.
