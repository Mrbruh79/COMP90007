# Build a portable long table for genuine Tableau temporal views.
source('R/landcover.R')
lc<-load_landcover();stopifnot(!is.null(lc))
x<-lc$summary
x$unit_label<-paste('Unit',sub('unit','',x$microID,fixed=TRUE))
x<-x[c('microID','unit_label','epoch_id','epoch_label','epoch_start','epoch_end','class_code','class_label','class_group',
       'area_ha','share_pct','valid_area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha','data_release')]
dir.create('tableau/data',recursive=TRUE,showWarnings=FALSE)
write.csv(x,'tableau/data/landcover.csv',row.names=FALSE,na='')
jsonlite::write_json(list(release=lc$manifest$release,chart_rows=nrow(x),chart_input_md5=unname(tools::md5sum('tableau/data/landcover.csv')),
  source_summary_md5=lc$manifest$summary_md5,dashboard='LandscapeChange',
  grain='microID x historical epoch x classified land-cover class',
  no_statewide_sums=TRUE,attribution=lc$manifest$attribution,licence='CC BY 4.0'),
  'tableau/data/manifest.json',auto_unbox=TRUE,pretty=TRUE)
message('Prepared ',nrow(x),' Tableau rows from ',lc$manifest$release)
