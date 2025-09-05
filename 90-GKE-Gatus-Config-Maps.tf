#
# Frontend Services ConfigMaps for Gatus
#


resource "kubernetes_config_map" "frontend_gatus_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "gatus-config-accounting-frontend-gatus-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
  }

  data = {
    "config.yaml" = templatefile("${path.module}/gatus-config.yaml.tpl", {
      service_name = "frontend-gatus-prod"
      Frontend = []
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
      Shared = [
        {
        # Shared service instance
        endpoint = google_compute_instance.shared_services.network_interface[0].network_ip
        service_name = google_compute_instance.shared_services.name
        }
      ]
    })
  }

  # Add dependency to ensure config_maps and pod data is created
  depends_on = [
    kubernetes_service.accounting_frontend_web_prod,
    kubernetes_service.accounting_frontend_web_dev,
    kubernetes_service.marketing_frontend_web_prod,
    kubernetes_service.marketing_frontend_web_dev,
    kubernetes_service.accounting_backend_web_prod,
    kubernetes_service.accounting_backend_web_dev,
    kubernetes_service.marketing_backend_web_prod,
    kubernetes_service.marketing_backend_web_dev,
    google_compute_instance.shared_services
  ]

  lifecycle {
    ignore_changes = [data["config.yaml"]]  # Prevent drift detection
  }
}

resource "kubernetes_config_map" "frontend_gatus_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "gatus-config-accounting-frontend-gatus-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
  }

  data = {
    "config.yaml" = templatefile("${path.module}/gatus-config.yaml.tpl", {
      service_name = "frontend-gatus-dev"
      Frontend = []
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
      Shared = [
        {
        # Shared service instance
        endpoint = google_compute_instance.shared_services.network_interface[0].network_ip
        service_name = google_compute_instance.shared_services.name
        }
      ]
    })
  }

  # Add dependency to ensure config_maps and pod data is created
  depends_on = [
    kubernetes_service.accounting_frontend_web_prod,
    kubernetes_service.accounting_frontend_web_dev,
    kubernetes_service.marketing_frontend_web_prod,
    kubernetes_service.marketing_frontend_web_dev,
    kubernetes_service.accounting_backend_web_prod,
    kubernetes_service.accounting_backend_web_dev,
    kubernetes_service.marketing_backend_web_prod,
    kubernetes_service.marketing_backend_web_dev,
    google_compute_instance.shared_services
  ]

  lifecycle {
    ignore_changes = [data["config.yaml"]]  # Prevent drift detection
  }
}


#
# Backend Services ConfigMaps for Gatus
#

resource "kubernetes_config_map" "backend_gatus_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "gatus-config-accounting-backend-gatus-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
  }

  data = {
    "config.yaml" = templatefile("${path.module}/gatus-config.yaml.tpl", {
      service_name = "backend-gatus-prod"
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
      Backend = []
      Shared = [
        {
        # Shared service instance
        endpoint = google_compute_instance.shared_services.network_interface[0].network_ip
        service_name = google_compute_instance.shared_services.name
        }
      ]
    })
  }

  # Add dependency to ensure config_maps and pod data is created
  depends_on = [
    kubernetes_service.accounting_frontend_web_prod,
    kubernetes_service.accounting_frontend_web_dev,
    kubernetes_service.marketing_frontend_web_prod,
    kubernetes_service.marketing_frontend_web_dev,
    kubernetes_service.accounting_backend_web_prod,
    kubernetes_service.accounting_backend_web_dev,
    kubernetes_service.marketing_backend_web_prod,
    kubernetes_service.marketing_backend_web_dev,
    google_compute_instance.shared_services
  ]

  lifecycle {
    ignore_changes = [data["config.yaml"]]  # Prevent drift detection
  }
}

resource "kubernetes_config_map" "backend_gatus_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "gatus-config-accounting-backend-gatus-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
  }

  data = {
    "config.yaml" = templatefile("${path.module}/gatus-config.yaml.tpl", {
      service_name = "backend-gatus-dev"
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
      Backend = []
      Shared = [
        {
        # Shared service instance
        endpoint = google_compute_instance.shared_services.network_interface[0].network_ip
        service_name = google_compute_instance.shared_services.name
        }
      ]
    })
  }

  # Add dependency to ensure config_maps and pod data is created
  depends_on = [
    kubernetes_service.accounting_frontend_web_prod,
    kubernetes_service.accounting_frontend_web_dev,
    kubernetes_service.marketing_frontend_web_prod,
    kubernetes_service.marketing_frontend_web_dev,
    kubernetes_service.accounting_backend_web_prod,
    kubernetes_service.accounting_backend_web_dev,
    kubernetes_service.marketing_backend_web_prod,
    kubernetes_service.marketing_backend_web_dev,
    google_compute_instance.shared_services
  ]

  lifecycle {
    ignore_changes = [data["config.yaml"]]  # Prevent drift detection
  }
}


