# Onboard GKE Clusters to Aviatrix 

data "google_container_cluster" "gke_frontend_cluster" {
  name     = google_container_cluster.gke_frontend_cluster.name
  location = google_container_cluster.gke_frontend_cluster.location
  
  # Ensure the cluster is created first
  depends_on = [google_container_cluster.gke_frontend_cluster]
}

# Register the GKE cluster with Aviatrix controller
resource "aviatrix_kubernetes_cluster" "gke_frontend_cluster" {
  cluster_id          = data.google_container_cluster.gke_frontend_cluster.self_link
  use_csp_credentials = true
  
  # Add dependencies to ensure proper creation order
  depends_on = [
    google_container_cluster.gke_frontend_cluster,
    data.google_container_cluster.gke_frontend_cluster,
    aviatrix_spoke_gateway.gke_frontend_spoke
  ]
}


data "google_container_cluster" "gke_backend_cluster" {
  name     = google_container_cluster.gke_backend_cluster.name
  location = google_container_cluster.gke_backend_cluster.location
  
  # Ensure the cluster is created first
  depends_on = [google_container_cluster.gke_backend_cluster]
}

# Register the backend GKE cluster with Aviatrix controller
resource "aviatrix_kubernetes_cluster" "gke_backend_cluster" {
  cluster_id          = data.google_container_cluster.gke_backend_cluster.self_link
  use_csp_credentials = true
  
  # Add dependencies to ensure proper creation order
  depends_on = [
    google_container_cluster.gke_backend_cluster,
    data.google_container_cluster.gke_backend_cluster,
    aviatrix_spoke_gateway.gke_backend_spoke
  ]
}