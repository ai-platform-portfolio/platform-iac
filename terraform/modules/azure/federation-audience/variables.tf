variable "name" {
  description = "Display name for the dedicated external-cloud token audience."
  type        = string
}

variable "principal_id" {
  description = "Existing shared managed identity object ID; no identity is created here."
  type        = string
  sensitive   = true
}

variable "app_role_id" {
  description = "Stable application role UUID, shared by the definition and assignment."
  type        = string
  default     = "f179797b-492c-4b74-89fb-c51ae46e8da4"
}

variable "app_role_value" {
  description = "Role claim required by the external federation provider."
  type        = string
  default     = "Federate.Workload"
}
