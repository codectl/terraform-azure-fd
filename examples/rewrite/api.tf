locals {
  api = {
    origin_groups = {
      backend = {
        origins = {
          primary = {
            host_name          = "example-api.azurewebsites.net"
            origin_host_header = "example-api.azurewebsites.net"
          }
        }
        routes = {
          api = {
            patterns_to_match      = ["/api/*"]
            https_redirect_enabled = false
            rule_sets = {
              traffic = {
                rules = {
                  versioned = {
                    order              = 1
                    behaviour_on_match = "Continue"
                    actions = [{
                      url_rewrite = {
                        source_pattern                  = "/api/"
                        destination_path                = "/v2/"
                        preserve_unmatched_path_enabled = true
                      }
                    }]
                    conditions = [{
                      request_header = {
                        name       = "X-Api-Version"
                        operator   = "NotEqual"
                        values     = ["1"]
                        transforms = ["Trim"]
                      }
                    }]
                  }
                  static = {
                    order              = 2
                    behaviour_on_match = "Stop"
                    actions = [{
                      route_configuration_override = {
                        caching = {
                          behaviour              = "OverrideAlways"
                          duration               = "1.12:00:00"
                          query_string_behaviour = "IgnoreQueryString"
                          compression_enabled    = true
                        }
                      }
                    }]
                    conditions = [{
                      request_method = {
                        operator = "Equal"
                        values   = ["GET", "HEAD"]
                      }
                      request_file_extension = {
                        operator   = "Equal"
                        values     = ["json", "xml"]
                        transforms = ["Lowercase"]
                      }
                    }]
                  }
                  blocklegacy = {
                    order              = 3
                    behaviour_on_match = "Stop"
                    actions = [{
                      url_redirect = {
                        redirect_type     = "PermanentRedirect"
                        redirect_protocol = "Https"
                        destination_path  = "/upgrade"
                        query_string      = "reason=unsupported"
                      }
                    }]
                    conditions = [{
                      http_version = {
                        operator = "NotEqual"
                        values   = ["2.0"]
                      }
                      request_scheme = {
                        operator = "Equal"
                        values   = ["HTTP"]
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
