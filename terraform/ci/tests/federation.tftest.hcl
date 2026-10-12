mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  state_container_scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test/blobServices/default/containers/state"
  function_storage = {
    name                = "fixturestorage"
    resource_group_name = "fixture"
  }
  function_vault = {
    name = "fixture-vault"
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fixture/providers/Microsoft.KeyVault/vaults/fixture-vault"
  }
  function_apps = {}
}

run "github_subject_matches_observed_repository_claim" {
  command = plan

  assert {
    condition = local.github_subjects == {
      ops-shared-plan    = "repo:ai-platform-portfolio@334196300/ops-shared@1389842744:environment:central-plan"
      ops-shared-apply   = "repo:ai-platform-portfolio@334196300/ops-shared@1389842744:environment:central-apply"
      platform-iac-plan  = "repo:ai-platform-portfolio@334196300/platform-iac@1389557192:environment:central-plan"
      platform-iac-apply = "repo:ai-platform-portfolio@334196300/platform-iac@1389557192:environment:central-apply"
    }
    error_message = "Only the two infrastructure repositories may plan the central estate; every other repository is apply-only."
  }
}

run "another_repository_reuses_the_identity" {
  command = plan

  variables {
    github_repositories = {
      platform-iac = {
        owner = "example", owner_id = "123", name = "platform-iac", repository_id = "456", plan_environment = "central-plan", apply_environment = "central-apply"
      }
      workload = {
        owner = "example", owner_id = "123", name = "workload", repository_id = "789", plan_environment = "plan", apply_environment = "deploy"
      }
    }
  }

  assert {
    condition     = length(local.github_subjects) == 4 && length(azurerm_user_assigned_identity.deployment) == 1 && local.github_subjects["workload-plan"] == "repo:example@123/workload@789:environment:plan" && local.github_subjects["workload-apply"] == "repo:example@123/workload@789:environment:deploy"
    error_message = "Adding a repository must add exactly two subjects without adding another managed identity."
  }
}
