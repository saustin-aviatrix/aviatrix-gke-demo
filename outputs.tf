output "vpc_networks" {
  description = "VPC network details"
  value = {
    gke_frontend = {
      name   = google_compute_network.gke_frontend.name
      id     = google_compute_network.gke_frontend.id
      subnet = google_compute_subnetwork.gke_frontend_subnet.ip_cidr_range
    }
    gke_backend = {
      name   = google_compute_network.gke_backend.name
      id     = google_compute_network.gke_backend.id
      subnet = google_compute_subnetwork.gke_backend_subnet.ip_cidr_range
    }
    shared_services = {
      name   = google_compute_network.shared_services.name
      id     = google_compute_network.shared_services.id
      subnet = google_compute_subnetwork.shared_services_subnet.ip_cidr_range
    }
    transit = {
      name   = google_compute_network.transit.name
      id     = google_compute_network.transit.id
      subnet = google_compute_subnetwork.transit_subnet.ip_cidr_range
    }
  }
}

output "aviatrix_gateways" {
  description = "Aviatrix gateway details"
  value = {
    transit_gateway = {
      name = aviatrix_transit_gateway.transit_gateway.gw_name
      size = aviatrix_transit_gateway.transit_gateway.gw_size
    }
    spoke_gateways = {
      gke_frontend         = aviatrix_spoke_gateway.gke_frontend_spoke.gw_name
      gke_backend          = aviatrix_spoke_gateway.gke_backend_spoke.gw_name
      shared_services = aviatrix_spoke_gateway.shared_services_spoke.gw_name
    }
  }
}

output "gke_clusters" {
  description = "GKE cluster details"
  value = {
    gke_frontend_cluster = {
      name     = google_container_cluster.gke_frontend_cluster.name
      endpoint = google_container_cluster.gke_frontend_cluster.endpoint
      location = google_container_cluster.gke_frontend_cluster.location
    }
    gke_backend_cluster = {
      name     = google_container_cluster.gke_backend_cluster.name
      endpoint = google_container_cluster.gke_backend_cluster.endpoint
      location = google_container_cluster.gke_backend_cluster.location
    }
  }
}

output "shared_services_instance" {
  description = "Shared Services compute instance details"
  value = {
    name         = google_compute_instance.shared_services.name
    internal_ip  = google_compute_instance.shared_services.network_interface[0].network_ip
    machine_type = google_compute_instance.shared_services.machine_type
  }
}

output "workload_urls" {
  description = "URLs to access workloads instances"
  value = {
    frontend_services = {
      accounting_prod = "http://${kubernetes_service.accounting_frontend_web_prod.status[0].load_balancer[0].ingress[0].ip}"
      accounting_dev  = "http://${kubernetes_service.accounting_frontend_web_dev.status[0].load_balancer[0].ingress[0].ip}"
      marketing_prod  = "http://${kubernetes_service.marketing_frontend_web_prod.status[0].load_balancer[0].ingress[0].ip}"
      marketing_dev   = "http://${kubernetes_service.marketing_frontend_web_dev.status[0].load_balancer[0].ingress[0].ip}"
    }
    backend_services = {
      accounting_prod = "http://${kubernetes_service.accounting_backend_web_prod.status[0].load_balancer[0].ingress[0].ip}"
      accounting_dev  = "http://${kubernetes_service.accounting_backend_web_dev.status[0].load_balancer[0].ingress[0].ip}"
      marketing_prod  = "http://${kubernetes_service.marketing_backend_web_prod.status[0].load_balancer[0].ingress[0].ip}"
      marketing_dev   = "http://${kubernetes_service.marketing_backend_web_dev.status[0].load_balancer[0].ingress[0].ip}"
    }
  }
}

output "gatus_urls" {
  description = "URLS to access Gatus instances"
  value = {
    frontend_gatus = {
      frontend_gatus_prod  = "http://${kubernetes_service.frontend_gatus_prod.status[0].load_balancer[0].ingress[0].ip}"
      frontend_gatus_dev   = "http://${kubernetes_service.frontend_gatus_dev.status[0].load_balancer[0].ingress[0].ip}"
    }
    backend_gatus = {
	    backend-gatus-prod  = "http://${kubernetes_service.backend_gatus_prod.status[0].load_balancer[0].ingress[0].ip}"
	    backend-gatus-dev   = "http://${kubernetes_service.backend_gatus_dev.status[0].load_balancer[0].ingress[0].ip}"
    }
    shared_service = "http://${google_compute_global_forwarding_rule.gatus_forwarding_rule.ip_address}"
  }
}