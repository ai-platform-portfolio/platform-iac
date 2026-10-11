# Network module

Creates a resource group, VNet, map-driven subnets and private DNS zone links.
Optional `network_security_groups` and `route_tables` maps configure security
and routing in the same module. Empty maps create no extra resources, preserving
existing callers and resource addresses.

Each subnet can select `network_security_group_key` and `route_table_key`.
Keys refer to the corresponding top-level maps; omit either key for no association.
Rules and routes use stable map keys, so adding entries does not renumber resources.
Do not manage these subnet associations from another module or state.

```hcl
network_security_groups = {
  apim = {
    name = "example-apim-nsg"
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
  apim = {
    name                          = "example-apim-rt"
    bgp_route_propagation_enabled = true
    routes                        = {}
  }
}
subnets = {
  apim = {
    name                       = "apim"
    address_prefixes           = ["10.80.0.0/24"]
    network_security_group_key = "apim"
    route_table_key            = "apim"
    delegations = {
      apim = {
        service = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
```

Azure default NSG rules remain. Add explicit allow/deny rules to implement the
environment's egress policy. There is no forced-tunnel route by default. If a
route uses `VirtualAppliance`, supply `next_hop_in_ip_address`. BGP propagation
is configurable per table. Creating a table alone establishes no cross-cloud
connectivity.

`subnet_ids` depends on the selected associations and their rules/routes. Workload
modules consuming this output therefore wait until subnet configuration is ready.
`network_security_group_ids` and `route_table_ids` expose references for later wiring.

Private endpoint subnet policy is configurable through each subnet's
`private_endpoint_network_policies`. It defaults to `Disabled` to preserve
existing deployments. Use `NetworkSecurityGroupEnabled` to enforce the selected
NSG on private endpoints, `RouteTableEnabled` for UDR policy, or `Enabled` for
both. NSG attachment alone does not enforce rules on a PE while policy is disabled.

[Microsoft private endpoint network policies](https://learn.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy)
