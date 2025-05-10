module "test" {
  source = "github.com/corp-ais/terraform-azurerm-redis.git?ref=X.X.X"

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
      log_retention_policy           = 10
      metric_retention_policy        = 20
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
      log_retention_policy           = 30
      metric_retention_policy        = 40
      storage_account_id             = null
      log_analytics_workspace_id     = azurerm_log_analytics_workspace.test.id
      log_analytics_destination_type = null
      eventhub_authorization_rule_id = null
      eventhub_name                  = null
    },
  ]

  depends_on = [azurerm_resource_group.test]
}