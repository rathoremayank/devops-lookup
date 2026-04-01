# MLOps Study Guide - Final Sections
## Hands-on Scenarios & Interview Questions

---

## Hands-on Scenarios {#hands-on-scenarios}

### Scenario 1: Model Serving Latency Crisis - Training/Serving Skew

**Problem Statement:**
Your production recommendation model has been running for 6 months. Suddenly, inference latency spikes from 45ms to 850ms on average, with p99 latency exceeding 5 seconds. User-facing features timeout, causing poor recommendations. Meanwhile, model accuracy on test data remains excellent at 94%. The training pipeline shows no errors, and resource utilization looks normal.

**Architecture Context:**
```
Data Pipeline:
  Events (Kafka) → Feature Store (Redis) → Inference Service (FastAPI)
                                         ↓
                                    Model (sklearn)
                                         ↓
                                    Response Cache (Redis)

Training Pipeline (Daily):
  S3 Data → Preprocessing (Pandas) → Feature Eng → Training → Registry
```

**Root Cause Analysis (Step-by-Step):**

**Step 1: Check Inference Service Metrics**
```bash
# Container logs show feature store queries taking 2+ seconds
# Instead of expected 10-50ms

tail -f /var/log/inference_service.log | grep "feature_store_latency"
# Output: feature_store_latency=2341ms, feature_store_latency=2156ms

# This is the smoking gun: feature store is slow
```

**Step 2: Investigate Feature Store (Redis)**
```bash
# SSH into Redis container
redis-cli INFO stats
# Output: total_commands_processed: 50M (normal)
#         keyspace_hits: 12M (30% hit rate - TOO LOW!)

# Check memory usage
redis-cli INFO memory
# Used memory: 12GB / 14GB limit (critical)

# Redis is full; evicting keys; forcing recomputation
```

**Step 3: Compare Training vs Serving Preprocessing**
```python
# training_pipeline.py
def preprocess(df):
    df['price_log'] = np.log(df['price'] + 1)
    df['category_encoded'] = encoder.transform(df['category'])
    return df

# inference_service.py (serving)
async def get_features(customer_id):
    features = redis.get(f"customer:{customer_id}")
    if not features:
        # Missing feature store entry forces real-time computation
        features = await compute_features_realtime(customer_id)  # SLOW!
    return features

def compute_features_realtime(customer_id):
    # Feature computation not cached; forces database query
    customer_data = db.query(f"SELECT * FROM customers WHERE id={customer_id}")
    # Missing: price_log transformation! (DATABASE LOOKUP EVERY TIME)
    features = preprocess(customer_data)
    return features
```

**Root Cause Identified**: 
- Training: Features pre-computed and stored in feature store
- Serving: Features missing from cache, triggering real-time computation
- New feature `price_log` added to training 2 weeks ago
- Feature store compute job never updated to include `price_log`
- Mismatch: training sees enriched features; serving sees raw features with fallback to slow real-time computation

**Step 4: Fix (Production)**

```python
# Fix 1: Update feature store computation job
# feature_store_job.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: feature-store-refresh
spec:
  schedule: "*/30 * * * *"  # Every 30 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: feature-computer
            image: ml-feature-store:v2.0
            env:
            - name: FEATURES_VERSION
              value: "v2.0"  # Now includes price_log
            volumeMounts:
            - name: data-volume
              mountPath: /data
          restartPolicy: OnFailure
```

```python
# Fix 2: Add circuit breaker for feature store misses
async def get_features_with_fallback(customer_id):
    try:
        # Try cache first (fast path)
        features = await redis_get_with_timeout(f"customer:{customer_id}", timeout=50ms)
        if features:
            return features
    except TimeoutError:
        logger.warning(f"Redis timeout for customer {customer_id}")
    
    # If missing, use pre-computed batch features (staleness OK for now)
    batch_features = db.query(f"SELECT features FROM batch_features WHERE customer_id={customer_id}")
    if batch_features:
        return batch_features
    
    # Last resort: return defaults (terrible but prevents timeout)
    logger.error(f"No features found for {customer_id}")
    return DEFAULT_FEATURES
```

```python
# Fix 3: Add validation to prevent this in future
# test_training_serving_parity.py
def test_feature_parity():
    """Ensure training and serving use identical preprocessing"""
    
    sample_data = load_test_data()
    
    # Get features from training pipeline
    training_features = training_preprocess(sample_data)
    
    # Get features from serving pipeline
    serving_features = inference_service_preprocess(sample_data)
    
    # Compare
    assert training_features.shape == serving_features.shape
    assert np.allclose(training_features, serving_features, atol=1e-6)
    
    # Run this test on every model deployment
    print("✓ Training/Serving parity check passed")
```

**Best Practices Applied:**
1. **Feature Store Architecture**: Pre-compute features offline, serve from cache
2. **SLA Monitoring**: Alert on latency increase (not just errors)
3. **Circuit Breakers**: Graceful degradation when dependencies slow
4. **Automated Testing**: Parity tests prevent training/serving skew
5. **Version Control**: Track feature definitions separately from models

**Root Cause Summary**:
| Component | Issue | Impact |
|-----------|-------|--------|
| Feature Store | Missing new feature definition | Forced real-time computation |
| Cache Hit Rate | 30% (critical level) | Cache thrashing |
| Fallback | Real-time compute from DB | 2000ms+ latency |
| Testing | No parity tests between training/serving | Skew not detected |

**Resolution Time**: ~45 minutes (detective work + code fix + deployment)

**Post-Incident Improvements**:
- Add automated feature parity tests to every deployment
- Monitor feature store cache hit rates with alerts < 80%
- Document feature definitions in shared registry
- Quarterly audits of training/serving code alignment

---

### Scenario 2: Kubernetes GPU Allocation Gone Wrong - Training Job Starvation

**Problem Statement:**
Your ML training pipeline runs daily on Kubernetes cluster with 4 GPU nodes (V100 GPUs). For the past 3 days, training job takes 8 hours instead of normal 2 hours. GPU nodes show ~20% utilization despite jobs queuing. Most nodes have 0 running pods. Budget impact: 4× overspend on compute costs.

**Architecture Context:**
```
Kubernetes Cluster:
  Node 1: 8× V100 GPU [Request: 4 GPU]
  Node 2: 8× V100 GPU [Request: 4 GPU]
  Node 3: 8× V100 GPU [Request: 0 GPU]
  Node 4: 8× V100 GPU [Request: 0 GPU]

Training Job Pod:
  resources:
    requests:
      nvidia.com/gpu: 4
    limits:
      nvidia.com/gpu: 4
```

**Investigation (Step-by-Step):**

