# Mapping Conservation Priorities and Tracking Biodiversity Management in Victoria

An R Shiny application for DEECA public servants comparing conservation opportunities and reviewing reported management activity.

The interface uses an atlas layout: a large map, a narrow control rail, an area-action heatmap and aligned opportunity bars. The progress view contains annual trends, priority-location shares, cumulative restoration charts and a selected-year target-gap dot plot.

## Run locally

Use R 4.4 or newer. Install these packages through your R environment before running the application: `shiny`, `leaflet`, `sf`, `ggplot2`, `jsonlite`, `htmltools`. Tests additionally require `testthat`. Application and preparation scripts do not install packages.

From this repository's root, run in R:

```r
source("scripts/prepare_data.R")  # First run: acquire public DEECA spatial data
shiny::runApp()
```

The preparation step requires internet access and writes a local `data/smp_cache.rds`. Later sessions use that cache and can run without external map tiles. The cache is excluded from Git; the repository includes the data acquisition code and attributed historical activity CSV. Do not run the preparation script during every app session.

## What works

- Select any of 16 management actions and explore 1,053 summary areas.
- Click a map polygon or choose a unit by keyboard.
- Compare the focused area with up to three pinned areas in the heatmap.
- Select a heatmap cell to change both the map action and selected area.
- Compare top-5% and top-15% extent in hectares or as a share of relevant area.
- Download all available action records for your comparison, including explicit missing rows and source metadata.
- Review four financial years of reported activity, with year selection, action filtering and data download.
- Read definitions, dates, caveats and official source links within the app.

## Tableau status

The companion `tableau/Biodiversity_2037_Progress.twbx` is packaged with its CSV and has been opened and tested in Tableau Desktop 2026.2. It contains four worksheets, the ProgressOverview dashboard, and working year/action parameters. Download it from the app or open it directly in Desktop.

Publication and live integration are deferred at the user's request. The Shiny app runs its local R progress charts. The API v3 bridge is implemented and unit-tested, but no live Tableau URL is configured and end-to-end embedding is not verified. This standalone delivery does not yet demonstrate the course's embedded Tableau requirement.

Later, publish ProgressOverview and set `tableau_view_url` in `config/app.json` (or `TABLEAU_VIEW_URL`) to the HTTPS Tableau Public /views/Workbook/ProgressOverview URL. Test anonymous loading and both directions of year/action changes before claiming integration complete.

## Data and interpretation

The spatial source is [DEECA's SMP4 summary-area service](https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer). Geometry is repaired and simplified to 100 metres for display; area values always come from source attributes. `CE_RANK` is the median relative cost-effectiveness rank. `AREA_20` follows NatureKit's published label, **Area in Top 15%**. Top-5% hectares are already included in top-15% hectares.

Historical activity was transcribed from the [Biodiversity 2037 progress report](https://www.environment.vic.gov.au/__data/assets/pdf_file/0025/722563/Bio2037-Progress-update-2020-2022-final.pdf), printed pages 5, 7, 11, 15 and 19. It covers 2018-19 through 2021-22 and includes multiple contributing organisations. Row-level source and page references are included in `data/activity.csv`.

Model ranks do not measure completed work. Reported hectares do not establish biodiversity recovery. Statewide historical figures cannot be filtered to individual summary areas. Missing action rows are shown as missing, including Unit 925. Revegetation has a method change around 2020-21. These limits are visible in the interface.

Attribution: State of Victoria, Department of Energy, Environment and Climate Action. Third-party data remain subject to their source terms; no new licence is asserted over them. This student project does not represent departmental advice.

## Check the project

```r
source("tests/run_tests.R")
```

The reference-value tests use the snapshot retrieved on 21 October 2026. Upstream updates may require reviewing those reference values rather than silently accepting changed figures. See `docs/VALIDATION.md` for the tested flows and remaining limits.

## Structure

`app.R` starts the app. `R/data.R` defines data access and calculations, `R/ui.R` defines the layout, and `R/server.R` coordinates interactions. `www/` contains the visual styles and browser event bridge. `scripts/prepare_data.R` acquires the public spatial source, and `tests/` checks data and server behaviour.

## Current development

The atlas also supports rank, top-15% share and hectare map measures, optional place labels, zoom to the selected area and pinned-area outlines. See `docs/VALIDATION.md` for current evidence and remaining gates, and `tableau/README.md` for the workbook contract. Run `Rscript scripts/prepare_tableau.R` and `node tests/progress_bridge.cjs` alongside the R tests. Planning documents supplied by the team are preserved under `docs/planning`; their planned statuses are historical context.

## Package for handoff

Run `python3 scripts/package_submission.py` after preparing the data. The local ZIP includes the frozen spatial cache, workbook, code, source notes and dependency versions. It excludes credentials, Git metadata, raw downloads and temporary Tableau files. Open the extracted folder and run `shiny::runApp()`; installed R packages are still required.
