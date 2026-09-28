This deploys frontdoor rules using url rewrites, caching overrides and redirects.

## Notes

Negation is expressed through the `Not*` operator values such as `NotEqual`; there is no separate negate flag anymore.

A `route_configuration_override` always requires a `caching` block with a `behaviour`.
