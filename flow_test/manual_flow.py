import json
import os

import prefect
from prefect import Flow, storage, task
from prefect.run_configs import KubernetesRun
from prefect.executors import DaskExecutor
from dask_kubernetes import KubeCluster, make_pod_spec

project = os.environ["PREFECT_PROJECT"]
flow_name = "hello-flow"


@task
def say_hello():
    logger = prefect.context.get("logger")
    logger.info("Hello, Cloud")
    return "hello result"


def make_cluster():
    return KubeCluster(
        make_pod_spec(
            image=os.environ["AZURE_BAKERY_IMAGE"],
            labels={
                "flow": flow_name
            },
            memory_limit="4G",
            memory_request="4G"
        )
    )


with Flow(
    flow_name,
    run_config=KubernetesRun(
        image=os.environ["AZURE_BAKERY_IMAGE"],
        env={"AZURE_STORAGE_CONNECTION_STRING": os.environ["FLOW_STORAGE_CONNECTION_STRING"], "AZURE_BAKERY_IMAGE": os.environ["AZURE_BAKERY_IMAGE"]},
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
    ),
    storage=storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    ),
    executor=DaskExecutor(
        cluster_class=make_cluster,
    )
) as flow:
    hello_result = say_hello()

flow.register(project_name=project)
