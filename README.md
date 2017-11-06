# Install a Solace Message Router onto a Google Container Engine, (gke), cluster

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide a concrete example of how to deploy a Solace VMR on Google Container Engine on a single node GKE cluster.

## Description of Solace VMR

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds.

## How to Deploy a VMR onto GKE

This is a 5 step process:

[//]:# (Section 1 prereq is direct copy from here:  https://cloud.google.com/container-registry/docs/quickstart)

1. Create a project in Google Cloud Platform and enable prerequisites:
* In the Cloud Platform Console, go to the Manage resources page and select or create a new project.

     [GO TO THE MANAGE RESOURCES PAGE](https://console.cloud.google.com/cloud-resource-manager)

* Enable billing for your project. Follow the guide from the below link.

     [ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

* Enable the Container Registry API.  Follow the below link and select the project you created from above.

     [ENABLE THE API](https://console.cloud.google.com/flows/enableapi?apiid=containerregistry.googleapis.com)

2. Go to the Solace Developer portal and request a Solace Community edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Community Edition for Docker" hyperlink.  This link is of the form "http<nolink>://em.solace.com ?" will be needed in the following section.

<a href="http://dev.solace.com/downloads/download_vmr-ce-docker" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/68545/images/register.png"/>
</a>

3. Place Solace VMR in Google Container Registry:
* Open a cloud shell. From the google cloud console used to create the project open a shell:

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/launch_google_cloud_shell.png "Google Cloud Shell")

* In the cloud shell paste the following, (replace http<nolink>://em.solace.com/??? with the link recieved in email from step 2.)

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/scripts/copy_vmr_to_gkr.sh
chmod 755 copy_vmr_to_gkr.sh
./copy_vmr_to_gkr.sh -u http://em.solace.com/???
```

* The script will end with a link required for next step.  You can view the new entry on the google container registry in the google cloud console.

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/google_container_registry.png "Google Container Registry")

4. Use google cloud console to create GKE cluster of one node.

* Download and execute the cluster create script in the google cloud shell. All argument defaults should be ok for this example:

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/scripts/create_cluster.sh
chmod 755 create_cluster.sh
./create_cluster.sh
```

5. Use google cloud console to deploy pod and service to that cluster.  This will finish with a Solace VMR deployed to GKE.

* Download and execute the cluster create and deployment script in the google cloud shell.  Replace &lt;password&gt; with a unique password. Replace ??? with the release tag of the image in the container registry.

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-kubernetes-quickstart/68545/scripts/start_vmr.sh
chmod 755 start_vmr.sh
./start_vmr.sh -p <password> -i gcr.io/${DEVSHELL_PROJECT_ID}/solos-vmr:???
```

* Now you can validate your deployment in the google cloud shell:

```sh
prompt:~$ kubectl get deployment,svc,pods,pvc

NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/solace   1         1         1            1           1h
NAME             CLUSTER-IP     EXTERNAL-IP      PORT(S)     AGE
svc/kubernetes   XX.XX.XX.XX    <none>           443/TCP     18h
svc/solace       10.15.250.74   104.154.54.154   80:31918/TCP,8080:31910/TCP,2222:31020/TCP,55555:32120/TCP,1883:32061/TCP   1h
NAME                         READY     STATUS    RESTARTS   AGE
po/solace-2554909293-tgqmk   1/1       Running   0          1h
NAME       STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS   AGE
pvc/dshm   Bound     pvc-5cb52cd8-b408-11e7-a882-42010af001ea   1Gi        RWO           standard       1h

prompt:~$ kubectl describe service solace
Name:                   solace
Namespace:              default
Labels:                 io.kompose.service=solace
Annotations:            kompose.cmd=./kompose -f solace-compose.yaml up
                        kompose.service.type=LoadBalancer
                        kompose.version=
Selector:               io.kompose.service=solace
Type:                   LoadBalancer
IP:                     10.15.250.74
LoadBalancer Ingress:   104.154.54.154
Port:                   80      80/TCP
NodePort:               80      31918/TCP
:
:
```

Note here serveral IPs and port.  In this example 104.154.54.154 is the external IP to use,  This can also be seen from the google cloud console:

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/google_container_loadbalancer.png "GKE Load Balancer")

## Viewing bringup logs

It is possible to watch the VMR come up via logs in the Google Cloud Platform log stack.  Inside Logging look for GKE Container, solace-vmr-cluster.  In the example below the Solace admin password was not set, therefore the container would not come up and exited.

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/gke_log_stack.png "GKE Log Stack")

## Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with standard ssh session from any internet:

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/solace_console.png "SolOS CLI")

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin management application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default.

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/gce_soladmin.png "soladmin connection to gce")

## Testing data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

![alt text](https://raw.githubusercontent.com/SolaceProducts/solace-gke-quickstart/68545/images/solace_tutorial.png "getting started publish/subscribe")

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
