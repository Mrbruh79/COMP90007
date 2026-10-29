# Feasibility assessment

## Decision and purpose

Proceed with **Mapping Conservation Priorities and Tracking Biodiversity Management in Victoria**, designed for DEECA public servants preparing conservation programme briefs on a desktop. This is Option 2 in the supplied specification: a Victorian Government department and public servants assessing a State Government topic. It does not require the different-audience approval described for Option 3.

The central task is: **compare places and management actions, explain why they merit further investigation, and place that decision alongside reported progress towards Biodiversity 2037 targets.** The product should end with a short, traceable comparison that an officer could discuss with regional specialists. It must not issue site prescriptions or promise a funding optimum.

Three proposed user tasks:

1. Locate summary areas where a chosen action has a high modelled cost-effectiveness rank, then compare up to three areas.
2. Determine whether an area's high rank represents extensive opportunity or only a small proportion of its relevant area.
3. Compare reported priority-location activity with statewide activity and the correct policy target over four years.

These are design hypotheses, not findings from interviews. Test them with peers playing the officer role, and with a relevant practitioner if available. Document the distinction in the report.

## Evidence available now

| Component | Evidence gathered | Feasibility judgment |
|---|---|---|
| Spatial priorities | 1,053 public SMP4 polygons and 12,403 action records, downloaded and joined | Strong core; compact enough for a local snapshot |
| Actions | 16 individual actions; relative ranks and relevant/top-ranked hectares | Strong comparisons; no dollar allocation model in this table |
| Temporal performance | Four financial years, five published measures, 52 rows | Suitable for a genuine multi-year Tableau component; explicitly historical |
| Species and costs | One complete official area report with extractable tables | Proven access for a case study; insufficient basis for statewide species/cost comparisons |
| Historical land cover | Seven official map-service epochs, 1985-1990 through 2015-2019 | Optional extension; actual raster processing and comparability not verified |
| Activity by summary area | Not acquired; statewide report totals only | Cannot map local delivery shortfalls or match investment to local priority |
| Current biodiversity outcomes | No consistent observed population/condition series acquired | Cannot claim biodiversity has improved because reported activity increased |

The [NatureKit catalogue](https://www.environment.vic.gov.au/biodiversity/naturekit/nk-datalists) identifies SMP4 as a July 2023 product. Retrieval in 2026 does not make it a 2026 ecological assessment. The [SMP guide](https://www.environment.vic.gov.au/biodiversity/choosing-actions-for-nature/how-to-use-strategic-management-prospects) explains its use for comparing potential management benefits. These model outputs and historic management records answer different questions.

## Scope that is realistic by 3 November

Build two substantive workspaces, with a comparison drawer and a methods panel. The first explores spatial priorities; the second embeds a Tableau dashboard of reported progress. A third page containing little more than lists would weaken the product. Detail tables belong behind charts and downloads.

Keep the following out of the core: statewide species modelling, a new weighted conservation index, budget optimisation, forecasts to 2037, individual property recommendations, annual land-cover animation, and an invented biodiversity health score. Each requires evidence or validation that this dataset does not provide. Species-specific needs can be acknowledged through a clearly identified sample report and links to official reports.

## Findings that affect design

- All 12,403 action rows join to `microID`. No duplicate area/action keys were found. `unit925` has a polygon but no action rows, so the interface must distinguish missing action coverage from zero rank.
- Action coverage is uneven: fox control appears in 1,051 areas, while horse control appears in 76. An absent action row is not evidence that a threat is absent.
- `AREA_20` is labelled **Area in Top 15% (ha)** in the live NatureKit configuration. Preserve the raw name in the data dictionary, but use the published display label in charts.
- `BE_RANK` is labelled mean benefit in the live configuration, while the downloaded area report describes median benefit. Exclude benefit-rank comparisons from the first release until this is resolved. `CE_RANK` is consistently described as median cost-effectiveness rank.
- The Unit 1 report dated 24 March 2023 gives fox control a median rank of 85; the live service gives 87. Reports also include integrated actions absent from the 16-action service. Use the live snapshot throughout core comparisons. Do not silently combine the report and service.
- The annual series measures activity delivered by multiple organisations, not DEECA alone. Annual control hectares may be treated repeatedly. Cross-action hectares may overlap.
- Revegetation is cumulative and has a reported method change around 2020-21. Its jump cannot be described entirely as new planting. Permanent protection is also cumulative.

## Risk register and decisions

| Risk | Likelihood / impact | Response and completion gate |
|---|---|---|
| Reuse terms absent from service metadata | Medium / high | Save applicable dataset terms before external publication. Public query access is verified; a dataset-specific licence is not. Do not infer it from a guidance PDF's licence. |
| Conflicting report and service values | Confirmed / high | Use one frozen service snapshot. Mark report as separate case-study evidence. Resolve benefit aggregation before enabling that metric. |
| Old figures mistaken for current performance | High / high | Persistent period labels; no default “current” KPI. Seek a newer consistent series, but retain verified four-year window if unavailable. |
| Model rank mistaken for probability or money | High / high | Label 0-100 relative rank; no percentage signs on rank, no summing ranks, no budget calculator. |
| Tableau failure on marker's machine | Medium / high | Publish and test early; package workbook and CSVs, document network dependency, test anonymous embed and opening the packaged workbook. |
| Large geometry slows interaction | Medium / medium | Simplify display geometry after topology checks, retain original, measure initial load and filter latency. |
| Too many interactions | Medium / medium | One action selector, explicit selection chips, compare up to three areas, reset visible, detail on demand. |
| Deadline pressure | High / high | Freeze core scope by 23 October; leave land cover and statewide species costs as stretch work. |

## What remains unverified

Dataset redistribution terms, the exact course page 8.5 embedding method, final Tableau compatibility, final Shiny runtime, real user performance and the separate video brief remain open. These do not invalidate the topic, but prevent claiming full submission compliance now. A failed `sf` load in the system R environment also showed that environment preparation must be checked explicitly rather than assumed.

## Alternatives considered

An observation-count dashboard would offer many records but could confuse survey effort with biodiversity change. A land-cover-change dashboard would provide a longer chronology but needs raster acquisition and careful classification handling. A purely spatial SMP explorer is technically feasible, but its performance story would be weaker. Combining priorities with an explicitly separate management-progress view gives the clearest fit to Option 2 within the available time.

## Feasibility conclusion

Planning estimate: approximately 100-140 student hours across data review, Shiny, Tableau, evaluation and submission, or 25-35 hours per member. This is a workload estimate, not measured effort. The core uses publicly accessible data and existing R/Tableau tools; no paid data purchase has been identified. Confirm the team's Tableau authoring access and hosting choice before treating software cost as settled. A statewide raster extension could materially increase both processing time and workload.

The topic is feasible with the acquired core data and has room for substantial technical and design work. Its strongest contribution is helping an officer explain a comparison, with evidence visible at each step. The excellent rubric bands will depend on implementation quality, observed usability and a precise report; dataset size and extra chart types alone will not establish them.
