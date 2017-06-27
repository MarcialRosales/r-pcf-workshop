R Experiments
---

# Example 01
Very simple R/Shiny application to demonstrate how to get it running in PCF thanks to https://github.com/wjjung317/heroku-buildpack-r.

## Run it in PCF

1. `cd example-01-hello`
2. `cf push`
3. Go to the browser and test the application

> Lessons Learnt: Install the package Cairo (see init.r) to force R to use Cairo graphic library very much needed to render plots. By default, R uses X11 to render plots. However, in certain runtime environments like PCF, there is no X11 system available. So we have to tell R to use Cairo or any other R graphic library.

## Run it with Docker

1. `cd example-01-hello`
2. `docker build -t dummyR .`
3. `docker run -p 8080:8080 dummyR`
4. Go the browser and test the application on port 8080. If you are using native docker, go to localhost:8080. If you are using docker-machine, go to the url reported here `docker-machine env <your-machine-name>`.

> We could have excluded the application from the docker image and simply mount it as a volume so that we can reuse the image for other applications.

## Connect to a managed database

1. Create database instance
  `cf create-service p-mysql pre-existing-plan r-db`
2. Bind application to the database instance
  `cf bind-service example-01 r-db ` or add it to the `manifest.yml`
3. Check the credentials
  `cf env example-01`
4. **Obtain credentials for our database `r-db` we proceed as follows:**
  ```
  library(RMySQL)
  source("credentials.R",  local=environment())

  dbCredentials <- getCredentials("r-db")
  ...
  con_sql <- dbConnect(RMySQL::MySQL(), username = dbCredentials$username,
    password = dbCredentials$password, host = dbCredentials$hostname,
    port = dbCredentials$port, dbname = dbCredentials$name)

  ```

5. To demonstrate this functionality we have created `credentials.R` file which serves as a utility library that obtains credentials from the environment. We have also created a `mysql.R` that interacts with the `r-db`.
6. We use `mysql.R` from the `server.R`. First we initialize it and then we fetch some data from an auto-generated table called `samples`.
