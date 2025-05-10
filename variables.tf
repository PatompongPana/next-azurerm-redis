variable "name" {
  description = "The name of the Redis instance. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Redis instance."
  type        = string
}

variable "location" {
  description = "Region that this container registry will be created"
  type        = string
  default     = "southeastasia"
}

variable "sku_name" {
  description = "The SKU of Redis to use."
  type        = string
  default     = "Basic"

  validation {
    condition     = can(regex("^(Basic|Standard|Premium|Enterprise)$", var.sku_name))
    error_message = "The valid value can be ==> Basic, Standard or Premium."
  }
}

variable "family" {
  description = "The SKU family/pricing group to use."
  type        = string
  default     = "C"

  validation {
    condition     = can(regex("^(C|P)$", var.family))
    error_message = "The valid value can be ==> C (for Basic/Standard SKU family) and P (for Premium)."
  }
}

variable "capacity" {
  description = "The size of the Redis cache to deploy. For family = C --> 0, 1, 2, 3, 4, 5, 6, For family = P --> 1, 2, 3, 4"
  type        = number
  default     = 0
}

variable "non_ssl_port_enabled" {
  description = "Enable the non-SSL port (6379)"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "The minimum TLS version."
  type        = string
  default     = "1.2"

  validation {
    condition     = can(regex("^(1.0|1.1|1.2)$", var.minimum_tls_version))
    error_message = "The valid value can be ==> 1.0, 1.1 or 1.2."
  }
}

variable "public_network_access_enabled" {
  description = "Whether or not public network access is allowed for this Redis Cache"
  type        = bool
  default     = true
}

variable "redis_version" {
  description = "Redis version. Only major version needed --> 4, 6 (Preview)"
  type        = number
  default     = 6

  validation {
    condition     = var.redis_version == 4 || var.redis_version == 6
    error_message = "The valid value can be ==> 4, 6 (Preview)."
  }
}

variable "replicas_per_master" {
  description = "Amount of replicas to create per master for this Redis Cache."
  type        = number
  default     = null
}

variable "replicas_per_primary" {
  description = "Amount of replicas to create per primary for this Redis Cache."
  type        = number
  default     = null
}

variable "shard_count" {
  description = "Only available when using the Premium SKU The number of Shards to create on the Redis Cluster. (Not support in Redis 6)"
  type        = number
  default     = null
}

variable "zones" {
  description = "A list of a one or more Availability Zones, where the Redis Cache should be allocated."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "Notice" = "Please use tags follow CDC standard"
  }
}

variable "redis_config_enable_authentication" {
  description = "If set to `false`, the Redis instance will be accessible without authentication."
  type        = bool
  default     = true
}

variable "redis_config_notify_keyspace_events" {
  description = "Keyspace notifications allows clients to subscribe to Pub/Sub channels in order to receive events affecting the Redis data set in some way. [Reference](https://redis.io/docs/manual/keyspace-notifications/)"
  type        = string
  default     = null
}

variable "redis_config_aof_backup_enabled" {
  description = "Enable or disable AOF persistence for this Redis Cache."
  type        = bool
  default     = false
}

variable "redis_config_aof_storage_connection_string_0" {
  description = "First Storage Account connection string for AOF persistence."
  type        = string
  default     = null
}

variable "redis_config_aof_storage_connection_string_1" {
  description = "Second Storage Account connection string for AOF persistence."
  type        = string
  default     = null
}

variable "redis_config_maxmemory_reserved" {
  description = "Value in megabytes reserved for non-cache usage e.g. failover. Defaults are shown below."
  type        = number
  default     = null
}

variable "redis_config_maxfragmentationmemory_reserved" {
  description = ""
  type        = number
  default     = null
}

variable "redis_config_maxmemory_delta" {
  description = "The max-memory delta for this Redis instance. Defaults are shown below."
  type        = number
  default     = null
}

variable "redis_config_maxmemory_policy" {
  description = "How Redis will select what to remove when maxmemory is reached. Defaults are shown below."
  type        = string
  default     = null
}

variable "redis_config_rdb_backup_enabled" {
  description = "Is Backup Enabled? Only supported on Premium SKUs."
  type        = bool
  default     = false
}

variable "redis_config_rdb_storage_connection_string" {
  description = "The Connection String to the Storage Account. Only supported for Premium SKUs."
  type        = string
  default     = null
}

variable "redis_config_rdb_backup_frequency" {
  description = "The Backup Frequency in Minutes. Only supported on Premium SKUs. Possible values are: `15`, `30`, `60`, `360`, `720` and `1440`."
  type        = number
  default     = null
}

variable "redis_config_rdb_backup_max_snapshot_count" {
  description = "The maximum number of snapshots to create as a backup. Only supported for Premium SKUs."
  type        = number
  default     = null
}

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Batch Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "A list of User Assigned Managed Identity IDs to be assigned to this Batch Account."
  type        = list(string)
  default     = []
}

variable "patch_schedule_day_of_week" {
  description = "The weekday name - possible values include `Monday`, `Tuesday`, `Wednesday` etc."
  type        = string
  default     = "Tuesday"
}

variable "patch_schedule_start_hour_utc" {
  description = "The start hour for maintenance in UTC - possible values range from `0 - 23`."
  type        = number
  default     = 18
}

variable "patch_schedule_maintenance_window" {
  description = "The ISO 8601 timespan which specifies the amount of time the Redis Cache can be updated."
  type        = string
  default     = "PT5H"
}

variable "private_static_ip_address" {
  description = "The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the Subnet within which the Redis Cache should be deployed. This Subnet must only contain Azure Cache for Redis instances without any other type of resources. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "tenant_settings" {
  description = "A mapping of tenant settings to assign to the resource."
  type        = map(any)
  default     = {}
}

variable "firewall_rules" {
  description = <<EOT
List of Firewall Rules:
```
firewall_rules = {
  "name" = {
    start_ip = string # The lowest IP address included in the range
    end_ip   = string # The highest IP address included in the range
  }
}
```
EOT
  type        = map(any)
  default     = {}
}

#
# Private Endpoint
#

variable "enable_private_endpoint" {
  description = "Enable Private Endpoint"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "ID of private DNS zone to register private link."
  type        = string
  default     = null
}

variable "link_snet_id" {
  description = "ID of subnet where private endpoint will be created."
  type        = string
  default     = null
}

variable "pe_name" {
  description = "Name of private endpoint"
  type        = string
  default     = ""
}

#
# Diagnostic
#

variable "diagnostic_settings" {
  description = <<EOT
List of diagnotic settings for this resource.
```
{
  suffix_name                    = string
  enabled_logs                   = list(string) # ["ConnectedClientList",]
  enabled_categories             = list(string) # ["audit", "allLogs",]
  metric                         = list(string) # ["AllMetrics",]
  log                            = list(string) # Same as `enabled_logs` but log will be deprecated in AzureRM 4.0
  storage_account_id             = string
  log_analytics_workspace_id     = string
  log_analytics_destination_type = string # "AzureDiagnostics" or "Dedicated"
  eventhub_authorization_rule_id = string
  eventhub_name                  = string
  partner_solution_id            = string
},
```
EOT
  type        = list(any)
  default     = []
}

variable "authentication_enabled" {
  description = "Enable Redis authentication"
  type        = bool
  default     = false
}

variable "active_directory_authentication_enabled" {
  description = "Enable Active Directory authentication"
  type        = bool
  default     = false
}