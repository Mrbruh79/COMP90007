# Validation status — 22 October 2026

The original main commit was cf841d537fcd6be4a71faeba617ecb6ac94a9c2a.

Verified locally: R 4.6.1 launches the original app; all original 19 checks pass. The updated implementation passes 31 R checks, including map metric denominators, missing data, common scales, temporal grain, scope-matched targets, release identity, URL validation and heatmap text contrast. Node tests pass for queued selections, duplicate-state suppression, mismatched releases, missing parameters, network errors and disposed views.

The spatial refresh retrieved 1,053 areas and 12,403 action records. Raw geometry and request hashes are retained locally under data/downloads. All 52 activity rows have unique action/year/coverage keys; priority plus other reconciles to statewide totals. This arithmetic check alone does not independently verify transcription against the PDF.

Browser evidence from the original app confirmed heatmap selection updating both action and area, and rendering of progress charts. The updated browser flow still needs verification. The pre-existing docs/browser-results.json is historical evidence, not a result from this revision.

Outstanding: author and open the Tableau workbook, publish ProgressOverview, configure its view URL, test anonymous embedding and bidirectional parameters, test network failure in-browser, extract and run the final submission package, and conduct real peer usability sessions. No completed workbook or live integration is claimed.

The user supplied course page 8.5 references on 22 October: Tableau Public publication, Tableau actions, Embedding API v3 and its tutorial. The integration uses API v3 and a Shiny custom-message bridge. Statewide progress is deliberately independent of polygon selection.
