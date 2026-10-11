terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

data "aws_bedrock_inference_profile" "source" {
  for_each             = var.profiles
  region               = var.region
  inference_profile_id = each.value.source_profile_id
}

resource "aws_bedrock_inference_profile" "this" {
  for_each    = var.profiles
  region      = var.region
  name        = "${var.name}-${each.key}"
  description = each.value.description
  tags        = var.tags

  model_source {
    copy_from = data.aws_bedrock_inference_profile.source[each.key].inference_profile_arn
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition = (
        data.aws_bedrock_inference_profile.source[each.key].status == "ACTIVE" &&
        data.aws_bedrock_inference_profile.source[each.key].type == "SYSTEM_DEFINED" &&
        length(data.aws_bedrock_inference_profile.source[each.key].models) > 0 &&
        alltrue([for model in data.aws_bedrock_inference_profile.source[each.key].models :
          contains(var.processing_regions, split(":", model.model_arn)[3])
        ])
      )
      error_message = "Use an active system profile whose entire target model list stays inside the approved processing regions."
    }
  }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints"
  description = "HTTPS from approved gateway networks to private AWS inference endpoints."
  vpc_id      = var.vpc_id
  egress      = []
  tags        = var.tags

  dynamic "ingress" {
    for_each = var.allowed_client_cidrs
    content {
      from_port   = var.endpoint_port
      to_port     = var.endpoint_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
}

locals {
  inference_resources = distinct(concat(
    [for profile in aws_bedrock_inference_profile.this : profile.arn],
    [for profile in data.aws_bedrock_inference_profile.source : profile.inference_profile_arn],
    flatten([for profile in data.aws_bedrock_inference_profile.source : [for model in profile.models : model.model_arn]])
  ))
  closed_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Deny", Principal = "*", Action = "*", Resource = "*" }]
  })
  inference_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = var.inference_actions
      Resource  = local.inference_resources
      Condition = { ArnEquals = { "aws:PrincipalArn" = var.runtime_role_arns } }
    }]
  })
  sts_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Resource  = var.runtime_role_arns
    }]
  })
}

resource "aws_vpc_endpoint" "this" {
  for_each            = var.endpoint_services
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  tags                = merge(var.tags, { Name = "${var.name}-${each.key}" })
  policy = length(var.runtime_role_arns) == 0 ? local.closed_policy : (
    each.value == "sts" ? local.sts_policy : local.inference_policy
  )
}
