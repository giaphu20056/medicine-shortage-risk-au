# Medicine shortage risk for public hospitals: which ingredients to buffer first

**Situation.** The pharmacy procurement team of a Victorian public health service has to decide which medicines to hold extra stock of before a national shortage occurs, with limited budget and storage space. Shortages are listed by the TGA, and public hospital use of each ingredient is measured from PBS dispensing data (July 2024 to April 2026).

**Complication.** The most used medicines are not the ones most exposed to shortages. The 49 highest-usage ingredients account for 70.3% of public hospital prescriptions, but the 49 highest by risk score account for only 46.8%, so a list sorted by volume alone misses ingredients with heavy shortage exposure. Prescription counts also give no early warning, because they do not fall when a shortage starts, and the TGA list is reported by sponsors with a delay.

**Question.** Which ingredients should the team buffer first, and what does the shortage history say about how long a buffer has to last?

**Answer.** Start with the 20 ingredients that stay in the top 30 of the risk ranking under all three scoring variants (`robust_top30`); METOPROLOL and AMOXICILLIN rank first. The ranking covers the 489 ingredients that have both TGA shortage records and public hospital prescriptions. Among resolved shortages, the median duration is 45 to 74 days depending on the impact rating. Critical shortages do not last longer than others (median 45 against 56 days), and 12.7% of them last more than 180 days. Prescriptions show no measurable drop when a shortage starts (median ratio 0.997, 95% CI 0.985 to 1.004), so a buffer should cover normal demand. The ranking is a screening tool: it shows where to look first, and the underlying columns and the drug form must be checked before a decision.

**Recommendations,** in priority order (impact against effort; both are judgements, not measured values).

1. **Review the 20 robust ingredients first, then check the rest.** For each ingredient with `robust_top30 = 1`, record a decision (buffer, do not buffer, monitor) for the specific drug form the hospital uses. Then review the other 10 in the top 30 and ingredients with many Critical events (for example ADRENALINE with 33), starting with the Events, Critical and Days short columns: the rating component gives one Critical event the same score as 33. Impact high, effort low, because the list already exists in `reports/priority_list.csv` and the dashboard.
2. **Size each buffer from the ingredient's own shortage durations and normal monthly demand.** Take its resolved durations from `out_shortage_duration`, choose the cover in days from a high percentile, and base the quantity on normal demand. Medians understate the range, since 12.7% of Critical shortages last more than 180 days and ongoing shortages are excluded. Procurement sets the percentile and the quantity rule. Impact high, effort medium.
3. **Check the TGA shortage list for the ranked ingredients on a fixed schedule,** and start a procurement review when one is listed as current or anticipated. Prescription counts cannot serve as the early warning. Impact medium, effort low.

**Metrics to track.**

- Share of the 20 robust ingredients with a documented decision, plus the number of other ingredients reviewed and how many changed decision after the column check (recommendation 1).
- Planned cover in days against the ingredient's longest recent resolved shortage, and days with stock-out during a TGA-listed shortage (recommendation 2).
- Time from a TGA listing to a documented procurement action. Sponsors report with delay, so this measures the team's response, not the shortage itself (recommendation 3).