# Build, evaluation and submission plan

The supplied deadline is 3 November 2026 at 23:59. This plan starts on 21 October and reserves the final days for testing and submission. It is a proposed schedule for four team members, not a record of work already performed.

| Dates | Deliverable and gate |
|---|---|
| 21-22 Oct | Confirm audience and scope; review downloaded data, licence terms, course page 8.5 and video instructions. Double-check transcribed figures. |
| 23 Oct | Freeze data definitions and two-view design. Produce first Tableau workbook and prove that a published view loads inside a minimal Shiny page. If integration fails, fix it before adding features. |
| 24-25 Oct | Build Shiny map, area-action heatmap, keyboard selector, missing-data states and comparison drawer. Author temporal worksheets, including the target-gap dot plot, with independently checked calculations. |
| 26 Oct | Integrate navigation, sources, exports and Tableau. Test each core task as a group. |
| 27-28 Oct | Conduct five peer task sessions; record errors, completion and interpretation. Revise layout and labels. |
| 29 Oct | Content freeze. Validate joins, denominators, source notes, geometry and workbook behaviour. Remove unfinished stretch features. |
| 30-31 Oct | Test extracted package on another machine; review accessibility, sizing, loading failures and browser behaviour. Draft report from final screenshots and findings. |
| 1 Nov | Render and inspect PDF; record pitch and demo against the separate video brief. |
| 2 Nov | Final group review, bibliography and contribution log. Upload early if possible. |
| 3 Nov | Contingency and submission verification before 23:59. |
| 4-6 Nov | Each member completes FeedbackFruits peer evaluation by 6 Nov 23:59. |

## Responsibilities

| Role | Owns | Cross-review |
|---|---|---|
| Data and spatial analysis | Source register, licence evidence, geometry, joins, data dictionary, reproducibility | Review Tableau measures and source notes |
| Shiny and interaction | Navigation, map/heatmap linkage, comparison state, exports, error states | Review usability tasks and packaging |
| Tableau and temporal analysis | Worksheets, calculations, workbook, publishing and embedding test | Check data pipeline figures and report examples |
| Design and evaluation | Visual system, task testing, report coordination and pitch | Review interface consistency and accessibility |

All four should understand and demonstrate the product. Keep a dated contribution log and have each deliverable checked by someone other than its author. Roles are not names and can be reassigned by the group.

## Implementation architecture

Use `shiny`, a layout package such as `bslib`, `sf`, `leaflet`, and a chart package selected for the tested interaction needs. Keep the dependency list short. The final app reads local processed data rather than requesting all statewide services on each session. Cache static spatial preparation. Use relative paths from one project root and record package versions outside application code. No installation calls belong in scripts.

Suggested modules: priorities, comparison, progress and evidence. Maintain one reactive selection state for action and pinned areas. Do not apply a spatial selection to statewide historical totals. Include model/version fields in every exported comparison.

## Tests with practical acceptance criteria

| Test | Pass condition |
|---|---|
| Snapshot completeness | IDs requested equal records returned; no transfer truncation; unique keys |
| Data join | All action records join; missing boundary-only unit is explicitly displayed |
| Derived shares | Independently recalculate five samples; all shares in 0-100; no duplicate totals |
| Historical measures | Reconcile all source table values; target basis correct; method change visible |
| Spatial display | Valid non-empty geometries, correct extent and selection; no unexpected changes from repair |
| Tableau | TWBX opens in installed version; all worksheets present; calculations match CSV; published dashboard embeds anonymously |
| State consistency | Map and profile agree after changing action, pinning, unpinning and resetting |
| Heatmap | Cell selection updates map area/action; action columns remain visible; missing cells differ from zero; values accessible by keyboard |
| Target-gap dots | Annual priority-only measures; percentage-point gaps verified; 100% reference visible; above-target values not clipped |
| Empty states | Missing action and unit925 do not become zero; no blank unexplained panels |
| Usability | Five task sessions; target at least four unaided completions per core task; revise failures |
| Performance | Aim for initial app usable within 5 seconds and local selections within 1 second on the tested machine; measure, do not claim in advance |
| Portability | Extract ZIP to new path on second machine; no absolute user paths or undeclared files |
| Network failure | Helpful Tableau unavailable state and local evidence remain; limitation documented |
| Accessibility | Keyboard selection/reset, readable text, contrast check, non-colour selection cues |

## Report allocation

Design summary, maximum two pages: audience and decision problem; data and limits; information hierarchy and encoding choices; implementation contribution; evaluation and changes. Use one annotated final screenshot only if it remains legible.

Pattern/use-case summary, maximum 1.5 pages: two or three reproducible cases, each linking a user question to interaction, observation and decision implication. Include the rank-versus-extent trade-off and a temporal interpretation example. Keep untested claims out.

Place sources/references in the separate PDF as required by the SPEC. Confirm the exact treatment of reference pages with the provided submission instructions if unclear. The research documents here are working material, not the final capped report.

## Pitch structure

Introduce the officer's problem, demonstrate finding and comparing an area, switch to the Tableau progress view, explain one useful finding and one limitation, then state the product's value to the client. Confirm duration, file format and video submission route from the separate video brief. No duration was supplied in SPEC.txt.

## Scope gates

By 23 October, proceed with the core only if the Tableau proof of integration and data-use terms are resolved. If species/cost information remains inconsistent, leave it as an official-report link. If land-cover raster acquisition is unfinished, omit that view without weakening the core. Do not trade the final testing period for additional datasets.
