module "gcp_network"{
  source = "./gcp_network"
  project_id = "cloud-prod-arrival"
  region = "europe-west2"
  zone = "europe-west2-a"
  vpc_network_name = "testvpcnetwork"
  vpc_subnetwork_name = "testvpcsubnetwork"
  vpc_subnetwork_cidr = "10.154.0.0/20"
  firewall_ssh_source_ranges = 	["0.0.0.0/0"]
  firewall_http_source_ranges = ["0.0.0.0/0"]
  firewall_https_source_ranges = ["0.0.0.0/0"]
  gce_instance_name = "testgceinstance"
  gce_instance_machine_type = "n1-standard-8"
  service_account_name = "testserviceaccount"
  service_account_roles = ["roles/viewer","roles/editor"]
}
