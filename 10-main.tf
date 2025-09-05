# Data sources
data "google_client_config" "current" {}

# Get your current public IP
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# VPC 1: gke-Frontend
resource "google_compute_network" "gke_frontend" {
  name                    = "gke-frontend"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
  
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_compute_subnetwork" "gke_frontend_subnet" {
  name          = "gke-frontend-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.gke_frontend.id
  
  # Secondary ranges for GKE
  secondary_ip_range {
    range_name    = "gke-frontend-pods"
    ip_cidr_range = "10.10.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "gke-frontend-services"
    ip_cidr_range = "10.11.0.0/16"
  }
}

resource "google_compute_subnetwork" "gke_frontend_gw_subnet" {
  name          = "gke-frontend-gw-subnet"
  ip_cidr_range = "10.12.0.0/24"
  region        = var.region
  network       = google_compute_network.gke_frontend.id
}

# VPC 2: gke-backend
resource "google_compute_network" "gke_backend" {
  name                    = "gke-backend"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
  
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_compute_subnetwork" "gke_backend_subnet" {
  name          = "gke-backend-subnet"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.region
  network       = google_compute_network.gke_backend.id
  
  # Secondary ranges for GKE
  secondary_ip_range {
    range_name    = "gke-backend-pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "gke-backend-services"
    ip_cidr_range = "10.21.0.0/16"
  }
}

resource "google_compute_subnetwork" "gke_backend_gw_subnet" {
  name          = "gke-backend-gw-subnet"
  ip_cidr_range = "10.22.0.0/24"
  region        = var.region
  network       = google_compute_network.gke_backend.id
}

# VPC 3: Shared-Services
resource "google_compute_network" "shared_services" {
  name                    = "shared-services"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
  
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_compute_subnetwork" "shared_services_subnet" {
  name          = "shared-services-subnet"
  ip_cidr_range = "10.3.0.0/24"
  region        = var.region
  network       = google_compute_network.shared_services.id
}

resource "google_compute_subnetwork" "shared_services_gw_subnet" {
  name          = "shared-services-gw-subnet"
  ip_cidr_range = "10.31.0.0/24"
  region        = var.region
  network       = google_compute_network.shared_services.id
}

# VPC 4: Transit
resource "google_compute_network" "transit" {
  name                    = "gcp-transit-us-west1"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
  
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_compute_subnetwork" "transit_subnet" {
  name          = "gcp-transit-us-west1-subnet"
  ip_cidr_range = "10.100.0.0/23"
  region        = var.region
  network       = google_compute_network.transit.id
}

# Firewall Rules
resource "google_compute_firewall" "gke_frontend_allow" {
  name    = "gke-frontend-allow-internal"
  network = google_compute_network.gke_frontend.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16", "35.235.240.0/20"]

  target_tags   = ["gke-frontend", "gke-frontend-spoke-gw"]
}

resource "google_compute_firewall" "gke_backend_allow" {
  name    = "gke-backend-allow-internal"
  network = google_compute_network.gke_backend.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16", "35.235.240.0/20"]
  target_tags   = ["gke-backend", "gke-backend-spoke-gw"]
}

resource "google_compute_firewall" "shared_services_allow" {
  name    = "shared-services-allow-internal"
  network = google_compute_network.shared_services.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
  
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8", "35.235.240.0/20"]
  target_tags   = ["shared-services"]
}

# Firewall rule to allow load balancer health checks and traffic
resource "google_compute_firewall" "allow_lb_to_gatus" {
  name    = "allow-lb-to-gatus"
  network = google_compute_network.shared_services.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  # Google Load Balancer IP ranges
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  
  target_tags = ["shared-services"]
}

