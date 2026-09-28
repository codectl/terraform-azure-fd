# existing
data "azurerm_cdn_frontdoor_profile" "this" {
  for_each = var.profile.existing != null ? { "this" = var.profile.existing } : {}

  name = each.value

  resource_group_name = coalesce(
    var.profile.resource_group_name, var.resource_group_name
  )
}


# profile
resource "azurerm_cdn_frontdoor_profile" "this" {
  for_each = var.profile.existing != null ? {} : { "this" = var.profile }

  resource_group_name = coalesce(
    each.value.resource_group_name, var.resource_group_name
  )

  name                     = each.value.name
  sku_name                 = each.value.sku_name
  response_timeout_seconds = each.value.response_timeout_seconds

  tags = coalesce(
    each.value.tags, var.tags
  )

  dynamic "identity" {
    for_each = each.value.identity != null ? { "this" = each.value.identity } : {}

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "log_scrubbing_rule" {
    for_each = each.value.log_scrubbing_rules

    content {
      match_variable = log_scrubbing_rule.value.match_variable
    }
  }
}

# endpoints
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = var.profile.endpoints

  name = coalesce(
    each.value.name, each.key
  )

  tags = coalesce(
    each.value.tags, var.tags
  )

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.this["this"].id : azurerm_cdn_frontdoor_profile.this["this"].id
  enabled                  = each.value.enabled
}

# custom domains
resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : [
        for og_key, og in app.origin_groups : [
          for route_key, route in og.routes : {
            for cd_key, cd in route.custom_domains : "${ep_key}-${app_key}-${og_key}-${route_key}-${cd_key}" => {
              cd_key        = cd_key
              custom_domain = cd
            }
          }
        ]
      ]
    ]
  ])...)

  name = coalesce(
    each.value.custom_domain.name, each.value.cd_key
  )

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.this["this"].id : azurerm_cdn_frontdoor_profile.this["this"].id
  dns_zone_id              = each.value.custom_domain.dns_zone_id
  host_name                = each.value.custom_domain.host_name

  dynamic "tls" {
    for_each = each.value.custom_domain.tls != null ? { "this" = each.value.custom_domain.tls } : {}

    content {
      certificate_type        = tls.value.certificate_type
      minimum_version         = tls.value.minimum_version
      cdn_frontdoor_secret_id = tls.value.cdn_frontdoor_secret_id

      dynamic "cipher_suite" {
        for_each = tls.value.cipher_suite != null ? { "this" = tls.value.cipher_suite } : {}

        content {
          type = cipher_suite.value.type

          dynamic "custom_ciphers" {
            for_each = cipher_suite.value.custom_ciphers != null ? { "this" = cipher_suite.value.custom_ciphers } : {}

            content {
              tls12 = custom_ciphers.value.tls12
              tls13 = custom_ciphers.value.tls13
            }
          }
        }
      }
    }
  }
}

# origin groups
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : {
        for og_key, og in app.origin_groups : "${ep_key}-${app_key}-${og_key}" => {
          og_key = og_key
          og     = og
        }
      }
    ]
  ])...)

  name = coalesce(
    each.value.og.name, each.value.og_key
  )

  cdn_frontdoor_profile_id                                  = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.this["this"].id : azurerm_cdn_frontdoor_profile.this["this"].id
  session_affinity_enabled                                  = each.value.og.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.og.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "health_probe" {
    for_each = each.value.og.health_probe != null ? { "this" = each.value.og.health_probe } : {}

    content {
      interval_in_seconds = health_probe.value.interval_in_seconds
      path                = health_probe.value.path
      protocol            = health_probe.value.protocol
      request_type        = health_probe.value.request_type
    }
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.og.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.og.load_balancing.sample_size
    successful_samples_required        = each.value.og.load_balancing.successful_samples_required
  }
}

