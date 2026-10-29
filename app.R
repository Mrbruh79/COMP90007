# Start from this directory with shiny::runApp().
required <- c('shiny', 'leaflet', 'sf', 'ggplot2', 'jsonlite', 'htmltools')
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop('Missing packages: ', paste(missing, collapse = ', '), '. See README.md for setup.')
source('R/landcover.R', local = TRUE)
source('R/data.R', local = TRUE)
source('R/landscape_ui.R', local = TRUE)
source('R/ui.R', local = TRUE)
source('R/landscape_server.R', local = TRUE)
source('R/server.R', local = TRUE)
if (!file.exists('data/smp_cache.rds')) stop('Run source("scripts/prepare_data.R") once to download the public spatial data.')
atlas <- load_atlas()
shiny::shinyApp(atlas_ui(atlas), atlas_server(atlas))
