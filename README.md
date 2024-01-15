
# Scipion-in-Kubernetes

This project deals with the use of the [Scipion](https://scipion.i2pc.es/) application and its 3DEM tools in a cloud environment. Scipion and its tools are packed in Docker images and ready to run on Kubernetes. The solution includes GUI with a browser-based remote desktop, and is capable of using a graphics card for CUDA-accelerated tools. [Onedata](https://onedata.org/) is used as a storage with dataset (e.g. data scanned by CryoEM) and project data.

This application is available on [Rancher](rancher.cloud.e-infra.cz/) of the e-INFRA infrastructure and uses [Datahub](https://datahub.egi.eu/) as a Onedata installation.

For more info about running the application, check the Rancher e-INFRA cloud [documentation](https://docs.cerit.io/docs/scipion/scipion.html).

[Developer documentation](https://github.com/CERIT-SC/scipion-docker/tree/master/docs) is available in the `docs` directory.
