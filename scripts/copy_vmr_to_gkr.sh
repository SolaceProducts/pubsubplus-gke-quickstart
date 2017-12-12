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

echo "`date` INFO: RETRIEVE SOLACE DOCKER IMAGE"
echo "#############################################################"
echo "`date` INFO: check to make sure we have a complete load"
wget -O ${solace_directory}/solos.info -nv  https://products.solace.com/download/VMR_DOCKER_EVAL_MD5
IFS=' ' read -ra SOLOS_INFO <<< `cat ${solace_directory}/solos.info`
MD5_SUM=${SOLOS_INFO[0]}
SolOS_LOAD=${SOLOS_INFO[1]}
echo "`date` INFO: Reference md5sum is: ${MD5_SUM}"

wget -q -O solace-redirect ${solace_url}
REAL_LINK=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=]*" ${solace_directory}/solace-redirect`
wget -q -O  ${solace_directory}/${SolOS_LOAD} ${REAL_LINK}
cd ${solace_directory}
LOCAL_OS_INFO=`md5sum ${SolOS_LOAD}`
IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
LOCAL_MD5_SUM=${SOLOS_INFO[0]}
if [ ${LOCAL_MD5_SUM} != ${MD5_SUM} ]; then
    echo "`date` WARN: Possible corrupt SolOS load, md5sum do not match"
else
    echo "`date` INFO: Successfully downloaded ${SolOS_LOAD}"
fi

echo "`date` INFO: LOAD DOCKER IMAGE INTO LOCALLY"
echo "##################################################################"
docker load -i ${solace_directory}/${SolOS_LOAD}

local_repo=`docker images solace-app | grep solace-app`
echo "`date` INFO: Current docker images are:"
echo ${local_repo}

tag=`echo $local_repo | awk '{print$2}'`
imageId=`echo $local_repo | awk '{print$3}'`

echo "`date` INFO: PUSH SOLACE VMR INSTANCE INTO GOOGLE CONTAINER REGISTRY"
echo "####################################################################################"
docker tag ${imageId} gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:${tag}
gcloud docker -- push gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:${tag}

echo "`date` INFO: Cleanup"
echo "#################################"

docker rmi gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:${tag}
docker rmi ${imageId}

export SOLACE_IMAGE=gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:${tag}
echo "`date` INFO: Record the image reference in the GCR you will need to for next steps"
echo "SOLACE_IMAGE=gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:${tag}"