# Add DCF smartgroups, webgroups, and policies

#
# Ensure DCF is enabled
#

resource "aviatrix_distributed_firewalling_config" "dcf_config" {
  enable_distributed_firewalling = true
  lifecycle {
    prevent_destroy = true
  }
}

#
# Smart Groups
#

resource "aviatrix_smart_group" "shared_services" {
    name = "Shared-Services"
    selector {
        match_expressions {
            type = "vm"
            tags = {
                    environment = "shared-services"
                }
        }

    }

}


resource "aviatrix_smart_group" "frontend_dev_namespace" {
    name = "Frontend-Dev-Namespace"
    selector {
        match_expressions {
            k8s_namespace = "dev"
            type = "k8s"
            k8s_cluster_id = "https://container.googleapis.com/v1/projects/csp-gcp-saustin/zones/us-west1-a/clusters/gke-frontend-cluster"
        }

    }

}

resource "aviatrix_smart_group" "geoblock_highrisk_countries" {
    name = "Geoblock for High Risk Countries"
    selector {
        match_expressions {
            external = "geo"
            ext_args = {
                    country_iso_code = "IR"
                }
        }

        match_expressions {
            external = "geo"
            ext_args = {
                    country_iso_code = "RU"
                }
        }

        match_expressions {
            external = "geo"
            ext_args = {
                    country_iso_code = "KP"
                }
        }

    }

}


resource "aviatrix_smart_group" "backend_dev_gatus_service" {
    name = "Backend-Dev-Gatus-Service"
    selector {
        match_expressions {
            k8s_cluster_id = "https://container.googleapis.com/v1/projects/csp-gcp-saustin/zones/us-west1-a/clusters/gke-backend-cluster"
            type = "k8s"
            k8s_namespace = "dev"
            k8s_service = "backend-gatus-dev"
        }

    }

}

resource "aviatrix_smart_group" "frontend_prod_namespace" {
    name = "Frontend-Prod-Namespace"
    selector {
        match_expressions {
            k8s_cluster_id = "https://container.googleapis.com/v1/projects/csp-gcp-saustin/zones/us-west1-a/clusters/gke-frontend-cluster"
            type = "k8s"
            k8s_namespace = "prod"
        }

    }

}

resource "aviatrix_smart_group" "backend_prod_namespace" {
    name = "Backend-Prod-Namespace"
    selector {
        match_expressions {
            k8s_cluster_id = "https://container.googleapis.com/v1/projects/csp-gcp-saustin/zones/us-west1-a/clusters/gke-backend-cluster"
            type = "k8s"
            k8s_namespace = "prod"
        }

    }

}

resource "aviatrix_smart_group" "backend_dev_namespace" {
    name = "Backend-Dev-Namespace"
    selector {
        match_expressions {
            k8s_cluster_id = "https://container.googleapis.com/v1/projects/csp-gcp-saustin/zones/us-west1-a/clusters/gke-backend-cluster"
            type = "k8s"
            k8s_namespace = "dev"
        }

    }

}

resource "aviatrix_smart_group" "all_threats_feed" {
    name = "All-Threats-Feed"
    selector {
        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "botcc"
                    severity = "informational"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "botcc"
                    severity = "major"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "ciarmy"
                    severity = "informational"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "ciarmy"
                    severity = "major"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "compromised"
                    severity = "informational"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "compromised"
                    severity = "major"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "tor"
                    severity = "informational"
                }
        }

        match_expressions {
            external = "threatiq"
            ext_args = {
                    type = "tor"
                    severity = "major"
                }
        }

    }

}


#
# Webgroups
#

resource "aviatrix_web_group" "frontend_dev_egress" {
    name = "Frontend-Dev-Egress"
    selector {
        match_expressions {
            snifilter = "kubernetes.io"
        }

        match_expressions {
            snifilter = "api.datadoghq.com"
        }

        match_expressions {
            snifilter = "pypi.org"
        }

        match_expressions {
            snifilter = "aws.amazon.com"
        }

    }

}


resource "aviatrix_web_group" "backend_dev_gatus_service_egress" {
    name = "Backend-Dev-Gatus-Service-Egress"
    selector {
        match_expressions {
            snifilter = "kubernetes.io"
        }

        match_expressions {
            snifilter = "api.datadoghq.com"
        }

        match_expressions {
            snifilter = "aws.amazon.com"
        }

        match_expressions {
            snifilter = "pypi.org"
        }

    }
	
}

resource "aviatrix_web_group" "google_apis" {
    name = "Google APIs"
    selector {
        match_expressions {
            snifilter = "*.googleapis.com"
        }

        match_expressions {
            snifilter = "*.docker.io"
        }

        match_expressions {
            snifilter = "*.gcr.io"
        }

        match_expressions {
            snifilter = "*.k8s.io"
        }

        match_expressions {
            snifilter = "quay.io"
        }

    }

}

