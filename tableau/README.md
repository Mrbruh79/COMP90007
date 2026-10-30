# Historical land cover in Victoria

Open `Victoria_Landscape_Change.twbx` to inspect or republish the workbook with its bundled 140,049-row CSV. The dashboard name is `LandscapeChange`.

## Reading the dashboard

The 1180 x 1240 desktop layout follows three questions:

1. **Selected cover through time:** the largest chart compares the chosen cover type across all seven periods. Labels at the ends identify the areas. The legend distinguishes the main area and each pinned comparison. The area legend remains available when labels collide. **Trend measure** switches between cover share (%) and change since each area's own first period (pp). The vertical axis title changes with this choice. Automatic ranges include zero in both modes.
2. **Land cover composition:** seven stacked bars describe the main area, identified in the heading. **Composition view** offers seven display groups, all 19 source classes, or the selected cover type on an automatic scale. The legend follows the top to bottom order of the stacks. Detailed mode has a scrolling legend; hover for long class names.
3. **Change between selected periods:** dots show later minus earlier share on a fixed -100 to +100 percentage-point scale. Five major ticks and a zero reference keep the scale comparable between selections. Labels give earlier percentage, later percentage and signed change; hover for greater precision. A small change therefore stays visibly small. Positive means increased cover share, not necessarily ecological benefit. Invalid or reversed intervals produce no endpoint comparison.

Shiny owns selection of areas, cover type and endpoint periods. Only the two presentation controls remain visible in Tableau. All original parameter names and captions remain available to the API bridge. The cover type title and endpoint-date heading update with those parameters. The shared Shiny selection strip names the main area; the series legend also identifies its role. For standalone inspection in Tableau Desktop, show a parameter from the Data pane to change it. The published view is designed for use within Shiny.

Small nonzero endpoint percentages and changes use <0.1 labels rather than appearing as exact zeros. Tooltips retain additional decimals.

The canvas uses the app's paper background, Georgia cover type heading, consistent section typography and restrained land cover colours. Duplicate worksheet titles and the nested outer frame are removed. The source data and chart values are unchanged.

## Data and interpretation

Source: State of Victoria / DEECA, Victorian Land Cover Time Series (2020), CC BY 4.0. The first downloaded file is labelled 1985-1990; the catalogue describes it as 1987-1990. The app follows the files. Baseline change always uses 1985-1990, independently of the chosen earlier endpoint.

Percentages exclude missing and unclassified land. Areas overlap and must not be summed into statewide hectares. Land cover change does not establish habitat quality, ecological recovery or what one class replaced. Further limitations appear in the app's Sources & methods section.

Group mapping by source code: agriculture (4,5,8); developed/disturbed (1,2,3); plantations/exotic trees (6,7,15); wetland vegetation (9,16,18,19); other native vegetation (10,11,12,13); natural low cover (14); open water (17). These are presentation groups, not new government classifications. Grouped shares sum source classes within one unit and epoch. Repeated coverage and missing-area fields aggregate by minimum rather than sum.

Colour assignments use explicit data source column instances so Tableau retains them. Colours follow selection slots for every area: main green, first pin ochre, second pin slate and third pin rose. The history and change charts use the same assignments as the local R history chart. Chart data use LF line endings to preserve the release checksum on Windows.

## Rebuild and republish

Run `python scripts/build_tableau.py`. The generator uses the native validated XML scaffold and `scripts/tableau_axis_title.xml`, a dynamic-axis graph saved by Tableau 2026.2. Each rebuild binds that graph to the generated trend worksheet's identifier. Reopen in Desktop to check the actual rendering; XML/data checks alone do not establish visual correctness.

Run `python tests/check_tableau.py` and `node tests/landscape_bridge.cjs` for the data/package and parameter-bridge checks.

If a workbook saved with an extract reports that `landcover.csv` is missing, its original CSV connection may point to an expired Tableau temporary folder. For local authoring, use Edit Connection to select `tableau/data/landcover.csv`. The `.twb` beside that data folder is also available for editing. Keep the data folder with it.

Before moving or submitting a saved `.twbx`, restore its bundled CSV without changing the extract or sheet layouts:

```sh
python scripts/repair_tableau_package.py --output tableau/Victoria_Landscape_Change.twbx
python tests/tableau_saved_package.py
python tests/check_tableau.py
```

The repair saves a backup when replacing the input file. It retains the saved workbook's parameters, calculations, layouts and extract, adds the frozen CSV, and uses a package-relative source path. The submission builder rejects packages with missing source files, mismatched releases or external temporary paths. Opening the data-source tab and refreshing its preview are part of the native workbook check.

Republish under the existing **Victoria_Landscape_Change** workbook name and **LandscapeChange** dashboard name. Keep this dashboard selected when publishing. The Shiny embed reads the publication's canvas size, supporting the older publication during the handover. Restart Shiny after updating the local files, then check that a map selection updates the title, lines, composition area and endpoint values. The replacement publication requires this final check after upload.

Display labels use words in place of dash punctuation. The chart axes abbreviate years, such as 1985/90; headings and Shiny controls retain full years. Parameter aliases change display text while original source values remain available to the bridge.
