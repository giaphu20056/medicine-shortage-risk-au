# Framing (locked at T2.4, 2026-11-06)

## Business problem
Pharmacy procurement at a Victorian public health service must decide which active ingredients to buffer before national shortages occur, with limited budget and storage. Objective: rank active ingredients by risk = shortage exposure (episodes, duration) x public hospital usage (prescriptions) to produce a buffer-stock priority list.

## Data grain and keys (profiled in `notebooks/01_profile.ipynb`)
- TGA active export: 1,044 rows, one per `ARTG ID`. TGA archived export: 9,697 rows, 4,945 distinct `ARTG ID` (several episodes per ID). Key columns: `Active ingredients`, `Shortage status` (active file only), `Supply impact start date`, `Supply impact end date`, `Shortage impact rating`, `Reason`. Dates are d/mm/yyyy.
- PBS DOS grain: `MONTH_OF_SUPPLY` x `ITEM_CODE` x `DRUG_TYPE` x `PATIENT_CAT` x `PHRMCY_TYPE` x `SCRIPT_TYPE`; measure `PRESCRIPTIONS`. Public hospital = `PHRMCY_TYPE == "S94 PUB"` (confirmed in PBS explanatory notes).
- Join: PBS `ITEM_CODE` -> `pbs_item_drug_map.DRUG_NAME` (99.96% of 5,198 DOS item codes found) -> normalised TGA `Active ingredients`. Exact string match before normalisation: 405 of 1,351 distinct TGA strings (30.0%). TGA uses salts and "~" for combinations; PBS uses generic names and "+". Normalisation is done in T2.5 and the final match rate is reported.
- Usage window: 202407-202604. 202605 and 202606 are excluded as the least complete months (PBS notes: recent months are less complete and not for trend analysis).

## Hypotheses (each has a falsification condition)
- H1 (concentration). Set = active ingredients matched in PBS with at least one TGA record (active or archived). Usage = sum of `PRESCRIPTIONS` where `PHRMCY_TYPE == "S94 PUB"` in the usage window. The top 10% of ingredients by usage account for more than 50% of the set's usage. False if <= 50%.
- H2 (resolution speed). Episodes with both `Supply impact start date` and `Supply impact end date` (archived rows plus active rows with `Shortage status == "Resolved"`, deduplicated by `ARTG ID` + start date; rows with end < start or end after 2026-11-06 are removed). duration_days = end - start. The median duration of `Shortage impact rating == "Critical"` is shorter than the median of all other ratings (Low, Medium, High). False if the Critical median >= the non-Critical median.
- H3 (usage drop). Unit = shortage episode with start month M in 202410-202604 whose ingredient is matched in PBS. ratio = S94 PUB `PRESCRIPTIONS` in M / mean of the 3 preceding months (baseline > 0). True if the median ratio < 1 (the share of episodes with ratio < 1 is also reported). False if the median ratio >= 1.

## Risk score
Finalised in T3.4. Inputs: number of episodes, total shortage days, highest impact rating, S94 PUB prescriptions.

## Caveats
- TGA data is sponsor-reported (delays), national shortages only, and excludes most non-reportable (over-the-counter) medicines. On 2026-11-06 TGA stated a technical issue with the archived export: some historical records may be missing.
- Archived export has a `High` rating (103 rows) that the active export does not show; treated as non-Critical in H2, sensitivity to be checked.
- H2 excludes ongoing shortages (right-censoring), so long-running shortages are under-represented.
- The PBS supplementary report excludes Section 100 supply, so it covers only part of hospital medicine use.
- TGA records are per product (ARTG), PBS is per generic ingredient; substitution by other brands can mask a usage drop in H3.
