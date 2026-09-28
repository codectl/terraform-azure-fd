# Frontdoor

This terraform module simplifies the deployment and management of azure frontdoor, providing customizable routing and backend configurations for efficient global traffic distribution and improved application performance.

## Features

Enables configuration of new or existing frontdoor profiles

Enables multiple endpoints and applications per profile.

Allows multiple custom domains per route configuration.

Multiple origin groups per application with load balancing and health probes.

Multiple origins per origin group with priority and weighting.

Supports multiple routes per origin group.

Enables creation of multiple rule sets per route.

Multiple rules per rule set with conditions and actions.

Supports private link configurations on origins

Utilization of terratest for robust validation.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 5.0)

## Resources

The following resources are used by this module:

- [azurerm_cdn_frontdoor_custom_domain.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) (resource)
- [azurerm_cdn_frontdoor_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) (resource)
- [azurerm_cdn_frontdoor_origin.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) (resource)
- [azurerm_cdn_frontdoor_origin_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) (resource)
- [azurerm_cdn_frontdoor_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) (resource)
- [azurerm_cdn_frontdoor_route.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) (resource)
- [azurerm_cdn_frontdoor_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) (resource)
- [azurerm_cdn_frontdoor_rule_set.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) (resource)
- [azurerm_cdn_frontdoor_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_profile) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_profile"></a> [profile](#input\_profile)

Description: contains frontdoor configuration

Type:

```hcl
object({
    name                     = optional(string)
    location                 = optional(string)
    resource_group_name      = optional(string)
    sku_name                 = optional(string, "Standard_AzureFrontDoor")
    response_timeout_seconds = optional(number)
    tags                     = optional(map(string))
    existing                 = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    log_scrubbing_rules = optional(map(object({
      match_variable = string
    })), {})
    endpoints = optional(map(object({
      name    = optional(string)
      enabled = optional(bool)
      tags    = optional(map(string))
      applications = optional(map(object({
        origin_groups = optional(map(object({
          name                                                      = optional(string)
          session_affinity_enabled                                  = optional(bool)
          restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number)
          health_probe = optional(object({
            interval_in_seconds = number
            path                = optional(string)
            protocol            = string
            request_type        = optional(string)
          }))
          load_balancing = optional(object({
            additional_latency_in_milliseconds = optional(number)
            sample_size                        = optional(number)
            successful_samples_required        = optional(number)
          }), {})
          origins = optional(map(object({
            name                           = optional(string)
            host_name                      = string
            certificate_name_check_enabled = optional(bool, true)
            enabled                        = optional(bool)
            http_port                      = optional(number)
            https_port                     = optional(number)
            origin_host_header             = optional(string)
            priority                       = optional(number)
            weight                         = optional(number)
            private_link = optional(object({
              request_message        = optional(string)
              target_type            = optional(string)
              location               = string
              private_link_target_id = string
            }))
          })), {})
          routes = optional(map(object({
            name                      = optional(string)
            enabled                   = optional(bool)
            forwarding_protocol       = optional(string, "HttpsOnly")
            https_redirect_enabled    = optional(bool)
            patterns_to_match         = list(string)
            supported_protocols       = optional(list(string), ["Http", "Https"])
            cdn_frontdoor_origin_path = optional(string)
            link_to_default_domain    = optional(bool)
            cache = optional(object({
              query_string_caching_behavior = optional(string)
              query_strings                 = optional(list(string))
              compression_enabled           = optional(bool)
              content_types_to_compress     = optional(list(string))
            }))
            custom_domains = optional(map(object({
              name        = optional(string)
              host_name   = string
              dns_zone_id = optional(string)
              tls = optional(object({
                certificate_type        = optional(string)
                minimum_version         = optional(string)
                cdn_frontdoor_secret_id = optional(string)
                cipher_suite = optional(object({
                  type = string
                  custom_ciphers = optional(object({
                    tls12 = optional(set(string))
                    tls13 = optional(set(string))
                  }))
                }))
              }), {})
            })), {})
            rule_sets = optional(map(object({
              name = optional(string)
              rules = optional(map(object({
                name               = optional(string)
                order              = number
                behaviour_on_match = optional(string)
                actions = optional(list(object({
                  url_redirect = optional(object({
                    redirect_type         = string
                    destination_host_name = optional(string)
                    destination_path      = optional(string)
                    query_string          = optional(string)
                    destination_fragment  = optional(string)
                    redirect_protocol     = optional(string)
                  }))
                  url_rewrite = optional(object({
                    source_pattern                  = string
                    destination_path                = string
                    preserve_unmatched_path_enabled = optional(bool)
                  }))
                  route_configuration_override = optional(object({
                    caching = object({
                      behaviour               = string
                      compression_enabled     = optional(bool)
                      duration                = optional(string)
                      query_string_behaviour  = optional(string)
                      query_string_parameters = optional(list(string))
                    })
                    origin_group = optional(object({
                      forwarding_protocol           = optional(string)
                      cdn_frontdoor_origin_group_id = optional(string)
                    }))
                  }))
                  modify_response_header = optional(object({
                    operator     = string
                    header_name  = string
                    header_value = string
                  }))
                  modify_request_header = optional(object({
                    operator     = string
                    header_name  = string
                    header_value = string
                  }))
                })), [])
                conditions = optional(list(object({
                  remote_address = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  client_port = optional(object({
                    operator = string
                    values   = optional(list(string))
                  }))
                  ssl_protocol = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  socket_address = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  server_port = optional(object({
                    operator = string
                    values   = optional(list(string))
                  }))
                  host_name = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_method = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  query_string = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  post_argument = optional(object({
                    name       = string
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_url = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_header = optional(object({
                    name       = string
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_body = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_scheme = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  request_path = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_file_extension = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_filename = optional(object({
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  request_cookies = optional(object({
                    name       = string
                    operator   = string
                    values     = optional(list(string))
                    transforms = optional(list(string))
                  }))
                  device_type = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                  http_version = optional(object({
                    operator = string
                    values   = list(string)
                  }))
                })), [])
              })), {})
            })), {})
          })), {})
        })), {})
      })), {})
    })), {})
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: default azure location to be used.

Type: `string`

Default: `null`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains)

Description: contains custom domain configuration

### <a name="output_endpoints"></a> [endpoints](#output\_endpoints)

Description: contains frontdoor endpoint configuration

### <a name="output_origin_groups"></a> [origin\_groups](#output\_origin\_groups)

Description: contains origin group configuration

### <a name="output_origins"></a> [origins](#output\_origins)

Description: contains origin configuration

### <a name="output_profile"></a> [profile](#output\_profile)

Description: contains frontdoor configuration

### <a name="output_routes"></a> [routes](#output\_routes)

Description: contains route configuration

### <a name="output_rule_sets"></a> [rule\_sets](#output\_rule\_sets)

Description: contains rule set configuration

### <a name="output_rules"></a> [rules](#output\_rules)

Description: contains rule configuration
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md).

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/frontdoor/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/frontdoor/)
