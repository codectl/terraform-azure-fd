mock_provider "azurerm" {
  mock_data "azurerm_cdn_frontdoor_profile" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.Cdn/profiles/afd-existing"
    }
  }
}

variables {
  location            = "westeurope"
  resource_group_name = "rg-fallback"

  profile = {
    name                = "afd-unused"
    existing            = "afd-existing"
    resource_group_name = "rg-shared"

    endpoints = {
      web = {
        applications = {
          portal = {
            origin_groups = {
              apps = {
                origins = {
                  primary = { host_name = "primary.example.net" }
                  backup  = { host_name = "backup.example.net" }
                }
                routes = {
                  main = {
                    patterns_to_match = ["/*"]
                    custom_domains = {
                      www = { host_name = "www.example.com" }
                    }
                    rule_sets = {
                      security = {
                        rules = {
                          hsts = {
                            order = 1
                            actions = [{
                              modify_response_header = {
                                operator     = "Append"
                                header_name  = "Strict-Transport-Security"
                                header_value = "max-age=31536000"
                              }
                            }]
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

run "existing_profile_selects_data_source" {
  command = plan

  assert {
    condition = length(data.azurerm_cdn_frontdoor_profile.this) == 1 && length(azurerm_cdn_frontdoor_profile.this) == 0
    error_message = format(
      "profile.existing must select the data source, got %d data source instance(s) and %d managed profile(s)",
      length(data.azurerm_cdn_frontdoor_profile.this),
      length(azurerm_cdn_frontdoor_profile.this),
    )
  }

  assert {
    condition     = data.azurerm_cdn_frontdoor_profile.this["this"].name == "afd-existing"
    error_message = format("data source must look up profile.existing, got %q", data.azurerm_cdn_frontdoor_profile.this["this"].name)
  }

  assert {
    condition = data.azurerm_cdn_frontdoor_profile.this["this"].resource_group_name == "rg-shared"
    error_message = format(
      "profile.resource_group_name must take precedence over var.resource_group_name, got %q",
      data.azurerm_cdn_frontdoor_profile.this["this"].resource_group_name,
    )
  }
}

run "children_attach_to_existing_profile" {
  command = plan

  assert {
    condition     = azurerm_cdn_frontdoor_endpoint.this["web"].cdn_frontdoor_profile_id == data.azurerm_cdn_frontdoor_profile.this["this"].id
    error_message = format("endpoint must attach to the existing profile id, got %q", azurerm_cdn_frontdoor_endpoint.this["web"].cdn_frontdoor_profile_id)
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin_group.this["web-portal-apps"].cdn_frontdoor_profile_id == data.azurerm_cdn_frontdoor_profile.this["this"].id
    error_message = format("origin group must attach to the existing profile id, got %q", azurerm_cdn_frontdoor_origin_group.this["web-portal-apps"].cdn_frontdoor_profile_id)
  }

  assert {
    condition     = azurerm_cdn_frontdoor_custom_domain.this["web-portal-apps-main-www"].cdn_frontdoor_profile_id == data.azurerm_cdn_frontdoor_profile.this["this"].id
    error_message = format("custom domain must attach to the existing profile id, got %q", azurerm_cdn_frontdoor_custom_domain.this["web-portal-apps-main-www"].cdn_frontdoor_profile_id)
  }

  assert {
    condition     = azurerm_cdn_frontdoor_rule_set.this["web-portal-apps-main-security"].cdn_frontdoor_profile_id == data.azurerm_cdn_frontdoor_profile.this["this"].id
    error_message = format("rule set must attach to the existing profile id, got %q", azurerm_cdn_frontdoor_rule_set.this["web-portal-apps-main-security"].cdn_frontdoor_profile_id)
  }

  assert {
    condition     = output.profile.id == data.azurerm_cdn_frontdoor_profile.this["this"].id
    error_message = format("output \"profile\" must expose the existing profile, got %q", output.profile.id)
  }
}

run "nested_keys_link_every_level" {
  command = plan

  assert {
    condition     = sort(keys(azurerm_cdn_frontdoor_origin.this)) == tolist(["web-portal-apps-backup", "web-portal-apps-primary"])
    error_message = format("origin keys must be <endpoint>-<application>-<origin_group>-<origin>, got %v", keys(azurerm_cdn_frontdoor_origin.this))
  }

  assert {
    condition     = sort(keys(azurerm_cdn_frontdoor_rule.this)) == tolist(["web-portal-apps-main-security-hsts"])
    error_message = format("rule key must chain through route and rule set, got %v", keys(azurerm_cdn_frontdoor_rule.this))
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_route.this["web-portal-apps-main"].cdn_frontdoor_origin_ids) == 2
    error_message = format("route must reference every origin in its origin group, got %d", length(azurerm_cdn_frontdoor_route.this["web-portal-apps-main"].cdn_frontdoor_origin_ids))
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_route.this["web-portal-apps-main"].cdn_frontdoor_custom_domain_ids) == 1 && length(azurerm_cdn_frontdoor_route.this["web-portal-apps-main"].cdn_frontdoor_rule_set_ids) == 1
    error_message = "route must reference its own custom domains and rule sets"
  }

  assert {
    condition     = azurerm_cdn_frontdoor_origin.this["web-portal-apps-primary"].name == "primary" && azurerm_cdn_frontdoor_route.this["web-portal-apps-main"].name == "main"
    error_message = "resource names must fall back to their map key"
  }
}

run "managed_profile_when_existing_unset" {
  command = plan

  variables {
    profile = {
      name      = "afd-managed"
      location  = "westeurope"
      endpoints = {}
    }
  }

  assert {
    condition = length(azurerm_cdn_frontdoor_profile.this) == 1 && length(data.azurerm_cdn_frontdoor_profile.this) == 0
    error_message = format(
      "without profile.existing a managed profile must be created, got %d managed profile(s) and %d data source instance(s)",
      length(azurerm_cdn_frontdoor_profile.this),
      length(data.azurerm_cdn_frontdoor_profile.this),
    )
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this["this"].resource_group_name == "rg-fallback" && azurerm_cdn_frontdoor_profile.this["this"].sku_name == "Standard_AzureFrontDoor"
    error_message = "managed profile must fall back to var.resource_group_name and the default sku"
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_endpoint.this) == 0 && length(azurerm_cdn_frontdoor_route.this) == 0
    error_message = "no endpoints must yield no child resources"
  }
}
