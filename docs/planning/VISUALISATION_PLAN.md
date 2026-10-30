# Visualisation and interaction plan

## Information hierarchy

Confirmed title (22 October 2026): **Mapping Conservation Priorities and Tracking Biodiversity Management in Victoria**.

Audience: DEECA public servants preparing conservation briefs. Primary device: desktop, target viewport 1440 x 900 with a usable 1280 x 800 layout. Use a restrained green and charcoal palette, white plot backgrounds, consistent type and persistent source/date labels. Government logos are unnecessary; identify the client and the purpose of the atlas.

Two navigation choices answer different questions:

- **Explore priorities**: Where should we investigate a particular conservation action?
- **Review progress**: How much management activity was reported, and how does it compare with targets?

A methods drawer remains available from both. It explains ranks, relevant area, model version, reporting coverage and limitations. A comparison drawer retains up to three selected summary areas. No fabricated overall score or unsupported “best investment” badge.

## Explore priorities: Shiny owns the interaction

Layout: 220 px control column, a large map and a full-width area-action heatmap beneath it so all 16 action columns remain readable. The heatmap shows the focused area and up to three pinned areas, without duplicate rows. A comparison drawer contains aligned opportunity-extent bars for the pinned areas.

| View | Data and encoding | Interaction | Decision supported |
|---|---|---|---|
| Statewide action map | Validated summary polygons joined by `microID`; fill `CE_RANK` for one action; fixed 0-100 sequential scale | Select action, click area, zoom, search unit ID, reset extent | Locate relative opportunity without changing scale across selections |
| Area-action heatmap | Rows are focused/pinned summary areas; columns are actions; cell colour encodes `CE_RANK` on a fixed 0-100 sequential scale | Select a cell to focus its area and action on the map; pin areas; inspect rank and relevant hectares | Identify differences in action priorities across areas |
| Extent profile | Adjacent bars for `AREA_5 / AREA_TOT` and `AREA_20 / AREA_TOT`; latter labelled Top 15% | Toggle percentage versus hectares; show denominator in tooltip | Distinguish concentrated opportunity from extensive opportunity |
| Comparison drawer | Up to three aligned opportunity-extent bar profiles with the same scales and action order | Add/remove selection, change action, export comparison CSV | Prepare a defensible comparison of places |
| Evidence detail | Source snapshot, relevant hectares, rank range, absent-action explanation, official report link | Open from any selected area | Understand what supports the visual claim |

Keep all action columns visible when the map action changes, and outline the selected column. Use stable action ordering and wrapped labels; offer deliberate sorting by the focused area only. Missing cells are grey with a visible missing-value marker, while rank zero uses the lowest numeric colour. Provide cell values through keyboard focus and an accessible table, so colour is not the only way to compare ranks.

Ranks are relative model outputs, not probabilities or absolute benefit. Do not label a rank of 90 as a 90% improvement. `CE_RANGE` describes source variation; it is not a statistical confidence interval. Its exact percentile interpretation is unverified, so show the raw range in details rather than draw a confidence band.

The Top 5% and Top 15% areas are nested. Never stack them as independent contributions. Do not add hectares across actions, where treatment areas may overlap. Keep missing rows grey and mark them “No action record”; retain zero as a valid numeric value. `unit925` is a required empty-state test.

Use an unobtrusive basemap with attribution, thin area boundaries and a strong selection outline. For analysis, use an appropriate projected CRS; use EPSG:4326 GeoJSON for display. No parcel-scale claims. Keep the legend fixed, label the model version, and provide a keyboard-accessible unit selector as an alternative to clicking the map. A regional grouping can be added only after a suitable boundary layer and crosswalk are verified; unit numbers should not be presented as place names.

## Review progress: the required Tableau component

Author **Biodiversity_2037_Progress.twbx** in Tableau using `biodiversity2037_activity_2018_2022.csv`. Publish the resulting **ProgressOverview** dashboard and embed that actual view in the Shiny progress page. A screenshot, external link or Markdown XML listing does not satisfy the embedded-visualisation requirement.

