output "network_id" {
  value     = google_compute_network.this.id
  sensitive = true
}

output "subnet_id" {
  value     = google_compute_subnetwork.endpoints.id
  sensitive = true
}

output "private_endpoint" {
  value = {
    id       = google_network_connectivity_regional_endpoint.inference.id
    hostname = local.hostname
    address  = google_compute_address.inference.address
  }
  sensitive = true
}

output "backends" {
  value = {
    for alias, model in var.models : alias => {
      model_id            = "google/${model.model_id}"
      processing_location = var.processing_location
      base_url            = "https://${local.hostname}/v1beta1/projects/${var.project_id}/locations/${var.processing_location}/endpoints/openapi"
    }
  }
  sensitive = true
}
