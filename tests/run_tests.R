# Run from project root: Rscript tests/run_tests.R
source('R/landcover.R');source('R/data.R');source('R/landscape_server.R');source('R/server.R')
d <- load_atlas()
checks <- 0L
check <- function(condition,label) {stopifnot(condition);checks <<- checks+1L;cat('PASS',label,'\n')}
check(nrow(d$areas)==1053,'snapshot area count')
check(nrow(d$actions)==12403,'snapshot action count')
check(identical(format_measure(c(0,.00012,-.00012,1.24,NA),'%'),c('0.0%','<0.1%','-<0.1%','1.2%','No classified coverage')),'small nonzero values remain distinct from zero and missing data')
check(identical(format_measure(c(-1e-11,1e-11),zero_tolerance=1e-8),c('0.0','0.0')) && format_measure(1e-11)=='<0.1','change formatting suppresses numerical residuals without erasing small source percentages')
check(setequal(names(action_labels),unique(d$actions$Action)),'all management action controls retain their source identifiers')
check(!anyDuplicated(paste(d$actions$microID,d$actions$Action)),'unique area/action grain')
check(all(d$actions$microID %in% d$areas$microID),'complete action-to-boundary join')
check(all(sf::st_is_valid(d$areas)) && !any(sf::st_is_empty(d$areas)),'valid nonempty display geometry')
check(all(d$actions$AREA_5<=d$actions$AREA_20 & d$actions$AREA_20<=d$actions$AREA_TOT),'nested opportunity areas')
check(nrow(action_row(d,'unit925','Control Foxes'))==0,'missing record stays missing')
r <- action_row(d,'unit668','Control Foxes')
check(r$CE_RANK==88 && r$AREA_20==3855,'verified Unit 668 reference values')
check(abs(r$share15-52.5993)<.0001,'opportunity share denominator')
check(all(is.na(compare_rows(d,'unit925','Control Foxes')$CE_RANK)),'comparison retains missing area')
shiny::testServer(atlas_server(d), {
  session$setInputs(area='unit668',action='Control Foxes',land_area='unit668',land_class='12',start_epoch='1985_1990',end_epoch='2015_2019',land_metric='share')
  check(focus()$CE_RANK==88,'server selection matches data')
  detail<-paste(as.character(output$area_detail),collapse='');grid<-paste(as.character(output$heatmap),collapse='')
  check(grepl('Selected action: Fox control',detail) && !grepl('Top 5%|Top 15%|Area extent in top ranks',paste(detail,grid)), 'priority detail and action grid contain rank and hectares without threshold categories')
  check(grepl('Source rank range: 16 to 98',detail),'source rank range retains a readable separator')
  session$setInputs(area='unit925',pin=1)
  check(identical(shown_ids()[1],'unit925'),'main area comes first in tables and local chart colour slots')
  check(nrow(focus())==0 && 'unit925' %in% pins(),'missing unit can be selected and compared')
  session$setInputs(area='unit1',pin=2)
  check(length(pins())==3 && !('unit1' %in% pins()),'three-area pin limit')
  session$setInputs(remove_pin='unit925')
  check(length(pins())==2,'remove pin')
  session$setInputs(clear=1)
  check(length(pins())==0,'clear comparison')
  session$setInputs(area='unit375',action='Control Foxes')
  check(focus()$CE_RANK==88 && abs(focus()$share15-97.9825)<.0001,'second reference area')
})


