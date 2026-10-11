terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = var.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = var.private_dns_zones
  name                  = "${each.key}-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

locals {
  security_rules = merge([
    for group_key, group in var.network_security_groups : {
      for rule_key, rule in group.rules : "${group_key}/${rule_key}" => merge(rule, {
        group_key = group_key
        name      = rule_key
      })
    }
  ]...)

  routes = merge([
    for table_key, table in var.route_tables : {
      for route_key, route in table.routes : "${table_key}/${route_key}" => merge(route, {
        table_key = table_key
        name      = route_key
      })
    }
  ]...)
}

resource "azurerm_network_security_group" "this" {
  for_each            = var.network_security_groups
  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each                    = local.security_rules
  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this[each.value.group_key].name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.network_security_group_key != null
  }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.value.network_security_group_key].id
  depends_on                = [azurerm_network_security_rule.this]
}

resource "azurerm_route_table" "this" {
  for_each                      = var.route_tables
  name                          = each.value.name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = var.tags
}

resource "azurerm_route" "this" {
  for_each               = local.routes
  name                   = each.value.name
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = azurerm_route_table.this[each.value.table_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.route_table_key != null
  }
  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this[each.value.route_table_key].id
  depends_on     = [azurerm_route.this]
}
