

# Frontend Cluster Namespaces
resource "kubernetes_namespace" "frontend_prod" {
  provider = kubernetes.frontend
  metadata {
    name = "prod"
    labels = {
      environment = "production"
    }
  }
  timeouts {
    delete = "5m"
  }

  depends_on = [
    data.google_container_cluster.frontend,
    data.google_client_config.default
  ]
}

resource "kubernetes_namespace" "frontend_dev" {
  provider = kubernetes.frontend
  metadata {
    name = "dev"
    labels = {
      environment = "development"
    }
  }  
  
  timeouts {
    delete = "5m"
  }

  depends_on = [
    data.google_container_cluster.frontend,
    data.google_client_config.default
  ]
}

# Frontend NGINX Config Maps

resource "kubernetes_config_map" "accounting_frontend_web_prod" {
  provider = kubernetes.frontend

  metadata {
    name      = "accounting-frontend-web-prod-config"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'Accounting Frontend Web - Prod Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting Frontend Web - Prod\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'Accounting Frontend Web - Prod Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting Frontend Web - Prod (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.frontend_prod]
}

resource "kubernetes_config_map" "accounting_frontend_web_dev" {
  provider = kubernetes.frontend

  metadata {
    name      = "accounting-frontend-web-dev-config"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'Accounting Frontend Web - Dev Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting Frontend Web - Dev\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'Accounting Frontend Web - Dev Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - Accounting Frontend Web - Dev (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.frontend_dev]
}

resource "kubernetes_config_map" "marketing_frontend_web_prod" {
  provider = kubernetes.frontend

  metadata {
    name      = "marketing-frontend-web-prod-config"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'marketing Frontend Web - Prod Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing Frontend Web - Prod\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'marketing Frontend Web - Prod Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing Frontend Web - Prod (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.frontend_prod]
}

resource "kubernetes_config_map" "marketing_frontend_web_dev" {
  provider = kubernetes.frontend

  metadata {
    name      = "marketing-frontend-web-dev-config"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name _;
          
          location / {
              return 200 'marketing Frontend Web - Dev Environment (HTTP)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing Frontend Web - Dev\n';
              add_header Content-Type text/plain;
          }
      }
      
      server {
          listen 443;
          server_name _;
          
          location / {
              return 200 'marketing Frontend Web - Dev Environment (HTTPS)\n';
              add_header Content-Type text/plain;
          }
          
          location /health {
              return 200 'OK - marketing Frontend Web - Dev (HTTPS)\n';
              add_header Content-Type text/plain;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.frontend_dev]
}

# Frontend Deployments

resource "kubernetes_deployment" "accounting_frontend_web_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "accounting-frontend-web-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
    labels = {
      app = "accounting-frontend-web-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "accounting-frontend-web-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "accounting-frontend-web-prod"
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
            name = kubernetes_config_map.accounting_frontend_web_prod.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.frontend_prod,
    kubernetes_config_map.accounting_frontend_web_prod]
}


resource "kubernetes_deployment" "accounting_frontend_web_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "accounting-frontend-web-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
    labels = {
      app = "accounting-frontend-web-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "accounting-frontend-web-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "accounting-frontend-web-dev"
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
            name = kubernetes_config_map.accounting_frontend_web_dev.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.frontend_dev,
    kubernetes_config_map.accounting_frontend_web_dev]
}


resource "kubernetes_deployment" "marketing_frontend_web_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "marketing-frontend-web-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
    labels = {
      app = "marketing-frontend-web-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "marketing-frontend-web-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "marketing-frontend-web-prod"
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
            name = kubernetes_config_map.marketing_frontend_web_prod.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.frontend_prod,
    kubernetes_config_map.marketing_frontend_web_prod]
}


resource "kubernetes_deployment" "marketing_frontend_web_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "marketing-frontend-web-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
    labels = {
      app = "marketing-frontend-web-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "marketing-frontend-web-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "marketing-frontend-web-dev"
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
            name = kubernetes_config_map.marketing_frontend_web_dev.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.frontend_dev,
    kubernetes_config_map.marketing_frontend_web_dev]
}


#
# Frontend Services
#

resource "kubernetes_service" "accounting_frontend_web_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "accounting-frontend-web-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "accounting-frontend-web-prod"
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

resource "kubernetes_service" "accounting_frontend_web_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "accounting-frontend-web-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "accounting-frontend-web-dev"
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

resource "kubernetes_service" "marketing_frontend_web_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "marketing-frontend-web-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "marketing-frontend-web-prod"
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

resource "kubernetes_service" "marketing_frontend_web_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "marketing-frontend-web-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = "marketing-frontend-web-dev"
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