-- ============================================================
-- Lichess Game Analysis — Engine Evaluation SQL Queries
-- Notebook: 02_engine_evaluation_analysis.ipynb
--
-- Purpose:
-- Analyze the engineered game-level engine-evaluation feature table.
-- The main focus is whether evaluation volatility, extreme swings,
-- mate notation, and final available evaluation features help explain
-- favorite wins, upsets, game categories, and termination types.
--
-- Table used:
-- eval_features
--
-- Note:
-- The eval_features table is created in Notebook 02 after parsing
-- raw Eval_ply_* columns, separating forced-mate notation, and
-- engineering game-level evaluation features.
-- ============================================================


-- ============================================================
-- Section 12: Validate SQLite Feature Table
--
-- Goal:
-- Confirm that the engineered evaluation feature table was loaded
-- into SQLite and preserves the expected game-level row structure.
-- ============================================================

SELECT
    COUNT(*) AS total_rows
FROM eval_features;


-- ============================================================
-- Section 13: Inspect Available SQL Columns
--
-- Goal:
-- Review the available columns before writing analysis queries.
-- This helps confirm that the engineered feature names are available
-- inside SQLite.
-- ============================================================

PRAGMA table_info(eval_features);


-- ============================================================
-- Section 14: Favorite Wins vs Upsets — Evaluation Volatility
--
-- Goal:
-- Compare decisive favorite wins and upsets using broad
-- engine-evaluation features. This tests whether upsets are linked
-- to larger swings, higher volatility, stronger final magnitude,
-- or more forced-mate notation.
-- ============================================================

SELECT
    ef.favorite_outcome,
    COUNT(*) AS total_games,
    ROUND(AVG(ef.max_eval_swing), 2) AS avg_max_eval_swing,
    ROUND(AVG(ef.eval_volatility), 2) AS avg_eval_volatility,
    ROUND(AVG(ef.abs_final_available_eval), 2) AS avg_abs_final_eval,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.had_mate_eval = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS mate_eval_rate,
    ROUND(
        AVG(CASE
            WHEN ef.had_mate_eval = 1 THEN ef.first_mate_ply
        END),
        2
    ) AS avg_first_mate_ply
FROM eval_features AS ef
WHERE ef.favorite_outcome IN ('Favorite won', 'Upset')
GROUP BY ef.favorite_outcome
ORDER BY
    CASE ef.favorite_outcome
        WHEN 'Favorite won' THEN 1
        WHEN 'Upset' THEN 2
    END;


-- ============================================================
-- Section 15: Evaluation Volatility by Rating-Gap Bucket
--
-- Goal:
-- Check whether favorite wins and upsets differ more clearly after
-- controlling for rating-gap size. This connects the evaluation
-- feature analysis back to the strongest metadata signal from
-- Notebook 01.
-- ============================================================

SELECT
    ef.rating_gap_bucket,
    ef.favorite_outcome,
    COUNT(*) AS total_games,
    ROUND(AVG(ef.max_eval_swing), 2) AS avg_max_eval_swing,
    ROUND(AVG(ef.eval_volatility), 2) AS avg_eval_volatility,
    ROUND(AVG(ef.abs_final_available_eval), 2) AS avg_abs_final_eval,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.had_mate_eval = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS mate_eval_rate,
    ROUND(
        AVG(CASE
            WHEN ef.had_mate_eval = 1 THEN ef.first_mate_ply
        END),
        2
    ) AS avg_first_mate_ply
FROM eval_features AS ef
WHERE ef.favorite_outcome IN ('Favorite won', 'Upset')
    AND ef.rating_gap_bucket IS NOT NULL
GROUP BY
    ef.rating_gap_bucket,
    ef.favorite_outcome
ORDER BY
    CASE ef.rating_gap_bucket
        WHEN '400+' THEN 4
        WHEN '200-399' THEN 3
        WHEN '100-199' THEN 2
        WHEN '51-99' THEN 1
    END DESC,
    CASE ef.favorite_outcome
        WHEN 'Favorite won' THEN 1
        WHEN 'Upset' THEN 2
    END;


-- ============================================================
-- Section 16: Evaluation Volatility by Game Category
--
-- Goal:
-- Compare broad evaluation-volatility features across Bullet,
-- Blitz, Rapid, and Classical games. This tests whether faster
-- categories show more unstable numeric evaluation patterns.
-- ============================================================

SELECT
    ef.Category,
    COUNT(*) AS total_games,
    ROUND(AVG(ef.max_eval_swing), 2) AS avg_max_eval_swing,
    ROUND(AVG(ef.eval_volatility), 2) AS avg_eval_volatility,
    ROUND(AVG(ef.abs_final_available_eval), 2) AS avg_abs_final_eval,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.had_mate_eval = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS mate_eval_rate,
    ROUND(
        AVG(CASE
            WHEN ef.had_mate_eval = 1 THEN ef.first_mate_ply
        END),
        2
    ) AS avg_first_mate_ply
FROM eval_features AS ef
WHERE ef.Category IS NOT NULL
GROUP BY ef.Category
ORDER BY
    CASE ef.Category
        WHEN 'Bullet' THEN 1
        WHEN 'Blitz' THEN 2
        WHEN 'Rapid' THEN 3
        WHEN 'Classical' THEN 4
    END;


