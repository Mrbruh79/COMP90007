# Build the scope-safe Tableau input from the attributed source CSV. No spatial data is published.
source('R/data.R')
x <- read.csv('data/activity.csv',stringsAsFactors=FALSE)
stopifnot(nrow(x)==52,!anyDuplicated(x[c('action','financial_year','coverage')]))
statewide <- x[x$coverage=='statewide' & x$action!='Permanent protection',]
pieces <- aggregate(area_ha~action+financial_year,x[x$coverage!='statewide',],sum)
joined <- merge(statewide,pieces,by=c('action','financial_year'))
stopifnot(nrow(joined)==16,all(joined$area_ha.x==joined$area_ha.y))
release <- paste0('B2037-2018-2022-',substr(unname(tools::md5sum('data/activity.csv')),1,12))
p <- progress_dataset(list(activity=x,activity_release=release))
stopifnot(nrow(p)==20,!anyDuplicated(p[c('action','financial_year')]),
  all(p$priority_share_pct[p$basis=='annual']>=0 & p$priority_share_pct[p$basis=='annual']<=100))
dir.create('tableau/data',recursive=TRUE,showWarnings=FALSE)
write.csv(p,'tableau/data/progress.csv',row.names=FALSE,na='')
jsonlite::write_json(list(release=release,source_md5=unname(tools::md5sum('data/activity.csv')),
  chart_input_md5=unname(tools::md5sum('tableau/data/progress.csv')),source_rows=nrow(x),chart_rows=nrow(p),
  source_url=x$source_url[1],printed_pages=sort(unique(x$source_pdf_page)),
  transformations=c('Annual: priority coverage only','Cumulative: priority revegetation and statewide permanent protection',
    'Priority share: matching priority hectares / statewide hectares',
    'Attainment: scope-matched reported hectares / target hectares; percentage-point gap = 100 - attainment')),
  'tableau/data/manifest.json',auto_unbox=TRUE,pretty=TRUE)
message('Prepared 20 action-year rows. Release: ',release)
