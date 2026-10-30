# Shared labels, formatting helpers and colour scales used throughout the app.
`%||%` <- function(x,y) if(is.null(x)) y else x
# Format display prose while retaining original identifiers and source values.
display_text <- function(x) {
  x <- gsub('([0-9]{4})[-\u2013\u2014]([0-9]{4})', '\\1 to \\2', x, perl=TRUE)
  trimws(gsub('[[:space:]]+', ' ', gsub('[-\u2013\u2014]', ' ', x, perl=TRUE)))
}
action_labels <- c('Control Foxes'='Fox control','Control Cats'='Feral cat control','Control Deer'='Deer control',
  'Control Rabbits'='Rabbit control','Control All Weeds'='All weeds control','Control Woody Weeds'='Woody weeds control',
  'Control Non-Woody Weeds'='Non woody weeds control','Control Grazing'='Livestock grazing control',
  'Control Goats'='Goat control','Control Horses'='Horse control','Control Pigs'='Pig control',
  'Control Overabundant Kangaroos'='Overabundant kangaroo control','Ecological Burning'='Ecological burning',
  'Restore Wetland'='Wetland restoration','Revegetate'='Revegetation','Permanent Protection'='Permanent protection')
ink <- '#203c32'
rank_palette <- grDevices::colorRampPalette(c('#edf2df','#b8d398','#6fa577','#285f47'))(101)
rank_colour <- function(rank) ifelse(is.na(rank),'#e1e3df',rank_palette[pmax(1,pmin(101,as.integer(rank)+1))])
rank_legend <- function() htmltools::HTML(paste0(
  '<strong>Relative rank</strong><div class="rank-gradient" role="img" aria-label="Continuous pale to dark green scale from rank 0 to 100"></div>',
  '<div class="rank-ticks"><span>0</span><span>50</span><span>100</span></div>',
  '<div class="rank-missing"><i></i>No action record</div>'))
number <- function(x, digits=0) format(round(x,digits),big.mark=',',trim=TRUE,scientific=FALSE,nsmall=digits)
# Keep small measured values distinct from exact zero at the displayed precision.
format_measure <- function(value, suffix='', digits=1, zero_tolerance=0) {
  value[!is.na(value) & abs(value)<zero_tolerance] <- 0
  label <- paste0(number(value,digits),suffix)
  tiny <- !is.na(value) & value != 0 & round(abs(value),digits)==0
  label[tiny] <- paste0(ifelse(value[tiny]<0,'-',''),'<',number(10^-digits,digits),suffix)
  label[is.na(value)] <- 'No classified coverage'
  label
}
unit_name <- function(id) paste('Unit',sub('unit','',id,fixed=TRUE))
# Load the saved spatial snapshot and verify its compatibility with the land cover release.
# Source action values are retained; missing records remain missing.
load_atlas <- function() {
  requireNamespace('sf', quietly=TRUE)
  d <- readRDS('data/smp_cache.rds')
  d$areas <- d$areas[order(as.integer(sub('unit','',d$areas$microID))),]
  d$landcover <- load_landcover()
  if(!is.null(d$landcover)) d$spatial_release_validation <- validate_spatial_release(d,d$landcover)
  d$actions$share5 <- 100*d$actions$AREA_5/d$actions$AREA_TOT
  d$actions$share15 <- 100*d$actions$AREA_20/d$actions$AREA_TOT
  d$release_id <- paste0('SMP4-',d$retrieved,'-',substr(unname(tools::md5sum('data/smp_cache.rds')),1,12))
  stopifnot(!anyDuplicated(paste(d$actions$microID,d$actions$Action)),all(d$actions$microID %in% d$areas$microID))
  d
}
# Match the chosen action to every map area by its stable identifier.
map_spec <- function(d, action) {
  rows <- d$actions[d$actions$Action==action,]
  values <- rows$CE_RANK[match(d$areas$microID,rows$microID)]
  list(field='CE_RANK',label='Cost effectiveness rank',unit='rank',
    values=values,limit=100,colours=rank_colour(values),
    formatted=ifelse(is.na(values),'No action record',paste('Rank',number(values),'(0 to 100 scale)')))
}
map_legend <- function(s) htmltools::HTML(paste0('<strong>',s$label,'</strong>',
  '<div class="rank-gradient" role="img" aria-label="Pale to dark green from zero to ',number(s$limit),' ',s$unit,'"></div>',
  '<div class="rank-ticks"><span>0 \u00b7 Lower</span><span>',number(s$limit/2),'</span><span>',number(s$limit),' \u00b7 Higher</span></div>',
  '<div class="rank-missing"><i></i>No action record</div>'))
# Accept only the expected Tableau Public dashboard URL.
tableau_config <- function(path='config/app.json') {
  config <- if(file.exists(path)) jsonlite::fromJSON(path) else list()
  url <- trimws(Sys.getenv('TABLEAU_VIEW_URL',if(is.null(config$tableau_view_url)) '' else config$tableau_view_url))
  valid <- grepl('^https://public[.]tableau[.]com/views/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/?([?][^#[:space:]]*)?$',url)
  valid <- valid && grepl('/LandscapeChange/?([?].*)?$',url)
  list(url=if(valid) sub('[?].*$','',url) else '',configured=nzchar(url),valid=valid)
}
action_row <- function(d,id,action) d$actions[d$actions$microID==id & d$actions$Action==action,,drop=FALSE]
compare_rows <- function(d,ids,action) {
  x <- data.frame(microID=ids,stringsAsFactors=FALSE)
  merge(x,d$actions[d$actions$Action==action,],by='microID',all.x=TRUE,sort=FALSE)
}
# Give the local charts a common background, type size and grid style.
chart_theme <- function() ggplot2::theme_minimal(base_size=13,base_family='sans') +
  ggplot2::theme(text=ggplot2::element_text(colour=ink),panel.grid.minor=ggplot2::element_blank(),
    panel.grid.major.x=ggplot2::element_blank(),plot.background=ggplot2::element_rect(fill='#f7f6f1',colour=NA),
    panel.background=ggplot2::element_rect(fill='#f7f6f1',colour=NA),legend.position='bottom',
    strip.text=ggplot2::element_text(face='bold',hjust=0),plot.margin=ggplot2::margin(14,24,14,10))

# Choose the higher contrast foreground; all palette cells exceed WCAG AA for normal text.
cell_text_colour <- function(background) {
  rgb <- grDevices::col2rgb(background)/255
  linear <- ifelse(rgb<=.04045,rgb/12.92,((rgb+.055)/1.055)^2.4)
  luminance <- colSums(linear*c(.2126,.7152,.0722))
  ifelse((luminance+.05)/.05 >= 1.05/(luminance+.05),'#000000','#ffffff')
}
