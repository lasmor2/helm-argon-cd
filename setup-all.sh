#!/bin/bash

echo "Setting up complete CI/CD pipeline..."

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Jenkins
echo "Installing Jenkins..."
kubectl create namespace jenkins
kubectl apply -f jenkins/jenkins-secrets.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml

# Wait for services
echo "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Deploy application
echo "Deploying application..."
helm upgrade --install demo-app ./app-demo
kubectl apply -f argocd-application.yaml

# Get passwords
echo "=== ACCESS INFORMATION ==="
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "Jenkins admin password:"
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
echo ""

echo "=== ACCESS URLS ==="
echo "Jenkins: http://jenkins.local or kubectl port-forward svc/jenkins -n jenkins 8080:8080"
echo "ArgoCD: https://localhost:8080 via kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "App: kubectl get svc demo-app"

echo "Setup completed!"