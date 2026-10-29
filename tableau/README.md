# Historical land cover in Victoria

Open `Victoria_Landscape_Change.twbx`. The `LandscapeChange` dashboard contains its own CSV: 140,049 area/period/cover-type records.

Choose a **Main area** and a **Cover type**. Optionally choose up to three **Additional areas**. An ID such as `unit668` identifies one mapped summary area. Blank additional-area slots are unused; repeated IDs do not duplicate records.

1. **What covers the main area?** Each bar is one historical period. In **All cover types**, colours identify cover types and each stack totals 100%. In **Selected cover type**, only the chosen type appears and its percentage scale adjusts to make small values readable. Use **Chart 1: what should the bars show?** to switch modes.
2. **How did the chosen cover type change over time?** Each coloured line is one area. All seven periods remain visible. The percentage scale stays at 0-100%; small categories can be inspected in chart 1.
3. **Did the chosen cover type increase or decrease?** Each row is one area. Dot colours distinguish the **Earlier period** and **Later period**. A later dot farther right means an increase; farther left means a decrease. Equal or close values can overlap. Period choices affect this chart only; the earlier period must precede the later period.

**Land covered (%)** uses land with classified data in each area and period. For example, 40% means 40 of every 100 classified hectares have that cover type. Missing and unclassified areas remain separate hover fields. A change from 30% to 35% is +5 percentage points. Overlapping units must not be added together. Historical cover does not establish habitat health or management outcomes.

Hover fields use readable labels for cover type, historical period, percentage, hectares, classified coverage, unclassified land and missing data. The dashboard includes on-chart reading guides, a complete cover-type legend and source notes.

Rebuild the input with `Rscript scripts/prepare_tableau.R`, then `python3 scripts/build_tableau.py`. Close the workbook before regenerating it, then reopen it in Tableau Desktop to verify rendering. The dashboard is 1200 by 2000 pixels, with the charts arranged vertically for readable labels.

The parameters used by the app bridge are **Main area**, **Additional area 1 (optional)** through **Additional area 3 (optional)**, **Cover type**, **Earlier period**, **Later period**, and **Data release**. The chart-1 mode is controlled within Tableau. Internal field names and the data release are preserved.

`data/manifest.json` identifies the release and CSV hash. The bridge rejects a mismatched release and an old ProgressOverview URL. Hosted integration remains a separate publication-dependent validation step.

## Dashboard layout

The 1400 × 1660 dashboard groups area and cover-type controls in the left sidebar. Optional comparison areas sit below them. The bar-view switch is above chart 1; earlier/later controls sit beside chart 3. Dark green headings, pale green control panels and white chart panels establish a consistent reading order. The complete cover-type legend is visible beside chart 1.
