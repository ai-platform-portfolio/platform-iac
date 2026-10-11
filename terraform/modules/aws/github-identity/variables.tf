variable "name_prefix" {
  description = "Deployment identity names and IAM namespace for runtime roles."
  type        = string
}

variable "region" {
  description = "Region in which the Apply role may manage tagged network and Bedrock resources."
  type        = string
}

variable "github_subjects" {
  description = "Exact GitHub-issued subjects for the distinct plan and apply environments, supplied externally."
  type        = object({ plan = string, apply = string })
  sensitive   = true
  validation {
    condition     = var.github_subjects.plan != var.github_subjects.apply && alltrue([for subject in values(var.github_subjects) : startswith(subject, "repo:") && strcontains(subject, ":environment:") && !strcontains(subject, "*")])
    error_message = "Supply distinct exact repository/environment subjects; wildcard trust is prohibited."
  }
}

variable "github_issuer_url" {
  description = "GitHub Actions OIDC issuer."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_audience" {
  description = "AWS STS audience requested by the workflow."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "runtime_issuer_url" {
  description = "Exact Entra runtime federation issuer, supplied externally; limits which IAM provider Apply may manage."
  type        = string
  sensitive   = true
}

variable "processing_regions" {
  description = "Reviewed model processing regions enforced by the runtime role permissions boundary."
  type        = set(string)
  validation {
    condition     = length(var.processing_regions) > 0 && alltrue([for region in var.processing_regions : can(regex("^[a-z]{2}-[a-z]+-[1-9]$", region))])
    error_message = "Supply explicit valid regions; global inference is not permitted by the boundary."
  }
}

variable "ownership_tag" {
  description = "Tag that limits network and inference-profile mutations to this workload."
  type        = object({ key = string, value = string })
}

variable "tags" {
  description = "Ownership tags for bootstrap identities and policies."
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum duration of deployment role sessions in seconds."
  type        = number
  default     = 3600
}

variable "ec2_read_actions" {
  description = "Network metadata permissions for refresh and planning."
  type        = set(string)
  default     = ["ec2:DescribeVpcs", "ec2:DescribeVpcAttribute", "ec2:DescribeSubnets", "ec2:DescribeAvailabilityZones", "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules", "ec2:DescribeVpcEndpoints", "ec2:DescribeNetworkInterfaces", "ec2:DescribeTags", "ec2:DescribePrefixLists", "ec2:DescribeRouteTables"]
}

variable "bedrock_read_actions" {
  description = "Bedrock model and profile metadata permissions; excludes invocation and content logs."
  type        = set(string)
  default     = ["bedrock:GetInferenceProfile", "bedrock:ListInferenceProfiles", "bedrock:GetFoundationModel", "bedrock:ListFoundationModels", "bedrock:ListTagsForResource"]
}

variable "iam_read_actions" {
  description = "Metadata permissions for this namespace's runtime roles and providers."
  type        = set(string)
  default     = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:GetOpenIDConnectProvider", "iam:GetPolicy", "iam:GetPolicyVersion"]
}

variable "ec2_create_actions" {
  description = "Tagged network resources Apply may create."
  type        = set(string)
  default     = ["ec2:CreateVpc", "ec2:CreateSubnet", "ec2:CreateSecurityGroup", "ec2:CreateVpcEndpoint"]
}

variable "ec2_create_actions_names" {
  description = "EC2 operations permitted to tag new resources during creation."
  type        = set(string)
  default     = ["CreateVpc", "CreateSubnet", "CreateSecurityGroup", "CreateVpcEndpoint", "AuthorizeSecurityGroupIngress", "AuthorizeSecurityGroupEgress"]
}

variable "ec2_update_actions" {
  description = "Operations constrained to network resources bearing the ownership tag."
  type        = set(string)
  default     = ["ec2:ModifyVpcAttribute", "ec2:DeleteVpc", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute", "ec2:DeleteSecurityGroup", "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress", "ec2:ModifySecurityGroupRules", "ec2:ModifyVpcEndpoint", "ec2:DeleteVpcEndpoints", "ec2:CreateTags", "ec2:DeleteTags"]
}

variable "iam_runtime_update_actions" {
  description = "Manage runtime roles only; cannot change CI roles or remove/edit their inference boundary."
  type        = set(string)
  default     = ["iam:DeleteRole", "iam:UpdateAssumeRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:TagRole", "iam:UntagRole", "iam:UpdateRole", "iam:UpdateRoleDescription"]
}
