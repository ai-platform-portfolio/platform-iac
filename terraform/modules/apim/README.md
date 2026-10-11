# API Management module (AI-33)

Creates a Standard v2 APIM instance in an existing resource group with outbound
VNet integration, a user-assigned managed identity and an inbound gateway private
endpoint. Resource definitions remain here; app repositories supply module calls
and environment settings. Backend APIs and model-provider policies follow later.

## Network contract

Use the shared network module to create the APIM subnet, its NSG and any route
table. The integration subnet must be dedicated to APIM, at least /27 (a /24 is
recommended), delegated to `Microsoft.Web/serverFarms`, and in the same region
and subscription as the service. Associate an NSG before APIM provisioning and
allow outbound TCP 443 to `AzureKeyVault`. The network module's `subnet_ids`
output waits for its NSG and route associations.

The inbound endpoint uses a separate undelegated subnet. Supply an existing
`privatelink.azure-api.net` private DNS zone linked to the client VNets. Only the
Gateway subresource supports Private Link. This does not privately expose the
developer portal or establish transport to AWS/GCP.

Microsoft requires the endpoint to exist before public network access can be
disabled. The service is created with public access enabled, the endpoint is
created, and an ordered `azapi_update_resource` sets `publicNetworkAccess` to
`Disabled`. AzureRM ignores this one property so it does not undo the update.
The module's ready service outputs depend on that update. No inference APIs are
created during this initial public provisioning window. AzAPI is used solely for
this ordered ARM property update, not shell scripts or a pipeline helper.

[Standard v2 VNet requirements](https://learn.microsoft.com/en-us/azure/api-management/integrate-vnet-outbound)
[Private endpoint requirements](https://learn.microsoft.com/en-us/azure/api-management/private-endpoint)

## Inputs and outputs

Required inputs: `name`, `resource_group_name`, `location`, `sku_name`,
`publisher_name`, `publisher_email`, `integration_subnet_id`,
`private_endpoint_subnet_id`, and `private_dns_zone_id`. `tags` is optional.
This first version supports `StandardV2_1` through `StandardV2_10`; it does not
pretend classic-tier VNet injection has the same networking requirements.

Publisher inputs are sensitive and must be supplied externally. No cloud
credentials, subscription IDs, publisher contact values or secret values are
hardcoded. Backend authentication will use the managed identity; no runtime
credential values are read from Key Vault into Terraform. Terraform state remains
in the approved external backend.

Outputs expose the ready service ID/URL, private endpoint ID and managed identity
references. Client and principal IDs are sensitive outputs. Assign narrowly scoped
backend RBAC and configure policy authentication during the provider stage.

Service create/update/delete timeouts are three hours because APIM operations can
be slow. The consuming GitHub Apply job must allow at least that long too. Verify
regional SKU capacity before applying; UK West currently supports Standard v2.

## Validation

Terraform 1.9+ is required. Run `terraform init -backend=false`, `terraform validate`
and `terraform test` here. Mocked tests verify private networking and identity,
reject unsupported tiers and reject sharing the integration/endpoint subnet.
Mock tests do not prove Azure region capacity, DNS reachability or provisioning;
review the consumer's live plan and validate private connectivity after deployment.
