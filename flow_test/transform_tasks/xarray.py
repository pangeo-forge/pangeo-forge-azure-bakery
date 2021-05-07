from typing import Any, List, Tuple

import fsspec
import xarray as xr
import prefect
from pangeo_forge_recipes import utils
from prefect import task


@task
def chunk(sources: List[Any], size: int) -> List[Tuple[Any, ...]]:
    return list(utils.chunked_iterable(sources, size))


@task
def combine_and_write(
    sources: List[str], target: str, append_dim: str, concat_dim: str
) -> List[str]:
    logger = prefect.context.get("logger")
    logger.info("Starting combine and write")
    double_open_files = [fsspec.open(url).open() for url in sources]
    logger.info("Double opened files")
    ds = xr.open_mfdataset(double_open_files, combine="nested", concat_dim=concat_dim)
    logger.info("Xarray opened mfdataset")
    ds = ds.chunk({append_dim: len(sources)})
    logger.info("Chunked dataset")
    mapper = fsspec.get_mapper(target)

    if not len(mapper):
        kwargs = dict(mode="w")
    else:
        kwargs = dict(mode="a", append_dim=append_dim)
    ds.to_zarr(mapper, **kwargs)
    return target
