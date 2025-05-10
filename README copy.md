<!-- BEGIN_TF_DOCS -->

# Terraform Module for creating Redis Cache [ Basic / Standard / Premium ]

## Release Note

- v0.0.5
  - Upgrade diagnostic settings to support multiple rules and destination with retention policy
- v0.1.0
  - Support AzureRM 3.0+
  - Add
    - `private_static_ip_address`
    - `tenant_settings`
    - `subnet_id`
    - `redis_config_*`
    - `identity_*`
    - `patch_schedule_*`
- v0.1.1
  - Test on AzureRM 3.41.0
  - Remove `location` validation
  - Change default value of `redis_version` from 4 to 6
  - Add resource `azurerm_redis_firewall_rule` which add new arguments as follows
    - `firewall_rules`
  - Add `azurerm_monitor_diagnostic_setting` arguments
    - `enabled_log`
    - `enabled_categories`
    - `partner_solution_id`
- v0.1.2
  - Test on AzureRM 3.41.0
  - ignore change on `enabled_log` and `log_analytics_destination_type` of `azurerm_monitor_diagnostic_setting`
- v0.1.3
  - Test on AzureRM 3.78.0
  - remove these variables because `retention_policy` is deprecated in favor of `azurerm_storage_management_policy`. See [more](https://aka.ms/diagnostic_settings_log_retention).
    - `diagnostic_settings[*].log_retention_policy`
    - `diagnostic_settings[*].metric_retention_policy`
- v0.2.0
  - Support AzureRM 4.0+
  - Test on AzureRM 4.4.0
  - Remove these variables because `log` is deprecated in favour of the `enabled_log`.
  - Change `enable_non_ssl_port` to `non_ssl_port_enabled`
  - Change `enable_authentication` to `authentication_enabled`

## Example

```hcl
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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity"></a> [capacity](#input\_capacity) | The size of the Redis cache to deploy. For family = C --> 0, 1, 2, 3, 4, 5, 6, For family = P --> 1, 2, 3, 4 | `number` | `0` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | List of diagnotic settings for this resource.<pre>{<br>  suffix_name                    = string<br>  enabled_logs                   = list(string) # ["ConnectedClientList",]<br>  enabled_categories             = list(string) # ["audit", "allLogs",]<br>  metric                         = list(string) # ["AllMetrics",]<br>storage_account_id             = string<br>  log_analytics_workspace_id     = string<br>  log_analytics_destination_type = string # "AzureDiagnostics" or "Dedicated"<br>  eventhub_authorization_rule_id = string<br>  eventhub_name                  = string<br>  partner_solution_id            = string<br>},</pre> | `list(any)` | `[]` | no |
| <a name="input_non_ssl_port_enabled"></a> [non\_ssl\_port\_enabled](#input\_non\_ssl\_port\_enabled) | Enable the non-SSL port (6379) | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Enable Private Endpoint | `bool` | `false` | no |
| <a name="input_family"></a> [family](#input\_family) | The SKU family/pricing group to use. | `string` | `"C"` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | List of Firewall Rules:<pre>firewall_rules = {<br>  "name" = {<br>    start_ip = string # The lowest IP address included in the range<br>    end_ip   = string # The highest IP address included in the range<br>  }<br>}</pre> | `map(any)` | `{}` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | A list of User Assigned Managed Identity IDs to be assigned to this Batch Account. | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Specifies the type of Managed Service Identity that should be configured on this Batch Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). | `string` | `null` | no |
| <a name="input_link_snet_id"></a> [link\_snet\_id](#input\_link\_snet\_id) | ID of subnet where private endpoint will be created. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Region that this container registry will be created | `string` | `"southeastasia"` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | The minimum TLS version. | `string` | `"1.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Redis instance. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_patch_schedule_day_of_week"></a> [patch\_schedule\_day\_of\_week](#input\_patch\_schedule\_day\_of\_week) | The weekday name - possible values include `Monday`, `Tuesday`, `Wednesday` etc. | `string` | `"Tuesday"` | no |
| <a name="input_patch_schedule_maintenance_window"></a> [patch\_schedule\_maintenance\_window](#input\_patch\_schedule\_maintenance\_window) | The ISO 8601 timespan which specifies the amount of time the Redis Cache can be updated. | `string` | `"PT5H"` | no |
| <a name="input_patch_schedule_start_hour_utc"></a> [patch\_schedule\_start\_hour\_utc](#input\_patch\_schedule\_start\_hour\_utc) | The start hour for maintenance in UTC - possible values range from `0 - 23`. | `number` | `18` | no |
| <a name="input_pe_name"></a> [pe\_name](#input\_pe\_name) | Name of private endpoint | `string` | `""` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | ID of private DNS zone to register private link. | `string` | `null` | no |
| <a name="input_private_static_ip_address"></a> [private\_static\_ip\_address](#input\_private\_static\_ip\_address) | The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether or not public network access is allowed for this Redis Cache | `bool` | `true` | no |
| <a name="input_redis_config_aof_backup_enabled"></a> [redis\_config\_aof\_backup\_enabled](#input\_redis\_config\_aof\_backup\_enabled) | Enable or disable AOF persistence for this Redis Cache. | `bool` | `false` | no |
| <a name="input_redis_config_aof_storage_connection_string_0"></a> [redis\_config\_aof\_storage\_connection\_string\_0](#input\_redis\_config\_aof\_storage\_connection\_string\_0) | First Storage Account connection string for AOF persistence. | `string` | `null` | no |
| <a name="input_redis_config_aof_storage_connection_string_1"></a> [redis\_config\_aof\_storage\_connection\_string\_1](#input\_redis\_config\_aof\_storage\_connection\_string\_1) | Second Storage Account connection string for AOF persistence. | `string` | `null` | no |
| <a name="input_redis_config_authentication_enabled"></a> [redis\_config\_authentication\_enabled](#input\_redis\_config\_authentication\_enabled) | If set to `false`, the Redis instance will be accessible without authentication. | `bool` | `true` | no |
| <a name="input_redis_config_maxfragmentationmemory_reserved"></a> [redis\_config\_maxfragmentationmemory\_reserved](#input\_redis\_config\_maxfragmentationmemory\_reserved) | n/a | `number` | `null` | no |
| <a name="input_redis_config_maxmemory_delta"></a> [redis\_config\_maxmemory\_delta](#input\_redis\_config\_maxmemory\_delta) | The max-memory delta for this Redis instance. Defaults are shown below. | `number` | `null` | no |
| <a name="input_redis_config_maxmemory_policy"></a> [redis\_config\_maxmemory\_policy](#input\_redis\_config\_maxmemory\_policy) | How Redis will select what to remove when maxmemory is reached. Defaults are shown below. | `string` | `null` | no |
| <a name="input_redis_config_maxmemory_reserved"></a> [redis\_config\_maxmemory\_reserved](#input\_redis\_config\_maxmemory\_reserved) | Value in megabytes reserved for non-cache usage e.g. failover. Defaults are shown below. | `number` | `null` | no |
| <a name="input_redis_config_notify_keyspace_events"></a> [redis\_config\_notify\_keyspace\_events](#input\_redis\_config\_notify\_keyspace\_events) | Keyspace notifications allows clients to subscribe to Pub/Sub channels in order to receive events affecting the Redis data set in some way. [Reference](https://redis.io/docs/manual/keyspace-notifications/) | `string` | `null` | no |
| <a name="input_redis_config_rdb_backup_enabled"></a> [redis\_config\_rdb\_backup\_enabled](#input\_redis\_config\_rdb\_backup\_enabled) | Is Backup Enabled? Only supported on Premium SKUs. | `bool` | `false` | no |
| <a name="input_redis_config_rdb_backup_frequency"></a> [redis\_config\_rdb\_backup\_frequency](#input\_redis\_config\_rdb\_backup\_frequency) | The Backup Frequency in Minutes. Only supported on Premium SKUs. Possible values are: `15`, `30`, `60`, `360`, `720` and `1440`. | `number` | `null` | no |
| <a name="input_redis_config_rdb_backup_max_snapshot_count"></a> [redis\_config\_rdb\_backup\_max\_snapshot\_count](#input\_redis\_config\_rdb\_backup\_max\_snapshot\_count) | The maximum number of snapshots to create as a backup. Only supported for Premium SKUs. | `number` | `null` | no |
| <a name="input_redis_config_rdb_storage_connection_string"></a> [redis\_config\_rdb\_storage\_connection\_string](#input\_redis\_config\_rdb\_storage\_connection\_string) | The Connection String to the Storage Account. Only supported for Premium SKUs. | `string` | `null` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis version. Only major version needed --> 4, 6 (Preview) | `number` | `6` | no |
| <a name="input_replicas_per_master"></a> [replicas\_per\_master](#input\_replicas\_per\_master) | Amount of replicas to create per master for this Redis Cache. | `number` | `null` | no |
| <a name="input_replicas_per_primary"></a> [replicas\_per\_primary](#input\_replicas\_per\_primary) | Amount of replicas to create per primary for this Redis Cache. | `number` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Redis instance. | `string` | n/a | yes |
| <a name="input_shard_count"></a> [shard\_count](#input\_shard\_count) | Only available when using the Premium SKU The number of Shards to create on the Redis Cluster. (Not support in Redis 6) | `number` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU of Redis to use. | `string` | `"Basic"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the Subnet within which the Redis Cache should be deployed. This Subnet must only contain Azure Cache for Redis instances without any other type of resources. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | <pre>{<br>  "Notice": "Please use tags follow CDC standard"<br>}</pre> | no |
| <a name="input_tenant_settings"></a> [tenant\_settings](#input\_tenant\_settings) | A mapping of tenant settings to assign to the resource. | `map(any)` | `{}` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A list of a one or more Availability Zones, where the Redis Cache should be allocated. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hostname"></a> [hostname](#output\_hostname) | The Hostname of the Redis Instance |
| <a name="output_id"></a> [id](#output\_id) | The Route ID |
| <a name="output_port"></a> [port](#output\_port) | The non-SSL Port of the Redis Instance |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | The Primary Access Key for the Redis Instance |
| <a name="output_primary_connection_string"></a> [primary\_connection\_string](#output\_primary\_connection\_string) | The primary connection string of the Redis Instance. |
| <a name="output_redis_configuration"></a> [redis\_configuration](#output\_redis\_configuration) | The configuration of redis |
| <a name="output_secondary_access_key"></a> [secondary\_access\_key](#output\_secondary\_access\_key) | The Secondary Access Key for the Redis Instance |
| <a name="output_secondary_connection_string"></a> [secondary\_connection\_string](#output\_secondary\_connection\_string) | The secondary connection string of the Redis Instance. |
| <a name="output_ssl_port"></a> [ssl\_port](#output\_ssl\_port) | The SSL Port of the Redis Instance |
<!-- END_TF_DOCS -->