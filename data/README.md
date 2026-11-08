# Data sources

Raw files live in `data/raw/` and are not committed (see `.gitignore`). The row-level TGA tables `tga_episodes.csv` and `out_shortage_duration.csv` are rebuilt by the pipeline and are not committed either. `data/processed/` otherwise holds aggregated and lookup tables derived from the TGA and PBS data. Download date for all files: 2026-11-06. Code in this repo is MIT-licensed.

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
- Terms of use: the TGA copyright page (https://www.tga.gov.au/copyright, last updated 10 September 2025, read on 2026-11-08) allows copying of its content in unaltered form for personal use or internal use within an organisation, bars commercial use, and requires written approval to distribute the material or to reproduce its files and information on another site. For that reason the row-level TGA tables are not committed. Not verified: whether the page covers the shortage export on `apps.tga.gov.au`, and whether it covers figures calculated from the data. Source: Therapeutic Goods Administration, Medicine Shortage Reports Database, © Commonwealth of Australia.

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
- Months used in the analysis: July 2024 to April 2026 (22 months). May and June 2026 are excluded because the PBS notes say the most recent months are less complete. Public hospital supply is the pharmacy type `S94 PUB` in the `PHRMCY_TYPE` column.
- Downloaded DOS files are larger than the sizes stated on the PBS page (16.5 MB and 17.5 MB); cause not verified.

Citation (derivative works): Analysis based on Pharmaceutical Benefits Scheme and Repatriation Pharmaceutical Benefits Scheme Date of Supply Data, Australian Government Department of Health, Disability and Ageing, www.pbs.gov.au

## 3. Re-downloading the raw files

1. Open each source above. For TGA, click the two export buttons. For PBS, download the three URLs.
2. Save each file into `data/raw/` under the exact name shown in the tables above (rename after download).
3. Do not edit the raw files. All changes happen in `notebooks/02_clean.ipynb` and are logged in `reports/cleaning_log.md`.

The TGA exports are snapshots. A download made after 2026-11-06 will contain different rows, so counts in the README will not match exactly. PBS may replace the DOS files with a newer quarterly release. Compare file sizes with the tables above to see whether you have the same files.
