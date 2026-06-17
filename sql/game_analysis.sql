-- ============================================================
-- Lichess Game Analysis — Metadata SQL Queries
-- Notebook: 01_sql_game_analysis.ipynb
--
-- Purpose:
-- Analyze the cleaned game-level dataset with SQL.
-- The main focus is how game category, termination type,
-- rating favorite, and rating gap relate to game outcomes.
-- ============================================================


-- ============================================================
-- Section 2: Termination Patterns by Game Category
--
-- Goal:
-- Compare how often each game category ends normally or by
-- time forfeit. This tests whether faster categories are more
-- affected by clock pressure.
-- ============================================================

WITH termination_by_category AS (
    SELECT
        g.Category,
        COUNT(*) AS total_games,
        SUM(CASE
                WHEN g.Termination = 'Normal' THEN 1
                ELSE 0
            END) AS normal_games,
        SUM(CASE
                WHEN g.Termination = 'Time forfeit' THEN 1
                ELSE 0
            END) AS time_forfeit_games
    FROM games AS g
    GROUP BY g.Category
)

SELECT
    tbc.Category,
    tbc.total_games,
    tbc.normal_games,
    tbc.time_forfeit_games,
    ROUND(tbc.time_forfeit_games * 100.0 / tbc.total_games, 2) AS time_forfeit_rate
FROM termination_by_category AS tbc
ORDER BY time_forfeit_rate DESC;


-- ============================================================
-- Section 3: Time-Forfeit Wins by Color
--
-- Goal:
-- Check whether decisive time-forfeit games favor White or Black.
-- This helps separate clock-pressure effects from color advantage.
-- ============================================================

WITH time_forfeit_wins AS (
    SELECT
        g.Category,
        COUNT(*) AS time_forfeit_wins,
        SUM(CASE
                WHEN g.winner = 'White' THEN 1
                ELSE 0
            END) AS white_time_forfeit_wins,
        SUM(CASE
                WHEN g.winner = 'Black' THEN 1
                ELSE 0
            END) AS black_time_forfeit_wins
    FROM games AS g
    WHERE g.Termination = 'Time forfeit'
      AND g.winner IN ('White', 'Black')
    GROUP BY g.Category
)

SELECT
    tfw.Category,
    tfw.time_forfeit_wins,
    tfw.white_time_forfeit_wins,
    tfw.black_time_forfeit_wins,
    ROUND(tfw.white_time_forfeit_wins * 100.0 / tfw.time_forfeit_wins, 2) AS white_win_percentage,
    ROUND(tfw.black_time_forfeit_wins * 100.0 / tfw.time_forfeit_wins, 2) AS black_win_percentage
FROM time_forfeit_wins AS tfw
ORDER BY tfw.time_forfeit_wins DESC;


-- ============================================================
-- Section 4: Rating Favorite Performance
--
-- Goal:
-- Measure how often clear rating favorites win overall.
-- Close-rating games and draws are excluded because this section
-- focuses only on decisive games with a clear favorite.
-- ============================================================

WITH favorite_outcomes AS (
    SELECT
        g.rating_favorite,
        CASE
            WHEN g.rating_favorite = 'White favorite' AND g.winner = 'White' THEN 'Favorite won'
            WHEN g.rating_favorite = 'Black favorite' AND g.winner = 'Black' THEN 'Favorite won'
            ELSE 'Upset'
        END AS outcome
    FROM games AS g
    WHERE g.rating_favorite IN ('White favorite', 'Black favorite')
      AND g.winner IN ('White', 'Black')
),

outcome_counts AS (
    SELECT
        fo.rating_favorite,
        fo.outcome,
        COUNT(*) AS games
    FROM favorite_outcomes AS fo
    GROUP BY
        fo.rating_favorite,
        fo.outcome
),

favorite_totals AS (
    SELECT
        oc.rating_favorite,
        SUM(oc.games) AS total_games
    FROM outcome_counts AS oc
    GROUP BY oc.rating_favorite
)

SELECT
    oc.rating_favorite,
    oc.outcome,
    oc.games,
    ROUND(oc.games * 100.0 / ft.total_games, 2) AS percentage_within_favorite
