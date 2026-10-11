mock_provider "azurerm" {}

variables {
  name                       = "example-foundry"
  resource_group_name        = "example-rg"
  location                   = "uksouth"
  private_endpoint_location  = "ukwest"
  managed_identity_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/shared"
  inference_principal_id     = "00000000-0000-0000-0000-000000000001"
  private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example/subnets/foundry"
  private_dns_zone_ids = [
    for zone in ["privatelink.openai.azure.com", "privatelink.cognitiveservices.azure.com", "privatelink.services.ai.azure.com"] :
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/privateDnsZones/${zone}"
  ]
  projects = { gateway = { display_name = "Gateway" } }
  deployments = {
    chat = {
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
      capacity      = 10
    }
  }
}

run "private_keyless_regional_inference" {
  command = plan
  assert {
    condition     = azurerm_cognitive_account_project.this["gateway"].location == var.location && contains(azurerm_cognitive_account_project.this["gateway"].identity[0].identity_ids, var.managed_identity_id)
    error_message = "Projects must use the Foundry account region and existing shared identity."
  }
  assert {
    condition     = !azurerm_cognitive_account.this.public_network_access_enabled && !azurerm_cognitive_account.this.local_auth_enabled && azurerm_cognitive_account.this.network_acls[0].bypass == "None"
    error_message = "Foundry must deny public and key-based access without trusted-service bypass."
  }
  assert {
    condition     = azurerm_cognitive_account.this.identity[0].type == "UserAssigned" && contains(azurerm_cognitive_account.this.identity[0].identity_ids, var.managed_identity_id) && azurerm_role_assignment.inference.principal_id == var.inference_principal_id && azurerm_role_assignment.inference.role_definition_name == "Cognitive Services OpenAI User"
    error_message = "The shared identity must receive account-scoped inference access."
  }
  assert {
    condition     = azurerm_private_endpoint.this.location == "ukwest" && azurerm_cognitive_account.this.location == "uksouth" && azurerm_cognitive_deployment.this["chat"].version_upgrade_option == "NoAutoUpgrade"
    error_message = "Endpoint placement and pinned model upgrades must remain independent of the model region."
  }
}

run "global_processing_is_not_implicitly_allowed" {
  command = plan
  variables {
    deployments = {
      chat = { model_name = "example", model_version = "1", capacity = 1, sku_name = "GlobalStandard" }
    }
  }
  expect_failures = [azurerm_cognitive_deployment.this["chat"]]
}

run "invalid_capacity_is_rejected" {
  command = plan
  variables {
    deployments = {
      chat = { model_name = "example", model_version = "1", capacity = 0 }
    }
  }
  expect_failures = [var.deployments]
}

run "incomplete_private_dns_is_rejected" {
  command = plan
  variables {
    private_dns_zone_ids = []
  }
  expect_failures = [var.private_dns_zone_ids]
}
