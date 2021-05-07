import json
import os

import pandas as pd
from prefect import Flow, Parameter, storage, task, unmapped
from prefect.executors import DaskExecutor
from prefect.run_configs import KubernetesRun
from dask_kubernetes import make_pod_spec

from flow_test.transform_tasks.http import download
from flow_test.transform_tasks.xarray import chunk, combine_and_write
from flow_test.transform_tasks.zarr import consolidate_metadata

project = os.environ["PREFECT_PROJECT"]
flow_name = "dask-transform-flow"


@task
def source_url(day: str) -> str:
    day = pd.Timestamp(day)
    source_url_pattern = (
        "https://www.ncei.noaa.gov/data/"
        "sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/"
        "{day:%Y%m}/oisst-avhrr-v02r01.{day:%Y%m%d}.nc"
    )
    return source_url_pattern.format(day=day)


with Flow(
    flow_name,
    storage=storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    ),
    run_config=KubernetesRun(
        image=os.environ["AZURE_BAKERY_IMAGE"],
        env={"AZURE_STORAGE_CONNECTION_STRING": os.environ["FLOW_STORAGE_CONNECTION_STRING"], "AZURE_BAKERY_IMAGE": os.environ["AZURE_BAKERY_IMAGE"]},
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
    ),
    executor=DaskExecutor(
        cluster_class="dask_kubernetes.KubeCluster",
        cluster_kwargs={
            "pod_template": make_pod_spec(
                image=os.environ["AZURE_BAKERY_IMAGE"],
                labels={
                    "flow": flow_name
                },
                memory_limit=None,
                memory_request=None,
                env={
                    "AZURE_STORAGE_CONNECTION_STRING": os.environ["FLOW_STORAGE_CONNECTION_STRING"]
                }
            )
        },
        adapt_kwargs={"maximum": 10},

    ),
) as flow:
    days = Parameter(
        "days",
        default=pd.date_range("1981-09-01", "1981-09-10", freq="D").strftime("%Y-%m-%d").tolist(),
    )
    sources = source_url.map(days)
    zarr_output = "dask_transform_flow.zarr"
    nc_sources = download.map(
        sources,
        cache_location=unmapped(f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/cache/transform_flow"),
    )
    chunked = chunk(nc_sources, size=5)
    target = f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/target/{zarr_output}"
    writes = combine_and_write.map(
        chunked,
        unmapped(target),
        append_dim=unmapped("time"),
        concat_dim=unmapped("time"),
    )

    consolidate_metadata(target, writes=writes)

flow.register(project_name=project)
