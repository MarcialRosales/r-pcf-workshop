FROM r-base:latest

MAINTAINER Flavio Barros "flaviommbarros@gmail.com"

RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core

# Download and install shiny server
# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN mkdir -p /app/app
COPY init.r /app
COPY startscript.R /app
COPY app/* /app/app/

RUN R --no-save --gui-none < /app/init.r

ENV PORT 8080
EXPOSE 8080


WORKDIR /app

ENTRYPOINT R --no-save --gui-none < /app/startscript.R
