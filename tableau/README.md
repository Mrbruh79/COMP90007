# Victoria Landscape Change

Open `Victoria_Landscape_Change.twbx` in Tableau Desktop. It contains its own `landcover.csv`, with 140,049 per-unit/epoch/class records. No PDF activity or policy-target data are used.

Dashboard: **LandscapeChange**. Worksheets:

- **T01_Composition:** 19-class composition through all seven epochs for the focused unit. Zero is excluded from the classified denominator. Use the legend and tooltips to inspect classes.
- **T02_ClassTrajectories:** selected-class share through all seven epochs, with one series per focused/comparison unit. Fixed 0-100% scale; no combined totals.
- **T03_EndpointComparison:** start and end shares for the selected class and separate units, using the same percentage scale. Invalid or reversed periods produce no endpoint marks; choose an earlier start epoch.

String parameters: `Focus area`, `Compare area 1`, `Compare area 2`, `Compare area 3`, `Land-cover class`, `Start epoch`, `End epoch`, `Data release`. Blank comparison slots are unused; duplicated unit choices do not duplicate rows. Focus uses source IDs such as `unit668`.

Rebuild the input with `Rscript scripts/prepare_tableau.R`, then `python3 scripts/build_tableau.py`. The generator uses a minimal native XML scaffold and only the new land-cover data. Any regenerated workbook must be opened and reviewed in Tableau Desktop; XML parsing alone is not a rendering test.

`data/manifest.json` identifies the release and CSV hash. Compare them with `data/landcover/manifest.json` before publishing. The Shiny bridge rejects a mismatched release and an old ProgressOverview URL. No publication has been authorised or carried out. Hosted API v3 integration remains a future validation step.
