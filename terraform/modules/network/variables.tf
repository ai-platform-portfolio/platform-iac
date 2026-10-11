variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name" { type = string }
variable "address_space" { type = list(string) }

variable "subnets" {
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    network_security_group_key        = optional(string)
    route_table_key                   = optional(string)
    private_endpoint_network_policies = optional(string, "Disabled")
    delegations = optional(map(object({
      service = string
      actions = list(string)
    })), {})
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], subnet.private_endpoint_network_policies)
    ])
    error_message = "Private endpoint network policies must be Disabled, Enabled, NetworkSecurityGroupEnabled or RouteTableEnabled."
  }
}

variable "private_dns_zones" { type = map(string) }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "network_security_groups" {
  description = "NSGs keyed by stable logical names; subnets select an optional key."
  type = map(object({
    name = string
    rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
  default = {}
}

variable "route_tables" {
  description = "Route tables keyed by stable logical names; no table or forced route is created by default."
  type = map(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  default = {}
}
