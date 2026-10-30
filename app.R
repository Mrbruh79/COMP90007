# Start from this directory with shiny::runApp().
# Check dependencies before loading data or constructing the interface.
required <- c('shiny', 'leaflet', 'sf', 'ggplot2', 'jsonlite', 'htmltools')
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop('Missing packages: ', paste(missing, collapse = ', '), '. See README.md for setup.')
# Load calculation helpers before the interface and server modules.
source('R/landcover.R', local = TRUE, encoding = 'UTF-8')
source('R/data.R', local = TRUE, encoding = 'UTF-8')
source('R/landscape_ui.R', local = TRUE, encoding = 'UTF-8')
source('R/ui.R', local = TRUE, encoding = 'UTF-8')
source('R/landscape_server.R', local = TRUE, encoding = 'UTF-8')
source('R/server.R', local = TRUE, encoding = 'UTF-8')
if (!file.exists('data/smp_cache.rds')) stop('Missing frozen spatial cache. Copy data/smp_cache.rds from the matching submission ZIP. See README.md for a complete source rebuild.')
# Read the frozen source snapshot and bind the interface to its server.
atlas <- load_atlas()
shiny::shinyApp(atlas_ui(atlas), atlas_server(atlas))
