# GKE Clusters and compute

# Commenting out, this only uses existing account, doesnt create if not there
# data "google_service_account" "gke_service_account" {
#   account_id = "gke-service-account"
# }

locals {
  service_account_exists = can(data.google_service_account.existing_gke_service_account.email)
  gke_service_account_email = (
    local.service_account_exists ? 
    data.google_service_account.existing_gke_service_account.email : 
    google_service_account.gke_service_account[0].email
  )
}

data "google_service_account" "existing_gke_service_account" {
  account_id = "gke-service-account"
}

resource "google_service_account" "gke_service_account" {
  count = local.service_account_exists ? 0 : 1
  
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "Service account for GKE clusters"
}

resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.gke_service_account_email}"
}

# GKE Cluster - frontend
resource "google_container_cluster" "gke_frontend_cluster" {
  name     = "gke-frontend-cluster"
  location = var.zone
  network  = google_compute_network.gke_frontend.id
  subnetwork = google_compute_subnetwork.gke_frontend_subnet.id

  resource_labels = {
    environment = "frontend"
    project     = "gke-demo"
  }

  networking_mode = "VPC_NATIVE"

  deletion_protection = false

  default_snat_status {
    disabled = true
  }

  # Disable public endpoint
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Set to true if you want fully private
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # CRITICAL: Add master authorized networks
  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "10.0.0.0/8"
  #     display_name = "Private Networks"
  #   }
  #   cidr_blocks {
  #     cidr_block   = "${chomp(data.http.myip.response_body)}/32"
  #     display_name = "My Current IP"
  #   }
  #   cidr_blocks {
  #     cidr_block   = "35.235.240.0/20"
  #     display_name = "Google Cloud Shell"
  #   }
  #   cidr_blocks {
  #     cidr_block = "0.0.0.0/0"
  #     display_name = "Temp allow for controller access"
  #   }
  # }

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-frontend-pods"
    services_secondary_range_name = "gke-frontend-services"
  }

  # Disable basic authentication and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # metrics collection should be disabled.
  # If it is enabled, destroying the terraform can fail because the test namespace stays stuck in the terminating
  # state, because a finalizer is registered and the metrics endpoints are already unavailable.
  monitoring_service = "none"

  depends_on = [
    google_project_iam_member.gke_service_account_roles,
    aviatrix_spoke_transit_attachment.gke_frontend_attachment
  ]
}

resource "google_container_node_pool" "gke_frontend_nodes" {
  name       = "gke-frontend-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.gke_frontend_cluster.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "e2-small"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    
    service_account = local.gke_service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    tags = ["gke-frontend", "avx-snat-noip", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# GKE Cluster - backend
resource "google_container_cluster" "gke_backend_cluster" {
  name     = "gke-backend-cluster"
  location = var.zone
  network  = google_compute_network.gke_backend.id
  subnetwork = google_compute_subnetwork.gke_backend_subnet.id

  resource_labels = {
    environment = "backend"
    project     = "gke-demo"
  }

  networking_mode = "VPC_NATIVE"

  deletion_protection = false  

  default_snat_status {
    disabled = true
  }

  # Disable public endpoint
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Set to true if you want fully private
    master_ipv4_cidr_block  = "172.16.1.0/28"
  }

  # CRITICAL: Add master authorized networks
  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "10.0.0.0/8"
  #     display_name = "Private Networks"
  #   }
  #   cidr_blocks {
  #     cidr_block   = "${chomp(data.http.myip.response_body)}/32"
  #     display_name = "My Current IP"
  #   }
  #   cidr_blocks {
  #     cidr_block   = "35.235.240.0/20"
  #     display_name = "Google Cloud Shell"
  #   }
  # }

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-backend-pods"
    services_secondary_range_name = "gke-backend-services"
  }

  # metrics collection should be disabled.
  # If it is enabled, destroying the terraform can fail because the test namespace stays stuck in the terminating
  # state, because a finalizer is registered and the metrics endpoints are already unavailable.
  monitoring_service = "none"

  # Disable basic authentication and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_project_iam_member.gke_service_account_roles,
    aviatrix_spoke_transit_attachment.gke_backend_attachment
  ]
}

