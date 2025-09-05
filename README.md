
# Aviatrix Kubernetes Firewall Demo with GKE

This repository demonstrates Aviatrix Kubernetes firewall capabilities using Google Kubernetes Engine (GKE) clusters with Custom Resource Definitions (CRDs) for webgroup policies.

## Prerequisites

Before getting started, ensure you have the following:

- **gcloud CLI** - Google Cloud command-line interface
- **bash shell** - Required for the finalizer script (if using VS Code on Windows, use Git Bash instead of PowerShell)
- **Google account** - Must be onboarded to your Aviatrix controller
- **Aviatrix Controller 8.1+** - Required for CRD webgroup policies
- **Feature flags enabled** - Both `k8s` and `k8s_dcf_policies` must be enabled
- **terraform.tfvars file** - Configure with your specific variables (see `terraform.tfvars.example`)

## Initial Setup

### 1. Authenticate with Google Cloud

```bash
gcloud auth login
2. Connect to your GKE cluster
bash
Copy code
gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a
Common kubectl Commands
Check cluster status and resources:

bash
Copy code
# View all namespaces
kubectl get namespaces

# View all pods across namespaces
kubectl get pods -A

# View pods in specific namespace
kubectl get pods -n prod
Setting Up CRD Webgroup Policies
1. Apply the Aviatrix CRD
bash
Copy code
# Ensure you're connected to the correct cluster
gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a

# Apply the CRD
kubectl apply -f networking.aviatrix.com_webgrouppolicies.yaml
2. Verify CRD Installation
bash
Copy code
kubectl api-resources | grep aviatrix
Expected output:

bash
Copy code
webgrouppolicies                                        networking.aviatrix.com/v1alpha1   true         WebgroupPolicy
3. Create and Manage Webgroup Policies
bash
Copy code
# Review the policy before applying
cat frontend-prod-egress.yaml

# Create the webgroup policy
kubectl create -f frontend-prod-egress.yaml

# Update existing policy (after making changes)
kubectl replace -f frontend-prod-egress.yaml

# View all applied policies
kubectl get webgrouppolicies -A
Note: After applying webgroup policies, update rule 100 in the Aviatrix controller to change the webgroup from "datadog" to the newly created webgroup. This allows you to see the impact of CRD updates on Gatus health checks.

Demonstrating Service Scaling
To showcase how Aviatrix reacts to services scaling:

1. Check Current Pod Count
bash
Copy code
kubectl get pods -n prod
2. Scale the Application
bash
Copy code
# Scale from 1 to 2 replicas
kubectl scale deployment accounting-frontend-web-prod --replicas=2 -n prod

# Verify scaling
kubectl get pods -n prod
3. View in CoPilot
Navigate to CoPilot → Groups
Click on "Frontend Prod Namespace" smartgroup
Refresh the page to see the additional pod
Modifying DCF Rules
To make changes to Distributed Cloud Firewall (DCF) rules:

Comment out the policies section in 110-Aviatrix-DCF.tf
Run terraform apply to remove existing rules
Uncomment and modify the policies as needed
Run terraform apply again to apply the updated rules
Debugging and Testing
For custom testing within clusters or namespaces, use this debug container:

bash
Copy code
kubectl run debug-frontend-prod -n prod --image=nicolaka/netshoot --restart=Never -it -- bash
This provides a container with networking tools for troubleshooting.

Cleanup and Destroy
Important Notes
When destroying the infrastructure:

Remove custom webgroups from rule 100 policy first to avoid errors
Handle stuck namespaces - prod/dev namespaces may get stuck with finalizers
Cleanup Stuck Namespaces
If namespaces get stuck in "Terminating" status during destruction:

bash
Copy code
./cleanup-finalizers.sh
This script will clear the finalizers and allow proper namespace deletion.

Troubleshooting
Common Issues
Namespace stuck in Terminating: Run the cleanup-finalizers script
CRD not found: Ensure the CRD was applied successfully before creating policies
Authentication errors: Verify gcloud auth login was successful
Cluster connection issues: Confirm the correct cluster name and zone
Verification Commands
bash
Copy code
# Check cluster connection
kubectl cluster-info

# Verify CRD installation
kubectl api-resources | grep aviatrix

# Check policy status
kubectl get webgrouppolicies -A



