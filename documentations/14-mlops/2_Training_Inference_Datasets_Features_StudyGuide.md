# MLOps Deep Dive Sections - Continuation
## Training vs Inference Pipelines, Datasets & Features, Data Collection & Preprocessing

**Part 2 of MLOps Study Guide Continuation**

---

### Training vs Inference Pipelines {#training-vs-inference}

#### Textual Deep Dive

The distinction between training and inference pipelines is critical for production systems. Training happens once (or periodically via retraining); inference happens continuously, processing millions of requests. Architectural requirements differ dramatically.

**Training Pipelines:**

*Characteristics*:
- Batch processing (hours/days acceptable)
- High computational requirements (GPUs common)
- Iterative: tries many configurations
- Temporary outputs (only final model matters)
- No latency SLA
- Expensive (GPU hours cost money)

*Internal Working*:
```
Historical Data (100GB)
         │
         ▼
   Preprocessing
         │
         ▼
   Feature Computation
         │
         ▼
   Model Training
   (SGD, Adam, etc)
         │
         ├─ Iteration 1: Loss 0.45
         ├─ Iteration 2: Loss 0.32
         ├─ Iteration N: Loss 0.18 (BEST)
         │
         ▼
   Model Checkpointing
   (Save every N iterations)
         │
         ▼
   Evaluation on Holdout Set
         │
         ▼
   Loss=0.18 → Save Final Model
```

*Production Patterns*:
1. **Scheduled Retraining**: Daily/weekly on latest data
   - Trigger: Time-based (11pm daily), fixed cadence
   - Data: Accumulate data since last training
   - Output: New model saved to registry
   - Cost: Predictable (fixed compute hours)

2. **Performance-Triggered Retraining**: Retrain when accuracy drops
   - Trigger: Automated alert when F1 < 0.80
   - Data: Recent data after model drift detected
   - Output: New model if improves over current
   - Cost: Unpredictable (depends on drift frequency)

3. **Continuous Training (Online Learning)**: Incrementally update model
   - Trigger: Every N incoming samples or time interval
   - Data: Streaming feedback (with ground truth)
   - Output: Updated model (minor weight adjustments)
   - Cost: Moderate (small training tasks)

*DevOps Best Practices*:
- **Resource Management**: Use spot instances (60-70% cheaper) for non-critical training
- **Checkpointing**: Save model every N iterations to resume if interrupted
- **Distributed Training**: Partition data across GPUs for faster training
- **Experiment Tracking**: Log all hyperparameters, metrics, artifacts
- **Cost Optimization**: Schedule training during off-peak hours (cheaper compute)

*Common Pitfalls*:
- Training on ALL historical data every time (inefficient; use windowed data)
- Insufficient feature engineering effort (80% of time should be here)
- Training on data with future information (data leakage)
- Ignoring training stability (same code ≠ same result due to randomness)

**Inference Pipelines:**

*Characteristics*:
- Real-time or near-real-time
- Should be stateless
- Low latency requirement (<100ms typical)
- High throughput (1000+ requests/sec)
- deterministic: same input → same output always
- Must be reliable (downtime impacts customers)

*Internal Working*:
```
Request from Client
        │
        ├─ Request Authentication & Rate Limiting
        │
        ▼
   Load Model from Cache
   (Pre-loaded for speed)
        │
        ▼
   Input Validation
   (Check schema, types)
        │
        ├─ Fetch Features
        │  (from feature store)
        │
        ▼
   Feature Transformation
   (standardization, encoding)
        │
        ├─ Check Feature Availability
        │  (required features exist)
        │
        ▼
   Model.predict(features)
        │
        ▼
   Post-processing
   (threshold, scaling back)
        │
        ▼
   Response Formatting
   (JSON, protobuf)
        │
        ├─ Logging (for monitoring)
        │
        ▼
   Return Response to Client
   (typically <100ms)
```

*Production Patterns*:
1. **REST API Endpoints**: Standard approach
   - Stateless: Model preloaded in memory
   - Framework: FastAPI, Flask
   - Scaling: Multiple replicas behind load balancer
   - Caching: Cache predictions for same inputs

2. **gRPC Services**: High-performance alternative
   - Protocol Buffers: Efficient serialization
   - Less overhead than REST+JSON
   - Better for high-volume/high-frequency calls
   - Lower latency absolute (but higher operational complexity)

