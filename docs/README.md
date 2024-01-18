# Scipion in Kubernetes - Developer Documentation
Used technologies, projects and services:
- **Docker, Kubernetes, Helm**
- [**Scipion**](https://scipion.i2pc.es/) - *Image processing framework for obtaining 3D models of macromolecular complexes using Electron Microscopy (3DEM)*
- [**Onedata**](https://github.com/onedata/onedata) - Data management system
- [**DataHub**](https://datahub.egi.eu/) - Onedata installation from [EGI](https://www.egi.eu/)
- [**CSI driver**](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/) - *Container Storage Interface* driver for Kubernetes

## Related repositories
- [**`scipion-docker`**](https://github.com/CERIT-SC/scipion-docker) (this repo) - Containerized Scipion application including widely-used plugins (tools), Xfce4, VNC remote desktop and CUDA dependencies. Designed to run in Kubernetes (and MicroK8s).
- [**`scipion-portal`**](https://github.com/CERIT-SC/scipion-portal) - User friendly web portal for creating own Scipion instancies.
- [**`scipion-helm-charts`**](https://github.com/CERIT-SC/scipion-helm-charts) - Additional repo with Kubernetes objects and Helm charts for deploying `scipion-docker` and `scipion-portal` on Kubernetes.

Other required repositories:
- [**`csi-onedata`**](https://github.com/CERIT-SC/csi-onedata) - CSI driver for mounting Onedata. This driver enables a Kubernetes cluster to mount volumes with Onedata.

**This documentation includes information about this repo (`scipion-docker`) and related Kubernetes objects and Helm chart from `scipion-helm-charts` repo.**

## Simple architecture of Scipion in Kubernetes
The following diagram shows very simplified architecture of the solution.
```
            ┌── Kubernetes ─────────────────────────┐
            │                                       │
┌────────┐  │  ┌───────────┐                        │  ┌───────────┐
│        │  │  │           │  API access            │  │           │
│  User  │◄─┼─►│  Scipion  │◄───────────────────────┼─►│           │
│        │  │  │  Portal   │                        │  │  Onedata  │
└────────┘  │  │           │              ┌─────────┼─►│           │
     ▲      │  └───────────┘              │         │  │           │
     │      │     │           Data access │         │  └───────────┘
     │      │     │ Deploy                │         │
     │      │     ▼                       │         │
     │      │  ┌───────────────────────── ▼ ────┐   │
     │      │  │            ┌────────────────┐  │─┐ │
     └──────┼─►│  Scipion   │  Volume for    │  │ │ │
            │  │  instance  │  stage-in/out  │  │ │ │
            │  │            └────────────────┘  │ │ │
            │  └────────────────────────────────┘ │ │
            │    └────────────────────────────────┘ │
            └───────────────────────────────────────┘
```

## Overview of containers (Docker images) used by the instance
- **`controller`**
  - Ensures syncing data between Onedata mounts and local (Kubernetes cluster) volumes. There 4 types of syncs:
    - **`clone`** - initial copy of **dataset space** into the **dataset volume**
    - **`restore`** - initial copy of **project space** into the **project volume**
    - **`autosave`** - periodic copy of **project volume** into the **project space**
    - **`finalsave`** - final copy of **project volume** into the **project space**
  - Contains a REST API with important info about the instance. This is especialy useful for **Scipion portal** to show info about the state, health, opened Onedata spaces, etc., of the instance.
- **`vnc`**
  - Container providing remote desktop. Contains TurboVNC and noVNC providing X11 server (by the TurboVNC) shared over the network, and available for the other instance components with GUI.
- **`firefox`**
  - Container with Firefox.
- **`base`**
  - This is just a helper image for `master` and `tools` images. Contains CUDA, OpenGL libraries and basic Scipion instalation.
- **`master`**
  - Contains Scipion installation with installed plugins (tools) excluding their binaries because they are too big and useless in the `master`. Tool binaries are packed in the `tools` images. Master also includes Xfce4 desktop environment and related basic tools.
- **`tools`**
  - Tools are many separate images. Each contains Scipion installation with one plugin (tool) including binaries. Tools containers are usually headless, but there are a few interactive tasks that show GUI.

### Docker images structure

```
    ubuntu       nvidia/cudagl   ubuntu        ubuntu    
       |               |            |             |      
       ▼               ▼            ▼             ▼      
┌──────────────┐   ┌────────┐   ┌───────┐   ┌───────────┐
│  $           │   │        │   │  $    │   │  **       │
│  controller  │   │  base  │   │  vnc  │   │  firefox  │
│              │   │        │   │       │   │  *        │
└──────────────┘   └───┬────┘   └───────┘   └───────────┘
                       │                                 
                ┌──────┴──────┐                          
                │             │                          
                ▼             ▼                          
          ┌──────────┐   ┌─────────┐                     
          │  $       │   │  **     │─┐                   
          │  master  │   │  tools  │ │─┐                 
          │  *       │   │  *      │ │ │                 
          └──────────┘   └─────────┘ │ │                 
                           └─────────┘ │                 
                             └─────────┘                 

Legend:
$ Container necessary for the instance to run properly. Created at instance startup.
* Contains GUI applications, that are rendered on `vnc` container (X11 server) over the network.
** Spawned by `master` container at user's request.
```

## Overview of Kubernetes objects and Helm chart

![Schema of Kubernetes objects of the deployed instance](images/sd-k8s-diagram.png?raw=true "Schema of Kubernetes objects of the deployed instance")

**These *source codes* are located in the `scipion-helm-charts` repository.**

- **Deployments** for necessary containers (`controller`, `master`, `vnc`)
- **Secret** with credentials to the Onedata spaces used by the instance. Cluster on Cerit-SC infrastructure automatically deploys appropriate PVs and PVCs based on the secret. The reason is that non-admin user doesn't have enought privileges to create custom PVs and non-*dynamic volume privisioned* PVCs.
- **PVCs** for *dynamically provisioned* volumes used for stage-in/out from/to Onedata mounts
- **Role, RoleBinding, ServiceAccount** for deploying other batch jobs containers (`tools`, `firefox`) from the `master`
- **ClusterIP SVCs** for exposing the running services:
  - `controller`'s REST API
  - `vnc`'s noVNC web service
  - `vnc`'s X11 service shared over the network for connecting the other containers with GUI (`tools`, `firefox`)
- **Ingress** for web access to the noVNC in the `vnc` container
- **LoadBalancer SVC, Certificate** for custom VNC client instead of the web-based noVNC

Additional components **required for deploying on MicroK8s**:
- **PVCs** for Onedata mounts
- **PVs** for Onedata mounts. Requires `onedata` CSI driver

To simplify deploying of such a large number of the Kubernetes objects, there is also prepared a Helm chart. The helm chart is used by the Scipion Portal for deploying ("*installing*", by the helm terminology) and uninstalling the Scipion instances.
