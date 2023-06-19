FROM rocker/tidyverse:latest
RUN apt-get update && apt-get -y install default-jre-headless && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN install2.r --error \
	rJava \
	xlsx \
	GWASinspector