3. **Batch Inference**: Process many predictions together
   - Offline: Run nightly, results in database
   - Use Case: Email campaigns, recommendations
   - Efficiency: Batch processing faster than sequential API calls

4. **Edge Inference**: Models deployed on edge devices
   - Mobile phones: On-device predictions (TensorFlow Lite)
   - IoT devices: Embedded models (ONNX)
   - Advantage: No network latency, privacy-preserving
   - Limitation: Model size constrained

*DevOps Best Practices*:
- **Model Caching**: Pre-load model at startup, don't reload per request
- **Feature Store**: Centralized feature management prevents training/serving skew
- **Circuit Breakers**: Fail gracefully if feature store unavailable
- **Canary Deployment**: Route 5% traffic to new model before full deployment
- **Monitoring**: Alert on latency increase, prediction distribution change

*Common Pitfalls*:
- **Training/Serving Skew**: Different preprocessing in training vs inference
  - Solution: Use same code, containerization ensures consistency
- **Feature Staleness**: Features not computed when needed
  - Solution: Feature store with SLA monitoring
- **Thundering Herd**: All requests hit feature store simultaneously
  - Solution: Caching, rate limiting, request batching
- **Model Loading Latency**: Loading large model on demand causes timeout
  - Solution: Pre-load model at server startup

#### Practical Code Examples

**Training Pipeline (Kubernetes Job)**

```yaml
# training-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ml-training-job-{{ job_id }}
  namespace: mlops
spec:
  backoffLimit: 3  # Retry 3 times before failing
  activeDeadlineSeconds: 86400  # Max 24 hours
  template:
    spec:
      containers:
      - name: trainer
        image: myregistry.azurecr.io/ml-trainer:latest
        command: ["python", "train.py"]
        env:
        - name: EPOCHS
          value: "50"
        - name: BATCH_SIZE
          value: "128"
        - name: MODEL_NAME
          value: "recommendation_v{{ version }}"
        - name: DATA_DATE
          value: "{{ execution_date }}"
        resources:
          requests:
            memory: "32Gi"
            nvidia.com/gpu: "4"  # 4 GPUs
          limits:
            memory: "40Gi"
            nvidia.com/gpu: "4"
        volumeMounts:
        - name: data-volume
          mountPath: /data
        - name: model-volume
          mountPath: /models
        - name: logs-volume
          mountPath: /logs
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: ml-data-pvc
      - name: model-volume
        persistentVolumeClaim:
          claimName: ml-models-pvc
      - name: logs-volume
        persistentVolumeClaim:
          claimName: ml-logs-pvc
      restartPolicy: Never
      tolerations:
      - key: "gpu"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

**Inference Service (FastAPI)**

```python
#!/usr/bin/env python3
"""Production Inference Service with Monitoring"""
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from typing import List, Optional
import logging
import time
import joblib
import numpy as np
from datetime import datetime

app = FastAPI(title="ML Inference Service", version="1.0")
logger = logging.getLogger(__name__)

# Pre-load model at startup
MODEL = None
SCALER = None
FEATURE_STORE_CLIENT = None

@app.on_event("startup")
async def load_model():
    """Load model into memory once at startup"""
    global MODEL, SCALER, FEATURE_STORE_CLIENT
    
    logger.info("Loading model at startup...")
    MODEL = joblib.load("/models/production/current/model.pkl")
    SCALER = joblib.load("/models/production/current/scaler.pkl")
    
    # Initialize feature store connection
    FEATURE_STORE_CLIENT = connect_to_feature_store()
    logger.info("Model and dependencies loaded successfully")

# Request/Response Schemas
class PredictionRequest(BaseModel):
    """Input schema for predictions"""
    customer_id: int
    product_id: int
    context: Optional[dict] = Field(default_factory=dict)

class PredictionResponse(BaseModel):
    """Output schema for predictions"""
    prediction: float
    probability: Optional[float] = None
    model_version: str
    timestamp: str
    execution_time_ms: float

