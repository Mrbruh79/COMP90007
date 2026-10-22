# Tableau workbook and integration contract

Run `Rscript scripts/prepare_tableau.R` to rebuild `data/progress.csv` from the attributed 52-row source. The result contains 20 action/year rows: 12 annual priority-control rows and eight cumulative rows (priority revegetation, statewide permanent protection). Do not sum these across measures or sum cumulative observations across years.

The delivered `Biodiversity_2037_Progress.twbx` contains dashboard `ProgressOverview`. The original visualisation contract for its worksheets is:

- T01_AnnualControl: annual rows, year on columns, reported hectares on rows, separate action panels, annual target reference lines.
- T02_PriorityShare: annual rows, year on columns, priority_share_pct on a fixed 0–100 axis, action colour.
- T03_CumulativeRestoration: cumulative rows, separate action panels; label the 200,000 ha / 2037 targets and the revegetation reporting-method change.
- T04_TargetGap: annual rows filtered to Selected year, action on rows, attainment_pct on a common axis containing 100; target connector and percentage-point gap tooltip.

Required string parameters:

- `Selected year`: 2018-19, 2019-20, 2020-21, 2021-22; default 2021-22. Filter only T04; retain all years in trend views.
- `Selected action`: All actions, Pest herbivore control, Pest predator control, Weed control. Highlight the corresponding annual series.
- `Data release`: exact release from data/manifest.json. The Shiny bridge refuses to label a different release as synchronised.

Tooltips include reported hectares, target basis, coverage, financial year, source page and method note. Data-release checking is a compatibility check, not independent verification of workbook calculations.

When integration is resumed, publish the actual dashboard to Tableau Public after confirming source reuse terms. Set `tableau_view_url` in config/app.json, or TABLEAU_VIEW_URL in the environment, to its HTTPS /views/Workbook/ProgressOverview address. The bridge uses the same Tableau Public host's Embedding API v3 library, waits for FirstInteractive, serialises parameter changes and retains local evidence on failure.

## Delivered workbook — 22 October 2026

`Biodiversity_2037_Progress.twbx` now contains the workbook and its 20-row CSV. It was opened in Tableau Desktop 2026.2, rendered, and tested with the year/action controls. The unpackaged TWB is also included for inspection. Use the TWBX for portable opening.

Publication and Shiny integration are deferred at the user's request. The statements above describe the intended authoring contract; see docs/VALIDATION.md for verified implementation and visual differences.
