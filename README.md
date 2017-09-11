R Experiments
---

# Example 01
Very simple R/Shiny application to demonstrate how to get it running in PCF thanks to https://github.com/wjjung317/heroku-buildpack-r.

## Run it in PCF

1. `cd example-01`
2. `cf push`
3. Go to the browser and test the application

> Lessons Learnt: Install the package Cairo (see init.r) to force R to use Cairo graphic library very much needed to render plots. By default, R uses X11 to render plots. However, in certain runtime environments like PCF, there is no X11 system available. So we have to tell R to use Cairo or any other R graphic library.

## Run it with Docker

1. `cd example-01`
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

## Connect to a shared file system

Reference documentation:
- https://docs.pivotal.io/pivotalcf/1-11/devguide/services/using-vol-services.html

Cloud Foundry application developers may want their applications to mount one or more volumes in order to write to a reliable, non-ephemeral file system. If we expose NFSv3 file systems in the marketplace as a service, developers can create a file system on-demand and in an automated fashion.

1. Check if this **nfs** service is available in the marketplace. If there is no volume service check with your PCF administrator to enable it.
  `cf marketplace`
2. Once we have access to the **nfs** service, we need to get from the administrators the list of available *nfs volumes*.
3. Let's create a service instance for a given *nfs volume*.
  Syntax: `cf create-service SERVICE-NAME PLAN SERVICE-INSTANCE -c SHARE-JSON`
  e.g:
  `cf create-service nfs Existing testnfs_pn -c '{ "share": "172.19.255.35/pcf_dev_test3" }'`

  > SHARE-JSON (NFS Only): If you create an instance of the NFS volume service, you must supply an extra parameter, **share**, by using the -c flag with a JSON string, in-line or in a file. This parameter forwards information to the broker about the NFS server and share required for the service.

4. Let's now bind this service to the application(s) that should have access to the volume service.
  Syntax: `cf bind-service YOUR-APP SERVICE-NAME -c GID-AND-UID-JSON MOUNT-PATH-JSON`
  e.g:
  `cf bind-service flight-availability testnfs_pn -c '{"uid":"0","gid":"0","mount":"/home/data"}'`

  > GID-AND-UID-JSON (NFS only): If you bind an instance of the NFS volume service, you must supply two extra parameters, **gid** and **uid**. You can specify these parameters with the -c flag and a JSON string, in-line or from a file. This parameter specifies the gid and uid to use when mounting the share to the app.

5. We need to restage the application in order for our application to access the volume service.
  `cf restage flight-availability`


6. We can check the new credentials injected into our application
  ```
  VCAP_SERVICES": {
  "nfs": [
   {
    "credentials": {},
    "label": "nfs",
    "name": "testnfs2",
    "plan": "Existing",
    "provider": null,
    "syslog_drain_url": null,
    "tags": [
     "nfs"
    ],
    "volume_mounts": [
     {
      "container_dir": "/var/vcap/data/8bb74f2c-46da-44ce-a6aa-33d9c26ed8e0",
      "device_type": "shared",
      "mode": "rw"
     }
    ]

  ```

All our application has to do is read the `container_dir` attribute from the `VCAP_SERVICES`.

Let's move to the `example-02`. In this example we will demonstrate how to obtain the location of the NFS volume bound to our application and use the file system to demonstrate that it actually works.

Starting from the `example-01` we applied the following changes:

1. First we added a new file called `app/files.R` which simply adds a couple of functions to list and copies files but  more importantly declare a global variable which has the location of the volume service named `testnfs`. we can have more than one mount volume.
  `TEST_NFS_DIR = unlist(getVolumeDir("testnfs"))`
2. We added a new function to the `app/credentials.R` file so that we can look up volume services by name.
  ```
  getVolumeDir <- function(volumeName)
  {
    json <- Sys.getenv("VCAP_SERVICES")
    if (json == '')
    {
      stop("Missing VCAP_SERVICES")
    }
    vcapServices <- fromJSON(json, simplifyVector = FALSE, simplifyDataFrame = FALSE)

    for (serviceType in vcapServices)
    {
      for (service in serviceType)
      {
        if (service$name == volumeName) {
          return ( fromJSON(toJSON(service))$volume_mounts$container_dir )
        }
      }
    }
  }
  ```
3. And finally we make use of the `files.R` library in the `server.R`:
  ```
  source("files.R", local=environment())

  InitMySQL()

  # Define server logic required to generate and plot a random distribution
  shinyServer(function(input, output) {

    print(DirFiles())
    CopyFiles()
    ....

  ```
