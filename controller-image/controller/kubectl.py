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

    def filter_masters(self):
        return list(filter(lambda master: master.startswith(self._get_x_name("master")), self._list_deployments()))

    def filter_tools(self):
        return list(filter(lambda tool: tool.startswith(self._get_x_name("tool-job")), self._list_jobs()))

    def filter_specials(self):
        return list(filter(lambda tool: tool.startswith(self._get_x_name("firefox")), self._list_jobs()))

    def kill_master(self):
        masters = self.filter_masters()
        if not masters or len(masters) != 1:
            return False

        self.api_apps.delete_namespaced_deployment(masters[0], self.namespace)
        return True

    def kill_tools(self):
        tools = self.filter_tools()
        if not tools:
            return False

        for t in tools:
            self.api_batch.delete_namespaced_job(t, self.namespace)

        return True

    def kill_specials(self):
        specials = self.filter_specials()
        if not specials:
            return False

        for s in specials:
            # specials contains only jobs in this version
            self.api_batch.delete_namespaced_job(s, self.namespace)

        return True