| Worksheet | Fields / construction | Reading task |
|---|---|---|
| T01_AnnualControl | Filter `basis = annual`, `coverage = priority`; columns `period_end_year`, rows `area_ha`; small multiples by action; annual target reference line | Compare four years of priority-location control against annual targets |
| T02_PriorityShare | For each annual action/year, calculate priority hectares divided by statewide hectares; 0-100% line or dot plot | See how the distribution of reported effort changes |
| T03_CumulativeRestoration | Two separate panels: priority revegetation and statewide permanent protection; cumulative hectares; 2037 target clearly labelled | Assess cumulative delivery without confusing it with annual control |
| T04_TargetGap | One dot per annual control action; x-axis is target attainment (%), y-axis is action; a 100% reference line and a thin connector show the gap to target | Compare the selected financial year's target attainment and percentage-point shortfall |

Do not sum priority, other and statewide rows. The statewide row already includes the first two. The denominator for T02 must remain the matching statewide action/year when a coverage filter changes. Use explicit conditional aggregation or a validated table calculation, then check against independent CSV calculations. For T01/T04, target attainment is `priority_area_ha / annual_priority_target_ha`. Cumulative target attainment uses its own scope and deadline. Keep “2037 target” distinct from an annual target.

The dashboard defaults to all four years. Selecting a year highlights it while preserving context; it updates the target-gap dot plot. Selecting an action highlights the corresponding time series. Tooltips state hectares, coverage, period, target basis and source page. Mark the revegetation method change between 2019-20 and 2020-21. Do not connect cumulative series to annual charts or extrapolate straight lines to 2037.

For T04_TargetGap, filter to annual measures and priority coverage for one financial year. Position each dot at `100 * area_ha / target_ha`. Label the gap as `100 - attainment` percentage points; show hectares and the hectare shortfall in the tooltip. Distinguish percentage points from percentage change. If attainment exceeds 100%, extend the axis and label the amount above target rather than clipping the dot or showing a negative shortfall. Keep a common axis across actions and years. Default the selected-year view to 2021-22 while keeping all four years visible in the trend charts.

## Cohesion and integration

Shiny handles navigation, map selections, comparison state and evidence exports. Tableau handles temporal performance and target comparisons. The progress panel is explicitly statewide: a selected map polygon must not appear to filter these totals.

The baseline integration should follow the course's page 8.5 method after the team retrieves that page. Its exact instructions were not present in the inspected local material. The current [Tableau Embedding API](https://help.tableau.com/current/api/embedding_api/en-us/docs/embedding_api_get.html) supports Tableau Public and version-matched libraries. A later enhancement can pass an action selection into the embed after it becomes interactive. Treat this as an extension to the course method, and test it before making it essential.

Use the view URL supplied by Tableau's share/embed controls. Package the workbook with data and test it in the installed Tableau version. Do not hand-author a large TWB XML document and assume it is valid. Test the live embed in Shiny anonymously, including resize, reset, filter changes, loading and failure states. A local chart fallback can preserve information during an outage, but does not replace the required Tableau integration.

## Proposed technical contribution

The substantive challenge is coordinated spatial selection, persistent comparison, coverage-aware filtering and an embedded temporal dashboard, all using a reproducible data snapshot. A useful original interaction is switching between relative rank and opportunity extent for the same selection. This exposes trade-offs without inventing a composite score.

Add brush-to-shortlist selection only after click and keyboard selection work reliably. If tested users cannot explain what a control changes, remove or rename it. Technical complexity earns its place through the task it supports.

## Authentic use cases and findings to test

1. **Programme briefing:** compare herbivore and predator control. In 2021-22, priority-location hectares imply approximately 40.8% and 61.5% of their respective annual targets. The larger number of hectares does not necessarily mean greater target attainment.
2. **Site screening:** compare two areas with similar median rank but different top-ranked shares. Select the actual examples from the frozen service snapshot; do not invent a pair in the final report.
3. **Interpretation check:** a user sees the revegetation increase and must identify the method-change note before describing it as management improvement.

The first and third examples use the [published progress tables](https://www.environment.vic.gov.au/__data/assets/pdf_file/0025/722563/Bio2037-Progress-update-2020-2022-final.pdf). They concern reported management, not causal ecological outcomes.

## Accessibility and evaluation

Use readable labels, visible focus, meaningful controls, tooltips available on focus, and text equivalents for map selections. Avoid red/green judgments. Test colour contrast and common colour-vision deficiencies. Support reset and removal without losing the full session.

Acceptance tasks: find a high-ranked action, compare two areas, explain a missing action, calculate a target comparison, identify the report's time limit, and export a comparison with source metadata. Target: each core task completed without help by at least four of five peer testers; record failures and revise. This is a proposed evaluation target, not a result.
