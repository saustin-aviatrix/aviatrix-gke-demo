#!/bin/bash
apt-get update
apt-get install -y docker.io

# Create Gatus config
cat > /tmp/gatus-config.yaml << 'EOF'
web:
  port: 8080

ui:
  title: "Shared Services Compute Gatus"
  description: "Status page for GKE Demo"
  header: "Shared Service Health Dashboard"
  logo: "https://aviatrix.com/images/logo/aviatrix.svg"

endpoints:

%{ if try(length(Frontend), 0) > 0 ~}
%{ for item in Frontend ~}
  - name: "TCP-80-${item.service_name}"
    group: "Frontend"
    url: "tcp://${item.endpoint}:80"
    interval: 30s
    conditions:
      - "[CONNECTED] == true"

  - name: "TCP-443-${item.service_name}"
    group: "Frontend"
    url: "tcp://${item.endpoint}:443"
    interval: 30s
    conditions:
      - "[CONNECTED] == true"

%{ endfor ~}
%{ endif ~}

%{ if try(length(Backend), 0) > 0 ~}
%{ for item in Backend ~}
  - name: "TCP-80-${item.service_name}"
    group: "Backend"
    url: "tcp://${item.endpoint}:80"
    interval: 30s
    conditions:
      - "[CONNECTED] == true"

  - name: "TCP-443-${item.service_name}"
    group: "Backend"
    url: "tcp://${item.endpoint}:443"
    interval: 30s
    conditions:
      - "[CONNECTED] == true"

%{ endfor ~}
%{ endif ~}

  - name: "api.datadoghq.com-https"
    group: "Egress"
    url: "https://api.datadoghq.com"
    interval: 60s
    conditions:
      - "[STATUS] == 200"

  - name: "pypi.org-https"
    group: "Egress"
    url: "https://pypi.org"
    interval: 60s
    conditions:
      - "[STATUS] == 200"

  - name: "aws.amazon.com-https"
    group: "Egress"
    url: "https://aws.amazon.com"
    interval: 60s
    conditions:
      - "[STATUS] == 200"

  - name: "HTTP Traffic"
    group: "Egress"
    url: "http://ipv4.icanhazip.com"
    interval: 60s
    conditions:
      - "[STATUS] == 200"  

  - name: "malware.net-https"
    group: "Egress"
    url: "https://malware.net"
    interval: 60s
    conditions:
      - "[STATUS] == 200"

  - name: "Geoblock Test"
    group: "Threats"
    url: "icmp://www.irna.ir"
    interval: 30s
    conditions:
      - "[RESPONSE_TIME] < 5000"
      - "[CONNECTED] == true"

  - name: "Threat Feed Test"
    group: "Threats"
    url: "icmp://102.130.117.167"
    interval: 30s
    conditions:
      - "[RESPONSE_TIME] < 5000"
      - "[CONNECTED] == true"

  - name: "Geoblock Test - NK"
    group: "Threats"
    url: "icmp://5.62.56.160"
    interval: 30s
    conditions:
      - "[RESPONSE_TIME] < 5000"
      - "[CONNECTED] == true"
EOF

# Run Gatus
docker run -d -p 80:8080 -p 443:8080 -p 8080:8080 -v /tmp/gatus-config.yaml:/config/config.yaml twinproduction/gatus:latest