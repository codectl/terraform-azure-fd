locals {
  assets = {
    origin_groups = {
      primary = {
        load_balancing = {
          sample_size                 = 4
          successful_samples_required = 3
        }
        health_probe = {
          interval_in_seconds = 100
          path                = "/health"
          protocol            = "Https"
        }
        origins = {
          storage = {
            host_name                      = module.storage.account.primary_web_host
            origin_host_header             = module.storage.account.primary_web_host
            certificate_name_check_enabled = true
            priority                       = 1
            weight                         = 500
            private_link = {
              location               = module.rg.groups.demo.location
              private_link_target_id = module.storage.account.id
              target_type            = "blob"
            }
          }
        }
        routes = {
          default = {
            patterns_to_match   = ["/*"]
            supported_protocols = ["Http", "Https"]
            forwarding_protocol = "HttpsOnly"
          }
        }
      }
    }
  }
}
