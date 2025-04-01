resource "random_id" "rg_name" {
  byte_length = 8
}

resource "random_id" "env_name" {
  byte_length = 8
}

resource "random_id" "container_name" {
  byte_length = 4
}

resource "azurerm_resource_group" "test" {
  location = "eastus"
  name     = "example-container-app-${random_id.rg_name.hex}"
}

# Get current IP address for use in KV firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

locals {
  counting_app_name  = "counting-${random_id.container_name.hex}"
  dashboard_app_name = "dashboard-${random_id.container_name.hex}"
  keyvault_name = "keyvault-${random_id.container_name.hex}"
  user_identity = "identity-${random_id.container_name.hex}"
}

module "test" {
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  location            = azurerm_resource_group.test.location
  enable_telemetry    = true # see variables.tf
  name                = local.user_identity
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_container_app_environment" "example" {
  location            = azurerm_resource_group.test.location
  name                = "my-environment"
  resource_group_name = azurerm_resource_group.test.name
}



data "azurerm_client_config" "current" {}

module "key_vault" {

  source             = "Azure/avm-res-keyvault-vault/azurerm"
  name                          = local.keyvault_name
  location                      = azurerm_resource_group.test.location
  enable_telemetry              = true
  resource_group_name           = azurerm_resource_group.test.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  public_network_access_enabled = true
  secrets = {
    test_secret = {
      name = "test-secret"
    }
  }
  secrets_value = {
    test_secret = "secret-value"
  }
  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }

    container_app_kv_reader = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.test.principal_id
    }
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = ["${data.http.ip.response_body}/32"]
  }
}

output "secrets" {
  value = module.key_vault.secrets
}

module "counting" {
  source                                = "Azure/avm-res-app-containerapp/azurerm"
  container_app_environment_resource_id = azurerm_container_app_environment.example.id
  name                                  = local.counting_app_name
  resource_group_name                   = azurerm_resource_group.test.name
  revision_mode                         = "Single"
  template = {
    containers = [
      {
        name   = "countingservicetest1"
        memory = "0.5Gi"
        cpu    = 0.25
        image  = "docker.io/hashicorp/counting-service:0.0.2"
        env = [
          {
            name  = "PORT"
            value = "9001"
          }
        ]
      },
    ]
  }
  ingress = {
    allow_insecure_connections = true
    client_certificate_mode    = "ignore"
    external_enabled           = true
    target_port                = 9001
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [module.test.resource_id]
  }
  
  secrets = {
    test_secret = {
      name  = "test-secret"
      value = "secret-value"
      key_vault_secret_id = module.key_vault.secrets["test_secret"].id
      identity = module.test.resource_id
    }
  }

  depends_on = [module.key_vault, module.test]
}

