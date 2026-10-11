output "vnet_id" { value = azurerm_virtual_network.this.id }
output "subnet_ids" {
  value = { for key, subnet in azurerm_subnet.this : key => subnet.id }
  depends_on = [
    azurerm_subnet_network_security_group_association.this,
    azurerm_subnet_route_table_association.this,
  ]
}
output "private_dns_zone_ids" { value = { for key, zone in azurerm_private_dns_zone.this : key => zone.id } }

output "network_security_group_ids" {
  value = { for key, group in azurerm_network_security_group.this : key => group.id }
}

output "route_table_ids" {
  value = { for key, table in azurerm_route_table.this : key => table.id }
}
