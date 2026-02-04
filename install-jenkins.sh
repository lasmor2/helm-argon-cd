#!/bin/bash

# Install Jenkins
kubectl create namespace jenkins
kubectl apply -f jenkins/jenkins-secrets.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml

# Wait for Jenkins to be ready
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Get Jenkins admin password
echo "Jenkins admin password:"
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# Port forward to access Jenkins UI
echo "Access Jenkins at http://localhost:8080"
kubectl port-forward svc/jenkins -n jenkins 8080:8080