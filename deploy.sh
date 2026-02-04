#!/bin/bash

# Install ArgoCD
./install-argocd.sh &

# Install Jenkins
./install-jenkins.sh &

# Deploy the application using Helm
helm upgrade --install demo-app ./app-demo

# Apply ArgoCD Application
kubectl apply -f argocd-application.yaml

# Check deployment status
kubectl get pods,svc,ingress

echo "Deployment completed!"
echo "Jenkins: http://localhost:8080"
echo "ArgoCD: https://localhost:8080"
echo "LoadBalancer service: kubectl get svc demo-app"
echo "Ingress: kubectl get ingress demo-app-ingress"