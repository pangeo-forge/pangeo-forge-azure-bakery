# pangeo-forge Azure Bakery ☁️🍞

This repository serves as the provider of an Terraform Application which deploys the necessary infrastructure to provide a `pangeo-forge` Bakery on Azure

# Contents

* [🧑‍💻 Development - Requirements](#requirements)
* [🧑‍💻 Development - Getting Started](#getting-started-🏃‍♀️)
* [🧑‍💻 Development - Makefile goodness](#makefile-goodness)
* [🚀 Deployment - Standard Deployments](#standard-deployments)

# Development

## Requirements

To develop on this project, you should have the following installed:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Terraform 0.15.0](https://www.terraform.io/downloads.html)

If you're developing on MacOS, all of the above can be installed using [homebrew](https://brew.sh/)

If you're developing on Windows, we'd recommend using either [Git BASH](https://gitforwindows.org/) or [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)


## Getting Started 🏃‍♀️

### Azure Credential setup

To develop and deploy this project, you will first need to setup some credentials and permissions on Azure; before doing this ensure you've installed the [requirements](#requirements) listed above.

#### Logging in

With the Azure CLI installed, run:

```bash
$ az login # Opens up a browser window to login with
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "<a-home-tenant-id>",
    "id": "<a-id>",
    "isDefault": true,
    "managedByTenants": [],
    "name": "SuperAwesomeSubscription",
    "state": "Enabled",
    "tenantId": "<a-tenant-id>",
    "user": {
      "name": "<your-username>",
      "type": "user"
    }
  },
  ...
]
```

If you notice that the `Subscription` you intend to use has `"isDefault": false`, then refer to [this documentation](https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#change-the-active-subscription) on how to switch your default `Subsciption`.

#### Creating a Service Principal

You will then need to create a `Service Principal` to deploy as:

```bash
$ az ad sp create-for-rbac --name "<name-for-your-service-principal>"
{
  "appId": "<an-app-id>",
  "displayName": "<name-for-your-service-principal>",
  "name": "http://<name-for-your-service-principal>",
  "password": "<a-password>",
  "tenant": "<a-tenant-id>"
}
```

Keep note of the values of `appId` and `password`.

#### Adding Service Principal permissions

Your service principal will need a few permissions added to it, for these you'll need to get its `objectId`, you can get this by running:

```bash
$ az ad sp list --display-name "<name-for-your-service-principal>"
[
  {
    "accountEnabled": "True",
    "addIns": [],
    "alternativeNames": [],
    "appDisplayName": "<name-for-your-service-principal>",
    "appId": "<a-app-id>",
    "appOwnerTenantId": "<a-tenant-id>",
    "appRoleAssignmentRequired": false,
    "appRoles": [],
    "applicationTemplateId": null,
    "deletionTimestamp": null,
    "displayName": "<name-for-your-service-principal>",
    "errorUrl": null,
    "homepage": "https://<name-for-your-service-principal>",
    "informationalUrls": {
      "marketing": null,
      "privacy": null,
      "support": null,
      "termsOfService": null
    },
    "keyCredentials": [],
    "logoutUrl": null,
    "notificationEmailAddresses": [],
    "oauth2Permissions": [
      {
        "adminConsentDescription": "Allow the application to access <name-for-your-service-principal> on behalf of the signed-in user.",
        "adminConsentDisplayName": "Access <name-for-your-service-principal>",
        "id": "<an-id>",
        "isEnabled": true,
        "type": "User",
        "userConsentDescription": "Allow the application to access <name-for-your-service-principal> on your behalf.",
        "userConsentDisplayName": "Access <name-for-your-service-principal>",
        "value": "user_impersonation"
      }
    ],
    "objectId": "<a-object-id>",
    "objectType": "ServicePrincipal",
    "odata.type": "Microsoft.DirectoryServices.ServicePrincipal",
    "passwordCredentials": [],
    "preferredSingleSignOnMode": null,
    "preferredTokenSigningKeyEndDateTime": null,
    "preferredTokenSigningKeyThumbprint": null,
    "publisherName": "<a-publisher-name>",
    "replyUrls": [],
    "samlMetadataUrl": null,
    "samlSingleSignOnSettings": null,
    "servicePrincipalNames": [
      "http://<name-for-your-service-principal>",
      "<a-service-principal-id>"
    ],
    "servicePrincipalType": "Application",
    "signInAudience": "AzureADMyOrg",
    "tags": [],
    "tokenEncryptionKeyId": null
  }
]
```

From the resultant JSON output to the screen, copy the value of `objectID`.

You can then run:

```bash
$ az role assignment create --assignee "<objectId>" --role "Storage Blob Data Contributor"
$ az role assignment create --assignee "<objectId>" --role "User Access Administrator"
$ az role assignment create --assignee "<objectId>" --role  "Azure Kubernetes Service Cluster User Role"
```

You should now be setup with the correct permissions to deploy the infrastructure onto Azure. Further reading on Azure Service Principals can be found [here](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest).

### `deployment.tfvars.json` file

A `deployment.tfvars.json` file is expected at the root of the repository to store variables used within deployment, the expected values are:

```bash
{
    "owner": "<your-name>",
    "identifier": "<a-unique-value-to-tie-to-your-deployment>",
    "region": "<azure-region-name-to-deploy-to>",
    "appId": "<value-of-appId-from-earlier>",
    "password": "<value-of-password-from-earlier>"
}
```

An example called `example.tfvars.json` is available for you to copy, rename, and fill out accordingly.

## Makefile goodness

A `Makefile` is available in the root of the repository to abstract away commonly used commands for development:

**`make init`**

> This will run `terraform init` within the `terraform/` directory, installing any providers required for deployment

**`make lint`**

> This will run `terraform validate` within the `terraform/` directory, showing you anything that is incorrect in your Terraform scripts

**`make format`**

> This will run `terraform fmt` within the `terraform/` directory, this **will** modify files if issues were found

**`make plan`**

> This will run `terraform plan` within the `terraform/` directory using the contents of your `deployment.tfvars.json` file

**`make apply`**

> This will run `terraform apply` within the `terraform/` directory using the contents of your `deployment.tfvars.json` file. The deployment is auto-approved, so **make sure** you know what you're changing with your deployment first! (Best to run `make plan` to check!)

**`make destroy`**

> This will run `terraform destroy` within the `terraform/` directory using the contents of your `deployment.tfvars.json` file. The destroy is auto-approved, so **make sure** you know what you're destroying first!

# Deployment

## Standard Deployments

For standard deploys, you can check _what_ you'll be deploying by running:

```bash
$ make plan # Outputs the result of `terraform plan`
```

To deploy the infrastructure, you can run:

```bash
$ make apply # Deploys the Bakery
```

To destroy the infrastructure, you can run:

```bash
$ make destroy # Destroys the Baker
