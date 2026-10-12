module "network" {
  source = "../modules/azure/network"

  resource_group_name = var.network.resource_group_name
  location            = var.network.location
  name                = var.network.name
  address_space       = var.network.address_space
  subnets             = var.network.subnets
  private_dns_zones   = var.network.private_dns_zones
  tags                = var.network.tags
}

data "azurerm_subscription" "current" {}

locals {
  github_subjects = merge([
    for name, repo in var.github_repositories : {
      for phase, environment in { plan = repo.plan_environment, apply = repo.apply_environment } :
      "${name}-${phase}" => "repo:${repo.owner}@${repo.owner_id}/${repo.name}@${repo.repository_id}:environment:${environment}"
      if environment != null
    }
  ]...)
}

# Keep the identity and RBAC in Terraform; ops-shared owns GitHub credentials.
resource "azurerm_resource_group" "deployment" {
  name     = var.deployment_identity.resource_group_name
  location = var.deployment_identity.location
}

resource "azurerm_user_assigned_identity" "deployment" {
  for_each            = toset(["central-deployment"])
  name                = "${var.deployment_identity.name_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.deployment.name
  location            = var.deployment_identity.location
}

resource "azurerm_role_assignment" "deployment" {
  for_each             = var.deployment_identity.roles
  scope                = each.key == "state" ? var.state_container_scope : "${data.azurerm_subscription.current.id}${each.value.scope_suffix}"
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.deployment["central-deployment"].principal_id
  principal_type       = "ServicePrincipal"
}

moved {
  from = module.deployment_identity.azurerm_resource_group.this[0]
  to   = azurerm_resource_group.deployment
}
moved {
  from = module.deployment_identity.azurerm_user_assigned_identity.this
  to   = azurerm_user_assigned_identity.deployment
}
moved {
  from = module.deployment_identity.azurerm_role_assignment.this
  to   = azurerm_role_assignment.deployment
}
removed {
  from = module.deployment_identity.azurerm_federated_identity_credential.this
  lifecycle { destroy = false }
}
removed {
  from = module.deployment_identity.azurerm_federated_identity_credential.extra
  lifecycle { destroy = false }
}
