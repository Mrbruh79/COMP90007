# Data guide and acquisition audit

Snapshot date: 21 October 2026. The source URLs below are DEECA/NatureKit public services or departmental publications. This is not a synthetic dataset.

## Acquired files

| File under `data/processed` | Grain and coverage | Purpose |
|---|---|---|
| `smp4_summary_areas.geojson` | 1,053 summary-area geometries, EPSG:4326 | Unmodified assembled query output |
| `smp4_summary_areas_valid.geojson` | Same IDs, repaired geometry | Map input; all geometries valid and non-empty after repair |
| `smp4_summary_areas.csv` | One row per summary area | Boundary attributes and join dimension |
| `smp4_actions.csv` | 12,403 area/action pairs; 16 actions | Raw attribute snapshot |
| `tableau_area_actions.csv` | Same pairs, names and two derived shares | Chart-ready table; not joined to statewide temporal totals |
| `biodiversity2037_activity_2018_2022.csv` | 52 action/year/coverage records | Four-year performance dataset |
| `unit1_report_table_1.csv` | Six area summary attributes | Sample report overview |
| `unit1_report_table_2.csv` | 27 individual/integrated actions | Sample only, inconsistent with live service |
| `unit1_report_table_3.csv` | 2,058 species rows | Sample modelled species benefits, not sightings or population counts |
| `unit1_report_table_4.csv` | Three action categories | Sample taxonomic summaries |
| `unit1_report_table_5.csv` | 13 indicative cost rows | Sample only; not actual expenditure |
| `unit1_report_table_6.csv` | 12 terms | Source report glossary |

## Sources and retrieval

1. [SMP4 summary-area MapServer](https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer): layer 0 boundaries, table 1 actions. The downloader first requests all object IDs, then fetches batches of 250. It checks returned counts and rejects transfer-limit truncation. Each batch URL, hash and byte count is in `evidence/download_manifest.json`.
2. [Official Unit 1 report](https://bio-prd-naturekit-public-data.s3-ap-southeast-2.amazonaws.com/smp-reports/summary_areas_v4/SMPreport_Summary_unit1.html): full HTML saved under `data/raw`. Its URL was obtained from the NatureKit summary-area configuration, not guessed from an unrelated repository. Embedded DataTables were parsed as JSON without executing the page's scripts. Date in report: 24 March 2023.
3. [Biodiversity 2037 progress report, 2020-2022 update](https://www.environment.vic.gov.au/__data/assets/pdf_file/0025/722563/Bio2037-Progress-update-2020-2022-final.pdf): tables on printed pages 5, 7, 11, 15 and 19 were transcribed into CSV, with row-level source/page fields. The web reader could read the PDF; direct local download returned HTTP 403, so the PDF is not bundled. A second team member should check transcription against these pages before final submission.
4. [NatureKit service directory](https://maps2.biodiversity.vic.gov.au/Geocortex/Essentials/REST/sites/NatureKit_75/map/mapservices): configuration saved in `evidence/naturekit_services.json`. This supplies friendly field labels and official report links.
5. [Land-cover service](https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/landcover/MapServer): metadata downloaded, seven epochs verified. No raster samples or area-change statistics are claimed.

## Field definitions and transformations

| Field | Meaning / use | Important restriction |
|---|---|---|
| `microID` | Stable join key within this snapshot, such as `unit1` | Do not join using generic OBJECTID fields across tables |
| `Name` | Unit display label | Not an LGA or settlement name |
| `CE_RANK` | Median cost-effectiveness rank, 0-100 observed | Higher is relatively higher ranked; not dollars, probability or additive benefit |
| `CE_RANGE` | Source cost-effectiveness range string | Preserve; not a confidence interval |
| `AREA_TOT` | Total relevant hectares for that action | Denominator varies by action and area |
| `AREA_5` | Relevant hectares in top 5% | Nested within top 15% |
| `AREA_20` | NatureKit display label: hectares in top 15% | Raw name is misleading; keep provenance |
| `BE_RANK` / `BE_RANGE` | Source benefit summary | Mean/median discrepancy between sources; omit from core comparisons |
| `top5_share_relevant_pct` | `100 * AREA_5 / AREA_TOT` | A proportion of relevant action area, not whole polygon |
| `top15_share_relevant_pct` | `100 * AREA_20 / AREA_TOT` | Same denominator rule; do not add to top5 share |
| `financial_year` | Published year, 2018-19 through 2021-22 | No interpolation or claim of present-day coverage |
| `coverage` | priority, other or statewide | Statewide already includes priority and other |
| `basis` | annual or cumulative since 2017 | Never sum successive cumulative observations |
| `target_ha` / `target_basis` | Scope-matched policy target | Annual targets for control; 2037 targets for cumulative measures |

The service's geometry source CRS is EPSG:3111 (legacy identifier 102171), whereas the Geocortex wrapper includes a different CRS identifier in one extent. The ArcGIS query explicitly requests 4326; the resulting GeoJSON was read and checked as 4326. Preserve this distinction if reprocessing directly from the service. Do not calculate hectares from longitude/latitude coordinates.

## Audit results

- 1,053 unique boundary keys; 12,403 unique area/action keys.
- 100% of action rows match a boundary. `unit925` has no action records.
- No blank fields in the acquired action table. Missing area/action combinations remain missing, not zero.
- Ranks range from 0 to 100. Relevant hectares range from 1 to 252,464.
- All records satisfy `0 <= AREA_5 <= AREA_20 <= AREA_TOT`.
- Three invalid source geometries, no empty geometries. `sf::st_make_valid` repaired them; all 1,053 IDs remain, with zero invalid or empty geometries. Reasons are in `evidence/geometry_repairs.csv`. Area-change/topology effects still need checking before analytical overlays; the repaired file is intended for the display map.
- The 52 performance rows cover four financial years. Four action families have priority, other and statewide categories; permanent protection has statewide totals only.
- Geographic extent is approximately 140.962 to 149.976 degrees east and 39.159 to 33.981 degrees south, consistent with Victoria.

Machine-readable results are in `evidence/data_audit.json` and `evidence/geometry_audit.txt`.

## Interpretation and licensing

Keep live service records and report tables separate. A Unit 1 fox-control rank is 87 in the service and 85 in the report. Neither should overwrite the other. Preserve dates and original labels when reporting the discrepancy.

The service metadata has blank copyright text and the layer metadata does not establish a redistribution licence. Public access is confirmed; publication rights are not confirmed by this audit. Retain State of Victoria/DEECA attribution and obtain the applicable dataset terms before uploading data to Tableau Public or redistributing outside the project. A Creative Commons notice on an explanatory publication is not proof that every underlying dataset has the same terms.

## Reproduce

Run `python scripts/gather_data.py`, `python scripts/gather_supporting_sources.py`, then `python scripts/prepare_and_audit.py` from any directory using Python 3. Run `Rscript scripts/audit_geometry.R` and optionally `Rscript scripts/exploratory_figure.R` from this folder with `sf` installed. No script installs R packages. Preserve the existing snapshot before refreshing because upstream values may change.

The successful geometry check used the existing workspace R runtime and its `tmp/r_runtime/library` library. The system R 4.6.1 library did not contain `sf`. That local runtime is not part of this data package. Before implementation, create and test a documented dependency environment rather than copy machine-specific paths into the submitted app.

The exploratory DataVic full-text query returned unrelated contract records; these are not accepted project datasets. The corresponding search-response file is evidence of a rejected search, not a source for the dashboard.
