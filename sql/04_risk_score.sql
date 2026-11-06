-- Risk score = exposure x usage, on ingredients with S94 PUB prescriptions (matched_public = 1).
-- exposure = (pct_rank(events) + pct_rank(union shortage days) + max_rating/4) / 3
-- risk_score = 100 x exposure x pct_rank(S94 PUB prescriptions)
-- events = resolved + current episodes (counted per product, so multi-brand ingredients are favoured; see n_periods).
-- union shortage days = calendar days with >= 1 product in shortage (resolved episodes, valid duration);
--   overlapping intervals of different products are merged (gaps-and-islands), not summed.
-- risk_score_alt  : events restricted to starts in 2024-07..2026-04.
-- risk_score_alt2 : max_rating/4 replaced by pct_rank(number of Critical events).
DROP TABLE IF EXISTS out_risk_ranking;
CREATE TABLE out_risk_ranking AS
WITH ev AS (
    SELECT ingredient_key,
           COUNT(*) AS n_events,
           SUM(episode_type = 'current') AS n_ongoing,
           SUM(shortage_impact_rating = 'Critical') AS n_critical,
           MAX(CASE shortage_impact_rating WHEN 'Critical' THEN 4 WHEN 'High' THEN 3
                                           WHEN 'Medium' THEN 2 WHEN 'Low' THEN 1 END) AS max_rating_score,
           SUM(CASE WHEN supply_impact_start_date >= '2024-07-01'
                     AND supply_impact_start_date <  '2026-05-01' THEN 1 ELSE 0 END) AS n_events_window
    FROM tga_episodes
    WHERE no_ingredient = 0 AND ingredient_key IS NOT NULL
      AND episode_type IN ('resolved', 'current')
    GROUP BY ingredient_key
),
iv AS (
    SELECT ingredient_key,
           supply_impact_start_date AS s,
           supply_impact_end_date AS e,
           MAX(supply_impact_end_date) OVER (
               PARTITION BY ingredient_key ORDER BY supply_impact_start_date, supply_impact_end_date
               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_max_end
    FROM tga_episodes
    WHERE episode_type = 'resolved' AND valid_duration = 1
      AND no_ingredient = 0 AND ingredient_key IS NOT NULL
),
isl AS (
    SELECT ingredient_key, s, e,
           SUM(CASE WHEN prev_max_end IS NULL OR s > prev_max_end THEN 1 ELSE 0 END) OVER (
               PARTITION BY ingredient_key ORDER BY s, e
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp
    FROM iv
),
un AS (
    SELECT ingredient_key, COUNT(*) AS n_periods, SUM(days) AS union_days
    FROM (SELECT ingredient_key, grp,
                 CAST(ROUND(julianday(MAX(e)) - julianday(MIN(s))) AS INTEGER) AS days
          FROM isl GROUP BY ingredient_key, grp)
    GROUP BY ingredient_key
),
base AS (
    SELECT s.ingredient_key,
           COALESCE(e.n_events, 0) AS n_events,
           COALESCE(e.n_ongoing, 0) AS n_ongoing,
           COALESCE(e.n_critical, 0) AS n_critical,
           COALESCE(e.max_rating_score, 0) AS max_rating_score,
           COALESCE(e.n_events_window, 0) AS n_events_window,
           COALESCE(u.union_days, 0) AS total_duration_days,
           COALESCE(u.n_periods, 0) AS n_periods,
           COALESCE(s.total_duration_days, 0) AS duration_sum_days,
           s.total_prescriptions
    FROM out_ingredient_shortage s
    LEFT JOIN ev e ON e.ingredient_key = s.ingredient_key
    LEFT JOIN un u ON u.ingredient_key = s.ingredient_key
    WHERE s.matched_public = 1
),
pr AS (
    SELECT *,
           PERCENT_RANK() OVER (ORDER BY n_events) AS pr_events,
           PERCENT_RANK() OVER (ORDER BY n_events_window) AS pr_events_window,
           PERCENT_RANK() OVER (ORDER BY total_duration_days) AS pr_duration,
           PERCENT_RANK() OVER (ORDER BY n_critical) AS pr_critical,
           PERCENT_RANK() OVER (ORDER BY total_prescriptions) AS pr_rx
    FROM base
),
sc AS (
    SELECT *,
           ROUND(100.0 * (pr_events + pr_duration + max_rating_score / 4.0) / 3.0 * pr_rx, 2) AS risk_score,
           ROUND(100.0 * (pr_events_window + pr_duration + max_rating_score / 4.0) / 3.0 * pr_rx, 2) AS risk_score_alt,
           ROUND(100.0 * (pr_events + pr_duration + pr_critical) / 3.0 * pr_rx, 2) AS risk_score_alt2
    FROM pr
)
SELECT RANK() OVER (ORDER BY risk_score DESC) AS risk_rank,
       RANK() OVER (ORDER BY risk_score_alt DESC) AS risk_rank_alt,
       RANK() OVER (ORDER BY risk_score_alt2 DESC) AS risk_rank_alt2,
       ingredient_key, risk_score, risk_score_alt, risk_score_alt2,
       n_events, n_periods, n_ongoing, n_critical,
       CASE max_rating_score WHEN 4 THEN 'Critical' WHEN 3 THEN 'High'
                             WHEN 2 THEN 'Medium' WHEN 1 THEN 'Low' ELSE 'None' END AS max_rating,
       total_duration_days, duration_sum_days, n_events_window, total_prescriptions,
       ROUND(pr_events, 3) AS pr_events, ROUND(pr_duration, 3) AS pr_duration,
       ROUND(pr_critical, 3) AS pr_critical, ROUND(pr_rx, 3) AS pr_rx
FROM sc;
