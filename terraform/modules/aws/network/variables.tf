variable "name" {
  description = "VPC name."
  type        = string
}

variable "address_space" {
  description = "Private VPC IPv4 CIDR."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.address_space))
    error_message = "Supply a valid IPv4 CIDR."
  }
}

variable "subnets" {
  description = "Private subnets keyed by workload purpose and availability zone."
  type = map(object({
    address_prefix    = string
    availability_zone = string
  }))
}

variable "tags" {
  description = "Ownership tags for VPC and subnets."
  type        = map(string)
  default     = {}
}
