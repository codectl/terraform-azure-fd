module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 3.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "frontdoor" {
  source  = "cloudnationhq/fd/azure"
  version = "~> 4.0"

  profile = {
    name                     = module.naming.cdn_frontdoor_profile.name_unique
    resource_group_name      = module.rg.groups.demo.name
    location                 = module.rg.groups.demo.location
    sku_name                 = "Premium_AzureFrontDoor"
    response_timeout_seconds = 120

    log_scrubbing_rules = {
      ip = {
        match_variable = "RequestIPAddress"
      }
      uri = {
        match_variable = "RequestUri"
      }
      query = {
        match_variable = "QueryStringArgNames"
      }
    }

    endpoints = {
      demo = {
        name = module.naming.cdn_frontdoor_endpoint.name_unique
        applications = {
          portal = {
            origin_groups = {
              apps = {
                origins = {
                  primary = {
                    host_name          = "example-web-app.azurewebsites.net"
                    origin_host_header = "example-web-app.azurewebsites.net"
                  }
                }
                routes = {
                  default = {
                    patterns_to_match = ["/*"]
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
