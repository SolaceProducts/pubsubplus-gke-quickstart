#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
## Params:
# PUBSUBPLUS_IMAGE_URL can be a Docker image name from an accessible registry, a download URL or a local file
PUBSUBPLUS_IMAGE_URL="${PUBSUBPLUS_IMAGE_URL:-solace/solace-pubsub-standard:latest}"
# GCR_HOST is the fully qualified hostname of the GCR server
GCR_HOST="${GCR_HOST:-gcr.io}"
# The GCR project, default is the current GCP project id
GCR_PROJECT="${GCR_PROJECT:-`gcloud info | tr -d '[]' | awk '/project:/ {print $2}'`}"
##
if [ "$#" -gt  "0" ] ; then
  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    # Provide help if needed
    echo "Usage:
    # First assign params to the env to be used by the script:
    # PUBSUBPLUS_IMAGE_URL defaults to solace/solace-pubsub-standard:latest from Docker Hub
    [PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \\
    # GCR_HOST defaults to gcr.io
    [GCR_HOST=<hostname>] \\
    # GCR_PROJECT defaults to the current GCP project
    [GCR_PROJECT=<project>] \\
    copy_docker_image_to_gcr.sh

    Check script inline comments for more details."
    exit 1
  fi
fi
##
echo "Using:"
echo "PUBSUBPLUS_IMAGE_URL=$PUBSUBPLUS_IMAGE_URL"
echo "GCR_HOST=$GCR_HOST"
echo "GCR_PROJECT=$GCR_PROJECT"
echo
echo "#############################################################"
# check pre-requisites gcloud and docker
command -v gcloud >/dev/null 2>&1 || { echo >&2 "'gcloud' must be installed, aborting."; exit 1; }
if ! docker images >/dev/null 2>&1 || ! service docker status | grep -o running >/dev/null ; then
  echo "'docker' must be installed, running and accessible from current user."
  exit 1
fi
# Remove any existing Solace image from local docker registry
if [ "`docker images | grep solace-`" ] ; then
  echo "Cleaning existing Solace images from local docker repo"
  docker rmi -f `docker images | grep solace- | awk '{print $3}'` > /dev/null 2>&1
fi
# Loading provided Solace image reference
echo "Trying to load ${PUBSUBPLUS_IMAGE_URL} as Docker ref into local Docker registry..."
if ! docker pull ${PUBSUBPLUS_IMAGE_URL} ; then
  echo "Loading as Docker ref failed, retrying to load as local file..."
  if ! docker load -i ${PUBSUBPLUS_IMAGE_URL} ; then
    echo "Loading as a local file failed, retrying as a download link"
    if [[ ${PUBSUBPLUS_IMAGE_URL} == *"solace.com/download"* ]]; then
      MD5_URL=${PUBSUBPLUS_IMAGE_URL}_MD5
    else
      MD5_URL=${PUBSUBPLUS_IMAGE_URL}.md5
    fi
    wget -q -O solos.info -nv  ${MD5_URL}
    IFS=' ' read -ra SOLOS_INFO <<< `cat solos.info`
    MD5_SUM=${SOLOS_INFO[0]}
    SolOS_LOAD=${SOLOS_INFO[1]}
    if [ -z ${MD5_SUM} ]; then
      echo "Missing md5sum for the Solace load, tried ${PUBSUBPLUS_IMAGE_URL}.md5 - exiting."
      exit 1
    fi
    echo "Reference md5sum is: ${MD5_SUM}"
    echo "Now downloading URL provided and validating"
    wget -q -O  ${SolOS_LOAD} ${PUBSUBPLUS_IMAGE_URL}
    ## Check MD5
    LOCAL_OS_INFO=`md5sum ${SolOS_LOAD}`
    IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
    LOCAL_MD5_SUM=${SOLOS_INFO[0]}
    if [ -z "${MD5_SUM}" ] || [ "${LOCAL_MD5_SUM}" != "${MD5_SUM}" ]; then
      echo "Possible corrupt Solace load, md5sum do not match - exiting."
      exit 1
    else
      echo "Successfully downloaded ${SolOS_LOAD}"
    fi
    ## Load the image tarball
    docker load -i ${SolOS_LOAD}
    rm solos.info ${SolOS_LOAD} # cleanup local files
  fi
fi
# Determine image details
SOLACE_IMAGE_ID=`docker images | grep solace | awk '{print $3}'`
if [ -z "${SOLACE_IMAGE_ID}" ] ; then
  echo "Could not load a valid Solace docker image - exiting."
  exit 1
fi
echo "Loaded ${PUBSUBPLUS_IMAGE_URL} to local docker repo"
SOLACE_IMAGE_NAME=`docker images | grep solace | awk '{split($0,a,"solace/"); print a[2]}' | awk '{print $1}'`
if [ -z $SOLACE_IMAGE_NAME ] ; then SOLACE_IMAGE_NAME=`docker images | grep solace | awk '{print $1}'`; fi
SOLACE_IMAGE_TAG=`docker images | grep solace | awk '{print $2}'`
SOLACE_GCR_IMAGE=${GCR_PROJECT}/${SOLACE_IMAGE_NAME}:${SOLACE_IMAGE_TAG}
# Tag and load to GCR now
docker_hub_solace=${PUBSUBPLUS_IMAGE_URL}
docker_gcr_solace="${GCR_HOST}/${SOLACE_GCR_IMAGE}"
docker tag $SOLACE_IMAGE_ID "$docker_gcr_solace"
docker push "$docker_gcr_solace" || { echo "Push to GCR failed, ensure it is accessible and Docker is logged in with the correct user"; exit 1; }
echo "Success - GCR image location: $docker_gcr_solace"
