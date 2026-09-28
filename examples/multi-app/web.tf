locals {
  web = {
    origin_groups = {
      frontend = {
        health_probe = {
          interval_in_seconds = 100
          path                = "/"
          protocol            = "Https"
        }
        origins = {
          primary = {
            host_name          = "example-web.azurewebsites.net"
            origin_host_header = "example-web.azurewebsites.net"
          }
        }
        routes = {
          default = {
            patterns_to_match = ["/*"]
            cache = {
              query_string_caching_behavior = "IgnoreQueryString"
              compression_enabled           = true
              content_types_to_compress     = ["text/html", "text/css", "text/javascript"]
            }
          }
        }
      }
    }
  }
}
