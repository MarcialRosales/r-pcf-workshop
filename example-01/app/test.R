source("app/credentials.R")

test <- function() {
  dbCredentials <- getCredentials("oracle-db")
  print(dbCredentials)
}