# origins
resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : [
        for og_key, og in app.origin_groups : {
          for origin_key, origin in og.origins : "${ep_key}-${app_key}-${og_key}-${origin_key}" => {
            og_key     = "${ep_key}-${app_key}-${og_key}"
            origin_key = origin_key
            origin     = origin
          }
        }
      ]
    ]
  ])...)

  name = coalesce(
    each.value.origin.name, each.value.origin_key
  )

  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.og_key].id
  enabled                        = each.value.origin.enabled
  certificate_name_check_enabled = each.value.origin.certificate_name_check_enabled
  host_name                      = each.value.origin.host_name
  http_port                      = each.value.origin.http_port
  https_port                     = each.value.origin.https_port
  origin_host_header             = each.value.origin.origin_host_header
  priority                       = each.value.origin.priority
  weight                         = each.value.origin.weight

  dynamic "private_link" {
    for_each = each.value.origin.private_link != null ? { "this" = each.value.origin.private_link } : {}

    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }
}

# routes
resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : [
        for og_key, og in app.origin_groups : {
          for route_key, route in og.routes : "${ep_key}-${app_key}-${og_key}-${route_key}" => {
            endpoint           = ep_key
            og_key             = "${ep_key}-${app_key}-${og_key}"
            origin_keys        = [for k in keys(og.origins) : "${ep_key}-${app_key}-${og_key}-${k}"]
            custom_domain_keys = [for k in keys(route.custom_domains) : "${ep_key}-${app_key}-${og_key}-${route_key}-${k}"]
            rule_set_keys      = [for k in keys(route.rule_sets) : "${ep_key}-${app_key}-${og_key}-${route_key}-${k}"]
            route_key          = route_key
            route              = route
          }
        }
      ]
    ]
  ])...)

  name = coalesce(
    each.value.route.name, each.value.route_key
  )

  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.og_key].id
  enabled                       = each.value.route.enabled
  forwarding_protocol           = each.value.route.forwarding_protocol
  https_redirect_enabled        = each.value.route.https_redirect_enabled
  patterns_to_match             = each.value.route.patterns_to_match
  supported_protocols           = each.value.route.supported_protocols
  link_to_default_domain        = each.value.route.link_to_default_domain
  cdn_frontdoor_origin_path     = each.value.route.cdn_frontdoor_origin_path

  cdn_frontdoor_origin_ids = [
    for k in each.value.origin_keys : azurerm_cdn_frontdoor_origin.this[k].id
  ]

  cdn_frontdoor_custom_domain_ids = [
    for k in each.value.custom_domain_keys : azurerm_cdn_frontdoor_custom_domain.this[k].id
  ]

  cdn_frontdoor_rule_set_ids = [
    for k in each.value.rule_set_keys : azurerm_cdn_frontdoor_rule_set.this[k].id
  ]

  dynamic "cache" {
    for_each = each.value.route.cache != null ? { "this" = each.value.route.cache } : {}

    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

# rule sets
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : [
        for og_key, og in app.origin_groups : [
          for route_key, route in og.routes : {
            for rs_key, rs in route.rule_sets : "${ep_key}-${app_key}-${og_key}-${route_key}-${rs_key}" => {
              rs_key = rs_key
              rs     = rs
            }
          }
        ]
      ]
    ]
  ])...)

  name = coalesce(
    each.value.rs.name, each.value.rs_key
  )

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.this["this"].id : azurerm_cdn_frontdoor_profile.this["this"].id
}

