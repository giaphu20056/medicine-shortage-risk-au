-- Join TGA shortage episodes to PBS public-hospital (S94 PUB) usage by ingredient_key.
-- Each side is aggregated to one row per ingredient_key BEFORE joining (no row fan-out).
-- Unmatched ingredients are kept with NULL usage: "not measurable", not zero.

DROP TABLE IF EXISTS out_match_rate;
CREATE TABLE out_match_rate AS
SELECT 'episodes' AS level,
       COUNT(*) AS n_total,
       SUM(in_pbs_map) AS n_in_pbs_map,
       SUM(in_pbs_public) AS n_in_pbs_public,
       ROUND(100.0 * SUM(in_pbs_map) / COUNT(*), 1) AS pct_in_pbs_map,
       ROUND(100.0 * SUM(in_pbs_public) / COUNT(*), 1) AS pct_in_pbs_public
FROM tga_episodes
UNION ALL
SELECT 'ingredient_keys',
       COUNT(*), SUM(in_map), SUM(in_public),
       ROUND(100.0 * SUM(in_map) / COUNT(*), 1),
       ROUND(100.0 * SUM(in_public) / COUNT(*), 1)
FROM (
    SELECT ingredient_key, MAX(in_pbs_map) AS in_map, MAX(in_pbs_public) AS in_public
    FROM tga_episodes
    WHERE no_ingredient = 0 AND ingredient_key IS NOT NULL
    GROUP BY ingredient_key
);

DROP TABLE IF EXISTS out_ingredient_shortage;
CREATE TABLE out_ingredient_shortage AS
WITH tga AS (
    SELECT ingredient_key,
           COUNT(*) AS n_episodes,
           SUM(episode_type = 'resolved') AS n_resolved,
           SUM(episode_type = 'current') AS n_current,
           SUM(episode_type = 'anticipated') AS n_anticipated,
           SUM(episode_type = 'discontinuation') AS n_discontinuation,
           SUM(CASE WHEN shortage_impact_rating = 'Critical'
                     AND episode_type IN ('resolved', 'current') THEN 1 ELSE 0 END) AS n_critical,
           SUM(CASE WHEN episode_type IN ('resolved', 'current')
                     AND supply_impact_start_date >= '2024-07-01'
                     AND supply_impact_start_date <  '2026-05-01' THEN 1 ELSE 0 END) AS n_events_in_window,
           SUM(CASE WHEN valid_duration = 1 THEN duration_days END) AS total_duration_days,
           ROUND(AVG(CASE WHEN valid_duration = 1 THEN duration_days END), 1) AS avg_duration_days
    FROM tga_episodes
    WHERE no_ingredient = 0 AND ingredient_key IS NOT NULL
    GROUP BY ingredient_key
),
pbs AS (
    SELECT ingredient_key,
           SUM(prescriptions) AS total_prescriptions,
           COUNT(DISTINCT month) AS n_months_with_rx
    FROM pbs_public_monthly
    GROUP BY ingredient_key
)
SELECT t.*,
       p.total_prescriptions,
       p.n_months_with_rx,
       CASE WHEN p.ingredient_key IS NULL THEN 0 ELSE 1 END AS matched_public
FROM tga t
LEFT JOIN pbs p ON p.ingredient_key = t.ingredient_key;