resource "google_container_node_pool" "gke_backend_nodes" {
  name       = "gke-backend-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.gke_backend_cluster.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "e2-small"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    
    service_account = local.gke_service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["gke-backend", "avx-snat-noip", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Shared Services Compute Instance
resource "google_compute_instance" "shared_services" {
  name         = "shared-services-instance"
  machine_type = "e2-small"
  zone         = var.zone

  labels = {
    environment = "shared-services"
  }
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.shared_services.id
    subnetwork = google_compute_subnetwork.shared_services_subnet.id
  }

  metadata_startup_script = templatefile("${path.module}/shared-services-startup.sh.tpl", {
    Frontend = [
        # Accounting Frontend Prod
        {
          endpoint = kubernetes_service.accounting_frontend_web_prod.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.accounting_frontend_web_prod.metadata[0].name
        },
        # Accounting Frontend Dev
        {
          endpoint = kubernetes_service.accounting_frontend_web_dev.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.accounting_frontend_web_dev.metadata[0].name
        },
        # Marketing Frontend Prod  
        {
          endpoint = kubernetes_service.marketing_frontend_web_prod.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.marketing_frontend_web_prod.metadata[0].name
        },
        # Marketing Frontend Dev
        {
          endpoint = kubernetes_service.marketing_frontend_web_dev.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.marketing_frontend_web_dev.metadata[0].name
        },
      ]
      Backend = [
        # Accounting Backend Prod
        {
          endpoint = kubernetes_service.accounting_backend_web_prod.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.accounting_backend_web_prod.metadata[0].name
        },
        # Accounting Backend Dev
        {
          endpoint = kubernetes_service.accounting_backend_web_dev.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.accounting_backend_web_dev.metadata[0].name
        },
        # Marketing Backend Prod  
        {
          endpoint = kubernetes_service.marketing_backend_web_prod.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.marketing_backend_web_prod.metadata[0].name
        },
        # Marketing Backend Dev
        {
          endpoint = kubernetes_service.marketing_backend_web_dev.status.0.load_balancer.0.ingress.0.ip
          service_name = kubernetes_service.marketing_backend_web_dev.metadata[0].name
        },
      ]
    })



  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["shared-services", "allow-health-check", "avx-snat-noip"]

  depends_on = [
    kubernetes_service.accounting_frontend_web_prod,
    kubernetes_service.accounting_frontend_web_dev,
    kubernetes_service.marketing_frontend_web_prod,
    kubernetes_service.marketing_frontend_web_dev,
    kubernetes_service.accounting_backend_web_prod,
    kubernetes_service.accounting_backend_web_dev,
    kubernetes_service.marketing_backend_web_prod,
    kubernetes_service.marketing_backend_web_dev
  ]
}

# Health check for Shared Serices Gatus
resource "google_compute_health_check" "gatus_health" {
  name               = "gatus-health-check"
  check_interval_sec = 60
  timeout_sec        = 10

  http_health_check {
    port         = "8080"
    request_path = "/"  # Adjust if Gatus has a specific health endpoint
  }
}

# Instance group for the shared service instance
resource "google_compute_instance_group" "gatus_group" {
  name        = "gatus-instance-group"
  zone        = var.zone
  description = "Instance group for Gatus monitoring"

  instances = [
    google_compute_instance.shared_services.self_link
  ]

  # Explicit dependency
  depends_on = [
    google_compute_instance.shared_services
  ]

  named_port {
    name = "gatus-http"
    port = "8080"
  }
}

# Backend service for Gatus
resource "google_compute_backend_service" "gatus_backend" {
  name                  = "gatus-backend-service"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "gatus-http"
  timeout_sec           = 30

  backend {
    group = google_compute_instance_group.gatus_group.id
  }

  health_checks = [google_compute_health_check.gatus_health.id]
}

# URL map for routing
resource "google_compute_url_map" "gatus_url_map" {
  name            = "gatus-url-map"
  default_service = google_compute_backend_service.gatus_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.gatus_backend.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.gatus_backend.id
    }
  }
}

# HTTP proxy
resource "google_compute_target_http_proxy" "gatus_proxy" {
  name    = "gatus-http-proxy"
  url_map = google_compute_url_map.gatus_url_map.id
}

# Global forwarding rule with public IP
resource "google_compute_global_forwarding_rule" "gatus_forwarding_rule" {
  name       = "gatus-forwarding-rule"
  target     = google_compute_target_http_proxy.gatus_proxy.id
  port_range = "80"
}

# Create a local for the DNS name
locals {
  shared_services_dns = "${google_compute_instance.shared_services.name}.${var.zone}.c.${var.project_id}.internal"
}