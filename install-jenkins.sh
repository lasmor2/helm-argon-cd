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
echo ""

echo "Jenkins installed successfully!"
echo "Use ./port-forward.sh to access Jenkins UI"