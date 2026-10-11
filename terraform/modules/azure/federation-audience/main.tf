terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azuread = { source = "hashicorp/azuread", version = ">= 3.10, < 4.0" }
  }
}

data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  display_name            = var.name
  sign_in_audience        = "AzureADMyOrg"
  owners                  = [data.azuread_client_config.current.object_id]
  prevent_duplicate_names = true

  api {
    requested_access_token_version = 1
  }

  app_role {
    allowed_member_types = ["Application"]
    description          = "Exchange a managed identity token with the approved external cloud."
    display_name         = "Federate workload"
    enabled              = true
    id                   = var.app_role_id
    value                = var.app_role_value
  }

  lifecycle {
    ignore_changes = [identifier_uris]
  }
}

resource "azuread_application_identifier_uri" "this" {
  application_id = azuread_application.this.id
  identifier_uri = "api://${azuread_application.this.client_id}"
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_app_role_assignment" "workload" {
  app_role_id         = var.app_role_id
  principal_object_id = var.principal_id
  resource_object_id  = azuread_service_principal.this.object_id
}