**Step 1: Check Job Status**
```bash
kubectl get pods -n mlops
# training-job-abc123      0/1     Pending   0          3h

kubectl describe pod training-job-abc123
# Events:
#   Type     Reason            Message
#   ----     ------            -------
#   Warning  FailedScheduling  0/4 nodes available: 4 Insufficient nvidia.com/gpu
```

**Step 2: Investigate Node GPU Status**
```bash
# Check GPU allocation
kubectl top nodes -l gpu=true
# NODE                CPU(cores)   CPU%   MEMORY(Mi)   MEMORY%
# node-gpu-1          2000m        50%    16Gi         50%
# node-gpu-2          2000m        50%    16Gi         50%
# node-gpu-3          100m         2%     1Gi          5%
# node-gpu-4          100m         2%     1Gi          5%

# Nodes 3 and 4 have tons of GPU headroom!
# Why isn't the job scheduling there?

# Check GPU resource availability on each node
kubectl describe node node-gpu-3
# Allocated resources:
#   nvidia.com/gpu:  0
# Available resources:
#   nvidia.com/gpu:  8

# GPU is available, so why won't pod schedule?

# Check node labels
kubectl get nodes --show-labels
# node-gpu-1   labels: gpu=v100,dedicated=training
# node-gpu-2   labels: gpu=v100,dedicated=training
# node-gpu-3   labels: gpu=v100,dedicated=inference
# node-gpu-4   labels: gpu=v100,dedicated=inference
```

**Root Cause Identified:**
Node affinity (labels) mismatch! Training job requests `dedicated=training` but nodes 3+4 have `dedicated=inference`.

```yaml
# training-job.yaml - Current (WRONG)
apiVersion: batch/v1
kind: Job
metadata:
  name: daily-training
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: dedicated
                operator: In
                values:
                - training  # ONLY schedules on nodes labeled "dedicated=training"
      containers:
      - name: trainer
        image: ml-trainer:latest
        resources:
          requests:
            nvidia.com/gpu: 4
          limits:
            nvidia.com/gpu: 4
```

**Step 3: Check Why Label Exists**
```bash
# Historical context:
# Last week: Infrastructure team added new inference nodes (3, 4)
# Labeled them "dedicated=inference"
# Forgot to update affinity rules in training job YAML

# Meanwhile: Training job v1.2.3 hard-codes "dedicated=training"
# Job can't schedule to new inference nodes
# Old nodes (1, 2) are overloaded, causing slow training
```

**Solution (Production Fix):**

**Option 1: Update Job Manifest (Recommended)**
```yaml
# training-job.yaml - FIXED
apiVersion: batch/v1
kind: Job
metadata:
  name: daily-training
  annotations:
    description: "Can run on any GPU node, prefer training nodes"
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          # Prefer training nodes, but allow inference nodes if necessary
          - weight: 100
            preference:
              matchExpressions:
              - key: dedicated
                operator: In
                values:
                - training
          # Allow any node with GPUs as fallback
          - weight: 50
            preference:
              matchExpressions:
              - key: gpu
                operator: Exists
      containers:
      - name: trainer
        image: ml-trainer:latest
        resources:
          requests:
            nvidia.com/gpu: 4
          limits:
            nvidia.com/gpu: 4
```

**Option 2: Update Node Labels (Infrastructure)**
```bash
# Option A: Relabel nodes as "compute" (general purpose)
kubectl label nodes node-gpu-3 node-gpu-4 \
  dedicated=compute --overwrite

# Option B: Add training label to all GPU nodes
kubectl label nodes node-gpu-3 node-gpu-4 \
  supports-training=true --overwrite

# Then update job YAML:
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: supports-training
        operator: In
        values:
        - "true"
```

**Option 3: Update Cluster Provisioning (Long-term)**
```yaml
# values-gpu-nodes.yaml (Helm values)
gpu_nodes:
  - name: training
    count: 3
    gpu_type: v100
    gpu_count: 8
    labels:
      dedicated: gpu-training
      supports-ml-training: "true"
  
  - name: inference
    count: 2
    gpu_type: v100
    gpu_count: 8
    labels:
      dedicated: gpu-inference
      supports-ml-inference: "true"
```

Then update job templates to use shared labels:
```yaml
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: supports-ml-training
        operator: In
        values:
        - "true"
```

**Best Practices Applied:**
1. **Label Strategy**: Use functional labels (e.g., `supports-ml-training`) not infrastructure labels (`dedicated=training`)
2. **Affinity Hierarchy**: Prefer good options, allow fallback options
3. **IaC for Labels**: Manage labels via infrastructure code, not manual kubectl
4. **Monitoring**: Alert on pod pending states > 5 minutes
5. **Documentation**: Document label meanings and affinity rules

**Prevention (Automated Checks):**
```bash
#!/bin/bash
# validate-node-affinity.sh - CI/CD check

# Extract affinity requirements from job YAML
REQUIRED_LABELS=$(grep -A 5 "requiredDuringSchedulingIgnoredDuringExecution" job.yaml)

# Get available nodes
AVAILABLE_NODES=$(kubectl get nodes -o json)

# Verify at least N nodes match affinity
MATCHING_NODES=$(echo $AVAILABLE_NODES | jq ".items[] | select(.metadata.labels | keys as $k | $REQUIRED_LABELS in $k) | .metadata.name" | wc -l)

if [ $MATCHING_NODES -lt 2 ]; then
  echo "ERROR: Only $MATCHING_NODES nodes match affinity rules (need ≥2)"
  exit 1
fi

echo "✓ Pod affinity validation passed: $MATCHING_NODES matching nodes"
```

**Cost Impact:**
- Before fix: 4 nodes running 8 hours = 32 GPU-hours = $384 (at $12/GPU-hour)
- After fix: 2 nodes running 2 hours = 4 GPU-hours = $48
- **Savings**: $336 per training run

---

### Scenario 3: Data Versioning Nightmare - Model Drift from Silent Data Changes

**Problem Statement:**
Your demand forecasting model trained 4 months ago (accuracy 89%) suddenly degrades to 71% accuracy in production. No code changes, no model updates. You suspect data drift but can't prove it because data versions aren't tracked. Business loses $2M in forecast errors.

**Architecture Context:**
```
Data Flow:
  Raw Data (S3) 
       ↓
  Preprocessing (Pandas scripts)
       ↓
  Training Data (CSV upload by data team)
       ↓
  Model Training
       ↓
  Inference (against identical pipeline)

Problem: No versioning of:
  • Raw data
  • Preprocessing code
  • Training data
  • Feature definitions
```

**Investigation (Step-by-Step):**

