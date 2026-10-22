# Run once from the project root. No package installation or credentials required.
stopifnot(requireNamespace('sf', quietly=TRUE), requireNamespace('jsonlite', quietly=TRUE))
dir.create('data/downloads', recursive=TRUE, showWarnings=FALSE)
base <- 'https://biod-gis.mapshare.vic.gov.au/arcgis/rest/services/NatureKit/SMP4_summary_areas/MapServer'
get_json <- function(url) {
  f <- tempfile(fileext='.json'); on.exit(unlink(f))
  download.file(url, f, quiet=TRUE, mode='wb')
  x <- jsonlite::fromJSON(f)
  if (!is.null(x$error)) stop(x$error$message)
  x
}
options(timeout=max(180, getOption('timeout')))
message('Downloading DEECA summary areas...')
ids <- get_json(paste0(base, '/0/query?where=1%3D1&returnIdsOnly=true&f=json'))$objectIds
parts <- list()
for (start in seq(1,length(ids),by=250)) {
  chunk <- ids[start:min(start+249,length(ids))]
  url <- paste0(base,'/0/query?objectIds=',paste(chunk,collapse=','),'&outFields=*&returnGeometry=true&outSR=4326&f=geojson')
  f <- tempfile(fileext='.geojson')
  download.file(url, f, quiet=TRUE, mode='wb'); parts[[length(parts)+1]] <- sf::st_read(f,quiet=TRUE);unlink(f)
  stopifnot(nrow(parts[[length(parts)]])==length(chunk))
}
areas <- do.call(rbind,parts)
message('Downloading action records...')
ids <- get_json(paste0(base, '/1/query?where=1%3D1&returnIdsOnly=true&f=json'))$objectIds
parts <- list()
for (start in seq(1,length(ids),by=1000)) {
  chunk <- ids[start:min(start+999,length(ids))]
  url <- paste0(base,'/1/query?objectIds=',paste(chunk,collapse=','),'&outFields=*&returnGeometry=false&f=json')
  x <- get_json(url); stopifnot(!isTRUE(x$exceededTransferLimit), nrow(x$features)==length(chunk))
  parts[[length(parts)+1]] <- x$features$attributes
}
actions <- do.call(rbind,parts)
stopifnot(!anyDuplicated(areas$microID),!anyDuplicated(paste(actions$microID,actions$Action)),all(actions$microID %in% areas$microID))
# Simplification affects display only. Hectares always come from source attributes.
areas <- sf::st_transform(sf::st_make_valid(areas),3111)
areas <- sf::st_simplify(areas,dTolerance=100,preserveTopology=TRUE)
areas <- sf::st_transform(sf::st_make_valid(areas),4326)
stopifnot(!any(sf::st_is_empty(areas)),all(sf::st_is_valid(areas)))
saveRDS(list(areas=areas,actions=actions,retrieved=as.character(Sys.Date()),source=base), 'data/smp_cache.rds')
message('Saved ',nrow(areas),' areas and ',nrow(actions),' action records to data/smp_cache.rds')
