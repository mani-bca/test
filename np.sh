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