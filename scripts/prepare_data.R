# Run once from the project root. Refresh explicitly with Rscript scripts/prepare_data.R --refresh.
prepare_spatial <- function(refresh='--refresh' %in% commandArgs(TRUE)) {
  stopifnot(requireNamespace('sf',quietly=TRUE),requireNamespace('jsonlite',quietly=TRUE))
  cache <- 'data/smp_cache.rds'
  if(file.exists(cache) && !refresh) {
    message('Using the frozen local snapshot. Pass --refresh to acquire a new release.')
    return(invisible(readRDS(cache)))
  }
  dir.create('data/downloads',recursive=TRUE,showWarnings=FALSE)
  base <- 'https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer'
  manifest <- list()
  fetch <- function(url,extension='.json') {
    f <- tempfile(fileext=extension)
    download.file(url,f,quiet=TRUE,mode='wb')
    manifest[[length(manifest)+1L]] <<- list(url=url,md5=unname(tools::md5sum(f)),bytes=unname(file.info(f)$size))
    f
  }
  get_json <- function(url) {
    f <- fetch(url);on.exit(unlink(f))
    x <- jsonlite::fromJSON(f)
    if(!is.null(x$error)) stop(x$error$message)
    x
  }
  options(timeout=max(180,getOption('timeout')))
  message('Downloading DEECA summary areas...')
  ids <- get_json(paste0(base,'/0/query?where=1%3D1&returnIdsOnly=true&f=json'))$objectIds
  stopifnot(length(ids)>0,!anyDuplicated(ids))
  parts <- list()
  for(start in seq(1,length(ids),by=250)) {
    chunk <- ids[start:min(start+249,length(ids))]
    url <- paste0(base,'/0/query?objectIds=',paste(chunk,collapse=','),'&outFields=*&returnGeometry=true&outSR=4326&f=geojson')
    f <- fetch(url,'.geojson');part <- sf::st_read(f,quiet=TRUE);unlink(f)
    stopifnot(nrow(part)==length(chunk))
    parts[[length(parts)+1L]] <- part
  }
  original <- do.call(rbind,parts)
  message('Downloading action records...')
  ids <- get_json(paste0(base,'/1/query?where=1%3D1&returnIdsOnly=true&f=json'))$objectIds
  stopifnot(length(ids)>0,!anyDuplicated(ids))
  parts <- list()
  for(start in seq(1,length(ids),by=1000)) {
    chunk <- ids[start:min(start+999,length(ids))]
    x <- get_json(paste0(base,'/1/query?objectIds=',paste(chunk,collapse=','),'&outFields=*&returnGeometry=false&f=json'))
    stopifnot(!isTRUE(x$exceededTransferLimit),nrow(x$features)==length(chunk))
    parts[[length(parts)+1L]] <- x$features$attributes
  }
  actions <- do.call(rbind,parts)
  stopifnot(!anyDuplicated(original$microID),!anyDuplicated(paste(actions$microID,actions$Action)),
    all(actions$microID %in% original$microID),all(actions$AREA_TOT>0),
    all(actions$AREA_5>=0 & actions$AREA_5<=actions$AREA_20 & actions$AREA_20<=actions$AREA_TOT),
    all(actions$CE_RANK>=0 & actions$CE_RANK<=100))
  # Repair in a projected CRS; simplify for display only. Source hectare attributes are untouched.
  repaired <- sf::st_transform(sf::st_make_valid(original),3111)
  areas <- sf::st_make_valid(sf::st_simplify(repaired,dTolerance=100,preserveTopology=TRUE))
  change <- 100*(as.numeric(sf::st_area(areas))-as.numeric(sf::st_area(repaired)))/as.numeric(sf::st_area(repaired))
  audit <- list(original_invalid=sum(!sf::st_is_valid(original)),display_invalid=sum(!sf::st_is_valid(areas)),
    max_absolute_display_area_change_pct=max(abs(change)),simplification_metres=100,
    note='Per-feature geometry check only; no analytical overlays or cross-boundary topology claim.')
  areas <- sf::st_transform(areas,4326)
  stopifnot(!any(sf::st_is_empty(areas)),all(sf::st_is_valid(areas)),identical(original$microID,areas$microID))
  stamp <- format(Sys.time(),'%Y%m%dT%H%M%S',tz='UTC')
  if(file.exists(cache)) file.copy(cache,paste0('data/downloads/smp_cache-',stamp,'.rds'),overwrite=FALSE)
  saveRDS(original,'data/downloads/smp_original.rds')
  saveRDS(original,'data/smp_original.rds')
  snapshot <- list(areas=areas,actions=actions,retrieved=as.character(Sys.Date()),source=base,
    retrieved_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),geometry_audit=audit)
  # The old cache remains usable if downloading or validation fails before this point.
  temporary <- tempfile(tmpdir='data',fileext='.rds');saveRDS(snapshot,temporary)
  if(!file.rename(temporary,cache)) stop('Could not replace the local snapshot.')
  jsonlite::write_json(list(retrieved_utc=snapshot$retrieved_utc,requests=manifest,geometry=audit,
    areas=nrow(areas),actions=nrow(actions),cache_md5=unname(tools::md5sum(cache))),
    'data/downloads/spatial_manifest.json',auto_unbox=TRUE,pretty=TRUE)
  message('Saved ',nrow(areas),' areas and ',nrow(actions),' action records. Original geometry and request hashes are in data/downloads/.')
  invisible(snapshot)
}
prepare_spatial()
