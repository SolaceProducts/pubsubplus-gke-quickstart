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
solace_password=""
solace_image=""
zone="us-central1-b"
verbose=0

while getopts "i:p:z:" opt; do
    case "$opt" in
    i)  solace_image=$OPTARG
        ;;
    p)  solace_password=$OPTARG
        ;;
    z)  zone=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "`date` INFO: solace_image=$solace_image, zone=$zone ,Leftovers: $@"