# Configure providers
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "aviatrix" {
  controller_ip = var.aviatrix_controller_ip
  username      = var.aviatrix_username
  password      = var.aviatrix_password
  skip_version_validation = true
}

# kubectl provider for FRONTEND cluster
provider "kubectl" {
  alias                  = "frontend"
  host                   = "https://${google_container_cluster.frontend.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.frontend.master_auth[0].cluster_ca_certificate)
}

# kubectl provider for BACKEND cluster  
provider "kubectl" {
  alias                  = "backend"
  host                   = "https://${google_container_cluster.backend.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.backend.master_auth[0].cluster_ca_certificate)
}