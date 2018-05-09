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

# The purpose of this script is to:
#  - take a URL to a Solace VMR docker container
#  - validate the container against known MD5
#  - load the container to create a local instance
#  - upload the instance into google container registery
#  - clean up load docker

OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
solace_url=""

verbose=0

while getopts "u:" opt; do
    case "$opt" in
    u)  solace_url=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "`date` INFO: solace_url=$solace_url ,Leftovers: $@"

solace_directory=.

echo "###############################################################"
wget -q -O solace-redirect ${solace_url}
if [[ ${solace_url} == *"em.solace.com"* ]]; then
  wget -q -O ${solace_directory}/solace-redirect ${solace_url} || echo "There has been an issue with downloading the redirect"
  REAL_LINK=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=%]*" ${solace_directory}/solace-redirect`
  LOAD_NAME="`echo $REAL_LINK | awk -v FS="(download/|?)" '{print $2}'`"
  # a redirect link provided by solace
  wget -O ${solace_directory}/solos.info -nv  https://products.solace.com/download/${LOAD_NAME}_MD5
else
  REAL_LINK=${solace_url}
  # an already-existing load (plus its md5 file) hosted somewhere else (e.g. in an s3 bucket)
  wget -O ${solace_directory}/solos.info -nv  ${solace_url}.md5
fi

IFS=' ' read -ra SOLOS_INFO <<< `cat ${solace_directory}/solos.info`
MD5_SUM=${SOLOS_INFO[0]}
SolOS_LOAD=${SOLOS_INFO[1]}
if [ -z ${MD5_SUM} ]; then
  echo "`date` ERROR: Missing md5sum for the Solace load" | tee /dev/stderr | tee /dev/stderr
  exit 1
fi
echo "`date` INFO: Reference md5sum is: ${MD5_SUM}"

echo "`date` INFO: Download from URL provided and validate"
wget -q -O  ${solace_directory}/${SolOS_LOAD} ${REAL_LINK}

LOCAL_OS_INFO=`md5sum ${SolOS_LOAD}`
IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
LOCAL_MD5_SUM=${SOLOS_INFO[0]}
if [ ${LOCAL_MD5_SUM} != ${MD5_SUM} ]; then
  echo "`date` ERROR: Possible corrupt Solace load, md5sum do not match" | tee /dev/stderr
  exit 1
else
  echo "`date` INFO: Successfully downloaded ${SolOS_LOAD}"
fi

echo "`date` INFO: LOAD DOCKER IMAGE INTO LOCAL REGISTRY"
echo "########################################################################"
if [ `docker images "solace-*" -q` ] ; then docker rmi -f `docker images "solace-*" -q`; fi;
docker load -i ${solace_directory}/${SolOS_LOAD}

local_repo=`docker images "solace-*" | grep solace`
echo "`date` INFO: Current docker images are:"
echo ${local_repo}

repoName=`echo $local_repo | awk '{print$1}'`
tag=`echo $local_repo | awk '{print$2}'`
imageId=`echo $local_repo | awk '{print$3}'`

echo "`date` INFO: PUSH SOLACE VMR INSTANCE INTO GOOGLE CONTAINER REGISTRY"
echo "##########################################################################################"
if [ -z ${DEVSHELL_PROJECT_ID} ]; then DEVSHELL_PROJECT_ID=`gcloud projects list | awk 'FNR>1 {print$1}'`; fi
docker tag ${imageId} gcr.io/${DEVSHELL_PROJECT_ID}/${repoName}:${tag}
gcloud docker -- push gcr.io/${DEVSHELL_PROJECT_ID}/${repoName}:${tag}

echo "`date` INFO: CLEANUP"
echo "##########################################"

docker rmi gcr.io/${DEVSHELL_PROJECT_ID}/${repoName}:${tag}
docker rmi ${imageId}

export SOLACE_IMAGE_URL=gcr.io/${DEVSHELL_PROJECT_ID}/${repoName}:${tag}
echo "`date` INFO: Record the image reference in the GCR you will need to for next steps"
echo "SOLACE_IMAGE_URL=${SOLACE_IMAGE_URL}"
