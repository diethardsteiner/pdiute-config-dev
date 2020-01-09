#!/usr/bin/env zsh

# ======================= INPUT ARGUMENTS ============================ #

## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##                      ______________________                        ##


## ------ THIS MEANT TO WORK WITH A FLAT FILE PDI APPRACH ONLY ------ ##

# environmental argument parameter
if [ $# -eq 0 ]
  then
    echo "Setting environment variables for PDI Spoon ..."
elif [ -z "$1" ] || [ -z "$2" ]
  then
    echo "ERROR: Not all mandatory arguments supplied, please supply environment and/or job arguments"
    echo
    echo "Usage: wrapper.sh [JOB NAME] [JOB HOME]"
    echo "Run a wrapper PDI job to execute input PDI jobs"
    echo 
    echo "Mandatory arguments"
    echo
    echo "JOB_HOME:         The PDI repo path. Specify '/' if job located in root dir."
    echo "JOB_NAME:         The name of the target job to run from within the wrapper"
    echo
    echo "exiting ..."
    exit 1
  else
    # PDI repo relative path for home directory of project kjb files
    JOB_HOME="$1"
    echo "JOB_HOME: ${JOB_HOME}"
    # target job name (kjb file name)
    JOB_NAME="$2"
    echo "JOB_NAME: ${JOB_NAME}"
fi


# ============= PROJECT-SPECIFIC CONFIGURATION PROPERTIES ============ #

## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##                      ______________________                        ##

# some logic to automatically figure out project name and environment
# this relies on following folder name conventions:
# one top level group folder - no specific naming convention
# within this folder:
# one code folder: naming convention [project-acronym]-code, e.g. abc-code.
# one config folder by environment: naming convention [project-acronym]-config-[enviornment]
# project-acronym: only letters, no dashes, underscores, space etc 


# we have to get the path to this shell script from any location we execute this script from
# and with both ./ and source
# https://unix.stackexchange.com/questions/4650/determining-path-to-sourced-shell-script
# if [[ $0 != ${BASH_SOURCE} ]] 
#   then
#     echo "Script is being sourced"
#     # this didn't seem to work consistently across all versions of bash
#     # for both source and script approaches hence we use this if condition here
#     # WRAPPER_DIR=${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}
#     WRAPPER_DIR=${BASH_SOURCE%/*}
#   else
#     # There shouldn't really be a use case for running this script directly
#     echo "Script is being run"
#     WRAPPER_DIR="$( cd "$( /usr/bin/dirname "$0" )" && pwd )"
# fi
# this didn't work reliably - resorted to this:
# source: https://unix.stackexchange.com/questions/76505/portable-way-to-get-scripts-absolute-path
WRAPPER_DIR=${0:a:h}

# WRAPPER_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
echo "WRAPPER_DIR: ${WRAPPER_DIR}"

# Path to the root directory where the common and project specific git repos are stored in
#
# we know that this shell script runs from within the 
# `proj-config-env/pdi/shell-scripts` folder
# we want to get the path to proj-config-env folder
# so we can easily extract project and environment names
PROJECT_CONFIG_DIR=${WRAPPER_DIR%/*/*}
echo "PROJECT_CONFIG_DIR: ${PROJECT_CONFIG_DIR}"
# deployment dir is 4 levels up if common config is external
DEPLOYMENT_DIR=${WRAPPER_DIR%/*/*/*/*}
echo "DEPLOYMENT_DIR: ${DEPLOYMENT_DIR}"
# Get project group name
PROJECT_GROUP_DIR=${WRAPPER_DIR%/*/*/*}
echo "PROJECT_GROUP_DIR: ${PROJECT_GROUP_DIR}"
# Get name of project group folder 
PROJECT_GROUP_FOLDER_NAME=${PROJECT_GROUP_DIR##*/}
echo "PROJECT_GROUP_FOLDER_NAME: ${PROJECT_GROUP_FOLDER_NAME}"

# Extract project name and environment from the standardised project folder name
# The folder name gets initially standardised by the `initialise-repo.sh`
# Get last `/` and apply substring from there to the end
PROJECT_CONFIG_FOLDER_NAME=${PROJECT_CONFIG_DIR##*/}
echo "PROJECT_CONFIG_FOLDER_NAME: ${PROJECT_CONFIG_FOLDER_NAME}"
# Get substring from first character to first `-`
PROJECT_NAME=${PROJECT_CONFIG_FOLDER_NAME%%-*}
echo "PROJECT_NAME: ${PROJECT_NAME}"
# Get substring from last `-` to the end
PDI_ENV=${PROJECT_CONFIG_FOLDER_NAME##*-}
echo "ENVIRONMENT: ${PDI_ENV}"
# build path for project code dir
PROJECT_CODE_DIR=${PROJECT_GROUP_DIR}/${PROJECT_NAME}-code
echo "PROJECT_CODE_DIR: ${PROJECT_CODE_DIR}"
# path to di files root dir - used for file-based pdi approach 
PROJECT_CODE_PDI_DIR=${PROJECT_CODE_DIR}/pdi/jobs-and-transformations
echo "PROJECT_CODE_PDI_DIR: ${PROJECT_CODE_PDI_DIR}"
# Path to the environment specific common configuration
PROJECT_CONFIG_DIR="${DEPLOYMENT_DIR}/${PROJECT_GROUP_FOLDER_NAME}/${PROJECT_NAME}-config-${PDI_ENV}"
echo "PROJECT_CONFIG_DIR: ${PROJECT_CONFIG_DIR}"
# Absolute path for project log files
PROJECT_LOG_HOME="${PROJECT_GROUP_DIR}/logs/${PDI_ENV}"

# ============== PDI CONFIGURATION PROPERTIES =============== #

## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##

# `export` is valid in a session only and not globally
# each crontab entry gets its own session

# since code for different projects might run on the same server

# path to PDI installation
PDI_DIR=/home/dsteiner/apps/kettle-neo4j-remix-beam-8.2.0.7-719-REMIX
echo "PDI_DIR: ${PDI_DIR}"
export KETTLE_HOME=${PROJECT_CONFIG_DIR}/pdi
echo "KETTLE_HOME: ${KETTLE_HOME}"
# the below unit test parameters could be set in here as long as
# they are added to the OPT section of spoon.sh
export PENTAHO_METASTORE_FOLDER=${PROJECT_CODE_DIR}/pdi
echo "PENTAHO_METASTORE_FOLDER: ${PENTAHO_METASTORE_FOLDER}"
# path to the PDI unit test datasets
export DATASETS_BASE_PATH=${PROJECT_CODE_DIR}/pdi/unit-test-datasets
echo "DATASETS_BASE_PATH: ${DATASETS_BASE_PATH}"
export UNIT_TESTS_BASE_PATH=${PROJECT_CODE_DIR}/pdi/jobs-and-transformations
echo "UNIT_TESTS_BASE_PATH: ${UNIT_TESTS_BASE_PATH}"

# ============== JOB-SPECIFIC CONFIGURATION PROPERTIES =============== #

## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##                      ______________________                        ##


# if we just want to set the env variables for Spoon, then do not run this part
if [ ! -z "$1" ] && [ ! -z "$2" ]; then

  # Project logs file name
  JOB_LOG_FILE="${JOB_NAME}.err.log"
  # Project historic logs filename
  JOB_LOG_HIST_FILE="${JOB_NAME}.hist.log"
  
  
  START_DATETIME=`date '+%Y-%m-%d_%H-%M-%S'`
  START_UNIX_TIMESTAMP=`date "+%s"`
  
  
  mkdir -p ${PROJECT_LOG_HOME}
  
  
  echo "Location of log file: ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}"
  
  # remove old log file
  if [ -f "${PROJECT_LOG_HOME}/${JOB_LOG_FILE}" ]
  then
      echo "Removing old log file."
      rm ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}
  else
      echo "No old log file exists ... so nothing to do."
  fi
  
  
  # moved this further down since otherwise the kitchen logFile flag does not work
  # cat > ${PROJECT_LOG_HOME}/${JOB_LOG_FILE} <<EOL
  
  # Starting at: ${START_DATETIME}
  
  # -----------------------------------------------------------------------
  # Running script with the following environment variables:
  
  # PDI Environment (PDI_ENV):                   ${PDI_ENV}
  # Directory containing PDI installation:       ${PDI_DIR}
  # Location of Kettle properties (KETTLE_HOME): ${KETTLE_HOME}
  # Location of Kettle Metastore:                ${PENTAHO_METASTORE_FOLDER}
  # Location of Project Configuration:           ${PROJECT_CONFIG_DIR}
  # Location of Project Code:                    ${PROJECT_CODE_DIR}
  # PDI Job Directory and Filename:              ${JOB_HOME}${JOB_NAME}
  # Location of log file:                        ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}
  # -----------------------------------------------------------------------
  
  # EOL
  
  
  
  # ====================== PDI KITCHEN WRAPPER ========================= #
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
  ##                      ______________________                        ##
  
  
  cd ${PDI_DIR}
  
  # Note: the parameters passed here to the kitchen command have to be defined
  # as parameters in the Kettle/PDI job that gets called otherwise they won't
  # be passed on.
  
  ./kitchen.sh \
  -file="${PROJECT_CODE_PDI_DIR}/${JOB_HOME}/${JOB_NAME}" \
  -logfile=${PROJECT_LOG_HOME}/${JOB_LOG_FILE} \
  -param:PROJECT_CONFIG_DIR=${PROJECT_CONFIG_DIR} \
  -param:PROJECT_CODE_DIR=${PROJECT_CODE_DIR} \
  -param:JOB_LOG_FILE=${JOB_LOG_FILE} \
  -param:PDI_ENV=${PDI_ENV} \
  -param:PROJECT_NAME=${PROJECT_NAME} \
  2>&1
  
  
  RES=$?
  
    
  END_DATETIME=`date '+%Y-%m-%d_%H-%M-%S'`
  END_UNIX_TIMESTAMP=`date "+%s"`
  echo
  echo "End DateTime: ${END_DATETIME}" >> ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}

# the EOL section can't be indented - otherwise it will throw error 
cat >> ${PROJECT_LOG_HOME}/${JOB_LOG_FILE} <<EOL

Starting at: ${START_DATETIME}

-----------------------------------------------------------------------
Running script with the following environment variables:

PDI Environment (PDI_ENV):                   ${PDI_ENV}
Directory containing PDI installation:       ${PDI_DIR}
Location of Kettle properties (KETTLE_HOME): ${KETTLE_HOME}
Location of Kettle Metastore:                ${PENTAHO_METASTORE_FOLDER}
Location of Project Configuration:           ${PROJECT_CONFIG_DIR}
Location of Project Code:                    ${PROJECT_CODE_DIR}
PDI Job Directory and Filename:              ${JOB_HOME}${JOB_NAME}
Location of log file:                        ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}
-----------------------------------------------------------------------