FROM outcome_counts AS oc
JOIN favorite_totals AS ft
    ON oc.rating_favorite = ft.rating_favorite
ORDER BY
    oc.rating_favorite,
    oc.outcome;


-- ============================================================
-- Section 5: Rating Favorite Performance by Game Category
--
-- Goal:
-- Check whether rating favorites win at similar rates across
-- Bullet, Blitz, Rapid, and Classical games.
-- ============================================================

WITH favorite_outcomes_by_category AS (
    SELECT
        g.Category,
        COUNT(*) AS total_decisive_favorite_games,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'White')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'Black')
                THEN 1
                ELSE 0
            END) AS favorite_wins,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'Black')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'White')
                THEN 1
                ELSE 0
            END) AS upsets
    FROM games AS g
    WHERE g.winner IN ('White', 'Black')
      AND g.rating_favorite IN ('White favorite', 'Black favorite')
    GROUP BY g.Category
)

SELECT
    fobc.Category,
    fobc.total_decisive_favorite_games,
    fobc.favorite_wins,
    fobc.upsets,
    ROUND(fobc.favorite_wins * 100.0 / fobc.total_decisive_favorite_games, 2) AS favorite_win_rate,
    ROUND(fobc.upsets * 100.0 / fobc.total_decisive_favorite_games, 2) AS upset_rate
FROM favorite_outcomes_by_category AS fobc
ORDER BY favorite_win_rate DESC;


-- ============================================================
-- Section 6: Favorite Win Rate by Rating Gap Size
--
-- Goal:
-- Test whether larger Elo gaps make rating favorites more reliable.
-- The smallest bucket starts at 51 because the rating_favorite
-- feature only labels a player as favorite when the gap is > 50.
-- ============================================================

WITH rating_gap_outcomes AS (
    SELECT
        CASE
            WHEN g.abs_rating_diff > 50 AND g.abs_rating_diff < 100 THEN '51-99'
            WHEN g.abs_rating_diff >= 100 AND g.abs_rating_diff < 200 THEN '100-199'
            WHEN g.abs_rating_diff >= 200 AND g.abs_rating_diff < 400 THEN '200-399'
            ELSE '400+'
        END AS rating_gap_bucket,
        COUNT(*) AS total_decisive_favorite_games,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'White')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'Black')
                THEN 1
                ELSE 0
            END) AS favorite_wins,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'Black')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'White')
                THEN 1
                ELSE 0
            END) AS upsets
    FROM games AS g
    WHERE g.winner IN ('White', 'Black')
      AND g.rating_favorite IN ('White favorite', 'Black favorite')
    GROUP BY rating_gap_bucket
)

SELECT
    rgo.rating_gap_bucket,
    rgo.total_decisive_favorite_games,
    rgo.favorite_wins,
    rgo.upsets,
    ROUND(rgo.favorite_wins * 100.0 / rgo.total_decisive_favorite_games, 2) AS favorite_win_rate,
    ROUND(rgo.upsets * 100.0 / rgo.total_decisive_favorite_games, 2) AS upset_rate
FROM rating_gap_outcomes AS rgo
ORDER BY favorite_win_rate DESC;


-- ============================================================
-- Section 7: Favorite Win Rate by Rating Gap and Game Category
--
-- Goal:
-- Compare favorite win rates across game categories while also
-- controlling for rating-gap size.
-- ============================================================

WITH category_rating_gap_outcomes AS (
    SELECT
        g.Category,
        CASE
            WHEN g.abs_rating_diff > 50 AND g.abs_rating_diff < 100 THEN '51-99'
            WHEN g.abs_rating_diff >= 100 AND g.abs_rating_diff < 200 THEN '100-199'
            WHEN g.abs_rating_diff >= 200 AND g.abs_rating_diff < 400 THEN '200-399'
            ELSE '400+'
        END AS rating_gap_bucket,
        COUNT(*) AS total_decisive_favorite_games,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'White')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'Black')
                THEN 1
                ELSE 0
            END) AS favorite_wins,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'Black')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'White')
                THEN 1
                ELSE 0
            END) AS upsets
    FROM games AS g
    WHERE g.winner IN ('White', 'Black')
      AND g.rating_favorite IN ('White favorite', 'Black favorite')
    GROUP BY
        rating_gap_bucket,
        g.Category
)

