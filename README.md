
# Aviatrix Kubernetes Firewall Demo with GKE

# Prerequisites

gcloud cli
bash shell (needed for the finializer script - if using VS Code on Windows, use gitbash instead of powershell)
google account onboarded to your controller
8.1 controller - required for CRD webgroup policies
Feature flags for k8s and k8s_dcf_policies enabled
terraform.tfvars file with your specific variables added - Check terraform.tfvars.example

# Before doing a plan/apply, get authenticated with google:

gcloud auth login

# To run kubectl commands, first get credentialed to the cluster you want to manage:

gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a

# Common commands to check

kubectl get namespaces

kubectl get pods -A

kubectl get pods -n prod

# To test CRD webgroup policies you first need to enable by pushing this:

gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a

kubectl apply -f networking.aviatrix.com_webgrouppolicies.yaml

# You can check if it was already applied by checking the api-resources on the cluster

kubectl api-resources | grep aviatrix

webgrouppolicies                                        networking.aviatrix.com/v1alpha1   true         WebgroupPolicy

# After that has been applied you can now push the webgroup policy, open it first to view the rules

kubectl create -f frontend-prod-egress.yaml

# Immediately after the create, it will show up in CoPilot under SmartGroups and Webgroups. You can then make updates to the policy and see them reflected immediately in CoPilot. Recommend just adding or removing a domain to keep it simple.

kubectl replace -f frontend-prod-egress.yaml

# Check applied policies

kubectl get webgrouppolicies -A

# Since the webgroup policies are applied after running the Terraform, you need to go into rule 100 and change the webgroup from datadog to the one that shows after you create the CRD. That way you can update the CRD and see the impact to traffic on the Gatus healthchecks.

# For showing how we react to services scaling up and down, you can spin up a replica pod. First go into CoPilot, groups, and click on the Frontend Prod Namespace smartgroup. Show that there is only 1 accounting pod showing. Then run this kubectl command to increase the replicas from 1 to 2:

kubectl get pods -n prod
kubectl scale deployment accounting-frontend-web-prod --replicas=2 -n prod
kubectl get pods -n prod

# Now go back in to CoPilot, refresh the page and you will see a 2nd accounting pod show up in the list.

# If you want to do any changes to the DCF rules, you need to remove them all first, make changes and then push them back. Easiest way to do this is to comment out the policies section in 110-Aviatrix-DCF.tf and do a terraform apply. This will remove the rules, you can then uncomment, make any changes and do another apply to add them back.

# If you want to do any custom tests from one of the clusters or namespaces, this container is very helpful, as the containers running in this lab dont have shells/tools

kubectl run debug-frontend-prod -n prod --image=nicolaka/netshoot --restart=Never -it -- bash

# When doing a destroy, there are a few things to be aware of. First, you need to remove the custom webgroup from the rule 100 policy, or you will get an error due to. Also, havent figured out a way to fix an issue with prod/dev namespaces getting stuck with finalizers. You will see if get stuck waiting on deleting the namespaces and you can run this script to clear them.

./cleanup-finalizers.sh



