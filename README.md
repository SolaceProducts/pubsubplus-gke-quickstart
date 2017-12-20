# Install Solace Message Router HA deployment onto a Google Kubernetes Engine (gke), cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide a concrete example of how to deploy redundent Solace VMRs in HA configuration on Google Kubernetes Engine on a 3 node GKE cluster across 3 zones.  If you are looking for a simple way to install a single Solace message router into GCP, please see [Solace GCP Quickstart](https://github.com/SolaceLabs/solace-gcp-quickstart).

![alt text](/images/network_diagram.png "Network Diagram")

- Purple - Data – Client data including active node mgmt.
- Blue   - DNS  – HA node discovery.
- Black  - Disk – Persistent disk mount.
- Orange - Mgmt – Direct CLI/SEMP.

## Description of Solace VMR

Solace Virtual Message Router (VMR) software provides enterprise-grade messaging capabilities so you can easily enable event-driven communications between applications, IoT devices, microservices and mobile devices across hybrid cloud and multi cloud environments. The Solace VMR supports open APIs and standard protocols including AMQP 1.0, JMS, MQTT, REST and WebSocket, along with all message exchange patterns including publish/subscribe, request/reply, fan-in/fan-out, queueing, streaming and more. The Solace VMR can be deployed in all popular public cloud, private cloud and on-prem environments, and offers both feature parity and interoperability with Solace’s proven hardware appliances and Messaging as a Service offering called Solace Cloud.

## How to Deploy a VMR onto GKE

This is a 5 step process:

[//]:# (Section 1 prereq is direct copy from here:  https://cloud.google.com/container-registry/docs/quickstart)

1. Create a project in Google Cloud Platform and enable prerequisites:
* In the Cloud Platform Console, go to the Manage resources page and select or create a new project.

     [GO TO THE MANAGE RESOURCES PAGE](https://console.cloud.google.com/projectselector/iam-admin/projects)

* Enable billing for your project. Follow the guide from the below link.

     [ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

* Enable the Container Registry API.  Follow the below link and select the project you created from above.

     [ENABLE THE API](https://console.cloud.google.com/flows/enableapi?apiid=containerregistry.googleapis.com)


<br>
<br>

2. Use the button below to go to the Solace Developer portal and request a Solace Evaluation edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Evaluation Edition for Docker" hyperlink. This link is of the form "http<nolink>://em.solace.com/" and will be needed in the following section.

<a href="http://dev.solace.com/downloads/download-vmr-evaluation-edition-docker" target="_blank">
    <img src="/images/register.png"/>
</a>

3. Place Solace VMR in Google Container Registry:

* Open a Google Cloud Shell from the Cloud Platform Console used to create the project, like this:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>
<br>

* In the Cloud Shell paste the following, (replace http<nolink>://em.solace.com/ with the link recieved in email from step 2.)

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/SOL-1245/scripts/copy_vmr_to_gkr.sh
chmod 755 copy_vmr_to_gkr.sh
./copy_vmr_to_gkr.sh -u http://em.solace.com/
```

<br>
<br>

* The script will end with a link required for next step.  You can view the new entry on the google container registry in the Cloud Platform Console.

![alt text](/images/google_container_registry.png "Google Container Registry")

<br>
<br>

4. Use Google Cloud Shell to create GKE cluster of one node.

* Download and execute the cluster create script in the Google Cloud Shell. All argument defaults would be ok if you want a single VMR, or HA Cluster in a single GCP zone.  If you want the VMR cluster spead across 3 zones within a region,(Recommended for production), the speficy the 3 zones as per the example below:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/SOL-1245/scripts/create_cluster.sh
chmod 755 create_cluster.sh
./create_cluster.sh -z us-central1-b,us-central1-c,us-central1-f
```

This will create a GKE cluster of 3 nodes spread across 3 zones:

![alt text](/images/Nodes_across_zones.png "Google Contain Engine nodes")

You can sets that the Kubernetes deployment on GKE is healthy with the following command, which should retun a single line with svc/kubernetes:

```sh
kubectl get services
```
If this fails, you will need to [troubleshoot GKE](https://cloud.google.com/kubernetes-engine/docs/support).

Also note that during install of GKE and release Solace HA, several GCP resources such as GCE nodes, Disks, and Loadbalancers are created.  After deleting kubernetes release you should validate all resources created are deleted.  The [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) describes how to delete a release.

<br>
<br>

5. Use Google Cloud Shell to deploy Pod and Service to that cluster.  This will finish with a Solace VMR deployed to GKE.

* Download and execute the cluster create and deployment script in the Google Cloud Shell.  Replace `<YourAdminPassword>` with the desired password for the management `admin` user. Replace `<releaseTag>` with the release tag of the image in the container registry.

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/SOL-1244/scripts/start_vmr.sh
chmod 755 start_vmr.sh
./start_vmr.sh -p <YourAdminPassword> -i gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:<releaseTag>
```

<br>
<br>

#### Using other VMR deployment configurations

In current configuration above script has created and started a small size non-HA VMR deployment with simple local non-persistent storage.

For other deployment configuration options refer to the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/blob/master/README.md).

### Validate the Deployment

Now you can validate your deployment in the Google Cloud Shell:

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                                 DESIRED   CURRENT   AGE
statefulsets/XXX-XXX-solace   3         3         3m
NAME                                  TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                       AGE
svc/XXX-XXX-solace             LoadBalancer   10.15.249.186   35.202.131.158   22:32656/TCP,8080:32394/TCP,55555:31766/TCP   3m
svc/XXX-XXX-solace-discovery   ClusterIP      None            <none>           8080/TCP                                      3m
svc/kubernetes                        ClusterIP      10.15.240.1     <none>           443/TCP                                       6d
NAME                         READY     STATUS    RESTARTS   AGE
po/XXX-XXX-solace-0   1/1       Running   0          3m
po/XXX-XXX-solace-1   0/1       Running   0          3m
po/XXX-XXX-solace-2   0/1       Running   0          3m
NAME                               STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS              AGE
pvc/data-XXX-XXX-solace-0   Bound     pvc-74d9ceb3-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
pvc/data-XXX-XXX-solace-1   Bound     pvc-74dce76f-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
pvc/data-XXX-XXX-solace-2   Bound     pvc-74e12b36-d492-11e7-b95e-42010a800173   30Gi       RWO            XXX-XXX-standard   3m
NAME                                          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                  STORAGECLASS              REASON    AGE
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
LoadBalancer Ingress:     35.202.131.158
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

Note here serveral IPs and port.  In this example 104.154.54.154 is the external IP to use,  This can also be seen from the google cloud console:

![alt text](/images/google_container_loadbalancer.png "GKE Load Balancer")

### Viewing bringup logs

It is possible to watch the VMR come up via logs in the Google Cloud Platform log stack.  Inside Logging look for GKE Container, solace-vmr-cluster.  In the example below the Solace admin password was not set, therefore the container would not come up and exited.

![alt text](/images/gke_log_stack.png "GKE Log Stack")

<br>
<br>

## Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with standard ssh session from any internet at port 22 by default:

```sh
$ssh -p 22 admin@104.154.54.154
Solace - Virtual Message Router (VMR)
Password:

System Software. SolOS-TR Version 8.6.0.1010

Virtual Message Router (Message Routing Node)

Copyright 2004-2017 Solace Corporation. All rights reserved.

This is the Community Edition of the Solace VMR.

XXX-XXX-solace-0>
```

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin management application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default.

![alt text](/images/gce_soladmin.png "soladmin connection to gce")

<br>

## Testing data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

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
