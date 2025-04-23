I'd be happy to help you create a comprehensive Kubernetes Network Policy demo for your team. Let's create YAML files for deployments and network policies that demonstrate both allowing and denying traffic between pods, along with the necessary curl commands to test connectivity.

Let me create an artifact with all the YAML files you'll need for your demo.

## 1. NAMESPACES
# Create three namespaces for your demo

# Create namespace1.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
---
# Create namespace2.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: backend
---
# Create namespace3.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: database


## 2. DEPLOYMENTS
# Three different deployments in different namespaces

# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
  labels:
    app: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
# frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
  labels:
    app: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: netshoot
        image: nicolaka/netshoot
        command: ["/bin/sh"]
        args: ["-c", "while true; do sleep 3600; done"]
---
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
---
# database-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
  labels:
    app: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "password123"
        ports:
        - containerPort: 5432
---
# database-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: database-svc
  namespace: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP


## 3. NETWORK POLICIES

# 1. Default deny all ingress traffic to frontend namespace
# deny-all-frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# 2. Allow specific ingress traffic to frontend from anywhere
# allow-frontend-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-ingress
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - ports:
    - port: 80
      protocol: TCP
---
# 3. Default deny all traffic to backend namespace
# deny-all-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# 4. Allow traffic from frontend to backend
# allow-frontend-to-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
---
# 5. Allow backend to reach database
# allow-backend-to-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: backend
      podSelector:
        matchLabels:
          app: backend
    ports:
    - port: 5432
      protocol: TCP
---
# 6. Allow egress from backend to database
# allow-backend-egress-to-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-egress-to-database
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: database
      podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
      protocol: TCP

Now, let me provide you with a step-by-step guide for running your Kubernetes Network Policy demo:

## Kubernetes Network Policy Demo Guide

### Step 1: Set Up Environment
```bash
# Apply all namespace definitions
kubectl apply -f namespace1.yaml
kubectl apply -f namespace2.yaml
kubectl apply -f namespace3.yaml

# Label namespaces for easier network policy selection
kubectl label namespace frontend kubernetes.io/metadata.name=frontend
kubectl label namespace backend kubernetes.io/metadata.name=backend
kubectl label namespace database kubernetes.io/metadata.name=database

# Deploy all applications
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f database-deployment.yaml
kubectl apply -f database-service.yaml
```

### Step 2: Verify Deployments
```bash
# Check if pods are running
kubectl get pods -n frontend
kubectl get pods -n backend
kubectl get pods -n database

# Check services
kubectl get svc -n frontend
kubectl get svc -n backend
kubectl get svc -n database
```

### Step 3: Test Connectivity (Before Network Policies)
```bash
# Get a frontend pod name
FRONTEND_POD=$(kubectl get pods -n frontend -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Get a backend pod name
BACKEND_POD=$(kubectl get pods -n backend -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Test connectivity from frontend to backend
kubectl exec -it $FRONTEND_POD -n frontend -- curl backend-svc.backend:8080 -m 5

# Test connectivity from backend to database
kubectl exec -it $BACKEND_POD -n backend -- curl database-svc.database:5432 -m 5

# You should see connectivity is allowed by default (though connections might time out since the services don't actually serve content)
```

### Step 4: Apply Default Deny Policies and Test
```bash
# Apply default deny policies
kubectl apply -f deny-all-frontend.yaml
kubectl apply -f deny-all-backend.yaml

# Test connectivity again from frontend to backend (should fail)
kubectl exec -it $FRONTEND_POD -n frontend -- curl backend-svc.backend:8080 -m 5

# Test connectivity from backend to database (should fail)
kubectl exec -it $BACKEND_POD -n backend -- curl database-svc.database:5432 -m 5
```

