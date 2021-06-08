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


with Flow(
    flow_name,
    storage=storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    ),
    run_config=KubernetesRun(
        image=os.environ["AZURE_BAKERY_IMAGE"],
        env={
            "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                "FLOW_STORAGE_CONNECTION_STRING"
            ],
            "AZURE_BAKERY_IMAGE": os.environ["AZURE_BAKERY_IMAGE"],
        },
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
    ),
    executor=DaskExecutor(
        cluster_class="dask_kubernetes.KubeCluster",
        cluster_kwargs={
            "pod_template": make_pod_spec(
                image=os.environ["AZURE_BAKERY_IMAGE"],
                labels={"flow": flow_name},
                memory_limit=None,
                memory_request=None,
                env={
                    "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                        "FLOW_STORAGE_CONNECTION_STRING"
                    ]
                },
            )
        },
        adapt_kwargs={"minimum": 3, "maximum": 10},
    ),
) as flow:
    days = Parameter(
        "days",
        default=pd.date_range("1981-09-01", "2021-01-05", freq="D")
        .strftime("%Y-%m-%d")
        .tolist(),
    )
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
