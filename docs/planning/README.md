# Mapping Conservation Priorities and Tracking Biodiversity Management in Victoria

Feasibility and design package. Data snapshot: 21 October 2026. Plan updated: 22 October 2026. Prepared against `../SPEC.txt` and its four-part rubric. The existing housing implementation was excluded from this assessment.

**Verdict: proceed with a bounded desktop decision-support interface for DEECA public servants.** The spatial and tabular core has been acquired. Public release remains conditional on confirming dataset reuse terms. The plan supports conservation priority screening and reported management performance; it cannot establish ecological recovery or local investment gaps.

## Read first

1. [Feasibility assessment](FEASIBILITY.md): scope, evidence, exclusions, risks and decision gates.
2. [Visualisation and Tableau plan](VISUALISATION_PLAN.md): screens, chart fields, interactions and integration.
3. [Spec and rubric matrix](SPEC_RUBRIC_MATRIX.md): requirements, planned evidence and acceptance checks.
4. [Data guide](DATA_GUIDE.md): files, definitions, source issues and audit results.
5. [Build and submission plan](BUILD_PLAN.md): responsibilities, dates, testing and report structure.
6. [Initial findings and figure](INITIAL_FINDINGS.md): actual examples supporting the design.

## Data gathered

- Complete public service snapshot: 1,053 SMP4 summary-area polygons and 12,403 action records covering 16 actions. All action records join to a boundary; one boundary has no action records.
- Four financial years of published management activity, 2018-19 to 2021-22: 52 rows across five measures and their available location categories. These are transcribed report tables, not a live activity database.
- One full SMP4 area report, with six extracted tables, including 2,058 species rows and indicative costs. This is a feasibility sample, kept separate from the statewide service because values differ.
- Metadata for seven land-cover epochs and further SMP layers. Raster values have not been downloaded or analysed. Land cover is optional, not a dependency of the proposed core.

`data/processed/tableau_area_actions.csv` and `data/processed/biodiversity2037_activity_2018_2022.csv` are the proposed Tableau inputs. The GeoJSON is the Shiny map input. Raw query pages, metadata, download URLs and hashes are retained in `evidence` and `data/raw`.

The package contains a plan and an audited data snapshot. It does not claim a completed Shiny application, authored Tableau workbook, tested embed, user evaluation or submission-ready PDF. Those are explicit implementation gates.

## Confirmed chart changes, 22 October 2026

The Shiny action comparison dot plot is replaced by an area-action heatmap. The Tableau selected-year bullet charts are replaced by a target-gap dot plot. The map, opportunity-extent bars, area comparison, annual trends, priority-location share and cumulative restoration charts remain in scope.
