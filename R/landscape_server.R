# Link the landscape map, selected area statistics, historical charts and Tableau parameters.
landscape_server <- function(d,input,output,session,selected,pins,shown_ids,notice) {
  library(shiny)
  if(is.null(d$landcover)) return(invisible(NULL))
  e<-d$landcover$epochs;classes<-d$landcover$classes
  # Reject reversed or identical endpoints before calculating a comparison.
  valid_period <- reactive({
    req(input$start_epoch %in% e$epoch_id,input$end_epoch %in% e$epoch_id)
    validate(need(match(input$start_epoch,e$epoch_id)<match(input$end_epoch,e$epoch_id),'Choose an earlier period before the later period.'))
    list(from=input$start_epoch,to=input$end_epoch)
  })
  chosen_class<-reactive({req(input$land_class %in% classes$class_code);as.integer(input$land_class)})
  class_label<-reactive(classes$class_label[match(chosen_class(),classes$class_code)])
  period_label<-reactive({p<-valid_period();paste(display_text(e$epoch_label[match(p$from,e$epoch_id)]),'to',display_text(e$epoch_label[match(p$to,e$epoch_id)]))})
  # Synchronise area selection between the priority and landscape workspaces.
  observeEvent(input$land_area,{
    if(input$land_area %in% d$areas$microID && !identical(input$land_area,input$area))
      updateSelectizeInput(session,'area',selected=input$land_area)
  })
  observeEvent(input$area,{
    if(input$area %in% d$areas$microID && !identical(input$area,input$land_area))
      updateSelectizeInput(session,'land_area',selected=input$area)
  })
  # Offer only later periods that follow the chosen starting period.
  observeEvent(input$start_epoch,{
    i<-match(input$start_epoch,e$epoch_id);req(!is.na(i),i<nrow(e))
    choices<-e$epoch_id[seq.int(i+1,nrow(e))]
    current<-if(input$end_epoch %in% choices) input$end_epoch else tail(choices,1)
    updateSelectInput(session,'end_epoch',choices=setNames(choices,display_text(e$epoch_label[match(choices,e$epoch_id)])),selected=current)
  })
  observeEvent(input$land_pin,{
    id<-selected()
    if(id %in% pins()) notice('This area is already pinned.')
    else if(length(pins())>=3) notice('Three areas are pinned. Remove one to add another.')
    else {pins(c(pins(),id));notice(paste(unit_name(id),'added.'))}
  })
  observeEvent(input$land_clear,{pins(character());notice('Comparison cleared.')})
  output$land_pinned<-renderUI(tagList(
    if(!length(pins())) p(class='caption','No areas pinned.') else lapply(pins(),function(id) div(class='pinned-row',
      tags$button(type='button',class='unit-link',`data-focus`=id,unit_name(id)),
      tags$button(type='button',class='remove-pin',`data-remove`=id,`aria-label`=paste('Remove',unit_name(id)),'Remove'))),
    p(class='caption',notice())))
  # Calculate either later cover share or the difference between the two endpoints.
  map_data<-reactive({p<-valid_period();landcover_map_spec(d,chosen_class(),p$from,p$to,input$land_metric %||% 'change')})
  # Construct the base map; reactive observers replace only the changing layers.
  output$landcover_map<-leaflet::renderLeaflet({
    s<-isolate(map_data());id<-isolate(selected())
    leaflet::leaflet(d$areas,options=leaflet::leafletOptions(preferCanvas=TRUE,minZoom=4,maxZoom=12)) |>
      leaflet::fitBounds(140.9,-39.2,150.05,-33.95) |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=s$colours,fillOpacity=.9,
        color='#aebbad',weight=.45,opacity=.85,label=paste(d$areas$Name,isolate(display_text(class_label())),s$formatted,sep=' / ')) |>
      leaflet::addPolygons(data=d$areas[d$areas$microID==id,],group='selection',fill=FALSE,
        color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE)) |>
      leaflet::addControl(landcover_legend(s),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE))
  })
  observe({
    s<-map_data()
    leaflet::leafletProxy('landcover_map',data=d$areas) |>
      leaflet::clearGroup('areas') |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=s$colours,fillOpacity=.9,
        color='#aebbad',weight=.45,opacity=.85,
        label=paste(d$areas$Name,display_text(class_label()),s$formatted,sep=' / '),
        highlightOptions=leaflet::highlightOptions(color=ink,weight=2,bringToFront=TRUE)) |>
      leaflet::clearControls() |>
      leaflet::addControl(landcover_legend(s),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE)) |>
      leaflet::addControl('DEECA / VICLANDCOVERTS',position='bottomright',className='source-control')
  })
  observe({
    map_data();proxy<-leaflet::leafletProxy('landcover_map') |> leaflet::clearGroup('selection')
    pinned<-d$areas[d$areas$microID %in% pins(),]
    if(nrow(pinned)) proxy<-proxy |> leaflet::addPolygons(data=pinned,group='selection',fill=FALSE,
      color='#a56a2b',weight=2,dashArray='4 3',options=leaflet::pathOptions(interactive=FALSE))
    proxy |> leaflet::addPolygons(data=d$areas[d$areas$microID==selected(),],group='selection',fill=FALSE,
      color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE))
  })
  observeEvent(input$landcover_map_shape_click,{
    id<-input$landcover_map_shape_click$id
    if(!is.null(id) && id %in% d$areas$microID) updateSelectizeInput(session,'area',selected=id)
  })
  observeEvent(input$land_zoom,{
    b<-sf::st_bbox(d$areas[d$areas$microID==selected(),])
    leaflet::leafletProxy('landcover_map') |> leaflet::fitBounds(b[['xmin']],b[['ymin']],b[['xmax']],b[['ymax']])
  })
  output$land_map_title<-renderText({
    if((input$land_metric %||% 'change')=='change') paste('Change in',tolower(display_text(class_label())),'cover:',period_label())
    else paste(display_text(class_label()),'cover in',display_text(e$epoch_label[match(input$end_epoch,e$epoch_id)]))
  })
  output$land_map_caption<-renderText({
    if((input$land_metric %||% 'change')=='change') paste('Green = increased share; brown = decreased share; pale = little or no change. Later minus earlier, in percentage points (pp). Legend range:',-map_data()$limit,'to',paste0('+',map_data()$limit),'/ this cover type and period pair.')
    else paste('Darker green = a larger percentage of classified land mapped as',tolower(display_text(class_label())),'in',paste0(display_text(e$epoch_label[match(input$end_epoch,e$epoch_id)]),'.'),'The earlier period is used in the comparisons below.')
  })
  # Retain comparisons for each area separately because the source units can overlap.
  comparison<-reactive({p<-valid_period();landcover_change(d,shown_ids(),p$from,p$to,chosen_class())})
  all_changes<-reactive({p<-valid_period();landcover_change(d,selected(),p$from,p$to)})
  fmt<-function(v,suffix='',digits=1) ifelse(is.na(v),'No classified coverage',paste0(number(v,digits),suffix))
  output$land_history_context<-renderUI({
    ids<-setdiff(shown_ids(),selected())
    tagList(
      div(class='history-selection',strong(unit_name(selected())),span(display_text(class_label()))),
      div(class='history-period',period_label()),
      p(class='caption history-pins',if(length(ids)) paste('Compared with',paste(unit_name(ids),collapse=', ')) else 'Pin another area on the map to compare.'))
  })
  # Display endpoint values and coverage beside the selected map area.
  output$land_focus<-renderUI({
    x<-comparison();r<-x[x$microID==selected(),];req(nrow(r))
    a<-action_row(d,selected(),input$action %||% 'Control Foxes')
    tagList(p(class='detail-label','Selected area'),h2(unit_name(selected())),
      h3(display_text(class_label())),
      div(class='land-endpoints',
        div(p(class='detail-label',paste('Earlier:',display_text(e$epoch_label[match(r$start_epoch,e$epoch_id)]))),p(class='land-share',fmt(r$share_pct_start,'%'))),
        div(p(class='detail-label',paste('Later:',display_text(e$epoch_label[match(r$end_epoch,e$epoch_id)]))),p(class='land-share',fmt(r$share_pct_end,'%')))),
      p(class='land-net-change',paste('Change:',fmt(r$change_pp,' percentage points'))),
      p(class='caption',paste('Change in mapped area:',fmt(r$change_ha,' hectares'))),
      p(class='caption','Percentages describe land mapped as this cover type among the land the source could classify.'),
      tags$details(tags$summary('Data coverage and management context'),
        p(class='caption',paste('Classified land:',fmt(r$coverage_pct_start,'%'),'in the earlier period;',fmt(r$coverage_pct_end,'%'),'in the later period. Unclassified or missing land is excluded from cover percentages.')),
        p(class='detail-label','Separate management model: SMP4 / July 2023'),
        p(paste(action_labels[[input$action %||% 'Control Foxes']],if(nrow(a)) paste('/ rank',a$CE_RANK) else '/ No action record')),
        tags$button(type='button',class='text-button',`data-page`='explore','Investigate management opportunities'),
        p(class='caption','This management rank is separate from historical land cover change. The historical maps do not show whether management was delivered or caused a change.')))
  })

  # Use one table layout for selected cover comparisons and the full class evidence.
  make_table<-function(x,caption) tags$table(class='evidence-table',
    tags$caption(caption),tags$thead(tags$tr(lapply(c('Area','Cover type','Earlier cover (%)','Later cover (%)','Change (percentage points)','Change (hectares)'),function(t) tags$th(scope='col',t)))),
    tags$tbody(lapply(seq_len(nrow(x)),function(i) tags$tr(
      tags$th(scope='row',unit_name(x$microID[i])),tags$td(display_text(x$class_label[i])),
      tags$td(fmt(x$share_pct_start[i])),tags$td(fmt(x$share_pct_end[i])),tags$td(fmt(x$change_pp[i])),tags$td(fmt(x$change_ha[i]))))))
  output$land_comparison<-renderUI(make_table(comparison(),paste(display_text(class_label()),'/',period_label(),'/ each area shown separately')))
  # Compare all cover types in the main area using either hectares or percentage points.
  output$class_changes<-renderPlot({
    x<-all_changes();x$value<-if((input$change_unit %||% 'pp')=='ha') x$change_ha else x$change_pp
    validate(need(any(!is.na(x$value)),'This area has no classified coverage in one or both selected periods.'))
    x$class_label<-display_text(x$class_label)
    x$class_label<-factor(x$class_label,levels=rev(x$class_label))
    ggplot2::ggplot(x,ggplot2::aes(value,class_label))+
      ggplot2::geom_vline(xintercept=0,colour='#7d8b7e',linewidth=.4)+
      ggplot2::geom_segment(ggplot2::aes(x=0,xend=value,yend=class_label,colour=value>=0),linewidth=3)+
      ggplot2::geom_point(ggplot2::aes(colour=value>=0),size=2)+
      ggplot2::scale_colour_manual(values=c('FALSE'='#9a613b','TRUE'='#285f47'),guide='none')+
      ggplot2::labs(x=if((input$change_unit %||% 'pp')=='ha') 'Change in mapped area (projected hectares)' else 'Change in cover share (percentage points)',y=NULL,
        subtitle=paste(unit_name(selected()),'/',period_label()))+chart_theme()+
      ggplot2::theme(axis.text.y=ggplot2::element_text(size=10),panel.grid.major.y=ggplot2::element_blank())
  },res=110,alt='Change between the chosen periods for all 19 cover types in the selected area. Right and green indicate an increase; left and brown indicate a decrease. Exact values are in the tables.')
  # Draw a local history chart that remains usable when the online workbook is unavailable.
  output$land_trends<-renderPlot({
    x<-d$landcover$summary;x<-x[x$microID %in% shown_ids() & x$class_code==chosen_class(),]
    x$epoch_label<-factor(display_text(x$epoch_label),levels=display_text(e$epoch_label));x$area<-factor(unit_name(x$microID),levels=unit_name(shown_ids()))
    ggplot2::ggplot(x,ggplot2::aes(epoch_label,share_pct,group=area,colour=area))+
      ggplot2::geom_line(linewidth=.8)+ggplot2::geom_point(size=2)+
      ggplot2::scale_y_continuous(limits=c(0,100))+
      ggplot2::scale_colour_manual(values=c('#285f47','#b47737','#6c7896','#9b6670'))+
      ggplot2::labs(x=NULL,y='Cover share (%)',colour=NULL,subtitle=paste(display_text(class_label()),'/ all seven historical periods'))+chart_theme()+
      ggplot2::theme(axis.text.x=ggplot2::element_text(size=10))
  },res=110,alt='Percentage of classified land mapped as the chosen cover type across all seven periods. Each line represents a separate selected or pinned area.')
  output$land_values<-renderUI({p<-valid_period();make_table(landcover_change(d,shown_ids(),p$from,p$to),paste('All cover types /',period_label(),'/ each area shown separately'))})
  # Download all seven periods for the selected areas, with coverage and source fields.
  output$download_landcover<-downloadHandler(filename=function() paste0('landcover-',selected(),'-and-comparison.csv'),content=function(file) {
    x<-d$landcover$summary;x<-x[x$microID %in% shown_ids(),]
    x$record_status<-ifelse(is.na(x$area_ha),'No classified coverage',ifelse(x$area_ha==0,'Class absent in classified area','Available'))
    x$area_basis<-'Projected grid hectares in EPSG:3111; exact boundary cell coverage fractions'
    x$share_basis<-'Codes 1-19 classified area in each unit/epoch; code 0 unclassified excluded'
    x$source_url<-d$landcover$manifest$download_url
    x$attribution<-d$landcover$manifest$attribution;x$licence<-'CC BY 4.0'
    write.csv(x,file,row.names=FALSE,na='')
  })
  output$download_tableau<-downloadHandler(filename='Victoria_Landscape_Change.twbx',
    content=function(file) file.copy('tableau/Victoria_Landscape_Change.twbx',file),contentType='application/octet-stream')
  # Mount the published workbook inside the page and retain a local evidence fallback.
  output$tableau<-renderUI({
    config<-tableau_config()
    if(config$valid) div(id='tableau-host',`data-view-url`=config$url,`data-release`=d$landcover$manifest$release,
      div(class='tableau-connection',
        span(class='tableau-credit','Interactive charts / Tableau'),
        div(id='tableau-status',role='status',`aria-live`='polite','Loading charts...'),
        tags$button(type='button',id='tableau-retry',class='button-outline','Retry Tableau')),
      div(class='tableau-viewport',tabindex='0',role='region',`aria-label`='Interactive historical land cover charts',div(id='tableau-mount')),
      p(class='caption tableau-width-hint','On a narrow window, scroll the chart panel sideways to see all controls.'),
      tags$details(class='tableau-help',tags$summary('Trouble viewing the dashboard?'),
        p('Use Retry Tableau above to reload the embedded view. A separate tab is available if your viewer blocks the embedded dashboard.'),
        tags$a(href=config$url,target='_blank',rel='noopener','Open a separate Tableau tab')))
    else div(class='empty-state',role='status',h3('Explore the interactive workbook'),
      p('Download and open the workbook in Tableau. Area, cover type and period selections are linked through this app when the online dashboard is available.'),
      if(config$configured) p('The online dashboard is currently unavailable. Download the workbook or explore the charts below.'),
      downloadButton('download_tableau','Download Tableau workbook'))
  })
  observe({
    # Send source parameter values unchanged so Tableau uses the same analytical selection.
    p<-valid_period();ids<-head(setdiff(pins(),selected()),3);slots<-rep('',3);slots[seq_along(ids)]<-ids
    session$sendCustomMessage('landscape-state',list(focus=selected(),compare1=slots[1],compare2=slots[2],compare3=slots[3],
      class=class_label(),start=e$epoch_label[match(p$from,e$epoch_id)],end=e$epoch_label[match(p$to,e$epoch_id)]))
  })
  # Accept validated parameter changes from Tableau and update the corresponding Shiny controls.
  observeEvent(input$tableau_parameter,{
    p<-input$tableau_parameter
    slot<-match(p$name,paste0('Additional area ',1:3,' (optional)'))
    if(!is.na(slot) && p$value %in% c('',d$areas$microID)) {
      slots<-rep('',3);current<-head(setdiff(pins(),selected()),3);slots[seq_along(current)]<-current
      slots[slot]<-p$value;pins(unique(slots[nzchar(slots)]))
    }
    if(identical(p$name,'Main area') && p$value %in% d$areas$microID) updateSelectizeInput(session,'area',selected=p$value)
    if(identical(p$name,'Cover type') && p$value %in% classes$class_label)
      updateSelectInput(session,'land_class',selected=classes$class_code[match(p$value,classes$class_label)])
    if(identical(p$name,'Earlier period') && p$value %in% head(e$epoch_label,-1))
      updateSelectInput(session,'start_epoch',selected=e$epoch_id[match(p$value,e$epoch_label)])
    if(identical(p$name,'Later period') && p$value %in% e$epoch_label && match(p$value,e$epoch_label)>match(input$start_epoch,e$epoch_id))
      updateSelectInput(session,'end_epoch',selected=e$epoch_id[match(p$value,e$epoch_label)])
  })
  invisible(list(comparison=comparison,all_changes=all_changes,map_data=map_data))
}
