mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "000000000000" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
}

variables {
  name_prefix = "example-gateway"
  region      = "eu-west-2"
  github_subjects = {
    plan  = "repo:example/example:environment:central-plan"
    apply = "repo:example/example:environment:central-apply"
  }
  runtime_issuer_url = "https://sts.windows.net/00000000-0000-0000-0000-000000000001/"
  processing_regions = ["eu-west-2", "eu-west-1"]
  ownership_tag      = { key = "project", value = "example" }
}

run "separate_environment_trust_and_read_only_plan" {
  command = apply
  assert {
    condition     = jsondecode(aws_iam_role.deployment["plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == var.github_subjects.plan && jsondecode(aws_iam_role.deployment["apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == var.github_subjects.apply
    error_message = "Plan and Apply must trust only their exact environment subjects."
  }
  assert {
    condition     = alltrue(flatten([for statement in jsondecode(aws_iam_role_policy.deployment["plan"].policy).Statement : [for action in statement.Action : can(regex(":(Get|List|Describe)", action))]]))
    error_message = "The Plan role must not have create, update, delete or inference permissions."
  }
  assert {
    condition     = alltrue([for statement in jsondecode(aws_iam_role_policy.deployment["apply"].policy).Statement : alltrue([for action in flatten([statement.Action]) : !contains(["iam:PutRolePermissionsBoundary", "iam:DeleteRolePermissionsBoundary", "iam:AttachRolePolicy", "iam:CreatePolicyVersion"], action)])])
    error_message = "Apply must not remove runtime boundaries or mutate deployment policies."
  }
}

run "runtime_boundary_excludes_unapproved_processing" {
  command = plan
  assert {
    condition     = alltrue([for resource in jsondecode(aws_iam_policy.runtime_boundary.policy).Statement[0].Resource : can(regex("^arn:aws:bedrock:eu-west-[12]:", resource))])
    error_message = "The boundary must include only approved regional resources, excluding global and other regions."
  }
}

run "wildcard_subject_is_rejected" {
  command = plan
  variables {
    github_subjects = {
      plan  = "repo:example/*:environment:central-plan"
      apply = "repo:example/example:environment:central-apply"
    }
  }
  expect_failures = [var.github_subjects]
}
