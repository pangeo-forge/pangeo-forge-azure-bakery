from typing import List, Optional

import fsspec
import zarr
from prefect import task


@task
def consolidate_metadata(target, fs, writes: Optional[List[str]] = None) -> None:
    mapper = fs.get_mapper(target)
    zarr.consolidate_metadata(mapper)
