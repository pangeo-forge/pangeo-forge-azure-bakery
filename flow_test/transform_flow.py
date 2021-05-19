import json
import os
from collections.abc import MutableMapping

import prefect
import pandas as pd
import azure.storage.blob
from prefect import Flow, Parameter, storage, task, unmapped
from prefect.executors import DaskExecutor
from prefect.run_configs import KubernetesRun
from dask_kubernetes import make_pod_spec
from azure.core.exceptions import ResourceNotFoundError

from flow_test.transform_tasks.http import download
from flow_test.transform_tasks.xarray import chunk, combine_and_write
from flow_test.transform_tasks.zarr import consolidate_metadata

project = os.environ["PREFECT_PROJECT"]
flow_name = "dask-transform-flow"


class AzureBlobStorageStore(MutableMapping):
    def __init__(self, container_client, root=""):
        logger = prefect.context.get("logger")
        logger.info("ROOT IS:")
        logger.info(root)
        if len(root):
            assert root[0] != "/"
            assert root[-1] == "/"
        self.container_client = container_client
        self.root = root

    def __getitem__(self, key):
        key = os.path.join(self.root, key)
        with self.container_client.get_blob_client(key) as bc:
            try:
                stream = bc.download_blob()
            except ResourceNotFoundError as e:
                raise KeyError(key) from e
            data = stream.readall()
        return data

    def __setitem__(self, key, value):
        key = os.path.join(self.root, key)
        # bug in zarr? xarray?
        if hasattr(value, "size") and value.size == 1 and hasattr(value, "tobytes"):
            value = value.tobytes()

        with self.container_client.get_blob_client(key) as bc:
            bc.upload_blob(value, overwrite=True)

    def __delitem__(self, key):
        key = os.path.join(self.root, key)
        with self.container_client.get_blob_client(key) as bc:
            bc.delete_blob()

    def __iter__(self):
        prefix_len = len(self.root)
        return (
            x["name"][prefix_len:] for x in self.container_client.list_blobs(self.root)
        )

    def __len__(self):
        return len(list(self.container_client.list_blobs(self.root)))


class AzureBlobStorageFS:
    def __init__(self, container_client):
        self.container_client = container_client

    def get_mapper(self, root):
        return AzureBlobStorageStore(self.container_client, root)

    def isdir(self, path):
        return True


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
        cache_location=unmapped(f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/cache/{zarr_output}"),
    )
    cc = azure.storage.blob.ContainerClient.from_connection_string(os.environ["FLOW_STORAGE_CONNECTION_STRING"], os.environ['FLOW_STORAGE_CONTAINER'])
    fs = AzureBlobStorageFS(cc)
    chunked = chunk(nc_sources, size=5)
    target = f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/target/{zarr_output}/"
    writes = combine_and_write.map(
        chunked,
        unmapped(target),
        unmapped(fs),
        append_dim=unmapped("time"),
        concat_dim=unmapped("time"),
    )

    consolidate_metadata(target, fs, writes=writes)

flow.register(project_name=project)