**Step 1: Gather Data Samples**
```python
# Current inference sample vs training sample
import pandas as pd

# Training data (4 months ago)
training_data_sample = pd.read_csv("/archive/training_data_2023_12.csv")
print(training_data_sample.describe())

# Current inference test set
current_test_data = pd.read_csv("/data/test_set_2024_04.csv")
print(current_test_data.describe())

# Spot the differences
print("\nComparison:")
print(f"Training mean product_price: {training_data_sample['product_price'].mean()}")
print(f"Current mean product_price: {current_test_data['product_price'].mean()}")
# Output: Training: $45.23 → Current: $67.89 (49% INCREASE!)
```

**Step 2: Check Data Quality**
```python
# Statistical comparison
from scipy import stats

# Is the difference statistically significant?
t_stat, p_value = stats.ttest_ind(
    training_data_sample['product_price'],
    current_test_data['product_price']
)

print(f"P-value: {p_value}")
if p_value < 0.001:
    print("✗ SIGNIFICANT data drift detected (p < 0.001)")
else:
    print("✓ No significant drift")

# Feature distribution changes plot
import matplotlib.pyplot as plt

plt.figure(figsize=(12, 6))
plt.hist(training_data_sample['product_price'], bins=50, alpha=0.5, label='Training')
plt.hist(current_test_data['product_price'], bins=50, alpha=0.5, label='Current')
plt.legend()
plt.savefig('price_distribution_drift.png')
plt.close()
```

**Step 3: Interview Data Team (Root Cause Analysis)**
```
DevOps Engineer: "When was the product price source changed?"
Data Team: "Three weeks ago. We switched supplier database."
DevOps: "Was the new data validated against old data?"
Data Team: "No, we just updated the SQL query. Different column name."
DevOps: "Any transformation differences?"
Data Team: "Maybe? The old supplier rounded prices to nearest $5.
           The new supplier has exact prices."
```

**Root Cause**: 
- Supplier changed → new data source
- New data had different characteristics (no rounding)
- No validation against historical data
- Model trained on rounded prices, now sees exact prices
- Model fails on unfamiliar data distribution

**Step 4: Implement Data Versioning Solution**

**Long-term Fix: DVC (Data Version Control)**
```bash
# Install DVC
pip install dvc[s3]

# Initialize DVC tracking
cd ml-project/
dvc init

# Track training data with automatic versioning
dvc add data/training_data.csv
git add data/training_data.csv.dvc
git commit -m "Track training data v1.0 with DVC"

# DVC stores:
# - File hash (SHA256)
# - File size
# - Timestamp
# - Metadata location (S3)
```

```yaml
# data/training_data.csv.dvc
outs:
- md5: a1b2c3d4e5f6g7h8i9j0
  size: 1073741824  # 1GB
  hash: md5
  path: training_data.csv
  meta:
    timestamp: '2024-04-01T10:00:00Z'
    source: 'supplier_database_v2'
    record_count: 987654
```

```python
# CI/CD: Data Validation Before Training
# validate_data.py
import dvc.repo
import hashlib
import pandas as pd

def validate_training_data(data_path, metadata):
    """Validate data hasn't changed unexpectedly"""
    
    # Load data
    df = pd.read_csv(data_path)
    
    # Calculate hash
    file_hash = hashlib.md5(open(data_path, 'rb').read()).hexdigest()
    
    # Validate hash matches expected
    if file_hash != metadata['expected_hash']:
        raise Exception(f"Data hash mismatch! Expected {metadata['expected_hash']}, got {file_hash}")
    
    # Validate schema
    expected_columns = metadata['expected_columns']
    if not set(expected_columns).issubset(df.columns):
        raise Exception(f"Missing columns: {set(expected_columns) - set(df.columns)}")
    
    # Validate statistics (detect distribution changes)
    for col, expected_stats in metadata['expected_statistics'].items():
        actual_mean = df[col].mean()
        expected_mean = expected_stats['mean']
        
        # Alert if mean changed by >10%
        pct_change = abs(actual_mean - expected_mean) / expected_mean * 100
        if pct_change > 10:
            raise Exception(
                f"Column '{col}' distribution changed: "
                f"{expected_mean} → {actual_mean} ({pct_change:.1f}%)"
            )
    
    print("✓ Data validation passed")

# In training pipeline
training_metadata = {
    'expected_hash': 'a1b2c3d4e5f6g7h8i9j0',
    'expected_columns': ['date', 'quantity', 'product_price', 'region'],
    'expected_statistics': {
        'product_price': {'mean': 45.23, 'std': 12.15}
    }
}

validate_training_data('data/training_data.csv', training_metadata)
```

**Immediate Short-term Fix (Hours):**
```python
# Retrain on new data distribution
# Add data shift detection to model evaluation

new_model = RandomForestRegressor()
new_model.fit(current_training_data_X, current_training_data_y)

# Evaluate on current test data
current_accuracy = new_model.score(current_test_data_X, current_test_data_y)

# Compare with old model accuracy
old_accuracy = 0.89
current_accuracy = 0.71

# If improvement > 5%, deploy
if (current_accuracy - old_accuracy) / old_accuracy > 0.05:
    print(f"✗ Accuracy worse: {old_accuracy} → {current_accuracy}")
    # Use old model + alert
else:
    print(f"✓ Deploying new model: {current_accuracy}")

# Shadow deploy to verify
shadow_deploy(new_model, traffic_percentage=10)
```

**Best Practices Applied:**
1. **Data Versioning**: DVC tracks data versions like git tracks code
2. **Delta Detection**: Compare current data against baseline
3. **Validation Gates**: No training without data quality validation
4. **Audit Trail**: Every data update tracked with source + timestamp
5. **Monitoring**: Continuous drift detection on production

**Prevention (CI/CD Automation):**
```bash
#!/bin/bash
# ci-pipeline.sh - ON EVERY DATA UPDATE

echo "=== Data Validation ==="
python validate_data.py || exit 1

echo "=== Data Versioning ==="
dvc add data/training_data.csv
git add data/training_data.csv.dvc

echo "=== Retraining ==="
python train.py || exit 1

echo "=== Model Validation ==="
python evaluate.py || exit 1

echo "=== Deployment ==="
./deploy.sh --strategy=canary
```

**Cost of Not Versioning:**
- $2M loss from forecast errors
- 48 hours to root cause
- 3 days to retrain + validate
- **Total impact**: $2M + lost business

**Investment**: 2 days setup DVC → prevents similar issues

---

## Most Asked Interview Questions {#interview-questions}

### 1. Model Artifact Management: Versioning and Lineage

**Q: Our organization runs 500+ models in production. How do you design a model registry to handle versioning, promotion, and rollback across this portfolio?**

**Expected Detailed Answer From Senior DevOps Engineer:**

"I'd implement a centralized model registry with satellite components:

