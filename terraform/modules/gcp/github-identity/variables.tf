variable "project_id" {
  description = "Existing billed Google project supplied externally."
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Prefix for the GitHub pool and deployment service accounts."
  type        = string
}

variable "github_subjects" {
  description = "Exact environment-specific OIDC subjects, including the organization's subject customization."
  type        = map(string)
  sensitive   = true
  validation {
    condition     = toset(keys(var.github_subjects)) == toset(["plan", "apply"])
    error_message = "Supply exactly plan and apply subjects."
  }
}

variable "repository_id" {
  description = "Immutable GitHub repository ID."
  type        = string
  sensitive   = true
}

variable "repository_owner_id" {
  description = "Immutable GitHub organization ID."
  type        = string
  sensitive   = true
}

variable "github_issuer" {
  description = "GitHub Actions OIDC issuer."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "apply_ref" {
  description = "Only this ref can use Apply credentials."
  type        = string
  default     = "refs/heads/main"
}

variable "services" {
  description = "APIs enabled and retained by the administrator bootstrap."
  type        = set(string)
  default = [
    "aiplatform.googleapis.com", "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com", "dns.googleapis.com", "iam.googleapis.com",
    "iamcredentials.googleapis.com", "networkconnectivity.googleapis.com",
    "serviceusage.googleapis.com", "sts.googleapis.com"
  ]
}

variable "plan_roles" {
  description = "Read-only network and DNS permissions for Plan."
  type        = set(string)
  default = [
    "roles/compute.viewer", "roles/dns.reader",
    "roles/networkconnectivity.regionalEndpointViewer", "roles/serviceusage.serviceUsageConsumer"
  ]
}

variable "apply_roles" {
  description = "Workload networking permissions; no project IAM, federation or service account administration."
  type        = set(string)
  default = [
    "roles/compute.networkAdmin", "roles/dns.admin",
    "roles/serviceusage.serviceUsageConsumer"
  ]
}