SELECT
    crgo.Category,
    crgo.rating_gap_bucket,
    crgo.total_decisive_favorite_games,
    crgo.favorite_wins,
    crgo.upsets,
    ROUND(crgo.favorite_wins * 100.0 / crgo.total_decisive_favorite_games, 2) AS favorite_win_rate,
    ROUND(crgo.upsets * 100.0 / crgo.total_decisive_favorite_games, 2) AS upset_rate
FROM category_rating_gap_outcomes AS crgo
ORDER BY
    CASE crgo.rating_gap_bucket
        WHEN '400+' THEN 4
        WHEN '200-399' THEN 3
        WHEN '100-199' THEN 2
        WHEN '51-99' THEN 1
    END DESC,
    crgo.Category;


-- ============================================================
-- Section 8: Does Time Forfeit Change Rating Favorite Reliability?
--
-- Goal:
-- Compare favorite win rates in Normal vs Time forfeit games
-- within the same rating-gap bucket.
-- ============================================================

WITH termination_rating_gap_outcomes AS (
    SELECT
        g.Termination,
        CASE
            WHEN g.abs_rating_diff > 50 AND g.abs_rating_diff < 100 THEN '51-99'
            WHEN g.abs_rating_diff >= 100 AND g.abs_rating_diff < 200 THEN '100-199'
            WHEN g.abs_rating_diff >= 200 AND g.abs_rating_diff < 400 THEN '200-399'
            ELSE '400+'
        END AS rating_gap_bucket,
        COUNT(*) AS total_decisive_favorite_games,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'White')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'Black')
                THEN 1
                ELSE 0
            END) AS favorite_wins,
        SUM(CASE
                WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'Black')
                  OR (g.rating_favorite = 'Black favorite' AND g.winner = 'White')
                THEN 1
                ELSE 0
            END) AS upsets
    FROM games AS g
    WHERE g.winner IN ('White', 'Black')
      AND g.rating_favorite IN ('White favorite', 'Black favorite')
      AND g.Termination IN ('Normal', 'Time forfeit')
    GROUP BY
        rating_gap_bucket,
        g.Termination
)

SELECT
    trgo.Termination,
    trgo.rating_gap_bucket,
    trgo.total_decisive_favorite_games,
    trgo.favorite_wins,
    trgo.upsets,
    ROUND(trgo.favorite_wins * 100.0 / trgo.total_decisive_favorite_games, 2) AS favorite_win_rate,
    ROUND(trgo.upsets * 100.0 / trgo.total_decisive_favorite_games, 2) AS upset_rate
FROM termination_rating_gap_outcomes AS trgo
ORDER BY
    CASE trgo.rating_gap_bucket
        WHEN '400+' THEN 4
        WHEN '200-399' THEN 3
        WHEN '100-199' THEN 2
        WHEN '51-99' THEN 1
    END DESC,
    CASE trgo.Termination
        WHEN 'Normal' THEN 1
        WHEN 'Time forfeit' THEN 2
    END;


-- ============================================================
-- Section 9: Comparing the Strength of Metadata Signals
--
-- Goal:
-- Summarize which metadata signal moves favorite win rate the most:
-- rating-gap size, category within rating-gap bucket, or termination
-- type within rating-gap bucket.
-- ============================================================

WITH base_favorite_games AS (
    SELECT
        g.Category,
        g.Termination,

        CASE
            WHEN g.abs_rating_diff > 50 AND g.abs_rating_diff < 100 THEN '51-99'
            WHEN g.abs_rating_diff >= 100 AND g.abs_rating_diff < 200 THEN '100-199'
            WHEN g.abs_rating_diff >= 200 AND g.abs_rating_diff < 400 THEN '200-399'
            ELSE '400+'
        END AS rating_gap_bucket,

        CASE
            WHEN (g.rating_favorite = 'White favorite' AND g.winner = 'White')
              OR (g.rating_favorite = 'Black favorite' AND g.winner = 'Black')
            THEN 1
            ELSE 0
        END AS favorite_won

    FROM games AS g
    WHERE g.winner IN ('White', 'Black')
      AND g.rating_favorite IN ('White favorite', 'Black favorite')
),