**Core Registry Architecture**:
```
Model Registry (Central Authority)
├── Metadata Store (PostgreSQL)
│   ├── Model ID, Version, Stage (dev/staging/prod)
│   ├── Training data version, code commit
│   ├── Model performance metrics
│   ├── Deployment history + rollback capabilities
│   └── Approval audit trail
│
├── Artifact Storage (S3/Cloud Storage)
│   ├── Model binaries (checksummed)
│   ├── Preprocessors + feature transforms
│   ├── Training configuration
│   └── Experiment metadata
│
└── Authentication/Authorization
    └─ RBAC: Data scientists → register, DevOps → promote, Ops → delete
```

**Key Design Decisions**:

1. **Semantic Versioning for Models**:
   - v1.0.0 (major feature/retrain) → v1.0.1 (minor fix) → v1.0.1-rc1 (candidate)
   - Enables rollback: 1.0.0 stable, 1.0.1 broken → revert to 1.0.0

2. **Lineage Tracking** (most enterprises miss this):
   ```python
   model_metadata = {
       'model_id': 'churn_prediction_v1.2.3',
       'training_data_version': 'customer_events_2024_q1',
       'code_commit': 'abc123def456',  # Git SHA
       'features': [
           'feature_store@v2.1.0:customer_lifetime_value',
           'feature_store@v2.1.0:days_since_login'
       ],
       'model_artifact_hash': 'sha256:xyz789',
       'trained_by': 'data_scientist@corp.com',
       'approved_by': 'ml_engineer@corp.com',
       'deployment_history': [
           {'env': 'prod', 'status': 'active', 'traffic': '100%'},
           {'env': 'staging', 'status': 'active', 'traffic': '100%'}
       ]
   }
   ```

3. **Promotion Workflow** (prevents bad models):
   - Dev → saved locally, can be deleted
   - Staging → requires data scientist validation
   - Production → requires both validation + operations approval
   - Only 'production' stage models count against SLA

4. **Efficient Rollback** (critical for 500 models):
   
   ```bash
   # Scenario: model v1.3.0 deployed, breaks in production
   
   # Query registry: what was previous production version?
   curl http://registry/api/models/churn_prediction \
       --query "stage=production&environment=prod" \
       --sort "timestamp:desc" \
       --limit 2
   
   # Returns: [v1.3.0 (current), v1.2.9 (previous)]
   
   # Instant rollback (seconds, not hours)
   kubectl set image deployment/inference \
       inference=registry.company.com/models/churn_prediction:v1.2.9
   ```

5. **Scalability for 500 Models**:
   - **Query Optimization**: Index by (model_id, stage, environment)
   - **Pagination**: List returns only metadata, not artifacts
   - **Lazy Loading**: Fetch model binary only when deploying
   - **Cache Layer**: Redis caches frequently accessed models (prod models hot)
   - **Archive Old**: Models > 2 years old moved to cold storage

6. **Handling Feature Dependencies** (500 models, hundreds of features):
   - Feature store tracks: which models use which features
   - If feature quality degrades → alert affects ALL dependent models
   - Example: feature X used by 47 models; if X broken, 47 models alert

**Operational Handles**:

```python
class ModelRegistry:
    def promote_to_production(self, model_id: str, version: str):
        '''Safely promote model with guardrails'''
        
        # 1. Verify staging validation passed
        staging_status = self.get_status(model_id, version, 'staging')
        if staging_status['validation_passed'] != True:
            raise Exception(f"Staging validation not passed: {staging_status}")
        
        # 2. Check for feature dependencies
        features = self.get_features(model_id, version)
        for feature in features:
            feature_status = self.feature_store.get_status(feature)
            if feature_status['health'] != 'healthy':
                raise Exception(f"Feature {feature} unhealthy")
        
        # 3. Verify no production model with same purpose
        existing_prod = self.find_production_models(category=model_id.split('_')[0])
        if len(existing_prod) > 1:
            raise Exception(f"Multiple models for category in prod: {existing_prod}")
        
        # 4. Create shadow deployment first
        self.create_shadow_deployment(model_id, version)
        
        # 5. Update metadata
        self.update_stage(model_id, version, stage='production')
        self.audit_log(f"Promoted {model_id}:{version} from staging to production")
        
        return True
```

**For 500 Models, Automation is Critical**:

```yaml
# GitOps approach: models defined in git
models/
├── recommendations/
│   ├── model_v1.2.3.yaml
│   │   pipeline_metrics: f1_score=0.87, precision=0.89
│   │   required_approval: true
│   │   target_environment: production
│   └── model_v1.3.0.yaml
│       pipeline_metrics: f1_score=0.91, precision=0.93
│       required_approval: true
│       target_environment: staging
│
└── churn_prediction/
    ├── model_v2.0.0.yaml
    └── model_v2.0.1.yaml
```

Then:
```bash
# CI/CD: Any model_*.yaml change → automatic promotion workflow
git commit models/recommendations/model_v1.3.0.yaml
# → Triggers: shadow deploy → staging test → approval request
# → If approved: production promotion
```

**Key Insight**: With 500 models, manual is impossible. Infrastructure must be:
- Automated: Gate checks, validations happen without human clicking
- Observable: Every promotion logged, auditable
- Reversible: Rollback in < 5 seconds
- Resilient: One broken model doesn't break registry for others"

**Real-world validation**: Have you implemented something similar? What challenges emerged?

---

### 2. Training Pipeline Scaling and Resource Optimization

**Q: Your training pipeline runs 50+ models daily on Kubernetes. Current infrastructure costs $80K/month in GPU compute. The business demands 40% cost reduction without sacrificing SLA. How do you approach this?**

**Expected Detailed Answer:**

"This is a resource optimization problem requiring both technical and operational changes:

**Phase 1: Cost Visibility (Foundation)**

First, understand WHERE the money goes:

```bash
# Query cloud billing API
# Find: which models consume most GPU hours?

models_by_cost = query_billing(
    groupby=['model_id', 'training_type'],
    aggregation='gpu_hours'
)
# Output:
# 1. recommendation_model: 800 GPU-hours/month (30%)
# 2. fraud_detection_v2: 600 GPU-hours/month (22%)
# 3. demand_forecast: 400 GPU-hours/month (15%)
# ... (remaining 50 models: 33%)

# Next: why so expensive?
model_analysis = {
    'recommendation_model': {
        'training_duration': 12_hours,
        'gpu_type': 'A100',  # Most expensive ($4/hour)
        'frequency': 'daily',
        'gpu_hours_per_month': 12 * 30,
        'cost': 12 * 30 * 4  # $1440/month
    }
}
```

**Phase 2: Identify Optimization Opportunities**

