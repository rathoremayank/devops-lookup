# Kubernetes Questions

## 1. How does Helm chart help in the project?

### Answer:

Helm is the package manager for Kubernetes, providing templating, versioning, and lifecycle management for Kubernetes applications.

**Key Benefits:**

1. **Templating & Reusability**
   - Parameterize Kubernetes manifests using Helm templates
   - Reduce YAML duplication across environments
   - Use variables for configuration management

**Example Helm Chart Structure:**
```
my-app-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default values
├── values-dev.yaml            # Dev environment overrides
├── values-prod.yaml           # Prod environment overrides
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── ingress.yaml
└── README.md
```

**templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        version: {{ .Values.appVersion }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.port }}
        env:
        - name: LOG_LEVEL
          value: "{{ .Values.logLevel }}"
        resources:
          requests:
            memory: "{{ .Values.resources.requests.memory }}"
            cpu: "{{ .Values.resources.requests.cpu }}"
          limits:
            memory: "{{ .Values.resources.limits.memory }}"
            cpu: "{{ .Values.resources.limits.cpu }}"
        livenessProbe:
          httpGet:
            path: /health
            port: {{ .Values.service.port }}
          initialDelaySeconds: 30
          periodSeconds: 10
```

**values.yaml:**
```yaml
replicaCount: 3

image:
  repository: myregistry.azurecr.io/myapp
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

logLevel: INFO

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

appVersion: "v1.0"
```

2. **Versioning & Rollback**
   - Version control for application releases
   - Easy rollback to previous versions
   - Release history tracking

```bash
# Deploy with Helm
helm install my-app ./my-app-chart -f values-prod.yaml

# Upgrade to new version
helm upgrade my-app ./my-app-chart -f values-prod.yaml --values values-prod.yaml

# Check release history
helm history my-app

# Rollback to previous release
helm rollback my-app 1
```

3. **Dependency Management**
   - Define and manage chart dependencies
   - Automatic chart updates

**Chart.yaml dependencies:**
```yaml
dependencies:
  - name: postgresql
    version: "12.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

4. **Release Management**
   - Create, update, and delete releases atomically
   - Pre/post deployment hooks

```yaml
# templates/pre-install-hook.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-pre-install
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
spec:
  template:
    spec:
      containers:
      - name: pre-install
        image: myregistry/migration-tool:latest
        command: ["./db-migration.sh"]
      restartPolicy: Never
  backoffLimit: 1
```

**Real-World Use Case:**
```bash
# Deploy microservices with different configurations
helm install payment-service ./microservice-chart \
  -f values-prod.yaml \
  --set image.tag=v2.1.0 \
  --set replicaCount=5 \
  -n production

helm install inventory-service ./microservice-chart \
  -f values-prod.yaml \
  --set image.repository=myregistry/inventory \
  --set replicaCount=3 \
  -n production
```

**Benefits Summary:**
- **DRY Principle**: Single source of truth for configurations
- **Automation**: Scriptable deployments and upgrades
- **Consistency**: Same deployment patterns across services
- **Flexibility**: Easy customization per environment

---

## 2. What are the storage classes available in Kubernetes?

### Answer:

Storage Classes define how persistent volumes are dynamically provisioned with different characteristics and performance tiers.

**Common Storage Classes:**

**1. AWS EBS Storage Class:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-ebs
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
```

**2. Azure Managed Disk Storage Class:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-managed-disk
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
allowVolumeExpansion: true
reclaimPolicy: Delete
```

**3. NFS Storage Class (On-Premises):**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-fast
provisioner: nfs.io/nfs
parameters:
  server: nfs-server.example.com
  path: "/export/fast"
allowVolumeExpansion: true
reclaimPolicy: Retain
```

**4. Local SSD Storage Class (High Performance):**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-ssd
provisioner: kubernetes.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
parameters:
  replication-factor: "3"
```

**Storage Class Comparison:**

| Type | Provider | Performance | Use Case | Cost |
|------|----------|-------------|----------|------|
| EBS gp3 | AWS | High | General workloads | Medium |
| EBS io1 | AWS | Very High | Databases | High |
| Azure Premium | Azure | High | Production workloads | High |
| NFS | All | Medium | Shared storage | Low-Medium |
| Local SSD | All | Very High | Real-time analytics | Medium |

**Using Storage Classes:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-ebs
  resources:
    requests:
      storage: 100Gi
```

**Multiple Storage Tiers Example:**
```yaml
# Fast tier for cache
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-cache
provisioner: ebs.csi.aws.com
parameters:
  type: io2
  iops: "10000"
  throughput: "250"
---
# Standard tier for data
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard-data
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
---
# Backup tier for archives
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: archive-backup
provisioner: ebs.csi.aws.com
parameters:
  type: sc1  # Throughput-optimized
  throughput: "40"
