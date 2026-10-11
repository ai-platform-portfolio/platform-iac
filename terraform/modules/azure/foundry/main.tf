terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
  }
}

resource "azurerm_cognitive_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "AIServices"
  sku_name                      = var.sku_name
  custom_subdomain_name         = var.name
  project_management_enabled    = true
  public_network_access_enabled = false
  local_auth_enabled            = false
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "azurerm_cognitive_account_project" "this" {
  for_each             = var.projects
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location
  display_name         = each.value.display_name
  description          = each.value.description
  tags                 = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "${var.name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.private_endpoint_location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = var.name
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "foundry"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}

resource "azurerm_cognitive_deployment" "this" {
  for_each               = var.deployments
  name                   = each.key
  cognitive_account_id   = azurerm_cognitive_account.this.id
  version_upgrade_option = each.value.version_upgrade_option
  rai_policy_name        = each.value.rai_policy_name

  model {
    format  = each.value.format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = contains(var.allowed_deployment_skus, each.value.sku_name)
      error_message = "The deployment SKU is outside the approved processing scope."
    }
  }
}

resource "azurerm_role_assignment" "inference" {
  scope                            = azurerm_cognitive_account.this.id
  role_definition_name             = var.inference_role_name
  principal_id                     = var.inference_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
