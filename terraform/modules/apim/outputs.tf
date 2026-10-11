output "id" {
  description = "API Management resource ID, ready for private gateway use."
  value       = azurerm_api_management.this.id
  depends_on  = [azapi_update_resource.private_access]
}

output "gateway_url" {
  description = "Gateway URL; clients must resolve its private endpoint through DNS."
  value       = azurerm_api_management.this.gateway_url
  depends_on  = [azapi_update_resource.private_access]
}

output "managed_identity_id" {
  description = "User-assigned identity resource ID for backend policy authentication."
  value       = azurerm_user_assigned_identity.this.id
}

output "managed_identity_client_id" {
  description = "Identity client ID for APIM authentication-managed-identity policies."
  value       = azurerm_user_assigned_identity.this.client_id
  sensitive   = true
}

output "managed_identity_principal_id" {
  description = "Identity principal for scoped backend role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
  sensitive   = true
}

output "private_endpoint_id" {
  description = "Inbound gateway private endpoint resource ID."
  value       = azurerm_private_endpoint.this.id
}
