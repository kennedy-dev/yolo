# How to deploy the application on Google Clould

## Live Application

**URL**: `http://http://34.123.61.30:3000`

*(Replace with your actual IP after deployment)*

---

## Quick Deploy

### 1. Setup
```bash
# Login to GCP
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Install auth plugin (if needed)
gcloud components install gke-gcloud-auth-plugin
```

### 2. Deploy

gcloud container clusters create yolo-cluster \
  --zone=us-central1-a \ /*or other region you'd like*/
  --num-nodes=2 \
  --machine-type=e2-medium

gcloud container clusters get-credentials yolo-cluster --zone=us-central1-a

kubectl apply -f mongo-statefulset.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f client-deployment.yaml
```

### 3. Get Your URL
```bash
kubectl get service kennedy-yolo-client
# Wait for EXTERNAL-IP (2-5 minutes)
# Access: http://EXTERNAL-IP:3000
```

---

