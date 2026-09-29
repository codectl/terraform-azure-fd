module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "policy" {
  source  = "codectl/fdfwp/azure"
  version = "~> 1.0"

  cdn_frontdoor_firewall_policy = {
    name                = module.naming.cdn_frontdoor_firewall_policy.name
    frontdoor_id        = module.frontdoor.profile.id
    resource_group_name = module.rg.groups.demo.name
    sku_name            = "Premium_AzureFrontDoor"
    mode                = "Prevention"

    managed_rules = {
      default = {
        type    = "DefaultRuleSet"
        version = "1.0"
      }
      botprotection = {
        type    = "Microsoft_BotManagerRuleSet"
        version = "1.0"
      }
    }

    security_policy = {
      name = module.naming.cdn_frontdoor_security_policy.name

      associations = {
        main = {
          patterns_to_match = ["/*"]
          domains = {
            website = {
              domain_id = module.frontdoor.custom_domains["demo-portal-apps-main-portal"].id
            }
            another = {
              domain_id = module.frontdoor.custom_domains["demo-portal-apps-legacy-backup"].id
            }
          }
        }
      }
    }
  }
}

module "frontdoor" {
  source  = "codectl/fd/azure"
  version = "~> 1.0"

  profile = {
    name                = module.naming.cdn_frontdoor_profile.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku_name            = "Premium_AzureFrontDoor"

    endpoints = {
      demo = {
        name = module.naming.cdn_frontdoor_endpoint.name_unique
        applications = {
          portal = local.portal
        }
      }
    }
  }
}