```

---

## 3. Kubernetes pod is crashing. How to check the pod and troubleshooting process?

### Answer:

Systematic troubleshooting is essential for diagnosing pod failures in production Kubernetes environments.

**Step 1: Check Pod Status**
```bash
# Get pod overview
kubectl get pods -n production
kubectl describe pod my-app-pod-abc123 -n production

# Expected output shows:
# - Phase: Running, Pending, Failed, Succeeded, Unknown
# - Conditions: Ready, Initialized, ContainersReady
# - Last State: Reason for termination
```

**Step 2: Analyze Pod Events**
```bash
# View recent events
kubectl get events -n production --sort-by='.lastTimestamp'

# Example issues:
# - ImagePullBackOff: Docker image not found
# - CrashLoopBackOff: Container continuously crashing
# - Pending: Insufficient resources
# - OOMKilled: Out of memory
```

**Step 3: Check Pod Logs**
```bash
# Real-time logs
kubectl logs -f my-app-pod-abc123 -n production

# Previous container logs (if crash-loop)
kubectl logs my-app-pod-abc123 --previous -n production

# All containers in pod
kubectl logs my-app-pod-abc123 --all-containers=true -n production

# Specific time window
kubectl logs my-app-pod-abc123 --since=10m -n production

# Stream logs from multiple pods
kubectl logs -f -l app=my-app -n production --all-containers=true
```

**Step 4: Debug Pod Resources**
```bash
# Check if resources are constrained
kubectl top pod my-app-pod-abc123 -n production
kubectl top nodes

# Describe node for capacity
kubectl describe node node-01

# Example output shows:
# Allocated resources:
#   CPU Requests: 2000m/4000m
#   Memory Requests: 4Gi/8Gi
```

**Step 5: Execute Commands in Pod**
```bash
# Interactive shell
kubectl exec -it my-app-pod-abc123 -n production -- /bin/bash

# Check connectivity
kubectl exec my-app-pod-abc123 -n production -- curl http://service-name:8080/health

# Check environment variables
kubectl exec my-app-pod-abc123 -n production -- env | grep DATABASE
```

**Step 6: Analyze Pod YAML**
```bash
# Export current pod definition
kubectl get pod my-app-pod-abc123 -n production -o yaml

# Check:
# - Image pull policy
# - Resource requests/limits
# - Environment variables
# - Health probes configuration
# - Security context
```

**Common Pod Crash Scenarios & Solutions:**

**Issue: CrashLoopBackOff**
```bash
# Root cause: Application crashes immediately
kubectl logs my-app-pod-abc123 --previous -n production

# Solutions:
# 1. Check application logs for startup errors
# 2. Verify environment variables are set
# 3. Check database connectivity
# 4. Review resource limits (OOM, CPU throttling)

# Example fix - update environment:
kubectl set env deployment/my-app \
  DATABASE_URL=postgres://db:5432/mydb \
  LOG_LEVEL=DEBUG \
  -n production
```

**Issue: ImagePullBackOff**
```bash
# Root cause: Container image cannot be pulled
kubectl describe pod my-app-pod-abc123 -n production

# Solutions:
# 1. Verify image URL and tag
# 2. Check image pull secrets
# 3. Verify registry credentials

# Example fix:
kubectl patch serviceaccount default -n production \
  -p '{"imagePullSecrets": [{"name": "registry-credentials"}]}'
```

**Issue: Out of Memory (OOMKilled)**
```bash
# Pod killed due to memory limits
kubectl describe pod my-app-pod-abc123 -n production
# Look for: "Last State: Terminated, Reason: OOMKilled"

# Solutions:
# 1. Increase memory limits
# 2. Optimize application memory usage
# 3. Implement caching/pagination

# Example fix:
kubectl set resources deployment/my-app \
  --limits=memory=2Gi,cpu=1000m \
  --requests=memory=1Gi,cpu=500m \
  -n production
```

**Issue: Pending Pod**
```bash
# Pod cannot be scheduled
kubectl describe pod my-app-pod-abc123 -n production

# Common reasons:
# - Insufficient CPU/Memory on nodes
# - Node affinity/anti-affinity constraints
# - Persistent volume not available
# - Resource quota exceeded

# Check node capacity
kubectl top nodes
kubectl describe nodes | grep -A 5 "AllocatedResources"

# Scale cluster if needed
kubectl scale nodes --replicas=3 -n production
```

**Comprehensive Debugging Script:**
```bash
#!/bin/bash

POD_NAME=$1
NAMESPACE=${2:-production}

echo "=== Pod Status ==="
kubectl describe pod $POD_NAME -n $NAMESPACE

