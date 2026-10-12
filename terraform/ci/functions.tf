data "azurerm_storage_account" "functions" {
  name                = var.function_storage.name
  resource_group_name = var.function_storage.resource_group_name
}

module "functions" {
  for_each = var.function_apps
  source   = "../modules/azure/function-app"

  name                = each.value.name
  resource_group_name = var.deployment_identity.resource_group_name
  location            = var.deployment_identity.location
  subnet_id           = module.network.subnet_ids["functions"]
  storage = {
    id            = data.azurerm_storage_account.functions.id
    name          = data.azurerm_storage_account.functions.name
    blob_endpoint = data.azurerm_storage_account.functions.primary_blob_endpoint
  }
  queues                 = each.value.queues
  create_host_containers = each.value.create_host_containers
  app_settings = merge(each.value.settings, {
    FEDERATION_IDENTITY_ID = azurerm_user_assigned_identity.deployment["central-deployment"].id
    KEY_VAULT_URL          = "https://${var.function_vault.name}.vault.azure.net/"
  })
  role_assignments = {
    for name in each.value.secret_names : name => {
      scope = "${var.function_vault.id}/secrets/${name}"
      role  = "Key Vault Secrets User"
    }
  }
}

# Only read/create/update credentials on the central identity; no delete or RBAC writes.
resource "azurerm_role_definition" "onboarding" {
  name              = "ai-platform-repository-onboarding"
  scope             = azurerm_resource_group.deployment.id
  assignable_scopes = [azurerm_resource_group.deployment.id]
  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write",
    ]
  }
}
resource "azurerm_role_assignment" "onboarding" {
  for_each           = module.functions
  scope              = azurerm_user_assigned_identity.deployment["central-deployment"].id
  role_definition_id = azurerm_role_definition.onboarding.role_definition_resource_id
  principal_id       = each.value.principal_id
  principal_type     = "ServicePrincipal"
}
