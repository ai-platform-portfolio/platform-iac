variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" {
  type    = string
  default = ""
}
variable "oidc_issuer_url" {
  type    = string
  default = null

  validation {
    condition     = !anytrue([for workload in values(var.workloads) : workload.federation_enabled]) || try(trimspace(var.oidc_issuer_url) != "", false)
    error_message = "An OIDC issuer is required when any workload enables federation."
  }
}

# Caller-defined identities; disable federation for shared Azure resources.
variable "workloads" {
  description = "Map of identities with optional OIDC federation. Set federation_enabled = false for a shared Azure resource identity."
  type = map(object({
    federation_enabled       = optional(bool, true)
    namespace                = optional(string)
    sa_name                  = optional(string)
    federated_subject        = optional(string)
    extra_federated_subjects = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for workload in values(var.workloads) : !workload.federation_enabled ? true : workload.federated_subject != null ?
      trimspace(workload.federated_subject) != "" :
      try(trimspace(workload.namespace) != "" && trimspace(workload.sa_name) != "", false)
    ])
    error_message = "Each federated workload needs a federated_subject or both namespace and sa_name."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_resource_group" {
  description = "Create the identity resource group when it is owned by this deployment."
  type        = bool
  default     = false
}

variable "role_assignments" {
  type = map(object({
    workload             = string
    scope                = string
    role_definition_name = string
  }))
  default = {}
}
