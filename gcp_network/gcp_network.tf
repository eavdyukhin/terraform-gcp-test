# Define the module inputs
variable "project_id" {
  description = "Google Cloud Project ID"
}

variable "region" {
  description = "Google Cloud Region"
}

variable "zone" {
  description = "Google Cloud Zone"
}

variable "vpc_network_name" {
  description = "Name of VPC Network"
}

variable "vpc_subnetwork_name" {
  description = "Name of VPC Subnetwork"
}

variable "vpc_subnetwork_cidr" {
  description = "CIDR Range for VPC Subnetwork"
}

variable "firewall_ssh_source_ranges" {
  description = "Source ranges for SSH firewall rule"
  type = list(string)
}

variable "firewall_http_source_ranges" {
  description = "Source ranges for HTTP firewall rule"
  type = list(string)
}

variable "firewall_https_source_ranges" {
  description = "Source ranges for HTTPS firewall rule"
  type = list(string)
}

variable "gce_instance_name" {
  description = "Name of GCE Instance"
}

variable "gce_instance_machine_type" {
  description = "Machine Type for GCE Instance"
}

variable "service_account_name" {
  description = "Name of Service Account"
}

variable "service_account_roles" {
  description = "List of roles to be granted to the Service Account"
  type = set(string)
}

# Create the VPC network
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network_name
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

# Create the VPC subnetwork
resource "google_compute_subnetwork" "vpc_subnetwork" {
  project                 = var.project_id
  name                    = var.vpc_subnetwork_name
  region                  = var.region
  network                 = google_compute_network.vpc_network.self_link
  ip_cidr_range           = var.vpc_subnetwork_cidr
}

# Create the external IP address
resource "google_compute_address" "external_ip" {
  name                    = "external-ip"
  region                  = var.region
  project                 = var.project_id
}

# Create the SSH firewall rule
resource "google_compute_firewall" "ssh_firewall_rule" {
  project                 = var.project_id
  name                    = "ssh-firewall-rule"
  network                 = google_compute_network.vpc_network.self_link
  allow {
    protocol              = "tcp"
    ports                 = ["22"]
  }
  source_ranges           = var.firewall_ssh_source_ranges
}

# Create the HTTP firewall rule
resource "google_compute_firewall" "http_firewall_rule" {
  project                 = var.project_id
  name                    = "http-firewall-rule"
  network                 = google_compute_network.vpc_network.self_link
  allow {
    protocol              = "tcp"
    ports                 = ["80"]
  }
  source_ranges           = var.firewall_http_source_ranges
}

# Create the HTTPS firewall rule
resource "google_compute_firewall" "https_firewall_rule" {
  project                 = var.project_id
  name                    = "https-firewall-rule"
  network                 = google_compute_network.vpc_network.self_link
  allow {
    protocol              = "tcp"
    ports                 = ["443"]
  }
  source_ranges           = var.firewall_https_source_ranges
}

# Create the GCE instance
resource "google_compute_instance" "gce_instance" {
  project                 = var.project_id
  name                    = var.gce_instance_name
  machine_type            = var.gce_instance_machine_type
  zone                    = var.zone
  boot_disk {
    initialize_params {
      image        = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network               = google_compute_network.vpc_network.self_link
    subnetwork            = google_compute_subnetwork.vpc_subnetwork.self_link
    access_config {
      nat_ip              = google_compute_address.external_ip.address
    }
  }
  service_account {
    email                 = google_service_account.service_account.email
    scopes                = ["cloud-platform"]
  }
}

# Create the service account
resource "google_service_account" "service_account" {
  account_id              = var.service_account_name
  project                 = var.project_id
  display_name            = var.service_account_name
}

# Add roles to the service account
resource "google_project_iam_member" "service_account_role" {
  project                 = var.project_id
  for_each                = var.service_account_roles
  role                    = each.value
  member                  = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.id
  private_key_type = "TYPE_UNSPECIFIED"
}
output "gce_instance_external_ip" {
  value = google_compute_instance.gce_instance.network_interface.0.access_config.0.nat_ip
}
output "gce_instance_cpu_platform" {
  value = google_compute_instance.gce_instance.cpu_platform
}
output "service_account_key" {
  value = google_service_account_key.service_account_key.private_key
}