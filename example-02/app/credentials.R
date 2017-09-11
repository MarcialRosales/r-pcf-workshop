library("jsonlite")

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

getCredentials <- function(serviceName)
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
      if (service$name == serviceName) {
        return ( fromJSON(toJSON(service))$credentials )
      }
    }
  }
}


traceJsonNode <- function(name, node, printNode = FALSE) {

  if (printNode == TRUE)  {
    cat(paste(name, "[", class(node), "]", length(node), "(", node, ")\n"))
  }else {
    cat(paste(name, "[", class(node), "]", length(node), "\n"))
  }
}