# Health check endpoint
@app.get("/health")
async def health():
    """Liveness probe for container orchestration"""
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "model_loaded": True}

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return {
        "inference_latency_p50": 45,  # In production, track actual metrics
        "inference_latency_p99": 120,
        "cache_hit_rate": 0.65,
        "requests_per_second": 1234
    }

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest, background_tasks: BackgroundTasks):
    """
    Main prediction endpoint
    
    Production considerations:
    1. Input validation (FastAPI handles via Pydantic)
    2. Feature retrieval from feature store
    3. Model inference
    4. Response formatting
    5. Async logging and monitoring
    """
    start_time = time.time()
    
    try:
        # Fetch features from feature store
        features = await FEATURE_STORE_CLIENT.get_features(
            customer_id=request.customer_id,
            product_id=request.product_id,
            online=True  # Get online features (fast)
        )
        
        if features is None:
            raise HTTPException(status_code=404, detail="Features not found")
        
        # Validate feature schema
        if len(features) != 10:
            raise HTTPException(status_code=422, detail="Feature dimension mismatch")
        
        # Preprocess (same as training!)
        features_scaled = SCALER.transform([features])
        
        # Make prediction
        prediction = float(MODEL.predict(features_scaled)[0])
        probability = float(MODEL.predict_proba(features_scaled)[0][1]) if hasattr(MODEL, 'predict_proba') else None
        
        execution_time = (time.time() - start_time) * 1000  # ms
        
        response = PredictionResponse(
            prediction=prediction,
            probability=probability,
            model_version="v1.2.3",
            timestamp=datetime.utcnow().isoformat(),
            execution_time_ms=execution_time
        )
        
        # Log prediction asynchronously (non-blocking)
        background_tasks.add_task(
            log_prediction,
            request.customer_id,
            request.product_id,
            prediction,
            execution_time
        )
        
        # Monitor latency
        if execution_time > 100:
            logger.warning(f"Slow inference: {execution_time}ms for customer {request.customer_id}")
        
        return response
        
    except ValueError as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=422, detail="Invalid features")
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Inference failed")

def log_prediction(customer_id: int, product_id: int, prediction: float, latency_ms: float):
    """Async logging for monitoring and model evaluation"""
    # In production:
    # 1. Log to centralized logging system
    # 2. Track prediction for later evaluation
    # 3. Update metrics/monitoring
    logger.info(f"Prediction - Customer: {customer_id}, Product: {product_id}, " +
                f"Prediction: {prediction:.4f}, Latency: {latency_ms:.1f}ms")

def connect_to_feature_store():
    """Connect to feature store (Redis, Feast, or custom)"""
    # Implementation depends on feature store choice
    pass

# Batch prediction endpoint
@app.post("/predict_batch")
async def predict_batch(requests: List[PredictionRequest]):
    """Batch prediction for offline processing"""
    results = []
    for req in requests:
        result = await predict(req, BackgroundTasks())
        results.append(result)
    return results

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**Deployment Configuration (Docker + Kubernetes)**

```dockerfile
# Dockerfile.inference
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Multi-stage build: final image
FROM python:3.11-slim

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application
COPY inference_service.py .
COPY models/ /models/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

EXPOSE 8000

CMD ["python", "inference_service.py"]
```

```yaml
# inference-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-inference
  namespace: mlops
spec:
  replicas: 5  # Scale for throughput
  selector:
    matchLabels:
      app: ml-inference
  template:
    metadata:
      labels:
        app: ml-inference
        version: v1.2.3  # Enable traffic split for canary
    spec:
      containers:
      - name: inference
        image: myregistry.azurecr.io/ml-inference:v1.2.3
        ports:
        - containerPort: 8000
        env:
        - name: MODEL_VERSION
          value: "v1.2.3"
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "3Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 20
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: ml-inference-service
  namespace: mlops
spec:
  selector:
    app: ml-inference
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ml-inference-hpa
  namespace: mlops
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ml-inference
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### ASCII Diagrams

**Training vs Inference Pipeline Architecture**

```
TRAINING PIPELINE                 INFERENCE PIPELINE
════════════════════════════════  ═════════════════════════════════

(Scheduled Daily 2AM)             (24/7 Real-time)
         │                                │
         ▼                                ▼
┌────────────────────┐          ┌───────────────────────────┐
│ Raw Training Data  │          │ Load Balanced Inference   │
│ (100GB CSV, S3)    │          │ Service (5 replicas)      │
└────────┬───────────┘          └───────────┬───────────────┘
         │                                  │
         ▼                                  ├─→ Port 8000/Replica
