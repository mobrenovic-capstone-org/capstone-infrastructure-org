module "vpc" {
  source       = "../../modules/network"
  network_name = var.network_name
  subnetworks  = var.subnets
}

module "cluster" {
  source                        = "../../modules/cluster"
  project_id                    = var.project_id
  network                       = module.vpc.network_id
  subnetwork                    = module.vpc.subnet_id[0]
  cluster_secondary_range_name  = var.subnets.0.pods_range_name
  services_secondary_range_name = var.subnets.0.services_range_name
  np_name                       = var.np_name
  cluster_location              = var.location
  cluster_name                  = var.cluster_name
  service_account               = var.service_account
}

data "google_client_config" "default" {
  depends_on = [module.cluster]
}

data "google_container_cluster" "default" {
  name       = var.cluster_name
  location   = var.location
  depends_on = [module.cluster]
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.default.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth.0.cluster_ca_certificate,
  )
}

module "hpa" {
  source       = "../../modules/kubernetes-config"
  hpa_name     = var.hpa_name
  max_replicas = var.max_replicas
  target_name  = var.target_name
  api_version  = var.api_version
}