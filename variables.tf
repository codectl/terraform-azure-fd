variable "profile" {
  description = "contains frontdoor configuration"
  type = object({
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

  validation {
    condition     = var.profile.location != null || var.location != null
    error_message = "Location must be provided either in the profile object or as a separate variable."
  }

  validation {
    condition     = var.profile.resource_group_name != null || var.resource_group_name != null
    error_message = "Resource group name must be provided either in the profile object or as a separate variable."
  }
}


variable "location" {
  description = "default azure location to be used."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
