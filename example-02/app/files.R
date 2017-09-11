source("credentials.R",  local=environment())

TEST_NFS_DIR = unlist(getVolumeDir("testnfs"))

CopyFiles <- function() {

  x <- 1:12
  targetFile <- paste(TEST_NFS_DIR, "/sample", sample(x)[1], ".csv", sep="" )
  file.copy("../data/sample.csv", targetFile, overwrite = TRUE)

}

DirFiles <- function() {

  cat(paste("Target folder:", TEST_NFS_DIR))

  DirFiles <- list.files(TEST_NFS_DIR)

}