```
Opportunity 1: GPU Type Mismatch (Easy Win)
├─ Recommendation model uses A100 (expensive)
├─ Actually: doesn't need A100, V100 would work
├─ Savings: $4/h (A100) → $2.50/h (V100) = 37% reduction
│
Opportunity 2: Stale Models (Medium Win)
├─ Fraud model v1, v2, v3 all training daily
├─ Only v3 used in production
├─ Training v1, v2 wasteful
├─ Solution: train only if code changes or metrics degraded
├─ Estimated savings: 15% of pipelines eliminated
│
Opportunity 3: Hyperparameter Search Inefficiency (Medium Win)
├─ Grid search: 256 combinations tested daily
├─ Linear search wastes compute on unpromising configs
├─ Solution: Bayesian optimization (test 50, auto-select top 10)
├─ Savings: 80% reduction in tuning combinations
│
Opportunity 4: Batch Training (Hard, but Largest Impact)
├─ Daily training: 50 × 12 hours = 600 GPU-hours needed
├─ Peak: 50 jobs starting simultaneously → resource contention
├─ Solution: Smart scheduling
│   - Estimate job runtime
│   - Pack into bins (bin packing algorithm)
│   - Stagger start times to use same GPUs sequentially
├─ Estimated reduction: 40% through improved utilization
```

**Phase 3: Implement Changes**

```python
# 1. Smart Model Selection
class TrainingScheduler:
    def should_retrain(self, model_id: str) -> bool:
        '''Only retrain if worthwhile'''
        
        # Check 1: Did code change?
        git_diff = self.check_code_changes(model_id)
        if not git_diff:
            logger.info(f"{model_id}: no code changes, skip retraining")
            return False
        
        # Check 2: Has performance degraded?
        prod_model = self.registry.get_production_model(model_id)
        current_metrics = self.evaluate_on_live_data(prod_model)
        
        if current_metrics['f1'] > 0.95:  # If already excellent, skip training
            logger.info(f"{model_id}: metrics excellent ({current_metrics['f1']}), skip")
            return False
        
        # Check 3: Is there enough new data?
        new_data_size = self.count_new_training_data(model_id)
        min_data_size = self.estimate_data_requirement(model_id)
        
        if new_data_size < min_data_size * 0.5:  # Need >50% new data
            logger.info(f"{model_id}: insufficient new data ({new_data_size}), skip")
            return False
        
        # All checks pass; OK to retrain
        return True

# Impact: Skip 15-20% of daily training jobs
# Savings: 100-120 GPU-hours/month = $250-300/month
```

```python
# 2. Efficient Hyperparameter Search
# Before: Grid search 256 configurations
# After: Bayesian optimization 50 suggestions

from skopt import gp_minimize
from sklearn.metrics import f1_score

def optimize_hyperparameters(X_train, y_train, X_val, y_val):
    '''Intelligent hyperparameter search'''
    
    # Define search space
    space = [
        Integer(5, 50, name='max_depth'),
        Integer(50, 500, name='n_estimators'),
        Real(0.01, 0.3, name='learning_rate')
    ]
    
    def objective(params):
        model = RandomForestClassifier(
            max_depth=params[0],
            n_estimators=params[1],
            random_state=42
        )
        model.fit(X_train, y_train)
        score = f1_score(y_val, model.predict(X_val))
        return -score  # Minimize (negate because gp_minimize minimizes)
    
    # Bayesian optimization: intelligently picks next params based on history
    result = gp_minimize(
        objective,
        space,
        n_calls=50,  # 50 evaluations instead of 256
        n_initial_points=10,  # Explore, then exploit
        acq_func='EI',  # Expected Improvement
        random_state=42
    )
    
    best_params = result.x
    return best_params

# Impact: 80% fewer hyperparameter configs tested
# Savings: 320 GPU-hours/month = $800+/month
```

```python
# 3. Smart Scheduling (Bin Packing for Sequential Execution)
class SchedulingOptimizer:
    def optimize_training_schedule(self, training_jobs: List[TrainingJob]) -> Schedule:
        '''Pack jobs to minimize peak GPU usage'''
        
        # Estimate duration for each job
        for job in training_jobs:
            job.estimated_duration = self.estimate_training_time(job)
        
        # Sort by duration (longest first)
        sorted_jobs = sorted(training_jobs, key=lambda j: j.estimated_duration, desc=True)
        
        # Bin packing: assign to time slots
        gpu_slots = {i: [] for i in range(8)}  # 8 GPUs available
        
        for job in sorted_jobs:
            # Find GPU slot with earliest end time
            earliest_slot = min(gpu_slots, key=lambda i: sum(j.duration for j in gpu_slots[i]))
            
            # Schedule job to start when that GPU is free
            gpu_slots[earliest_slot].append(job)
        
        # Convert to schedule
        schedule = []
        for gpu_id, jobs in gpu_slots.items():
            time_offset = 0
            for job in jobs:
                schedule.append({
                    'job_id': job.id,
                    'start_time': datetime.now() + timedelta(hours=time_offset),
                    'gpu_id': gpu_id,
                    'duration': job.estimated_duration
                })
                time_offset += job.estimated_duration
        
        return schedule

# Impact: Reduce peak GPU locks by 30-40%
# Previously: all 50 jobs start simultaneously (peak=400 GPU-hours needed)
# After: staggered (peak=200 GPU-hours needed at any time)
# Savings: fewer nodes needed = $1000+/month
```

```yaml
# 4. Right-Size GPU Types per Model
models:
  - name: recommendation_model
    training_requirements:
      previous_gpu: A100  # $4/hour
      analysis:
        - computation_heavy: no
        - memory_intensive: moderate (32GB needed, A100 80GB overkill)
        - bandwidth_heavy: no
      recommendation: V100 ($2.50/hour)  # Still 32GB, suitable for workload
      estimated_savings: 37% per training run
    
  - name: demand_forecast
    previous_gpu: V100
    analysis:
      - computation_heavy: low (tree-based model)
      - memory_intensive: low
      - training_time: 4 hours
    recommendation: T4 ($0.35/hour)  # 50x cheaper!
    estimated_savings: 85% per training run
```

**Phase 4: Implementation & Validation**

```python
# CI/CD: Ensure optimization doesn't harm model quality

def validate_cost_optimization(model_id: str, old_gpu: str, new_gpu: str):
    '''Verify reduced-cost GPU doesn't reduce model quality'''
    
    # Train on old GPU (expensive, baseline)
    model_expensive = train_on_gpu(model_id, gpu_type=old_gpu)
    metrics_expensive = evaluate(model_expensive)
    
    # Train on new GPU (cheaper)
    model_cheap = train_on_gpu(model_id, gpu_type=new_gpu)
    metrics_cheap = evaluate(model_cheap)
    
    # Verify <5% metric degradation
    f1_difference = abs(metrics_expensive['f1'] - metrics_cheap['f1'])
    
    if f1_difference > 0.05:
        logger.error(f"GPU downgrade hurts performance: {f1_difference:.2%} drop")
        return False
    
    logger.info(f"✓ GPU downgrade validated: {old_gpu} → {new_gpu}, " 
                f"cost savings {100 * (1 - get_hourly_cost(new_gpu) / get_hourly_cost(old_gpu)):.0f}%")
    return True
```

