# Validation — 22 October 2026

## Verified

- 31 R checks pass: spatial joins, missing records, selection and three-pin limit, metric denominators/scales, temporal grain, targets, release identity, URL validation and heatmap contrast.
- Node bridge checks pass: queued selections, duplicate suppression, mismatched release, missing parameters, network errors and disposed views. These use a mock workbook, not the hosted Tableau service.
- Shiny was launched and inspected in a browser. Switching to top-15% share updates the fixed percentage legend; selecting the Unit 668 / Horses heatmap cell updates the action and explicitly displays no action record. Progress charts and all 52 accessible evidence rows render. Selecting 2018–19 gives the expected 327,382 / 823,735 / 69,726 annual priority hectares.
- The spatial refresh retrieved 1,053 areas and 12,403 action records, with valid display geometry. Original geometry and request hashes remain locally under data/downloads.
- All 52 historical figures were compared with the official progress PDF tables on printed pages 5, 7, 11, 15 and 19. Priority plus other reconciles to statewide for all 16 applicable groups.
- The packaged Tableau workbook was opened in Desktop 2026.2 with its included CSV. All four charts rendered. Selecting 2018–19 changed target dots to 8.18%, 54.92%, 4.65%; trend views retained four years. Action parameter selection and restoration of defaults were exercised. The percentage axes include 0–100.

## Current delivery boundary

The user deferred publication and live integration. No public workbook was published; config/app.json remains blank. The actual workbook and Shiny application are delivered separately, with a workbook download in the app. Anonymous embedding, API parameter events against a live workbook and browser network-failure recovery remain unverified. Do not claim the course's embedded Tableau requirement is complete.

Tableau uses faceted trend lines, target values in the explanatory header/tooltips, and selected-year target-attainment dots. Compared with the original visualisation plan, annual reference lines and target-gap connectors are not drawn in Tableau; the R charts include annual reference lines. The phone layout is auto-generated and has not been accepted as mobile QA.

No real peer evaluation, report submission, video recording, or deployment is claimed. Historical docs/browser-results.json predates this work. Planning documents preserve supplied context and are not a current implementation checklist.
