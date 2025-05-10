/*
*
* # Terraform Module for creating Redis Cache [ Basic / Standard / Premium ]
*
*/

resource "azurerm_redis_cache" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = var.non_ssl_port_enabled
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  redis_version                 = var.redis_version
  private_static_ip_address     = var.private_static_ip_address
  tenant_settings               = var.tenant_settings

  # For sku = Premium
  replicas_per_master  = var.sku_name == "Premium" ? var.replicas_per_master : null
  replicas_per_primary = var.sku_name == "Premium" ? var.replicas_per_primary : null
  shard_count          = var.sku_name == "Premium" ? var.shard_count : null
  zones                = var.sku_name == "Premium" ? var.zones : null
  subnet_id            = var.sku_name == "Premium" ? var.subnet_id : null

  redis_configuration {
    authentication_enabled             = var.authentication_enabled
    active_directory_authentication_enabled = var.active_directory_authentication_enabled
    authentication_enabled = var.redis_config_enable_authentication
    notify_keyspace_events = var.redis_config_notify_keyspace_events

    aof_backup_enabled              = var.sku_name == "Premium" ? var.redis_config_aof_backup_enabled : null
    aof_storage_connection_string_0 = var.redis_config_aof_storage_connection_string_0
    aof_storage_connection_string_1 = var.redis_config_aof_storage_connection_string_1

    maxmemory_reserved              = var.sku_name == "Premium" || var.sku_name == "Standard" ? var.redis_config_maxmemory_reserved : null              # MB
    maxfragmentationmemory_reserved = var.sku_name == "Premium" || var.sku_name == "Standard" ? var.redis_config_maxfragmentationmemory_reserved : null # MB
    maxmemory_delta                 = var.sku_name == "Premium" || var.sku_name == "Standard" ? var.redis_config_maxmemory_delta : null                 # MB
    maxmemory_policy                = var.redis_config_maxmemory_policy

    rdb_backup_enabled            = var.sku_name == "Premium" ? var.redis_config_rdb_backup_enabled : null # Premium SKU
    rdb_storage_connection_string = var.sku_name == "Premium" ? var.redis_config_rdb_storage_connection_string : null
    rdb_backup_frequency          = var.sku_name == "Premium" ? var.redis_config_rdb_backup_frequency : null # 15, 30, 60, 360, 720, 1440 minutes
    rdb_backup_max_snapshot_count = var.sku_name == "Premium" ? var.redis_config_rdb_backup_max_snapshot_count : null
  }

  dynamic "identity" {
    for_each = var.identity_type == null ? [] : ["create"]
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  patch_schedule {
    day_of_week        = var.patch_schedule_day_of_week
    start_hour_utc     = var.patch_schedule_start_hour_utc
    maintenance_window = var.patch_schedule_maintenance_window
  }

  lifecycle {
    ignore_changes = [
      # KNOWN ISSUE: https://github.com/Azure/azure-rest-api-specs/issues/3037
      redis_configuration.0.rdb_storage_connection_string,
    ]
  }

}

#
# Firewall Rules
# 

resource "azurerm_redis_firewall_rule" "main" {
  for_each = var.firewall_rules

  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = azurerm_redis_cache.main.resource_group_name

  name     = each.key
  start_ip = each.value.start_ip
  end_ip   = each.value.end_ip
}

#
# Private Endpoint
#

resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = var.pe_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.link_snet_id

  private_dns_zone_group {
    name                 = split("/", var.private_dns_zone_id)[8]
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  private_service_connection {
    name                           = "${var.pe_name}-conn"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
  }

  tags = var.tags
}

#
# Diagnostic log
#

resource "azurerm_monitor_diagnostic_setting" "main" {
  count = length(var.diagnostic_settings)

  name               = "diag-${var.name}-${var.diagnostic_settings[count.index].suffix_name}"
  target_resource_id = azurerm_redis_cache.main.id

  storage_account_id             = lookup(var.diagnostic_settings[count.index], "storage_account_id", null)
  log_analytics_workspace_id     = lookup(var.diagnostic_settings[count.index], "log_analytics_workspace_id", null)
  log_analytics_destination_type = lookup(var.diagnostic_settings[count.index], "log_analytics_destination_type", "Dedicated")
  eventhub_authorization_rule_id = lookup(var.diagnostic_settings[count.index], "eventhub_authorization_rule_id", null)
  eventhub_name                  = lookup(var.diagnostic_settings[count.index], "eventhub_name", null)
  partner_solution_id            = lookup(var.diagnostic_settings[count.index], "partner_solution_id", null)

  # enabled_log
  dynamic "enabled_log" {
    for_each = lookup(var.diagnostic_settings[count.index], "enabled_logs", toset([]))

    content {
      category = enabled_log.value
    }
  }

  # enabled_category
  dynamic "enabled_log" {
    for_each = lookup(var.diagnostic_settings[count.index], "enabled_categories", toset([]))

    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = lookup(var.diagnostic_settings[count.index], "metric", toset([]))

    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [metric, enabled_log, log_analytics_destination_type, ]
  }
}