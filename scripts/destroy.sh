#!/bin/bash
poetry run dotenv run terraform -chdir="terraform/" destroy -auto-approve