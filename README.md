[![Build Status](https://travis-ci.org/SolaceProducts/solace-gke-quickstart.svg?branch=master)](https://travis-ci.org/SolaceProducts/solace-gke-quickstart)

# Deploying a Solace PubSub+ Software Event Broker HA group onto a Google Kubernetes Engine (GKE) cluster

## Purpose of this repository

This repository extends the [PubSub+ Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to show you how to deploy Solace PubSub+ software event brokers on Google Kubernetes Engine (GKE).

The recommended Solace PubSub+ Software Event Broker version is 9.3 or later.

## Description of Solace PubSub+ Software Event Broker

The Solace PubSub+ software event broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to Deploy a Solace PubSub+ Software Event Broker onto GKE

The PubSub+ software event broker can be deployed in either a 3-node High-Availability (HA) cluster, or as a single-node non-HA deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

Detailed documentation of deploying the event broker in a Kubernetes environment is provided in the [Solace PubSub+ Event Broker on Kubernetes Guide](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md).

The following diagram illustrates an HA deployment on a 3 node GKE cluster spread across 3 zones.

![alt text](/images/network_diagram.png "Network Diagram")

- Purple        - Data – Client data including active node management.
- Blue          - DNS  – HA node discovery.
- Black         - Disk – Persistent disk mount.
- Orange/Yellow - Mgmt – Direct CLI/SEMP.

### Step 1: Access to GKE

Perform any prerequisites to access GKE from your command-line environment.  For specific details, refer to Google Cloud's [GKE documentation](https://cloud.google.com/kubernetes-engine/docs/quickstart).

Tasks may include:

* Get access to the Google Cloud Platform platform, [select or create a new project](//console.cloud.google.com/projectselector2/kubernetes) and enable billing.
* Install the Kubernetes [`kubectl`](//kubernetes.io/docs/tasks/tools/install-kubectl/ ) tool.
* Install the [`gcloud`](//cloud.google.com/sdk/gcloud/) command-line tool and initialize it running `gcloud init`.
* Create a GKE cluster. Ensure to meet [minimum CPU, Memory and Storage requirements](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#cpu-and-memory-requirements) for the targeted PubSub+ configuration size.
* Fetch the credentials for the GKE cluster.

Commands can be executed either from your local command-line interface after installing above tools, or open a Google Cloud Shell from the Cloud Platform Console, which already has the tools available:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>

If using an existing GKE cluster your admin shall be able to provide you with the [`gcloud container clusters get-credentials'](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials) command.

#### Creating a new GKE cluster

Download and execute the cluster creation script included in this repo as in the example below.

Script options and arguments:

* Default (no arguments): creates a one node GKE cluster, can be used if you were setting up and running a single-node event broker
* For a multi-node GKE-cluster in a single GCP zone, specify `-n = 3` as the number of nodes per zone and a single `-z <zone>`. 
* If you want the HA cluster spread across 3 zones within a region - which is the configuration recommended for production situations - specify the 3 zones as per the example below, but leave the number of nodes per zone at the default value of 1.
* The default cluster name is `solace-cluster` which can be changed by specifying the `-c <cluster name>` command line argument.
* The default machine type is "n1-standard-4". To use a different [Google machine type](https://cloud.google.com/compute/docs/machine-types ), specify `-m <machine-type>`. Note that the [minimum CPU and memory requirements](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#cpu-and-memory-requirements) must be satisfied for the targeted event broker size.
* The default node OS image type is Ubuntu. Specify [other node image type](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images ) using `-i <image-type>`

> **Important:** if connecting Solace brokers across GCP regions, there is a known issue affecting TCP throughput with the default node OS image type Ubuntu and default settings. In this case additionally specify the node image as Container-Optimized OS (cos) and a flag to apply performance tuning: `-i cos -p`. 

Example:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/create_cluster.sh
chmod +x create_cluster.sh
# Creates a recommended production-like deployment with 3 nodes across 3 availability zones
./create_cluster.sh -z us-central1-b,us-central1-c,us-central1-f
```

This will create a GKE cluster of 3 nodes spread across 3 zones and configure the required credentials to access this cluster from the command-line.

![alt text](/images/Nodes_across_zones.png "Google Container Engine nodes")

<br>

You can check that the Kubernetes deployment on GKE is healthy with the following command (which should return the available nodes with their status):

```sh
kubectl get nodes -o wide
```
If this fails, you will need to [troubleshoot GKE](https://cloud.google.com/kubernetes-engine/docs/support ).

<br>

### Step 2: Deploy Helm package manager

We recommend using the [Kubernetes Helm](//github.com/kubernetes/helm/blob/master/README.md ) tool to manage the deployment.

Refer to the [Install and configure Helm](https://github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg#2-install-and-configure-helm) section of the PubSub+ Kubernetes Quickstart.

<br>

### Step 3 (Optional): Load the PubSub+ Docker image to a private Docker image registry

**Hint:** You may skip the rest of this step if not using Google Container Registry (GCR) or other private Docker registry. The free PubSub+ Standard Edition is available from the [public Docker Hub registry](//hub.docker.com/r/solace/solace-pubsub-standard/tags/ ), the image reference is `solace/solace-pubsub-standard:<TagName>`.

To get the PubSub+ event broker Docker image URL, go to the Solace Developer Portal and download the Solace PubSub+ software event broker as a **docker** image or obtain your version from Solace Support.

| PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
| [Download Standard docker image](http://dev.solace.com/downloads/ ) | [Download Evaluation docker image](http://dev.solace.com/downloads#eval ) |

#### Loading the PubSub+ Docker image to Google Container Registry (GCR)

If using GCR for private Docker registry, use the `copy_docker_image_to_gcr.sh` script from this repo.

Prerequisites:
* local installation of [Docker](//docs.docker.com/get-started/ ) is required
* Ensure `gcloud init` is complete.

Script options and arguments:
* PUBSUBPLUS_IMAGE_URL: the PubSub+ docker image location, can be one of the followings:
  * name of a Docker image from a publicly available Docker image registry (default is `solace/solace-pubsub-standard:latest`)
  * a Solace Docker image download URL obtained from the [Solace Downloads site](//solace.com/downloads/)
  * a web server download URL - the corresponding `md5` file must be collocated with the Solace Docker image
  * path to a Solace Docker image tar.gz file in the local file system
* GCR_HOST: fully qualified hostname of the GCR server - default is `gcr.io`
* GCR_PROJECT: the GCR project, default is the current GCP project id

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/copy_docker_image_to_gcr.sh
chmod +x copy_docker_image_to_gcr.sh
# Define variables up-front to be passed to the "copy_docker_image_to_gcr" script:
  [PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \
  [GCR_HOST=<hostname>] \
  [GCR_PROJECT=<project>] \
  copy_docker_image_to_gcr.sh
```

The script will end with showing the "GCR image location" in `<your-image-location>:<your-image-tag>` format. You can view the new entry on the Google Container Registry in the Cloud Platform Console:

![alt text](/images/google_container_registry.png "Google Container Registry")

<br>

For general additional information, refer to the [Using private registries](https://github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#using-private-registries) section in the Kubernetes Guide.

### Step 4: Deploy the event broker

From here follow the steps in [the PubSub+ Kubernetes Quickstart](//github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg#2-install-and-configure-helm) to deploy a single-node or an HA event broker.

Refer to the detailed PubSub+ Kubernetes documentation for:
* [Validating the deployment](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#validating-the-deployment); or
* [Troubleshooting](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#troubleshooting)
* [Modifying or Upgrading](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment)
* [Deleting the deployment](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#deleting-a-deployment)

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