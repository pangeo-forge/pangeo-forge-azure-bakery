import json
import os
import time

import pandas as pd
from dask_kubernetes.objects import make_pod_spec
from prefect import Flow, Parameter, storage, task, unmapped
from prefect.executors.dask import DaskExecutor
from prefect.run_configs.kubernetes import KubernetesRun

flow_name = "dask_memory_flow"


@task
def source_url(day: str) -> str:
    day = pd.Timestamp(day)
    source_url_pattern = (
        "https://www.ncei.noaa.gov/data/"
        "sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/"
        "{day:%Y%m}/oisst-avhrr-v02r01.{day:%Y%m%d}.nc"
    )
    return source_url_pattern.format(day=day)


@task
def download(source_url, cache_location):
    time.sleep(0.4)


with Flow(flow_name) as flow:
    sources = list(
        map(
            source_url,
            pd.date_range("1981-09-01", "2021-01-05", freq="D")
            .strftime("%Y-%m-%d")
            .to_list(),
        )
    )
    #  Unsure if the unmapped parameter is part of the issue
    nc_sources = download.map(
        sources,
        cache_location=unmapped("none"),
    )
    flow.name = "dask-memory"
    project_name = os.environ["PREFECT_PROJECT"]

    flow.storage = storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    )
    flow.run_config = KubernetesRun(
        image=os.environ["AZURE_BAKERY_IMAGE"],
        cpu_request=1, memory_request="3Gi",
        env={
            "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                "FLOW_STORAGE_CONNECTION_STRING"
            ],
            "AZURE_BAKERY_IMAGE": os.environ["AZURE_BAKERY_IMAGE"],
        },
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
    )
    flow.executor = DaskExecutor(
        cluster_class="dask_kubernetes.KubeCluster",
        cluster_kwargs={
            "pod_template": make_pod_spec(
                image=os.environ["AZURE_BAKERY_IMAGE"],
                labels={"flow": flow_name},
                memory_request="4Gi",
                cpu_request=1,
                env={
                    "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                        "FLOW_STORAGE_CONNECTION_STRING"
                    ],
                    # https://github.com/dask/distributed/issues/4091
                    # https://stackoverflow.com/a/63680548
                    "DASK_DISTRIBUTED__WORKER__PROFILE__INTERVAL": "1000ms",
                    "DASK_DISTRIBUTED__WORKER__PROFILE__CYCLE": "1000ms",
                },
            )
        },
        adapt_kwargs={"maximum": 10},
    )
 

flow.register(project_name=project_name)