EOL

  
  END_DATETIME=`date '+%Y-%m-%d_%H-%M-%S'`
  END_UNIX_TIMESTAMP=`date "+%s"`
  echo
  echo "End DateTime: ${END_DATETIME}" >> ${PROJECT_LOG_HOME}/${JOB_LOG_FILE}
  
  
  DURATION_IN_SECONDS=`expr ${END_UNIX_TIMESTAMP} - ${START_UNIX_TIMESTAMP}`
  #DURATION_IN_MINUTES=`echo "scale=0;${DURATION_IN_SECONDS}/60" | bc`
  DURATION_IN_SECONDS_MSG=`printf '%dh:%dm:%ds\n' $((${DURATION_IN_SECONDS}/(60*60))) $((${DURATION_IN_SECONDS}%(60*60)/60)) $((${DURATION_IN_SECONDS}%60))`
  
  # Project historic logs filename
  JOB_LOG_HIST_FILE="${JOB_NAME}.hist.log"
  # Project archive logs filename
  PROJECT_LOG_ARCHIVE_FILE="${JOB_NAME}_${END_DATETIME}.err.log"
  
  # Get the duration in human-readable format
  # DURATION=`grep "Processing ended after " ${PROJECT_LOG_HOME}/${JOB_LOG_FILE} | sed -n -e 's/^.*Processing ended after after //p'`
  
  echo "Result: ${RES}"
  # DURATION_IN_SECONDS calc missing
  echo "Start: ${START_DATETIME} END: ${END_DATETIME} Result: ${RES} Duration: ${DURATION_IN_SECONDS_MSG} - Duration in Seconds: ${DURATION_IN_SECONDS}s" >> ${PROJECT_LOG_HOME}/${JOB_LOG_HIST_FILE}
  cat ${PROJECT_LOG_HOME}/${JOB_LOG_FILE} > ${PROJECT_LOG_HOME}/${PROJECT_LOG_ARCHIVE_FILE}
  
  exit ${RES}
fi