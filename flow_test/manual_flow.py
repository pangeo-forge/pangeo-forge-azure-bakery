import json
import os

import prefect
from prefect import Flow, storage, task
from prefect.run_configs import KubernetesRun

project = os.environ["PREFECT_PROJECT"]
flow_name = "hello-flow"


@task
def say_hello():
    logger = prefect.context.get("logger")
    logger.info("Hello, Cloud")
    return "hello result"


with Flow(
    flow_name,
    run_config=KubernetesRun(
        image="prefecthq/prefect:0.14.16-python3.8",
        env={"AZURE_STORAGE_CONNECTION_STRING": os.environ["FLOW_STORAGE_CONNECTION_STRING"]},
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
    ),
    storage=storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    ),
) as flow:
    hello_result = say_hello()

flow.register(project_name=project)
