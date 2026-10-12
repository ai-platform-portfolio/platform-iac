output "name" { value = azurerm_function_app_flex_consumption.this.name }
output "hostname" {
  value     = azurerm_function_app_flex_consumption.this.default_hostname
  sensitive = true
}

output "principal_id" { value = azurerm_user_assigned_identity.this.principal_id }