┌────────────────────┐          │
│ Data Loading       │          ├─ Feature Store
│ & Preprocessing    │          │  Request
└────────┬───────────┘          │
         │                       ├─ Redis Cache
         ▼                       │  (miss → compute)
┌────────────────────┐          │
│ Feature Transform  │          ├─ Scaler (sklearn)
│ (StandardScaler)   │          │
└────────┬───────────┘          ├─ Model (pickle)
         │                       │
         ▼                       ├─ Batch Processing
┌────────────────────┐          │  (prepare features)
│ Train/Val Split    │          │
│ (80/20)            │          ├─ Prediction
└────────┬───────────┘          │  (model.predict)
         │                       │
         ▼                       ├─ Post-processing
┌────────────────────┐          │  (threshold/scaling)
│ Model Training     │          │
│ (TF/PyTorch)       │          ├─ JSON Response
│ Epochs: 100        │          │
│ Batch Size: 256    │          ├─ Async Logging
└────────┬───────────┘          │  (non-blocking)
         │                       │
         ◄──────────────┬────► ├─ Return Response
    SGD           4 GPUs       └─→ Client (via HTTP)
  Optimization             (<100ms total)

         ▼
┌────────────────────┐
│ Model Evaluation   │
│ Test Set           │
│ Metrics: F1=0.87   │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Model Registry     │
│ Save: v1.2.3       │
│ Metadata: timestamp│
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Approval Gate      │
│ (Human/Automated)  │
└────────┬───────────┘
         │
         ▼ (If approved)
┌────────────────────┐
│ Shadow Deployment  │
│ (0% prod traffic)  │
└────────┬───────────┘
    Wait 24 hours
    Validate quality
         │
         ▼
┌────────────────────┐
│ Canary Deployment  │
│ (5% prod traffic)  │
└────────┬───────────┘
    Monitor 1 hour
    Validate metrics
         │
         ▼
┌────────────────────┐
│ Full Deployment    │
│ (100% traffic)     │
└────────────────────┘
 Duration: ~34 hours
 Resource Cost: ~$40

