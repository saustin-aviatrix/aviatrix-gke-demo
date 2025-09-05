# Frontend Gatus Deployments

resource "kubernetes_deployment" "frontend_gatus_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "frontend-gatus-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
    labels = {
      app = "frontend-gatus-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "frontend-gatus-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend-gatus-prod"
        }
        annotations = {
          "configmap/checksum" = sha256(jsonencode(kubernetes_config_map.frontend_gatus_prod.data))
        }
      }

      spec {
        container {
          image = "twinproduction/gatus:latest"
          name  = "gatus"
          port {
            container_port = 8080
          }

          # Add security context for ICMP capability
          security_context {
            capabilities {
              add = ["NET_RAW"]
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
           }
         }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.frontend_gatus_prod.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "frontend_gatus_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "frontend-gatus-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
    labels = {
      app = "frontend-gatus-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "frontend-gatus-dev"
      }
      
    }

    template {
      metadata {
        labels = {
          app = "frontend-gatus-dev"
        }
        annotations = {
          "configmap/checksum" = sha256(jsonencode(kubernetes_config_map.frontend_gatus_dev.data))
        }
      }

      spec {
        container {
          image = "twinproduction/gatus:latest"
          name  = "gatus"
          port {
            container_port = 8080
          }

          # Add security context for ICMP capability
          security_context {
            capabilities {
              add = ["NET_RAW"]
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
           }
         }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.frontend_gatus_dev.metadata[0].name
          }
        }
      }
    }
  }
}


# Frontend Gatus Service

resource "kubernetes_service" "frontend_gatus_prod" {
  provider = kubernetes.frontend
  metadata {
    name      = "frontend-gatus-prod"
    namespace = kubernetes_namespace.frontend_prod.metadata[0].name
  }
  spec {
    selector = {
      app = "frontend-gatus-prod"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "frontend_gatus_dev" {
  provider = kubernetes.frontend
  metadata {
    name      = "frontend-gatus-dev"
    namespace = kubernetes_namespace.frontend_dev.metadata[0].name
  }
  spec {
    selector = {
      app = "frontend-gatus-dev"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}



# Backend Gatus Deployments

resource "kubernetes_deployment" "backend_gatus_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "backend-gatus-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
    labels = {
      app = "backend-gatus-prod"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "backend-gatus-prod"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-gatus-prod"
        }
        annotations = {
          "configmap/checksum" = sha256(jsonencode(kubernetes_config_map.backend_gatus_prod.data))
        }
      }

      spec {
        container {
          image = "twinproduction/gatus:latest"
          name  = "gatus"
          port {
            container_port = 8080
          }

          # Add security context for ICMP capability
          security_context {
            capabilities {
              add = ["NET_RAW"]
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
           }
         }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.backend_gatus_prod.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "backend_gatus_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "backend-gatus-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
    labels = {
      app = "backend-gatus-dev"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "backend-gatus-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-gatus-dev"
        }
        annotations = {
          "configmap/checksum" = sha256(jsonencode(kubernetes_config_map.backend_gatus_dev.data))
        }
      }

      spec {
        container {
          image = "twinproduction/gatus:latest"
          name  = "gatus"
          port {
            container_port = 8080
          }

          # Add security context for ICMP capability
          security_context {
            capabilities {
              add = ["NET_RAW"]
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
           }
         }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.backend_gatus_dev.metadata[0].name
          }
        }
      }
    }
  }
}


# backend Gatus Service

resource "kubernetes_service" "backend_gatus_prod" {
  provider = kubernetes.backend
  metadata {
    name      = "backend-gatus-prod"
    namespace = kubernetes_namespace.backend_prod.metadata[0].name
  }
  spec {
    selector = {
      app = "backend-gatus-prod"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "backend_gatus_dev" {
  provider = kubernetes.backend
  metadata {
    name      = "backend-gatus-dev"
    namespace = kubernetes_namespace.backend_dev.metadata[0].name
  }
  spec {
    selector = {
      app = "backend-gatus-dev"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}