# Source notes for the landscape redesign

## Land cover

Official catalogue: https://discover.data.vic.gov.au/dataset/victorian-land-cover-time-series

Official metadata: https://metashare.maps.vic.gov.au/geonetwork/srv/api/records/81726131-7c8d-52b9-a243-d6a8429966e2/formatters/xml

Official direct prepackage, discovered through DataShare's public catalogue metadata: https://cl-isd-prd-datashare-s3-delivery.s3.amazonaws.com/PrePackages/VIC_LANDCOVER_TS.zip

Attribution: State of Victoria (Department of Energy, Environment and Climate Action). Catalogue and source metadata identify Creative Commons Attribution 4.0 International: https://creativecommons.org/licenses/by/4.0/. The prepackage contains raster metadata and attribute tables, preserved locally under data/downloads/landcover. No government logo is used to imply endorsement.

Downloaded files were created in July 2020; the archive's HTTP last-modified value was 25 September 2024. These distribution dates are distinct from observation epochs. Filenames and START_YEAR/END_YEAR fields describe 1985-1990 through 2015-2019. Catalogue text describes the first epoch as 1987-1990. The downloaded dates are used consistently in the app and Tableau.

All seven rasters share EPSG:3111, 25 m cell spacing, origin, extent and 31,538 x 37,450 dimensions. Raster attribute tables have codes 0-19. Code 0 is Unclassified; NoData is 127 in the TIFF. The active category exposed by terra defaults to START_YEAR, so preparation removes that categorical mapping before analysing raw class codes. This step prevents treating a year as a class.

Class labels follow the downloaded CLASS_NAME field, including "Native scrubland". The explanatory webpage uses "Native shrubland". Source descriptions contain a duplicated dryland-cropping description for the horticulture class in the earliest table; the app uses the class label and does not repeat that description as an authoritative definition. Broad CLASS_GEND groupings are retained in the data for provenance and are not used as a habitat-quality score.

No transition matrix is produced. Matching grids were verified, but this implementation compares per-class totals. Classified denominators are epoch-specific. The latest epoch contains 0.125 grid hectares of NoData in Unit 905; this stays separate from code 0. Class change must not be attributed to conservation management.

## SMP4

Boundary layer: https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer/0

Action table: https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer/1

The actual frozen cache was retrieved 22 October 2026. The 21 October date in the handoff describes an earlier snapshot; it is not substituted for local provenance. The displayed SMP4 model release is July 2023, supported by NatureKit's dataset guide.

The existing source terms apply independently of land cover's CC BY 4.0. No new licence is asserted over SMP4. Original boundaries are frozen in data/smp_original.rds, with the hash used in the land-cover release. Analytical processing transforms and repairs these vertices in EPSG:3111. Three originally invalid geometries become valid; maximum planar repair-area change was about 0.0001 square metres. Display geometry remains simplified to 100 m and is never used for the overlay.

There are four source overlap pairs above one square metre, with the largest about 490.6 ha. Much smaller intersections are numerical slivers. Full pair records are in data/landcover/boundary_overlaps.csv. Unit totals must not be summed into a statewide or combined-area estimate.

CE_RANK is a median relative model rank, not probability, financial return or observed recovery. CE_RANGE is not a confidence interval. AREA_TOT is action-relevant area. Top-5% hectares are included in AREA_20, whose NatureKit display meaning is top 15%. Benefit-rank fields remain outside the core interface. Join keys are microID, not OBJECTID.

## Numeric treatment and provenance

Per-unit class fractions use exact polygon-cell intersection coverage at the native resolution. Finite-precision fraction accumulators are checked against projected polygon area, with a strict 0.1 ha closure bound on the largest units, before normalisation to polygon hectares. Unclassified and NoData fractions remain separate through normalisation. Values are projected grid hectares in EPSG:3111, not geodesic surface areas.

Every exported record identifies its release, unit, epoch, class, coverage, denominator, source and attribution. Per-source MD5 fingerprints provide reproducibility, not a security guarantee. No resampling, raster reclassification or annual interpolation is used. Net totals do not identify class-to-class transitions, degradation or recovery.
