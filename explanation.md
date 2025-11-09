# Explanation - Kubernetes Deployment Decisions

This document explains the reasoning behind the implementation decisions for the application deployment on Google Kubernetes Engine (GKE).

---

## 1. Choice of Kubernetes Objects Used for Deployment

### StatefulSet for MongoDB (Database)

**Decision**: Used **StatefulSet** for MongoDB deployment.

**Reasoning**:

#### Why StatefulSet?

I chose StatefulSet for MongoDB because databases require stable, persistent infrastructure that regular Deployments cannot provide.

**1. Stable Network Identity**
- StatefulSet provides predictable pod names (`mongo-0`) that remain constant across restarts
- This is crucial for database applications where connection strings need to be reliable
- With a regular Deployment, pods get random names (`mongo-xyz123`) that change on every restart, making it difficult to maintain stable database connections

**2. Persistent Storage Management**
- StatefulSet automatically creates and manages PersistentVolumeClaims through `volumeClaimTemplates`
- Each pod gets its own dedicated storage that persists across pod lifecycle events
- When `mongo-0` crashes and restarts, StatefulSet ensures it reattaches to the same PersistentVolume
- This guarantees data persistence without manual intervention

**3. Ordered Deployment and Scaling**
- StatefulSet deploys pods in a predictable order (mongo-0, then mongo-1, etc.)
- This ordered behavior is essential for databases that may need to establish primary-replica relationships in the future
- If I scale to multiple replicas later, StatefulSet ensures proper initialization sequence

**4. Industry Best Practice**
- StatefulSet is the Kubernetes-recommended controller for stateful applications like databases
- It's specifically designed to handle the unique requirements of storage applications
- Using StatefulSet demonstrates understanding of Kubernetes best practices for database deployments

**Alternative Considered**: Regular Deployment
- Rejected because Deployments don't guarantee stable pod names
- Managing persistent storage manually would be complex and error-prone
- Not suitable for database workloads that require state preservation

---

### Deployments for Frontend and Backend

**Decision**: Used **Deployment** for both frontend (React) and backend (Node.js) applications.

**Reasoning**:

#### Why Deployment?

I chose Deployments for the frontend and backend because they are stateless applications that benefit from Deployment's features:

**1. Stateless Nature**
- **Frontend**: Serves static React files; no local data storage required
- **Backend**: Processes API requests but stores all data in MongoDB (external state)
- Neither application maintains state within the pod itself

**2. Easy Scaling**
- Deployments make it simple to scale horizontally (`replicas: 1` → `replicas: 3`)
- All replicas are identical and interchangeable
- Load balancing works seamlessly across multiple pods

**3. Rolling Updates**
- Deployments support zero-downtime updates
- Can update application versions gradually without service interruption
- If an update fails, easy rollback to previous version

**4. Appropriate for Stateless Workloads**
- No need for stable network identities (unlike databases)
- No need for persistent storage per pod
- Pods are ephemeral and replaceable without data loss

**Why Not StatefulSet?**
- Frontend and backend don't need stable pod names
- They don't require persistent storage per pod
- Using StatefulSet would be overkill and add unnecessary complexity
- Deployments are simpler and more appropriate for stateless applications

---

### Summary: Object Selection

| Component | Kubernetes Object | Reason |
|-----------|------------------|--------|
| MongoDB | StatefulSet | Requires persistent storage, stable identity, ordered operations |
| Backend API | Deployment | Stateless, easy scaling, rolling updates |
| Frontend | Deployment | Stateless, serves static files, no local storage needed |

---

## 2. Method Used to Expose Pods to Internet Traffic

### LoadBalancer Service for Frontend

**Decision**: Used **LoadBalancer** type Service to expose the frontend to internet traffic.

**Reasoning**:

#### Why LoadBalancer?

**1. Direct Internet Access Required**
- The frontend React application needs to be accessible to end users on the internet
- LoadBalancer is the standard Kubernetes method for exposing applications externally in cloud environments
- It provides a stable, production-ready entry point for external traffic

**2. Cloud Provider Integration**
- On GKE, LoadBalancer automatically provisions a Google Cloud Load Balancer
- Google assigns a public IP address that users can access
- This integration is seamless and requires no additional configuration

**3. Production-Ready Solution**
- LoadBalancer provides proper load distribution across multiple frontend pods (if scaled)
- Handles health checks and routes traffic only to healthy pods
- More reliable than alternatives like NodePort

**4. Simple Implementation**
- Single service definition provides external access
- No need for additional Ingress controllers or complex configurations
- Appropriate for the project scope and requirements

---

### ClusterIP Services for Backend and Database

**Decision**: Used **ClusterIP** (default) type Services for backend and database.

**Reasoning**:

#### Why ClusterIP for Backend and Database?

**1. Security Best Practice**
- Backend API and database should NOT be directly accessible from the internet
- Only the frontend needs external access
- ClusterIP keeps these services internal to the cluster

**2. Internal Communication**
- Frontend pods can reach backend at `kennedy-yolo-backend:5000` (DNS-based service discovery)
- Backend pods can reach database at `app-mongo:27017`
- All internal communication is secure and doesn't traverse the internet

**3. Network Isolation**
- Reduces attack surface by limiting exposure
- Database is completely isolated from external traffic
- Backend only accepts requests from within the cluster

