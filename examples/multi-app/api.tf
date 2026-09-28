locals {
  api = {
    origin_groups = {
      backend = {
        load_balancing = {
          sample_size                 = 4
          successful_samples_required = 3
        }
        health_probe = {
          interval_in_seconds = 30
          path                = "/health"
          protocol            = "Https"
        }
        origins = {
          west = {
            host_name          = "example-api-west.azurewebsites.net"
            origin_host_header = "example-api-west.azurewebsites.net"
            priority           = 1
          }
          north = {
            host_name          = "example-api-north.azurewebsites.net"
            origin_host_header = "example-api-north.azurewebsites.net"
            priority           = 2
          }
        }
        routes = {
          api = {
            patterns_to_match         = ["/api/*"]
            cdn_frontdoor_origin_path = "/v1"
            link_to_default_domain    = true
          }
        }
      }
    }
  }
}
