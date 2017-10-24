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
cluster_name="solace-vmr-cluster"
machine_type="n1-standard-2"
number_of_nodes="1"
zone="us-central1-b"
verbose=0

while getopts "c:m:n:z:" opt; do
    case "$opt" in
    c)  cluster_name=$OPTARG
        ;;
    m)  machine_type=$OPTARG
        ;;
    n)  number_of_nodes=$OPTARG
        ;;
    z)  zone=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "`date` INFO: cluster_name=${cluster_name}, machine_type=${machine_type}, number_of_nodes=${number_of_nodes} zone=${zone} ,Leftovers: $@"

echo "`date` INFO: INITIALIZE GCLOUD"
echo "#############################################################"
gcloud components install kubectl
gcloud config set compute/zone ${zone}

echo "`date` INFO: CREATE CLUSTER"
echo "#############################################################"
gcloud container clusters create ${cluster_name} --machine-type=${machine_type} --num-nodes=${number_of_nodes}
gcloud container clusters get-credentials ${cluster_name}