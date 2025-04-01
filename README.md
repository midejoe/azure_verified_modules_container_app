# azure_verified_modules_container_app
# Terraform Azure Deployment using Azure verified modules

## Overview
This Terraform configuration deploys an Azure infrastructure that includes:
- A resource group
- A user-assigned managed identity
- A key vault with secrets
- An Azure Container Apps environment
- A counting service container app with ingress and managed identity

## Prerequisites
Ensure you have the following installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- An active Azure subscription

## Setup

### 1. Authenticate with Azure
Run the following command to authenticate Terraform with Azure:
```sh
az login
```
If using multiple subscriptions, set the active subscription:
```sh
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Initialize Terraform
Initialize Terraform to download required providers and modules:
```sh
terraform init
```

### 3. Validate Configuration
Ensure the configuration is valid:
```sh
terraform validate
```

### 4. Plan Deployment
Preview the changes Terraform will make:
```sh
terraform plan
```

### 5. Apply Deployment
Deploy the resources:
```sh
terraform apply --auto-approve
```

### 6. View Outputs
Check the created secrets and other outputs:
```sh
terraform output
```

## Resources Created
- **Resource Group:** Stores all resources in a specific Azure region.
- **Managed Identity:** Used to authenticate the container app with the key vault.
- **Key Vault:** Securely stores secrets, accessible by the container app.
- **Container Apps Environment:** Hosts containerized applications.
- **Counting Service Container App:** Runs a demo counting service in a container.

## Cleanup
To remove all created resources, run:
```sh
terraform destroy --auto-approve
```

## Notes
- The key vault allows access from your current public IP.
- The counting service uses the image `docker.io/hashicorp/counting-service:0.0.2`.
- Ensure you replace placeholders like `YOUR_SUBSCRIPTION_ID` before running commands.

## Troubleshooting
- If encountering authentication issues, try re-running `az login`.
- If a module fails to load, ensure `terraform init` has been run.

---
Developed using Terraform and Azure for automated infrastructure provisioning.

