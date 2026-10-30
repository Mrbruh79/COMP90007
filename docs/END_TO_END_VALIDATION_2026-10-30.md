# End-to-end validation, 30 October 2026

Outcome: most exercised application paths passed, but the published Tableau change chart and the existing submission ZIP have material issues. This audit did not change application code or publish anything.

## Tested version and scope

Local base commit: ad8bc9d. The working tree also includes the requested place-label removal and rank-range formatting fix, with their tests. Those changes are not committed. Main test server: http://127.0.0.1:7390/. Separate browser session used for interactive checks. Published dashboard: https://public.tableau.com/views/Victoria_Landscape_Change/LandscapeChange.

## Findings

### High: published endpoint-change chart is empty for valid selections

Reproduction:

1. Open Explore landscape change.
2. Clear comparison pins and select Unit 602.
3. Select Water, earlier period 1985 to 1990, later period 2015 to 2019.
4. Wait for Selection linked to map.
5. Inspect Tableau chart 03, Change from 1985-1990 to 2015-2019.

The chart is blank. Its accessibility description states No data to visualise with current filters. Shiny, its exact-value table and the saved data contain valid values: earlier 1.294752%, later 0.8952561%, change -0.3994963 percentage points, and change -45.1504 hectares. The issue was also observed when comparing Units 602 and 608. The same chart renders for Unit 668. The hosted workbook's exact cause remains unverified; this report does not attribute it to a specific filter or calculation.

Screenshot: qa-e2e-empty-change-unit602.png. The screenshot shows the empty chart underneath its title and the other composition view above it.

### High: existing ZIP is stale and has no configured hosted Tableau URL

The existing dist/Victoria_Landscape_Atlas.zip differs from the current application in 11 runtime files: app.R, R/data.R, R/landcover.R, R/landscape_server.R, R/landscape_ui.R, R/server.R, R/ui.R, www/atlas.css, www/tableau.js, config/app.json and tableau/Victoria_Landscape_Change.twbx.

Its config/app.json contains an empty tableau_view_url. It also has 51 ZIP entries, including development documentation. Do not submit this archive as the current minimal runtime. A new ZIP should be built from the agreed runtime list plus concise run instructions after the hosted chart is corrected.

### Delivery: the latest UI fixes are local only

The removal of place-label controls/layers and the readable source-range display are uncommitted working-tree changes. They are present in the tested local app. This audit did not push them.

### Minor: very small nonzero values display as 0.0%

The selected-area panel rounds to one decimal place. Unit 668 Built environment therefore displays 0.0% at both endpoints even though some source values are positive. Tableau's selected-cover mode enlarges the small values and downloads retain precision. This is rounding, not missing data, but a less-than-0.1% label would communicate small nonzero values more clearly.

### Maintenance: the optional browser harness has stale assumptions

The checked-in tests/browser_check.cjs expects the older hyphenated period wording and a visible #download_tableau button in the online configuration. The current interface uses readable 'to' labels and offers that workbook button in the unconfigured fallback. The current audit used actual browser interactions rather than claiming this older harness passed.

## Successful checks

- R suite: 53 checks passed, including geometry, source joins, missing records, rank-range formatting, removed place-label code, selection, pin limits, source denominators and change calculations.
- Cache compatibility suite: exact cache, retrieval-metadata change, row reordering, changed identifiers, changed attributes, shifted geometry and changed original analytical source cases passed.
- Tableau structure/package check: all 140,049 rows reconcile with the runtime summary; seven presentation groups close correctly; coverage aggregation, baseline reference and three-sheet structure passed.
- JavaScript bridge tests: release mismatch, missing controls, queued state, clearing comparison slots, deduplication, closed view and network failure passed.
- Interactive checklist: 59 recorded checks, 58 passed and one failed (the published Unit 602 endpoint-change view). Counts describe the recorded checklist, not all possible combinations.
- All 16 management actions were clicked through the heatmap for Unit 668. Fifteen source records and the absent Horse-control record displayed correctly. Missing action headings are styled uppercase, which was accounted for when checking the result.
- All 19 cover choices were selected, and both displayed endpoint percentages matched saved values to the interface's one decimal place.
- All six earlier-period choices were exercised and offered only later periods. All six later-period choices were exercised.
- Both map measures, both change-unit radio choices, priority and landscape polygon clicks, selected-area zoom, map zoom buttons, pin addition/removal/limit, clear, reset and shared navigation/selection were exercised.
- The evidence panels, local history chart, exact-value tables, section anchors, Edit selection link and sources page opened successfully.
- Hosted Tableau received the Water and area/period choices. Its selected-cover scale settled at 0 to 3%, the detailed legend exposed all 19 cover types, and grouped, detailed, selected-cover, cover-share and baseline-change modes responded. Share dialog and fullscreen entry/exit worked.
- Priority CSV downloaded with 48 rows and reconciled by area/action against CE_RANK, AREA_TOT, AREA_5 and AREA_20, including missing records.
- Landscape CSV downloaded with 133 rows (one area, all seven periods, all 19 classes) and reconciled against share, hectares, classified coverage, unclassified and missing values.
- Workbook download from the app fallback was byte-identical to the validated local TWBX, with valid ZIP integrity.
- The agreed 18 runtime files were copied into an isolated temporary directory. The Shiny application loaded without relying on repository scripts/docs/tests. A separate instance with the hosted URL disabled rendered the local fallback and served its workbook download.
- Independent terra exact extraction for Units 602 and 608 in the first and last raster periods agreed with prepared class hectares. Maximum differences were 0.7745, 0.5821, 1.5307 and 0.6701 square metres respectively, below the 20-square-metre tolerance.
- No browser JavaScript errors were recorded in the main interactive session. No visible Shiny output errors were present at the final check. At the observed 1280px desktop viewport, document width was 1265px with no document overflow.

## Link validation

Opened the source-page links and an actual selected-area report link in the browser. NatureKit Layers & Datasets, the DataVic land-cover catalogue and the Unit 602 source report rendered. The separate Tableau link opened the expected published dashboard.

HTTP checks also succeeded for the DataVic catalogue, published Tableau URL and API script, Leaflet, Units 668/900 report examples, raster ZIP availability (HEAD only), source XML metadata, CC BY 4.0 licence and both ArcGIS layer/table metadata endpoints. NatureKit returned 403 to the automated request but opened correctly in the browser, so it is not classified as a broken link. Report links are generated per area; not all 1,053 report URLs were requested.

## Limits and unresolved verification

The Tableau toolbar's own Workbook export dialog opened and accepted Download, but no completed file was observed in the in-app browser within 20 seconds. This remains unverified, rather than being asserted broken. The app's fallback workbook download did pass.

The independent minimal runtime test used installed packages on this laptop. It does not prove dependency installation on a clean operating system. The fallback test disabled the hosted URL; it did not disconnect the laptop's network. Network failures are covered by the bridge unit tests. No phone/device-matrix or every-combination usability claim is made. The visible published workbook exposes composition/trend presentation controls; reverse area/class parameter events are covered by bridge/server code and earlier documentation, not a new visible parameter-control test in this audit.

No source rasters were changed or reprocessed. No comments in application code were added or changed. No Git commit, push, Tableau publication or submission archive rebuild was performed during this audit.
