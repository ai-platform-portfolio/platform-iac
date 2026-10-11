mock_provider "azurerm" {}

variables {
  resource_group_name = "example-rg"
  location            = "ukwest"
  name                = "example-vnet"
  address_space       = ["10.80.0.0/16"]
  subnets = {
    gateway = {
      name             = "gateway"
      address_prefixes = ["10.80.0.0/24"]
    }
  }
  private_dns_zones = {}
}

run "existing_callers_remain_unchanged" {
  command = plan

  assert {
    condition = (
      length(azurerm_network_security_group.this) == 0 &&
      length(azurerm_route_table.this) == 0 &&
      length(azurerm_subnet_network_security_group_association.this) == 0 &&
      length(azurerm_subnet_route_table_association.this) == 0
    )
    error_message = "Existing callers must not acquire an NSG, route table or association."
  }
}

run "subnets_select_security_and_routing_by_key" {
  command = plan

  variables {
    subnets = {
      gateway = {
        name                       = "gateway"
        address_prefixes           = ["10.80.0.0/24"]
        network_security_group_key = "gateway"
        route_table_key            = "egress"
      }
      private_endpoints = {
        name             = "private-endpoints"
        address_prefixes = ["10.80.4.0/24"]
      }
    }
    network_security_groups = {
      gateway = {
        name = "example-gateway-nsg"
        rules = {
          allow-key-vault = {
            priority                   = 100
            direction                  = "Outbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            destination_port_range     = "443"
            source_address_prefix      = "VirtualNetwork"
            destination_address_prefix = "AzureKeyVault"
          }
        }
      }
    }
    route_tables = {
      egress = {
        name                          = "example-egress-rt"
        bgp_route_propagation_enabled = false
        routes = {
          inspection = {
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.80.8.4"
          }
        }
      }
    }
  }

  assert {
    condition = (
      keys(azurerm_subnet_network_security_group_association.this) == ["gateway"] &&
      keys(azurerm_subnet_route_table_association.this) == ["gateway"]
    )
    error_message = "Only the selected subnet may receive the NSG and route table."
  }
  assert {
    condition = (
      azurerm_route.this["egress/inspection"].next_hop_in_ip_address == "10.80.8.4" &&
      azurerm_route_table.this["egress"].bgp_route_propagation_enabled == false
    )
    error_message = "Custom next-hop and BGP propagation settings must reach the route table."
  }
}
