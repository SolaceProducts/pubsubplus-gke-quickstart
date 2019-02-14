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
#  - create a GCP cluster to host a Solace PubSub+ message broker deployment


OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
cluster_name="solace-cluster"
machine_type="n1-standard-4"
image_type="UBUNTU"
number_of_nodes="1"
zones="us-central1-b"
bridge_perf_tune=false
verbose=0

while getopts "c:i:m:n:z:p" opt; do
    case "$opt" in
    c)  cluster_name=$OPTARG
        ;;
    i)  image_type=$OPTARG
        ;;
    m)  machine_type=$OPTARG
        ;;
    n)  number_of_nodes=$OPTARG
        ;;
    z)  zones=$OPTARG
        ;;
    p)  perf_tune=true
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "`date` INFO: cluster_name=${cluster_name}, machine_type=${machine_type}, image_type=${image_type}, number_of_nodes=${number_of_nodes}, zones=${zones}, perf_tune=${perf_tune} ,Leftovers: $@"

# multi-region bridge performance tuning
node_performance_tune () {
  command="echo '
  net.core.rmem_max = 134217728
  net.core.wmem_max = 134217728
  net.ipv4.tcp_rmem = 4096 25165824 67108864
  net.ipv4.tcp_wmem = 4096 25165824 67108864
  net.ipv4.tcp_mtu_probing=1' | sudo tee /etc/sysctl.d/98-solace-sysctl.conf ; sudo sysctl -p /etc/sysctl.d/98-solace-sysctl.conf"

  list=`gcloud compute instances list | grep gke-$1`
  echo 'Applying multi-region bridge performance tuning to nodes'
  while read -r a b c ; do
    echo $a
    gcloud compute ssh --ssh-flag="-T -o StrictHostKeyChecking=no" --zone $b $a -- "$command" &>/dev/null &
  done <<< "$list"
  wait
}


echo "`date` INFO: INITIALIZE GCLOUD"
echo "#############################################################"
IFS=',' read -ra zone_array <<< "$zones"
gcloud config set compute/zone ${zone_array[0]}

echo "`date` INFO: CREATE CLUSTER"
echo "#############################################################"
gcloud container clusters create ${cluster_name} --machine-type=${machine_type} --image-type=${image_type} --node-locations=${zones} --num-nodes=${number_of_nodes}
if $perf_tune ; then
  node_performance_tune ${cluster_name}
fi
gcloud container clusters get-credentials ${cluster_name}