echo -e "\n=== Recent Logs ==="
kubectl logs $POD_NAME --tail=50 -n $NAMESPACE

echo -e "\n=== Previous Logs ==="
kubectl logs $POD_NAME --previous -n $NAMESPACE 2>/dev/null || echo "No previous logs"

echo -e "\n=== Pod Events ==="
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD_NAME

echo -e "\n=== Resource Usage ==="
kubectl top pod $POD_NAME -n $NAMESPACE

echo -e "\n=== Pod YAML ==="
kubectl get pod $POD_NAME -n $NAMESPACE -o yaml | grep -E "image:|env:|resources:" -A 5
```

---

## 4. What is the difference between PV and PVC?

### Answer:

PV (Persistent Volume) and PVC (Persistent Volume Claim) are Kubernetes abstractions for persistent storage management.

**Persistent Volume (PV):**
- Cluster-level resource provisioned by administrator
- Abstract representation of physical storage
- Independent of pod lifecycle
- Has capacity, access modes, and reclaim policy

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-database
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  awsElasticBlockStore:
    volumeID: vol-0a1b2c3d4e5f6g7h8
    fsType: ext4
```

**Persistent Volume Claim (PVC):**
- Namespace-level request for storage
- Created by developers
- Consumes storage from PV
- Similar to Pod requesting compute resources

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-app-data
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 50Gi
```

**Key Differences Table:**

| Aspect | PV | PVC |
|--------|----|----|
| Scope | Cluster-wide | Namespace-wide |
| Created by | Admin/Automated provisioner | Developer |
| Lifecycle | Independent of pod | Bound to pod lifecycle |
| Resource Type | Infrastructure resource | User request |
| Access Control | No | Yes, via namespace |
| Reclaim Policy | Delete, Retain, Recycle | N/A |

**Complete Storage Workflow Example:**

```yaml
# Step 1: Storage Class (Admin)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
---

# Step 2: Persistent Volume (Manual/Automatic via provisioner)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-database-01
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  awsElasticBlockStore:
    volumeID: vol-0a1b2c3d4e5f6g7h8
    fsType: ext4
---

# Step 3: Persistent Volume Claim (Developer)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage
  namespace: staging
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
---

# Step 4: Pod using PVC
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
  namespace: staging
spec:
  containers:
  - name: postgresql
    image: postgres:14
    ports:
    - containerPort: 5432
    volumeMounts:
    - name: db-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: db-storage
    persistentVolumeClaim:
      claimName: db-storage
```

**Access Modes Explained:**

```yaml
# ReadWriteOnce (RWO) - Single node read/write
# Single node can read and write
# Used for databases, traditional workloads

# ReadOnlyMany (ROX) - Multiple nodes read-only
# Multiple nodes can read, not write
# Used for shared configuration, assets

# ReadWriteMany (RWX) - Multiple nodes read/write
# Multiple nodes can read and write
# Used for distributed systems, NFS storage

# ReadWriteOncePod (RWOP) - Single pod read/write
# Only one pod can read/write
# Used for StatefulSets with stricter isolation
```

**Dynamic Provisioning Example:**

```yaml
# With StorageClass, PV is created automatically
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-ebs  # Triggers automatic PV creation
  resources:
    requests:
      storage: 50Gi
```

---

## 5. We want to deploy a new service using Helm chart. How to do this?

### Answer:

Deploying a service with Helm involves creating a chart, configuring values, and using Helm commands to manage the deployment.

**Step 1: Create Helm Chart**

```bash
# Initialize new chart
helm create my-service
cd my-service

# Chart structure created:
# my-service/
# ├── Chart.yaml
# ├── values.yaml
# ├── charts/
# ├── templates/
# │   ├── deployment.yaml
# │   ├── service.yaml
# │   ├── ingress.yaml
# │   ├── hpa.yaml
# │   └── NOTES.txt
# └── README.md
```

**Step 2: Customize Chart.yaml**

```yaml
apiVersion: v2
name: my-service
description: A Helm chart for deploying my microservice
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - microservice
  - api
home: https://github.com/company/my-service
sources:
  - https://github.com/company/my-service
maintainers:
  - name: DevOps Team
    email: devops@company.com
```

**Step 3: Configure values.yaml**

```yaml
# Default values for my-service
namespace: production

replicaCount: 3

image:
  repository: myregistry.azurecr.io/my-service
  pullPolicy: IfNotPresent
  tag: "1.0.0"

imagePullSecrets:
  - name: registry-credentials

service:
  type: ClusterIP
  port: 8080
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: tls-cert
      hosts:
        - api.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

nodeSelector:
  workload: general

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - my-service
          topologyKey: kubernetes.io/hostname

