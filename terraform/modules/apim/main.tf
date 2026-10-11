resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_api_management" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = var.integration_subnet_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  public_network_access_enabled = true

  # Azure requires public access during creation. The ordered AzAPI update
  # disables it after the private endpoint exists and owns this one property.
  lifecycle {
    ignore_changes = [public_network_access_enabled]
  }

  timeouts {
    create = "3h"
    update = "3h"
    delete = "3h"
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "${var.name}-gateway-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-gateway"
    private_connection_resource_id = azurerm_api_management.this.id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "gateway"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azapi_update_resource" "private_access" {
  type        = "Microsoft.ApiManagement/service@2024-05-01"
  resource_id = azurerm_api_management.this.id
  body = {
    properties = {
      publicNetworkAccess = "Disabled"
    }
  }

  timeouts {
    create = "3h"
    update = "3h"
  }

  depends_on = [azurerm_private_endpoint.this]
}
