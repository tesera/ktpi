FROM tesera/r-spatial-raster
MAINTAINER Tesera Systems Inc.

RUN apt-get update && apt-get -y dist-upgrade

# Setup environment
ENV KTPIPATH /opt/ktpi

RUN mkdir $KTPIPATH
WORKDIR $KTPIPATH

CMD ["/bin/bash"]
