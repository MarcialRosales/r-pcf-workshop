.libPaths("/site-library")
library(shiny)

port <- Sys.getenv('PORT')
print(port)

shiny::runApp('app', host = '0.0.0.0', port = as.numeric(port))
