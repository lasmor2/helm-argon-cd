# Helm ArgoCD CI/CD Pipeline Setup Guide

## Table of Contents

1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Components Breakdown](#components-breakdown)
5. [Step-by-Step Quick Setup](#step-by-step-quick-setup)
6. [Step-by-Step Manual Setup](#step-by-step-manual-setup)
7. [Accessing Services](#accessing-services)
8. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
9. [Troubleshooting](#troubleshooting)

---

## Project Overview

This is a complete **CI/CD pipeline** that automates the deployment of a Node.js application using:

- **Jenkins** for continuous integration (building and pushing Docker images)
- **ArgoCD** for continuous deployment (GitOps-based deployment)
- **Helm** for Kubernetes application templating
- **Docker** for containerization
- **Kubernetes** for orchestration

The pipeline flow is: **GitHub Push → Jenkins Build → Docker Hub Push → ArgoCD Sync → Kubernetes Deployment**

---

## Project Structure

```
helm-argon-cd/
├── index.js                          # Node.js Express application
├── package.json                      # Node.js dependencies
├── Dockerfile                        # Docker image definition
├── docker-compose.yml                # Local development setup
├── Jenkinsfile                       # Jenkins CI/CD pipeline configuration
├── .env                              # Environment variables
├── .sh/                              # Shell scripts for setup
│   ├── setup-all.sh                 # Complete setup automation
│   ├── install-jenkins.sh            # Jenkins-only installation
│   ├── install-argocd.sh             # ArgoCD-only installation
│   ├── deploy.sh                     # Manual deployment script
│   ├── port-forward.sh               # Linux/Mac port forwarding
│   └── port-forward.bat              # Windows port forwarding
├── app-demo/                         # Helm chart for the application
│   ├── Chart.yaml                   # Helm chart metadata
│   ├── value.yml                    # Helm values (image tag, replicas, etc.)
│   └── templates/                   # Kubernetes resource templates
│       ├── deployment.yaml          # Kubernetes Deployment
│       ├── service.yaml             # Kubernetes Service
│       └── ingress.yaml             # Kubernetes Ingress
├── jenkins/                          # Jenkins configuration
│   ├── jenkins-deployment.yaml      # Jenkins Kubernetes Deployment
│   ├── jenkins-config.yaml          # Jenkins configuration
│   └── jenkins-secrets.yaml         # Jenkins credentials
└── argoncd/                          # ArgoCD configuration
    └── argocd-application.yaml      # ArgoCD Application resource
```

---

## Prerequisites

### Required Software

- **Kubernetes Cluster** (Kind, Minikube, EKS, etc.) - running and accessible via `kubectl`
- **kubectl** - command-line tool for Kubernetes
- **Helm 3** - package manager for Kubernetes
- **Docker** - for building and running containers
- **Git** - for version control
- **GitHub Account** - for repository and webhook setup
- **Docker Hub Account** - for pushing Docker images

### Verify Prerequisites

```bash
# Check Kubernetes cluster
kubectl cluster-info
kubectl get nodes

# Check kubectl version
kubectl version --client

# Check Helm version
helm version

# Check Docker version
docker --version
```

---

## Components Breakdown

### 1. Node.js Application (index.js)

A simple Express.js server with three endpoints:

- `GET /` - Returns "Hello, World!"
- `GET /status` - Returns JSON status with timestamp
- `GET /health` - Health check endpoint (returns "Healthy")

Port: 3000 (configurable via `PORT` env variable)

### 2. Docker Setup

- **Dockerfile** - Multi-stage build using Node.js 18
- **docker-compose.yml** - Local development environment with Jenkins LTS service
- Builds image as `demo-app` for local testing

### 3. Helm Chart (app-demo/)

Kubernetes deployment template with customizable values:

- **Chart.yaml** - Chart metadata (name, version, description)
- **value.yml** - Default values:
  - Image repository: `lasmor2025/demo-app`
  - Image tag: `v2` (updated automatically by Jenkins)
  - Replicas: 1
  - Service type: LoadBalancer
  - Service port: 80 → 3000 (internal)
  - Ingress enabled for `demo.local` hostname

### 4. Jenkins Pipeline (Jenkinsfile)

Automated CI/CD pipeline with stages:

1. **Checkout** - Clones latest code from GitHub
2. **Build** - Builds Docker image with build number tag
3. **Push to Docker Hub** - Authenticates and pushes image
4. **Update Helm Values** - Updates image tag in `value.yml`
5. Post-action: Docker logout for security

Environment Variables:

- `DOCKER_HUB_REPO` - Docker Hub repository path
- `DOCKER_HUB_CREDENTIALS` - Docker Hub login credentials
- `GITHUB_CREDENTIALS` - GitHub authentication

Triggers:

- GitHub push events (webhooks)

### 5. ArgoCD Application

GitOps deployment configuration:

- Watches GitHub repository for changes
- Automatically syncs Kubernetes with Git state
- Prune disabled resources
- Self-healing enabled
- Source: `https://github.com/lasmor2/helm-argon-cd.git` → `app-demo/` path
- Destination: Default Kubernetes cluster

---

## Step-by-Step Quick Setup

### Automated Setup (Linux/Mac)

If you have a Kubernetes cluster running and want automated setup:

```bash
# Make script executable
chmod +x .sh/setup-all.sh

# Run complete setup
./.sh/setup-all.sh
```

This script will:

1. Create ArgoCD namespace and install ArgoCD
2. Create Jenkins namespace and deploy Jenkins
3. Wait for both services to be ready
4. Deploy the application via Helm
5. Apply ArgoCD Application resource
6. Display admin credentials and access URLs

---

## Step-by-Step Manual Setup

### Step 1: Verify Kubernetes Cluster

```bash
# Check cluster is accessible
kubectl cluster-info

# View available nodes
kubectl get nodes

# Check all namespaces
kubectl get pods -A
```

**Expected Output:** Should show cluster info and at least one node in "Ready" state.

---

### Step 2: Install ArgoCD

#### 2.1 Create ArgoCD Namespace

```bash
kubectl create namespace argocd
```

#### 2.2 Install ArgoCD using official manifest

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 2.3 Wait for ArgoCD to be ready

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

#### 2.4 Verify ArgoCD installation

```bash
kubectl get all -n argocd
```

**Expected Output:** Should show argocd-server, argocd-repo-server, argocd-controller-manager pods in "Running" state.

#### 2.5 Get ArgoCD admin password

```bash
# On Linux/Mac
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# On Windows PowerShell
$encodedPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
```

**Save this password** - you'll need it to log in to ArgoCD.

---

### Step 3: Install Jenkins

#### 3.1 Create Jenkins Namespace

```bash
kubectl create namespace jenkins
```

#### 3.2 Create Jenkins Secrets (GitHub and Docker Hub credentials)

First, edit `jenkins/jenkins-secrets.yaml` and replace:

- `GITHUB_USERNAME` - Your GitHub username
- `GITHUB_TOKEN` - Your GitHub personal access token
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password
- `GIT_EMAIL` - Your email for Git commits
- `GIT_USERNAME` - Your name for Git commits

Then apply it:

```bash
kubectl apply -f jenkins/jenkins-secrets.yaml
```

#### 3.3 Deploy Jenkins

```bash
kubectl apply -f jenkins/jenkins-deployment.yaml
```

#### 3.4 Wait for Jenkins to be ready

```bash
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins
```

#### 3.5 Verify Jenkins installation

```bash
kubectl get all -n jenkins
```

**Expected Output:** Jenkins Deployment, Pod, Service, and PVC should all be running.

#### 3.6 Get Jenkins admin password

```bash
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

**Save this password** - you'll need it for initial Jenkins login.

---

### Step 4: Deploy Your Application

#### 4.1 Update Helm Chart values (Optional)

Edit `app-demo/value.yml` if needed:

- Change `image.repository` to your Docker Hub username
- Change `image.tag` to desired version
- Modify `replicaCount` if needed
- Change `ingress.host` to your hostname

#### 4.2 Deploy application using Helm

```bash
helm upgrade --install demo-app ./app-demo
```

**Expected Output:**

```
Release "demo-app" has been upgraded/installed successfully.
```

#### 4.3 Verify the deployment

```bash
kubectl get all -n default
```

**Expected Output:** Deployment, Pod, and Service should show as ready.

Get the LoadBalancer IP:

```bash
kubectl get svc demo-app
```

---

### Step 5: Apply ArgoCD Application Resource

#### 5.1 Update ArgoCD Application (if using your own repo)

Edit `argoncd/argocd-application.yaml` and update:

- `repoURL` - Change to your GitHub repository URL
- `source.path` - Path to Helm chart (default is `app-demo`)
- `destination.namespace` - Target namespace for deployment

#### 5.2 Apply the ArgoCD Application

```bash
kubectl apply -f argoncd/argocd-application.yaml
```

**Expected Output:**

```
application.argoproj.io/demo-app created
```

#### 5.3 Verify ArgoCD Application

```bash
kubectl get applications -n argocd
kubectl describe application demo-app -n argocd
```

---

## Accessing Services

### Access ArgoCD UI

#### Option 1: Port Forwarding (Recommended for Testing)

**Linux/Mac:**

```bash
kubectl port-forward svc/argocd-server -n argocd 8083:443
```

**Windows:**

```powershell
kubectl port-forward svc/argocd-server -n argocd 8083:443
```

Then open browser: `https://localhost:8083`

**Login:**

- Username: `admin`
- Password: (from Step 2.5)

**Note:** Browser will show certificate warning (self-signed). Click "Advanced" → "Proceed anyway"

#### Option 2: Using Ingress (Production-like)

Set up an Ingress Controller first, then access via `https://argocd.your-domain.com`

---

### Access Jenkins UI

#### Option 1: Port Forwarding

**Linux/Mac:**

```bash
kubectl port-forward svc/jenkins -n jenkins 8080:8080
```

**Windows:**

```powershell
kubectl port-forward svc/jenkins -n jenkins 8080:8080
```

Then open browser: `http://localhost:8080`

**Login:**

- Username: `admin`
- Password: (from Step 3.6)

#### Option 2: Using Ingress

Configure Ingress to access Jenkins via hostname.

---

### Access Your Application

#### Option 1: Port Forwarding

```bash
kubectl port-forward svc/demo-app 3000:80
```

Then open browser: `http://localhost:3000`

Endpoints:

- `http://localhost:3000/` - Hello message
- `http://localhost:3000/status` - Status JSON
- `http://localhost:3000/health` - Health check

#### Option 2: LoadBalancer IP

```bash
kubectl get svc demo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then access via that IP address and port 80.

#### Option 3: Ingress

Add to your `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 demo.local
```

Then access: `http://demo.local`

---

## CI/CD Pipeline Configuration

### Prerequisites for CI/CD

1. **GitHub Repository** - Your forked/cloned repo
2. **Docker Hub Account** - For pushing images
3. **Jenkins Running** - With access via port-forward or Ingress

### Step 1: Configure Jenkins Credentials

1. Open Jenkins UI at `http://localhost:8080`
2. Go to **Manage Jenkins** → **Manage Credentials**
3. Click **Global** credentials domain
4. **Add Credentials** (top left):

#### Add Docker Hub Credentials

- Kind: **Username with password**
- Username ID: `dockerhub-credentials`
- Username Field: Your Docker Hub username
- Password Field: Your Docker Hub password (or access token)
- Click **Create**

#### Add GitHub Credentials

- Kind: **Username with password**
- Username ID: `github-credentials`
- Username Field: Your GitHub username
- Password Field: Your GitHub personal access token
- Click **Create**

### Step 2: Configure GitHub Webhook

1. Go to your GitHub repository → **Settings** → **Webhooks**
2. Click **Add webhook**
3. Fill in:
   - **Payload URL:** `http://jenkins.local/github-webhook/` (or your Jenkins IP:port)
   - **Content type:** `application/json`
   - **Which events?** Select **Push events**
   - Check **Active**
4. Click **Add webhook**

### Step 3: Create Jenkins Pipeline Job

1. In Jenkins UI, click **New Item**
2. Enter job name: `demo-app-pipeline`
3. Select **Pipeline** job type
4. Click **OK**
5. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: Your GitHub repo URL
   - Credentials: Select `github-credentials`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
6. Click **Save**

### Step 4: Test the Pipeline

**Trigger manually or via GitHub:**

```bash
# Make a change and push to GitHub
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

Jenkins should automatically trigger the pipeline job.

### Step 5: Monitor Pipeline Execution

1. In Jenkins UI, click on the job
2. Click **Build History** to see builds
3. Click on a build number to see logs
4. View ArgoCD to see automatic deployment

---

## CI/CD Pipeline Flow Detailed

```
GitHub Push
    ↓
Jenkins Webhook (githubPush trigger)
    ↓
Stage: Checkout
  └─ git clone with credentials
    ↓
Stage: Build
  └─ docker build -t repo:v{BuildNumber}
    ↓
Stage: Push to Docker Hub
  └─ docker login → docker push
    ↓
Stage: Update Helm Values
  └─ Update app-demo/value.yml with new image tag
  └─ git commit and push
    ↓
GitHub Repository Updated
  └─ value.yml changed on main branch
    ↓
ArgoCD Detects Change
  └─ Monitors git repository for changes
    ↓
ArgoCD Syncs
  └─ Runs: helm upgrade --install demo-app ./app-demo
    ↓
Kubernetes Creates New Pods
  └─ New pods pull updated image from Docker Hub
    ↓
Application Deployed
  └─ LoadBalancer/Ingress routes to new pods
```

---

## Troubleshooting

### ArgoCD Issues

**Problem: ArgoCD pods not starting**

```bash
# Check pod logs
kubectl logs -n argocd deployment/argocd-server
kubectl describe pods -n argocd
```

**Problem: Cannot login to ArgoCD**

- Verify password from Step 2.5
- Try using `admin` username
- Check browser has no cached login

**Problem: ArgoCD Application shows "OutOfSync"**

```bash
# Manually sync
argocd app sync demo-app

# Or via kubectl
kubectl patch application demo-app -n argocd -p '{"spec":{"syncPolicy":{"automated":{"prune":true}}}}' --type merge
```

### Jenkins Issues

**Problem: Jenkins pod not starting**

```bash
# Check logs
kubectl logs -n jenkins deployment/jenkins

# Check PVC
kubectl get pvc -n jenkins
```

**Problem: Cannot access Jenkins**

- Verify port-forward is running
- Check Jenkins service exists: `kubectl get svc -n jenkins`
- Try port 8082 if 8080 is in use

**Problem: Pipeline fails at Docker Push**

- Verify Docker Hub credentials in Jenkins
- Check Docker daemon is running: `docker ps`
- Verify credentials have proper permissions

### Application Issues

**Problem: Application pods are "Pending"**

```bash
# Check resource availability
kubectl describe nodes

# Check pod details
kubectl describe pod -l app=demo-app
```

**Problem: Application shows "ImagePullBackOff"**

- Verify Docker image exists on Docker Hub
- Check image tag in `value.yml` matches pushed image
- Check image repository settings

### Network Issues

**Problem: Cannot reach application via LoadBalancer**

```bash
# Get LoadBalancer details
kubectl get svc demo-app -o yaml

# If using Kind (local Kubernetes), use port-forward instead
kubectl port-forward svc/demo-app 3000:80
```

**Problem: Ingress not working**

- Verify Ingress Controller is installed
- Check Ingress resource: `kubectl get ingress`
- Update `/etc/hosts` with correct mapping

### Git/GitHub Issues

**Problem: Jenkins cannot access GitHub**

- Verify GitHub credentials in Jenkins
- Check GitHub token has repo access permissions
- Test with: `git clone <repo>` manually

**Problem: ArgoCD cannot access GitHub repository**

```bash
# Check ArgoCD repository connection
argocd repo list

# Add repository credentials
argocd repo add https://github.com/yourusername/yourrepo --username <user> --password <token>
```

---

## Environment Variables

### Application (.env)

```
PORT=3000
```

### Docker Compose

Configured in docker-compose.yml:

```
NODE_ENV=development
```

### Jenkins (Jenkinsfile Environment)

- `DOCKER_HUB_REPO` - Docker Hub repository path
- `DOCKER_HUB_CREDENTIALS` - Jenkins credentials ID
- `GITHUB_CREDENTIALS` - Jenkins credentials ID
- `GIT_BRANCH` - Git branch to build

---

## Resources and Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Documentation](https://docs.docker.com/)

---

## Quick Reference Commands

```bash
# Check all services
kubectl get all -A

# Check specific namespace
kubectl get all -n argocd
kubectl get all -n jenkins
kubectl get all -n default

# View logs
kubectl logs -n <namespace> deployment/<deployment-name>
kubectl logs -n <namespace> pod/<pod-name>

# Port forward
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# Delete and reinstall
kubectl delete namespace <namespace>
kubectl apply -f <yaml-file>

# Helm operations
helm list
helm status <release> -n <namespace>
helm upgrade --install <release> <chart> -n <namespace>
helm uninstall <release> -n <namespace>
```

---

## Security Notes

**Important:** This setup is for development/learning purposes.

For production deployments:

- Enable TLS/SSL certificates (not self-signed)
- Use sealed secrets or external secret management
- Enable RBAC and network policies
- Use private Docker registries
- Rotate credentials regularly
- Enable audit logging
- Use resource quotas and limits
- Implement pod security policies
