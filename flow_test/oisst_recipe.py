import json
import logging
import os
from functools import wraps
import time

import pandas as pd
from adlfs import AzureBlobFileSystem
from dask_kubernetes.objects import make_pod_spec
# from pangeo_forge_recipes.patterns import pattern_from_file_sequence
from pangeo_forge_recipes.patterns import FilePattern, ConcatDim
from pangeo_forge_recipes.recipes import XarrayZarrRecipe
from pangeo_forge_recipes.recipes.base import BaseRecipe
from pangeo_forge_recipes.storage import CacheFSSpecTarget, FSSpecTarget
from prefect import storage
from prefect.executors.dask import DaskExecutor
from prefect.run_configs.kubernetes import KubernetesRun
from rechunker.executors import PrefectPipelineExecutor
from distributed import get_worker
from pangeo_forge_recipes.recipes.base import closure


level = logging.DEBUG
logger = logging.getLogger("pangeo_forge_recipes")
logger.setLevel(level)
handler = logging.StreamHandler()
handler.setLevel(level)
formatter = logging.Formatter("[%(asctime)s - %(levelname)s - %(filename)s:%(lineno)s - %(funcName)10s() - %(thread)d] %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)



class SleepingInputCache(CacheFSSpecTarget):
    def cache_file(self, fname, **fsspec_open_kwargs):
        time.sleep(1)
        return


def register_recipe(recipe: BaseRecipe):
    fs_remote = AzureBlobFileSystem(
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"]
    )
    target = FSSpecTarget(
        fs_remote,
        root_path=f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/azurerecipetest/",
    )
    recipe.target = target
    recipe.lock_timeout = 60  # seconds
    recipe.input_cache = SleepingInputCache(
        fs_remote,
        root_path=(
            f"abfs://{os.environ['FLOW_STORAGE_CONTAINER']}/azurerecipetestcache/"
        ),
    )
    recipe.metadata_cache = target

    # from pangeo_forge_recipes.executors import PrefectPipelineExecutor
    # pipeline = recipe.to_pipelines()
    # flow = PrefectPipelineExecutor().pipelines_to_plan(pipeline)

    flow = recipe.to_prefect()

    flow_name = "test-noaa-flow"
    flow.storage = storage.Azure(
        container=os.environ["FLOW_STORAGE_CONTAINER"],
        connection_string=os.environ["FLOW_STORAGE_CONNECTION_STRING"],
    )
    flow.run_config = KubernetesRun(
        image=os.environ["AZURE_BAKERY_IMAGE"],
        cpu_request="250m", memory_request="128Mi",
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
                memory_request="3.9e9",
                cpu_request="1",
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

    flow.name = flow_name
    project_name = os.environ["PREFECT_PROJECT"]
    flow.register(project_name=project_name)


if __name__ == "__main__":
    def format_function(time):
        base = pd.Timestamp("1981-09-01")
        day = base + pd.Timedelta(days=time)
        input_url_pattern = (
            "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation"
            "/v2.1/access/avhrr/{day:%Y%m}/oisst-avhrr-v02r01.{day:%Y%m%d}.nc"
        )
        return input_url_pattern.format(day=day)

    dates = pd.date_range("1981-09-01", "2021-01-05", freq="D")
    pattern = FilePattern(format_function, ConcatDim("time", range(len(dates)), 1))
    recipe = XarrayZarrRecipe(pattern, inputs_per_chunk=20, cache_inputs=True)
    register_recipe(recipe)
