# Install a Solace Message Router onto a Google Container Engine (gke), cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide a concrete example of how to deploy a Solace VMR in standalone non-HA configuration on Google Container Engine on a single node GKE cluster.

## Description of Solace VMR

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds.

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

2. Use the button below to go to the Solace Developer portal and request a Solace Community edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Community Edition for Docker" hyperlink. This link is of the form "http<nolink>://em.solace.com/<ABCD>" and will be needed in the following section.

<a href="http://dev.solace.com/downloads/download_vmr-ce-docker" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/master/images/register.png"/>
</a>

3. Place Solace VMR in Google Container Registry:

* Open a Google Cloud Shell from the Cloud Platform Console used to create the project, like this:

![alt text](/images/launch_google_cloud_shell.png "Google Cloud Shell")

<br>
<br>

* In the Cloud Shell paste the following, (replace http<nolink>://em.solace.com/<ABCD> with the link recieved in email from step 2.)

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/copy_vmr_to_gkr.sh
chmod 755 copy_vmr_to_gkr.sh
./copy_vmr_to_gkr.sh -u http://em.solace.com/<ABCD>
```

<br>
<br>

* The script will end with a link required for next step.  You can view the new entry on the google container registry in the Cloud Platform Console.


![alt text](/images/google_container_registry.png "Google Container Registry")

<br>
<br>

4. Use Google Cloud Shell to create GKE cluster of one node.

* Download and execute the cluster create script in the Google Cloud Shell. All argument defaults should be ok for this example:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/master/scripts/create_cluster.sh
chmod 755 create_cluster.sh
./create_cluster.sh
```

<br>
<br>

5. Use Google Cloud Shell to deploy Pod and Service to that cluster.  This will finish with a Solace VMR deployed to GKE.

* Download and execute the cluster create and deployment script in the Google Cloud Shell.  Replace `<YourAdminPassword>` with the desired password for the management `admin` user. Replace `<releaseTag>` with the release tag of the image in the container registry.

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/master/scripts/start_vmr.sh
chmod 755 start_vmr.sh
./start_vmr.sh -p <YourAdminPassword> -i gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:<releaseTag>
```

<br>
<br>

#### Using other VMR deployment configurations

In current configuration above script has created and started a small size non-HA VMR deployment with simple local non-persistent storage.

For other deployment configuration options refer to the [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart).

### Validate the Deployment

Now you can validate your deployment in the Google Cloud Shell:

```sh
prompt:~$kubectl get statefulset,services,pods,pvc
NAME                                  DESIRED   CURRENT   AGE
statefulsets/XXX-XXX-solace           1         1         2m
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                       AGE
svc/kubernetes               ClusterIP      10.19.240.1     <none>           443/TCP                                       26m
svc/XXX-XXX-solace           LoadBalancer   10.19.245.131   104.154.136.44   22:31061/TCP,8080:30037/TCP,55555:31723/TCP   2m
NAME                          READY     STATUS    RESTARTS   AGE
po/XXX-XXX-solace-0           1/1       Running   0          2m
NAME                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS            AGE
pvc/data-XXX-XXX-solace-0    Bound     pvc-63ce3ad3-cae1-11e7-ae62-42010a800120   30Gi       RWO            XXX-XXX-standard        2


prompt:~$ kubectl describe service XXX-XXX-solace
Name:                     XXX-XXX-solace
Namespace:                default
Labels:                   app=solace
                          chart=solace-0.1.0
                          heritage=Tiller
                          release=XXX-XXX
Annotations:              <none>
Selector:                 app=solace,release=XXX-XXX
Type:                     LoadBalancer
IP:                       10.19.245.131
LoadBalancer Ingress:     104.154.54.154
Port:                     ssh  22/TCP
TargetPort:               22/TCP
NodePort:                 ssh  31061/TCP
Endpoints:                10.16.0.12:22
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
