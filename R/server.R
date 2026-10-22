atlas_server <- function(d) function(input, output, session) {
  library(shiny)
  pins <- reactiveVal(c('unit668','unit375'))
  notice <- reactiveVal('')
  selected <- reactive({req(input$area %in% d$areas$microID); input$area})
  chosen_action <- reactive({req(input$action %in% names(action_labels));input$action})
  focus <- reactive(action_row(d,selected(),chosen_action()))
  shown_ids <- reactive(unique(c(pins(),selected())))
  observeEvent(input$pin, {
    id <- selected()
    if (id %in% pins()) notice('This area is already pinned.')
    else if (length(pins())>=3) notice('Three areas are pinned. Remove one to add another.')
    else {pins(c(pins(),id));notice(paste(unit_name(id),'added.'))}
  })
  observeEvent(input$remove_pin,{pins(setdiff(pins(),input$remove_pin));notice('')})
  observeEvent(input$clear,{pins(character());notice('Comparison cleared.')})
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
  output$priority_map <- leaflet::renderLeaflet({
    rows <- d$actions[d$actions$Action=='Control Foxes',]
    values <- rows$CE_RANK[match(d$areas$microID,rows$microID)]
    labels <- paste(d$areas$Name,'/ Foxes /',ifelse(is.na(values),'No action record',paste('Rank',values)))
    leaflet::leaflet(d$areas,options=leaflet::leafletOptions(preferCanvas=TRUE,minZoom=4,maxZoom=11,zoomSnap=.25)) |>
      leaflet::fitBounds(140.9,-39.2,150.05,-33.95) |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=rank_colour(values),fillOpacity=.95,
        color='#f7f6f1',weight=.2,opacity=.4,label=labels,
        highlightOptions=leaflet::highlightOptions(color='#203c32',weight=2,bringToFront=TRUE)) |>
      leaflet::addPolygons(data=d$areas[d$areas$microID=='unit668',],group='selection',fill=FALSE,color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE)) |>
      leaflet::addControl(rank_legend(),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE)) |>
      leaflet::addControl('DEECA  /  SMP4',position='bottomright',className='source-control')
  })
  observeEvent(input$action,{
    a <- chosen_action(); rows <- d$actions[d$actions$Action==a,]
    m <- match(d$areas$microID,rows$microID);v <- rows$CE_RANK[m]
    labels <- paste0(d$areas$Name,'  /  ',action_labels[[a]],'  /  ',ifelse(is.na(v),'No action record',paste('Rank',v)))
    leaflet::leafletProxy('priority_map',data=d$areas) |>
      leaflet::clearGroup('areas') |>
      leaflet::addPolygons(layerId=~microID,group='areas',fillColor=rank_colour(v),fillOpacity=.95,
        color='#f7f6f1',weight=.2,opacity=.4,label=labels,
        highlightOptions=leaflet::highlightOptions(color='#203c32',weight=2,bringToFront=TRUE)) |>
      leaflet::clearControls() |>
      leaflet::addControl(rank_legend(),position='topright',className='rank-legend') |>
      leaflet::addScaleBar(position='bottomleft',options=leaflet::scaleBarOptions(imperial=FALSE)) |>
      leaflet::addControl('DEECA  /  SMP4',position='bottomright',className='source-control')
    # Reapply outline after changing the polygon layer.
    s <- d$areas[d$areas$microID==selected(),]
    leaflet::leafletProxy('priority_map') |> leaflet::clearGroup('selection') |>
      leaflet::addPolygons(data=s,group='selection',fill=FALSE,color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE))
  },ignoreInit=TRUE)
  observeEvent(input$area,{
    s <- d$areas[d$areas$microID==selected(),]
    leaflet::leafletProxy('priority_map') |> leaflet::clearGroup('selection') |>
      leaflet::addPolygons(data=s,group='selection',fill=FALSE,color='#142e23',weight=3,options=leaflet::pathOptions(interactive=FALSE))
  },ignoreInit=TRUE)
  observeEvent(input$priority_map_shape_click,{
    id <- input$priority_map_shape_click$id
    if (!is.null(id) && id %in% d$areas$microID) updateSelectizeInput(session,'area',selected=id)
  })
  observeEvent(input$reset,{
    updateSelectInput(session,'action',selected='Control Foxes');updateSelectizeInput(session,'area',selected='unit668')
    leaflet::leafletProxy('priority_map') |> leaflet::fitBounds(140.9,-39.2,150.05,-33.95)
    notice('Map and action reset. Your pinned areas are retained.')
  })
  extent_bar <- function(label,value,total) {
    pct <- 100*value/total
    div(class='extent-row',div(class='extent-label',span(label),strong(paste(number(value),'ha'))),
      div(class='bar-track',`aria-label`=paste(label,number(pct,1),'percent of relevant area'),
        div(class='bar-fill',style=paste0('width:',pct,'%;'))),span(class='caption',paste0(number(pct,1),'% of relevant area')))
  }
  output$area_detail <- renderUI({
    r <- focus()
    tagList(p(class='detail-label','Selected area'),h2(unit_name(selected())),
      if(!nrow(r)) div(class='empty-state',h3('No action record'),p('This snapshot has no record for this area and action. This does not establish that the threat is absent.')) else tagList(
        p(class='detail-label','Median cost-effectiveness rank'),div(class='rank-value',r$CE_RANK,span('/ 100')),
        p(class='detail-label','Relevant area'),div(class='area-value',number(r$AREA_TOT),span(' ha')),
        tags$hr(),h3('Area extent in top ranks'),extent_bar('Top 5%',r$AREA_5,r$AREA_TOT),extent_bar('Top 15%',r$AREA_20,r$AREA_TOT),
        p(class='caption','The top 5% is included within the top 15%.'),
        tags$details(tags$summary('Evidence for this selection'),p(paste('Source rank range:',trimws(r$CE_RANGE))),
          p('This is a source range, not a confidence interval.'),p(paste('Snapshot:',d$retrieved)),
          tags$a(href=paste0('https://bio-prd-naturekit-public-data.s3-ap-southeast-2.amazonaws.com/smp-reports/summary_areas_v4/SMPreport_Summary_',selected(),'.html'),target='_blank',rel='noopener','Open official area report'),p('Report values may differ from this service snapshot.'))))
  })
  output$heatmap <- renderUI({
    ids <- shown_ids();acts <- names(action_labels)
    div(class='heatmap-scroll',tags$table(class='heatmap',
      tags$caption(class='sr-only','Area by management action. Values are median cost-effectiveness ranks, 0 to 100. Missing values are labelled No record.'),
      tags$thead(tags$tr(tags$th(scope='col','Area'),lapply(acts,function(a) tags$th(scope='col',class=if(a==chosen_action()) 'active-action' else '',action_labels[[a]])))),
      tags$tbody(lapply(ids,function(id) tags$tr(tags$th(scope='row',unit_name(id)),lapply(acts,function(a) {
        r <- action_row(d,id,a);v <- if(nrow(r)) r$CE_RANK else NA_real_
        label <- paste(unit_name(id),a,if(is.na(v)) 'No action record' else paste('rank',v),sep='; ')
        tags$td(class=if(a==chosen_action()) 'active-action' else '',
          tags$button(type='button',class=paste('heat-cell',if(is.na(v)) 'missing' else ''),`data-area`=id,`data-action`=a,
            style=paste0('background:',rank_colour(v),';color:',if(!is.na(v)&&v>=65)'#ffffff' else '#203c32'),
            `aria-label`=label,title=label,if(is.na(v)) 'No record' else as.character(v)))
      }))))))
  })
  output$comparison <- renderUI({
    ids <- pins()
    if(!length(ids)) return(div(class='empty-state','Pin areas from the map or heatmap to compare their opportunity extent.'))
    rows <- compare_rows(d,ids,chosen_action());pct <- is.null(input$extent_unit)||input$extent_unit=='pct'
    limit <- if(pct) 100 else max(c(rows$AREA_TOT,1),na.rm=TRUE)
    div(class='comparison-grid',lapply(ids,function(id) {
      r <- rows[rows$microID==id,]
      div(class='comparison-column',h3(unit_name(id)),
        if(!nrow(r)||is.na(r$CE_RANK)) p('No action record') else tagList(
          p(paste(action_labels[[chosen_action()]],' /  Rank',r$CE_RANK,' / ',number(r$AREA_TOT),'relevant ha')),
          lapply(c('Top 5%'='AREA_5','Top 15%'='AREA_20'),function(field) {
            value <- if(pct) 100*r[[field]]/r$AREA_TOT else r[[field]]
            div(class='extent-row',div(class='extent-label',span(if(field=='AREA_5') 'Top 5%' else 'Top 15%'),
              strong(if(pct) paste0(number(value,1),'%') else paste(number(value),'ha'))),
              div(class='bar-track',div(class='bar-fill',style=paste0('width:',100*value/limit,'%;'))))
          })))
    }))
  })
  output$download_compare <- downloadHandler(filename=function() paste0('conservation-comparison-',Sys.Date(),'.csv'),content=function(file) {
    ids <- unique(c(pins(),selected()))
    x <- expand.grid(microID=ids,Action=names(action_labels),stringsAsFactors=FALSE)
    x <- merge(x,d$actions,by=c('microID','Action'),all.x=TRUE)
    x$model <- 'SMP4';x$retrieved <- d$retrieved;x$source <- d$source
    x$record_status <- ifelse(is.na(x$CE_RANK),'No action record','Available')
    write.csv(x,file,row.names=FALSE,na='')
  })
  output$download_activity <- downloadHandler(filename='biodiversity2037-activity.csv',content=function(file) write.csv(d$activity,file,row.names=FALSE,na=''))
  output$target_gap <- renderPlot({
    req(input$year);x <- annual_progress(d,input$year)
    ggplot2::ggplot(x,ggplot2::aes(x=attainment,y=reorder(action,attainment))) +
      ggplot2::geom_vline(xintercept=100,linetype='dashed',colour='#9a7142') +
      ggplot2::geom_segment(ggplot2::aes(xend=100,yend=action),colour='#bcc5bc',linewidth=1) +
      ggplot2::geom_point(size=4,colour='#285f47') +
      ggplot2::geom_text(ggplot2::aes(label=paste0(round(attainment,1),'%')),nudge_y=.2,size=3.6,colour=ink) +
      ggplot2::scale_x_continuous(limits=c(0,max(110,x$attainment+10)),breaks=c(0,25,50,75,100)) +
      ggplot2::labs(x=paste('Annual target attained (%)  / ',input$year),y=NULL) + chart_theme()
  },res=110)
  output$target_table <- renderUI({
    req(input$year);x <- annual_progress(d,input$year)
    tags$table(class='evidence-table',tags$caption('Selected-year values'),
      tags$thead(tags$tr(tags$th('Action'),tags$th('Reported ha'),tags$th('Target ha'),tags$th('Gap'))),
      tags$tbody(lapply(seq_len(nrow(x)),function(i) tags$tr(tags$td(x$action[i]),tags$td(number(x$area_ha[i])),tags$td(number(x$target_ha[i])),
        tags$td(paste(number(abs(x$gap_pp[i]),1),'pp',if(x$gap_pp[i]>=0)'below' else 'above'))))))
  })
  filtered_annual <- reactive({x<-annual_progress(d);if(!is.null(input$trend_action)&&input$trend_action!='All actions') x<-x[x$action==input$trend_action,];x})
  output$annual_trends <- renderPlot({
    x <- filtered_annual()
    ggplot2::ggplot(x,ggplot2::aes(period_end_year,area_ha/1e6))+
      ggplot2::geom_hline(ggplot2::aes(yintercept=target_ha/1e6),linetype='dashed',colour='#a17d4b')+
      ggplot2::geom_line(colour='#285f47',linewidth=.8)+ggplot2::geom_point(colour='#285f47',size=2)+
      ggplot2::facet_wrap(~action,ncol=1,scales='free_y')+
      ggplot2::scale_x_continuous(breaks=2019:2022,labels=c('2018-19','2019-20','2020-21','2021-22'))+
      ggplot2::scale_y_continuous(limits=c(0,NA))+
      ggplot2::labs(x=NULL,y='Million hectares')+chart_theme()
  },res=110)
  output$priority_share <- renderPlot({
    x <- filtered_annual();totals<-d$activity[d$activity$coverage=='statewide',]
    x$total<-totals$area_ha[match(paste(x$action,x$financial_year),paste(totals$action,totals$financial_year))]
    ggplot2::ggplot(x,ggplot2::aes(period_end_year,100*area_ha/total,colour=action))+
      ggplot2::geom_line(linewidth=.9)+ggplot2::geom_point(size=2)+
      ggplot2::scale_color_manual(values=c('Pest herbivore control'='#285f47','Pest predator control'='#816499','Weed control'='#b47737'))+
      ggplot2::scale_x_continuous(breaks=2019:2022,labels=c('2018-19','2019-20','2020-21','2021-22'))+
      ggplot2::scale_y_continuous(limits=c(0,100))+
      ggplot2::labs(x=NULL,y='Priority-location share (%)',colour=NULL)+chart_theme()+ggplot2::theme(legend.text=ggplot2::element_text(size=10))
  },res=110)
  output$cumulative <- renderPlot({
    x<-d$activity[(d$activity$action=='Revegetation' & d$activity$coverage=='priority') | d$activity$action=='Permanent protection',]
    ggplot2::ggplot(x,ggplot2::aes(period_end_year,area_ha))+
      ggplot2::geom_line(colour='#285f47',linewidth=.8)+ggplot2::geom_point(colour='#285f47',size=2)+
      ggplot2::facet_wrap(~action,ncol=2)+
      ggplot2::scale_y_continuous(limits=c(0,NA),labels=function(x) format(x,big.mark=',',scientific=FALSE))+
      ggplot2::scale_x_continuous(breaks=c(2019,2022),labels=c('2018-19','2021-22'),expand=ggplot2::expansion(mult=c(.2,.2)))+
      ggplot2::labs(x=NULL,y='Cumulative hectares',caption='2037 target: 200,000 ha per measure (beyond the displayed scale)')+chart_theme()
  },res=110)
  output$tableau <- renderUI({
    url<-Sys.getenv('TABLEAU_VIEW_URL','')
    if(nzchar(url)&&grepl('^https://public[.]tableau[.]com/views/[A-Za-z0-9_/-]+',url))
      tags$iframe(src=url,title='Biodiversity 2037 Tableau dashboard',width='100%',height='800',style='border:0',loading='lazy')
    else p(class='caption','This first release uses interactive R controls and R charts. The Tableau workbook is the next stage; no Tableau view has been connected yet.')
  })
}
