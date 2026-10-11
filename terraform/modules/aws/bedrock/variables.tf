variable "name" {
  description = "Prefix for endpoints and application inference profiles."
  type        = string
}

variable "region" {
  description = "Source region for endpoints and inference profiles."
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "Private VPC hosting the endpoints."
}

variable "endpoint_subnet_ids" {
  description = "Endpoint subnets, one per availability zone."
  type        = set(string)
  validation {
    condition     = length(var.endpoint_subnet_ids) >= 2
    error_message = "Provide endpoint subnets in at least two availability zones."
  }
}

variable "allowed_client_cidrs" {
  description = "Authorized gateway source CIDRs as seen after private transport; never a public wildcard."
  type        = set(string)
  validation {
    condition     = length(var.allowed_client_cidrs) > 0 && alltrue([for cidr in var.allowed_client_cidrs : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)])
    error_message = "Provide explicit IPv4 client CIDRs; /0 ingress is prohibited."
  }
}

variable "processing_regions" {
  description = "Explicitly reviewed inference processing regions. Live source-profile targets are checked against this set."
  type        = set(string)
  validation {
    condition     = contains(var.processing_regions, var.region)
    error_message = "The source region must be inside the approved processing boundary."
  }
}

variable "profiles" {
  description = "Model aliases and approved system-defined geographic inference profiles."
  type = map(object({
    source_profile_id = string
    description       = optional(string)
  }))
  validation {
    condition     = alltrue([for profile in var.profiles : anytrue([for prefix in var.allowed_profile_prefixes : startswith(profile.source_profile_id, prefix)]) && !startswith(profile.source_profile_id, "global.")])
    error_message = "Only explicitly approved geographic profile prefixes are allowed; global profiles are prohibited."
  }
}

variable "allowed_profile_prefixes" {
  description = "Approved geographic inference profile prefixes. Target-region checks also apply."
  type        = set(string)
  default     = ["eu."]
}

variable "runtime_role_arns" {
  description = "Externally supplied runtime role allowlist. Empty keeps both endpoint policies explicitly deny-all until federation is ready."
  type        = set(string)
  default     = []
  sensitive   = true
  validation {
    condition     = alltrue([for arn in var.runtime_role_arns : can(regex("^arn:[a-z-]+:iam::[0-9]{12}:role/[^*]+$", arn))])
    error_message = "Supply exact IAM role ARNs, without wildcard principals."
  }
}

variable "endpoint_services" {
  description = "Map-defined private runtime and federation endpoints."
  type        = map(string)
  default     = { runtime = "bedrock-runtime", sts = "sts" }
  validation {
    condition     = alltrue([for service in values(var.endpoint_services) : contains(["bedrock-runtime", "sts"], service)])
    error_message = "Endpoint policies are defined only for Bedrock Runtime and STS."
  }
}

variable "endpoint_port" {
  description = "HTTPS endpoint port."
  type        = number
  default     = 443
}

variable "inference_actions" {
  description = "Runtime invocation permissions for approved role and model resources."
  type        = set(string)
  default     = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
}

variable "timeouts" {
  description = "Inference profile operation timeouts."
  type        = object({ create = string, update = string, delete = string })
  default     = { create = "5m", update = "5m", delete = "5m" }
}

variable "tags" {
  description = "Ownership and cost attribution tags."
  type        = map(string)
  default     = {}
}