environment:
  LOG_LEVEL: INFO
  CACHE_TTL: "3600"
  
configMap:
  enabled: true
  data:
    application.properties: |
      server.port=8080
      logging.level=INFO

secrets:
  enabled: true
  # Use external secrets provider in production
```

**Step 4: Create Templates**

**templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-service.fullname" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "my-service.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-service.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-service.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "my-service.serviceAccountName" . }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        livenessProbe:
          {{- toYaml .Values.livenessProbe | nindent 12 }}
        readinessProbe:
          {{- toYaml .Values.readinessProbe | nindent 12 }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        env:
        {{- range $key, $value := .Values.environment }}
        - name: {{ $key }}
          value: "{{ $value }}"
        {{- end }}
        volumeMounts:
        - name: config
          mountPath: /etc/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: {{ include "my-service.fullname" . }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

**templates/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-service.fullname" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "my-service.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "my-service.selectorLabels" . | nindent 4 }}
```

**Step 5: Validate Chart**

```bash
# Lint the chart for errors
helm lint ./my-service

# Validate templates rendering
helm template my-service ./my-service

# Dry-run to see what will be created
helm install my-service ./my-service --dry-run --debug
```

**Step 6: Deploy Service**

```bash
# Initial deployment
helm install my-service ./my-service \
  --namespace production \
  --create-namespace \
  -f values-prod.yaml

# Or use environment-specific values with overrides
helm install my-service ./my-service \
  --namespace production \
  --create-namespace \
  -f values-prod.yaml \
  --set image.tag=v2.1.0 \
  --set replicaCount=5 \
  --set resources.requests.memory=512Mi

# Verify deployment
kubectl get deployments -n production
kubectl get pods -n production
kubectl get services -n production

# Check Helm release
helm status my-service -n production
helm get values my-service -n production
```

**Step 7: Upgrade Service**

```bash
# Update values and upgrade deployment
helm upgrade my-service ./my-service \
  --namespace production \
  -f values-prod.yaml \
  --set image.tag=v2.2.0 \
  --wait  # Wait for deployment to be ready

# Rolling upgrade (default behavior)
# New pods are created while old ones are terminated

# Check upgrade status
helm status my-service -n production
kubectl rollout status deployment/my-service -n production
```

**Step 8: Rollback if Needed**

```bash
# View release history
helm history my-service -n production

# Rollback to previous release
helm rollback my-service 1 -n production

# Verify rollback
kubectl get pods -n production
```

**Multi-Environment Deployment:**

```bash
# Dev environment
helm install my-service ./my-service \
  --namespace dev \
  --create-namespace \
  -f values-dev.yaml

# Staging environment
helm install my-service ./my-service \
  --namespace staging \
  --create-namespace \
  -f values-staging.yaml

# Production environment
helm install my-service ./my-service \
  --namespace production \
  --create-namespace \
  -f values-prod.yaml
```

---

## 6. What kinds of services do we need to use to keep the data in local?

### Answer:

For local data persistence, specific Kubernetes service types and storage solutions are required.

**Local Data Persistence Options:**

**1. StatefulSet with Local Storage**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: production
spec:
  serviceName: postgresql
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:14
        ports:
        - containerPort: 5432
          name: db
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: local-storage
                operator: In
                values:
                - "true"
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-ssd
      resources:
        requests:
          storage: 50Gi
```

**2. Local Volume Storage Class**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-ssd
provisioner: kubernetes.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
parameters:
  replication-factor: "3"
```

**3. DaemonSet for Local Volume Discovery**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: local-volume-provisioner
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: local-volume-provisioner
  template:
    metadata:
      labels:
        app: local-volume-provisioner
    spec:
      containers:
      - name: provisioner
        image: registry.k8s.io/sig-storage/local-volume-provisioner:v0.5.0
        volumeMounts:
        - name: local-volumes
          mountPath: /mnt/data
      volumes:
      - name: local-volumes
        hostPath:
          path: /mnt/data
          type: Directory
      nodeSelector:
        local-storage: "true"
```

**4. Pod with EmptyDir (Temporary Local Storage)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - name: cache
    image: redis:7
    volumeMounts:
    - name: cache-data
      mountPath: /data
  volumes:
  - name: cache-data
    emptyDir:
      sizeLimit: 5Gi  # Limit size to prevent node disk full
```

**Storage Solution Comparison:**

| Solution | Persistence | Speed | Use Case | Replicas |
|----------|-------------|-------|----------|----------|
| Local Volume | Yes | Very Fast | Databases, cache | Single |
| emptyDir | No | Very Fast | Temp cache, scratch | Any |
| HostPath | Yes | Fast | Development | Single |
| PVC (block) | Yes | Medium | General apps | Multiple |
| NFS | Yes | Medium | Shared storage | Multiple |

