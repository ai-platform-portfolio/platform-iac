output "providers" {
  value     = { for phase, provider in google_iam_workload_identity_pool_provider.github : phase => provider.name }
  sensitive = true
}

output "service_accounts" {
  value     = { for phase, account in google_service_account.deployment : phase => account.email }
  sensitive = true
}
