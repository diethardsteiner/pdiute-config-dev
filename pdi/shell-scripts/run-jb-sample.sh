#!/bin/sh
# specify the path to the job as of the pdi/jobs-and-transformations directory
# if the job is exactly in this directory, just specify /
JOB_PATH="/"
# specify the PDI job name - with extension for file-based approach, otherwise without
JOB_NAME="jb_sample.kjb"

## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##                      ______________________                        ##

#BASE_DIR=$(dirname 0)
# to make it run with crontab as well
BASE_DIR="$( cd "$( /usr/bin/dirname "$0" )" && pwd )"
echo "The run shell script is running from following directory: ${BASE_DIR}"
# the repo name has to be the env name
source ${BASE_DIR}/wrapper.sh ${JOB_PATH} ${JOB_NAME}