**Practical Example - Database with Local Storage:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: databases
---
# StorageClass for local SSD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-ssd
provisioner: kubernetes.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
---
# PersistentVolume backed by local SSD
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local-postgres
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-ssd
  local:
    path: /mnt/nvme0n1  # NVMe SSD path
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-name
          operator: In
          values:
          - data-node-01
---
# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: databases
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-ssd
  resources:
    requests:
      storage: 100Gi
---
# StatefulSet using local storage
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: databases
spec:
  serviceName: postgresql
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-name
                operator: In
                values:
                - data-node-01
      containers:
      - name: postgresql
        image: postgres:14
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-data
```

---

## 7. What is NodePort and Cluster IP?

### Answer:

Service types define how Kubernetes exposes applications internally and externally.

**ClusterIP Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-service
  namespace: production
spec:
  type: ClusterIP  # Default, internal only
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: my-app
```

**Characteristics:**
- Internal-only access within cluster
- Gets stable internal DNS name: `service-name.namespace.svc.cluster.local`
- No external connectivity
- Most common for service-to-service communication
- Zero extra cost

**Usage Example:**
```bash
# Access from another pod
kubectl run -it debug --image=curlimages/curl --restart=Never -- \
  curl http://internal-service.production.svc.cluster.local/api/data
```

**NodePort Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
  namespace: production
spec:
  type: NodePort
  ports:
  - port: 80              # Internal service port
    targetPort: 8080      # Container port
    nodePort: 30080       # External port on nodes (30000-32767)
    protocol: TCP
  selector:
    app: my-app
```

**Characteristics:**
- External access through any node's IP
- Allocates port from 30000-32767
- Traffic routed to any node, then to pod
- Simple but less elegant than Ingress
- Useful for non-HTTP protocols (TCP, UDP)

**Access Methods:**
```bash
# Get NodePort service details
kubectl get svc external-service -n production

# Access from outside cluster
curl http://node-ip:30080/api/data

# Access from any worker node
curl http://10.0.1.5:30080/api/data
```

**Service Type Comparison:**

| Type | Internal | External | Use Case | Cost |
|------|----------|----------|----------|------|
| ClusterIP | ✅ | ❌ | Inter-service communication | Free |
| NodePort | ✅ | ✅ | External access to services | Free |
| LoadBalancer | ✅ | ✅ | Production external access | $$ |
| ExternalName | ✅ | N/A | DNS alias | Free |

**Complete Service Architecture Example:**

```yaml
# Frontend pod
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: production
  labels:
    app: frontend
spec:
  containers:
  - name: frontend
    image: nginx:latest
    ports:
    - containerPort: 80
---

# Backend pod
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: production
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: api:latest
    ports:
    - containerPort: 8080
---

# Internal ClusterIP for backend
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: production
spec:
  type: ClusterIP  # Internal access
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: backend
---

# External NodePort for frontend
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: production
spec:
  type: NodePort  # External access
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: frontend
---

# Frontend pod can access backend via ClusterIP
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: production
data:
  backend_url: "http://backend-service.production.svc.cluster.local:8080"
```

**Load Balancing with Multiple Replicas:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-backend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-backend
  template:
    metadata:
      labels:
        app: api-backend
    spec:
      containers:
      - name: api
        image: api:v2.0
        ports:
        - containerPort: 8080
---

# Service automatically load-balances across replicas
apiVersion: v1
kind: Service
metadata:
  name: api-backend
  namespace: production
spec:
  type: ClusterIP
  sessionAffinity: ClientIP  # Optional: sticky sessions
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: api-backend
```

---

## 8. How to handle storage persistence?

### Answer:

Storage persistence requires careful planning of provisioning, backup, and disaster recovery strategies.

**1. Storage Architecture Design**

```yaml
# Multi-tier storage strategy
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd    # For hot data (databases, cache)
provisioner: ebs.csi.aws.com
parameters:
  type: io2
  iops: "20000"
  throughput: "1000"
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard    # For warm data (logs, indexes)
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: archive     # For cold data (backups)
provisioner: ebs.csi.aws.com
parameters:
  type: sc1
  throughput: "40"
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Retain
```

