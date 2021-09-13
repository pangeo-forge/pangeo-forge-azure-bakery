#!/bin/bash

terraform -chdir="terraform/" init -backend=false
terraform -chdir="terraform/" fmt
poetry run isort --profile black test/recipes/ scripts/
poetry run black test/recipes/ scripts/
terraform -chdir="terraform/" validate
poetry run flake8 test/recipes/ scripts/
poetry run isort --check-only --profile black test/recipes/ scripts/
poetry run black --check --diff test/recipes/ scripts/