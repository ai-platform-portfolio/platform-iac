mock_provider "aws" {
  mock_data "aws_bedrock_inference_profile" {
    defaults = {
      inference_profile_arn = "arn:aws:bedrock:eu-west-2:000000000000:inference-profile/eu.example"
      status                = "ACTIVE"
      type                  = "SYSTEM_DEFINED"
      models = [
        { model_arn = "arn:aws:bedrock:eu-west-2::foundation-model/example" },
        { model_arn = "arn:aws:bedrock:eu-west-1::foundation-model/example" },
      ]
    }
  }

  mock_resource "aws_bedrock_inference_profile" {
    defaults = {
      arn = "arn:aws:bedrock:eu-west-2:000000000000:application-inference-profile/example"
    }
  }
}

variables {
  name                 = "example"
  region               = "eu-west-2"
  vpc_id               = "vpc-00000000000000000"
  endpoint_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
  allowed_client_cidrs = ["10.60.0.0/24"]
  processing_regions   = ["eu-west-2", "eu-west-1"]
  profiles             = { claude = { source_profile_id = "eu.example" } }
}

run "foundation_is_closed_until_federation" {
  command = plan
  assert {
    condition     = alltrue([for endpoint in aws_vpc_endpoint.this : jsondecode(endpoint.policy).Statement[0].Effect == "Deny" && jsondecode(endpoint.policy).Statement[0].Action == "*"])
    error_message = "Unconfigured federation must never create an open endpoint policy."
  }
  assert {
    condition     = length(aws_security_group.endpoints.egress) == 0 && alltrue([for rule in aws_security_group.endpoints.ingress : rule.from_port == 443 && rule.to_port == 443 && toset(rule.cidr_blocks) == toset(["10.60.0.0/24"])])
    error_message = "Only approved gateway HTTPS ingress and stateful replies are allowed."
  }
}

run "profile_target_drift_outside_boundary_is_rejected" {
  command = plan
  override_data {
    target = data.aws_bedrock_inference_profile.source["claude"]
    values = {
      models = [{ model_arn = "arn:aws:bedrock:us-east-1::foundation-model/example" }]
    }
  }
  expect_failures = [aws_bedrock_inference_profile.this["claude"]]
}

run "global_profiles_are_rejected" {
  command = plan
  variables {
    profiles = { claude = { source_profile_id = "global.example" } }
  }
  expect_failures = [var.profiles]
}

run "public_wildcard_ingress_is_rejected" {
  command = plan
  variables {
    allowed_client_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.allowed_client_cidrs]
}

run "invalid_description_is_rejected_before_apply" {
  command = plan
  variables {
    profiles = { claude = { source_profile_id = "eu.example", description = "UK/EU processing" } }
  }
  expect_failures = [var.profiles]
}

run "invalid_generated_name_is_rejected_before_apply" {
  command = plan
  variables {
    profiles = { "claude.v1" = { source_profile_id = "eu.example" } }
  }
  expect_failures = [var.profiles]
}

run "federated_policy_is_scoped_to_role_and_models" {
  command = apply
  variables {
    runtime_role_arns = ["arn:aws:iam::000000000000:role/example/runtime/apim"]
  }
  assert {
    condition     = toset(jsondecode(aws_vpc_endpoint.this["runtime"].policy).Statement[0].Condition.ArnEquals["aws:PrincipalArn"]) == var.runtime_role_arns && !contains(jsondecode(aws_vpc_endpoint.this["runtime"].policy).Statement[0].Resource, "*") && contains(jsondecode(aws_vpc_endpoint.this["runtime"].policy).Statement[0].Resource, "arn:aws:bedrock:eu-west-1::foundation-model/example")
    error_message = "Bedrock endpoint access must name the exact role, profile and every approved target model."
  }
  assert {
    condition     = jsondecode(aws_vpc_endpoint.this["sts"].policy).Statement[0].Action == "sts:AssumeRoleWithWebIdentity" && toset(jsondecode(aws_vpc_endpoint.this["sts"].policy).Statement[0].Resource) == var.runtime_role_arns
    error_message = "STS endpoint access must only exchange tokens for the approved runtime roles."
  }
}
