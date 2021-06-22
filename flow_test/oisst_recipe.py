import json
import logging
import os
from functools import wraps

import pandas as pd
from adlfs import AzureBlobFileSystem
from dask_kubernetes.objects import make_pod_spec
from pangeo_forge_recipes.patterns import pattern_from_file_sequence
from pangeo_forge_recipes.recipes import XarrayZarrRecipe
from pangeo_forge_recipes.recipes.base import BaseRecipe
from pangeo_forge_recipes.storage import CacheFSSpecTarget, FSSpecTarget
from prefect import storage
from prefect.executors.dask import DaskExecutor
from prefect.run_configs.kubernetes import KubernetesRun
from rechunker.executors import PrefectPipelineExecutor
import yaml


def set_log_level(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        logging.basicConfig()
        logging.getLogger("pangeo_forge.recipes.xarray_zarr").setLevel(
            level=logging.DEBUG
        )
        result = func(*args, **kwargs)
        return result

    return wrapper


def register_recipe(recipe: BaseRecipe):
    fs_remote = AzureBlobFileSystem(
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"]
    )
    target = FSSpecTarget(
        fs_remote,
        root_path=f"abfs://{os.environ['FLOW_CACHE_CONTAINER']}/azurerecipetest/",
    )
    recipe.target = target
    recipe.input_cache = CacheFSSpecTarget(
        fs_remote,
        root_path=(
            f"abfs://{os.environ['FLOW_CACHE_CONTAINER']}/azurerecipetestcache/"
        ),
    )
    recipe.metadata_cache = target

    executor = PrefectPipelineExecutor()
    pipeline = recipe.to_pipelines()
    flow = executor.pipelines_to_plan(pipeline)

    job_template = yaml.safe_load(
        """
        apiVersion: batch/v1
        kind: Job
        metadata:
          annotations:
            "cluster-autoscaler.kubernetes.io/safe-to-evict": "false"
        spec:
          template:
            spec:
              containers:
                - name: flow
        """
    )

    flow_name = "test-noaa-flow"
    flow.storage = storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    )
    flow.run_config = KubernetesRun(
        job_template=job_template,
        image=os.environ["BAKERY_IMAGE"],
        env={
            "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                "FLOW_STORAGE_CONNECTION_STRING"
            ],
        },
        labels=json.loads(os.environ["PREFECT__CLOUD__AGENT__LABELS"]),
        cpu_request="1000m",
        memory_request="3Gi"
    )
    flow.executor = DaskExecutor(
        cluster_class="dask_kubernetes.KubeCluster",
        cluster_kwargs={
            "pod_template": make_pod_spec(
                image=os.environ["BAKERY_IMAGE"],
                labels={"flow": flow_name},
                memory_limit="1Gi",
                memory_request="500Mi",
                cpu_limit="512m",
                cpu_request="256m",
                env={
                    "AZURE_STORAGE_CONNECTION_STRING": os.environ[
                        "FLOW_STORAGE_CONNECTION_STRING"
                    ]
                },
            ),
        },
        adapt_kwargs={"maximum": 10},
    )

    for flow_task in flow.tasks:
        flow_task.run = set_log_level(flow_task.run)

    flow.name = flow_name
    project_name = os.environ["PREFECT_PROJECT"]
    flow.register(project_name=project_name)


if __name__ == "__main__":
    input_url_pattern = (
        "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation"
        "/v2.1/access/avhrr/{yyyymm}/oisst-avhrr-v02r01.{yyyymmdd}.nc"
    )
    dates = pd.date_range("2019-09-01", "2021-01-05", freq="D")
    input_urls = [
        input_url_pattern.format(
            yyyymm=day.strftime("%Y%m"), yyyymmdd=day.strftime("%Y%m%d")
        )
        for day in dates
    ]
    pattern = pattern_from_file_sequence(input_urls, "time", nitems_per_file=1)

    recipe = XarrayZarrRecipe(pattern, inputs_per_chunk=20)
    register_recipe(recipe)
