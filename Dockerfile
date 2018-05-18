FROM achubaty/r-spatial-base
MAINTAINER Tesera Systems Inc.

RUN apt-get update --fix-missing
RUN apt-get install -y libssl-dev

# Install R Dependencies
RUN R -e 'install.packages(c("docopt"))'
RUN R -e 'install.packages(c("jsonlite"))'
RUN mkdir -p /opt/ktpi

# Setup some ENV vars
ENV PATH="/root/ktpi:${PATH}"
ENV HRIS_R_LIB="/var/lib/hris-r-lib"
ENV HRIS_DATA="/data"

# Install project files
RUN mkdir -p /root/ktpi/
COPY ktpi.R /root/ktpi
COPY lib/ /root/ktpi/lib/

# Finally, set the container entrypoint
ENTRYPOINT ["ktpi.R"]
