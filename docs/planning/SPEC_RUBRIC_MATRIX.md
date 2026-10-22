# Specification and rubric traceability

Authority: the user-supplied `A3/SPEC.txt`, including its rubric. The documents in this folder are plans and research evidence, not evidence of completed implementation. “Planned” below means it must be demonstrated before submission.

## Mandatory requirements

| Requirement | Design response | Status now | Acceptance evidence |
|---|---|---|---|
| One cohesive group product | The priority and progress views share navigation, terms and sources | Planned | One app entry point; cross-page terminology review |
| Option 2 department client | DEECA | Selected | Client stated in app, design summary and pitch |
| Public servants or public audience | DEECA officers preparing conservation briefs | Selected | Three explicit user tasks and audience evaluation |
| Intuitive, audience-specific interface | Two task-based workspaces, progressive detail, comparison drawer | Planned | Observed task completion and revision log |
| Practical information, patterns or decisions | Rank/extent trade-offs and target comparisons | Data supports it | Reproducible examples match visible charts |
| Graphics, cartography and HCI principles | Common scales, appropriate denominators, restrained map, accessible selection | Planned | Design rationale plus rendered interface review |
| R Shiny interface | Shiny owns layout, map and comparison state | Planned | Clean-session launch on another machine |
| At least one Tableau visualisation incorporated | ProgressOverview embedded within Shiny | Planned | Working anonymous embed, filters and correct sizing |
| Use page 8.5 techniques | Retrieve exact course instructions before integration | Open dependency | Compare implementation against page 8.5; do not infer compliance from API documentation |
| No package installation commands in scripts | Document dependencies separately | Planning scripts comply | Scan final R scripts for installation calls |
| Data formatting, initial analysis and iterative redesign | Snapshot scripts, audit, initial findings, scheduled usability rounds | Data stage completed | Reproducible data pipeline and design change log |
| Final testing | Data, interaction, visual and portability checks | Planned | Dated test record with failures and corrections |
| ZIP contains implementation and all required files/data | Relative paths, local data, packaged workbook, run instructions | Planned | Extract into new directory and run without original workspace |
| Separate PDF outside ZIP | Design max 2 pages; patterns/use cases max 1.5 pages; references | Planned | Render and inspect final PDF; check page allocation |
| Professional video pitch and demo | Problem, task, evidence, decision, limitations | Planned | Follow separate video brief; duration not specified in supplied SPEC |
| Group participation | Four workstreams with cross-review | Planned | Contribution log and peer evaluation |
| Submission deadline | Tuesday 3 November 2026, 23:59 per SPEC | Scheduled | Upload and reopen submissions before deadline |
| Peer evaluation | FeedbackFruits, 4-6 November 2026; closes 23:59 on 6 November | Scheduled | Each member submits evaluation |

The assignment allows one device class; a mobile layout is not required. Choosing public servants keeps the proposed audience within Option 2. Do not introduce an approval step solely because the theme has changed from housing to biodiversity.

## Rubric: 25 points per dimension

| Dimension | What the excellent band asks for | Proposed evidence | Main failure to avoid |
|---|---|---|---|
| Basic design | Correct runnable package, coherent valid story, consistent appearance, sound graphic/cartographic/interface principles | Complete files; clear time/version labels; shared map and heatmap scales; valid joins; no overlap double counting; accessible controls | Attractive layout with misleading rank or temporal claims |
| Technical challenge | Advanced techniques and varied complex interactions that remain intuitive; independent work | Reproducible spatial pipeline, linked map/heatmap selection, persistent three-area comparison, extent/rank toggle, embedded Tableau filters | Adding controls that do not support the audience's task |
| Design innovation | Original, audience-specific design that reveals meaningful patterns | Compare area-action patterns and rank with extent; evidence attached to selections; show target attainment alongside activity volume; distinguish model and observed reporting | Reproducing NatureKit's layer list or a generic KPI dashboard |
| Report | Clear background, design process and justified decisions; meaningful patterns and authentic use cases; academic writing | Before/after design evidence, tested tasks, correct calculations, source limitations and concise references | Claiming ecological recovery from activity hectares or describing features not built |

The plan gives a route toward the excellent bands. It cannot establish a mark before the product is implemented and evaluated. Complexity, chart count and data volume are not substitutes for accuracy and task performance.

## Submission checks

- Open every packaged data file and workbook after extracting the ZIP elsewhere.
- Verify that the report describes the final product, not abandoned stretch features.
- Confirm every reported pattern can be reproduced from supplied data and shown in the demo.
- Distinguish reported activity, modelled priority and historical context in every chart title or subtitle.
- Include references and attribution, not government branding that implies endorsement.
- Resolve page 8.5, licence and video-brief dependencies before declaring compliance complete.
