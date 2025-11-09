# YOLO Application - Google Kubernetes Deployment

**Live URL**: `http://34.123.61.30:3000`

*(Update with actual IP after deployment)*

---

## Project Overview

This project uses the following Kubernetes objects:
- **StatefulSet** for MongoDB (persistent database storage)
- **Deployments** for Frontend and Backend (stateless applications)  
- **LoadBalancer Service** for external access
- **PersistentVolumes** for data persistence

**Built with Docker images from Week 2 project:**
- Frontend: `kipanch/yolo-client:v1.0.3`
- Backend: `kipanch/yolo-backend:v1.0.3`
- Database: `mongo:latest`

---

## Deployment Instructions

### Prerequisites
- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed ([Install Guide](https://cloud.google.com/sdk/docs/install))
- `kubectl` installed
- Git installed

### Step 1: Clone Repository
```bash
git clone https://github.com/kennedy-dev/yolo.git
cd yolo
```

### Step 2: Setup GCP
```bash
# Authenticate
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Install auth plugin
gcloud components install gke-gcloud-auth-plugin
```

### Step 3: Create GKE Cluster
```bash
gcloud container clusters create yolo-cluster \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=e2-medium

# Get credentials
gcloud container clusters get-credentials yolo-cluster --zone=us-central1-a
```

### Step 4: Deploy Application
```bash
# Deploy in order (database first!)
kubectl apply -f mongo-statefulset.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f client-deployment.yaml
```

### Step 5: Get Application URL
```bash
# Wait 2-5 minutes for LoadBalancer IP
kubectl get service kennedy-yolo-client

# Look for EXTERNAL-IP column
# Access application at: http://34.123.61.30:3000
```

---

## Repository Structure

```
yolo/
├── README.md                    # This file
├── explanation.md               # Implementation reasoning
├── mongo-statefulset.yaml       # MongoDB StatefulSet + Service
├── backend-deployment.yaml      # Backend Deployment + Service
|── client-deployment.yaml       # Frontend Deployment + LoadBalancer

```

---

## Architecture

```
Internet
    ↓
LoadBalancer Service (Public IP:3000)
    ↓
Frontend Pods - Deployment
    ↓
Backend Service (Internal ClusterIP:5000)
    ↓
Backend Pods - Deployment
    ↓
MongoDB Service (Headless:27017)
    ↓
MongoDB Pod - StatefulSet
    ↓
PersistentVolume (1Gi Google Cloud Disk)
```

---

## Verification

Check deployment status:
```bash
# View all pods (should show 3 pods Running)
kubectl get pods

# View services (LoadBalancer should have EXTERNAL-IP)
kubectl get services

# View StatefulSet (should show 1/1 READY)
kubectl get statefulset

# View persistent storage (should show Bound PVC)
kubectl get pvc

# View logs if needed
kubectl logs -l app=yolo-client
kubectl logs -l app=yolo-backend
kubectl logs -l app=mongo
```
---

## Git Workflow

Development workflow used:
```bash
# Feature branch development
git checkout -b feature/k8s-manifests
git add .
git commit -m "Add Kubernetes deployment manifests"
git push origin feature/k8s-manifests

# Merge to main
git checkout main
git merge feature/k8s-manifests
git push origin main
```

---

## Cleanup

To remove all resources:
```bash
# Delete Kubernetes resources
kubectl delete -f client-deployment.yaml
kubectl delete -f backend-deployment.yaml
kubectl delete -f mongo-statefulset.yaml

# Delete GKE cluster
gcloud container clusters delete yolo-cluster --zone=us-central1-a
```

**Note**: Deleting the cluster also removes all PersistentVolumes and data.

---

## Additional Documentation

- **explanation.md** - Detailed reasoning for implementation decisions (objectives 1-3)
- See individual YAML files for inline comments