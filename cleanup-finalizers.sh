#!/bin/bash

# finalize_namespaces.sh - Script to finalize stuck namespaces on multiple clusters

set -e  # Exit on any error

# Configuration
NAMESPACES=("prod" "dev")
CLUSTERS=(
    "gke_csp-gcp-saustin_us-west1-a_gke-frontend-cluster"
    "gke_csp-gcp-saustin_us-west1-a_gke-backend-cluster"
)
PROXY_PORT=8080

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if namespace exists and is stuck
check_namespace_stuck() {
    local namespace=$1
    local status=$(kubectl get namespace "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    if [[ "$status" == "NotFound" ]]; then
        return 1  # Namespace doesn't exist
    elif [[ "$status" == "Terminating" ]]; then
        return 0  # Namespace is stuck
    else
        return 2  # Namespace exists but not stuck
    fi
}

# Function to create finalize JSON file
create_finalize_json() {
    local namespace=$1
    local json_file="finalize-${namespace}.json"
    
    cat > "$json_file" << EOF
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "$namespace"
  },
  "spec": {
    "finalizers": []
  }
}
EOF
    echo "$json_file"
}

# Function to finalize namespace using curl
finalize_namespace() {
    local namespace=$1
    local json_file=$2
    
    print_status "Starting kubectl proxy on port $PROXY_PORT..."
    kubectl proxy --port=$PROXY_PORT &
    local proxy_pid=$!
    
    # Wait for proxy to start
    sleep 2
    
    print_status "Finalizing namespace '$namespace'..."
    
    # Use curl to finalize the namespace
    local response=$(curl -s -X PUT "http://localhost:$PROXY_PORT/api/v1/namespaces/$namespace/finalize" \
        -H "Content-Type: application/json" \
        -d @"$json_file" 2>&1)
    
    local curl_exit_code=$?
    
    # Kill the proxy
    kill $proxy_pid 2>/dev/null || true
    wait $proxy_pid 2>/dev/null || true
    
    if [[ $curl_exit_code -eq 0 ]]; then
        print_success "Successfully finalized namespace '$namespace'"
        return 0
    else
        print_error "Failed to finalize namespace '$namespace': $response"
        return 1
    fi
}

# Function to cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f finalize-*.json
}

# Main function with informative output
main() {
    echo "🔍 Scanning ${#CLUSTERS[@]} cluster(s) for stuck namespaces..."
    echo "📋 Target namespaces: ${NAMESPACES[*]}"
    echo ""
    
    for i in "${!CLUSTERS[@]}"; do
        cluster="${CLUSTERS[$i]}"
        echo "🔄 Processing cluster $((i+1))/${#CLUSTERS[@]}: $(basename "$cluster")"
        
        # Switch context
        if ! kubectl config use-context "$cluster" >/dev/null 2>&1; then
            echo "   ❌ Failed to switch to cluster: $cluster"
            continue
        fi
        echo "   ✅ Connected to cluster"
        
        # Process namespaces
        local found_stuck=false
        for j in "${!NAMESPACES[@]}"; do
            namespace="${NAMESPACES[$j]}"
            
            # Check if namespace exists and get its status
            if kubectl get namespace "$namespace" >/dev/null 2>&1; then
                status=$(kubectl get namespace "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)
                if [[ "$status" == "Terminating" ]]; then
                    echo "   🚨 Found stuck namespace: $namespace (status: $status)"
                    found_stuck=true
                    
                    # Call the cleanup function here
                    # Create the JSON file first
                    json_file=$(create_finalize_json "$namespace")
                    echo "   📝 Created finalize JSON: $json_file"
    
                    # Now call finalize with both parameters
                    if finalize_namespace "$namespace" "$json_file"; then
                        echo "   ✅ Successfully processed stuck namespace: $namespace"
                    else
                        echo "   ❌ Failed to process namespace: $namespace"
                    fi
                else
                    echo "   ✅ Namespace $namespace exists and is healthy (status: ${status:-Active})"
                fi
            else
                echo "   ℹ️  Namespace $namespace does not exist (already cleaned up)"
            fi
        done
        
        if [[ "$found_stuck" == false ]]; then
            echo "   ✅ No stuck namespaces found in this cluster"
        fi
        echo ""
    done
    
    echo "🎉 Finished processing all clusters"
}

# Your arrays and other setup
CLUSTERS=($(kubectl config get-contexts -o name | grep gke))
NAMESPACES=("prod" "dev")


# Help function
show_help() {
    cat << EOF
Namespace Finalization Script

This script checks for stuck namespaces (in Terminating state) across multiple
Kubernetes clusters and attempts to finalize them using the Kubernetes API.

Usage: $0 [OPTIONS]

Options:
    -h, --help     Show this help message
    --dry-run      Show what would be done without making changes
    
The script will process the following:
- Namespaces: ${NAMESPACES[*]}
- Clusters: ${CLUSTERS[*]}

Requirements:
- kubectl configured with access to target clusters
- Network connectivity to Kubernetes API servers
EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --dry-run)
        print_warning "DRY RUN MODE - No changes will be made"
        # Add dry-run logic if needed
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac