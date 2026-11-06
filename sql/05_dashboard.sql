-- Source tables for the Power BI dashboard (ranked ingredients only, window 2024-07..2026-04).
DROP TABLE IF EXISTS out_dash_ranking;
CREATE TABLE out_dash_ranking AS
SELECT r.*,
       CASE WHEN risk_rank <= 30 AND risk_rank_alt <= 30 AND risk_rank_alt2 <= 30 THEN 1 ELSE 0 END AS robust_top30
FROM out_risk_ranking r;

DROP TABLE IF EXISTS out_dash_trend;
CREATE TABLE out_dash_trend AS
SELECT t.ingredient_key,
       strftime('%Y-%m-01', t.supply_impact_start_date) AS month,
       COUNT(*) AS n_events,
       SUM(t.shortage_impact_rating = 'Critical') AS n_critical
FROM tga_episodes t
JOIN out_risk_ranking r ON r.ingredient_key = t.ingredient_key
WHERE t.episode_type IN ('resolved', 'current')
  AND t.supply_impact_start_date >= '2024-07-01' AND t.supply_impact_start_date < '2026-05-01'
GROUP BY t.ingredient_key, month;

DROP TABLE IF EXISTS out_dash_month;
CREATE TABLE out_dash_month AS
WITH RECURSIVE m(month) AS (
    SELECT '2024-07-01' UNION ALL SELECT date(month, '+1 month') FROM m WHERE month < '2026-04-01')
SELECT month FROM m;

DROP TABLE IF EXISTS out_dash_kpi;
CREATE TABLE out_dash_kpi AS
SELECT (SELECT COUNT(*) FROM out_dash_ranking) AS n_ranked,
       (SELECT SUM(total_prescriptions) FROM out_dash_ranking) AS total_public_rx,
       (SELECT SUM(n_events) FROM out_dash_trend) AS n_events_window,
       (SELECT SUM(n_critical) FROM out_dash_trend) AS n_critical_window,
       (SELECT SUM(n_ongoing) FROM out_dash_ranking) AS n_ongoing_products,
       (SELECT SUM(robust_top30) FROM out_dash_ranking) AS n_robust_top30,
       (SELECT pct_in_pbs_public FROM out_match_rate WHERE level = 'episodes') AS pct_episodes_with_public_rx;
