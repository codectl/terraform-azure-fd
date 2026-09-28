moved {
  from = data.azurerm_cdn_frontdoor_profile.profile["profile"]
  to   = data.azurerm_cdn_frontdoor_profile.this["this"]
}

moved {
  from = azurerm_cdn_frontdoor_profile.profile["profile"]
  to   = azurerm_cdn_frontdoor_profile.this["this"]
}

moved {
  from = azurerm_cdn_frontdoor_endpoint.eps
  to   = azurerm_cdn_frontdoor_endpoint.this
}

moved {
  from = azurerm_cdn_frontdoor_custom_domain.domains
  to   = azurerm_cdn_frontdoor_custom_domain.this
}

moved {
  from = azurerm_cdn_frontdoor_origin_group.ogs
  to   = azurerm_cdn_frontdoor_origin_group.this
}

moved {
  from = azurerm_cdn_frontdoor_origin.origins
  to   = azurerm_cdn_frontdoor_origin.this
}

moved {
  from = azurerm_cdn_frontdoor_route.routes
  to   = azurerm_cdn_frontdoor_route.this
}

moved {
  from = azurerm_cdn_frontdoor_rule_set.rule_sets
  to   = azurerm_cdn_frontdoor_rule_set.this
}

moved {
  from = azurerm_cdn_frontdoor_rule.rules
  to   = azurerm_cdn_frontdoor_rule.this
}
