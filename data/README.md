# Data sources

Raw files live in `data/raw/` and are not committed (see `.gitignore`). Download date for all files: 2026-11-06. Code in this repo is MIT-licensed; the data is not redistributed here.

## 1. TGA Medicine Shortage Reports Database

- Page: https://www.tga.gov.au/safety/shortages/medicine-shortage-reports-database
- Export page: https://apps.tga.gov.au/Prod/msi/search?shortagetype=All

| File | Source | Size (bytes) |
|---|---|---|
| `tga_shortages_active_20261106.csv` | "Export active shortage reports" | 363,155 |
| `tga_shortages_archived_20261106.csv` | "Export archived shortage reports" | 2,308,634 |

Caveats:
- Based on reports submitted by sponsors. Sponsors must report critical shortages within 2 working days and other shortages within 10 working days; some are reported late.
- Only national shortages are included. Excluded: non-reportable medicines (most over-the-counter), unapproved medicines, local-level supply disruptions.
- A shortage resolution date is the date stock is available at wholesalers; it may take about a week to reach pharmacy shelves.
- On 2026-11-06 the TGA export page displayed a notice of a technical issue affecting the archived export: some historical shortages and discontinuations may be missing. The active export is stated as not affected.
- Both files start with preamble lines (report generation time, title) before the data; handled in cleaning.
- Terms of use: not yet verified. Check https://www.tga.gov.au/copyright before release (task T4.3).

## 2. PBS Date of Supply data

- Page: https://pbs.gov.au/statistics/dos-and-dop/dos-and-dop (page last updated 22 Oct 2026)

| File | Source | Size (bytes) |
|---|---|---|
| `pbs_dos_2025-07_2026-06.csv` | https://pbs.gov.au/statistics/dos-and-dop/files/dos-jul-2025-to-jun-2026-phrmcy-type.csv | 36,398,673 |
| `pbs_dos_2024-07_2025-06.csv` | https://pbs.gov.au/statistics/dos-and-dop/files/dos-jul-2024-to-jun-2025-phrmcy-type.csv | 35,384,567 |
| `pbs_item_drug_map.csv` | https://pbs.gov.au/statistics/dos-and-dop/files/pbs-item-drug-map.csv | 1,070,507 |

Notes:
- The two DOS files are the quarterly supplementary reports. They include dispensing pharmacy type for PBS section 85 and RPBS items and exclude section 100 supply.
- Per PBS data notes: figures are never final, recent months are less complete, and the report should not be used to analyse recent trends.
- The item drug map gives the generic drug names associated with each item code.
- Months actually covered by each file and the values of `PHRMCY_TYPE`: to be confirmed in profiling (T2.4).
- Downloaded DOS files are larger than the sizes stated on the PBS page (16.5 MB and 17.5 MB); cause not verified.

Citation (derivative works): Analysis based on Pharmaceutical Benefits Scheme and Repatriation Pharmaceutical Benefits Scheme Date of Supply Data, Australian Government Department of Health, Disability and Ageing, www.pbs.gov.au
