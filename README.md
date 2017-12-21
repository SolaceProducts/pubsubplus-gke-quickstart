# Install Solace Message Router HA deployment onto a Google Kubernetes Engine (gke), cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide a concrete example of how to deploy redundant Solace VMRs in HA configuration on Google Kubernetes Engine on a 3 node GKE cluster across 3 zones.  If you are looking for a simple way to install a single Solace message router into GCP, please see [Solace GCP Quickstart](https://github.com/SolaceLabs/solace-gcp-quickstart).

![alt text](/images/network_diagram.png "Network Diagram")

- Purple        - Data – Client data including active node mgmt.
- Blue          - DNS  – HA node discovery.
- Black         - Disk – Persistent disk mount.
- Orange/Yellow - Mgmt – Direct CLI/SEMP.

## Description of Solace VMR

Solace Virtual Message Router (VMR) software provides enterprise-grade messaging capabilities so you can easily enable event-driven communications between applications, IoT devices, microservices and mobile devices across hybrid cloud and multi cloud environments. The Solace VMR supports open APIs and standard protocols including AMQP 1.0, JMS, MQTT, REST and WebSocket, along with all message exchange patterns including publish/subscribe, request/reply, fan-in/fan-out, queueing, streaming and more. The Solace VMR can be deployed in all popular public cloud, private cloud and on-prem environments, and offers both feature parity and interoperability with Solace’s proven hardware appliances and Messaging as a Service offering called Solace Cloud.

## How to Deploy a VMR onto GKE

This is a 5 step process:

