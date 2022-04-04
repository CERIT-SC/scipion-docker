# Instructions for starting custom Scipion instance

## Prerequisites

* Kubernetes cluster with full privileges or microk8s with full privileges
* If you want to use microk8s, make sure dns sevice is enabled. You can enable
the service with the following command: `microk8s enable dns`

## Prepare Microk8s

1. Install Microk8s  
  `sudo snap install microk8s --classic --channel=1.21/stable`  
  `sudo usermod -a -G microk8s $USER && sudo chown -f -R $USER ~/.kube`  
  **Log out and log in to apply group changes!**

2. Start the Microk8s  
  `microk8s start`

3. Enable the DNS add-on  
  `microk8s enable dns`

## Deploying CSI-Onedata (for cluster administrator)

1. Clone the csi-onedata project  
  `git clone --branch mountflags https://github.com/josefhandl/csi-onedata`

2. Go to `csi-onedata/deploy/kubernetes`

3. Deploy the driver  
  `kubectl apply -f ./`  

## Deploying a Scipion instance (for users)

1. Clone this project  
  `git clone --branch k8s-test https://github.com/CERIT-SC/scipion-docker`

2. Create your own namespace (if you don't already have one)  
  Use this command: `kubectl create namespace` _`name`_

3. (non-microk8s only) Open the `scipion-docker/k8s/ingress.yaml` file and change a domain name
  Replace the following URL with your own. If you don't know the URL, consult
this step with your cluster administrator.  
```
12   tls:
13     - hosts:
14         - "scipion.dyn.cloud.e-infra.cz"
15       secretName: scipion-dyn-cloud-e-infra-cz-tls
16   rules:
17   - host: "scipion.dyn.cloud.e-infra.cz"
18     http:
```

4. Get Onedata host and token for the Onedata storage you want to use in your
Scipion instance

5. Deploy the instance  
  This step requires the namespace name from the step 2, Onedata credentials from the previous step, and a new password you want to use for log in to the new Scipion instance.
  `cd scipion-docker/k8s/ && ./deploy.sh` _`your-namespace`_ _`onedata-host`_ _`onedata-token`_ _`vnc-password`_

6. (microk8s only) Expose the service  
  `microk8s.kubectl -n scipion port-forward service/scipion-master-svc-novnc 5901:5901 &`  
  `microk8s.kubectl -n scipion port-forward service/scipion-master-svc-x11 6001:6001 &`

7. Connect to the instance  
  In a web browser, open the URL you entered in the ingress.yaml file in the step 3.
