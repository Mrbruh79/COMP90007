# Runtime summaries only. The full-resolution overlay lives in scripts/prepare_landcover.R.
load_landcover <- function(path='data/landcover') {
  if(!file.exists(file.path(path,'summary.csv.gz'))) return(NULL)
  x <- read.csv(gzfile(file.path(path,'summary.csv.gz')),stringsAsFactors=FALSE)
  classes <- read.csv(file.path(path,'classes.csv'),stringsAsFactors=FALSE)
  epochs <- read.csv(file.path(path,'epochs.csv'),stringsAsFactors=FALSE)
  manifest <- jsonlite::fromJSON(file.path(path,'manifest.json'))
  stopifnot(!anyDuplicated(x[c('microID','epoch_id','class_code')]),
    all(x$class_code %in% classes$class_code),all(x$epoch_id %in% epochs$epoch_id),
    all(x$data_release==manifest$release),
    identical(unname(tools::md5sum(file.path(path,'summary.csv.gz'))),manifest$summary_md5))
  x$class_label <- classes$class_label[match(x$class_code,classes$class_code)]
  x$class_group <- classes$class_group[match(x$class_code,classes$class_code)]
  x$epoch_label <- epochs$epoch_label[match(x$epoch_id,epochs$epoch_id)]
  x$epoch_start <- epochs$epoch_start[match(x$epoch_id,epochs$epoch_id)]
  x$epoch_end <- epochs$epoch_end[match(x$epoch_id,epochs$epoch_id)]
  # Deliberately restrained categorical colours; labels remain the primary key.
  classes$colour <- c('#555b54','#8a9087','#a58c78','#c6be85','#c6a352','#7d8f51','#876b4f',
    '#879d6e','#5a8974','#9db56b','#6d995b','#285f47','#759779','#ccc2a8','#9f7b63',
    '#6b9f91','#658da5','#8ab8ad','#3b807d')
  list(summary=x,classes=classes,epochs=epochs,manifest=manifest)
}
landcover_change <- function(d,ids,from,to,class_code=NULL) {
  stopifnot(!is.null(d$landcover))
  epochs<-d$landcover$epochs
  if(!from %in% epochs$epoch_id || !to %in% epochs$epoch_id ||
     match(from,epochs$epoch_id)>=match(to,epochs$epoch_id)) stop('Choose an earlier period before the later period.')
  x<-d$landcover$summary
  x<-x[x$microID %in% ids & (is.null(class_code) | x$class_code %in% class_code),]
  a<-x[x$epoch_id==from,];b<-x[x$epoch_id==to,]
  keep<-c('microID','class_code','class_label','area_ha','share_pct','valid_area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha')
  out<-merge(a[keep],b[keep],by=c('microID','class_code','class_label'),suffixes=c('_start','_end'),all=TRUE,sort=FALSE)
  out$change_ha<-out$area_ha_end-out$area_ha_start
  out$change_pp<-out$share_pct_end-out$share_pct_start
  out$start_epoch<-from;out$end_epoch<-to;out$data_release<-d$landcover$manifest$release
  out$area_basis<-'EPSG:3111 projected grid hectares; exact boundary-cell fractions'
  out$share_basis<-'Classified area (codes 1-19) in each unit and epoch; no combined-area totals'
  out[order(match(out$microID,ids),out$class_code),]
}
landcover_map_spec <- function(d,code,from,to,metric='share') {
  x<-landcover_change(d,d$areas$microID,from,to,code)
  x<-x[match(d$areas$microID,x$microID),]
  vals<-if(metric=='change') x$change_pp else x$share_pct_end
  pal<-if(metric=='change') grDevices::colorRampPalette(c('#9a613b','#f7f6f1','#285f47'))(201) else rank_palette
  limit<-if(metric=='change') max(1,ceiling(max(c(0,abs(vals)),na.rm=TRUE))) else 100
  index<-if(metric=='change') pmax(1,pmin(201,round(100*vals/limit)+101)) else pmax(1,pmin(101,round(vals)+1))
  colours<-ifelse(is.na(vals),'#e1e3df',pal[index])
  label<-if(metric=='change') 'Change in cover (percentage points)' else 'Cover in later period (%)'
  list(values=vals,colours=colours,rows=x,label=label,metric=metric,limit=limit,
    formatted=ifelse(is.na(vals),'No classified coverage',paste0(ifelse(metric=='change' & vals>0,'+',''),number(vals,1),if(metric=='change') ' percentage points' else '%')))
}
landcover_legend <- function(s) htmltools::HTML(paste0('<strong>',s$label,'</strong>',
  '<div class="land-gradient ',if(s$metric=='change') 'diverging' else '', '" role="img" aria-label="',s$label,'"></div>',
  '<div class="rank-ticks">',if(s$metric=='change') paste0('<span>-',number(s$limit),'</span><span>0</span><span>+',number(s$limit),'</span>') else '<span>0%</span><span>50%</span><span>100%</span>',
  '</div>',if(s$metric=='change') '<div class="rank-ticks land-directions"><span>Decrease</span><span>Increase</span></div>' else '',
  '<div class="rank-missing"><i></i>No classified coverage</div>'))