[//]:# (Section 1 prereq is direct copy from here:  https://cloud.google.com/container-registry/docs/quickstart)

**Step 1**: Create a project in Google Cloud Platform and enable prerequisites:

* In the Cloud Platform Console, go to the Manage resources page and select or create a new project.

    [GO TO THE MANAGE RESOURCES PAGE](https://console.cloud.google.com/projectselector/iam-admin/projects)

* Enable billing for your project. Follow the guide from the below link.

    [ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

* Enable the Container Registry API.  Follow the below link and select the project you created from above.

    [ENABLE THE API](https://console.cloud.google.com/flows/enableapi?apiid=containerregistry.googleapis.com)


<br>
<br>

**Step 2**: Use the button below to go to the Solace Developer portal and request a Solace Evaluation edition VMR. This process will return an email with a Download link. In the email do a right click "Copy Hyperlink" on the "Download the VMR Evaluation Edition for Docker" hyperlink. This link is of the form "http<nolink>://em.solace.com/" and will be needed in the following section.

Note: The Evaluation edition VMR is required to support HA deployment.

<a href="http://dev.solace.com/downloads/download-vmr-evaluation-edition-docker" target="_blank">
    <img src="/images/register.png"/>
</a>

**Step 3**: Place Solace VMR in Google Container Registry:

* Open a Google Cloud Shell from the Cloud Platform Console used to create the project, like this:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>
<br>

* In the Cloud Shell paste the following, (replace http<nolink>://em.solace.com/ with the link received in email from step 2.)

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/copy_vmr_to_gkr.sh
chmod 755 copy_vmr_to_gkr.sh
./copy_vmr_to_gkr.sh -u http://em.solace.com/
```

<br>

* The script will end with a link required for next step.  You can view the new entry on the google container registry in the Cloud Platform Console.

![alt text](/images/google_container_registry.png "Google Container Registry")

<br>
<br>

**Step 4**: Use Google Cloud Shell to create GKE cluster of three nodes.

* Download and execute the cluster create script in the Google Cloud Shell. All argument defaults would be ok if you want a single non-HA VMR. Specify `-n = 3` as number of nodes and a single `-z <zone>` for an HA Cluster in a single GCP zone. If you want the VMR cluster spread across 3 zones within a region (recommended for production), then specify the 3 zones as per the example below but leave the number of nodes at default 1 (meaning one node per zone):

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/create_cluster.sh
chmod 755 create_cluster.sh
./create_cluster.sh -z us-central1-b,us-central1-c,us-central1-f
```

This will create a GKE cluster of 3 nodes spread across 3 zones:

![alt text](/images/Nodes_across_zones.png "Google Container Engine nodes")

Further GKE `create_cluster.sh` options:
* The default cluster name is "solace-vmr-cluster", which can be changed by specifying the `-c <cluster name>` command line argument.
* The default machine type is "n1-standard-4". To use a different [Google machine type](https://cloud.google.com/compute/docs/machine-types ), specify `-m <machine type>`. Note that the minimum CPU and memory requirements must be satisfied for the targeted VMR size, see the next step.

<br>

You can check that the Kubernetes deployment on GKE is healthy with the following command, which should return a single line with svc/kubernetes:

```sh
kubectl get services
```
If this fails, you will need to [troubleshoot GKE](https://cloud.google.com/kubernetes-engine/docs/support ).

Also note that during install of GKE and release Solace HA, several GCP resources such as GCE nodes, Disks, and Loadbalancers are created.  After deleting a Kubernetes release you should validate that all resources created are deleted.  The [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart(TODO) ) describes how to delete a release. If it is necessary to delete the GKE cluster refer to the [Google Cloud Platform documentation](https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete ).

<br>
<br>

**Step 5**: Use Google Cloud Shell to deploy Pod and Service to that cluster.  This will finish with a Solace VMR HA configuration deployed to GKE.

* Download and execute the cluster create and deployment script in the Google Cloud Shell.  Replace `<YourAdminPassword>` with the desired password for the management `admin` user. Replace `<releaseTag>` with the release tag of the image in the container registry.

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/master/scripts/start_vmr.sh
chmod 755 start_vmr.sh
./start_vmr.sh -p <YourAdminPassword> -i gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:<releaseTag> -v values-examples/small-persist-ha-provisionPvc.yaml
```

#### Using other VMR deployment configurations

In current configuration above script has created and started a small-size HA VMR deployment with a provisioned PersistentVolume (PV) storage.

For other deployment configuration options refer to the [Solace Kubernetes Quickstart README](https://github.com/bczoma/solace-kubernetes-quickstart/tree/master#using-other-vmr-deployment-configurations ).

### Validate the Deployment

Now you can validate your deployment in the Google Cloud Shell:

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                          DESIRED   CURRENT   AGE
statefulsets/XXX-XXX-solace   3         3         3m
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                       AGE
svc/XXX-XXX-solace             LoadBalancer   10.15.249.186   104.154.54.154   22:32656/TCP,8080:32394/TCP,55555:31766/TCP   3m
svc/XXX-XXX-solace-discovery   ClusterIP      None            <none>           8080/TCP                                      3m
svc/kubernetes                 ClusterIP      10.15.240.1     <none>           443/TCP                                       6d
NAME                  READY     STATUS    RESTARTS   AGE
po/XXX-XXX-solace-0   1/1       Running   0          3m
po/XXX-XXX-solace-1   0/1       Running   0          3m
po/XXX-XXX-solace-2   0/1       Running   0          3m
NAME                        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
pvc/data-XXX-XXX-solace-0   Bound     pvc-74d9ceb3-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
pvc/data-XXX-XXX-solace-1   Bound     pvc-74dce76f-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
pvc/data-XXX-XXX-solace-2   Bound     pvc-74e12b36-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
NAME                                          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                           STORAGECLASS       REASON    AGE
pv/pvc-74d9ceb3-d492-11e7-b95e-42010a800173   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-0   XXX-XXX-standard             3m
pv/pvc-74dce76f-d492-11e7-b95e-42010a800173   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-1   XXX-XXX-standard             3m
pv/pvc-74e12b36-d492-11e7-b95e-42010a800173   30Gi       RWO            Delete           Bound     default/data-XXX-XXX-solace-2   XXX-XXX-standard             3m


prompt:~$ kubectl describe service XXX-XX-solace
Name:                     XXX-XX-solace
Namespace:                default
Labels:                   app=solace
                          chart=solace-0.1.0
                          heritage=Tiller
                          release=XXX-XX
Annotations:              <none>
Selector:                 app=solace,release=XXX-XXX
Type:                     LoadBalancer
IP:                       10.15.249.186
LoadBalancer Ingress:     104.154.54.154
Port:                     ssh  22/TCP
TargetPort:               22/TCP
NodePort:                 ssh  32656/TCP
Endpoints:                10.12.7.6:22
Port:                     semp  8080/TCP
TargetPort:               8080/TCP
NodePort:                 semp  32394/TCP
Endpoints:                10.12.7.6:8080
Port:                     smf  55555/TCP
TargetPort:               55555/TCP
NodePort:                 smf  31766/TCP
Endpoints:                10.12.7.6:55555
Session Affinity:         None
External Traffic Policy:  Cluster
:
:

```

<br>

Note here several IPs and port. In this example 104.154.54.154 is the external Public IP to use. This can also be seen from the google cloud console:

![alt text](/images/google_container_loadbalancer.png "GKE Load Balancer")

### Viewing bringup logs

It is possible to watch the VMR come up via logs in the Google Cloud Platform log stack.  Inside Logging look for GKE Container, solace-vmr-cluster.  In the example below the Solace admin password was not set, therefore the container would not come up and exited.

![alt text](/images/gke_log_stack.png "GKE Log Stack")

<br>
<br>

## Gaining admin and ssh access to the VMR

The external management IP will be the Public IP associated with your GCE instance. Access will go through the load balancer service as described in the introduction and will always point to the active VMR. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

See the [Solace Kubernetes Quickstart README](https://github.com/bczoma/solace-kubernetes-quickstart/tree/master##gaining-admin-access-to-the-vmr ) for more details including admin and ssh access to the individual VMRs.

## Testing Data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Public IP. It may be necessary to [open up external access to a port](TODO) used by the particular messaging API if it is not already exposed.

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

<br>

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceProducts/solace-gke-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

* The Solace Developer Portal website at: http://dev.solace.com
* Understanding [Solace technology.](http://dev.solace.com/tech/)
* Ask the [Solace community](http://dev.solace.com/community/).
