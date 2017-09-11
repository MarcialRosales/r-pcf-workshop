PCF workshop for R Developers
==

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Introduction](#Introduction)
- [Pivotal Cloud Foundry Technical Overview](#pivotal-cloud-foundry-technical-overview)
- [Orgs, Spaces and Users](orgsSpacesUsers-README.md)
- [Deploying simple apps](#deploying-simple-apps)
  - [Lab - Deploy web site](#Deploy-web-site)
- [Cloud Foundry services](#cloud-foundry-services)
  - [Lab - Load data from a database](#access-database)  
  - [Lab - Manipulate files from an external file system](#access-files)
  - [Deploying applications with application manifest](#deploying-applications-with-application-manifest)
	- [Platform guarantees](#Platform-guarantees)
- [Quick Introduction to Buildpacks](#quick-intro-buildpack)  
- [Troubleshooting](#Troubleshooting)
- [Routes and Domains](#routes-and-domains)
  - [Lab - Private and Public routes/domains](#private-and-public-routesdomains)
  - [Lab - Blue-Green deployment](#blue-green-deployment)
  - [Lab - Routing Services](#routing-services)
- [Domains & Routing Services](#domains)
  -	[Private and public routess](#domains1)
  -	[Blue/Green deployment](#domains2)

<!-- /TOC -->
---

# Introduction

## Prerequisites

- R installed
- Latest git client
- CF client (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
- `curl` or `Postman` (https://www.getpostman.com/) or similar http client.
- Ideally, a github account but not essential.
`git clone https://github.com/MarcialRosales/r-pcf-workshops.git`

# Pivotal Cloud Foundry Technical Overview

Reference documentation:
- https://docs.pivotal.io
- [Elastic Runtime concepts](http://docs.pivotal.io/pivotalcf/concepts/index.html)


# Deploying simple apps

CloudFoundry excels at the developer experience: deploy, update and scale applications on-demand regardless of the application stack (java, php, node.js, go, etc).  We are going to learn how to deploy static web pages, and R applications without writing any logic/script to make it happen.

Reference documentation:
- [Using Apps Manager](http://docs.pivotal.io/pivotalcf/1-9/console/index.html)
- [Using cf CLI](http://docs.pivotal.io/pivotalcf/1-9/cf-cli/index.html)
- [Deploying Applications](http://docs.pivotal.io/pivotalcf/1-9/devguide/deploy-apps/deploy-app.html)
- [Deploying with manifests](http://docs.pivotal.io/pivotalcf/1-9/devguide/deploy-apps/manifest.html)

# <a name="Deploy-web-site"></a> Lab - Deploy web site
Very simple static web site to get used to Cloud Foundry command-line and concepts and also to see that the developers experience is the same regardless of the type of application we are deploying.

1. Go the project
  `cd example-00`
2. Deploy the application
  `cf push api-docs`
3. Check the application is deployed
  `cf apps`
  `cf app api-docs`
4. Go to the browser and test the application


# Cloud Foundry services
In **Cloud** environments, Cloud Native applications should follow the [12 Factors](https://12factor.net/config), specially the 3rd factor that says "Environment related configuration is provided via environment variables". In Cloud Foundry, the *Connection strings* to services like databases is provided via the `VCAP_SERVICES` variable.

## Quick introduction to Services

  `cf marketplace`  Check out what services are available

  `cf marketplace -s p-mysql pre-existing-plan ...`  Check out the service details like available plans

  `cf create-service ...`   Create a service instance with the name `flight-repository`

  `cf service ...`  Check out the service instance. Is it ready to use?

  `cf env flight-availability` Check the environment variables attached to our application


## Container/App Environment variables

PCF uses environment variables to communicate environment's configuration such as name of the app, on which port is listening, etc.
The environment variables PCF inject on each application's container are :
- `VCAP_APPLICATION` - It contains Application attributes such as version, instance index, limits, URLs, etc.
- `VCAP_SERVICES` - It contains bound services: name, label, credentials, etc.
- `CF_INSTANCE_*` like `CF_INSTANCE_ADDR`, `CF_INSTANCE_INDEX`, etc.

Example of `VCAP_APPLICATION`:
  ```
  ￼"VCAP_APPLICATION": {
    "application_id": "95bb5b8e-3d35-4753-86ee-2d9d505aec7c", "application_name": "fortuneService",
    "application_uris": [
      "fortuneservice-glottologic-neigh.apps.testcloud.com" ],
    "application_version": "40933f4c-75c5-4c61-b369-018febb0a347", "cf_api": "https://api.system.testcloud.com",
    "limits": {
      "disk": 1024, "fds": 16384, "mem": 512
    },
    "name": "fortuneService",
    "space_id": "86111584-e059-4eb0-b2e6-c89aa260453c", "space_name": "test",
    "uris": [
      "fortuneservice-glottologic-neigh.apps.testcloud.com" ],
    "users": null,
    "version": "40933f4c-75c5-4c61-b369-018febb0a347"
  }
  ```

## <a name="access-database"></a> Lab - Load data from a database
Very simple R/Shiny application to demonstrate how to get it running in PCF thanks to https://github.com/wjjung317/heroku-buildpack-r.

1. `cd example-01`
2. `cf push`
3. Go to the browser and test the application

> Lessons Learnt: Install the package Cairo (see init.r) to force R to use Cairo graphic library very much needed to render plots. By default, R uses X11 to render plots. However, in certain runtime environments like PCF, there is no X11 system available. So we have to tell R to use Cairo or any other R graphic library.

### Run it with Docker

1. `cd example-01`
2. `docker build -t dummyR .`
3. `docker run -p 8080:8080 dummyR`
4. Go the browser and test the application on port 8080. If you are using native docker, go to localhost:8080. If you are using docker-machine, go to the url reported here `docker-machine env <your-machine-name>`.

> We could have excluded the application from the docker image and simply mount it as a volume so that we can reuse the image for other applications.

### Connect to a managed database

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

## <a name="access-files"></a>Lab - Manipulate files from an external file system

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

# <a name="quick-intro-buildpack"></a> Quick Introduction to Buildpacks

> Note: Continue with slides "06-buildpacks.ppt"

Why buildpacks?
- Control what frameworks/runtimes are used on the platform
- Provides consistent deployments across environments:
  - Stops deployments from piling up at operation’s doorstep
  - Enables a self-service platform
- Eases ongoing operations burdens:
  - Security vulnerability is identified
  - Subsequently fixed with a new buildpack release
  - Restage applications


We have pushed two applications, an R application and a static web site. We know to deploy a static web site we need a web server like Apache or Nginx. And to deploy an R application we need the R runtime.

From [Static buildpack](https://docs.cloudfoundry.org/buildpacks/staticfile/#staticfile) ...
> Cloud Foundry requires a file named Staticfile in the root directory of the app to use the Staticfile buildpack with the app.

From [R buildpack](https://github.com/wjjung317/heroku-buildpack-r#usage) ...
> The buildpack will detect your app makes use of R if it has the init.r file in the root. The R runtime is vendored into your slug, and includes the gcc compiler for fortran support.

## Deploying applications with application manifest

Rather than passing a potentially long list of parameters to `cf push` we are going to move those parameters to a file so that we don't need to type them everytime we want to push an application. This file is called  *Application Manifest*.

The equivalent *manifest* file for the command `cf push flight-availability -p  publish -i 2 --hostname fa` is:

```
---
applications:
- name: flight-availability
  instances: 2
  path: publish
  host: fa
```


*Things we can do with the manifest.yml file* (more details [here](http://docs.pivotal.io/pivotalcf/1-9/devguide/deploy-apps/manifest.html))
- [ ] simplify push command with manifest files (`-f <manifest>`, `-no-manifest`)
- [ ] register applications with DNS (`domain`, `domains`, `host`, `hosts`, `no-hostname`, `random-route`, `routes`). We can register http and tcp endpoints.
- [ ] deploy applications without registering with DNS (`no-route`) (for instance, a messaging based server which does not listen on any port)
- [ ] specify compute resources : memory size, disk size and number of instances!! (Use manifest to store the 'default' number of instances ) (`instances`, `disk_quota`, `memory`)
- [ ] specify environment variables the application needs (`env`)
- [ ] as far as CloudFoundry is concerned, it is important that application start (and shutdown) quickly. If we are application is too slow we can adjust the timeouts CloudFoundry uses before it deems an application as failed and it restarts it:
	- `timeout` (60sec) Time (in seconds) allowed to elapse between starting up an app and the first healthy response from the app
	- `env: CF_STAGING_TIMEOUT` (15min) Max wait time for buildpack staging, in minutes
	- `env: CF_STARTUP_TIMEOUT` (5min) Max wait time for app instance startup, in minutes
- [ ] CloudFoundry is able to determine the health status of an application and restart if it is not healthy. We can tell it not to check or to checking the port (80) is opened or whether the http endpoint returns a `200 OK` (`health-check-http-endpoint`, `health-check-type`)
- [ ] CloudFoundry builds images from our applications. It uses a set of scripts to build images called buildpacks. There are buildpacks for different type of applications. CloudFoundry will automatically detect the type of application however we can tell CloudFoundry which buildpack we want to use. (`buildpack`)
- [ ] specify services the application needs (`services`)

## Platform guarantees

We have seen how we can scale our application (`cf scale -i #` or `cf push  ... -i #`). When we specify the number of instances, we create implicitly creating a contract with the platform. The platform will try its best to guarantee that the application has those instances. Ultimately the platform depends on the underlying infrastructure to provision new instances should some of them failed. If the infrastructure is not ready available, the platform wont be able to comply with the contract. Besides this edge case, the platform takes care of our application availability.

> Reference docs: https://docs.cloudfoundry.org/devguide/deploy-apps/healthchecks.html

Let's try to simulate our application crashed. To do so go to the home page and click on the link `KillApp`.

If we have +1 instances, we have zero-downtime because the other instances are available to receive requests while PCF creates a new one. If we had just one instance, we have downtime of a few seconds until PCF provisions another instance33.

The platform uses the health-check-type configured for the application in order to monitor and determine its status.  There are several types of `health-check-type`: `process` (only necessary when we dont expose any TPC port), `port` (default) and `http` (it must expose a http port and must return 200 OK. We can specify the endpoint with `--endpoint <path>`).

# <a name="troubleshooting-hints"></a> Troubleshooting hints

## Find the cell(s) an application is running on
Sometimes the application fails we don't really understand why it is failing. There is nothing the logs. We want to access the physical VM where the application's container is running.

  ```
  cf app APPNAME --guid
  cf curl /v2/apps/c6d1259c-8057-489e-9ac2-beaa896c2bf3/stats | jq 'with_entries(.value = .value.stats.host)'
  ```
Use the bosh vms command to correlate the IPs to BOSH job indexes or VM UUIDs.

## Download application droplet
You want to know exactly which files and directory layout our application is running with. Maybe we are testing some custom buildpack and we want to test that it has inserted all the required files.


    ```
    cf app myappname --guid
    mkdir /tmp/droplet && cd /tmp/droplet
    cf curl /v2/apps/9caddd73-706c-4f82-bb63-b1435bd6240d/droplet/download > droplet.tar.gz
    tar -zxf droplet.tar.gz
    ```

# <a name="domains"></a>Domains & Routing Services

> Use slides: 07.1-domains-and-routes.ppt

## <a name="domains1"></a> Private and public routes

## <a name="domains2"></a>Blue/Green deployment

Lab: Apply blue-green deployment with some of the applications we have pushed so far.
