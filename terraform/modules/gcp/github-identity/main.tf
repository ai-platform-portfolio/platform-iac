terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    google = { source = "hashicorp/google", version = ">= 8.6, < 9.0" }
  }
}

resource "google_project_service" "this" {
  for_each           = var.services
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.name}-github"
  display_name              = "${var.name} GitHub"
  depends_on                = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  for_each                           = nonsensitive(toset(keys(var.github_subjects)))
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = each.key
  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
  }
  attribute_condition = join(" && ", concat([
    "assertion.repository_id == '${var.repository_id}'",
    "assertion.repository_owner_id == '${var.repository_owner_id}'",
    "assertion.sub == '${var.github_subjects[each.key]}'"
  ], each.key == "apply" ? ["assertion.ref == '${var.apply_ref}'", "assertion.event_name != 'pull_request'"] : []))
  oidc {
    issuer_uri = var.github_issuer
  }
}

resource "google_service_account" "deployment" {
  for_each     = nonsensitive(toset(keys(var.github_subjects)))
  project      = var.project_id
  account_id   = "${var.name}-${each.key}"
  display_name = "${var.name} Terraform ${each.key}"
  depends_on   = [google_project_service.this]
}

resource "google_service_account_iam_member" "github" {
  for_each           = nonsensitive(toset(keys(var.github_subjects)))
  service_account_id = google_service_account.deployment[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/${var.github_subjects[each.key]}"
  depends_on         = [google_iam_workload_identity_pool_provider.github]
}

locals {
  deployment_roles = merge(
    { for role in var.plan_roles : "plan:${role}" => { phase = "plan", role = role } },
    { for role in var.apply_roles : "apply:${role}" => { phase = "apply", role = role } }
  )
}

resource "google_project_iam_member" "deployment" {
  for_each = local.deployment_roles
  project  = var.project_id
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.deployment[each.value.phase].email}"
}
