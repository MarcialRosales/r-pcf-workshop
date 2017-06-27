library(shiny)
library(RMySQL)
source("mysql.R", local=environment())
source("files.R", local=environment())

InitMySQL()

# Define server logic required to generate and plot a random distribution
shinyServer(function(input, output) {

  print(DirFiles())
  CopyFiles()

  # Expression that generates a plot of the distribution. The expression
  # is wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should be automatically
  #     re-executed when inputs change
  #  2) Its output type is a plot
  #
  output$distPlot <- renderPlot({

    # generate an rnorm distribution and plot it
    dist <- rnorm(input$obs)
    hist(dist)

    samples <- FetchSamples()
    print(samples)

  })

})
