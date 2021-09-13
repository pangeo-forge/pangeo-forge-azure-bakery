#!/bin/bash
az login
poetry run dotenv run terraform -chdir="terraform/" init