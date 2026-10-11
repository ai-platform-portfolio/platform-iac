variable "project_id" {
  description = "Existing billed Google Cloud project supplied externally."
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Prefix for private inference endpoint resources."
  type        = string
}

variable "network_name" {
  description = "Dedicated custom-mode VPC name."
  type        = string
}

variable "region" {
  description = "Infrastructure region for subnet and regional PSC endpoint."
  type        = string
  validation {
    condition     = contains(var.allowed_regions, var.region)
    error_message = "The infrastructure region must be explicitly approved."
  }
}

variable "allowed_regions" {
  description = "Approved infrastructure regions; this does not establish model processing residency."
  type        = set(string)
  default     = ["europe-west2", "europe-west4"]
}

variable "subnet_cidr" {
  description = "Private endpoint subnet with no overlap with Azure or AWS."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr)) && try(tonumber(split("/", var.subnet_cidr)[1]) >= 16, false)
    error_message = "Supply a valid IPv4 subnet of /16 or smaller."
  }
}

variable "processing_location" {
  description = "Jurisdictional processing location used in both hostname and API resource path."
  type        = string
  validation {
    condition     = contains(var.allowed_processing_locations, var.processing_location)
    error_message = "Processing location must be explicitly approved; global is not allowed."
  }
}

variable "allowed_processing_locations" {
  description = "Approved jurisdictional locations; each model must independently support them."
  type        = set(string)
  default     = ["eu"]
  validation {
    condition     = length(var.allowed_processing_locations) > 0 && !contains(var.allowed_processing_locations, "global")
    error_message = "Global processing cannot be approved in this module."
  }
}

variable "models" {
  description = "Approved Gemini aliases and reviewed supported processing locations. No GPU/model deployment is required for managed inference."
  type = map(object({
    model_id             = string
    processing_locations = set(string)
  }))
  validation {
    condition = length(var.models) > 0 && alltrue([
      for model in var.models : startswith(model.model_id, "gemini-") && contains(model.processing_locations, var.processing_location)
    ])
    error_message = "Each Gemini model must have a reviewed approval for the configured processing location."
  }
}

variable "endpoint_access_type" {
  description = "REGIONAL restricts reachability; GLOBAL permits private clients in other VPC regions without changing model processing location."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.endpoint_access_type)
    error_message = "Endpoint access type must be REGIONAL or GLOBAL."
  }
}

variable "routing_mode" {
  description = "Dynamic routing scope for future private cross-cloud connectivity."
  type        = string
  default     = "REGIONAL"
}

variable "dns_ttl" {
  description = "Private inference DNS record TTL."
  type        = number
  default     = 300
}

variable "timeouts" {
  description = "Regional endpoint operation timeouts."
  type = object({
    create = optional(string, "20m")
    update = optional(string, "20m")
    delete = optional(string, "20m")
  })
  default = {}
}

variable "labels" {
  description = "Labels for owned inference resources."
  type        = map(string)
  default     = {}
}
