# Pangeo Forge Azure Bakery ☁️🍞

This repository serves as the provider of an Terraform Application which deploys the necessary infrastructure to provide a `pangeo-forge` Bakery on Azure

# Contents

* [🧑‍💻 Development - Requirements](#requirements)
* [🧑‍💻 Development - Getting Started](#getting-started-🏃‍♀️)
* [🧑‍💻 Development - Makefile goodness](#makefile-goodness)
* [🚀 Deployment - Prerequisites](#prerequisites)
* [🚀 Deployment - Deploying](#deploying)
* [🚀 Deployment - Destroying](#destroying)
* [📊 Flows - Registering the test Recipe](#registering-the-test-recipe)

# Development

## Requirements

To develop on this project, you should have the following installed:

* JQ
* [Python 3.8.*](https://www.python.org/downloads/) (We recommend using [Pyenv](https://github.com/pyenv/pyenv) to handle Python versions)
* [Poetry](https://github.com/python-poetry/poetry)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [Terraform 0.15.1](https://www.terraform.io/downloads.html)
* [Docker](https://docs.docker.com/get-docker/)
* [Helm](https://helm.sh/docs/intro/install/)

If you're developing on MacOS, all of the above can be installed using [homebrew](https://brew.sh/)

If you're developing on Windows, we'd recommend using either [Git BASH](https://gitforwindows.org/) or [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)


## Getting Started 🏃‍♀️

_**NOTE:** All `make` commands should be run from the **root** of the repository_

### Azure Credential setup

To develop and deploy this project, you will first need to setup some credentials and permissions on Azure

#### Logging in

Run `make init`. This will trigger an azure login

#### Setup azure credentials

Run `make service-principal` to create the service principal needed in the later steps.
This script will make the service principal and inject it into the config.

### `.env` file

A `.env` file is expected at the root of the repository to store variables used within deployment, the expected variables are:

```bash
# SET BY YOU MANUALLY:

ARM_SUBSCRIPTION_ID="<your-subscription-id>" # See [Development > Getting Started > Azure Credential setup > Getting your Subscription ID]
ARM_TENANT_ID="<your-service-principals-tenant-id>" # See [Development > Getting Started > Azure Credential setup > Creating a Service Principal]
ARM_CLIENT_ID="<your-service-principals-app-id>" # See [Development > Getting Started > Azure Credential setup > Creating a Service Principal]
ARM_CLIENT_SECRET="<your-service-principals-password>" # See [Development > Getting Started > Azure Credential setup > Creating a Service Principal]

TF_VAR_owner="<your-name>"
TF_VAR_identifier="<a-unique-value-to-tie-to-your-deployment>" # Try to keep this short (Less than 10 chars and only a-z A-Z 0-9 symbols)
TF_VAR_region="<azure-region-name-to-deploy-to>"
BAKERY_NAMESPACE="<the-name-for-your-prefect-agent-k8s-configs-namespace>"
BAKERY_IMAGE="<pangeo-forge-bakery-images-image-you-wish-to-use>" # See [Deployment > Prerequisites > Bakery Image]
PREFECT__CLOUD__AGENT__AUTH_TOKEN="<value-of-runner-token>" # See https://docs.prefect.io/orchestration/agents/overview.html#tokens - This is required for your Agent to communicate to Prefect Cloud
PREFECT__CLOUD__AUTH_TOKEN="<value-of-tenant-token>" # See https://docs.prefect.io/orchestration/concepts/tokens.html#tenant - This is used to support flow registration
PREFECT_PROJECT="<name-of-a-prefect-project>" # See https://docs.prefect.io/orchestration/concepts/projects.html#creating-a-project - This is where the bakery's test flows will be registered
PREFECT__CLOUD__AGENT__LABELS="<a-set-of-prefect-agent-labels>" # See https://docs.prefect.io/orchestration/agents/overview.html#labels - These will be registered with the deployed agent to limit which flows should be executed by the agent

# AUTOMATICALLY INSERTED/UPDATED BY MAKE COMMANDS:

TF_CLI_ARGS_init="<backend-config-values>" # See [Deployment - Prerequisites > Terraform Remote State infrastructure]
FLOW_STORAGE_CONTAINER="<a-flow-storage-container-name>" # See [Deployment - Standard Deployments > Retrieving Flow Storage Container names and Storage Connection String]
FLOW_CACHE_CONTAINER="<a-flow-storage-container-name>" # See [Deployment - Standard Deployments > Retrieving Flow Storage Container names and Storage Connection String]
FLOW_STORAGE_CONNECTION_STRING="<a-storage-account-connection-string>" # See [Deployment - Standard Deployments > Retrieving Flow Storage Container name and Storage Connection String]
```

An example called `example.env` is available for you to copy, rename, and fill out accordingly.

## Makefile goodness

A `Makefile` is available in the root of the repository to abstract away commonly used commands for development:
**`make init`**

> This will initialise terraform and perform an Azure login

**`make deploy`**

> This deploy the bakery
 
**`make test`**

> This uses the bakery image defined in `BAKERY_IMAGE` to register your Flow with Prefect. It deploys the oisst test recipe from the test directory


**`make setup-remote-state`**

> This will run `setup_remote_state.sh` with the contents of `.env`, it uses Azure CLI to provision a Resource Group, Storage Account, and Storage container for the Remote State that Terraform will use

**`make destroy-remote-state`**

> This will use Azure CLI to destroy the Remote State infrastructure provisioned via `make setup-remote-state`. The command assumes that the Resource Group is named as defined in the `setup_remote_state.sh` script: `<identifier>-bakery-remote-state-resource-group`

**`make lint`**

> This will run `terraform validate` within the `terraform/` directory, showing you anything that is incorrect in your Terraform scripts. It also runs isort, black, and flake8 to highlight any linting issues in `flow_test/` and `scripts/`

**`make destroy`**

> This will run `terraform destroy` within the `terraform/` directory using the contents of your `.env` file. The destroy is auto-approved, so **make sure** you know what you're destroying first! You **must** have run `make setup-remote-state` beforehand

**`make generate-bakery-yaml`**

> This generates a bakery definition YAML file

# Deployment

## Prerequisites

### Terraform Remote State infrastructure

The Terraform deployment relies on [Remote State](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage) within Azure, this is so that the state of your deployment is not locked to a file on your local machine.

> The concept of Remote State becomes a 🐓 and 🥚 situation where you need infrastructure available for Terraform to store your state, but you don't want to use Terraform for that infrastructure as that then needs remote state...

The process of provisioning the infrastructure to support Remote State is encapsulated in a bash script: `setup_remote_state.sh`. To provision your Remote State infrastructure, run:

```bash
$ make setup-remote-state # Creates the infrastructure to host your Terraform Remote State
<various-azure-cli-ouput>

Found TF_CLI_ARGS_init set in `.env`, replaced with: TF_CLI_ARGS_init="-backend-config='resource_group_name=<identifier>-bakery-remote-state-resource-group' -backend-config='storage_account_name=remotestatestoreacc' -backend-config='container_name=<identifier>-bakery-remote-state-storage-container' -backend-config='access_key=<an-access-key>' -backend-config='key=<identifier>-bakery.state'"
```

### Bakery Image

To be able to register and run Recipes as Prefect Flows, your Bakery must be running one of the `pangeo-forge-bakery-images` images in both your Prefect Agent **and** your Flow & Dask tasks.

You can find more information on the `pangeo-forge-bakery-images` [here](https://github.com/pangeo-forge/pangeo-forge-bakery-images). Once you've selected which tag you wish to support, you need to add an entry into `.env` under the name `BAKERY_IMAGE`. See below for an example:

```bash
BAKERY_IMAGE="pangeo/pangeo-forge-bakery-images:pangeonotebook-2021.05.15_prefect-0.14.19_pangeoforgerecipes-0.3.4"
```

## Deploying

A Standard Deployment of the Azure Bakery comprises of several steps, they are listed below; the links will take you to an explanation of each step.

Should you wish to just deploy the Bakery without diving into these steps, ensure you've met all of the [prerequisites](#prerequisites) for deployment, then you can simply run:

```bash
$ make deploy # Deploys all the Azure Bakery infrastructure and prepares `.env` for further usage
```

**Deployment steps**

0. [Ensure you've done the pre-requisites](#prerequisites)
1. [Deploy the bakery](#deploying)

## Destroying

**Destroying steps**

Removal of the Bakery comprises of two steps, they are listed below and further explained as you scroll down:

1. [Destroying all Bakery Azure infrastructure](#destroying-all-bakery-azure-infrastructure)
2. [Destroying the Remote State infrastructure](#destroying-the-remote-state-infrastructure)

### Destroying all Bakery Azure infrastructure

To destroy the Bakery infrastructure within Azure, you can run:

```bash
$ make destroy # Destroys the Bakery infrastructure - ** NOT the Remote State infrastructure **
```

### Destroying the Remote State infrastructure

As the Remote State infrastructure is not provisioned with Terraform, we have to delete it manually with the Azure CLI.

**You only need to delete this infrastructure if you're no longer deploying a Bakery; if you're destroying and re-deploying your Bakery frequently, don't delete this infrastructure**

To delete the Remote State infrastructure, run:

```bash
$ make destroy-remote-state # Uses Azure CLI to destroy the Remote State infrastructure
```

# Flows

## Running the test Recipe

For quick testing of your Bakery deployment, there's a Recipe setup as a Flow within `flow_test/` that you can register and run. Before you register the example Flow, you must have the values of `PREFECT__CLOUD__AUTH_TOKEN`, `PREFECT_PROJECT`, `PREFECT__CLOUD__AGENT__LABELS`, `FLOW_STORAGE_CONTAINER`, `FLOW_CACHE_CONTAINER`, `FLOW_STORAGE_CONNECTION_STRING`, and `BAKERY_IMAGE` present and populated in `.env`. You must also have run [`make deploy`](#makefile-goodness).

When your `.env` is populated and you've installed the project dependencies, you can register the Flow by running:

```
$ make test-flow
...
[2021-04-29 13:28:22+0100] INFO - prefect.Azure | Uploading test-noaa-flow/2021-06-03t10-07-21-944813-00-00 to <identifier>-bakery-flow-storage-container
Flow URL: https://cloud.prefect.io/<your-account>/flow/aef82344-8a31-485b-a189-bc1398755f9e
 └── ID: ca02500f-97ea-4605-9f66-1cccb457a3c0
 └── Project: <PREFECT_PROJECT>
 └── Labels: <PREFECT__CLOUD__AGENT__LABELS>
```

# Generating Bakery YAML files
- To generate a bakery YAML file, run `make generatebakeryyaml`.
- The resulting YAML can be added to the bakery definition repo here https://github.com/pangeo-forge/bakery-database/blob/main/bakeries.yaml

# Debugging
1. Open Lens and add your cluster (this will leverage your updated kubectl config).
2. To view pods in your pangeoforge namespace click workloads and select the namespace you specified when deploying.
3. Verify your Prefect agent pod is healthy.

### To view Dask cluster logs via Grafana  
1. Get the info needed to access the Grafana instance with `make get-grafana-admin`.
2. Use Lens to connect to Grafana by navigating Network -> Services and click `loki-grafana` and then click the `80:3000/TCP` link and use username `admin` and the password obtained in step 1.
3. Add the Loki datasource in Grafana.  
  1. Click the the configuration incon on the left
  2. Click Add Datasource
  3. Select Loki
  4. The URL of the Loki Stack is `http://loki-stack.loki-stack.svc.cluster.local:3100`
  5. Click Save and Test
4. Browsing logs
  1. Return to the main page and select the Explore icon on the left.
  2. Click Log Browser.
  3. After running a test flow via `make test-flow` use `make getinfo` to view a list of flow runs.
  4. Select the flow run of interest and a set of Loki search terms will be provided.
  5. Enter the search term in the Log Browser bar and click Shift+Enter.
  6. To include additional search terms you can add `| "<your search term>" to the exising string.

### Dask dashboard
  1. Once your flow is running and the Dask cluster pods have been created the Dask dashboard can be accessed at http://localhost:8787.