### Step 5: Apply Selective Allow Policies and Test
```bash
# Apply policies to allow specific traffic
kubectl apply -f allow-frontend-ingress.yaml
kubectl apply -f allow-frontend-to-backend.yaml
kubectl apply -f allow-backend-to-database.yaml
kubectl apply -f allow-backend-egress-to-database.yaml

# Test connectivity again from frontend to backend (should work now)
kubectl exec -it $FRONTEND_POD -n frontend -- curl backend-svc.backend:8080 -m 5

# Test connectivity from backend to database (should work now)
kubectl exec -it $BACKEND_POD -n backend -- curl database-svc.database:5432 -m 5
```

### Additional Tests to Demonstrate Policy Enforcement
```bash
# Create a temporary test pod in the default namespace
kubectl run test-pod --image=nicolaka/netshoot -- sleep 3600

# Try to access frontend from outside its namespace (should be blocked)
kubectl exec -it test-pod -- curl frontend-svc.frontend:80 -m 5

# Try to access backend from outside its namespace (should be blocked)
kubectl exec -it test-pod -- curl backend-svc.backend:8080 -m 5

# Try to access database from outside its namespace (should be blocked)
kubectl exec -it test-pod -- curl database-svc.database:5432 -m 5
```

## Key Demo Highlights

1. **Default Open Network**: Initially, all pods can communicate with each other (Kubernetes default)

2. **Default Deny Policies**: Demonstrate how to lock down all traffic with default deny rules

3. **Selective Traffic Flow**: Show how to create granular rules to allow specific traffic flows:
   - External → Frontend (on port 80 only)
   - Frontend → Backend (specific path)
   - Backend → Database (specific path)

4. **Multi-directional Policies**: For complete traffic control, use both ingress and egress policies together

This demo provides a comprehensive overview of Kubernetes Network Policies with real examples of blocking and allowing specific traffic patterns between different application tiers. Let me know if you need any clarification or have questions about any part of the demo!

##₹₹₹₹₹₹#####@######
I'll create a simpler version of the PV/PVC, health check, namespace quota, and resource limits demo that follows the same structure as your network policy demo. This will complement your existing network policy demo without making any changes to it.

## 1. NAMESPACE WITH RESOURCE QUOTA

# app-namespace-quota.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-demo
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: app-quota
  namespace: app-demo
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 2Gi
    limits.cpu: "2"
    limits.memory: 4Gi
    pods: "10"


## 2. PERSISTENT VOLUMES & CLAIMS

# app-pv-pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-pv
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: app-demo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi


## 3. WEBSERVER DEPLOYMENT WITH RESOURCES AND HEALTH CHECKS

# webserver-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver
  namespace: app-demo
  labels:
    app: webserver
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app-storage
          mountPath: /usr/share/nginx/html
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: app-pvc
---
# webserver-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: webserver-svc
  namespace: app-demo
spec:
  selector:
    app: webserver
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP


## 4. API DEPLOYMENT WITH RESOURCES AND HEALTH CHECKS

# api-deployment.yaml  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: app-demo
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: httpd:alpine
        resources:
          requests:
            memory: "128Mi"
            cpu: "150m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
---
# api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  namespace: app-demo
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP


## 5. DATABASE DEPLOYMENT WITH RESOURCES AND HEALTH CHECKS

# database-deployment.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-pv
  labels:
    type: local
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/db-data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: app-demo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: app-demo
  labels:
    app: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: "password123"
        volumeMounts:
        - name: db-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          initialDelaySeconds: 30
          periodSeconds: 20
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: db-storage
        persistentVolumeClaim:
          claimName: db-pvc
---
# database-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  namespace: app-demo
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP

## Simple Kubernetes Resources Demo Guide

This demo will complement your network policy demo by adding resource management components including PVs/PVCs, health checks, namespace quotas, and CPU/memory limits.

### Step 1: Create Namespace with Resource Quota
```bash
# Apply namespace with quota
kubectl apply -f app-namespace-quota.yaml

# Verify the quota
kubectl get namespace app-demo
kubectl describe namespace app-demo
kubectl get resourcequota -n app-demo
```

