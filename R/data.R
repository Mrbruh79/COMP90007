action_labels <- c('Control Foxes'='Foxes','Control Cats'='Cats','Control Deer'='Deer',
  'Control Rabbits'='Rabbits','Control All Weeds'='All weeds','Control Woody Weeds'='Woody weeds',
  'Control Non-Woody Weeds'='Non-woody weeds','Control Grazing'='Domestic stock',
  'Control Goats'='Goats','Control Horses'='Horses','Control Pigs'='Pigs',
  'Control Overabundant Kangaroos'='Kangaroos','Ecological Burning'='Ecological burning',
  'Restore Wetland'='Wetland restoration','Revegetate'='Revegetation','Permanent Protection'='Protection')
ink <- '#203c32'
rank_palette <- grDevices::colorRampPalette(c('#edf2df','#b8d398','#6fa577','#285f47'))(101)
rank_colour <- function(rank) ifelse(is.na(rank),'#e1e3df',rank_palette[pmax(1,pmin(101,as.integer(rank)+1))])
rank_legend <- function() htmltools::HTML(paste0(
  '<strong>Relative rank</strong><div class="rank-gradient" role="img" aria-label="Continuous pale to dark green scale from rank 0 to 100"></div>',
  '<div class="rank-ticks"><span>0</span><span>50</span><span>100</span></div>',
  '<div class="rank-missing"><i></i>No action record</div>'))
number <- function(x, digits=0) format(round(x,digits),big.mark=',',trim=TRUE,scientific=FALSE,nsmall=digits)
unit_name <- function(id) paste('Unit',sub('unit','',id,fixed=TRUE))
load_atlas <- function() {
  requireNamespace('sf', quietly=TRUE)
  d <- readRDS('data/smp_cache.rds')
  d$areas <- d$areas[order(as.integer(sub('unit','',d$areas$microID))),]
  d$activity <- read.csv('data/activity.csv',stringsAsFactors=FALSE)
  d$actions$share5 <- 100*d$actions$AREA_5/d$actions$AREA_TOT
  d$actions$share15 <- 100*d$actions$AREA_20/d$actions$AREA_TOT
  stopifnot(!anyDuplicated(paste(d$actions$microID,d$actions$Action)),all(d$actions$microID %in% d$areas$microID))
  d
}
action_row <- function(d,id,action) d$actions[d$actions$microID==id & d$actions$Action==action,,drop=FALSE]
annual_progress <- function(d,year=NULL) {
  x <- d$activity[d$activity$basis=='annual' & d$activity$coverage=='priority',]
  if (!is.null(year)) x <- x[x$financial_year==year,]
  x$attainment <- 100*x$area_ha/x$target_ha
  x$gap_pp <- 100-x$attainment
  x
}
compare_rows <- function(d,ids,action) {
  x <- data.frame(microID=ids,stringsAsFactors=FALSE)
  merge(x,d$actions[d$actions$Action==action,],by='microID',all.x=TRUE,sort=FALSE)
}
chart_theme <- function() ggplot2::theme_minimal(base_size=13,base_family='sans') +
  ggplot2::theme(text=ggplot2::element_text(colour=ink),panel.grid.minor=ggplot2::element_blank(),
    panel.grid.major.x=ggplot2::element_blank(),plot.background=ggplot2::element_rect(fill='#f7f6f1',colour=NA),
    panel.background=ggplot2::element_rect(fill='#f7f6f1',colour=NA),legend.position='bottom',
    strip.text=ggplot2::element_text(face='bold',hjust=0),plot.margin=ggplot2::margin(14,24,14,10))