**2. Stateful Application with Persistence**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: production
spec:
  clusterIP: None  # Headless service for StatefulSet
  selector:
    app: mysql
  ports:
  - port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-cluster
  namespace: production
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: mysql
            topologyKey: kubernetes.io/hostname
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
```

**3. Backup & Recovery Strategy**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-script
  namespace: production
data:
  backup.sh: |
    #!/bin/bash
    
    # Daily backup cron job
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="/backups/mysql/${TIMESTAMP}"
    
    mkdir -p ${BACKUP_DIR}
    
    # Backup database
    mysqldump -h mysql-0.mysql -u root --all-databases \
      > ${BACKUP_DIR}/mysql-backup-${TIMESTAMP}.sql
    
    # Compress backup
    gzip ${BACKUP_DIR}/mysql-backup-${TIMESTAMP}.sql
    
    # Upload to S3
    aws s3 cp ${BACKUP_DIR}/ s3://company-backups/mysql/daily/ --recursive
    
    # Retention: keep 30 days of backups
    find ${BACKUP_DIR} -type f -mtime +30 -delete
---
# Backup CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: production
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            volumeMounts:
            - name: backup-script
              mountPath: /scripts
            - name: backup-storage
              mountPath: /backups
            command: ["/bin/bash", "/scripts/backup.sh"]
          volumes:
          - name: backup-script
            configMap:
              name: backup-script
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-storage
          restartPolicy: OnFailure
```

**4. Snapshot & Restore**

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: snapshot-class
driver: ebs.csi.aws.com
deletionPolicy: Delete
---
# Create snapshot
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: mysql-snapshot-20240101
  namespace: production
spec:
  volumeSnapshotClassName: snapshot-class
  source:
    persistentVolumeClaimName: mysql-data
---
# Restore from snapshot
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data-restored
  namespace: production
spec:
  storageClassName: fast-ssd
  dataSource:
    name: mysql-snapshot-20240101
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
```

**5. High Availability with Replication**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: production
data:
  postgresql.conf: |
    wal_level = replica
    max_wal_senders = 3
    wal_keep_size = 1GB
  pg_hba.conf: |
    host    replication     all     10.0.0.0/8     md5
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      initContainers:
      - name: init-clone
        image: postgres:14
        command:
        - bash
        - -c
        - |
          if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
            pg_basebackup -h postgres-0 -D /var/lib/postgresql/data || true
          fi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      containers:
      - name: postgresql
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_INITDB_ARGS
          value: "-c max_connections=200"
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /etc/postgresql
      volumes:
      - name: config
        configMap:
          name: postgres-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
```

**6. Storage Monitoring**

```bash
# Monitor PVC usage
kubectl get pvc -w -n production

# Check node disk usage
kubectl top nodes
kubectl describe node node-name

# Alert on storage capacity
kubectl get pvc -A | grep "95%"

# Storage metrics query (Prometheus)
kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.85
```

---

## 9. Do you have experience with Kustomize?

### Answer:

Kustomize is a Kubernetes configuration management tool that enables customization without forking templates.

**Kustomize Benefits:**

1. **No Templating Language** - Uses pure YAML with overlays
2. **DRY** - Eliminates duplication across environments
3. **Native Integration** - Built-in with kubectl (kubectl -k)
4. **GitOps Friendly** - Works seamlessly with ArgoCD, Flux
5. **Flexible merging** - Strategic merge patch semantics

**Kustomize Directory Structure:**

```
my-app/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── deployment-patch.yaml
│   │   └── resources.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── replicas.yaml
│   └── production/
│       ├── kustomization.yaml
│       ├── deployment-patch.yaml
│       └── pvc.yaml
└── README.md
```

**Base Configuration:**

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: default

namePrefix: my-app-

commonLabels:
  app: my-app
  managed-by: kustomize

commonAnnotations:
  description: My application

resources:
- deployment.yaml
- service.yaml
- configmap.yaml
```

**base/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
```

**Development Overlay:**

```yaml
# overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: development

bases:
- ../../base

replicas:
- name: my-app
  count: 1

patchesStrategicMerge:
- deployment-patch.yaml

configMapGenerator:
- name: app-config
  literals:
  - ENVIRONMENT=dev
  - LOG_LEVEL=DEBUG
  behavior: merge
```

**overlays/dev/deployment-patch.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:dev
        imagePullPolicy: Always
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
```

**Production Overlay:**

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
- ../../base

namePrefix: ""
nameSuffix: "-prod"

replicas:
- name: my-app
  count: 3

patchesStrategicMerge:
- deployment-patch.yaml

patchesJson6902:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: my-app
  patch: |-
    - op: replace
      path: /spec/template/spec/affinity
      value:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: my-app
            topologyKey: kubernetes.io/hostname

resources:
- pvc.yaml

configMapGenerator:
- name: app-config
  literals:
  - ENVIRONMENT=production
  - LOG_LEVEL=INFO
  behavior: merge

secretGenerator:
- name: app-secrets
  envs:
  - secrets.env

images:
- name: my-app
  newTag: "v1.5.0"
```

**overlays/production/deployment-patch.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: myregistry/my-app:v1.5.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

**Kustomize Usage:**

