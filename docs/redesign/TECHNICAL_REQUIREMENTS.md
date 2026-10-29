# Technical requirements against supplied specification

The user supplied ASSIGNMENT_SPEC.txt on 29 October 2026 and limited this task to implementation and Tableau. Report, pitch and peer evaluation are outside this task.

| Requirement | Implemented evidence | Remaining gate |
|---|---|---|
| Cohesive R Shiny product for a Victorian department audience | One app, shared environmental atlas styling, DEECA audience, task-based priority/landscape workspaces | Real audience testing is not claimed |
| Useful exploration and decisions | Linked focus and pins; 16-action rank matrix; opportunity extent; class/epoch map; net changes; temporal comparison; attributed downloads | No causal or ecological-outcome claims |
| Cartography, graphics and HCI | Explicit ranks/denominators; fixed relative-rank and class-share scales; explicitly bounded symmetric net-change scale; keyboard search; labelled missing data; accessible exact-value tables | Desktop is the supported device class |
| R Shiny incorporates genuine Tableau visualisation using page 8.5 techniques | Genuine three-sheet land-cover workbook; Embedding API v3 component; parameter synchronisation and release guards implemented and mock-tested | User has not authorised publication/uploads. Hosted anonymous rendering and bidirectional events must be verified before claiming this requirement complete |
| No package installation in submitted scripts | Dependencies documented externally; R scripts acquire/process data but do not install packages | Install listed packages in the marking environment |
| Final testing | Numerical/geometry, R server, mock bridge, full CSV reconciliation, browser selection/download and native Tableau rendering evidence in VALIDATION.md | Hosted Tableau integration remains untested |
| ZIP includes implementation and required data | Runtime cache, original boundaries, prepared summaries, workbook/CSV, relative paths and run instructions included | Installed R packages are external prerequisites |

The source audit confirms historical epochs rather than annual data, four substantive summary-area overlaps, exact boundary-cell coverage and separate unclassified/NoData handling. The PDF-derived progress prototype is archived and excluded from runtime delivery.