rating_gap_rates AS (
    SELECT
        bfg.rating_gap_bucket,
        COUNT(*) AS total_games,
        SUM(bfg.favorite_won) AS favorite_wins,
        SUM(bfg.favorite_won) * 100.0 / COUNT(*) AS favorite_win_rate
    FROM base_favorite_games AS bfg
    GROUP BY bfg.rating_gap_bucket
),

category_gap_rates AS (
    SELECT
        bfg.Category,
        bfg.rating_gap_bucket,
        COUNT(*) AS total_games,
        SUM(bfg.favorite_won) AS favorite_wins,
        SUM(bfg.favorite_won) * 100.0 / COUNT(*) AS favorite_win_rate
    FROM base_favorite_games AS bfg
    GROUP BY
        bfg.Category,
        bfg.rating_gap_bucket
),

termination_gap_rates AS (
    SELECT
        bfg.Termination,
        bfg.rating_gap_bucket,
        COUNT(*) AS total_games,
        SUM(bfg.favorite_won) AS favorite_wins,
        SUM(bfg.favorite_won) * 100.0 / COUNT(*) AS favorite_win_rate
    FROM base_favorite_games AS bfg
    WHERE bfg.Termination IN ('Normal', 'Time forfeit')
    GROUP BY
        bfg.Termination,
        bfg.rating_gap_bucket
),

signal_strength_summary AS (
    SELECT
        1 AS sort_order,
        0 AS bucket_order,
        'Across rating-gap buckets' AS comparison_type,
        'All clear-favorite games' AS comparison_group,
        MIN(rgr.favorite_win_rate) AS min_favorite_win_rate,
        MAX(rgr.favorite_win_rate) AS max_favorite_win_rate,
        MAX(rgr.favorite_win_rate) - MIN(rgr.favorite_win_rate) AS range_percentage_points
    FROM rating_gap_rates AS rgr

    UNION ALL

    SELECT
        2 AS sort_order,
        CASE cgr.rating_gap_bucket
            WHEN '400+' THEN 4
            WHEN '200-399' THEN 3
            WHEN '100-199' THEN 2
            WHEN '51-99' THEN 1
        END AS bucket_order,
        'Across categories within rating-gap bucket' AS comparison_type,
        cgr.rating_gap_bucket AS comparison_group,
        MIN(cgr.favorite_win_rate) AS min_favorite_win_rate,
        MAX(cgr.favorite_win_rate) AS max_favorite_win_rate,
        MAX(cgr.favorite_win_rate) - MIN(cgr.favorite_win_rate) AS range_percentage_points
    FROM category_gap_rates AS cgr
    GROUP BY cgr.rating_gap_bucket

    UNION ALL

    SELECT
        3 AS sort_order,
        CASE tgr.rating_gap_bucket
            WHEN '400+' THEN 4
            WHEN '200-399' THEN 3
            WHEN '100-199' THEN 2
            WHEN '51-99' THEN 1
        END AS bucket_order,
        'Normal vs time forfeit within rating-gap bucket' AS comparison_type,
        tgr.rating_gap_bucket AS comparison_group,
        MIN(tgr.favorite_win_rate) AS min_favorite_win_rate,
        MAX(tgr.favorite_win_rate) AS max_favorite_win_rate,
        MAX(tgr.favorite_win_rate) - MIN(tgr.favorite_win_rate) AS range_percentage_points
    FROM termination_gap_rates AS tgr
    GROUP BY tgr.rating_gap_bucket
)

SELECT
    sss.comparison_type,
    sss.comparison_group,
    ROUND(sss.min_favorite_win_rate, 2) AS min_favorite_win_rate,
    ROUND(sss.max_favorite_win_rate, 2) AS max_favorite_win_rate,
    ROUND(sss.range_percentage_points, 2) AS range_percentage_points
FROM signal_strength_summary AS sss
ORDER BY
    sss.sort_order,
    sss.bucket_order DESC;
