[![Actions Status](https://github.com/SolaceProducts/pubsubplus-gke-quickstart/workflows/build/badge.svg?branch=master)](https://github.com/SolaceProducts/pubsubplus-gke-quickstart/actions?query=workflow%3Abuild+branch%3Amaster)

# Install a Solace PubSub+ Software Event Broker HA group onto a Google Kubernetes Engine (GKE) cluster

## Purpose of this repository

This repository extends the [PubSub+ Software Event Broker on Kubernetes Quickstart](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart ) to show you how to install Solace PubSub+ Software Event Broker onto Google Kubernetes Engine (GKE).

The recommended software event broker version is 9.4 or later.

## Description of the Solace PubSub+ Software Event Broker

The [Solace PubSub+ Platform](https://solace.com/products/platform/)'s [software event broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices and user interfaces running in the cloud, on-premises, and hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premises environments, and brokers in multiple locations can be linked together in an [event mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## How to deploy Solace PubSub+ Software Event Broker onto GKE

Solace PubSub+ Software Event Broker can be deployed in either a three-node High-Availability (HA) group, or as a single-node standalone deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA deployment is required.

Detailed documentation of deploying PubSub+ in a general Kubernetes environment is provided in the [Solace PubSub+ Software Event Broker in Kubernetes Documentation](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md).

Consult the [Deployment Considerations](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#pubsub-software-event-broker-deployment-considerations) when planning your deployment, then follow these steps to deploy.

The following diagram illustrates an HA deployment on a three node GKE cluster spread across three zones.

![alt text](/images/network_diagram.png "Network Diagram")

- Purple        - Data – Client data including active node management.
- Blue          - DNS  – HA node discovery.
- Black         - Disk – Persistent disk mount.
- Orange/Yellow - Mgmt – Direct CLI/SEMP.

### Step 1: Access to GKE

Perform any prerequisites to access GKE from your command-line environment.  For specific details, refer to Google Cloud's [GKE documentation](https://cloud.google.com/kubernetes-engine/docs/quickstart).

Tasks may include:

* Get access to the Google Cloud Platform, [select or create a new project](//console.cloud.google.com/projectselector2/kubernetes) and enable billing.
* Install the Kubernetes [`kubectl`](//kubernetes.io/docs/tasks/tools/install-kubectl/ ) tool.
* Install the [`gcloud`](//cloud.google.com/sdk/gcloud/) command-line tool and initialize it running `gcloud init`.
* Create a GKE cluster (see below) or use an existing one.
* Fetch the credentials of the GKE cluster.

Commands can be executed either from your local command-line interface after installing above tools, or open a Google Cloud Shell from the Cloud Platform Console, which already has the tools available:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>

If using an existing GKE cluster your admin shall be able to provide you with the [`gcloud container clusters get-credentials'](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials) command.

#### Creating a new GKE cluster

Download and execute the cluster creation script included in this repo as in the example below.

Script options and arguments:

* Default (no arguments): creates a one node GKE cluster, can be used if you were setting up and running a single-node event broker
* For a multi-node GKE-cluster in a single GCP zone, specify `-n = 3` as the number of nodes per zone and a single `-z <zone>`. 
* If you want the HA cluster spread across three zones within a region - which is the configuration recommended for production situations - specify the three zones as per the example below, but leave the number of nodes per zone at the default value of 1.
* The default cluster name is `solace-cluster` which can be changed by specifying the `-c <cluster name>` command line argument.
* The default machine type is "n1-standard-4". To use a different [Google machine type](https://cloud.google.com/compute/docs/machine-types ), specify `-m <machine-type>`. Ensure to meet the [CPU and memory requirements](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#cpu-and-memory-requirements).
* The default node OS image type is Ubuntu. Specify [other node image type](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images ) using `-i <image-type>`

> **Important:** if connecting Solace brokers across GCP regions, there is a known issue affecting TCP throughput with the default node OS image type Ubuntu and default settings. In this case additionally specify the node image as Container-Optimized OS (cos) and a flag to apply performance tuning: `-i cos -p`. 

Example:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/pubsubplus-gke-quickstart/master/scripts/create_cluster.sh
chmod +x create_cluster.sh
# Creates a recommended production-like deployment with 3 nodes across 3 availability zones
./create_cluster.sh -z us-central1-b,us-central1-c,us-central1-f
```

This will create a GKE cluster of three nodes spread across three zones and configure the required credentials to access this cluster from the command-line.

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

Refer to the [Install and configure Helm](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart#2-install-and-configure-helm) section of the PubSub+ Kubernetes Quickstart.

<br>

### Step 3 (Optional): Load the PubSub+ EBS Docker image to private Docker image registry

**Hint:** You may skip the rest of this step if not using Google Container Registry (GCR) or other private Docker registry. The free PubSub+ Software Event Broker Standard Edition is available from the [public Docker Hub registry](//hub.docker.com/r/solace/solace-pubsub-standard/tags/ ), the image reference is `solace/solace-pubsub-standard:<TagName>`.

To get the event broker Docker image URL, go to the Solace Developer Portal and download the Solace PubSub+ Software Event Broker as a **docker** image or obtain your version from Solace Support.

| PubSub+ Software Event Broker Standard<br/>Docker Image | PubSub+ Software Event Broker Enterprise Evaluation Edition<br/>Docker Image |
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
| [Download Standard docker image](http://dev.solace.com/downloads/ ) | [Download Evaluation docker image](http://dev.solace.com/downloads#eval ) |

#### Loading the PubSub+ Docker image to Google Container Registry (GCR)

If using GCR for private Docker registry, use the `copy_docker_image_to_gcr.sh` script from this repo.

Prerequisites:
* Local installation of [Docker](//docs.docker.com/get-started/ ) is required
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
wget https://raw.githubusercontent.com/SolaceProducts/pubsubplus-gke-quickstart/master/scripts/copy_docker_image_to_gcr.sh
chmod +x copy_docker_image_to_gcr.sh
# Define variables up-front to be passed to the "copy_docker_image_to_gcr" script:
  [PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \
  [GCR_HOST=<hostname>] \
  [GCR_PROJECT=<project>] \
  copy_docker_image_to_gcr.sh
```

The script will end with showing the "GCR image location" in `<your-image-location>:<your-image-tag>` format and this shall be passed to the PubSub+ deployment parameters `image.repository` and `image.tag` respectively.

You can also view the new entry on the Google Container Registry in the Cloud Platform Console:

![alt text](/images/google_container_registry.png "Google Container Registry")

<br>

For general additional information, refer to the [Using private registries](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#using-private-registries) section in the PubSub+ Kubernetes Documentation.

### Step 4: Deploy the event broker

From here follow the steps in [the PubSub+ Software Event Broker in Kubernetes Quickstart](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart#3-install-the-solace-pubsub-software-event-broker-with-default-configuration) to deploy a single-node or an HA event broker.

Refer to the detailed PubSub+ Kubernetes documentation for:
* [Validating the deployment](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#validating-the-deployment); or
* [Troubleshooting](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting)
* [Modifying or Upgrading](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment)
* [Deleting the deployment](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#deleting-a-deployment)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/pubsubplus-gke-quickstart/graphs/contributors ) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: [solace.dev](//solace.dev/)
- Understanding [Solace technology](//solace.com/products/platform/)
- Ask the [Solace community](//dev.solace.com/community/).