```bash
# View rendered manifests for dev
kubectl kustomize overlays/dev/

# Apply development environment
kubectl apply -k overlays/dev/

# Apply production environment
kubectl apply -k overlays/production/

# Apply with dry-run
kubectl apply -k overlays/production/ --dry-run=client -o yaml

# Diff between environments
diff <(kubectl kustomize overlays/dev/) <(kubectl kustomize overlays/production/)
```

**Real-World Experience:**

1. **Multi-environment Management**
   - Maintained consistency across dev, staging, production
   - Used overlays for environment-specific values
   - Reduced configuration errors by 60%

2. **Image Tag Management**
   - Dynamic image updates without forking yamls
   - Automated tag updates in CI/CD pipelines

3. **Cross-Cluster Deployments**
   - Same base configs deployed across multiple clusters
   - Cluster-specific overlays for regional differences

4. **GitOps Integration**
   - Integrated with ArgoCD for declarative deployments
   - Automatic sync based on repository changes

---

## 10. What are the benefits of Helm?

### Answer:

Helm provides numerous benefits for Kubernetes application management at scale.

**Key Benefits:**

**1. Package Management**
- Bundles Kubernetes manifests as reusable packages
- Version control for applications
- Easy upgrade/downgrade
- Dependency management (Chart dependencies)

**2. Template Engine**
```yaml
# Single template, multiple environments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        resources:
          limits:
            memory: {{ .Values.resources.limits.memory }}
```

**3. Release Management**
- Atomic deployments/rollbacks
- Release history tracking
- Helm hooks for lifecycle management
- Test charts

```bash
helm list -a                    # All releases
helm history my-app             # Release history
helm rollback my-app 1          # Rollback
helm status my-app              # Current status
```

**4. Configuration Management**
- Centralized values management
- Environment-specific overrides
- Secrets integration

**5. Ecosystem**
- Artifact Hub: 30,000+ charts
- Community contributions
- Well-maintained official charts (Bitnami, etc.)

**6. Scaling**
- Deploy 100s of identical services
- Consistent patterns across teams
- Simplified onboarding

**7. GitOps Ready**
- Works with ArgoCD, Flux
- Declarative deployments
- Audit trail via Git

**Helm vs Other Tools:**

| Feature | Helm | Kustomize | Terraform |
|---------|------|-----------|-----------|
| Templating | Yes | Limited | Yes |
| Package Format | Yes | No | No |
| Versioning | Yes | No | Yes |
| Dependency Mgmt | Yes | No | Yes |
| K8s Native | Yes | Yes | No |
| Learning Curve | Medium | Low | High |

---

## 11. What are the benefits of Flux deployment?

### Answer:

Flux is a GitOps toolkit for automated, declarative Kubernetes deployments.

**Key Benefits:**

**1. Declarative GitOps**
- Git as single source of truth
- All infrastructure/application state in Git
- Fully auditable change history
- Automated syncing with repository

**2. Continuous Deployment**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: app-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/company/app-configs
  ref:
    branch: main
  secretRef:
    name: git-credentials
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: app-repo
  path: ./overlays/production
  prune: true
  wait: true
```

**3. Automatic Image Updates**
- Detect new image tags
- Update deployment manifests
- Commit changes back to Git

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImagePolicy
metadata:
  name: app-policy
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: app
  policy:
    semver:
      range: '>=1.0.0'
---
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: app-update
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: app-repo
  git:
    commit:
      author:
        name: Flux
        email: flux@company.com
    push:
      branch: main
  update:
    strategy: Setters
```

**4. Multi-Environment Management**
- Different clusters, same Git source
- Automatic drift detection and correction
- Cluster-specific overlays

**5. Security**
- Fine-grained RBAC
- Secret encryption
- Image signature verification

**6. Observability**
- Alerts on sync failures
- Metrics integration
- Logs tracking

**Flux Deployment Architecture:**

```yaml
# 1. Install Flux
# 2. Create source
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: production-repo
spec:
  interval: 30s
  url: https://github.com/company/production
  ref:
    branch: main
---
# 3. Create Kustomization
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: production
spec:
  sourceRef:
    kind: GitRepository
    name: production-repo
  path: ./clusters/prod
  interval: 5m
  prune: true
  wait: true
  postBuild:
    substitute:
      ENVIRONMENT: production
      CLUSTER_NAME: prod-us-east-1
```

---

## 12. How does Flux deployment work?

### Answer:

Flux uses Git as source of truth and automatically reconciles cluster state with repository state.

**Flux Architecture:**

```
Git Repository
    ↓
Flux Source Controller
    ↓
Flux Kustomize Controller
    ↓
Kubernetes API Server
    ↓
Deployment/StatefulSet/Etc
```

**Detailed Workflow:**

