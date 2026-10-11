mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000002"
      tenant_id = "00000000-0000-0000-0000-000000000003"
    }
  }
}

variables {
  name         = "test-google-federation"
  principal_id = "00000000-0000-0000-0000-000000000001"
}

run "dedicated_managed_identity_audience" {
  command = plan
  assert {
    condition     = azuread_service_principal.this.app_role_assignment_required && azuread_application.this.sign_in_audience == "AzureADMyOrg" && azuread_application.this.api[0].requested_access_token_version == 1
    error_message = "Use a single-tenant v1 token audience restricted by app-role assignment."
  }
  assert {
    condition     = azuread_app_role_assignment.workload.principal_object_id == var.principal_id
    error_message = "Only the existing shared managed identity receives the role."
  }
}
