[![Build Status](https://travis-ci.org/SolaceProducts/solace-gke-quickstart.svg?branch=master)](https://travis-ci.org/SolaceProducts/solace-gke-quickstart)

# Deploying a Solace PubSub+ Software Message Broker HA group onto a Google Kubernetes Engine (gke) cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to show you how to deploy Solace PubSub+ software message brokers in an HA configuration on a 3 node Google Kubernetes Engine (GKE) cluster spread across 3 zones.

![alt text](/images/network_diagram.png "Network Diagram")

- Purple        - Data – Client data including active node management.
- Blue          - DNS  – HA node discovery.
- Black         - Disk – Persistent disk mount.
- Orange/Yellow - Mgmt – Direct CLI/SEMP.

## Description of Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to Deploy a Solace PubSub+ Software Message Broker onto GKE

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

### Step 2: Obtain a reference to the docker image of the Solace  PubSub+ message broker to be deployed

First, decide which [Solace PubSub+ message broker](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm ) and version is suitable to your use case.

The docker image reference can be:

*	A public or accessible private docker registry repository name with an optional tag. This is the recommended option if using PubSub+ Standard. The default is to use the latest message broker image [available from Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/ ) as `solace/solace-pubsub-standard:latest`, or use a specific version [tag](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ).

*	A docker image download URL
     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

     * If you have purchased a Docker image of Solace PubSub+ Enterprise, Solace will give you information for how to download the compressed tar archive package from a secure Solace server. Contact Solace Support at support@solace.com if you require assistance. Then you can host this tar archive together with its MD5 on a file server and use the download URL as the image reference.

### Step 3 (Optional): Place the message broker in Google Container Registry, using a script

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

* Download and execute the cluster creation script. Accept the default values for all the script's arguments if you were setting up and running a single message broker; however, some need to be changed to support the 3 node HA cluster. If you want to run the HA cluster in a single GCP zone, specify `-n = 3` as the number of nodes per zone and a single `-z <zone>`. If you want the HA cluster spread across 3 zones within a region - which is the configuration recommended for production situations - specify the 3 zones as per the example below, but leave the number of nodes per zone at the default value of 1.

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

* The default machine type is "n1-standard-4". To use a different [Google machine type](https://cloud.google.com/compute/docs/machine-types ), specify `-m <machine-type>`. Note that the minimum CPU and memory requirements must be satisfied for the targeted message broker size, see the next step.

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

### Step 5: Use Google Cloud SDK or Cloud Shell to deploy Solace message broker Pods and Service to that cluster

This will finish with a message broker HA configuration deployed to GKE.

* Retrieve the Solace Kubernetes QuickStart from GitHub:

```
mkdir ~/workspace; cd ~/workspace
git clone https://github.com/SolaceProducts/solace-kubernetes-quickstart.git
cd solace-kubernetes-quickstart
```

* Update the Solace Kubernetes helm chart values.yaml configuration file for your target deployment with the help of the Kubernetes quick start `configure.sh` script. (Please refer to the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart#step-4 ) for further details).

     Notes:
     * Providing `-i SOLACE_IMAGE_URL` is optional (see [Step 3](#step-3-optional-place-the-message-broker-in-google-container-registry-using-a-script ), if using the latest Solace PubSub+ Standard edition message broker image from the Solace public Docker Hub registry
     * Set the cloud provider option to `-c gcp` because you are deploying to Google Cloud Platform.

Execute the configuration script, which will install the `helm` tool if it doesn't exist then customize the `solace` helm chart. It will be ready for creating a `production` HA message broker deployment, with up to 1000 connections, using a provisioned PersistentVolume (PV) storage. For other deployment configuration options refer to the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#other-message-broker-deployment-configurations ).

```
cd ~/workspace/solace-kubernetes-quickstart/solace
# Substitute <ADMIN_PASSWORD> with the desired password for the management "admin" user.
../scripts/configure.sh -p <ADMIN_PASSWORD> -c gcp -v values-examples/prod1k-persist-ha-provisionPvc.yaml -i <SOLACE_IMAGE_URL> 
# Initiate the deployment
helm install . -f values.yaml
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch kubectl get statefulset,service,pods,pvc,pv --show-labels
```

Additional notes:
* If you need to repair or modify the deployment, refer to [this section](#modifying-upgrading-or-deleting-the-deployment ).
*  If using Google Cloud Shell the `helm` installation may be lost because of [known limitations](https://cloud.google.com/shell/docs/limitations ). If the `helm` command no longer responds run `../scripts/configure.sh -r` to repair the helm installation.

### Validate the Deployment

Now you can validate your deployment:

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                          DESIRED   CURRENT   AGE
statefulsets/XXX-XXX-solace   3         3         4d

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                       AGE
svc/XXX-XXX-solace             LoadBalancer   10.19.242.217   107.178.210.65   22:30238/TCP,8080:31684/TCP,55555:32120/TCP   4d
svc/XXX-XXX-solace-discovery   ClusterIP      None            <none>           8080/TCP                                      4d
svc/kubernetes                 ClusterIP      10.19.240.1     <none>           443/TCP                                       4d

NAME                  READY     STATUS    RESTARTS   AGE
po/XXX-XXX-solace-0   1/1       Running   0          4d
po/XXX-XXX-solace-1   1/1       Running   0          4d
po/XXX-XXX-solace-2   1/1       Running   0          4d

NAME                        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS            AGE
pvc/data-XXX-XXX-solace-0   Bound     pvc-47e3bd45-53ce-11e8-bda4-42010a800031   30Gi       RWO            XXX-XXX-standard   4d
pvc/data-XXX-XXX-solace-1   Bound     pvc-47e826a0-53ce-11e8-bda4-42010a800031   30Gi       RWO            XXX-XXX-standard   4d
pvc/data-XXX-XXX-solace-2   Bound     pvc-47ef4d7c-53ce-11e8-bda4-42010a800031   30Gi       RWO            XXX-XXX-standard   4d

NAME                                          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                           STORAGECLASS       REASON    AGE
pv/pvc-47e3bd45-53ce-11e8-bda4-42010a800031   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-0   XXX-XXX-standard             4d
pv/pvc-47e826a0-53ce-11e8-bda4-42010a800031   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-1   XXX-XXX-standard             4d
pv/pvc-47ef4d7c-53ce-11e8-bda4-42010a800031   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-2   XXX-XXX-standard             4d



$ kubectl describe service XXX-XXX-solace
Name:                     XXX-XXX-solace
Namespace:                default
Labels:                   app=solace
                          chart=solace-0.3.0
                          heritage=Tiller
                          release=XXX-XXX
Annotations:              <none>
Selector:                 active=true,app=solace,release=XXX-XXX
Type:                     LoadBalancer
IP:                       10.19.242.217
LoadBalancer Ingress:     107.178.210.65
Port:                     ssh  22/TCP
TargetPort:               22/TCP
NodePort:                 ssh  30238/TCP
Endpoints:                10.16.0.10:22
Port:                     semp  8080/TCP
TargetPort:               8080/TCP
NodePort:                 semp  31684/TCP
Endpoints:                10.16.0.10:8080
Port:                     smf  55555/TCP
TargetPort:               55555/TCP
NodePort:                 smf  32120/TCP
Endpoints:                10.16.0.10:55555
Session Affinity:         None
External Traffic Policy:  Cluster
:
:

```

<br>

Note here that there are several IPs and ports. In this example `107.178.210.65` is the external Public IP to use, indicated as "LoadBalancer Ingress". This can also be seen from the Google Cloud Console:

![alt text](/images/google_container_loadbalancer.png "GKE Load Balancer")

### Viewing bringup logs

It is possible to watch the message broker come up via logs in the Google Cloud Platform log stack.  Inside Logging look for the GKE Container called solace-message-broker-cluster.  In the example below the Solace admin password was not set, therefore the container would not come up and exited.

![alt text](/images/gke_log_stack.png "GKE Log Stack")

<br>
<br>

## Gaining admin and ssh access to the message broker

The external management IP will be the Public IP associated with your GCE instance. Access will go through the load balancer service as described in the introduction and will always point to the active message broker. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

See the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#gaining-admin-access-to-the-message-broker ) for more details including admin and ssh access to the individual message brokers.

## Testing Data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: The Host will be the Public IP. It may be necessary to [open up external access to a port](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#upgradingmodifying-the-message-broker-cluster ) used by the particular messaging API if it is not already exposed.

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

<br>

## Modifying, upgrading or deleting the deployment

Refer to the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart#upgradingmodifying-the-message-broker-cluster )

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