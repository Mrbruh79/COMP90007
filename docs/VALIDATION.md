# Landscape redesign validation, 29 October 2026

## Verified implementation

- Downloaded and inspected the 426,746,271-byte official land-cover archive. Seven classified TIFFs, matching projected grids and source class/epoch metadata were checked. Source NoData is distinct from unclassified code 0.
- Full-resolution original-boundary overlay completed for all 1,053 units, seven epochs and 19 classes, producing 140,049 unique records. Processing took about 187 seconds on this machine after download. The source archive, raster fingerprints, geometry repair, overlap audit and denominator definitions are recorded in data/landcover/manifest.json.
- 50 R checks passed, including retained SMP behaviour, area/share closure, zero versus missing, reversed epochs, source overlaps, a fractional boundary-cell/NoData fixture and independent terra extraction on real Unit 668. The independent result agreed within 0.002 grid ha (20 square metres) per class.
- JavaScript bridge tests passed for queued latest-state updates, duplicate suppression, clearing blank comparison slots, release mismatch, absent controls, disposal and simulated network failure. These use a mock workbook.
- Tableau structure/data checks reconcile all 140,049 input rows to the runtime summary, verify parameters, an automatic focused-chart scale and fixed comparison percentage scales, reject old PDF identities and inspect the packaged CSV.
- The new packaged workbook was opened in Tableau Desktop 2026.2. Composition, selected-class trajectories and endpoint comparisons rendered. Switching the class parameter from treed native vegetation to Water updated trajectories and endpoint dots, retaining all seven trend epochs. The final layout adds visible comparison-slot controls and a full-height categorical legend. Native saving successfully produced a portable package with its CSV.
- Shiny was inspected in the in-app browser and Chrome. Both maps render; the landscape map's first-render race was corrected. Class-share maps use 0-100%; net-change maps use a labelled symmetric range for the chosen class/period, with visible unit outlines. Area search selected Unit 925, then the priority page showed its explicit missing-action message while landscape values remained available. Water selection, the net-change map legend, 2010-2015 to 2015-2019 interval, and shared pinning were exercised.
- The real browser CSV download contained 399 records for three separate units, all seven epochs and 19 classes, including the exact release and provenance.

## Priority-page simplification, 29 October 2026

The priority map now displays only the supplied cost-effectiveness rank on a fixed 0-100 scale. Top-5%/15% map measures, detail bars, comparison bars and their tooltip text were removed. The selected-area panel retains unit, action, rank, relevant hectares and existing source evidence. Action-grid comparison, pins and historical land-cover views remain available. Both area lookups search all 1,053 units, opening results after typing rather than showing an initial 100-option list.

The 50 R checks include the revised map/selection behaviour and absence of threshold controls and chart text. Live browser checks confirmed the removed controls were absent, all 32 initial action-grid cells remained, and switching Unit 668 from foxes to cats changed the displayed rank from 88 to 97 and relevant hectares from 7,329 to 3,446. The landscape view retained its 45.4% to 46.1% treed-native-vegetation values. An actual comparison CSV download retained AREA_5=2632, AREA_20=3855, AREA_TOT=7329 and CE_RANK=88 for the Unit 668 fox-control row, plus the derived shares. The JavaScript bridge checks also passed.

## Clearer action-ranking labels, 29 October 2026

The first view now introduces the investment question and explains that higher ranks indicate stronger modelled benefits for native plants and animals relative to management cost. Action options use explicit names such as Fox control and Rabbit control. The map title, caption and selected-area explanation name the chosen action; the legend labels the low and high ends of its fixed 0-100 scale. The rank is displayed with a scale label, and the source evidence explains its median/relative meaning. Area lookup guidance identifies units as mapped areas, and the action grid describes rows and columns.

Live browser checks confirmed that choosing Rabbit control changed the map title and caption, selected-action text and rank explanation together, and displayed Unit 668 rank 93 with 4,423 relevant hectares. No threshold controls were reintroduced. The original snapshot and land-cover/Tableau data were not modified.

## Clearer landscape-change labels, 29 October 2026

The landscape view now introduces historical land cover in plain language. Numbered controls identify area, cover type and earlier/later periods. A live map title names the selected type and period(s), and separate map choices distinguish later-period cover from change. Legend ticks include percentage signs for cover and increase/decrease labels for change. The selected-area panel labels both endpoints, percentage-point change and hectare change. Coverage and separate management-model context remain available in expandable details.

Comparison tables spell out earlier/later cover, percentage points and hectares. A 30% to 35% example explains percentage points. The all-types chart explains left/right direction and colour; the history guide explains each line and that all seven periods remain visible. Workbook guidance describes composition bars, trends and endpoint dots and notes that downloaded workbooks use their own controls.

