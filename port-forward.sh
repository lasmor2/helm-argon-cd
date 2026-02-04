#!/bin/bash

# Function to start port-forward with retry
start_portforward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    local name=$5
    
    echo "Starting port-forward for $name..."
    while true; do
        kubectl port-forward svc/$service -n $namespace $local_port:$remote_port --address=0.0.0.0
        echo "Port-forward for $name disconnected. Retrying in 5 seconds..."
        sleep 5
    done
}

# Kill existing port-forwards
pkill -f "kubectl port-forward" 2>/dev/null

# Start ArgoCD port-forward in background
start_portforward "argocd-server" "argocd" "8080" "443" "ArgoCD" &

# Start Jenkins port-forward in background  
start_portforward "jenkins" "jenkins" "8081" "8080" "Jenkins" &

echo "Port-forwards started:"
echo "ArgoCD: https://localhost:8080"
echo "Jenkins: http://localhost:8081"
echo ""
echo "Press Ctrl+C to stop all port-forwards"

# Wait for interrupt
trap 'pkill -f "kubectl port-forward"; exit' INT
wait