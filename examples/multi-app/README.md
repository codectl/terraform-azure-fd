This deploys multiple applications on a single frontdoor endpoint.

## Notes

Each application is defined as a local in its own file (`web.tf`, `api.tf`) and referenced from `main.tf`. Adding another application means adding a file and one entry under `applications`.

Application keys prefix the resulting resource keys, so origin groups, origins and routes stay isolated per application.
