#!/bin/bash
poetry run dotenv run sh -c 'FLOW=oisst_recipe.py &&
docker run -it --rm \
  -v $(pwd)/test/recipes/$FLOW:/$FLOW \
  -e FLOW_STORAGE_CONNECTION_STRING \
  -e FLOW_STORAGE_CONTAINER \
  -e FLOW_CACHE_CONTAINER -e BAKERY_IMAGE \
  -e PREFECT__CLOUD__AGENT__LABELS \
  -e PREFECT_PROJECT \
  -e PREFECT__CLOUD__AUTH_TOKEN \
  $BAKERY_IMAGE conda run -n notebook python3 /$FLOW'
