# Conservation priorities and historical land cover

Local redesign authorised 29 October 2026. No public deployment, data upload or Tableau publication is authorised. This contract describes implementation decisions; VALIDATION.md records actual evidence.

Audience: DEECA public servants preparing landscape assessments. The task is to investigate modelled opportunities in the context of historical land cover, without attributing past change to management or treating mapped classes as habitat quality.

## Data decision

Use the downloaded classified TIFFs, not rendered service images or LGA summaries. The verified prepackage is 426,746,271 bytes and contains seven TIFFs with matching EPSG:3111 grids, 25 m cells, and class codes 0-19. Raw filenames and raster attribute tables use 1985-1990 for the first epoch; the catalogue says 1987-1990. The interface follows the files and discloses the difference. These are multi-year epochs, not annual observations.

Analyse original SMP geometry after projection and repair. The existing simplified boundaries remain display geometry only. Exact cell-intersection fractions preserve boundary cells, including small units. Class hectares are projected grid areas (625 square metres per complete cell); this is explicit in the data export and methods. Class share uses codes 1-19 as its denominator. Unclassified code 0 and NoData/outside coverage remain separate. Real class absence is zero when the unit has classified coverage; no classified coverage yields missing values.

SMP units overlap. Store per-unit statistics and prevent statewide or combined-area totals. No transition matrix is implemented: changing class totals does not identify the origin or destination of pixels. The existing SMP snapshot was actually retrieved 22 October 2026, as recorded in the local cache, rather than assuming the handoff's 21 October date.

## Responsibilities and interactions

Shiny owns navigation, the SMP action explorer, focused/pinned units (maximum three pins), endpoint epochs, selected class, class-share/change choropleth, all-class net-change chart, exact values and downloads. The landscape map displays summaries by SMP unit, not a pixel-resolution raster. Each map has an explicit legend and display-geometry caveat. Class shares use 0-100%; changes use a symmetric range determined by the largest absolute change across all units for that class/period, with a minimum +/-1 pp range and explicit bounds. The comparison keeps units separate.

Tableau owns a genuine interactive historical composition view for the focused unit and a selected-class trajectory comparison for the focus plus pins. All seven epochs remain visible. Parameters share focused unit, three comparison slots, selected class and data release with Shiny. The endpoint period can be highlighted rather than dropping intermediate epochs. A missing publication URL exposes the portable workbook download and local evidence; it must not be described as a completed embed.

The R all-class changes and Tableau temporal views answer different tasks: identify which classes changed, then inspect the temporal pattern and compare the same class across units. No redundant KPI cards or composite priority/change score are introduced. A later SMP4 model snapshot is always labelled separately from 1985-2019 land cover.

## Validation and submission

Verify categorical mapping, grid/epoch metadata, boundary repair/overlap, area closure, shares, empty coverage, zero versus missing, reversed endpoints, shared selections, pin limits, exports, workbook parameter calculations, rendering and extracted-package launch. Use a synthetic fractional-cell fixture plus independent full-resolution extraction on real units.

The user supplied the original assignment specification during implementation; it is saved as ASSIGNMENT_SPEC.txt. The technical requirements confirm: cohesive Shiny product, genuine Tableau incorporation using API v3, no installation commands in submitted R, portable ZIP, design summary up to two pages, patterns/use cases up to 1.5 pages plus references, and a professional pitch. The user explicitly narrowed this task to code and Tableau. Report, pitch, video and peer-evaluation deliverables are outside this implementation scope. Hosted Tableau embedding remains a publication-dependent gate.
