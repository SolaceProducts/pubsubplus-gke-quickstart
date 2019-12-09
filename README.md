[![Build Status](https://travis-ci.org/SolaceProducts/solace-gke-quickstart.svg?branch=master)](https://travis-ci.org/SolaceProducts/solace-gke-quickstart)

# Deploying a Solace PubSub+ Software Event Broker HA group onto a Google Kubernetes Engine (gke) cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to show you how to deploy Solace PubSub+ software event brokers in an HA configuration on a 3 node Google Kubernetes Engine (GKE) cluster spread across 3 zones.

![alt text](/images/network_diagram.png "Network Diagram")

- Purple        - Data – Client data including active node management.
- Blue          - DNS  – HA node discovery.
- Black         - Disk – Persistent disk mount.
- Orange/Yellow - Mgmt – Direct CLI/SEMP.

## Description of Solace PubSub+ Software Event Broker

The Solace PubSub+ software event broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to Deploy a Solace PubSub+ Software Event Broker onto GKE

This is a 5 step process:

[//]:# (Section 1 prereq is direct copy from here:  https://cloud.google.com/container-registry/docs/quickstart )

### Step 1: Create a project in Google Cloud Platform and enable prerequisites

* In the Cloud Platform Console, go to the Manage Resources page and select or create a new project.

    [GO TO THE MANAGE RESOURCES PAGE](https://console.cloud.google.com/projectselector/iam-admin/projects )

* Enable billing for your project by following this link.

    [ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

* Enable the Container Registry API by following this link and selecting the project you created above.

    [ENABLE THE API](https://console.cloud.google.com/flows/enableapi?apiid=containerregistry.googleapis.com)


<br>
<br>

### Step 2: Obtain a reference to the docker image of the Solace  PubSub+ event broker to be deployed

First, decide which [Solace PubSub+ event broker](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm ) and version is suitable to your use case.

The docker image reference can be:

*	A public or accessible private docker registry repository name with an optional tag. This is the recommended option if using PubSub+ Standard. The default is to use the latest event broker image [available from Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/ ) as `solace/solace-pubsub-standard:latest`, or use a specific version [tag](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ).

*	A docker image download URL
     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

     * If you have purchased a Docker image of Solace PubSub+ Enterprise, Solace will give you information for how to download the compressed tar archive package from a secure Solace server. Contact Solace Support at support@solace.com if you require assistance. Then you can host this tar archive together with its MD5 on a file server and use the download URL as the image reference.

### Step 3 (Optional): Place the event broker in Google Container Registry, using a script

**Hint:** You may skip this step if using the free PubSub+ Standard Edition available from the [Solace public Docker Hub registry](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ). The docker registry reference to use will be `solace/solace-pubsub-standard:<TagName>`. 

* The script can be executed from an installed Google Cloud SDK Shell or open a Google Cloud Shell from the Cloud Platform Console.

   * If using Google Cloud SDK Shell, also setup following dependencies:
      * docker and gcloud CLI installed
      * use `gcloud init` to setup account locally
      * proper Google Cloud permissions have been set: `container.clusterRoleBindings.create` permission is required
      * [authenticate to the container registry](//cloud.google.com/container-registry/docs/advanced-authentication), running `gcloud auth configure-docker`

   * If using the Cloud Shell from the Cloud Platform Console, it can be started in the browser from the red underlined icon in the upper right:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>
<br>

* Get and use the script:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/copy_solace_image_to_gkr.sh
chmod +x copy_solace_image_to_gkr.sh
# Note how the parameter is assigned through setting env for the script
SOLACE_IMAGE_REF=<solace-image-location> ./copy_solace_image_to_gkr.sh
```

`<solace-image-location>` can be one of the followings:
- name of a Docker image from a publicly available Docker image registry (default is `solace/solace-pubsub-standard:latest`)
- a Solace Docker image download URL obtained from the [Solace Downloads site](//solace.com/downloads/)
- a web server download URL - the corresponding `md5` file must be collocated with the Solace Docker image
- path to a Solace Docker image tar.gz file in the local file system

Run `./copy_solace_image_to_gkr.sh -h` for additional help.

<br>

* The script will end with showing the "GCR image location" required for [Step 5](https://github.com/SolaceDev/solace-gke-quickstart/tree/SolaceDockerHubSupport#step-5-use-google-cloud-sdk-or-cloud-shell-to-deploy-solace-message-broker-pods-and-service-to-that-cluster ).  You can view the new entry on the Google Container Registry in the Cloud Platform Console:

![alt text](/images/google_container_registry.png "Google Container Registry")

<br>
<br>

### Step 4: Use Google Cloud SDK or Cloud Shell to create the three node GKE cluster

* Download and execute the cluster creation script. Accept the default values for all the script's arguments if you were setting up and running a single event broker; however, some need to be changed to support the 3 node HA cluster. If you want to run the HA cluster in a single GCP zone, specify `-n = 3` as the number of nodes per zone and a single `-z <zone>`. If you want the HA cluster spread across 3 zones within a region - which is the configuration recommended for production situations - specify the 3 zones as per the example below, but leave the number of nodes per zone at the default value of 1.

**Important:** if connecting Solace brokers across GCP regions, there is a known issue affecting TCP throughput with the default node OS image type Ubuntu and default settings. In this case additionally specify the node image as Container-Optimized OS (cos) and a flag to apply performance tuning: `-i cos -p`. 

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/create_cluster.sh
chmod 755 create_cluster.sh
./create_cluster.sh -z us-central1-b,us-central1-c,us-central1-f
```

This will create a GKE cluster of 3 nodes spread across 3 zones:

![alt text](/images/Nodes_across_zones.png "Google Container Engine nodes")

Here are more GKE `create_cluster.sh` arguments you may need to consider changing for your deployment:

* The default cluster name is `solace-cluster` which can be changed by specifying the `-c <cluster name>` command line argument.

* The default machine type is "n1-standard-4". To use a different [Google machine type](https://cloud.google.com/compute/docs/machine-types ), specify `-m <machine-type>`. Note that the minimum CPU and memory requirements must be satisfied for the targeted event broker size, see the next step.

* The default node OS image type is Ubuntu. Specify [other node image type](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images ) using `-i <image-type>`

<br>

You can check that the Kubernetes deployment on GKE is healthy with the following command (which should return a single line with svc/kubernetes):

```sh
kubectl get services
```
If this fails, you will need to [troubleshoot GKE](https://cloud.google.com/kubernetes-engine/docs/support ).

Also note that during installation of GKE and release Solace HA, several GCP resources, such as GCE nodes, disks and load balancers, are created.  After deleting a Kubernetes release you should validate that all its resources are also deleted.  The [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#deleting-a-deployment) ) describes how to delete a release. If it is necessary to delete the GKE cluster refer to the [Google Cloud Platform documentation](https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete ).

<br>
<br>

### Step 5: Use Google Cloud SDK or Cloud Shell to deploy Solace event broker Pods and Service to that cluster

Now that the GKE environment is ready, follow the steps in [the PubSub+ Kubernetes Quickstart](https://github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg) to deploy a single-node or an HA event broker.

Refer to the PubSub+ Kubernetes documentation for
* [Validating the deployment](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#validating-the-deployment); or
* [Troubleshooting](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#troubleshooting)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceProducts/solace-gke-quickstart/graphs/contributors ) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

* The Solace Developer Portal website at: http://dev.solace.com
* Understanding [Solace technology.](http://dev.solace.com/tech/)
* Ask the [Solace community](http://dev.solace.com/community/).