**Implementation**:
```yaml
# Backend Service (ClusterIP)
apiVersion: v1
kind: Service
metadata:
  name: kennedy-yolo-backend
spec:
  # type: ClusterIP is default, so it's omitted
  selector:
    app: yolo-backend
  ports:
  - port: 5000
    targetPort: 5000

# MongoDB Service (Headless - ClusterIP: None)
apiVersion: v1
kind: Service
metadata:
  name: app-mongo
spec:
  clusterIP: None    # Headless service for StatefulSet
  selector:
    app: mongo
  ports:
  - port: 27017
```

**Why Headless Service for MongoDB?**
- StatefulSets work best with headless services (`clusterIP: None`)
- Provides direct DNS resolution to individual pods
- Enables stable network identity for `mongo-0`

---

### Traffic Flow Architecture

```
Internet (Users)
    ↓
LoadBalancer Service (EXTERNAL-IP:3000)
    ↓
Frontend Pods (kennedy-yolo-client)
    ↓ (Internal traffic only)
ClusterIP Service (kennedy-yolo-backend:5000)
    ↓
Backend Pods
    ↓ (Internal traffic only)
Headless Service (app-mongo:27017)
    ↓
MongoDB Pod (mongo-0)
```

**Security Model**:
-  Frontend: Exposed to internet (necessary for users)
-  Backend: NOT exposed to internet (internal API only)
-  Database: NOT exposed to internet (internal data store only)

---

### Summary: Exposure Strategy

| Component | Service Type | Exposed to Internet? | Reason |
|-----------|-------------|---------------------|--------|
| Frontend | LoadBalancer |  Yes | Users need browser access |
| Backend | ClusterIP |  No | Internal API only |
| Database | Headless (ClusterIP: None) |  No | Internal data store only |

This approach follows the **principle of least privilege**: only expose what's absolutely necessary.

---

## 3. Use of Persistent Storage

### Persistent Storage for MongoDB

**Decision**: Implemented **persistent storage** for MongoDB using PersistentVolumeClaims (PVC) via StatefulSet's `volumeClaimTemplates`.

**Reasoning**:

#### Why Persistent Storage is Critical

**1. Data Durability**
- Without persistent storage, all database data would be lost when a pod restarts or crashes
- Persistent storage ensures data survives pod lifecycle events (crashes, updates, rescheduling)
- This is critical for any production database deployment

**2. StatefulSet Integration**
- StatefulSet's `volumeClaimTemplates` automatically creates a PersistentVolumeClaim for each pod
- This PVC is bound to a PersistentVolume (Google Cloud Persistent Disk on GKE)
- The binding is stable: `mongo-0` always gets `mongo-storage-mongo-0`

**3. Data Persistence Across Failures**

**Scenario 1: Pod Crashes**
```
1. mongo-0 pod crashes
2. Kubernetes detects failure
3. StatefulSet recreates mongo-0 (same name)
4. Reattaches mongo-storage-mongo-0 (same PVC)
5. MongoDB starts and finds all data intact
```

**Scenario 2: Node Failure**
```
1. Entire node fails
2. Kubernetes reschedules mongo-0 to different node
3. GKE reattaches the same Persistent Disk
4. Data remains intact
```

**Scenario 3: Manual Deletion**
```
1. kubectl delete pod mongo-0
2. StatefulSet immediately recreates mongo-0
3. Same PVC reattached
4. Data preserved
```

**4. Storage Implementation Details**

**Implementation**:
```yaml
volumeClaimTemplates:
  - metadata:
      name: mongo-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

**What Happens:**
1. StatefulSet creates PersistentVolumeClaim named `mongo-storage-mongo-0`
2. GKE provisions a 1Gi Google Cloud Persistent Disk
3. Disk is mounted to pod at `/data/db` (MongoDB's data directory)
4. All database files, collections, and indexes are stored on this disk

**Verification**:
```bash
# Check PVC created
kubectl get pvc
# Output: mongo-storage-mongo-0   Bound   1Gi

# Check PV created
kubectl get pv
# Shows corresponding PersistentVolume provisioned by GKE
```

---

---

### Data Flow and Storage

```
User adds item to cart (Browser)
    ↓
Frontend sends API request
    ↓
Backend processes request
    ↓
Backend writes to MongoDB
    ↓
Data written to /data/db
    ↓
Stored on Persistent Disk (1Gi)
    ↓
 Data persists even if all pods restart
```

---

### Persistent Storage Benefits Demonstrated

**1. Pod Restart Test**
```bash
# Delete MongoDB pod
kubectl delete pod mongo-0

# Pod recreates automatically
kubectl get pods -w

# Data still intact (check by accessing application)
# Cart items, products, etc. all preserved
```

**2. Scaling Test**
```bash
# Scale backend to 3 replicas
kubectl scale deployment kennedy-yolo-backend --replicas=3

# All 3 backend pods connect to same MongoDB
# All see the same data (from shared Persistent Disk)
```

---

### Storage Best Practices Applied

 **Persistent storage for stateful workloads** (MongoDB)
 **No storage for stateless workloads** (Frontend, Backend)
 **Appropriate storage size** (1Gi is sufficient for development/testing)
 **ReadWriteOnce access mode** (suitable for single-node databases)
 **Automatic provisioning** (via volumeClaimTemplates)

---

### Summary: Storage Strategy

| Component | Persistent Storage? | Reason |
|-----------|-------------------|--------|
| MongoDB | Yes (1Gi PVC) | Database must persist data across restarts |
| Backend | No | Stateless; stores data in MongoDB |
| Frontend | No | Stateless; serves static files only |

**Key Principle**: Only add persistent storage where actually needed. This keeps the architecture simple, cost-effective, and maintainable.