KEY DIFFERENCES:
╔════════════════════════════════════════════════════╗
║ Training           │ Inference                     ║
╠────────────────────┼───────────────────────────────╣
║ Hours/days         │ <100ms                        ║
║ Batch processing   │ Streaming/online              ║
║ High resource      │ Low resource (serving)        ║
║ One-time/periodic  │ Continuous 24/7               ║
║ Offline            │ Online (must be reliable)     ║
║ Expensive          │ Must be cost-optimized        ║
║ Can be complex     │ Must be fast/simple           ║
║ Failure: retry     │ Failure: impacts users        ║
╚════════════════════╧═════════════════════════════════╝
```

---

### Datasets & Features {#datasets-features}

#### Textual Deep Dive

Data is the foundation of ML systems. Poor quality data produces poor models, no matter how sophisticated the algorithm. DevOps engineers must understand data management, feature engineering, and quality assurance requirements.

**Datasets:**

A dataset combines features (independent variables) and targets/labels (dependent variables). Quality datasets define model ceiling performance.

*Characteristics of Production Datasets*:
1. **Scale**: Production datasets often too large for single machine
   - Typical: 1GB-100GB, processed in batches
   - Large-scale: 1TB-10TB+, requires distributed processing
   - BigData: 10TB+, Spark/Hadoop partition across clusters

2. **Temporal Dynamics**: Data evolves over time
   - Seasonal patterns (higher demand summer vs winter)
   - Trends (customer behavior changing gradually)
   - Concept drift (relationship between features and target changing)
   - Non-stationary (statistics change over time)

3. **Imbalanced Classes**: Rare events (fraud 0.1%, disease 5%)
   - Standard accuracy metric misleading (96% accuracy on fraud by always predicting "no fraud")
   - Requires: stratified sampling, weighted loss functions, SMOTE oversampling

4. **Missing Values**: Real data incomplete
   - Missing completely at random (MCAR): unbiased deletion
   - Missing at random (MAR): selection bias manageable via imputation
   - Missing not at random (MNAR): potentially biased (e.g., rich people omit income)

5. **Data Quality Issues**:
   - Outliers: unusual values (John age=999)
   - Inconsistencies: (start_date > end_date)
   - Duplicates: repeated records
   - Type mismatches: (age="twenty-five" instead of 25)

**Feature Engineering:**

Features are the model's input signals. Quality features determine model performance more than algorithm choice.

*Production Feature Engineering Patterns*:
1. **Domain Knowledge Features**:
   - User tenure (days since signup)
   - Customer lifetime value (accumulated spend)
   - Product popularity (sales in last 30 days)
   - Interaction terms (age × years_of_service)

2. **Temporal Features**:
   - Hour of day (transactions higher evening)
   - Day of week (weekend patterns different)
   - Month/quarter/year (seasonal demand)
   - Days since last activity (recency)

3. **Statistical Features** (automated):
   - Rolling averages (price trend last 7 days)
   - Standard deviation (volatility)
   - Min/max (range)
   - Percentiles (quartiles, deciles)

4. **Text/NLP Features**:
   - TF-IDF (term frequency)
   - Word embeddings (word2vec, GloVe)
   - Sentiment scores (positive/negative)
   - BERT embeddings (modern transformers)

5. **Image/Vision Features**:
   - Pretrained CNN features (ResNet, Inception)
   - Edge detection
   - Color histograms

*DevOps Best Practices for Feature Management*:
- **Feature Store**: Centralized repository prevents duplicate work, ensures consistency
- **Feature Versioning**: Track feature definitions over time (features change)
- **Training/Serving Consistency**: Same preprocessing in training and inference (common cause of model failure)
- **Feature Monitoring**: Alert when feature values change unexpectedly (data quality issue)
- **Feature Selection**: Remove low-signal features to improve generalization

*Common Pitfalls*:
1. **Data Leakage**: Using information not available at prediction time
   - Example: using next day's stock price to predict today's price
   - Solution: temporal ordering; careful feature engineering

2. **Feature Importance Misinterpretation**: High correlation ≠ causation
   - Example: ice cream sales correlated with drowning (both peak in summer)
   - Solution: domain knowledge + multivariate analysis

3. **Overfitting on Features**: Too many features relative to training samples
   - Rule of thumb: samples ≥ 10 × features (better: 100 × features)
   - Solution: feature selection, regularization, dimensionality reduction

4. **Non-Stationarity**: Features/target change over time
   - Example: model trains on old customer behavior, fails on new customers
   - Solution: retraining on recent data, online learning

---

## Dataset Quality Framework (Production)

```
Raw Data Source
        │
        ├─ Schema Validation: Correct columns, types
        │  Alert if: new columns, missing columns
        │
        ├─ Completeness: Missing values <5%
        │  Alert if: null_rate > 5%
        │
        ├─ Uniqueness: No duplicates
        │  Alert if: duplicate_count > threshold
        │
        ├─ Consistency: Values within expected range
        │  Alert if: age < 0, age > 150
        │
        ├─ Timeliness: Data fresh (<24 hours old)
        │  Alert if: last_update > 24 hours
        │
        └─→ Decision Tree:
            All checks pass? → USE DATA
            Any check fail?  → QUARANTINE, INVESTIGATE, ALERT
