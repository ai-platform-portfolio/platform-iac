mock_provider "google" {}

variables {
  project_id          = "example-project"
  name                = "test-gemini"
  network_name        = "test-network"
  region              = "europe-west4"
  subnet_cidr         = "10.80.0.0/24"
  processing_location = "eu"
  models = {
    flash = { model_id = "gemini-3.8-flash", processing_locations = ["eu"] }
  }
}

run "jurisdictional_private_endpoint" {
  command = plan
  assert {
    condition     = google_network_connectivity_regional_endpoint.inference.target_google_api == "aiplatform.eu.rep.googleapis.com" && google_compute_network.this.delete_default_routes_on_create
    error_message = "Use the jurisdictional PSC endpoint and remove default internet routes."
  }
  assert {
    condition     = google_dns_managed_zone.inference.visibility == "private" && endswith(output.backends.flash.base_url, "/locations/eu/endpoints/openapi")
    error_message = "DNS must be private and the API path must match EU processing."
  }
}

run "reject_global_processing" {
  command = plan
  variables {
    processing_location = "global"
    models = {
      flash = { model_id = "gemini-3.8-flash", processing_locations = ["global"] }
    }
  }
  expect_failures = [var.processing_location]
}

run "reject_unapproved_model_location" {
  command = plan
  variables {
    models = {
      flash = { model_id = "gemini-3.8-flash", processing_locations = ["us"] }
    }
  }
  expect_failures = [var.models]
}