All 50 R checks, JavaScript bridge checks and Tableau structure/data checks passed. Live browser checks exercised Water, change mode and 2010-2015 to 2015-2019: titles and captions updated, legend and caption settled to the same -68 to +68 range, Unit 668 showed 2.3% to 2.1%, -0.2 percentage points and -15.7 hectares, with no output errors. Restoring treed native vegetation and the full period pair retained 45.4% to 46.1%, 0.7 percentage points and 53.1 hectares. Underlying summaries, denominators and the native workbook were unchanged.

The default landscape map measure is Change between periods, including its initial-render fallback. The all-cover-types change chart appears before the selected-cover-type area comparison.

The Tableau section is the final landscape section, after the history, exact-value table and calculation notes. History and exact-value headings use bold type with separating rules; live browser checks verified both computed font weights as 700. The trend-axis label is shortened to Cover share (%) to fit its plot.

## Focused-area detail view, 29 October 2026

Added a Focused plot view parameter with All cover types (default) and Selected cover type. The selected view filters only the focused chart to the existing Land-cover class parameter. Its automatic bar axis includes zero and fits small values; the comparison charts retain their fixed 0-100 scales. The overview restores all 19 classes with 100% stacks. The existing percentage and hectare tooltip fields are retained.

Native Tableau Desktop checks confirmed Unit 668 Built environment is visible at approximately 0.000814%, Mangrove vegetation remains zero across all seven periods, and returning to All cover types restores the complete composition and legend. Native saving preserved the default overview and Treed native vegetation selection. The main package contains that native-saved workbook XML and the unchanged CSV; the development package and original selections are backed up outside the delivery. Structure checks reconcile all 140,049 records and verify the view filter, parameter choices, small-category records and comparison scales.

## Clear Tableau labels and reading guides, 29 October 2026

Replaced terse focused/class/epoch wording with Main area, Cover type, Earlier period, Later period and optional Additional areas. Three numbered question titles explain the composition bars, historical lines and earlier/later dots. Reading guides beside each view explain its marks, colours, direction, scales and affected controls. The introduction defines the classified-area percentage with a 40-of-100-hectares example and explains source area IDs. Tooltip/axis/legend field captions use readable names and units. Source, denominator, overlap and interpretation notes remain visible at the bottom.

The dashboard now stacks the three charts vertically at 1200 by 2000 pixels, giving the cover-type legend enough height for all 19 names and enough space for the source notes. The embedding height and both directions of the app's parameter-name mapping were updated to match the renamed controls. Numerical inputs, class filters and percentage scales were preserved. Native Tableau review confirmed all three question titles and reading guides, all 19 full legend names, and the complete source/denominator notes. Choosing Water and Selected cover type updated the focused bars and comparison lines. The final package was saved natively with the default All cover types / Treed native vegetation selections. All 50 R checks, bridge checks and the 140,049-row Tableau reconciliation passed.

## Delivery boundary

The user authorised local development and narrowed the task to code and Tableau. No public deployment, data upload, Tableau publication, report or video is included. config/app.json remains blank. The API v3 bridge is implemented and mock-tested, but anonymous hosted rendering and real bidirectional parameter events remain unverified. The assignment's requirement to incorporate Tableau in the running Shiny page therefore remains a publication-dependent step.

The workbook has a fixed desktop layout; phone-layout QA is not claimed or required by the supplied specification. Source discovery, numerical analysis and UI checks do not establish real DEECA usability or ecological validity. The classified maps are historical evidence, not current habitat condition or management outcomes.

A Tableau Desktop crash occurred while closing/reopening a development copy whose file had been regenerated; the app recovered, and the final package subsequently opened, rendered and saved natively. No crash report was transmitted. Do not overwrite an open workbook when regenerating it.

Historical planning and the old progress prototype are preserved separately. They are not evidence of the revised implementation or current requirements. tests/browser_check.cjs is an optional standalone browser harness; the current live interaction evidence above was collected through the connected browser tools.

## Tableau visual redesign, 29 October 2026

Replaced the tall ungrouped layout with a 1400 × 1660 dashboard, green header, area sidebar, white chart sections and shorter reading guides. Positioned endpoint period controls beside chart 3 and widened the 19-class legend. Opened and saved the final packaged workbook in Tableau Desktop; verified the upper layout, full legend, lower comparison and source notes. Screenshot: `docs/qa-tableau-redesign.png`. Workbook checks reconcile all 140,049 records and preserve the focus switch and comparison scales. The JavaScript bridge checks pass; hosted embedding remains deferred.