# rules
resource "azurerm_cdn_frontdoor_rule" "this" {
  for_each = merge(flatten([
    for ep_key, ep in var.profile.endpoints : [
      for app_key, app in ep.applications : [
        for og_key, og in app.origin_groups : [
          for route_key, route in og.routes : [
            for rs_key, rs in route.rule_sets : {
              for rule_key, rule in rs.rules : "${ep_key}-${app_key}-${og_key}-${route_key}-${rs_key}-${rule_key}" => {
                rs_key   = "${ep_key}-${app_key}-${og_key}-${route_key}-${rs_key}"
                rule_key = rule_key
                rule     = rule
              }
            }
          ]
        ]
      ]
    ]
  ])...)

  name = coalesce(
    each.value.rule.name, each.value.rule_key
  )

  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[each.value.rs_key].id
  order                     = each.value.rule.order
  behaviour_on_match        = each.value.rule.behaviour_on_match

  depends_on = [
    azurerm_cdn_frontdoor_origin.this,
    azurerm_cdn_frontdoor_origin_group.this,
  ]

  dynamic "actions" {
    for_each = each.value.rule.actions

    content {
      dynamic "url_redirect" {
        for_each = actions.value.url_redirect != null ? { "this" = actions.value.url_redirect } : {}

        content {
          redirect_type         = url_redirect.value.redirect_type
          destination_host_name = url_redirect.value.destination_host_name
          destination_path      = url_redirect.value.destination_path
          query_string          = url_redirect.value.query_string
          destination_fragment  = url_redirect.value.destination_fragment
          redirect_protocol     = url_redirect.value.redirect_protocol
        }
      }

      dynamic "url_rewrite" {
        for_each = actions.value.url_rewrite != null ? { "this" = actions.value.url_rewrite } : {}

        content {
          source_pattern                  = url_rewrite.value.source_pattern
          destination_path                = url_rewrite.value.destination_path
          preserve_unmatched_path_enabled = url_rewrite.value.preserve_unmatched_path_enabled
        }
      }

      dynamic "route_configuration_override" {
        for_each = actions.value.route_configuration_override != null ? { "this" = actions.value.route_configuration_override } : {}

        content {
          caching {
            behaviour               = route_configuration_override.value.caching.behaviour
            compression_enabled     = route_configuration_override.value.caching.compression_enabled
            duration                = route_configuration_override.value.caching.duration
            query_string_behaviour  = route_configuration_override.value.caching.query_string_behaviour
            query_string_parameters = route_configuration_override.value.caching.query_string_parameters
          }

          dynamic "origin_group" {
            for_each = route_configuration_override.value.origin_group != null ? { "this" = route_configuration_override.value.origin_group } : {}

            content {
              forwarding_protocol           = origin_group.value.forwarding_protocol
              cdn_frontdoor_origin_group_id = origin_group.value.cdn_frontdoor_origin_group_id
            }
          }
        }
      }

      dynamic "modify_response_header" {
        for_each = actions.value.modify_response_header != null ? { "this" = actions.value.modify_response_header } : {}

        content {
          operator     = modify_response_header.value.operator
          header_name  = modify_response_header.value.header_name
          header_value = modify_response_header.value.header_value
        }
      }

      dynamic "modify_request_header" {
        for_each = actions.value.modify_request_header != null ? { "this" = actions.value.modify_request_header } : {}

        content {
          operator     = modify_request_header.value.operator
          header_name  = modify_request_header.value.header_name
          header_value = modify_request_header.value.header_value
        }
      }
    }
  }

  dynamic "conditions" {
    for_each = each.value.rule.conditions

    content {
      dynamic "remote_address" {
        for_each = conditions.value.remote_address != null ? { "this" = conditions.value.remote_address } : {}

        content {
          operator = remote_address.value.operator
          values   = remote_address.value.values
        }
      }

      dynamic "client_port" {
        for_each = conditions.value.client_port != null ? { "this" = conditions.value.client_port } : {}

        content {
          operator = client_port.value.operator
          values   = client_port.value.values
        }
      }

      dynamic "ssl_protocol" {
        for_each = conditions.value.ssl_protocol != null ? { "this" = conditions.value.ssl_protocol } : {}

        content {
          values   = ssl_protocol.value.values
          operator = ssl_protocol.value.operator
        }
      }

      dynamic "socket_address" {
        for_each = conditions.value.socket_address != null ? { "this" = conditions.value.socket_address } : {}

        content {
          values   = socket_address.value.values
          operator = socket_address.value.operator
        }
      }

      dynamic "server_port" {
        for_each = conditions.value.server_port != null ? { "this" = conditions.value.server_port } : {}

        content {
          operator = server_port.value.operator
          values   = server_port.value.values
        }
      }

      dynamic "host_name" {
        for_each = conditions.value.host_name != null ? { "this" = conditions.value.host_name } : {}

        content {
          values     = host_name.value.values
          operator   = host_name.value.operator
          transforms = host_name.value.transforms
        }
      }

      dynamic "request_method" {
        for_each = conditions.value.request_method != null ? { "this" = conditions.value.request_method } : {}

        content {
          values   = request_method.value.values
          operator = request_method.value.operator
        }
      }

      dynamic "query_string" {
        for_each = conditions.value.query_string != null ? { "this" = conditions.value.query_string } : {}

        content {
          operator   = query_string.value.operator
          values     = query_string.value.values
          transforms = query_string.value.transforms
        }
      }

      dynamic "post_argument" {
        for_each = conditions.value.post_argument != null ? { "this" = conditions.value.post_argument } : {}

        content {
          operator   = post_argument.value.operator
          name       = post_argument.value.name
          transforms = post_argument.value.transforms
          values     = post_argument.value.values
        }
      }

      dynamic "request_url" {
        for_each = conditions.value.request_url != null ? { "this" = conditions.value.request_url } : {}

        content {
          operator   = request_url.value.operator
          values     = request_url.value.values
          transforms = request_url.value.transforms
        }
      }

      dynamic "request_header" {
        for_each = conditions.value.request_header != null ? { "this" = conditions.value.request_header } : {}

        content {
          name       = request_header.value.name
          operator   = request_header.value.operator
          values     = request_header.value.values
          transforms = request_header.value.transforms
        }
      }

      dynamic "request_body" {
        for_each = conditions.value.request_body != null ? { "this" = conditions.value.request_body } : {}

        content {
          operator   = request_body.value.operator
          values     = request_body.value.values
          transforms = request_body.value.transforms
        }
      }

      dynamic "request_scheme" {
        for_each = conditions.value.request_scheme != null ? { "this" = conditions.value.request_scheme } : {}

        content {
          operator = request_scheme.value.operator
          values   = request_scheme.value.values
        }
      }

      dynamic "request_path" {
        for_each = conditions.value.request_path != null ? { "this" = conditions.value.request_path } : {}

        content {
          operator   = request_path.value.operator
          values     = request_path.value.values
          transforms = request_path.value.transforms
        }
      }

      dynamic "request_file_extension" {
        for_each = conditions.value.request_file_extension != null ? { "this" = conditions.value.request_file_extension } : {}

        content {
          operator   = request_file_extension.value.operator
          values     = request_file_extension.value.values
          transforms = request_file_extension.value.transforms
        }
      }

      dynamic "request_filename" {
        for_each = conditions.value.request_filename != null ? { "this" = conditions.value.request_filename } : {}

        content {
          operator   = request_filename.value.operator
          values     = request_filename.value.values
          transforms = request_filename.value.transforms
        }
      }

      dynamic "request_cookies" {
        for_each = conditions.value.request_cookies != null ? { "this" = conditions.value.request_cookies } : {}

        content {
          name       = request_cookies.value.name
          operator   = request_cookies.value.operator
          values     = request_cookies.value.values
          transforms = request_cookies.value.transforms
        }
      }

      dynamic "device_type" {
        for_each = conditions.value.device_type != null ? { "this" = conditions.value.device_type } : {}

        content {
          operator = device_type.value.operator
          values   = device_type.value.values
        }
      }

      dynamic "http_version" {
        for_each = conditions.value.http_version != null ? { "this" = conditions.value.http_version } : {}

        content {
          operator = http_version.value.operator
          values   = http_version.value.values
        }
      }
    }
  }
}
