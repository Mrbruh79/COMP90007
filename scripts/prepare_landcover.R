# Reproducible full resolution overlay. Run from the project root.
# Dependencies are installed separately; no runtime installation or public upload.
prepare_landcover <- function(refresh='--refresh' %in% commandArgs(TRUE)) {
  for(p in c('terra','sf','exactextractr','jsonlite','foreign'))
    if(!requireNamespace(p,quietly=TRUE)) stop('Missing preparation dependency: ',p)
  out <- 'data/landcover'; raw <- 'data/downloads/landcover'
  dir.create(out,recursive=TRUE,showWarnings=FALSE);dir.create(raw,recursive=TRUE,showWarnings=FALSE)
  if(file.exists(file.path(out,'summary.csv.gz')) && !refresh) {
    message('Using frozen land cover summaries. Use --refresh to recalculate.');return(invisible(NULL))
  }
  url <- 'https://cl-isd-prd-datashare-s3-delivery.s3.amazonaws.com/PrePackages/VIC_LANDCOVER_TS.zip'
  zip <- file.path(raw,'VIC_LANDCOVER_TS.zip')
  options(timeout=max(1200,getOption('timeout')))
  if(!file.exists(zip)) {
    temporary <- paste0(zip,'.part');download.file(url,temporary,mode='wb',quiet=FALSE)
    if(!file.rename(temporary,zip)) stop('Could not save source archive')
  }
  # Extract source rasters and their metadata from the official archive.
  members <- unzip(zip,list=TRUE)$Name
  keep <- members[grepl('[.]tif$|[.]xml$|[.]dbf$|[.]mht$',members)]
  unzip(zip,files=keep,exdir=raw,overwrite=TRUE)
  files <- sort(list.files(file.path(raw,'VIC_LANDCOVER_TS'),pattern='[.]tif$',full.names=TRUE))
  stopifnot(length(files)==7)
  boundary_path<-if(file.exists('data/smp_original.rds')) 'data/smp_original.rds' else 'data/downloads/smp_original.rds'
  if(!file.exists(boundary_path))
    stop('Original SMP boundaries are required. Run Rscript scripts/prepare_data.R --refresh first. Display boundaries must not be used for analysis.')
  # Use original area boundaries for analysis, with projected units in metres.
  original <- readRDS(boundary_path)
  original <- original[order(as.integer(sub('unit','',original$microID))),]
  projected <- sf::st_transform(original,3111)
  pre_area <- as.numeric(sf::st_area(projected))
  repaired <- sf::st_make_valid(projected)
  stopifnot(all(sf::st_is_valid(repaired)),!any(sf::st_is_empty(repaired)),!anyDuplicated(repaired$microID))
  polygon_ha <- as.numeric(sf::st_area(repaired))/10000
  # Shared boundaries are not assumed to form a partition. Retain each unit separately.
  rel <- sf::st_relate(repaired,pattern='2********')
  pairs <- do.call(rbind,lapply(seq_along(rel),function(i) {j<-rel[[i]];j<-j[j>i];if(length(j)) cbind(i,j)}))
  overlap <- if(is.null(pairs)) data.frame() else data.frame(
    microID_a=repaired$microID[pairs[,1]],microID_b=repaired$microID[pairs[,2]],
    overlap_ha=vapply(seq_len(nrow(pairs)),function(i)
      sum(as.numeric(sf::st_area(suppressWarnings(sf::st_intersection(sf::st_geometry(repaired[pairs[i,1],]),sf::st_geometry(repaired[pairs[i,2],]))))))/10000,0.0))
  write.csv(overlap,file.path(out,'boundary_overlaps.csv'),row.names=FALSE)
  epochs <- list();summaries <- list();audits <- list();definition_changes<-list();classes <- NULL;template <- NULL
  started <- Sys.time()
  # Process each historical raster on its native grid and retain source class definitions.
  for(i in seq_along(files)) {
    f<-files[i];r<-terra::rast(f);rat<-foreign::read.dbf(paste0(f,'.vat.dbf'),as.is=TRUE)
    stopifnot(identical(sort(as.integer(rat$Value)),0:19),length(unique(rat$START_YEAR))==1,length(unique(rat$END_YEAR))==1)
    current <- data.frame(class_code=rat$Value,class_label=trimws(rat$CLASS_NAME),class_group=trimws(rat$CLASS_GEND),source_description=trimws(rat$CLASS_DESC))
    if(is.null(classes)) classes<-current else stopifnot(identical(classes[c('class_code','class_label','class_group')],current[c('class_code','class_label','class_group')]))
    if(i>1) {
      changed<-which(classes$source_description!=current$source_description)
      if(length(changed)) definition_changes[[i]]<-data.frame(source_filename=basename(f),class_code=current$class_code[changed],
        initial_description=classes$source_description[changed],epoch_description=current$source_description[changed])
    }
    nodata_line<-grep('NoData Value=',terra::describe(f),value=TRUE)
    source_nodata<-if(length(nodata_line)) as.numeric(sub('.*NoData Value=','',nodata_line[1])) else NA_real_
    # Remove the active START_YEAR category. The analysis must use raw class codes.
    levels(r)<-NULL;names(r)<-'class_code'
    if(is.null(template)) template<-r else stopifnot(isTRUE(terra::compareGeom(template,r,stopOnError=FALSE)))
    stopifnot(!terra::is.lonlat(r),all(terra::res(r)==25),terra::same.crs(r,'EPSG:3111'))
    start<-unique(rat$START_YEAR);end<-unique(rat$END_YEAR);id<-paste0(start,'_',end)
    epochs[[i]]<-data.frame(epoch_id=id,epoch_label=paste(start,end,sep='-'),epoch_start=start,epoch_end=end,source_filename=basename(f))
    message('Exact class coverage: ',id,' (',i,'/7)')
    # Weight boundary cells by the fraction covered by each area.
    z<-exactextractr::exact_extract(r,repaired,c('count','frac'),default_value=-9999,progress=FALSE,max_cells_in_memory=2e6)
    codes<-as.integer(sub('frac_','',names(z)[grepl('^frac_',names(z))]))
    stopifnot(all(codes %in% c(-9999,0:19)))
    # Keep source NoData (127 in the TIFF) separate from code 0 using a sentinel.
    # Every unit is wholly inside the raster rectangle.
    # Coverage/frac accumulators use finite precision; normalise fractions to polygon area
    # only after verifying closure within 0.1 ha (less than 2 cells for the largest unit).
    bb<-sf::st_bbox(repaired);re<-as.vector(terra::ext(r))
    stopifnot(bb[['xmin']]>=re[1],bb[['xmax']]<=re[2],bb[['ymin']]>=re[3],bb[['ymax']]<=re[4])
    numerical_residual<-z$count*.0625-polygon_ha
    stopifnot(all(abs(numerical_residual)<.1))
    fractions<-as.matrix(z[paste0('frac_',codes)]);fraction_total<-rowSums(fractions)
    stopifnot(all(abs(fraction_total-1)<1e-5))
    class_area<-matrix(0,nrow=nrow(repaired),ncol=21,dimnames=list(NULL,as.character(c(-9999,0:19))))
    for(code in codes) class_area[,as.character(code)]<-z[[paste0('frac_',code)]]/fraction_total*polygon_ha
    unclassified<-class_area[,'0'];valid<-rowSums(class_area[,as.character(1:19),drop=FALSE])
    nodata<-class_area[,'-9999']
    stopifnot(all(abs(rowSums(class_area)-polygon_ha)<.01))
    # Produce one row for every area and classified cover type in this period.
    x<-expand.grid(class_code=1:19,area_index=seq_len(nrow(repaired)))
    x$microID<-repaired$microID[x$area_index];x$epoch_id<-id
    x$area_ha<-class_area[cbind(x$area_index,x$class_code+2L)]
    x$valid_area_ha<-valid[x$area_index];x$unclassified_area_ha<-unclassified[x$area_index]
    x$nodata_area_ha<-nodata[x$area_index];x$polygon_area_ha<-polygon_ha[x$area_index]
    x$share_pct<-ifelse(x$valid_area_ha>0,100*x$area_ha/x$valid_area_ha,NA_real_)
    x$area_ha[x$valid_area_ha<=0]<-NA_real_
    x$coverage_pct<-100*x$valid_area_ha/x$polygon_area_ha
    x$source_id<-'VIC_LANDCOVER_TS_2020';x$area_index<-NULL
    summaries[[i]]<-x
    audits[[i]]<-list(filename=basename(f),bytes=unname(file.info(f)$size),md5=unname(tools::md5sum(f)),
      crs='EPSG:3111',resolution_m=terra::res(r),origin=terra::origin(r),extent=as.vector(terra::ext(r)),
      rows=terra::nrow(r),columns=terra::ncol(r),nodata_flag=source_nodata,maximum_nodata_area_ha=max(nodata),
      maximum_numerical_area_residual_ha=max(abs(numerical_residual)),
      min_valid_coverage_pct=min(x$coverage_pct),class_codes=codes)
  }
  epochs<-do.call(rbind,epochs);x<-do.call(rbind,summaries)
  changes<-do.call(rbind,definition_changes)
  if(is.null(changes)) changes<-data.frame(source_filename=character(),class_code=integer(),initial_description=character(),epoch_description=character())
  write.csv(changes,file.path(out,'metadata_description_changes.csv'),row.names=FALSE)
  # Bind the prepared release to both the source archive and analytical boundaries.
  release<-paste0('VLCTS2020-',substr(unname(tools::md5sum(zip)),1,12),'-',substr(unname(tools::md5sum(boundary_path)),1,8))
  x$data_release<-release
  stopifnot(nrow(x)==nrow(repaired)*7*19,!anyDuplicated(x[c('microID','epoch_id','class_code')]))
  temporary<-tempfile(tmpdir=out,fileext='.csv.gz');con<-gzfile(temporary,'wt');write.csv(x,con,row.names=FALSE,na='');close(con)
  if(!file.rename(temporary,file.path(out,'summary.csv.gz'))) stop('Could not save summaries')
  write.csv(classes[classes$class_code>0,],file.path(out,'classes.csv'),row.names=FALSE,na='')
  write.csv(epochs,file.path(out,'epochs.csv'),row.names=FALSE)
  manifest<-list(release=release,created_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
    download_url=url,archive_bytes=unname(file.info(zip)$size),archive_md5=unname(tools::md5sum(zip)),
    source_metadata='https://metashare.maps.vic.gov.au/geonetwork/srv/api/records/81726131-7c8d-52b9-a243-d6a8429966e2/formatters/xml',
    attribution='State of Victoria (Department of Energy, Environment and Climate Action)',licence='CC BY 4.0',
    licence_url='https://creativecommons.org/licenses/by/4.0/',
    boundary_source='SMP4_summary_areas/MapServer/0',boundary_md5=unname(tools::md5sum(boundary_path)),
    spatial_cache_md5=unname(tools::md5sum('data/smp_cache.rds')),
    geometry=list(original_invalid=sum(!sf::st_is_valid(projected)),repaired_invalid=sum(!sf::st_is_valid(repaired)),
      maximum_repair_area_change_m2=max(abs(as.numeric(sf::st_area(repaired))-pre_area)),
      interior_overlap_pairs=nrow(overlap),overlap_pairs_above_1m2=sum(overlap$overlap_ha>.0001)),
    denominator='Classified area, codes 1-19, within each unit and epoch. Code 0 is unclassified and excluded; NoData or outside coverage is separate.',
    area_method='Exact polygon-cell class fractions times projected polygon area. Fraction sums normalised after raster coverage closure within 0.1 ha; NoData sentinel preserved separately; units wholly inside raster rectangle. Grid hectares in EPSG:3111, not geodesic hectares.',
    boundary_method='Original source vertices transformed to EPSG:3111 then GEOS make-valid. No simplification for analysis. Units overlap and must not be summed to statewide totals.',
    epoch_note='Downloaded filenames and START_YEAR/END_YEAR use 1985-1990; catalogue says 1987-1990. App follows downloaded metadata.',
    transition_analysis=FALSE,aligned=TRUE,class_label_and_group_consistency=TRUE,metadata_description_variants=nrow(changes),rasters=audits,rows=nrow(x),units=nrow(repaired),epochs=nrow(epochs),classes=19,
    summary_md5=unname(tools::md5sum(file.path(out,'summary.csv.gz'))),
    processing_elapsed_seconds=as.numeric(difftime(Sys.time(),started,units='secs')))
  jsonlite::write_json(manifest,file.path(out,'manifest.json'),auto_unbox=TRUE,pretty=TRUE,na='null')
  message('Saved ',nrow(x),' rows. Release: ',release)
  invisible(x)
}
if(sys.nframe()==0) prepare_landcover()
