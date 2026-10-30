# Mapping Conservation Priorities and Land-Cover Change in Victoria

An environmental atlas for DEECA public servants investigating modelled conservation opportunities alongside historical landscape classifications. Desktop is the primary device class.

## Run the delivered app

Install dependencies separately in your R environment: `shiny`, `leaflet`, `sf`, `ggplot2`, `jsonlite`, `htmltools`. Use R 4.4 or newer. The app does not install packages.

From this project's root:

```r
shiny::runApp()
```

The local application ZIP includes `data/smp_cache.rds`, original boundaries, and prepared land cover summaries. It needs no raster processing or online map tiles to run. When cloning this repository, prepare the spatial cache first:

```sh
Rscript scripts/prepare_data.R
```

The prepared land cover release is tied to the frozen original boundaries. Startup verifies their fingerprint. A different spatial-cache hash is accepted only after matching area IDs and source attributes and checking display geometry against the frozen boundaries to within 0.01 metre. Retrieval metadata and RDS serialization therefore do not force an unnecessary raster rebuild. If boundaries actually change, restore the matching snapshot or rebuild the land cover summaries and Tableau input together.

## Explore

- **Explore priorities:** 16 actions, relative cost effectiveness ranks and selected-action relevant hectares across 1,053 summary areas. The introduction, action names, live map title and legend explain that higher ranks indicate stronger modelled benefits relative to cost for the chosen action. Select by map or unit search. Pin up to three areas, compare the action heatmap and download records including explicit missing actions.
- **Explore landscape change:** choose one of 19 cover types and an earlier/later historical period. The introduction and live map title distinguish later-period cover from change between periods. Legends, labelled endpoint values and a percentage-point example explain colours and calculations. Compare selected/pinned areas, inspect all-cover type changes and follow the chosen type through all seven periods. Downloads retain coverage and provenance.
- **Tableau:** open `tableau/Victoria_Landscape_Change.twbx`. Its `LandscapeChange` dashboard shows selected cover through time, main area composition and endpoint change dots. Shiny owns area, cover type and period selection. Tableau retains the composition and trend presentation controls. The packaged workbook includes its CSV and uses the same prepared land cover values as R.
- **Sources & methods:** dates, denominator definitions, source links and interpretation limits.

Selections and pins are shared across the two workspaces. Land cover statistics are per summary area, not per LGA. Units overlap; their values are never summed into combined-area or statewide totals.

## Sources and processing

SMP4 boundaries and action attributes come from [DEECA's summary-area service](https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer). The frozen local snapshot was retrieved **22 October 2026**, and the model is associated with July 2023. It has 1,053 boundaries and 12,403 action records. The priority map uses only `CE_RANK`. Source `AREA_5` and `AREA_20` are retained in comparison downloads, alongside derived shares, but are not visualised in the interface. `AREA_20` follows NatureKit's **top 15%** label; the top 5% is included within it. Missing action records are not zeros. Unit 925 has no SMP action records.

[Victorian Land Cover Time Series](https://discover.data.vic.gov.au/dataset/victorian-land-cover-time-series) supplies seven classified 25 m GeoTIFFs. Downloaded filenames and raster attribute tables use **1985-1990** for the first epoch, although the catalogue describes it as 1987-1990. The app follows the downloaded files. These are multiple year epochs ending in 2019, not annual or current observations.

`data/landcover/summary.csv.gz` contains 140,049 records at microID x epoch x class grain. Original boundary vertices are transformed to EPSG:3111 and repaired without simplification. Exact cell-coverage fractions determine class proportions. Grid hectares are projected polygon hectares allocated by those proportions. Small numerical residuals are checked before normalisation. The 100 m simplified geometry is used for display only.

Class share divides class area by classified area, codes 1-19, within each unit/epoch. Code 0 is unclassified; TIFF NoData (127) is retained separately. NoData is not changed into an absent class. A complete boundary audit and raster fingerprints are in `data/landcover/manifest.json`.

For a reproducible full resolution rebuild, also install `terra`, `exactextractr` and `foreign`, then run:

```sh
Rscript scripts/prepare_landcover.R --refresh
Rscript scripts/prepare_tableau.R
python3 scripts/build_tableau.py
```

The preparation script downloads the 426,746,271-byte official ZIP if absent. Seven epochs processed in about three minutes on the development machine; timing varies by hardware. Raw raster downloads remain under `data/downloads/` and are not needed at runtime. Reopen a regenerated workbook in Tableau Desktop to validate it after changing the schema or calculations.

## Tableau integration boundary

The user-published `https://public.tableau.com/views/Victoria_Landscape_Change/LandscapeChange` view is configured in `config/app.json`. The interactive dashboard loads within Explore landscape change. A separate-tab link is available only inside the collapsed troubleshooting section.

The API v3 bridge synchronises focus, three comparison slots, class and start/end epochs and checks the exact data release. It clears saved manual area restrictions on the third worksheet so that the current main area and pins control the endpoint comparison. The class and period calculation filters remain active. A fresh headless Edge session verified the actual published view loading inside localhost Shiny and accepting a Shiny-to-Tableau Water selection, with no JavaScript errors or failed requests. Bidirectional selection, exports, fallback rendering and laptop sizing have also been checked in local Edge sessions. RStudio Viewer and a deployed HTTPS Shiny installation have not been verified.

## Validate and package

```sh
Rscript tests/run_tests.R
node tests/landscape_bridge.cjs
python3 tests/check_tableau.py
python3 scripts/package_submission.py
```

See `docs/VALIDATION.md` for current evidence. The package builder produces `dist/Victoria_Landscape_Atlas.zip`, including code, prepared data, original geometry and the workbook. R packages must already be installed. It excludes raw rasters, archived versions, credentials and Git metadata.

The old PDF activity data and progress workbook are preserved under `archive/progress/` for history. They are not read by the active app or revised Tableau views.

Attribution: State of Victoria, Department of Energy, Environment and Climate Action. Land cover data are provided under CC BY 4.0. SMP4 remains subject to its own source terms. Modelled opportunities do not prove completed work or recovery; land cover classes do not measure habitat quality, species abundance or management effectiveness. Net class totals do not establish pixel transitions or causes of change.
