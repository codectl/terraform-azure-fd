output "profile" {
  description = "contains frontdoor configuration"
  value       = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.this["this"] : azurerm_cdn_frontdoor_profile.this["this"]
}

output "endpoints" {
  description = "contains frontdoor endpoint configuration"
  value       = azurerm_cdn_frontdoor_endpoint.this
}

output "custom_domains" {
  description = "contains custom domain configuration"
  value       = azurerm_cdn_frontdoor_custom_domain.this
}

output "origin_groups" {
  description = "contains origin group configuration"
  value       = azurerm_cdn_frontdoor_origin_group.this
}

output "origins" {
  description = "contains origin configuration"
  value       = azurerm_cdn_frontdoor_origin.this
}

output "routes" {
  description = "contains route configuration"
  value       = azurerm_cdn_frontdoor_route.this
}

output "rule_sets" {
  description = "contains rule set configuration"
  value       = azurerm_cdn_frontdoor_rule_set.this
}

output "rules" {
  description = "contains rule configuration"
  value       = azurerm_cdn_frontdoor_rule.this
}