resource "aviatrix_web_group" "gke_external_services" {
    name = "GKE External Services"
    selector {
        match_expressions {
            snifilter = "*.googleapis.com"
        }

        match_expressions {
            snifilter = "*.docker.io"
        }

        match_expressions {
            snifilter = "*.gcr.io"
        }

        match_expressions {
            snifilter = "*.k8s.io"
        }

        match_expressions {
            snifilter = "quay.io"
        }

    }

}

resource "aviatrix_web_group" "datadog" {
    name = "Datadog"
    selector {
        match_expressions {
            snifilter = "api.datadoghq.com"
        }

    }

}

#
# DCF policies
#

resource "aviatrix_distributed_firewalling_policy_list" "GKE-Demo-Ruleset" {

  policies {
    name     = "Threat Feed Drop"
    priority = 10
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]
    dst_smart_groups = [
      aviatrix_smart_group.all_threats_feed.uuid
    ]

    logging = true
  }

  policies {
    name     = "GEO Block High Risk Countries"
    priority = 20
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]
    dst_smart_groups = [
      aviatrix_smart_group.geoblock_highrisk_countries.uuid
    ]

    logging = true
  }

    policies {
    name     = "GKE Services - Allow and Monitor"
    priority = 50
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
        aviatrix_web_group.gke_external_services.id
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Frontend Prod - CRD"
    priority = 100
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.frontend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
        aviatrix_web_group.datadog.id
    ]

    logging = true
  }

  policies {
    name     = "Frontend Prod to Backend Prod"
    priority = 110
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.frontend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      aviatrix_smart_group.backend_prod_namespace.uuid
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Frontend Prod Deny All"
    priority = 150
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      aviatrix_smart_group.frontend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Frontend Dev"
    priority = 200
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.frontend_dev_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
      aviatrix_web_group.frontend_dev_egress.id
    ]

    logging = true
  }

  policies {
    name     = "Frontend Dev to Backend Dev"
    priority = 210
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.frontend_dev_namespace.uuid
    ]
    dst_smart_groups = [
      aviatrix_smart_group.backend_dev_namespace.uuid
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Frontend Dev Deny All"
    priority = 250
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      aviatrix_smart_group.frontend_dev_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Backend Prod"
    priority = 300
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.backend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
      aviatrix_web_group.datadog.id
    ]

    logging = true
  }

  policies {
    name     = "Backend Prod to Shared Services"
    priority = 310
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.backend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      aviatrix_smart_group.shared_services.uuid
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Frontend Prod Deny All"
    priority = 350
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      aviatrix_smart_group.backend_prod_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Backend Dev Gatus Service"
    priority = 400
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.backend_dev_gatus_service.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
      aviatrix_web_group.backend_dev_gatus_service_egress.id
    ]

    logging = true
  }

  policies {
    name     = "Backend Dev to Shared Services"
    priority = 410
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.backend_dev_namespace.uuid
    ]
    dst_smart_groups = [
      aviatrix_smart_group.shared_services.uuid
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Backend Dev Deny All"
    priority = 450
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      aviatrix_smart_group.backend_dev_namespace.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Shared Services"
    priority = 500
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.shared_services.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
      aviatrix_web_group.datadog.id
    ]

    logging = true
  }

  policies {
    name     = "Shared Services to Backend"
    priority = 510
    action   = "PERMIT"
    protocol = "TCP"
    port_ranges {
            lo = 443
            hi = 0
    }
    src_smart_groups = [
      aviatrix_smart_group.shared_services.uuid
    ]
    dst_smart_groups = [
      aviatrix_smart_group.backend_prod_namespace.uuid,
      aviatrix_smart_group.backend_dev_namespace.uuid
    ]

    logging = true
  }

  policies {
    name     = "ZT Egress - Shared Services Deny All"
    priority = 550
    action   = "DENY"
    protocol = "ANY"
    src_smart_groups = [
      aviatrix_smart_group.shared_services.uuid
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    logging = true
  }


  policies {
    name     = "ZT Egress - Permit All - Temp for Monitoring"
    priority = 900
    action   = "PERMIT"
    protocol = "ANY"
    src_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000001"
    ]

    web_groups = [
      "def000ad-0000-0000-0000-000000000002"
    ]

    logging = true
  }

  policies {
    name     = "Deny - Catch All"
    priority = 1000
    action   = "PERMIT"
    protocol = "ANY"
    src_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]
    dst_smart_groups = [
      "def000ad-0000-0000-0000-000000000000"
    ]

    logging = true
    exclude_sg_orchestration = true
  }

}
