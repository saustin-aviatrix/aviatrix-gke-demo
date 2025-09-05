
# backend Cluster Namespaces
resource "kubernetes_namespace" "backend_prod" {
  provider = kubernetes.backend
  metadata {
    name = "prod"
    labels = {
      environment = "production"
    }
  }

  timeouts {
    delete = "5m"
  }
}

resource "kubernetes_namespace" "backend_dev" {
  provider = kubernetes.backend
  metadata {
    name = "dev"
    labels = {
      environment = "development"
    }
  }

  timeouts {
    delete = "5m"
  }
}

#
# Backend NGINX Config Maps
#

resource "kubernetes_config_map" "accounting_backend_web_prod" {
  provider = kubernetes.backend

  metadata {
    name      = "accounting-backend-web-prod-config"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'Accounting backend Web - Prod Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting backend Web - Prod\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'Accounting backend Web - Prod Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting backend Web - Prod (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.backend_prod]
}

resource "kubernetes_config_map" "accounting_backend_web_dev" {
  provider = kubernetes.backend

  metadata {
    name      = "accounting-backend-web-dev-config"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'Accounting backend Web - Dev Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting backend Web - Dev\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'Accounting backend Web - Dev Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting backend Web - Dev (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.backend_dev]
}

resource "kubernetes_config_map" "marketing_backend_web_prod" {
  provider = kubernetes.backend

  metadata {
    name      = "marketing-backend-web-prod-config"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'marketing backend Web - Prod Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing backend Web - Prod\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'marketing backend Web - Prod Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing backend Web - Prod (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.backend_prod]
}

resource "kubernetes_config_map" "marketing_backend_web_dev" {
  provider = kubernetes.backend

  metadata {
    name      = "marketing-backend-web-dev-config"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'marketing backend Web - Dev Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing backend Web - Dev\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'marketing backend Web - Dev Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing backend Web - Dev (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.backend_dev]
}

#
# Backend Deployments
#

resource "kubernetes_deployment" "accounting_backend_web_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "accounting-backend-web-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
    labels = {
      app = "accounting-backend-web-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "accounting-backend-web-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "accounting-backend-web-prod"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.accounting_backend_web_prod.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.backend_prod,
    kubernetes_config_map.accounting_backend_web_prod]
}

# Added so we can reference the pod IP for Gatus healthchecks

# resource "null_resource" "get_accounting_backend_web_prod_pod_ips" {
#   provisioner "local-exec" {
#     interpreter = ["PowerShell", "-Command"]
#     command = <<-EOT
#       gcloud container clusters get-credentials gke-backend-cluster --zone=${var.zone} --project=${var.project_id}
#       kubectl --context=gke_${var.project_id}_${var.zone}_gke-backend-cluster get pods -n prod -l app=accounting-backend-web-prod -o jsonpath='{.items[*].status.podIP}' | Out-File -Encoding ASCII -NoNewline accounting_backend_web_prod_pod_ips.txt
#     EOT
#   }
  
#   depends_on = [
#     google_container_cluster.gke_backend_cluster,
#     kubernetes_deployment.accounting_backend_web_prod
#   ]
  
#   triggers = {
#     cluster_endpoint = google_container_cluster.gke_backend_cluster.endpoint,
#     deployment_id = kubernetes_deployment.accounting_backend_web_prod.metadata[0].uid
#   }
# }

# data "local_file" "accounting_backend_web_prod_pod_ips" {
#   filename   = "accounting_backend_web_prod_pod_ips.txt"
#   depends_on = [null_resource.get_accounting_backend_web_prod_pod_ips]
# }


resource "kubernetes_deployment" "accounting_backend_web_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "accounting-backend-web-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
    labels = {
      app = "accounting-backend-web-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "accounting-backend-web-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "accounting-backend-web-dev"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.accounting_backend_web_dev.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.backend_dev,
    kubernetes_config_map.accounting_backend_web_dev
    ]
}

# Added so we can reference the pod IP for Gatus healthchecks

# resource "null_resource" "get_accounting_backend_web_dev_pod_ips" {
#   provisioner "local-exec" {
#     interpreter = ["PowerShell", "-Command"]
#     command = <<-EOT
#       gcloud container clusters get-credentials gke-backend-cluster --zone=${var.zone} --project=${var.project_id}
#       kubectl --context=gke_${var.project_id}_${var.zone}_gke-backend-cluster get pods -n dev -l app=accounting-backend-web-dev -o jsonpath='{.items[*].status.podIP}' | Out-File -Encoding ASCII -NoNewline accounting_backend_web_dev_pod_ips.txt
#     EOT
#   }
  
#   depends_on = [
#     google_container_cluster.gke_backend_cluster,
#     kubernetes_deployment.accounting_backend_web_dev
#   ]
  
#   triggers = {
#     cluster_endpoint = google_container_cluster.gke_backend_cluster.endpoint,
#     deployment_id = kubernetes_deployment.accounting_backend_web_dev.metadata[0].uid
#   }
# }

# data "local_file" "accounting_backend_web_dev_pod_ips" {
#   filename   = "accounting_backend_web_dev_pod_ips.txt"
#   depends_on = [null_resource.get_accounting_backend_web_dev_pod_ips]
# }


resource "kubernetes_deployment" "marketing_backend_web_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "marketing-backend-web-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
    labels = {
      app = "marketing-backend-web-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "marketing-backend-web-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "marketing-backend-web-prod"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.marketing_backend_web_prod.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.backend_prod,
    kubernetes_config_map.marketing_backend_web_prod
    ]
}


resource "kubernetes_deployment" "marketing_backend_web_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "marketing-backend-web-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
    labels = {
      app = "marketing-backend-web-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "marketing-backend-web-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "marketing-backend-web-dev"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.marketing_backend_web_dev.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.backend_dev,
    kubernetes_config_map.marketing_backend_web_dev
    ]
}


#
# Backend Services
#

resource "kubernetes_service" "accounting_backend_web_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "accounting-backend-web-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "accounting-backend-web-prod"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "accounting_backend_web_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "accounting-backend-web-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "accounting-backend-web-dev"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "marketing_backend_web_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "marketing-backend-web-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "marketing-backend-web-prod"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "marketing_backend_web_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "marketing-backend-web-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "marketing-backend-web-dev"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
}
