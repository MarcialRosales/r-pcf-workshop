source("credentials.R",  local=environment())

dbCredentials <- getCredentials("r-db")
cat(paste("host:", dbCredentials$hostname, "dbname:", dbCredentials$name))
SAMPLES_TABLE = "samples"

OpenConnMySQL <- function() {
  print("Connecting to r-db ...")
  con_sql <- dbConnect(RMySQL::MySQL(), username = dbCredentials$username,
    password = dbCredentials$password, host = dbCredentials$hostname,
    port = dbCredentials$port, dbname = dbCredentials$name)

  print(summary(con_sql))

  print("Connected to r-db")
  OpenConnMySQL = con_sql
}

InitMySQL <- function() {
  print("Initializing r-db schema ...")
  conn <- OpenConnMySQL()

  tryCatch(createSchema(conn), error = function(err) { print(err) },
     finally = dbDisconnect(conn))

  print("Initialized r-db schema")
}

createSchema <- function(conn)
{
  if (dbExistsTable(conn, SAMPLES_TABLE)) {
    print(dbListTables(conn))
  }else {

    print("Creating sample table in r-db schema ...")

    x <- 1:10
    y <- letters[1:10]
    samples <- data.frame(x, y)

    dbWriteTable(conn, SAMPLES_TABLE, samples, overwrite = TRUE)
    print(dbListTables(conn))
    dbCommit(conn)
  }
}

FetchSamples <- function() {
  print("Fetching samples in r-db schema ...")
  conn <- OpenConnMySQL()

  FetchSamples = tryCatch(fetch(conn), error = function(err) { print(err) },
    finally = dbDisconnect(conn)
  )

}

fetch <- function(conn)
{
  sql <- paste("SELECT * FROM ", SAMPLES_TABLE, " LIMIT 5")
  rs1 <- dbSendQuery(conn, sql)
  fetch <- dbFetch(rs1, n = -1)

  cat(paste("Returning", length(FetchSamples), " samples from r-db schema.", "\n"))

  fetch
}
