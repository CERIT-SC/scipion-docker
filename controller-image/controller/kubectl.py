#!venv/bin/python3

from kubernetes import client, config

from constants import *

# TODO try except

class Kubectl:
    def __init__(self, config, namespace, instance_name):
        self.config = config
        self.namespace = namespace
        self.instance_name = instance_name

        self.api_apps = client.AppsV1Api(client.ApiClient(config))
        self.api_batch = client.BatchV1Api(client.ApiClient(config))

        # test namespace
        self.api_apps.list_namespaced_deployment(self.namespace)

    def _get_x_name(self, x_name):
        return f"scipion-{x_name}-{self.instance_name}"

    def _list_deployments(self):
        items = self.api_apps.list_namespaced_deployment(self.namespace).items
        return list(map(lambda deployment: deployment.metadata.name, items))

    def _list_jobs(self):
        items = self.api_batch.list_namespaced_job(self.namespace).items
        return list(map(lambda job: job.metadata.name, items))

    def filter_main(self, include_controller = True):
        result = list()
        for d in self._list_deployments():
            if include_controller and \
                    d.startswith(self._get_x_name("controller")):
                result.append(d)

            if d.startswith(self._get_x_name("vnc")) or \
                    d.startswith(self._get_x_name("master")):
                result.append(d)
        return result

    def filter_tools(self):
        result = list()
        for j in self._list_jobs():
            if j.startswith(self._get_x_name("tool")):
                result.append(j)
        return result

    def filter_specials(self):
        result = list()
        for j in self._list_jobs():
            if j.startswith(self._get_x_name("firefox")):
                result.append(j)
        return result

    def delete_main(self):
        deployments = self.filter_main(include_controller=False)
        if not deployments:
            return False

        for d in deployments:
            self.api_apps.delete_namespaced_deployment(d, self.namespace)
        return True

    def delete_tools(self):
        jobs = self.filter_tools()
        if not jobs:
            return False

        for j in jobs:
            self.api_batch.delete_namespaced_job(j, self.namespace)

        return True

    def delete_specials(self):
        jobs = self.filter_specials()
        if not jobs:
            return False

        for j in jobs:
            self.api_batch.delete_namespaced_job(j, self.namespace)

        return True
