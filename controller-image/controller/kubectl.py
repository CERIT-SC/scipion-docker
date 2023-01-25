#!venv/bin/python3

from kubernetes import client, config

from constants import *

# TODO try except

class Kubectl:
    def __init__(self, config, namespace, instance_name):
        self.config = config
        self.namespace = namespace

        self.api_apps = client.AppsV1Api(client.ApiClient(config))
        self.api_batch = client.BatchV1Api(client.ApiClient(config))

        # test namespace
        self.api_apps.list_namespaced_deployment(self.namespace)

    def list_masters(self):
        items = self.api_apps.list_namespaced_deployment(self.namespace).items
        return list(map(lambda deployment: deployment.metadata.name, items))

    def list_tools(self):
        items = self.api_batch.list_namespaced_job(self.namespace).items
        return list(map(lambda job: job.metadata.name, items))

    def filter_masters(self, instance_name):
        prefixed_name = f"{k8s_prefix_master}-{instance_name}"
        return list(filter(lambda master: master.startswith(prefixed_name), self.list_masters()))

    def filter_tools(self, instance_name):
        prefixed_name = f"{k8s_prefix_tool}-{instance_name}"
        return list(filter(lambda tool: tool.startswith(prefixed_name), self.list_tools()))