# Aviatrix Spoke Gateways
resource "aviatrix_spoke_gateway" "gke_frontend_spoke" {
  cloud_type   = 4  # GCP
  account_name = var.gcp_account_name
  gw_name      = "gke-frontend-spoke-gw"
  vpc_id       = "${google_compute_network.gke_frontend.name}~-~${var.project_id}"
  vpc_reg      = var.zone
  gw_size      = "n1-standard-2"
  subnet       = google_compute_subnetwork.gke_frontend_gw_subnet.ip_cidr_range
  
  # Enable Source NAT for local egress
  single_ip_snat = true

  # Advertise GKE routes
  included_advertised_spoke_routes = "${google_compute_subnetwork.gke_frontend_subnet.ip_cidr_range},${google_compute_subnetwork.gke_frontend_subnet.secondary_ip_range.0.ip_cidr_range},${google_compute_subnetwork.gke_frontend_gw_subnet.ip_cidr_range}"

  depends_on = [google_compute_subnetwork.gke_frontend_gw_subnet]
}

resource "aviatrix_spoke_gateway" "gke_backend_spoke" {
  cloud_type   = 4  # GCP
  account_name = var.gcp_account_name
  gw_name      = "gke-backend-spoke-gw"
  vpc_id       = "${google_compute_network.gke_backend.name}~-~${var.project_id}"
  vpc_reg      = var.zone
  gw_size      = "n1-standard-2"
  subnet       = google_compute_subnetwork.gke_backend_gw_subnet.ip_cidr_range

  # Enable Source NAT for local egress
  single_ip_snat = true
  
  included_advertised_spoke_routes = "${google_compute_subnetwork.gke_backend_subnet.ip_cidr_range},${google_compute_subnetwork.gke_backend_subnet.secondary_ip_range.0.ip_cidr_range},${google_compute_subnetwork.gke_backend_gw_subnet.ip_cidr_range}"

  depends_on = [google_compute_subnetwork.gke_backend_gw_subnet]
}

resource "aviatrix_spoke_gateway" "shared_services_spoke" {
  cloud_type   = 4  # GCP
  account_name = var.gcp_account_name
  gw_name      = "shared-services-spoke-gw"
  vpc_id       = "${google_compute_network.shared_services.name}~-~${var.project_id}"
  vpc_reg      = var.zone
  gw_size      = "n1-standard-2"
  subnet       = google_compute_subnetwork.shared_services_gw_subnet.ip_cidr_range

  # Enable Source NAT for local egress
  single_ip_snat = true
  
  depends_on = [google_compute_subnetwork.shared_services_gw_subnet]
}

# Aviatrix Transit Gateway
resource "aviatrix_transit_gateway" "transit_gateway" {
  cloud_type   = 4  # GCP
  account_name = var.gcp_account_name
  gw_name      = "gcp-transit-us-west1-gw"
  vpc_id       = "${google_compute_network.transit.name}~-~${var.project_id}"
  vpc_reg      = var.zone
  gw_size      = "n1-standard-1"
  subnet       = google_compute_subnetwork.transit_subnet.ip_cidr_range

  # Enable Connected Transit
  connected_transit = true
    
  depends_on = [google_compute_subnetwork.transit_subnet]
}

# Spoke to Transit Attachments
resource "aviatrix_spoke_transit_attachment" "gke_frontend_attachment" {
  spoke_gw_name   = aviatrix_spoke_gateway.gke_frontend_spoke.gw_name
  transit_gw_name = aviatrix_transit_gateway.transit_gateway.gw_name
}

resource "aviatrix_spoke_transit_attachment" "gke_backend_attachment" {
  spoke_gw_name   = aviatrix_spoke_gateway.gke_backend_spoke.gw_name
  transit_gw_name = aviatrix_transit_gateway.transit_gateway.gw_name
}

resource "aviatrix_spoke_transit_attachment" "shared_services_attachment" {
  spoke_gw_name   = aviatrix_spoke_gateway.shared_services_spoke.gw_name
  transit_gw_name = aviatrix_transit_gateway.transit_gateway.gw_name
}



