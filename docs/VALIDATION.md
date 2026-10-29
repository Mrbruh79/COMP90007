# Landscape redesign validation, 29 October 2026

## Verified implementation

- Downloaded and inspected the 426,746,271-byte official land-cover archive. Seven classified TIFFs, matching projected grids and source class/epoch metadata were checked. Source NoData is distinct from unclassified code 0.
- Full-resolution original-boundary overlay completed for all 1,053 units, seven epochs and 19 classes, producing 140,049 unique records. Processing took about 187 seconds on this machine after download. The source archive, raster fingerprints, geometry repair, overlap audit and denominator definitions are recorded in data/landcover/manifest.json.
- 48 R checks passed, including retained SMP behaviour, area/share closure, zero versus missing, reversed epochs, source overlaps, a fractional boundary-cell/NoData fixture and independent terra extraction on real Unit 668. The independent result agreed within 0.002 grid ha (20 square metres) per class.
- JavaScript bridge tests passed for queued latest-state updates, duplicate suppression, clearing blank comparison slots, release mismatch, absent controls, disposal and simulated network failure. These use a mock workbook.
- Tableau structure/data checks reconcile all 140,049 input rows to the runtime summary, verify parameters and fixed percentage scales, reject old PDF identities and inspect the packaged CSV.
- The new packaged workbook was opened in Tableau Desktop 2026.2. Composition, selected-class trajectories and endpoint comparisons rendered. Switching the class parameter from treed native vegetation to Water updated trajectories and endpoint dots, retaining all seven trend epochs. The final layout adds visible comparison-slot controls and a full-height categorical legend. Native saving successfully produced a portable package with its CSV.
- Shiny was inspected in the in-app browser and Chrome. Both maps render; the landscape map's first-render race was corrected. Class-share maps use 0-100%; net-change maps use a labelled symmetric range for the chosen class/period, with visible unit outlines. Area search selected Unit 925, then the priority page showed its explicit missing-action message while landscape values remained available. Water selection, the net-change map legend, 2010-2015 to 2015-2019 interval, and shared pinning were exercised.
- The real browser CSV download contained 399 records for three separate units, all seven epochs and 19 classes, including the exact release and provenance.

## Delivery boundary

The user authorised local development and narrowed the task to code and Tableau. No public deployment, data upload, Tableau publication, report or video is included. config/app.json remains blank. The API v3 bridge is implemented and mock-tested, but anonymous hosted rendering and real bidirectional parameter events remain unverified. The assignment's requirement to incorporate Tableau in the running Shiny page therefore remains a publication-dependent step.

The workbook has a fixed desktop layout; phone-layout QA is not claimed or required by the supplied specification. Source discovery, numerical analysis and UI checks do not establish real DEECA usability or ecological validity. The classified maps are historical evidence, not current habitat condition or management outcomes.

A Tableau Desktop crash occurred while closing/reopening a development copy whose file had been regenerated; the app recovered, and the final package subsequently opened, rendered and saved natively. No crash report was transmitted. Do not overwrite an open workbook when regenerating it.

Historical planning and the old progress prototype are preserved separately. They are not evidence of the revised implementation or current requirements. tests/browser_check.cjs is an optional standalone browser harness; the current live interaction evidence above was collected through the connected browser tools.
