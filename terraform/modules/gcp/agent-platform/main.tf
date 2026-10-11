terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    google = { source = "hashicorp/google", version = ">= 8.6, < 9.0" }
  }
}

locals {
  hostname = "aiplatform.${var.processing_location}.rep.googleapis.com"
}

resource "google_compute_network" "this" {
  project                         = var.project_id
  name                            = var.network_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = var.routing_mode
}

resource "google_compute_subnetwork" "endpoints" {
  project       = var.project_id
  name          = "${var.name}-endpoints"
  region        = var.region
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.this.id
}

resource "google_compute_address" "inference" {
  project      = var.project_id
  name         = "${var.name}-inference"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.endpoints.id
  labels       = var.labels
}

resource "google_network_connectivity_regional_endpoint" "inference" {
  project           = var.project_id
  name              = "${var.name}-inference"
  location          = var.region
  target_google_api = local.hostname
  access_type       = var.endpoint_access_type
  address           = google_compute_address.inference.id
  network           = google_compute_network.this.id
  subnetwork        = google_compute_subnetwork.endpoints.id
  labels            = var.labels

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "google_dns_managed_zone" "inference" {
  project     = var.project_id
  name        = "${var.name}-inference"
  dns_name    = "${local.hostname}."
  description = "Private Agent Platform jurisdictional endpoint."
  visibility  = "private"
  labels      = var.labels
  private_visibility_config {
    networks {
      network_url = google_compute_network.this.id
    }
  }
}

resource "google_dns_record_set" "inference" {
  project      = var.project_id
  name         = google_dns_managed_zone.inference.dns_name
  managed_zone = google_dns_managed_zone.inference.name
  type         = "A"
  ttl          = var.dns_ttl
  rrdatas      = [google_compute_address.inference.address]
  depends_on   = [google_network_connectivity_regional_endpoint.inference]
}

resource "google_dns_policy" "hybrid" {
  project                   = var.project_id
  name                      = "${var.name}-hybrid"
  enable_inbound_forwarding = true
  networks {
    network_url = google_compute_network.this.id
  }
}
