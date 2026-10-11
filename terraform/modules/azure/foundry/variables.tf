variable "name" {
  description = "Foundry account name and unique Entra-enabled custom subdomain."
  type        = string
}

variable "resource_group_name" {
  description = "Existing environment resource group."
  type        = string
}

variable "location" {
  description = "Foundry resource and regional inference location."
  type        = string
}

variable "sku_name" {
  description = "Foundry account SKU. Model deployment capacity is configured separately."
  type        = string
  default     = "S0"
}

variable "managed_identity_id" {
  description = "Existing shared user-assigned identity attached to the Foundry account."
  type        = string
}

variable "inference_principal_id" {
  description = "Existing managed identity principal authorized for inference, supplied by the caller."
  type        = string
  sensitive   = true
}

variable "inference_role_name" {
  description = "Account-scoped inference role, without model deployment permissions."
  type        = string
  default     = "Cognitive Services OpenAI User"
}

variable "private_endpoint_location" {
  description = "Region of the private endpoint VNet; may differ from the Foundry account region."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Existing private endpoint subnet. Its NSG must permit approved clients."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Existing private DNS zones for services.ai.azure.com, openai.azure.com and cognitiveservices.azure.com."
  type        = list(string)

  validation {
    condition = alltrue([
      for zone in ["privatelink.openai.azure.com", "privatelink.cognitiveservices.azure.com", "privatelink.services.ai.azure.com"] :
      anytrue([for id in var.private_dns_zone_ids : endswith(lower(id), "/${zone}")])
    ])
    error_message = "All three Foundry private DNS zones are required."
  }
}

variable "allowed_deployment_skus" {
  description = "Explicitly approved processing scope. Standard remains within the resource geography; global and data-zone deployments require a reviewed override."
  type        = set(string)
  default     = ["Standard"]
}

variable "projects" {
  description = "Foundry projects keyed by stable name, reusing the environment identity."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "deployments" {
  description = "Model deployments keyed by stable deployment name; versions and capacity are explicit."
  type = map(object({
    format                 = optional(string, "OpenAI")
    model_name             = string
    model_version          = string
    sku_name               = optional(string, "Standard")
    capacity               = number
    version_upgrade_option = optional(string, "NoAutoUpgrade")
    rai_policy_name        = optional(string, "Microsoft.DefaultV2")
  }))
  default = {}

  validation {
    condition = alltrue([
      for deployment in values(var.deployments) :
      deployment.capacity >= 1 && floor(deployment.capacity) == deployment.capacity &&
      contains(["NoAutoUpgrade", "OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"], deployment.version_upgrade_option)
    ])
    error_message = "Deployment capacity must be a positive integer and the version upgrade option must be supported."
  }
}

variable "timeouts" {
  description = "Foundry account and model deployment operation timeouts."
  type = object({
    create = optional(string, "1h")
    update = optional(string, "1h")
    delete = optional(string, "1h")
  })
  default = {}
}

variable "tags" {
  description = "Environment ownership and cost allocation tags."
  type        = map(string)
  default     = {}
}
