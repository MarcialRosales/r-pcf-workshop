library(shiny)

port <- Sys.getenv('PORT')
print(port)

.libPaths()
capabilities()
print(getwd())


shiny::runApp('app', host = '0.0.0.0', port = as.numeric(port))
