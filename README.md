R Experiments
---

# Example 01
Very simple R/Shiny application to demonstrate how to get it running in PCF thanks to https://github.com/wjjung317/heroku-buildpack-r.

## Run it in PCF

1. `cd example-01-hello`
2. `cf push`
3. Go to the browser and test the application

> Known issue (under investigation): The application starts up fine but the graph that should be drawn on the right hand-side fails to display.

## Run it with Docker

1. `cd example-01-hello`
2. `docker build -t dummyR .`
3. `docker run -p 8080:8080 dummyR`
4. Go the browser and test the application on port 8080. If you are using native docker, go to localhost:8080. If you are using docker-machine, go to the url reported here `docker-machine env <your-machine-name>`.

> We could have excluded the application from the docker image and simply mount it as a volume so that we can reuse the image for other applications.