# Additional behaviours introduced by the completed atlas and Tableau data contract.
rank_map <- map_spec(d,'Control Foxes')
check(rank_map$limit==100 && map_spec(d,'Control Cats')$limit==100,'priority rank scale stays fixed across actions')
idx <- match('unit668',d$areas$microID)
check(rank_map$values[idx]==88 && rank_map$colours[idx]==rank_colour(88),'priority map uses the supplied cost-effectiveness rank')
check(is.na(rank_map$values[match('unit925',d$areas$microID)]),'missing action stays missing on the priority map')
check(map_spec(d,'Control Cats')$values[idx]==97,'changing action updates the mapped rank')
# Verify normal-size text contrast for every palette colour and the missing-data cell.
lum <- function(col) {r<-grDevices::col2rgb(col)/255;l<-ifelse(r<=.04045,r/12.92,((r+.055)/1.055)^2.4);colSums(l*c(.2126,.7152,.0722))}
background <- c(rank_palette,'#e1e3df');foreground<-cell_text_colour(background)
contrast <- (pmax(lum(background),lum(foreground))+.05)/(pmin(lum(background),lum(foreground))+.05)
check(all(contrast>=4.5),'every heatmap label meets AA text contrast')

lc<-d$landcover;check(!is.null(lc),'prepared land-cover release loads')
x<-lc$summary
check(nrow(x)==1053*7*19,'complete unit x epoch x class grain')
check(!anyDuplicated(x[c('microID','epoch_id','class_code')]),'unique land-cover keys')
check(identical(lc$epochs$epoch_label,c('1985-1990','1990-1995','1995-2000','2000-2005','2005-2010','2010-2015','2015-2019')),'epochs follow downloaded filenames and raster attributes')
check(all(x$class_code %in% 1:19) && all(is.na(x$area_ha)|x$area_ha>=0),'classified codes and nonnegative areas')
check(all(x$share_pct>=0 & x$share_pct<=100,na.rm=TRUE),'class shares remain bounded')
a<-aggregate(area_ha~microID+epoch_id,x,sum);v<-x[!duplicated(x[c('microID','epoch_id')]),]
joined<-merge(a,v[c('microID','epoch_id','valid_area_ha')],by=c('microID','epoch_id'))
check(all(abs(joined$area_ha-joined$valid_area_ha)<1e-6),'19 classes close to classified denominator')
shares<-aggregate(share_pct~microID+epoch_id,x,sum)
check(all(abs(shares$share_pct-100)<1e-7),'class shares total 100 within each covered unit and epoch')
check(all(abs(v$valid_area_ha+v$unclassified_area_ha+v$nodata_area_ha-v$polygon_area_ha)<1e-6),'classified plus unclassified plus NoData closes to polygon')
check(any(x$area_ha==0) && all(!is.na(x$share_pct[x$area_ha==0])),'genuine absent class is zero with a known denominator')
check(all(x$valid_area_ha[x$microID=='unit925']>0),'missing SMP action does not erase independent land-cover evidence')
check(lc$manifest$geometry$overlap_pairs_above_1m2==4,'source overlaps are explicitly audited')
check(all(v$nodata_area_ha>=0) && any(v$nodata_area_ha>0),'NoData retained separately from code zero')
c<-landcover_change(d,c('unit668','unit375'),'1985_1990','2015_2019',12)
check(nrow(c)==2 && all(abs(c$change_pp-(c$share_pct_end-c$share_pct_start))<1e-9),'net change is endpoint subtraction in percentage points')
check(inherits(try(landcover_change(d,'unit668','2015_2019','1985_1990'),silent=TRUE),'try-error'),'reversed epochs are rejected')
check(inherits(try(landcover_change(d,'unit668','1985_1990','1985_1990'),silent=TRUE),'try-error'),'identical endpoints are rejected')
no_coverage<-d;no_coverage$landcover$summary$area_ha[no_coverage$landcover$summary$microID=='unit668']<-NA
no_coverage$landcover$summary$share_pct[no_coverage$landcover$summary$microID=='unit668']<-NA
check(all(is.na(landcover_change(no_coverage,'unit668','1985_1990','2015_2019')$change_pp)),'missing coverage never becomes zero change')
s<-landcover_map_spec(d,12,'1985_1990','2015_2019','share');t<-landcover_map_spec(d,12,'1985_1990','2015_2019','change')
check(length(s$values)==1053 && length(t$colours)==1053,'land-cover map aligns by microID')
check(abs(s$values[match('unit668',d$areas$microID)]-c$share_pct_end[c$microID=='unit668'])<1e-9,'map and comparison use identical values')
config_file<-tempfile(fileext='.json');writeLines('{"tableau_view_url":"https://public.tableau.com/views/Victoria/LandscapeChange?:showVizHome=no"}',config_file)
check(tableau_config(config_file)$valid,'landscape dashboard URL accepted')
writeLines('{"tableau_view_url":"https://public.tableau.com/views/Biodiversity/ProgressOverview"}',config_file)
check(!tableau_config(config_file)$valid,'old PDF dashboard cannot be configured as landscape')
writeLines('{"tableau_view_url":"https://public.tableau.com.evil.example/views/Victoria/LandscapeChange"}',config_file)
check(!tableau_config(config_file)$valid,'lookalike host rejected');unlink(config_file)
# Independent fractional-cell fixture: classified, unclassified and actual NoData.
if(requireNamespace('terra',quietly=TRUE) && requireNamespace('exactextractr',quietly=TRUE)) {
  r<-terra::rast(nrow=2,ncol=2,xmin=0,xmax=50,ymin=0,ymax=50,crs='EPSG:3111');terra::values(r)<-c(1,2,0,NA)
  p<-sf::st_as_sf(terra::vect('POLYGON ((0 0, 30 0, 30 50, 0 50, 0 0))',crs='EPSG:3111'))
  z<-exactextractr::exact_extract(r,p,c('count','frac'),default_value=-9999,progress=FALSE)
  check(abs(z$frac_1*z$count*.0625-.0625)<1e-7 && abs(z$frac_2*z$count*.0625-.0125)<1e-7,'partial boundary cells retain exact fractional classified area')
  check(abs(z$frac_0*z$count*.0625-.0625)<1e-7 && abs(z[['frac_-9999']]*z$count*.0625-.0125)<1e-7,'fixture distinguishes unclassified zero and NoData')
  # Compare an independent terra extraction against the prepared exactextractr output.
  rawfile<-'data/downloads/landcover/VIC_LANDCOVER_TS/VIC_LANDCOVER_TS_1985_90.tif'
  if(file.exists(rawfile)) {
    original<-sf::st_make_valid(sf::st_transform(readRDS('data/downloads/smp_original.rds'),3111))
    original<-original[original$microID=='unit668',];r<-terra::rast(rawfile);levels(r)<-NULL
    z<-terra::extract(r,terra::vect(original),fun=table,exact=TRUE)
    code<-z[[2]];expected<-x[x$microID=='unit668' & x$epoch_id=='1985_1990',]
    actual<-setNames(z$count*.0625,as.character(code));prepared<-expected$area_ha[match(code,expected$class_code)]
    check(all(abs(actual-prepared)<.002,na.rm=TRUE),'real Unit 668 class areas agree with independent terra exact extraction within 20 square metres')
  }
} else cat('SKIP optional preparation fixtures and raw raster re-extraction: terra and exactextractr are both required.\n')
check(t$limit>=max(abs(t$values),na.rm=TRUE) && t$limit>=1,'change map uses a labelled symmetric range covering all units')
tiny_map<-landcover_map_spec(d,1,'1985_1990','2015_2019','share')
check(grepl('<0.1%',tiny_map$formatted[match('unit668',d$areas$microID)],fixed=TRUE),'map tooltip preserves small nonzero cover')
source('R/landscape_ui.R');source('R/ui.R')
html<-as.character(atlas_ui(d))
check(grepl('Explore landscape change',html) && !grepl('Review progress|Reported management|Target ha',html),'new navigation and sources replace the PDF core')
check(!grepl('map_metric|extent_unit|Compare opportunity extent|Top.?5%|Top.?15%',html),'priority threshold controls and bars are absent from the interface')
check(!grepl('map_context|land_context|Show place labels online',html),'place label controls are absent from both maps')
check(!any(grepl('addProviderTiles|map_context|land_context',c(readLines('R/server.R'),readLines('R/landscape_server.R')))),'online place label layers and handlers are removed')
cat('TOTAL',checks,'checks passed.\n')