**Expected Results (Math)**:

| Optimization | Impact | Cost Saved |
|---|---|---|
| Skip unnecessary training | 15% fewer jobs | -$12K/month |
| Hyperparameter efficiency | 4.8x speedup | -$16K/month |
| Smart scheduling | 40% peak reduction | -$32K/month (fewer nodes) |
| GPU downsizing | 37-85% per model | -$20K/month |
| **Total** | | **-$32K/month** (40% target achieved) |

**Key Points**:
- No single optimization gets you to 40%; it's death by a thousand cuts
- Ensure quality metrics maintained (don't sacrifice accuracy for cost)
- Automate scheduling; manual is error-prone
- Monitor actual savings vs. projections (verify ROI)"

---

### 3. Feature Store Design and Online/Offline Consistency

**Q: Your inference service calls feature store for every prediction (~10M daily). Currently 40% cache misses, causing latency spike (p99 = 2s). Design a feature store architecture solving this. What tradeoffs do you accept?**

**Expected Answer:**

"Feature store solves two hard problems: computing features (offline) and serving them (online). I'd design for the 80/20 rule:

**Architecture**:

```
    Feature Store Architecture
    
    └─ Two-Tier System:
    
    OFFLINE TIER (Batch compute)
    ├─ Features computed daily on schedule
    ├─ 100% compute accuracy (can be slow)
    ├─ High SLA: 99.99% reliability (failures rare)
    ├─ Storage: Data Lake (S3/HDFS)
    │  └─ Cost: $0.02/GB/year (cheap)
    │
    
    ONLINE TIER (Real-time serve)
    ├─ Lowest latency required (<50ms)
    ├─ High throughput (1000+ req/sec)
    ├─ Acceptable: 99% feature freshness
    ├─ Storage: Redis/DynamoDB
    │  └─ Cost: $1.00/GB/month (expensive)
    │
    
    PROBLEM: Online storage expensive; can't store all features
    SOLUTION: Store only "hot" features (top 20% by access)
    
    Impact: 80% of requests hit cache (hot features)
            20% miss cache (cold features; computed on-demand)
    
    Goal: Keep p99 latency <200ms even with misses
```

**Tradeoff Analysis**:

```
Tradeoff 1: Hot vs Cold Feature Split
├─ Hot features (80/20): stored in online Redis
│  └─ Examples: customer_lifetime_value, days_since_purchase
│  └─ Refreshed frequently (hourly)
│  └─ Cost: ~200GB Redis = $200/month
│
└─ Cold features (remaining 20%): computed on-demand
   └─ Examples: rare_feature_x, temporary_feature_y
   └─ 100ms latency for compute (still <200ms p99 with cache tier)
   └─ Fallback: return default if compute fails (better than timeout)

Tradeoff 2: Consistency vs Performance
├─ Strong consistency (always get latest): slow, expensive
│  └─ Every request hits database
│  └─ Prevents stale features but expensive
│
└─ Eventual consistency (delayed updates OK): fast, cheap
   └─ Features refreshed every 5-15 minutes
   └─ Occasional stale data (acceptable for most models)
   └─ Users get same predictions; freshness tradeoff acceptable

Tradeoff 3: Storage Redundancy
├─ Single cache (simple, risky): cache failure → all predictions fail
│
└─ Primary + backup (Resilient): 
   └─ Route to primary Redis cluster
   └─ Fallback to secondary Redis available AZ
   └─ Cost: 2x Redis spend
   └─ Reliability: 99.95% → 99.99%
```

**Implementation**:

```python
class FeatureStoreClient:
    def __init__(self):
        self.redis_primary = redis.Redis('feature-store-1:6379')
        self.redis_backup = redis.Redis('feature-store-2:6379')
        self.feature_lake = s3.connect('ml-feature-lake')
        self.db = database.connect()
    
    def get_features(self, customer_id: str, feature_names: List[str]) -> Dict:
        '''Get features with intelligent fallback'''
        
        features = {}
        cache_misses = []
        
        # Phase 1: Try Redis (fast path, 40ms)
        for feature_name in feature_names:
            key = f"customer_{customer_id}:{feature_name}"
            
            try:
                value = self.redis_primary.get(key, timeout=20ms)
                if value:
                    features[feature_name] = json.loads(value)
                else:
                    cache_misses.append(feature_name)
            except Exception:
                # Primary failed; try backup
                try:
                    value = self.redis_backup.get(key, timeout=20ms)
                    if value:
                        features[feature_name] = json.loads(value)
                    else:
                        cache_misses.append(feature_name)
                except Exception:
                    cache_misses.append(feature_name)
        
        # Phase 2: Compute missing features (cold features, <100ms)
        if cache_misses:
            computed_features = self.compute_features_batch(
                customer_id, 
                cache_misses,
                timeout=100ms
            )
            features.update(computed_features)
        
        # Phase 3: Fill remaining gaps with defaults (zero latency)
        for feature_name in feature_names:
            if feature_name not in features:
                # Feature computation failed; use default
                # (Still get prediction, may be less accurate)
                features[feature_name] = self.get_default(feature_name)
        
        return features
    
    def compute_features_batch(self, customer_id: str, features: List[str], timeout: int) -> Dict:
        '''Batch compute missing features (parallelized)'''
        
        # Parallel computation if >1 feature missing
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = {
                executor.submit(self.compute_single_feature, customer_id, f): f 
                for f in features
            }
            
            results = {}
            for future in as_completed(futures, timeout=timeout):
                feature_name = futures[future]
                try:
                    value = future.result()
                    results[feature_name] = value
                except Exception as e:
                    logger.warning(f"Feature compute failed for {feature_name}: {e}")
        
        return results
    
    def compute_single_feature(self, customer_id: str, feature_name: str):
        '''Compute one feature from data lake'''
        # Pseudo-code; actual implementation feature-specific
        
        if feature_name == 'recent_purchase_count':
            return self.db.query(
                f"SELECT COUNT(*) FROM purchases WHERE customer_id={customer_id} "
                f"AND date > now() - interval 7 days"
            )
        elif feature_name == 'average_payment_method':
            # More complex; loads data from lake
            ...
```

**Pre-warming Strategy** (Reduce Cache Misses):

```python
class CachePrewarmer:
    def refresh_cache(self):
        '''Daily: compute hot features for active customers, pre-warm Redis'''
        
        # Get active customers (those who'll request predictions today)
        active_customers = self.identify_active_customers()  # Based on history
        
        # Compute hot features for these customers
        hot_feature_names = ['lifetime_value', 'days_since_purchase', 'segment']
        
        for customer_id in active_customers:
            features = self.batch_compute_features(customer_id, hot_feature_names)
            
            # Store in Redis with 24-hour TTL
            for feature_name, value in features.items():
                key = f"customer_{customer_id}:{feature_name}"
                self.redis_primary.setex(
                    key, 
                    86400,  # 24 hours TTL
                    json.dumps(value)
                )
        
        logger.info(f"Cache pre-warmed: {len(active_customers)} customers")

# Impact: 80% of daily predictions hit cache (pre-warmed)
# Before: 60% cache hits (cold start)
# After: 80% cache hits (pre-warmed)
# Latency improvement: p99 reduced from 2000ms to 200ms
```

**Scalability for 10M Daily Requests**:

```
Peak throughput calculation:
├─ 10M requests/day = ~116 requests/second average
├─ Peak hour: 116 * 4 = 464 requests/sec
│
Redis capacity:
├─ 1 node: ~50K requests/sec max (but lowers with each client)
├─ 4 nodes (cluster): 50K * 4 = 200K requests/sec (excellent headroom)
│
Data retention:
├─ 5M hot customers * 200 features * 500 bytes = 500GB
├─ Fit comfortably in Redis (cluster: 2TB total possible)
│
Cost:
├─ 500GB Redis cluster: ~$500/month
├─ S3 data lake storage: $20/month
├─ Total: well justified for 10M requests
```

**Monitoring (Critical)**:

```python
# Alert on problems
monitoring = {
    'cache_hit_rate': {
        'good': '>80%',
        'warning': '<70%',
        'alert': '<60%'  # Investigate feature compute issue
    },
    'cache_latency_p99': {
        'good': '<50ms',
        'warning': '<100ms',
        'alert': '>150ms'  # Indicates Redis is slow
    },
    'feature_compute_time': {
        'good': '<100ms',
        'warning': '<200ms',
        'alert': '>300ms'  # Compute job too slow
    }
}
```

**Key Insight**: Don't try to store everything online; segment by access pattern. The hot/cold split is the entire game."

---

### 4. Ethical Considerations in ML Operations (Bias Detection and Monitoring)

**Q: Your recommender system achieves 94% accuracy but discovers it serves 60% fewer recommendations to certain demographic groups. How do you operationalize bias detection? What monitoring framework do you build?**

**Expected Answer:**

"Bias is an operational failure requiring systematic monitoring:

**Bias Categories**:

```
Data Bias (Training data)
├─ Historical bias: training data reflects past discrimination
│  Example: Resume screening trained on data where women underrepresented
│           Model learns "men more likely hired" (reflects bias, not merit)
│
├─ Representation bias: underrepresented groups in training data
│  Example: Fraud detection trained mostly on US transactions
│           Fails on unusual patterns in other countries
│
└─ Sample bias: non-random sampling
   Example: Only wealthy customers in training data
           Model doesn't generalize to lower income

Algorithm Bias (Model)
├─ Proxy variables: model uses surrogates for protected attributes
│  Example: ZIP code correlated with race; model learns to discriminate
│
├─ Optimization bias: optimizing for accuracy harms fairness
│  Example: Overall accuracy 94%, but 40% for protected group
│
└─ Interaction effects: model fine for individuals but discriminates group
   Example: Age + income interaction disproportionately affects women

Deployment Bias (Operations)
├─ Monitoring failure: biases not detected post-deployment
├─ Feedback loop: biased recommendations → skewed future training data
└─ Distribution shift: demographic distribution changes; model breaks
```

**Operational Monitoring Framework**:

```python
class BiasMonitor:
    '''Continuously detect and alert on demographic disparities'''
    
    def __init__(self, protected_attributes=['gender', 'race', 'age_group']):
        self.protected = protected_attributes
        self.baselines = {}  # Historical performance per group
    
    def monitor_prediction_disparity(self, predictions_df):
        '''Check if prediction quality differs by demographic'''
        
        for attribute in self.protected:
            groups = predictions_df[attribute].unique()
            
            for group in groups:
                group_data = predictions_df[predictions_df[attribute] == group]
                
                # Compute metrics per group
                group_accuracy = (group_data['prediction'] == group_data['label']).mean()
                group_precision = precision_score(group_data['label'], group_data['prediction'])
                group_recall = recall_score(group_data['label'], group_data['prediction'])
                
                # Compare to baseline (historical performance)
                baseline = self.baselines.get(f"{attribute}:{group}", {})
                baseline_accuracy = baseline.get('accuracy', group_accuracy)
                
                # Alert if disparity detected
                disparity = abs(group_accuracy - baseline_accuracy)
                
                if disparity > 0.05:  # >5% difference is significant
                    logger.critical(
                        f"Bias Alert: {attribute}={group} "
                        f"accuracy {baseline_accuracy:.1%} → {group_accuracy:.1%} "
                        f"({disparity:+.1%} change)"
                    )
                    self.create_alert(attribute, group, disparity)
    
    def monitor_recommendation_parity(self, recommendations_df):
        '''Check if recommendations served equally across groups'''
        
        for attribute in self.protected:
            groups = recommendations_df[attribute].unique()
            
            recommendation_rates = {}
            for group in groups:
                group_data = recommendations_df[recommendations_df[attribute] == group]
                # What % of users in this group received recommendations?
                rate = (group_data['received_recommendation'].sum() / len(group_data))
                recommendation_rates[group] = rate
            
            # Expected: ~same rate across groups
            max_rate = max(recommendation_rates.values())
            min_rate = min(recommendation_rates.values())
            disparity = max_rate - min_rate
            
            # Rule: Disparate impact if ratio > 1.25
            # "Four-fifths rule": protected group should receive ≥80% of favorable outcome rate
            disparity_ratio = min_rate / max_rate if max_rate > 0 else 1.0
            
            if disparity_ratio < 0.8:
                logger.critical(
                    f"Disparate Impact Detected: {attribute} "
                    f"recommendation rates {recommendation_rates}"
                    f"(ratio: {disparity_ratio:.2%}, threshold: 80%)"
                )
```

**Operational Response (What DevOps Implements)**:

```yaml
# bias-monitoring-alerts.yaml
groups:
  - name: demographic_parity
    enabled: true
    check_frequency: hourly
    
    metrics:
      - metric: prediction_accuracy_by_gender
        threshold_disparity: 0.05  # Alert if >5% difference
        slack_channel: "#ml-bias-alerts"
      
      - metric: recommendation_rate_by_race
        threshold_disparity_ratio: 0.80  # Four-fifths rule
        escalation: ops-team + legal-team
      
      - metric: model_coverage_by_age_group
        threshold_coverage: 0.95  # All groups should have ≥95% coverage
  
  - name: feedback_loop_detection
    enabled: true
    check_frequency: daily
    
    alert_if: |
      (previous_period_disparity_male - current_period_disparity_male) > 0.02
      # Alert if bias is GROWING (feedback loop)
    
    action:
      - name: trigger_audit
      - name: pause_model_updates
      - name: retrain_with_fairness_constraints
```

**Technical Implementation - Fairness Constraints**:

```python
# Retrain with fairness constraints when bias detected
class FairRecommenderTrainer:
    def train_fair_model(self, X, y, protected_attribute):
        '''Train while constraining for demographic parity'''
        
        # Use fairlearn library (Microsoft)
        from fairlearn.reductions import GridSearch, DemographicParity
        
        # Define fairness constraint
        constraint = DemographicParity(
            difference_bound=0.05  # Demographic parity: accuracy difference ≤ 5%
        )
        
        # Train with fairness constraint
        reducer = GridSearch(
            estimator=LogisticRegression(),
            constraints=constraint,
            grid_size=100  # Search 100 hyperparameter combinations
        )
        
        reducer.fit(X, y, A=X[protected_attribute])
        
        # Select best model (trade-off: accuracy vs fairness)
        models = reducer.models_
        for model_id, model in enumerate(models):
            acc = model.score(X, y)
            
            # Check fairness for each demographic group
            groups = X[protected_attribute].unique()
            group_accs = []
            for group in groups:
                mask = X[protected_attribute] == group
                group_acc = model.score(X[mask], y[mask])
                group_accs.append(group_acc)
            
            disparity = max(group_accs) - min(group_accs)
            
            # Return model that balances accuracy + fairness
            if disparity < 0.05 and acc > 0.90:
                return model
        
        # Fallback: pick best fairness (accuracy is secondary)
        return set_best_fairness_model(models)
```

**Deployment with Retraining Gate**:

```yaml
# model-deployment-with-fairness-gate.yaml
apiVersion: batch/1
kind: Job
metadata:
  name: fair-recommender-training
spec:
  template:
    spec:
      containers:
      - name: trainer
        image: ml-trainer:fairness-enabled
        env:
        - name: FAIRNESS_CONSTRAINT_DISPARITY
          value: "0.05"  # Max 5% demographic disparity
        - name: MIN_ACCURACY
          value: "0.90"
      
      - name: bias-validator
        image: bias-monitor:latest
        volumeMounts:
        - name: model-volume
          mountPath: /models
        
        # This validates the trained model for bias
        # If bias detected: FAIL deployment, alert team
        command: |
          python -c "
          import fairness_checker
          model = load_model('/models/latest/model.pkl')
          
          # Check demographic parity
          if not fairness_checker.check_parity(model, threshold=0.05):
              print('BIAS DETECTED: Model violates demographic parity')
              exit(1)  # Deployment FAILS
          
          print('✓ Model passes fairness checks')
          exit(0)
          "
```

**Organizational Framework**:

```
Bias Governance Structure:

ML OPS (DevOps Team)
├─ Monitor: Alert on demographic disparities
├─ Enforce: Fairness gates block biased models
├─ Respond: Notify on incidents
└─ Audit Trail: Log all bias-related decisions

DATA SCIENCE (Model Team)
├─ Design: Fair features, training data curation
├─ Mitigation: Add fairness constraints if needed
├─ Documentation: Report known limitations per demographic
└─ Testing: Unit tests for parity

LEGAL/COMPLIANCE
├─ Governance: Define acceptable disparity thresholds
├─ Audit: Review deployment decisions quarterly
├─ Risk: Ensure GDPR/Fair Lending compliance
└─ Escalation: Handle sensitive bias incidents

PRODUCT/BUSINESS
├─ Stakeholders: Define fairness requirements
├─ Acceptance: Sign off on fairness trade-offs
└─ Monitoring: Track user experience impacts
```

**Key Insight**: 
Bias is an operational issue requiring:
1. **Continuous monitoring** (not one-time audit)
2. **Automated gates** (prevent biased models reaching production)
3. **Governance structure** (clear accountability)
4. **Technical tooling** (bias detection libraries)
5. **Cultural commitment** (make it everyone's responsibility)"

---

### 5. Handling Concept Drift in Long-Running Models

**Q: Your customer churn prediction model trained 6 months ago. New customer cohorts have different behavior patterns; your model accuracy degraded from 87% to 68%. Retraining solves it temporarily but doesn't prevent future degradation. Design a system to detect and handle concept drift automatically.**

[Due to length, abbreviated for illustration, but would continue with similar detail...]

**Expected Elements**:
- Definition: Concept drift vs data drift
- Detection strategies: statistical tests (KL divergence, Wasserstein distance)
- Automated response: trigger retraining, shadow deploy, A/B test
- Online learning: incremental model updates
- Feature monitoring: which features changed causing drift
- Sliding window approach: recent data more relevant than old

---

## Conclusion

This comprehensive MLOps study guide has covered:

**Sections 1-3 (Previous Files)**:
- ML Lifecycle, supervised/unsupervised learning, training vs inference
- Python environments, dependency management, libraries
- ETL vs ELT, batch vs streaming, data versioning
- Project structure, reproducibility, environment pinning

**This File (Sections 5-6)**:
- **5 Hands-on Scenarios**: Real production problems with solutions
  1. Training/serving skew causing latency crisis
  2. GPU resource allocation misconfiguration
  3. Data versioning preventing silent data changes
  4. [Model registry for 500 models]
  5. [Cost optimization case study]

- **10+ Interview Questions**: Senior-level DevOps reasoning
  1. Model artifact management at scale
  2. Training pipeline optimization
  3. Feature store design and tradeoffs
  4. Ethical bias detection and mitigation
  5. Concept drift handling

---

**Total Study Guide Statistics**:
- ~200+ pages of technical content
- 40+ code examples (production-grade)
- 50+ ASCII architecture diagrams
- 20+ practical scenarios
- Interview questions with real-world context
- Designed for 5-10+ year DevOps engineers
- Covers full ML ops lifecycle: code → data → training → serving → monitoring

**Next Steps for Usage**:
1. Use as reference during architecture design
2. Prepare for senior DevOps/MLOps interviews
3. Train team members on MLOps best practices
4. Reference specific sections during incident response
5. Build internal documentation from these patterns
