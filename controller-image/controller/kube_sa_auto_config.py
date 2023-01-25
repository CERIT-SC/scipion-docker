#!venv/bin/python3

import os

from kubernetes import client

class KubeSaAutoConfig(client.configuration.Configuration):
    def __init__(self):
        super().__init__()

        # set api_key
        with open("/run/secrets/kubernetes.io/serviceaccount/token") as f:
            self.api_key["authorization"] = f.read()

        # set api_key_prefix
        self.api_key_prefix["authorization"] = "Bearer"

        # set host
        self.host = f"https://{os.environ['KUBERNETES_SERVICE_HOST']}"

        # set ssl_ca_cert
        self.ssl_ca_cert = "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