-- ============================================================
-- Section 17: Extreme Evaluation Swing Rate by Category and Outcome
--
-- Goal:
-- Average volatility can hide skewed behavior, so this query checks
-- whether unusually large maximum evaluation swings are concentrated
-- in specific categories or favorite outcomes.
--
-- Threshold:
-- The threshold below is the 95th percentile of max_eval_swing from
-- Notebook 02 after loading all available Eval_ply_* columns.
-- This makes the cutoff data-driven instead of arbitrary.
-- ============================================================

WITH extreme_swing_params AS (
    SELECT 57.861 AS extreme_swing_threshold
)

SELECT
    ef.Category,
    ef.favorite_outcome,
    COUNT(*) AS total_games,
    SUM(CASE
        WHEN ef.max_eval_swing >= esp.extreme_swing_threshold THEN 1
        ELSE 0
    END) AS extreme_swing_games,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.max_eval_swing >= esp.extreme_swing_threshold THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS extreme_swing_rate,
    ROUND(AVG(ef.max_eval_swing), 2) AS avg_max_eval_swing,
    ROUND(AVG(ef.eval_volatility), 2) AS avg_eval_volatility
FROM eval_features AS ef
CROSS JOIN extreme_swing_params AS esp
WHERE ef.Category IS NOT NULL
    AND ef.favorite_outcome IN ('Favorite won', 'Upset')
    AND ef.max_eval_swing IS NOT NULL
GROUP BY
    ef.Category,
    ef.favorite_outcome
ORDER BY
    CASE ef.Category
        WHEN 'Bullet' THEN 1
        WHEN 'Blitz' THEN 2
        WHEN 'Rapid' THEN 3
        WHEN 'Classical' THEN 4
    END,
    CASE ef.favorite_outcome
        WHEN 'Favorite won' THEN 1
        WHEN 'Upset' THEN 2
    END;


-- ============================================================
-- Section 18: Final Available Evaluation State by Termination Type
--
-- Goal:
-- Explore whether normal endings and time-forfeit endings differ
-- in the last available numeric evaluation. This query attempts a
-- winner-perspective transformation using the raw evaluation sign.
--
-- Important limitation:
-- This query is exploratory. A later sanity check showed that the
-- raw evaluation sign does not clearly align with winner color, so
-- directional claims such as "winner ahead" or "winner behind" should
-- not be treated as strong findings without clearer documentation of
-- the dataset's evaluation convention.
-- ============================================================

WITH final_eval_state AS (
    SELECT
        ef.game_id,
        ef.Termination,
        ef.Category,
        ef.winner,
        ef.final_available_eval,
        ef.abs_final_available_eval,
        CASE
            WHEN ef.winner = 'White' THEN ef.final_available_eval
            WHEN ef.winner = 'Black' THEN -ef.final_available_eval
        END AS final_eval_from_winner_perspective
    FROM eval_features AS ef
    WHERE ef.winner IN ('White', 'Black')
        AND ef.final_available_eval IS NOT NULL
        AND ef.Termination IN ('Normal', 'Time forfeit')
)

SELECT
    fes.Termination,
    COUNT(*) AS total_games,
    ROUND(AVG(fes.final_eval_from_winner_perspective), 2) AS avg_final_eval_from_winner_perspective,
    ROUND(AVG(fes.abs_final_available_eval), 2) AS avg_abs_final_eval,
    ROUND(
        100.0 * SUM(CASE
            WHEN fes.final_eval_from_winner_perspective > 0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS winner_ahead_rate,
    ROUND(
        100.0 * SUM(CASE
            WHEN fes.final_eval_from_winner_perspective BETWEEN -0.50 AND 0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS roughly_equal_rate,
    ROUND(
        100.0 * SUM(CASE
            WHEN fes.final_eval_from_winner_perspective < -0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS winner_behind_rate
FROM final_eval_state AS fes
GROUP BY fes.Termination
ORDER BY
    CASE fes.Termination
        WHEN 'Normal' THEN 1
        WHEN 'Time forfeit' THEN 2
    END;


-- ============================================================
-- Section 19: Evaluation Sign Sanity Check by Winner
--
-- Goal:
-- Check whether positive and negative final_available_eval values
-- clearly align with the actual winner. If the sign were a simple
-- White-perspective score, White wins should be mostly positive and
-- Black wins should be mostly negative.
--
-- Main use:
-- This query supports the limitation that directional final-eval
-- claims should be avoided unless the raw evaluation sign convention
-- is verified more clearly.
-- ============================================================

SELECT
    ef.winner,
    COUNT(*) AS total_games,
    ROUND(AVG(ef.final_available_eval), 2) AS avg_final_available_eval,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.final_available_eval > 0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS positive_eval_rate,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.final_available_eval BETWEEN -0.50 AND 0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS roughly_equal_rate,
    ROUND(
        100.0 * SUM(CASE
            WHEN ef.final_available_eval < -0.50 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS negative_eval_rate
FROM eval_features AS ef
WHERE ef.winner IN ('White', 'Black')
    AND ef.final_available_eval IS NOT NULL
GROUP BY ef.winner;
