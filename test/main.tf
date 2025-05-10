terraform {
  required_version = ">= 1.0.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.4.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = "833df664-61c8-4af0-bcce-b9eed5f10e5a"
  subscription_id = "43e663b4-8b43-49b0-978d-949807f559b3"
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
    }
  }
}

provider "azurerm" {
  alias                           = "hub"
  tenant_id                       = "833df664-61c8-4af0-bcce-b9eed5f10e5a"
  subscription_id                 = "d7561777-d00e-434a-9846-39c778716bde"
  resource_provider_registrations = "none"
  features {}
}

# -------- Prerequisite -----------------------------------------------------------

# 1) Resource Group
resource "azurerm_resource_group" "test" {
  name     = "test-module-redis"
  location = "southeastasia"
}

# 2) Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "test" {
  name                = "log-test-az-asse-dev-001"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.test.name
  retention_in_days   = 30 # range ==> 30 - 730
}

resource "azurerm_storage_account" "diag" {
  name                     = "sttestterraformazasse003"
  location                 = azurerm_resource_group.test.location
  resource_group_name      = azurerm_resource_group.test.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3) Vnet and subnets
resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies = "Enabled"
}

#4) Private DNS Zone
data "azurerm_private_dns_zone" "test" {
  provider            = azurerm.hub
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = "rg-hubdnsforwarder-az-asse-dev-001"
}

resource "azurerm_private_dns_zone_virtual_network_link" "test" {
  provider              = azurerm.hub
  name                  = "link-${azurerm_virtual_network.test.name}"
  resource_group_name   = "rg-hubdnsforwarder-az-asse-dev-001"
  private_dns_zone_name = data.azurerm_private_dns_zone.test.name
  virtual_network_id    = azurerm_virtual_network.test.id

  depends_on = [
    azurerm_virtual_network.test
  ]
}

# -------- Module -----------------------------------------------------------------

module "test" {
  source = "../"

  name                = "redis-test-az-asse-dev-001"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  tags                = { "feeling" = "bored" }

  # Premium (P) --> 1, 2, 3, 4
  # Basic/Standard(C) --> 0, 1, 2, 3, 4, 5, 6
  sku_name                      = "Standard"
  family                        = "C"
  capacity                      = 0
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  redis_version                 = 6

  # For Premium
  #  - If both replicas_per_master and replicas_per_primary are setted, they have to be the same
  replicas_per_master  = 3
  replicas_per_primary = 3
  #  - Redis 6 does not support shard_count:
  shard_count = 1 # shard_count ==> 1 - 10
  zones       = ["1", "2", "3"]

  # vnet access
  // private_static_ip_address = ""
  // subnet_id = ""

  # Firewall Rules
  firewall_rules = {
    "rule001" = {
      start_ip = "10.0.0.0"
      end_ip   = "10.1.12.14"
    }
    "rule002" = {
      start_ip = "1.20.30.0"
      end_ip   = "1.20.30.3"
    }
  }

  # Private Endpoint
  enable_private_endpoint = true
  private_dns_zone_id     = data.azurerm_private_dns_zone.test.id
  link_snet_id            = azurerm_subnet.test.id
  pe_name                 = "pe-test-az-asse-dev-001"

  # Diagnostic Setting
  diagnostic_settings = [
    {
      suffix_name                    = "to-st"
      enabled_logs                   = ["ConnectedClientList"]
      metric                         = ["AllMetrics"]
      storage_account_id             = azurerm_storage_account.diag.id
      log_analytics_workspace_id     = null
      log_analytics_destination_type = null
      eventhub_authorization_rule_id = null
      eventhub_name                  = null
    },
    {
      suffix_name                    = "to-log"
      enabled_logs                   = ["ConnectedClientList"]
      metric                         = ["AllMetrics"]
      storage_account_id             = null
      log_analytics_workspace_id     = azurerm_log_analytics_workspace.test.id
      log_analytics_destination_type = null
      eventhub_authorization_rule_id = null
      eventhub_name                  = null
    },
  ]

  depends_on = [azurerm_resource_group.test]
}

# ----- Output --------------------------------------------------------------------------

output "id" {
  description = "The Route ID"
  value       = module.test.id
}

output "hostname" {
  description = "The Hostname of the Redis Instance"
  value       = module.test.hostname
}

output "ssl_port" {
  description = "The SSL Port of the Redis Instance"
  value       = module.test.ssl_port
}

output "port" {
  description = "The non-SSL Port of the Redis Instance"
  value       = module.test.ssl_port
}

output "primary_access_key" {
  description = "The Primary Access Key for the Redis Instance"
  value       = module.test.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The Secondary Access Key for the Redis Instance"
  value       = module.test.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string of the Redis Instance."
  value       = module.test.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string of the Redis Instance."
  value       = module.test.secondary_connection_string
  sensitive   = true
}

output "redis_configuration" {
  description = "The configuration of redis"
  value       = module.test.redis_configuration
  sensitive   = true
}