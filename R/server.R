# Coordinate priority selection, pinned areas, map layers and comparison exports.
atlas_server <- function(d) function(input, output, session) {
  library(shiny)
  # Store pins separately from the active area so navigation retains comparisons.
  pins <- reactiveVal(c('unit668','unit375'))
  notice <- reactiveVal('')
  selected <- reactive({req(input$area %in% d$areas$microID); input$area})
  chosen_action <- reactive({req(input$action %in% names(action_labels));input$action})
  focus <- reactive(action_row(d,selected(),chosen_action()))
  shown_ids <- reactive(unique(c(selected(),pins())))
  # Limit the comparison to three pins and avoid duplicate areas.
  observeEvent(input$pin, {
    id <- selected()
    if (id %in% pins()) notice('This area is already pinned.')
    else if (length(pins())>=3) notice('Three areas are pinned. Remove one to add another.')
    else {pins(c(pins(),id));notice(paste(unit_name(id),'added.'))}
  })
  observeEvent(input$remove_pin,{pins(setdiff(pins(),input$remove_pin));notice('')})
  observeEvent(input$clear,{pins(character());notice('Comparison cleared.')})
  # A heatmap click changes both the area and the management action.
  observeEvent(input$cell,{
    if (input$cell$area %in% d$areas$microID && input$cell$action %in% names(action_labels)) {
      updateSelectizeInput(session,'area',selected=input$cell$area)
      updateSelectInput(session,'action',selected=input$cell$action)
    }
  })
  output$pin_message <- renderText(notice())
  output$pinned <- renderUI({
    if (!length(pins())) return(p(class='caption','No areas pinned.'))
    tagList(lapply(pins(),function(id) div(class='pinned-row',
      tags$button(type='button',class='unit-link',`data-focus`=id,unit_name(id)),
      tags$button(type='button',class='remove-pin',`data-remove`=id,`aria-label`=paste('Remove',unit_name(id)),'Remove'))))
  })
  observeEvent(input$focus_area,{if(input$focus_area %in% d$areas$microID) updateSelectizeInput(session,'area',selected=input$focus_area)})
  # Create the map once, then update its layers through Leaflet proxies.
  output$priority_map <- leaflet::renderLeaflet({
    a <- isolate(chosen_action());s <- map_spec(d,a)
    leaflet::leaflet(d$areas,options=leaflet::leafletOptions(preferCanvas=TRUE,minZoom=4,maxZoom=12,zoomSnap=.25)) |>
      leaflet::fitBounds(140.9,-39.2,150.05,-33.95) |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=s$colours,fillOpacity=.85,
        color='#f7f6f1',weight=.3,opacity=.6,label=paste(d$areas$Name,action_labels[[a]],s$formatted,sep=' / '),
        highlightOptions=leaflet::highlightOptions(color='#203c32',weight=2,bringToFront=TRUE)) |>
      leaflet::addControl(map_legend(s),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE)) |>
      leaflet::addControl('DEECA / SMP4',position='bottomright',className='source-control')
  })
  # Recolour all areas when the management action changes.
  observeEvent(input$action,{
    a <- chosen_action();s <- map_spec(d,a)
    leaflet::leafletProxy('priority_map',data=d$areas) |>
      leaflet::clearGroup('areas') |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=s$colours,fillOpacity=.85,
        color='#f7f6f1',weight=.3,opacity=.6,label=paste(d$areas$Name,action_labels[[a]],s$formatted,sep=' / '),
        highlightOptions=leaflet::highlightOptions(color='#203c32',weight=2,bringToFront=TRUE)) |>
      leaflet::clearControls() |>
      leaflet::addControl(map_legend(s),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE)) |>
      leaflet::addControl('DEECA / SMP4',position='bottomright',className='source-control')
  },ignoreInit=TRUE)
  # Draw the active area and pins as separate outlines above the filled map.
  observe({
    req(selected())
    proxy <- leaflet::leafletProxy('priority_map') |> leaflet::clearGroup('selection')
    pinned <- d$areas[d$areas$microID %in% pins(),]
    if(nrow(pinned)) proxy <- proxy |> leaflet::addPolygons(data=pinned,group='selection',fill=FALSE,
      color='#a56a2b',weight=2,dashArray='4 3',options=leaflet::pathOptions(interactive=FALSE))
    proxy |> leaflet::addPolygons(data=d$areas[d$areas$microID==selected(),],group='selection',fill=FALSE,
      color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE))
    chosen_action()
  })
  observeEvent(input$zoom_area,{
    b <- sf::st_bbox(d$areas[d$areas$microID==selected(),])
    leaflet::leafletProxy('priority_map') |> leaflet::fitBounds(b[['xmin']],b[['ymin']],b[['xmax']],b[['ymax']])
  })
  output$priority_map_title <- renderText(paste('Area rankings for',tolower(action_labels[[chosen_action()]])))
  output$map_caption <- renderText(paste('Darker green = a higher cost effectiveness rank for',tolower(action_labels[[chosen_action()]]),'/ 0 to 100 scale.'))
  observeEvent(input$priority_map_shape_click,{
    id <- input$priority_map_shape_click$id
    if (!is.null(id) && id %in% d$areas$microID) updateSelectizeInput(session,'area',selected=id)
  })
  observeEvent(input$reset,{
    updateSelectInput(session,'action',selected='Control Foxes');updateSelectizeInput(session,'area',selected='unit668')
    leaflet::leafletProxy('priority_map') |> leaflet::fitBounds(140.9,-39.2,150.05,-33.95)
    notice('Map and action reset. Your pinned areas are retained.')
  })
  # Report the selected action rank and relevant hectares without treating gaps as zeros.
  output$area_detail <- renderUI({
    r <- focus()
    tagList(p(class='detail-label','Selected area'),h2(unit_name(selected())),
      p(class='selected-action',paste('Selected action:',action_labels[[chosen_action()]])),
      if(!nrow(r)) div(class='empty-state',h3('No action record'),p('This snapshot has no record for this area and action. This does not establish that the threat is absent.')) else tagList(
        p(class='detail-label','Cost effectiveness rank'),div(class='rank-value',r$CE_RANK,span('on a 0 to 100 scale')),
        p(class='caption',paste('Higher ranks indicate stronger expected benefits relative to cost for',paste0(tolower(action_labels[[chosen_action()]]),'.'))),
        p(class='detail-label','Relevant land for this action'),div(class='area-value',number(r$AREA_TOT),span(' ha')),
        p(class='caption','Relevant hectares as reported by the source. One hectare is 10,000 square metres.'),
        tags$details(tags$summary('Evidence for this selection'),p('The government supplies the median cost effectiveness rank for this area and action. It is a relative ranking, not an area\u2019s position in a numbered list or a percentage chance of success.'),p(paste('Source rank range:',display_text(gsub('[-\u2013\u2014]', ' to ', r$CE_RANGE)))),
          p('This is a source range, not a confidence interval.'),p(paste('Snapshot:',format(as.Date(d$retrieved),'%d %B %Y'))),
          tags$a(href=paste0('https://bio-prd-naturekit-public-data.s3-ap-southeast-2.amazonaws.com/smp-reports/summary_areas_v4/SMPreport_Summary_',selected(),'.html'),target='_blank',rel='noopener','Open official area report'),p('Report values may differ from this service snapshot.'))))
  })
  # Build an accessible area by action grid with a selectable button in each cell.
  output$heatmap <- renderUI({
    ids <- shown_ids();acts <- names(action_labels)
    div(class='heatmap-scroll',tags$table(class='heatmap',
      tags$caption(class='sr-only','Area by management action. Values are median cost effectiveness ranks, 0 to 100. Missing values are labelled No record.'),
      tags$thead(tags$tr(tags$th(scope='col','Area'),lapply(acts,function(a) tags$th(scope='col',class=if(a==chosen_action()) 'active-action' else '',action_labels[[a]])))),
      tags$tbody(lapply(ids,function(id) tags$tr(tags$th(scope='row',unit_name(id)),lapply(acts,function(a) {
        r <- action_row(d,id,a);v <- if(nrow(r)) r$CE_RANK else NA_real_
        label <- paste(unit_name(id),action_labels[[a]],if(is.na(v)) 'No action record' else paste('rank',v,';',number(r$AREA_TOT),'relevant ha'),sep='; ')
        tags$td(class=if(a==chosen_action()) 'active-action' else '',
          tags$button(type='button',class=paste('heat-cell',if(is.na(v)) 'missing' else ''),`data-area`=id,`data-action`=a,
            style=paste0('background:',rank_colour(v),';color:',cell_text_colour(rank_colour(v))),
            `aria-label`=label,title=label,if(is.na(v)) 'No record' else as.character(v)))
      }))))))
  })
  # Export every requested area and action combination with source provenance.
  output$download_compare <- downloadHandler(filename=function() paste0('conservation-comparison-',Sys.Date(),'.csv'),content=function(file) {
    ids <- unique(c(pins(),selected()))
    x <- expand.grid(microID=ids,Action=names(action_labels),stringsAsFactors=FALSE)
    x <- merge(x,d$actions,by=c('microID','Action'),all.x=TRUE)
    x$model <- 'SMP4';x$retrieved <- d$retrieved;x$source <- d$source;x$release_id <- d$release_id
    x$record_status <- ifelse(is.na(x$CE_RANK),'No action record','Available')
    write.csv(x,file,row.names=FALSE,na='')
  })
  # Pass shared selection and pin state to the landscape workspace.
  landscape_server(d,input,output,session,selected,pins,shown_ids,notice)
}
