terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.address_space
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "this" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.address_prefix
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "${var.name}-${each.key}" })
}
