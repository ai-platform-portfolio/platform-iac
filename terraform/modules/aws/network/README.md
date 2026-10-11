# Private AWS network

Creates a DNS-enabled VPC and map-defined private subnets. It creates no internet
gateway, NAT gateway or public IP assignments. Subnets initially use the VPC's
local-only main route table. Transport routes and DNS forwarding are separate
dependencies when connecting other clouds. Endpoints use explicit workload security
groups rather than the default VPC security group.
