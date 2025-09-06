
# Aviatrix Kubernetes Firewall Demo with GKE

### Prerequisites

  * **gcloud CLI**
  * **bash shell**: Needed for the finalizer script. If you're using VS Code on Windows, use **Git Bash** instead of PowerShell.
  * **Google account**: Must be onboarded to your Aviatrix Controller.
  * **Aviatrix Controller 8.1**: Required for CRD webgroup policies.
  * **Feature Flags**: The **k8s** and **k8s\_dcf\_policies** feature flags must be enabled on the controller.
  * **`terraform.tfvars` file**: Ensure you've created this file and added your specific variables. Check the **`terraform.tfvars.example`** file for guidance.

-----

### Before You Begin

1.  Authenticate with Google Cloud:
    ```bash
    gcloud auth login
    ```

### Once you have built the environment

1. Go into CoPilot DCF and check the last 2 rules. These are denies, but left as permits so it doesnt block traffic if you have other rules in place. You can check the monitor logs to see if anything is hitting those rules that you dont expect. Once you have confirmed, change those 2 rules to deny.

2.  Get credentials for the cluster you want to manage. Replace `gke-frontend-cluster` and `us-west1-a` with your cluster's name and zone.
    ```bash
    gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a
    ```

-----

### Common `kubectl` Commands

  * Check all namespaces:
    ```bash
    kubectl get namespaces
    ```
  * List all pods in all namespaces:
    ```bash
    kubectl get pods -A
    ```
  * List pods in a specific namespace (e.g., `prod`):
    ```bash
    kubectl get pods -n prod
    ```

-----

### Working with CRD Webgroup Policies

#### 1\. Enable CRD Policies

To enable custom resource definition (CRD) policies, apply the webgroup policy manifest.

```bash
gcloud container clusters get-credentials gke-frontend-cluster --zone=us-west1-a
kubectl apply -f networking.aviatrix.com_webgrouppolicies.yaml
```

You can verify if it's already applied by checking the API resources on the cluster.

```bash
kubectl api-resources | grep aviatrix
```

You should see output like this:

```
webgrouppolicies                                        networking.aviatrix.com/v1alpha1   true         WebgroupPolicy
```

#### 2\. Create and Update Policies

After applying the manifest, you can create a webgroup policy. Open `frontend-prod-egress.yaml` to view the rules first.

```bash
kubectl create -f frontend-prod-egress.yaml
```

Immediately after creation, the policy will appear in Aviatrix CoPilot under **SmartGroups** and **Webgroups**. You can then make updates to the policy and see them reflected immediately in CoPilot. It's recommended to just add or remove a domain to keep it simple.

```bash
kubectl replace -f frontend-prod-egress.yaml
```

#### 3\. Check Applied Policies

```bash
kubectl get webgrouppolicies -A
```

#### Important Note on CRD Policies

Since the webgroup policies are applied after running Terraform, you need to go into **rule 100** and change the webgroup from `datadog` to the one that appears after you create the CRD `frontend-prod-egress.yaml`. This way, you can update the CRD and see the impact on reachable domains via Gatus health checks.

-----

### Demonstrating Service Scaling

To show how Aviatrix reacts to services scaling, you can spin up a replica pod.

1.  In Aviatrix CoPilot, navigate to **Groups** and click on the **Frontend Prod Namespace** smart group. You will see there is only one accounting pod.
2.  Run the following command to increase the replicas from 1 to 2:
    ```bash
    kubectl get pods -n prod
    kubectl scale deployment accounting-frontend-web-prod --replicas=2 -n prod
    ```
3.  Check the pods again to confirm the new replica:
    ```bash
    kubectl get pods -n prod
    ```
4.  Go back to CoPilot, refresh the page, and you will see a second accounting pod appear in the list.

-----

### Modifying Distributed Cloud Firewall (DCF) Rules

If you need to make changes to the DCF rules, you must remove them first, make your changes, and then push them back.
The easiest way to do this is to follow this process:

1. Comment out the relevant policy block(s) in 110-Aviatrix-DCF.tf.

2. Run terraform apply to remove the old rules.

3. Uncomment the block(s), make your changes, and save the file.

4. Run terraform apply again to add the new rules.

-----

### Custom Tests

If you want to run custom tests from one of the clusters or namespaces, the `nicolaka/netshoot` container is very helpful, as the containers in this lab don't have a shell or tools.

```bash
kubectl run debug-frontend-prod -n prod --image=nicolaka/netshoot --restart=Never -it -- bash
```

-----

### Destroying Resources

When running `terraform destroy`, be aware of a few things:

  * You must first **remove the custom webgroup from the rule 100 policy**, or you will get an error.
  * You may encounter an issue with the `prod` and `dev` namespaces getting stuck with finalizers. You will see the destroy process get stuck while waiting for the namespaces to be deleted.
  * To resolve this, you can run the provided script to clear the finalizers.
    ```bash
    ./cleanup-finalizers.sh
    ```

!(https://github.com/saustin-aviatrix/aviatrix-gke-demo/blob/main/GKE-Demo-Diagram.png?raw=true)