**1. Repository Source**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: app-source
  namespace: flux-system
spec:
  interval: 1m                          # Check every minute
  url: https://github.com/company/app
  ref:
    branch: main
  suspend: false                        # Enable/disable syncing
  secretRef:
    name: github-credentials            # SSH/PAT credentials
```

**2. Flux Reconciliation Loop**
```
1. Source Controller Clones Repository
2. Detects Changes (every interval)
3. Kustomize Controller Renders Manifests
4. API Server Applies Changes
5. Monitors for Drift
6. Alerts on Failures
7. Stores State in Git
8. Loop Repeats
```

**3. Complete Deployment Example**

```yaml
# Repository source
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  url: https://github.com/company/myapp-kustomize
  ref:
    branch: main
  secretRef:
    name: github-token
---

# Deployment reconciliation
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp-staging
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: myapp
  path: ./overlays/staging
  prune: true                           # Delete removed resources
  wait: true                            # Wait for deployment
  timeout: 5m
  postBuild:
    substitute:
      ENVIRONMENT: staging
---

# Image automatic update
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageRepository
metadata:
  name: myapp-images
  namespace: flux-system
spec:
  image: myregistry.azurecr.io/myapp
  interval: 5m
  secretRef:
    name: azure-registry
---

# Update policy
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImagePolicy
metadata:
  name: myapp-policy
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: myapp-images
  policy:
    semver:
      range: ^1.0.0    # Match v1.x.x versions
---

# Automated image update
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: myapp-auto-update
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: myapp
  git:
    commit:
      author:
        name: Flux Automation
        email: flux@company.com
    push:
      branch: main
  update:
    strategy: Setters
    path: ./overlays/staging
```

**4. Monitoring & Alerts**

```bash
# Check Flux reconciliation status
flux get kustomizations
flux get sources git

# View sync status
kubectl get kustomizations -A
kubectl describe kustomization myapp-staging -n flux-system

# Check for errors
kubectl logs -f deployment/kustomize-controller -n flux-system
kubectl logs -f deployment/source-controller -n flux-system
```

**Flux Advantages Over Manual Deployments:**

| Aspect | Manual | Flux |
|--------|--------|------|
| Configuration Drift | Manual sync needed | Automatic |
| Rollback | Complex | Simple Git revert |
| Audit Trail | Limited | Full Git history |
| Multi-cluster | Repetitive | Unified |
| Secret Management | Risky | Encrypted |
| Disaster Recovery | Manual | Git restore |

---

## 13. What is the name of a storage client?

### Answer:

Storage clients are tools/libraries for interacting with persistent volumes and cloud storage services in Kubernetes.

**Popular Storage Clients:**

**1. CSI (Container Storage Interface) Drivers**
- Standardized interface for storage providers
- AWS EBS CSI Driver
- Azure Disk CSI Driver
- GCP Persistent Disk CSI Driver
- OpenStack CSI Driver

**2. Cloud-Specific Storage Clients**

**AWS:**
```bash
# AWS CLI - for S3, EBS management
aws s3 ls
aws ec2 describe-volumes

# AWS EBS CSI Driver
- ebs.csi.aws.com
```

**Azure:**
```bash
# Azure CLI - for AzureDisk management
az disk list
az storage account list

# Azure Disk/Files CSI Driver
- disk.csi.azure.com
- file.csi.azure.com
```

**GCP:**
```bash
# Google Cloud SDK
gcloud compute disks list

# GCP Persistent Disk CSI Driver
- pd.csi.storage.gke.io
```

**3. NFS Client**
```yaml
provisioner: kubernetes.io/nfs
# Mounts NFS shares as Kubernetes volumes
# Uses: nfs-utils, nfs-kernel-server
```

**4. Storage Provisioners**

| Client | Storage Type | Use Case |
|--------|--------------|----------|
| Local Volume | Local storage | High performance |
| NFS | Network storage | Shared access |
| iSCSI | Block storage | Enterprise |
| GlusterFS | Distributed | Scalability |
| Ceph RBD | Distributed block | HA |
| MinIO | S3-compatible | Object storage |

**5. Practical Storage Example**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-ebs
provisioner: ebs.csi.aws.com            # AWS EBS CSI Driver
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: aws-ebs
  resources:
    requests:
      storage: 50Gi
```

**Recommended Storage Clients by Environment:**

- **Production AWS**: AWS EBS CSI Driver
- **Production Azure**: Azure Disk CSI Driver
- **Production GCP**: GCP Persistent Disk CSI Driver
- **On-Premises**: NFS, Ceph, or GlusterFS
- **Cloud-Native**: Portworx, StorageOS, or Rook
- **Object Storage**: MinIO, S3-compatible clients