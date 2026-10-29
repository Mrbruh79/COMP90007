# Mapping Conservation Priorities and Land-Cover Change in Victoria

An environmental atlas for DEECA public servants investigating modelled conservation opportunities alongside historical landscape classifications. Desktop is the primary device class.

## Run the delivered app

Install dependencies separately in your R environment: `shiny`, `leaflet`, `sf`, `ggplot2`, `jsonlite`, `htmltools`. Use R 4.4 or newer. Submitted scripts do not install packages.

From this project's root:

```r
shiny::runApp()
```

The local handoff ZIP includes `data/smp_cache.rds`, original boundaries, and prepared land-cover summaries. It needs no raster processing or online map tiles to run. Place labels are optional and require an internet connection. When cloning this repository, prepare the spatial cache first:

```sh
Rscript scripts/prepare_data.R
```

After a fresh clone, run the full land-cover and Tableau rebuild commands below before launching. The prepared land-cover release is tied to the exact spatial cache fingerprint. If you refresh the spatial source, rebuild the land-cover summaries and Tableau input together rather than mixing releases.

## Explore

- **Explore priorities:** 16 actions, relative ranks and opportunity extent across 1,053 summary areas. Select by map or unit search. Pin up to three areas, compare the action heatmap and download records including explicit missing actions.
- **Explore landscape change:** select one of 19 classes and two ordered historical epochs. Map end-epoch class share or net share change, inspect all-class changes, compare focused/pinned areas and download all seven epochs with coverage and provenance.
- **Tableau:** open `tableau/Victoria_Landscape_Change.twbx`. Its `LandscapeChange` dashboard has focused-area composition, class trajectories and start/end comparisons. The portable package contains its CSV. This is a real Tableau workbook, with unit/class/epoch parameters.
- **Sources & methods:** dates, denominator definitions, source links and interpretation limits.

Selections and pins are shared across the two Shiny workspaces. Land-cover statistics are per summary area, not per LGA. Units overlap; their values are never summed into combined-area or statewide totals.

## Sources and processing

SMP4 boundaries and action attributes come from [DEECA's summary-area service](https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer). The frozen local snapshot was retrieved **22 October 2026**, and the model is associated with July 2023. It has 1,053 boundaries and 12,403 action records. Source `AREA_20` follows NatureKit's **top 15%** label; the top 5% is included within it. Missing action records are not zeros. Unit 925 has no SMP action records.

[Victorian Land Cover Time Series](https://discover.data.vic.gov.au/dataset/victorian-land-cover-time-series) supplies seven classified 25 m GeoTIFFs. Downloaded filenames and raster attribute tables use **1985-1990** for the first epoch, although the catalogue describes it as 1987-1990. The app follows the downloaded files. These are multi-year epochs ending in 2019, not annual or current observations.

`data/landcover/summary.csv.gz` contains 140,049 records at microID x epoch x class grain. Original boundary vertices are transformed to EPSG:3111 and repaired without simplification. Exact cell-coverage fractions determine class proportions. Grid hectares are projected polygon hectares allocated by those proportions. Small numerical residuals are checked before normalisation. The 100 m simplified geometry is used for display only.

Class share divides class area by classified area, codes 1-19, within each unit/epoch. Code 0 is unclassified; TIFF NoData (127) is retained separately. NoData is not changed into an absent class. A complete boundary audit and raster fingerprints are in `data/landcover/manifest.json`.

For a reproducible full-resolution rebuild, also install `terra`, `exactextractr` and `foreign`, then run:

```sh
Rscript scripts/prepare_landcover.R --refresh
Rscript scripts/prepare_tableau.R
python3 scripts/build_tableau.py
```

The preparation script downloads the 426,746,271-byte official ZIP if absent. Seven epochs processed in about three minutes on the development machine; timing varies by hardware. Raw raster downloads remain under `data/downloads/` and are not needed at runtime. Reopen a regenerated workbook in Tableau Desktop to validate it after changing the schema or calculations.

## Tableau integration boundary

Local development is complete independently of publication. The user has not authorised public deployment, data uploads or Tableau publication for this redesign. `config/app.json` therefore has a blank `tableau_view_url`.

The API v3 bridge is prepared for `LandscapeChange`, synchronising focus, three comparison slots, class, start/end epochs and an exact data-release check. Unit tests use a mock workbook. After publication is authorised, configure the HTTPS Tableau Public `/views/Workbook/LandscapeChange` URL and verify anonymous loading, sizing and both directions of parameter changes against the actual hosted workbook. That live embedding requirement is still outstanding; a local workbook download is not an embedded visualisation.

## Validate and package

```sh
Rscript tests/run_tests.R
node tests/landscape_bridge.cjs
python3 tests/check_tableau.py
python3 scripts/package_submission.py
```

See `docs/VALIDATION.md` for current evidence. The package builder produces `dist/Victoria_Landscape_Atlas.zip`, including code, prepared data, original geometry and the workbook. R packages must already be installed. It excludes raw rasters, historical prototypes, credentials and Git metadata.

The old PDF activity data and progress workbook are preserved under `archive/progress/` for history. They are not read by the active app or revised Tableau views. The supplied assignment specification is in `docs/redesign/ASSIGNMENT_SPEC.txt`. This task covers code and Tableau; report/video/peer-evaluation work is outside the requested scope.

Attribution: State of Victoria, Department of Energy, Environment and Climate Action. Land-cover data are provided under CC BY 4.0. SMP4 remains subject to its own source terms. This student project does not represent departmental advice. Modelled opportunities do not prove completed work or recovery; land-cover classes do not measure habitat quality, species abundance or management effectiveness. Net class totals do not establish pixel transitions or causes of change.
