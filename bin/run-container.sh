#!/bin/bash
#
# run-container.sh
#
# This is a simple helper script to kick-off a container exection. Ensure the container is set.
# This script will read the following environment variables.
#   LOCAL_LIBS  Uses local libraries. Requires $HRIS_PYTHON_LIB and $HRIS_R_LIB to be set.
#   DEBUG       Gives a prompt in the container instead of running the container.
#   COPY        Indicates if the sample data should be copied onto the data folder.

CONTAINER="tesera/ktpi"

if [ ! -z ${COPY+x} ] && $COPY || [ ! -d "data" ]; then
  >&2 echo "Copying sample data"
  cp -rf sampleData data
fi

if [ ! -z ${LOCAL_LIBS+x} ] && $LOCAL_LIBS; then
  echo "using local libs"
  [ -z "$HRIS_PYTHON_LIB" ] && echo "You need to set \$HRIS_PYTHON_LIB." && exit 1
  [ -z "$HRIS_R_LIB" ] && echo "You need to set \$HRIS_R_LIB." && exit 1
  LOCAL_LIBS="-v ${HRIS_PYTHON_LIB}:/var/lib/hris-python-lib -v ${HRIS_R_LIB}:/var/lib/hris-r-lib"
else
  LOCAL_LIBS=""
fi

if [ ! -z ${DEBUG+x} ] && $DEBUG; then
  echo "debug mode"
  DEBUG="--entrypoint /bin/bash"
else
  DEBUG=""
fi

if [ ! -z ${RUNNER+x} ] && $RUNNER; then
  echo "Setting to runner mode"
  AWS_ACCESS_KEY_ID=$(aws --profile default configure get aws_access_key_id)
  AWS_SECRET_ACCESS_KEY=$(aws --profile default configure get aws_secret_access_key)
  QUEUE="${QUEUE:-https://sqs.us-west-2.amazonaws.com/073688489507/hris-runner}"
  INPUT_PATH="${INPUT_PATH:-H1649_Chinook\ Cohort_hris_inventory/working/6_Tiling/lidar/height}"
  RUNNER="--entrypoint /usr/local/hris-runner/index.js -e INPUT_PATH=$INPUT_PATH -e QUEUE=$QUEUE -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
else
  RUNNER=""
fi

DATA_MOUNT="-v "`pwd`"/data:/data"
OPTIONS="${DEBUG} ${DATA_MOUNT} ${LOCAL_LIBS} ${RUNNER}"
COMMAND="docker run ${OPTIONS} -i ${CONTAINER} ${@}"

eval $COMMAND