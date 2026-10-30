# Meaningful cache compatibility checks, including a changed map with unchanged IDs.
source('R/landcover.R')
stopifnot(requireNamespace('sf',quietly=TRUE))
scratch<-tempfile('cache-check-');dir.create(scratch)
original<-sf::st_as_sf(data.frame(microID=c('unit1','unit2'),Name=c('Unit 1','Unit 2'),
  Area=c(100,100),Shape_Area=c(1e6,1e6),
  wkt=c('POLYGON ((2500000 2500000,2501000 2500000,2501000 2501000,2500000 2501000,2500000 2500000))',
        'POLYGON ((2502000 2500000,2503000 2500000,2503000 2501000,2502000 2501000,2502000 2500000))')),
  wkt='wkt',crs=3111)
boundary<-file.path(scratch,'original.rds');cache<-file.path(scratch,'cache.rds');saveRDS(original,boundary)
display<-sf::st_transform(sf::st_make_valid(sf::st_simplify(original,dTolerance=100,preserveTopology=TRUE)),4326)
d<-list(areas=display,retrieved='2026-10-22');saveRDS(d,cache)
lc<-list(manifest=list(boundary_md5=unname(tools::md5sum(boundary)),spatial_cache_md5=unname(tools::md5sum(cache))))
verify<-function(x=d) validate_spatial_release(x,lc,cache,boundary)
stopifnot(verify()$method=='exact-cache')
d$retrieved<-'2026-10-29';saveRDS(d,cache)
stopifnot(verify()$method=='verified-boundaries')
reordered<-d;reordered$areas<-reordered$areas[2:1,];saveRDS(reordered,cache)
stopifnot(verify(reordered)$method=='verified-boundaries')
rejected<-function(x) inherits(try(suppressMessages(verify(x)),silent=TRUE),'try-error')
changed<-d;changed$areas$microID[1]<-'unit999';stopifnot(rejected(changed))
changed<-d;changed$areas$Shape_Area[1]<-9e6;stopifnot(rejected(changed))
changed<-d;g<-sf::st_transform(changed$areas,3111);sf::st_geometry(g)<-sf::st_geometry(g)+c(100,0)
sf::st_crs(g)<-3111;changed$areas<-sf::st_transform(g,4326);stopifnot(rejected(changed))
changed_original<-original;changed_original$Area[1]<-101;saveRDS(changed_original,boundary)
stopifnot(rejected(d))
stopifnot(startsWith(normalizePath(scratch,winslash='/'),paste0(normalizePath(tempdir(),winslash='/'),'/')))
unlink(scratch,recursive=TRUE)
cat('PASS exact cache, metadata-only change, row order, changed IDs, changed attributes, shifted geometry and changed analytical source\n')