```

#### Practical Code Examples

**Feature Engineering Pipeline**

```python
#!/usr/bin/env python3
"""Production Feature Engineering"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

class FeatureEngineer:
    """Transform raw data into model-ready features"""
    
    def __init__(self, reference_date=None):
        self.reference_date = reference_date or datetime.now()
        self.feature_config = {}
    
    def create_temporal_features(self, df: pd.DataFrame, date_col: str) -> pd.DataFrame:
        """Extract temporal patterns"""
        df = df.copy()
        df[date_col] = pd.to_datetime(df[date_col])
        
        # Calendar features
        df['hour'] = df[date_col].dt.hour
        df['day_of_week'] = df[date_col].dt.dayofweek
        df['day_of_month'] = df[date_col].dt.day
        df['month'] = df[date_col].dt.month
        df['quarter'] = df[date_col].dt.quarter
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
        
        # Recency features
        df['days_since_event'] = (self.reference_date - df[date_col]).dt.days
        
        return df
    
    def create_aggregation_features(self, df: pd.DataFrame, group_col: str, 
                                   value_col: str, windows=[7, 30, 90]) -> pd.DataFrame:
        """Create rolling window aggregations"""
        df = df.copy()
        df = df.sort_values('date')
        
        for window in windows:
            # Rolling mean
            df[f'{value_col}_mean_{window}d'] = \
                df.groupby(group_col)[value_col].rolling(window=window).mean().reset_index(0, drop=True)
            
            # Rolling std
            df[f'{value_col}_std_{window}d'] = \
                df.groupby(group_col)[value_col].rolling(window=window).std().reset_index(0, drop=True)
            
            # Rolling sum
            df[f'{value_col}_sum_{window}d'] = \
                df.groupby(group_col)[value_col].rolling(window=window).sum().reset_index(0, drop=True)
        
        return df
    
    def create_interaction_features(self, df: pd.DataFrame, features: list) -> pd.DataFrame:
        """Create feature interactions"""
        df = df.copy()
        
        for i in range(len(features)):
            for j in range(i+1, len(features)):
                feat1, feat2 = features[i], features[j]
                
                # Multiplication
                df[f'{feat1}_x_{feat2}'] = df[feat1] * df[feat2]
                
                # Division (with safety)
                df[f'{feat1}_div_{feat2}'] = df[feat1] / (df[feat2] + 1e-6)
        
        return df
    
    def apply_transformations(self, df: pd.DataFrame, feature_definitions: dict) -> pd.DataFrame:
        """Apply all feature transformations"""
        df = df.copy()
        
        for feature_name, config in feature_definitions.items():
            if config['type'] == 'temporal':
                df = self.create_temporal_features(df, config['date_col'])
            
            elif config['type'] == 'aggregation':
                df = self.create_aggregation_features(
                    df, config['group_col'], config['value_col']
                )
            
            elif config['type'] == 'interaction':
                df = self.create_interaction_features(df, config['features'])
        
        return df

# Usage
feature_definitions = {
    'temporal_features': {
        'type': 'temporal',
        'date_col': 'transaction_date'
    },
    'aggregation_features': {
        'type': 'aggregation',
        'group_col': 'customer_id',
        'value_col': 'amount',
        'windows': [7, 30, 90]
    },
    'interaction_features': {
        'type': 'interaction',
        'features': ['age', 'income', 'tenure']
    }
}

engineer = FeatureEngineer()
df_engineered = engineer.apply_transformations(raw_data, feature_definitions)
```

**Data Quality Validation**

```python
#!/usr/bin/env python3
"""Data Quality Checks for Production Pipelines"""
import pandas as pd
import logging

logger = logging.getLogger(__name__)

class DataQualityValidator:
    def __init__(self, config: dict):
        self.config = config
        self.validation_results = {}
    
    def validate_schema(self, df: pd.DataFrame) -> bool:
        """Check column names and types"""
        required_columns = self.config.get('required_columns', [])
        column_types = self.config.get('column_types', {})
        
        # Check columns exist
        missing = set(required_columns) - set(df.columns)
        if missing:
            logger.error(f"Missing columns: {missing}")
            return False
        
        # Check types
        for col, expected_type in column_types.items():
            if col in df.columns and not pd.api.types.is_dtype_equal(df[col].dtype, expected_type):
                logger.error(f"Column '{col}' has type {df[col].dtype}, expected {expected_type}")
                return False
        
        return True
    
    def validate_completeness(self, df: pd.DataFrame) -> bool:
        """Check for missing values"""
        max_null_rate = self.config.get('max_null_rate', 0.05)
        
        null_rates = df.isnull().sum() / len(df)
        violations = null_rates[null_rates > max_null_rate]
        
        if len(violations) > 0:
            logger.error(f"Columns exceed null rate {max_null_rate}: {violations.to_dict()}")
            return False
        
        return True
    
    def validate_uniqueness(self, df: pd.DataFrame) -> bool:
        """Check for duplicates"""
        pk_columns = self.config.get('primary_key', [])
        
        duplicates = df.duplicated(subset=pk_columns).sum()
        if duplicates > 0:
            logger.error(f"Found {duplicates} duplicate rows")
            return False
        
        return True
    
    def validate_value_ranges(self, df: pd.DataFrame) -> bool:
        """Check values within expected ranges"""
        value_constraints = self.config.get('value_constraints', {})
        
        for col, constraint in value_constraints.items():
            if col not in df.columns:
                continue
            
            min_val, max_val = constraint.get('min'), constraint.get('max')
            
            violations = df[(df[col] < min_val) | (df[col] > max_val)]
            if len(violations) > 0:
                logger.error(f"Column '{col}' has {len(violations)} values outside range [{min_val}, {max_val}]")
                return False
        
        return True
    
    def validate_distributions(self, df: pd.DataFrame) -> bool:
        """Detect data drift via distribution changes"""
        reference_stats = self.config.get('reference_statistics', {})
        drift_threshold = self.config.get('drift_threshold', 0.2)
        
        for col, ref_mean in reference_stats.items():
            if col not in df.columns:
                continue
            
            current_mean = df[col].mean()
            drift = abs(current_mean - ref_mean) / abs(ref_mean + 1e-6)
            
            if drift > drift_threshold:
                logger.warning(f"Column '{col}' shows potential drift: " +
                              f"ref_mean={ref_mean:.2f}, current={current_mean:.2f}, drift={drift:.2%}")
                return False
        
        return True
    
    def run_all_checks(self, df: pd.DataFrame) -> bool:
        """Execute all data quality checks"""
        logger.info("Starting data quality validation...")
        
        checks = [
            ("schema", self.validate_schema),
            ("completeness", self.validate_completeness),
            ("uniqueness", self.validate_uniqueness),
            ("value_ranges", self.validate_value_ranges),
            ("distributions", self.validate_distributions)
        ]
        
        all_passed = True
        for check_name, check_func in checks:
            try:
                result = check_func(df)
                self.validation_results[check_name] = result
                status = "PASS" if result else "FAIL"
                logger.info(f"Check '{check_name}': {status}")
                all_passed = all_passed and result
            except Exception as e:
                logger.error(f"Check '{check_name}' raised exception: {str(e)}")
                all_passed = False
        
        if all_passed:
            logger.info("All data quality checks PASSED ✓")
        else:
            logger.error("Data quality checks FAILED ✗")
        
        return all_passed

# Configuration
quality_config = {
    'required_columns': ['user_id', 'transaction_amount', 'transaction_date'],
    'column_types': {
        'user_id': 'int64',
        'transaction_amount': 'float64',
        'transaction_date': 'datetime64[ns]'
    },
    'max_null_rate': 0.05,
    'primary_key': ['user_id', 'transaction_date'],
    'value_constraints': {
        'transaction_amount': {'min': 0, 'max': 1000000},
        'user_id': {'min': 1, 'max': 10000000}
    },
    'reference_statistics': {
        'transaction_amount': 150.0,  # Expected mean
    },
    'drift_threshold': 0.20
}

# Usage
validator = DataQualityValidator(quality_config)
is_valid = validator.run_all_checks(incoming_df)

if is_valid:
    # Proceed with training/inference
    model.fit(incoming_df)
else:
    # Quarantine data, trigger alert
    raise Exception("Data quality check failed - pipeline halted")
```

#### ASCII Diagrams

**Feature Engineering Workflow**

```
Raw Business Data
   │
   ├─ Customer: id, name, signup_date
   ├─ Transaction: amount, timestamp
   ├─ Product: category, price
   │
   └─→ Transform Pipeline
       │
       ├─ Temporal Features
       │  • hour, day_of_week, month
       │  • is_weekend
       │  • days_since_signup
       │
       ├─ Aggregation Features
       │  • 7-day rolling average
       │  • 30-day total spend
       │  • 90-day frequency
       │  • Spending volatility
       │
       ├─ Domain Features
       │  • Customer Lifetime Value
       │  • Product popularity
       │  • Repeat purchase rate
       │
       ├─ Interaction Features
       │  • age × tenure
       │  • income / region_median
       │
       └─→ Model-Ready Features (100+ features)
           │
           └─→ Feature Store
               ├─ Version: v1.2.3
               ├─ Last Updated: 2024-04-01
               ├─ Statistics: mean, std saved
               └─ Availability: Monitored
```

---

**I'm continuing with Continued Next sections. Due to length, I'll create one more file to complete the deep dive sections.**

Let me create another file for the final deep dive topics.
