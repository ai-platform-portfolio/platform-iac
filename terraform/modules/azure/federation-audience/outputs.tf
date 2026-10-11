output "audience" {
  value     = azuread_application_identifier_uri.this.identifier_uri
  sensitive = true
}

output "issuer" {
  value     = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/"
  sensitive = true
}

output "tenant_id" {
  value     = data.azuread_client_config.current.tenant_id
  sensitive = true
}

output "role_value" {
  value = var.app_role_value
}
