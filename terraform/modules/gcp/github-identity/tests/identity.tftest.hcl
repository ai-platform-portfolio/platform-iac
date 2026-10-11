mock_provider "google" {}

variables {
  project_id          = "example-project"
  name                = "test-gateway"
  repository_id       = "123456"
  repository_owner_id = "654321"
  github_subjects = {
    plan  = "repo:example/gateway:environment:central-plan"
    apply = "repo:example/gateway:environment:central-apply"
  }
}

run "separate_deployment_permissions" {
  command = plan
  assert {
    condition     = strcontains(google_iam_workload_identity_pool_provider.github["apply"].attribute_condition, "assertion.ref == 'refs/heads/main'") && strcontains(google_iam_workload_identity_pool_provider.github["apply"].attribute_condition, "assertion.event_name != 'pull_request'")
    error_message = "Apply must require main and reject PR events."
  }
  assert {
    condition     = strcontains(google_iam_workload_identity_pool_provider.github["plan"].attribute_condition, "assertion.repository_id == '123456'") && strcontains(google_iam_workload_identity_pool_provider.github["plan"].attribute_condition, "assertion.repository_owner_id == '654321'")
    error_message = "Trust must restrict immutable repository and organization IDs."
  }
  assert {
    condition     = !contains(var.apply_roles, "roles/owner") && !contains(var.apply_roles, "roles/iam.securityAdmin") && !contains(var.apply_roles, "roles/editor")
    error_message = "Workload Apply must not administer its own IAM."
  }
}
