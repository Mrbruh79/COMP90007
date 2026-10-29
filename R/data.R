`%||%` <- function(x,y) if(is.null(x)) y else x
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
  d$activity_release <- paste0('B2037-2018-2022-',substr(unname(tools::md5sum('data/activity.csv')),1,12))
  d$actions$share5 <- 100*d$actions$AREA_5/d$actions$AREA_TOT
  d$actions$share15 <- 100*d$actions$AREA_20/d$actions$AREA_TOT
  d$release_id <- paste0('SMP4-',d$retrieved,'-',substr(unname(tools::md5sum('data/smp_cache.rds')),1,12))
  stopifnot(!anyDuplicated(paste(d$actions$microID,d$actions$Action)),all(d$actions$microID %in% d$areas$microID))
  d
}
map_spec <- function(d, action, metric='rank') {
  choices <- list(rank=list(field='CE_RANK',label='Median cost-effectiveness rank',unit='rank'),
    share15=list(field='share15',label='Top-15% share of relevant area',unit='%'),
    hectares=list(field='AREA_20',label='Top-15% opportunity extent',unit='ha'))
  if (!metric %in% names(choices)) metric <- 'rank'
  s <- choices[[metric]]
  rows <- d$actions[d$actions$Action==action,]
  s$values <- rows[[s$field]][match(d$areas$microID,rows$microID)]
  s$limit <- if(metric=='hectares') max(c(1,s$values),na.rm=TRUE) else 100
  s$colours <- rank_colour(100*s$values/s$limit)
  s$formatted <- ifelse(is.na(s$values),'No action record',paste(number(s$values,if(metric=='share15') 1 else 0),s$unit))
  s
}
map_legend <- function(s) htmltools::HTML(paste0('<strong>',s$label,'</strong>',
  '<div class="rank-gradient" role="img" aria-label="Pale to dark green from zero to ',number(s$limit),' ',s$unit,'"></div>',
  '<div class="rank-ticks"><span>0</span><span>',number(s$limit/2),'</span><span>',number(s$limit),'</span></div>',
  '<div class="rank-missing"><i></i>No action record</div>'))
tableau_config <- function(path='config/app.json') {
  config <- if(file.exists(path)) jsonlite::fromJSON(path) else list()
  url <- trimws(Sys.getenv('TABLEAU_VIEW_URL',if(is.null(config$tableau_view_url)) '' else config$tableau_view_url))
  valid <- grepl('^https://public[.]tableau[.]com/views/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/?([?][^#[:space:]]*)?$',url)
  list(url=if(valid) sub('[?].*$','',url) else '',configured=nzchar(url),valid=valid)
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

# Choose the higher-contrast foreground; all palette cells exceed WCAG AA for normal text.
cell_text_colour <- function(background) {
  rgb <- grDevices::col2rgb(background)/255
  linear <- ifelse(rgb<=.04045,rgb/12.92,((rgb+.055)/1.055)^2.4)
  luminance <- colSums(linear*c(.2126,.7152,.0722))
  ifelse((luminance+.05)/.05 >= 1.05/(luminance+.05),'#000000','#ffffff')
}
progress_dataset <- function(d) {
  x <- d$activity
  annual <- x[x$basis=='annual' & x$coverage=='priority',]
  cumulative <- x[x$basis=='cumulative_since_2017' &
    ((x$action=='Revegetation' & x$coverage=='priority') | x$action=='Permanent protection'),]
  result <- rbind(annual,cumulative)
  totals <- x[x$coverage=='statewide',]
  key <- function(z) paste(z$action,z$financial_year)
  result$statewide_ha <- totals$area_ha[match(key(result),key(totals))]
  result$priority_share_pct <- ifelse(result$basis=='annual',100*result$area_ha/result$statewide_ha,NA_real_)
  result$attainment_pct <- 100*result$area_ha/result$target_ha
  result$gap_pp <- 100-result$attainment_pct
  result$shortfall_ha <- pmax(0,result$target_ha-result$area_ha)
  result$above_target_ha <- pmax(0,result$area_ha-result$target_ha)
  result$data_release <- d$activity_release
  result[order(result$action,result$period_end_year),]
}
