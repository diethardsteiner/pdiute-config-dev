# Core Principals of this Setup

- PDI Flat files, no repo.
- Seperation of code and config: One code repo, one config repo for each environment.
- There is no concept of sharing config details across projects: This keeps the setup simple and in reality this approach is not often used any ways.
- `kettle.properties` file is specific to one project - no global sharing across all projects. All required parameters/properties should be stored in this file.

# Naming Convention

Some logic to automatically figure out project name and environment
This relies on following folder name conventions:

- one top level group folder - no specific naming convention
- within this folder:
  - one code folder: naming convention [project-acronym]-code, e.g. abc-code.
  - one config folder by environment: naming convention [project-acronym]-config-[environment]
  - project-acronym: only letters, no dashes, underscores, space etc 

# Setting up the Folder Structure

You can use this simple script:

- `pdi-unit-test-example` is the project group name here
- `pdiute` is the project acronym here

```bash
#!/bin/bash

# create project group folder
mkdir pdi-unit-test-example
cd pdi-unit-test-example

# create project repo
mkdir pdiute-code
cd pdiute-code

mkdir -p pdi/jobs-and-transformations
mkdir -p pdi/unit-test-datasets
mkdir -p pdi/metastore
mkdir -p pdi/sql
mkdir -p pentaho-server/dashboards
mkdir -p pentaho-server/mondrian
mkdir -p pentaho-server/metadata
mkdir shell-scripts

touch pdi/jobs-and-transformations/.gitignore
touch pdi/unit-test-datasets/.gitignore
touch pdi/metastore/.gitignore
touch pdi/sql/.gitignore
touch pentaho-server/dashboards/.gitignore
touch pentaho-server/mondrian/.gitignore
touch pentaho-server/metadata/.gitignore
touch shell-scripts/.gitignore

cd ..

# create config repo
mkdir pdiute-config-dev
cd pdiute-config-dev

mkdir -p pdi/shell-scripts
touch pdi/shell-scripts/run-jb-sample.sh
mkdir pentaho-server
touch pentaho-server/.gitignore
```

# Wrapper

In the environment specific config repo you will find following script: 

```
pdi/shell-scripts/wrapper.sh
```

## Purpose

The purpose of this script is twofold:

> **Important**: Make sure you add the `PENTAHO_METASTORE_FOLDER` parameter to the `OPT` section in PDI's `spoon.sh`.

### Define Environment For Spoon

If **no arguments** are passed, it will set the `KETTLE_HOME` and `PENTAHO_METASTORE_FOLDER` variables for the current shell - intention is that you run it like this:

```bash
source pdi/shell-scripts/wrapper.sh
```

This is mainly useful if you want to start **Spoon** from the **same shell** so that these config paths are correctly set.

### Define Environment For PDI Job

The recommended pattern is that you create one shell file for each job that you want to execute and then source the `wrapper.sh`, passing along the **path** to the job and the **name** of the job.

Example:

```bash
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
```

## Configuration

A lot configuration details are automatically derived from the folder name pattern described earlier on. The only variable you have to manually change is `PDI_DIR`.