### Step 2: Create Persistent Volumes and Claims
```bash
# Create PV and PVC for the application
kubectl apply -f app-pv-pvc.yaml

# Verify PV and PVC are created and bound
kubectl get pv
kubectl get pvc -n app-demo
```

### Step 3: Deploy Applications with Resource Limits and Health Checks
```bash
# Deploy webserver with volume, resource limits and health checks
kubectl apply -f webserver-deployment.yaml
kubectl apply -f webserver-service.yaml

# Deploy API server with resource limits and health checks
kubectl apply -f api-deployment.yaml
kubectl apply -f api-service.yaml

# Deploy database with volume, resource limits and health checks
kubectl apply -f database-deployment.yaml
kubectl apply -f database-service.yaml
```

### Step 4: Verify Deployments
```bash
# Check if pods are running
kubectl get pods -n app-demo

# Check resource consumption
kubectl top pods -n app-demo

# Check if services are created
kubectl get svc -n app-demo
```

### Step 5: Test Health Checks
```bash
# Get the name of a webserver pod
WEBSERVER_POD=$(kubectl get pods -n app-demo -l app=webserver -o jsonpath='{.items[0].metadata.name}')

# Check the readiness and liveness probe status
kubectl describe pod $WEBSERVER_POD -n app-demo | grep -A 10 "Liveness" 
kubectl describe pod $WEBSERVER_POD -n app-demo | grep -A 10 "Readiness"

# Simulate a failure to trigger health check
kubectl exec -it $WEBSERVER_POD -n app-demo -- rm -rf /usr/share/nginx/html/index.html

# Check pod events to see if health checks are working
kubectl describe pod $WEBSERVER_POD -n app-demo | grep -A 15 Events:
```

### Step 6: Test Resource Limits
```bash
# Create a pod that exceeds the quota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: large-resource-pod
  namespace: app-demo
spec:
  containers:
  - name: large-container
    image: nginx
    resources:
      requests:
        memory: "1.5Gi"
        cpu: "800m"
      limits:
        memory: "2Gi"
        cpu: "1"
EOF

# Check if quota is enforced
kubectl get pod large-resource-pod -n app-demo
kubectl describe pod large-resource-pod -n app-demo
```

### Step 7: Test Persistent Storage
```bash
# Add content to the webserver volume
kubectl exec -it $WEBSERVER_POD -n app-demo -- sh -c "echo 'Hello from Kubernetes Volume Demo' > /usr/share/nginx/html/index.html"

# Test accessing the content
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -n app-demo -- curl webserver-svc

# Delete and recreate the pod to verify persistence
kubectl delete pod $WEBSERVER_POD -n app-demo
# Wait for the new pod to be created
sleep 10
# Get the new pod name
NEW_WEBSERVER_POD=$(kubectl get pods -n app-demo -l app=webserver -o jsonpath='{.items[0].metadata.name}')
# Check if the data persisted
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -n app-demo -- curl webserver-svc
```

## Demo Highlights

1. **Namespace Resource Quota**: Controls CPU and memory consumption across the namespace

2. **Persistent Volumes**: Provides storage that survives pod restarts
   - Application HTML files stored on PV
   - Database files stored on PV

3. **Resource Management**:
   - CPU and memory requests (guaranteed minimum)
   - CPU and memory limits (maximum allowed)
   - Different tiers for different workloads (DB has higher resources than web)

4. **Health Checks**:
   - Liveness probes ensure containers are restarted when unhealthy
   - Readiness probes prevent traffic to pods that aren't ready
   - Database uses exec-based probes, web servers use HTTP probes

This demo shows how to ensure application stability and resource efficiency in Kubernetes by properly configuring storage, resource limits, and health checks.

You can use this alongside your network policy demo to provide a comprehensive overview of Kubernetes security and reliability features.
api-service.yaml