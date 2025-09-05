# Get cluster credentials
data "google_client_config" "default" {}

data "google_container_cluster" "frontend" {
  name     = google_container_cluster.gke_frontend_cluster.name
  location = google_container_cluster.gke_frontend_cluster.location
}

data "google_container_cluster" "backend" {
  name     = google_container_cluster.gke_backend_cluster.name
  location = google_container_cluster.gke_backend_cluster.location
}

# Kubernetes provider for frontend cluster
provider "kubernetes" {
  alias = "frontend"
  host  = "https://${data.google_container_cluster.frontend.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.frontend.master_auth[0].cluster_ca_certificate,
  )
}

# Kubernetes provider for backend cluster
provider "kubernetes" {
  alias = "backend"
  host  = "https://${data.google_container_cluster.backend.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.backend.master_auth[0].cluster_ca_certificate,
  )
}