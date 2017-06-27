FROM alpine:edge
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk --update add --no-cache R R-dev g++ make gdal-dev@testing proj4-dev@testing

ENV PATH="/opt/ktpi:${PATH}"
ENV KTPIPATH /opt/ktpi
WORKDIR $KTPIPATH
RUN R -e 'install.packages("raster", repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("docopt", repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("rgdal", repos = "http://cran.us.r-project.org")'
COPY R/ /opt/ktpi

ENTRYPOINT ["ktpi.R"]
