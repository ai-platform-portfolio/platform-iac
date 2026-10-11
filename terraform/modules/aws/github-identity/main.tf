terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  iam_prefix    = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}"
  ec2_prefix    = "arn:${data.aws_partition.current.partition}:ec2:${var.region}:${data.aws_caller_identity.current.account_id}"
  runtime_roles = "${local.iam_prefix}:role/${var.name_prefix}/runtime/*"
  regional_model_resources = flatten([
    for region in var.processing_regions : [
      "arn:${data.aws_partition.current.partition}:bedrock:${region}::foundation-model/*",
      "arn:${data.aws_partition.current.partition}:bedrock:${region}:${data.aws_caller_identity.current.account_id}:inference-profile/*",
      "arn:${data.aws_partition.current.partition}:bedrock:${region}:${data.aws_caller_identity.current.account_id}:application-inference-profile/*"
    ]
  ])
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = var.github_issuer_url
  client_id_list = [var.github_audience]
  tags           = var.tags
}

resource "aws_iam_policy" "runtime_boundary" {
  name = "${var.name_prefix}-runtime-boundary"
  path = "/${var.name_prefix}/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = local.regional_model_resources
    }]
  })
  tags = var.tags
}

resource "aws_iam_role" "deployment" {
  for_each             = toset(["plan", "apply"])
  name                 = "${var.name_prefix}-${each.key}"
  path                 = "/${var.name_prefix}/ci/"
  max_session_duration = var.max_session_duration
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = { StringEquals = {
        "${trimprefix(var.github_issuer_url, "https://")}:aud" = var.github_audience
        "${trimprefix(var.github_issuer_url, "https://")}:sub" = var.github_subjects[each.key]
      } }
    }]
  })
  tags = var.tags
}

locals {
  read_statements = [
    { Effect = "Allow", Action = var.ec2_read_actions, Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region } } },
    { Effect = "Allow", Action = var.bedrock_read_actions, Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region } } },
    { Effect = "Allow", Action = var.iam_read_actions, Resource = ["${local.iam_prefix}:role/${var.name_prefix}/*", "${local.iam_prefix}:oidc-provider/*", aws_iam_policy.runtime_boundary.arn] }
  ]
  apply_statements = concat(local.read_statements, [
    for action, resource_type in var.ec2_create_actions :
    { Effect = "Allow", Action = action, Resource = "${local.ec2_prefix}:${resource_type}/*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region, "aws:RequestTag/${var.ownership_tag.key}" = var.ownership_tag.value } } }
    ], [
    { Effect = "Allow", Action = var.ec2_dependency_create_actions, Resource = [for resource_type in var.ec2_dependency_resource_types : "${local.ec2_prefix}:${resource_type}/*"], Condition = { StringEquals = { "aws:RequestedRegion" = var.region, "ec2:ResourceTag/${var.ownership_tag.key}" = var.ownership_tag.value } } },
    { Effect = "Allow", Action = var.ec2_update_actions, Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region, "ec2:ResourceTag/${var.ownership_tag.key}" = var.ownership_tag.value } } },
    { Effect = "Allow", Action = "ec2:CreateTags", Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region }, StringLike = { "ec2:CreateAction" = var.ec2_create_actions_names } } },
    { Effect = "Allow", Action = "iam:CreateRole", Resource = local.runtime_roles, Condition = { StringEquals = { "iam:PermissionsBoundary" = aws_iam_policy.runtime_boundary.arn } } },
    { Effect = "Allow", Action = var.iam_runtime_update_actions, Resource = local.runtime_roles },
    { Effect = "Allow", Action = ["iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider", "iam:AddClientIDToOpenIDConnectProvider", "iam:RemoveClientIDFromOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint", "iam:TagOpenIDConnectProvider", "iam:UntagOpenIDConnectProvider"], Resource = "${local.iam_prefix}:oidc-provider/${trimprefix(trimsuffix(var.runtime_issuer_url, "/"), "https://")}" },
    { Effect = "Allow", Action = ["bedrock:CreateInferenceProfile", "bedrock:TagResource"], Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region, "aws:RequestTag/${var.ownership_tag.key}" = var.ownership_tag.value } } },
    { Effect = "Allow", Action = ["bedrock:DeleteInferenceProfile", "bedrock:UntagResource"], Resource = "*", Condition = { StringEquals = { "aws:RequestedRegion" = var.region, "aws:ResourceTag/${var.ownership_tag.key}" = var.ownership_tag.value } } }
  ])
}

resource "aws_iam_role_policy" "deployment" {
  for_each = toset(["plan", "apply"])
  name     = "${var.name_prefix}-deployment"
  role     = aws_iam_role.deployment[each.key].id
  policy = each.key == "plan" ? jsonencode({
    Version   = "2012-10-17"
    Statement = local.read_statements
    }) : jsonencode({
    Version   = "2012-10-17"
    Statement = local.apply_statements
  })
}
