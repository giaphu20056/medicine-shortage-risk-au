-- Window metrics. PBS series is expanded to a full ingredient x month grid so that
-- LAG / ROWS frames are calendar-accurate. Missing months stay NULL (not 0).

DROP TABLE IF EXISTS out_rx_window;
CREATE TABLE out_rx_window AS
WITH months AS (SELECT DISTINCT month FROM pbs_public_monthly),
keys AS (SELECT DISTINCT ingredient_key FROM pbs_public_monthly),
grid AS (
    SELECT k.ingredient_key, m.month, p.prescriptions
    FROM keys k
    CROSS JOIN months m
    LEFT JOIN pbs_public_monthly p
           ON p.ingredient_key = k.ingredient_key AND p.month = m.month
)
SELECT ingredient_key, month, prescriptions,
       LAG(prescriptions, 1) OVER (PARTITION BY ingredient_key ORDER BY month) AS prescriptions_prev1,
       AVG(prescriptions) OVER (PARTITION BY ingredient_key ORDER BY month
                                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS avg_prev3,
       COUNT(prescriptions) OVER (PARTITION BY ingredient_key ORDER BY month
                                  ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS n_prev3
FROM grid;

-- H3 base: one row per ingredient x shortage-start month (2024-10..2026-04).
-- Inner join: ingredients with no PBS public data are excluded (not measurable).
DROP TABLE IF EXISTS out_h3_base;
CREATE TABLE out_h3_base AS
WITH starts AS (
    SELECT ingredient_key,
           strftime('%Y-%m-01', supply_impact_start_date) AS start_month,
           COUNT(*) AS n_episodes,
           MAX(shortage_impact_rating = 'Critical') AS has_critical
    FROM tga_episodes
    WHERE no_ingredient = 0 AND ingredient_key IS NOT NULL
      AND episode_type IN ('resolved', 'current')
      AND supply_impact_start_date >= '2024-10-01'
      AND supply_impact_start_date <  '2026-05-01'
    GROUP BY ingredient_key, start_month
)
SELECT s.ingredient_key, s.start_month, s.n_episodes, s.has_critical,
       w.prescriptions, w.avg_prev3, w.n_prev3,
       ROUND(100.0 * (w.prescriptions - w.avg_prev3) / w.avg_prev3, 1) AS pct_vs_prev3
FROM starts s
JOIN out_rx_window w ON w.ingredient_key = s.ingredient_key AND w.month = s.start_month;

-- H2 base: resolved episodes with valid duration.
-- gap_days_since_prev_end < 0 means overlap with an earlier episode of the same ingredient.
DROP TABLE IF EXISTS out_shortage_duration;
CREATE TABLE out_shortage_duration AS
SELECT ingredient_key, artg_id, shortage_impact_rating, source,
       supply_impact_start_date AS start_date,
       supply_impact_end_date AS end_date,
       duration_days,
       ROW_NUMBER() OVER (PARTITION BY ingredient_key
                          ORDER BY supply_impact_start_date, artg_id) AS seq_in_ingredient,
       COUNT(*) OVER (PARTITION BY ingredient_key) AS n_resolved_ingredient,
       CAST(julianday(supply_impact_start_date) - julianday(
            LAG(supply_impact_end_date) OVER (PARTITION BY ingredient_key
                                              ORDER BY supply_impact_start_date, artg_id)
       ) AS INTEGER) AS gap_days_since_prev_end
FROM tga_episodes
WHERE episode_type = 'resolved' AND valid_duration = 1
  AND no_ingredient = 0 AND ingredient_key IS NOT NULL;
