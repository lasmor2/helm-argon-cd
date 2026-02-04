# Manual Setup Commands

## 1. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## 2. Install Jenkins

```bash
kubectl create namespace jenkins
kubectl apply -f jenkins/jenkins-secrets.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml
```

## 3. Get Passwords

```bash
# ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Jenkins admin password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

## 4. Deploy Application

```bash
helm upgrade --install demo-app ./app-demo
kubectl apply -f argocd-application.yaml
```

## 5. Access Services

- **Jenkins**: http://jenkins.local or `kubectl port-forward -n jenkins svc/jenkins 8080:8080`
- **ArgoCD**: https://localhost:8080 via `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- **App LoadBalancer**: `kubectl get svc demo-app`
- **App Ingress**: Add `demo.local` to hosts file

## 6. Configure Jenkins

1. Install suggested plugins
2. Create admin user
3. Configure GitHub webhook: `http://jenkins.local/github-webhook/`
4. Update credentials in `jenkins-secrets.yaml` with your actual values

## Pipeline Flow

1. Code push to GitHub triggers Jenkins
2. Jenkins builds Docker image
3. Pushes to Docker Hub
4. Updates Helm values with new tag
5. ArgoCD syncs changes automatically
