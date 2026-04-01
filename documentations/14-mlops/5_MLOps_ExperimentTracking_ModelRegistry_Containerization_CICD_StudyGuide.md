# MLOps: Experiment Tracking, Model Versioning, Containerization & CI/CD

**Target Audience:** Senior DevOps Engineers (5-10+ years experience)  
**Level:** Advanced Production Patterns  
**Focus:** Enterprise-scale ML infrastructure, governance, and automation

---

## Table of Contents

### Part 1: Foundation
- [1. Introduction](#1-introduction)
- [2. Foundational Concepts](#2-foundational-concepts)

### Part 2: Core Topics
- [3. Experiment Tracking & Metadata](#3-experiment-tracking--metadata)
- [4. Model Versioning & Registries](#4-model-versioning--registries)
- [5. Containerization for ML](#5-containerization-for-ml)
- [6. CI/CD for ML](#6-cicd-for-ml)

### Part 3: Advanced Implementation
- [7. Hands-on Scenarios](#7-hands-on-scenarios)
- [8. Interview Questions](#8-interview-questions)

---

## 1. Introduction

### 1.1 Overview of MLOps

MLOps (Machine Learning Operations) is the discipline of applying DevOps principles, practices, and cultural mindset to machine learning systems. It bridges the gap between traditional software operations and the unique challenges of ML workloads: experimentation, non-determinism, data dependency, and model lifecycle management.

**Key Distinction from Traditional DevOps:**
- **Traditional DevOps:** Manages code → build → deploy → monitor
- **MLOps:** Manages data → experiments → models → deployments → monitoring with continuous retraining

MLOps encompasses the complete ML lifecycle:
1. **Experiment Phase:** Iterative development, parameter tuning, model selection
2. **Model Phase:** Registry, versioning, promotion, governance
3. **Deployment Phase:** Containerization, orchestration, serving
4. **Operations Phase:** Monitoring, retraining triggers, drift detection

### 1.2 Why MLOps Matters in Modern DevOps Platforms

**Production Challenges Resolved:**

| Challenge | Impact | MLOps Solution |
|-----------|--------|-----------------|
| **Reproducibility** | Same code produces different results with different data or seeds | Experiment tracking with full metadata capture |
| **Model Governance** | No audit trail for model changes, compliance violations | Model registry with versioning and lineage |
| **Training at Scale** | Distributed training without proper orchestration | CI/CD pipelines with containerized workloads |
| **Deployment Risk** | Models break in production without detection | Comprehensive monitoring and drift detection |
| **Collaboration** | Data scientists and engineers working in silos | Shared artifact stores and standardized workflows |
| **Cost Control** | Unchecked GPU resource usage, inefficient training | Resource quotas, job scheduling, cost attribution |

**Enterprise Requirements:**
- Compliance and audit trails (financial, healthcare, government)
- Multi-region, multi-cloud deployment strategies
- Real-time model performance monitoring
- Automated rollback and canary deployments
- Resource optimization and cost management

### 1.3 Real-World Production Use Cases

#### Use Case 1: Financial Risk Modeling
**Scenario:** A financial institution runs daily credit risk models on millions of transactions.

**MLOps Requirements:**
- Minutes-level re-training on new market data
- Exact reproducibility for regulatory audits
- Sub-millisecond inference (<1ms SLA)
- Model explainability for risk decisions
- Automatic rollback on prediction drift > 10%

**Architecture:**
```
Data Pipeline (daily) 
  → Experiment Tracking (hyperparameter grid search)
  → Model Registry (versioning + approval workflow)
  → Containerized Serving (GPU-optimized inference)
  → Monitoring Dashboard (detect drift, alert)
  → Auto-rollback (previous known-good model)
```

#### Use Case 2: E-Commerce Recommendation System
**Scenario:** Real-time product recommendations affecting $billions in annual revenue.

**MLOps Requirements:**
- A/B testing framework (champion vs. experimental models)
- Shadow mode deployment (run new model without affecting users)
- Millisecond inference latency (<50ms)
- Multi-armed bandit strategies for exploration
- Continuous retraining (hourly/daily based on user behavior)

**Architecture:**
```
User Events (real-time) 
  → Feature Store 
  → Model Serving (A/B routing, shadow mode)
  → Performance Metrics (CTR, conversion)
  → Experiment Tracking (log model variants)
  → Conditional Retraining (on metric degradation)
```

#### Use Case 3: Healthcare Diagnostics
**Scenario:** Medical imaging AI for early disease detection.

**MLOps Requirements:**
- FDA validation and audit trails (21 CFR Part 11 compliance)
- Model card documentation (demographics, limitations, performance metrics)
- Explainability and interpretability for clinical review
- Data lineage and provenance
- Handling class imbalance and edge cases (rare diseases)

**Architecture:**
```
Clinical Data (DICOM images) 
  → Experiment Tracking (data splits, seed values, model versions)
  → Validation Gates (accuracy, fairness, robustness tests)
  → Model Registry (clinical sign-off workflow)
  → Containerized Deployment (isolated inference environments)
  → Audit Logging (all predictions, model decisions)
```

### 1.4 Where MLOps Appears in Cloud Architecture

**Typical Enterprise MLOps Stack:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Data Sources (Ingestion)                     │
│  (Databases, Data Lakes, APIs, Streaming, Real-time Events)    │
└──────────────────────┬──────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│              Data Pipeline & Feature Store                      │
│  (ETL/ELT, Feature Engineering, Data Validation, Versioning)   │
└──────────────────────┬──────────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┬──────────────────┐
        │                             │                  │
┌───────▼────────────┐    ┌──────────▼────────┐  ┌─────▼──────────┐
│ Experiment Tracking│    │  Model Registry   │  │ Artifact Store │
│ (MLflow, W&B, etc) │    │ (DVC, MLflow, etc)│  │ (Versing, Prod)│
└───────┬────────────┘    └──────────┬────────┘  └─────┬──────────┘
        │                             │                 │
        └─────────────────┬───────────┴─────────────────┘
                          │
        ┌─────────────────▼──────────────────┐
        │    Model Training Environment      │
        │  (Kubernetes, Distributed Training)│
        │  (Container Registry, Resource Pool)
        └─────────────────┬──────────────────┘
                          │
                          │ (Containerized models)
        ┌─────────────────▼──────────────────────────────┐
        │          Model Serving Layer                   │
        │  (KServe, Seldon, Model Servers, APIs)        │
        │  (Batch, Real-time, Stream Processing)        │
        └─────────────────┬──────────────────────────────┘
                          │
   ┌──────────────────────┴───────────────────────┐
   │                                              │
┌──▼─────────────┐                     ┌─────────▼──┐
│  API Gateway   │                     │  Monitoring│
│  & Auth Cache  │                     │  & Logging │
└────────────────┘                     └───────────┘
   │
   └──→ Client Applications
```

**Regional Deployment Patterns:**

- **Primary Region:** Training, experiment tracking, central registry
- **Secondary/Edge Regions:** Model serving, inference caching, compliance zones
- **Disaster Recovery:** Cross-region model registry replication, failover models

---

## 2. Foundational Concepts

### 2.1 Key Terminology

#### Core ML Workflow Terms

| Term | Definition | DevOps Relevance |
|------|-----------|------------------|
| **Experiment** | Single training run with specific data, hyperparameters, and code version | Reproducibility requirement; requires artifact capture |
| **Hyperparameter** | Model configuration set before training (learning rate, batch size, etc.) | Must be version-controlled; enables search/tuning |
| **Artifact** | Output from training (model weights, logs, metrics, plots) | Requires versioning and storage strategy |
| **Dataset Version** | Immutable snapshot of training/validation data | Critical for reproducibility; enables rollback |
| **Model Checkpoint** | Intermediate model state during training | Enables recovery, distributed training |
| **Vectorization** | Numerical transformation of raw data for model consumption | Data dependency; requires versioning |
| **Metadata** | Contextual information about experiments/models (tags, author, timestamp) | Enables search, lineage, governance |
| **Model Card** | Documentation of model purpose, performance, limitations | Governance; compliance requirement |
| **Data Card** | Documentation of dataset characteristics, sources, limitations | Governance; bias/fairness assessment |
| **Feature Store** | Centralized repository for computed features across organization | Reduces training/serving skew, enables reusability |

#### MLOps-Specific Terms

| Term | Definition | Implementation Pattern |
|------|-----------|----------------------|
| **Training Pipeline** | Automated data → model sequence (ELT, feature engineering, training) | CI/CD stage, triggered by data/code changes |
| **Inference Pipeline** | Optimized sequence for making predictions (feature computation, model loading, post-processing) | Containerized service, optimized for latency |
| **Model Registry** | Centralized system for model storage, versioning, promotion | Single source of truth for production models |
| **Model Promotion** | Moving model through stages (experimental → staging → production) | Approval workflows, gate conditions |
| **Model Drift** | Performance degradation due to distribution shift in production data | Monitoring metric; triggers retraining |
| **Data Drift** | Changes in input data distribution | Triggers retraining, alerts |
| **Shadow Deployment** | Running new model in parallel without affecting users | A/B testing, risk mitigation |
| **Canary Deployment** | Releasing model to small user percentage, monitoring before full rollout | Progressive rollout pattern |
| **Blue-Green Deployment** | Maintaining two production environments, switching traffic atomically | Zero-downtime deployment strategy |

### 2.2 Architecture Fundamentals

#### The ML Lifecycle vs. Software Lifecycle

**Traditional Software:**
```
Code → Build → Test → Deploy → Monitor → (fix bug) → repeat
```

**ML Workflows:**
```
Data → Experiment → Model Selection → Validation → Deploy → Monitor
  ↓                                                         ↓
(ongoing)←───── Retraining (on drift/schedule) ←──────(degradation)
```

**Key Differences:**

1. **Non-deterministic Code**
   - Same code + same inputs may produce different results (random seeds, floating-point operations)
   - Requires full execution context capture (Random seed, data version, library versions)
   - Example: Two identical training runs with different random seeds produce different models

2. **Data Dependency**
   - Model quality fundamentally depends on data quality/distribution
   - Code changes alone don't guarantee better performance
   - Requires data versioning, validation gates, distribution shift detection

3. **Continuous Experimentation**
   - ML teams run hundreds of experiments weekly
   - Each experiment is a "release candidate"
   - Requires experiment tracking infrastructure to manage scale

4. **Offline Validation Gap**
   - Validation metrics (accuracy, AUC) don't guarantee production performance
   - Models can be technically accurate but miss business requirements
   - Requires production monitoring and feedback loops

#### Reproducibility as the Foundation

```
Reproducibility Matrix:
┌────────────────┬─────────────┬─────────────┐
│                │ Same Code   │ Same Data   │
├────────────────┼─────────────┼─────────────┤
│ Deterministic  │ YES         │ YES         │
│ Random Seeds   │ PARTIAL*    │ YES         │
│ Distributed    │ NO          │ YES         │
│ GPU-Dependent  │ NO          │ NO          │
└────────────────┴─────────────┴─────────────┘

* Requires fixing random seed in code + same library versions
```

**Reproducibility Layers:**

| Layer | Control | Method |
|-------|---------|--------|
| **Code** | Exact version (git hash/tag) | Store commit hash |
| **Data** | Exact dataset (immutable snapshot) | Store data hash/version ID |
| **Environment** | Library versions | requirements.txt / poetry.lock / conda.yml |
| **Randomness** | Seed values | Capture seeds in metadata |
| **Infrastructure** | Hardware consistency | Container specifications, GPU driver versions |

**Real-world Example - Training Reproducibility Issue:**

```python
# First experiment run (date: 2025-01-15)
np.random.seed(42)
model = trainModel(data_version="prod-2025-01-15")
# Accuracy: 0.925

# Second experiment run (date: 2025-02-15, same code)
np.random.seed(42)
model = trainModel(data_version="prod-2025-02-15")
# Accuracy: 0.891  ← Different result!

# Root cause: data_version changed (2025-01-15 vs 2025-02-15)
# Solution: Experiment tracking captures both versions, enables investigation
```

### 2.3 Important DevOps Principles Applied to MLOps

#### 1. **Infrastructure as Code (IaC) for ML**

**Traditional IaC:** Define cloud resources (VMs, networks, databases)

**ML IaC:** Define experiment environments, training infrastructure, serving infrastructure

```yaml
# Example: Training Environment Definition
apiVersion: batch/v1
kind: Job
metadata:
  name: model-training-job
spec:
  template:
    spec:
      containers:
      - name: trainer
        image: ml-trainer:v2.1.4  # Versioned image
        resources:
          requests:
            nvidia.com/gpu: 8
        env:
        - name: EXPERIMENT_ID
          value: exp-2025-01-15-001
        - name: DATA_VERSION
          value: prod-2025-01-15
        volumeMounts:
        - name: artifact-store
          mountPath: /artifacts
      volumes:
      - name: artifact-store
        nfs:
          server: artifact-store.internal
          path: /ml-artifacts
```

#### 2. **Observability in ML Systems**

**Three Pillars Extended for ML:**

| Pillar | Traditional | ML Addition |
|--------|-------------|------------|
| **Logs** | Application events, errors | Training logs, hyperparameters, data statistics |
| **Metrics** | CPU, memory, latency | Model accuracy, loss curves, data drift, prediction distribution |
| **Traces** | Request flow | Feature computation → model prediction → post-processing |

**ML-Specific Metrics:**
```
Training Metrics:
- Loss over time
- Gradient statistics (norm, sparsity)
- Learning rate effectiveness
- Hardware utilization (GPU/TPU)

Model Metrics:
- Performance by data segment (e.g., accuracy by demographic)
- Prediction latency distribution
- Cache hit rates

Production Metrics:
- Prediction volume and throughput
- Latency percentiles (p50, p95, p99)
- Model prediction distribution shift
- Data drift indicators
- Business metrics (CTR, conversion, revenue impact)
```

#### 3. **Continuous Integration Applied to ML**

**Software CI:**
```
Code → Lint → Unit Tests → Build → Deploy
```

**ML CI:**
```
Data → Data Validation → Feature Engineering → Unit Tests → 
Model Training → Model Tests → Registry Upload → Staging Deploy
```

**ML-Specific Test Gates:**

| Test Type | Validation | Pass Criteria |
|-----------|-----------|---------------|
| **Data Validation** | Schema, null rates, value ranges, distribution | Schema match, <5% nulls, within expected ranges |
| **Feature Tests** | Feature correctness, no data leaks, distribution | No NaNs, no target leakage, distribution stable |
| **Model Tests** | Training succeeds, metrics acceptable | Training loss < threshold, accuracy > baseline |
| **Bias Tests** | Fairness metrics across demographics | Demographic parity > threshold |
| **Regression Tests** | Performance vs. previous model | Accuracy loss < 2%, latency same |
| **Integration Tests** | Feature store + model inference | End-to-end inference < 100ms |

#### 4. **Deployment Strategies for ML**

**Canary Deployment:**
```
Day 1: Route 5% traffic to new model, monitor
Day 2: Route 25% traffic (if metrics OK)
Day 3: Route 100% traffic (full rollout)
Rollback: If error rate > 1% or latency > 200ms
```

**Shadow Deployment:**
```
Production Flow:
Raw Request → Feature Computation → [Production Model] → Prediction
                                    → [Shadow Model]    → Log only

Result: Compare predictions without affecting users
Decision: Deploy shadow after validation
```

**Blue-Green Deployment:**
```
Blue Environment (Current):
- Traffic: 100%
- Model: v2.1.0
- Serving: Running, validated

Green Environment (New):
- Traffic: 0%
- Model: v2.2.0
- Serving: Running, validated

Switchover:
Blue ← → Green (atomic traffic switch)
```

### 2.4 Best Practices for ML Infrastructure

#### 1. **Separation of Concerns**

```
Layer 1 - Data:
├── Raw Data (immutable, versioned)
├── Processed Data (transformation history tracked)
└── Feature Store (computed features, cached)

Layer 2 - Experiments:
├── Experiment Tracking (metrics, artifacts, metadata)
├── Model Registry (versioning, promotion workflow)
└── Comparison Tools (compare runs, statistical tests)

Layer 3 - Production:
├── Containerized Models (reproducible serving)
├── Model Serving Infrastructure (scaling, load balancing)
├── Monitoring & Alerting (drift, performance, errors)
└── Retraining Triggers (scheduled, on-demand, drift-based)
```

#### 2. **Single Source of Truth Pattern**

**Problem:** Different systems have different model versions
```
Engineer A: Model stored in local laptop
Engineer B: Model stored in shared drive
Engineer C: Model deployed in container registry
Production: Different model running (which one is authoritative?)
```

**Solution:** Model Registry as authoritative source
```
├── Model Registry (Authoritative)
│   ├── Production Models (registered, tested, approved)
│   ├── Staging Models (under review)
│   └── Archived Models (historical)
│
└── All other locations reference the Registry
    (Container images, serving endpoints pull from Registry)
```

#### 3. **Immutability at Scale**

**Data Immutability:**
- Original raw data never modified (append-only logs)
- Transformations create new versions, old versions retained
- Enables rollback, audit, reproducibility

**Artifact Immutability:**
- Model weights: tagged with version, never overwritten
- Training logs: archived with experiment, not removed
- Code: git commits are immutable

**Versioning Strategy:**
```
Model versioning: semantic or timestamp-based
├── v1.0.0-prod     (production, stable)
├── v1.1.0-staging  (under review)
├── v1.2.0-rc       (release candidate)
└── v2.0.0-dev      (development, experimental)

Lineage tracking:
├── Input: dataset-v2.5.3
├── Code: training-job:sha256-abc123
├── Output: model-v1.1.0
└── Metadata: {author, timestamp, hyperparameters, metrics}
```

#### 4. **Cost Optimization Patterns**

**Challenge:** Unchecked GPU resources in training
```
Multiple teams, each running training jobs
→ GPU utilization: 20% average
→ GPU cost: $8,640/month per GPU
→ Total waste: $69,120/month across team
```

**Solution: Resource Quotas & Scheduling**
```
Quota System:
├── Dev environment: 2 GPUs, auto-shutdown after 8 hours
├── Staging environment: 4 GPUs, reserved time slots
└── Production training: 16 GPUs, reserved for critical experiments

Scheduling:
├── Schedule experiments during off-peak hours (10pm - 6am = cheaper)
├── Batch similar jobs together (shared hardware setup)
└── Right-size resources (use CPU for data preprocessing, GPU for training)

Expected improvement: 40-60% cost reduction
```

#### 5. **Security and Compliance Patterns**

**Access Control:**
```
Model artifact access:
├── Read (inference): Any authenticated service
├── Write (training outputs): Only training jobs
├── Promote: Only designated approvers
└── Delete: Only administrators (with audit trail)

Data access:
├── Raw data: Only data engineers + ML engineers
├── Features: ML engineers + serving services
└── Predictions: Client applications (via API)
```

**Audit and Compliance:**
```
Required logging:
├── Who created/modified the model (user identity)
├── When changes occurred (timestamp)
├── What changed (version changes, metadata updates)
├── Why changes occurred (experiment results, business justification)
└── Where deployed (which environments, services)

Compliance gates:
├── Models require approval before production
├── All decisions logged with reason
├── Audit trail retained for 7 years (regulatory requirement)
└── Data lineage traceable to source
```

### 2.5 Common Misunderstandings in MLOps

#### Misunderstanding 1: "MLOps Just Applies DevOps Tools to ML"

**Incorrect Assumption:**
"We can use the same CI/CD pipeline as software engineering. Just add a training step."

**Why This Fails:**
- Software testing validates code logic (deterministic, repeatable)
- ML testing validates model behavior (non-deterministic, data-dependent)
- Software artifacts are code (small, immutable)
- ML artifacts include models, data, metrics (large, interdependent)

**Correct Approach:**
- Adapt DevOps principles, not just tools
- Build ML-specific testing frameworks (data validation, fairness tests)
- Use container orchestration (Kubernetes) but with ML-aware scheduling
- Monitor model performance, not just system metrics

#### Misunderstanding 2: "ML Reproducibility is About Using Same Random Seed"

**Incorrect Assumption:**
"If I set `np.random.seed(42)`, I'll always get the same model."

**Why This Fails:**
```python
# Run 1 (2025-01-15 data)
np.random.seed(42)
model = train(data)  # Accuracy: 0.925

# Run 2 (2025-02-15 data, same seed)
np.random.seed(42)
model = train(data)  # Accuracy: 0.891 ← Different!

# Why? Data changed! (though random seed matches)
```

**Correct Approach:**
- Random seed is necessary but insufficient
- Capture: code version, data version, library versions, infrastructure specs
- Verify reproducibility by re-running experiments
- Use experiment tracking to capture full context

#### Misunderstanding 3: "Model Registry Just Stores Model Files"

**Incorrect Assumption:**
"Model registry = folder with model.pkl files"

**Why This Fails:**
- No version history
- No lineage (which data, which code, who approved)
- No promotion workflow
- No deployment metadata
- Data scientists can't find what model to use

**Correct Approach:**
- Registry tracks: version, status (dev/staging/prod), lineage, metrics
- Stores: model artifacts + metadata + associated data
- Enables: versioning, promotion workflows, rollback
- Integrates: with CI/CD, serving infrastructure, monitoring

```
Model Registry (Correct Implementation):
├── Metadata:
│   ├── Version: v1.2.0
│   ├── Status: production
│   ├── Created: 2025-01-15 14:32:00
│   ├── Creator: data-scientist-team
│   ├── Data Version: prod-2025-01-15
│   ├── Code Commit: abc123def456
│   └── Metrics: {accuracy: 0.925, latency_ms: 42, f1: 0.918}
│
├── Files:
│   ├── model.pkl (weights + architecture)
│   ├── preprocessor.pkl (feature transformations)
│   ├── requirements.txt (dependencies)
│   └── model_card.md (documentation)
│
└── History:
    ├── v1.1.9 → v1.2.0 (metadata, metrics)
    ├── Promotion: staging → production (2025-01-16)
    └── Deployment: served by inference-prod-service
```

#### Misunderstanding 4: "We Don't Need Data Versioning, Just Use Latest Data"

**Incorrect Assumption:**
"Data changes incrementally. Just retrain on newest data."

**Why This Fails:**
- **Reproducibility lost:** Can't reproduce past experiments
- **Drift attribution:** If performance degrades, can't tell if model or data changed
- **Regulatory issue:** Can't prove which data was used for high-stakes decisions
- **Debugging:**  Hard to trace when model broke (was it training code or data?)

**Correct Approach:**
```
Data Versioning Strategy:

Raw Data (Immutable):
├── s3://raw-data/2025-01-15/events.parquet (hash: abc123)
├── s3://raw-data/2025-01-16/events.parquet (hash: def456)
└── s3://raw-data/2025-01-17/events.parquet (hash: ghi789)

Processed Data (Tracked):
├── dataset-v1.0.0 = (raw 2025-01-15) + (schema validation) + (feature eng v1.0)
├── dataset-v1.0.1 = (raw 2025-01-15) + (schema validation) + (feature eng v1.0.1)
└── dataset-v1.1.0 = (raw 2025-01-17) + (schema validation v2) + (feature eng v1.1)

Model Training References:
├── model-v1.0.0 ← dataset-v1.0.0 (code: sha-abc)
├── model-v1.0.1 ← dataset-v1.0.1 (code: sha-abc)
└── model-v2.0.0 ← dataset-v1.1.0 (code: sha-def)

Result: Can reproduce any model by referencing dataset version
```

#### Misunderstanding 5: "CI/CD for ML is Just Running Training in CI"

**Incorrect Assumption:**
"Set up a GitHub Actions workflow that trains the model, push to registry."

**Why This Fails:**
- Training takes hours/days; CI runners have timeouts
- Models need GPU; CI runners don't have GPUs by default
- Large datasets can't fit in CI environment
- Tests pass but model doesn't perform in production

**Correct Approach:**
```
ML-Specific CI/CD Pipeline:

CI Stage (Fast, Lightweight):
├── Data validation (schema, nulls, ranges)
├── Unit tests (feature engineering logic)
├── Model tests (mock training, baseline comparison)
├── Build artifact (container image)
└── Push to registry (tagged with git commit)

CD Stage (Async, Heavy Resources):
├── Trigger: Could be scheduled, on demand, or on data changes
├── Allocate GPU resources from cluster
├── Execute full training (hours/days)
├── Compare metrics vs. baseline
├── If better: promote to staging
├── If worse: archive experiment, notify team

Production Deployment:
├── Manual approval (governance)
├── Canary deployment (5% traffic)
├── Monitor for 24 hours
├── Full rollout or rollback
```

#### Misunderstanding 6: "Model Metrics at Training Time = Production Performance"

**Incorrect Assumption:**
"If validation accuracy is 95%, production model will have 95% accuracy."

**Why This Fails:**
```
Training Environment:
├── Data: Balanced, clean snapshot (2025-01-15)
├── Distribution: Identical to validation set
└── Validation Accuracy: 95%

Production Environment:
├── Data: Live, imbalanced, drifting
├── Distribution: Shifted from training data
│   ├── User demographics changed
│   ├── New product categories introduced
│   └── Competitor entries in market
└── Actual Accuracy: 87% ← 8% degradation!

Problem: Model performance depends on:
├── Model quality (addressed in training)
├── Input data distribution (often ignored)
└── Business context (not measured in accuracy)
```

**Correct Approach:**
- Track distribution shift: data drift detectors
- Define business metrics: revenue impact, not just accuracy
- Monitor all model predictions in production
- Set up automated retraining triggers

---

## 3. Experiment Tracking & Metadata

### 3.1 Core Concepts and Architecture

**Experiment Tracking** is a centralized system for capturing, storing, and managing all metadata associated with ML training runs. Unlike traditional software versioning that tracks code, experiment tracking captures:

- **Hyperparameters:** Training configuration (learning rate, batch size, epochs, regularization)
- **Metrics:** Performance measurements (accuracy, loss, AUC, custom metrics)
- **Artifacts:** Output files (model checkpoints, visualizations, logs, data versions)
- **Parameters:** Code state (git commit, branch, environment variables)
- **Metadata:** Contextual information (user, timestamp, tags, notes)

**Why Experiment Tracking is Critical:**

```
Problem Without Experiment Tracking:
├── Run model training → Results: Accuracy 0.892
├── Tweak hyperparameters → Results: Accuracy 0.901 (but forgot exact changes)
├── Run again → Results: Accuracy 0.891 (different? environment changed?)
├── Manager asks: "Which model is best to deploy?"
├── Response: "I... I'm not sure. Let me check my laptop."
└── Repeat experiments wasted: 40 hours of GPU time

Solution With Experiment Tracking:
├── All experiments logged automatically
├── Compare side-by-side: Experiment A vs B vs C
├── Trace: This run used dataset-v2.1 with LR=0.001
├── Confidence: Reproduction requires one click
└── Decision: Deploy model from run #247 (reproducible, traceable)
```

### 3.2 Internal Mechanisms and Architecture

#### Experiment Tracking System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Client Application                           │
│  (Training Script, Jupyter Notebook, ML Framework)                  │
└──────────────────┬─────────────────────────────────────────────────┘
                   │
                   │ mlflow.log_param, mlflow.log_metric, etc.
                   │
┌──────────────────▼─────────────────────────────────────────────────┐
│            Experiment Tracking Client Library                       │
│  (MLflow, W&B SDK, Neptune, etc.)                                  │
│  - Batches messages                                                 │
│  - Local buffering                                                  │
│  - Retry logic                                                      │
└──────────────────┬─────────────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
    [REST API]          [File System]
        │                     │
┌───────▼──────────┐   ┌──────▼─────────────┐
│ Tracking Server  │   │ Local Artifact     │
│ (Backend)        │   │ Store              │
└───────┬──────────┘   │ (Job output dir)   │
        │              └────────────────────┘
        │
  ┌─────▼──────────────────────┐
  │ Backend Database           │
  ├─────────────────────────────┤
  │ Experiments                │
  │ Runs (metadata + metrics)  │
  │ Artifacts (object refs)    │
  │ Parameters (hyperparams)   │
  └─────────────────────────────┘
```

**Data Model:**

```
Experiment (top-level container)
├── name: "fraud-detection"
├── created_at: 2025-01-15T10:00:00Z
└── runs: [Run1, Run2, Run3, ...]
    
    Run (single training execution)
    ├── run_id: "a1b2c3d4e5f6"
    ├── experiment_id: "exp-1"
    ├── start_time: 2025-01-15T10:05:00Z
    ├── end_time: 2025-01-15T12:15:00Z
    ├── status: "FINISHED"
    ├── params: {learning_rate: 0.001, batch_size: 32}
    ├── metrics: {
    │   accuracy: 0.925,
    │   loss: 0.182,
    │   f1_score: 0.918
    │ }
    ├── artifacts: {
    │   model: "runs/a1b2c3d4e5f6/artifacts/model.pkl",
    │   preprocessor: "runs/a1b2c3d4e5f6/artifacts/preprocessor.pkl",
    │   training_log: "runs/a1b2c3d4e5f6/artifacts/training.log"
    │ }
    ├── tags: {
    │   team: "fraud-detection",
    │   environment: "staging",
    │   model_type: "gradient_boosting"
    │ }
    └── metadata: {
        user: "data-scientist-1",
        git_commit: "abc123def456",
        dataset_version: "prod-2025-01-15"
      }
```

#### Artifact Storage Strategy

**Two-Tier Storage Model:**

```
Tier 1 - Metadata Store (PostgreSQL/MySQL):
├── Fast queries (< 100ms)
├── Indexed: experiment_id, run_id, metric_name, timestamp
├── Data: parameters, metrics, tags, run status
└── Size: Small (kilobytes per run)

Tier 2 - Artifact Store (S3/NFS/Blob Storage):
├── Bulk storage (terabytes)
├── Lazy loading (loaded only when needed)
├── Data: model weights, training logs, plots, data snapshots
├── Size: Large (gigabytes per run)
└── Expiration: Archive old runs after 90 days
```

**Access Pattern:**

```
Query: "Find best model from last week"
├── Step 1: Query metadata DB (fast)
│   SELECT run_id, metric_value WHERE experiment_id=X AND timestamp > now()-7d
│   Result: 10 runs (milliseconds)
│
├── Step 2: Fetch artifact paths from metadata
│   Result: S3 path for model weights
│
└── Step 3: Stream artifact on demand
    s3://artifacts/runs/a1b2c3d4e5f6/model.pkl
    Result: Model downloaded (seconds)
```

### 3.3 Production Usage Patterns

#### Pattern 1: Multi-Stage Experiment Workflow

```
Stage 1: Rapid Experimentation (Data Scientists)
├── Run: 20 experiments/day
├── Tracking: All hyperparams, metrics, code version
├── Duration: Minutes to hours
└── Storage: Local + central tracking

Stage 2: Validation (ML Engineers)
├── Run: Best 3-5 candidates
├── Tracking: Cross-validation scores, fairness metrics
├── Duration: Hours to days
└── Validation: Against holdout dataset

Stage 3: Pre-Production (ML Ops)
├── Run: Champion model
├── Tracking: Performance on production-like data
├── Duration: Days
└── Validation: Edge cases, adversarial examples

Stage 4: Production Monitoring (Operations)
├── Tracking: Real prediction metrics
├── Duration: Continuous
└── Metric: Compare production vs. offline metrics
```

**Experiment Tracking in Multi-Stage Workflow:**

```python
# Stage 1: Data Scientist Local Development
import mlflow

mlflow.set_experiment("fraud-detection-v2")

for lr in [0.001, 0.01, 0.1]:
    for batch_size in [16, 32, 64]:
        with mlflow.start_run(run_name=f"lr-{lr}_bs-{batch_size}"):
            model = train_model(
                learning_rate=lr,
                batch_size=batch_size,
                data_version="staging-latest"
            )
            
            mlflow.log_params({
                "learning_rate": lr,
                "batch_size": batch_size,
                "model_type": "xgboost",
                "data_version": "staging-latest"
            })
            
            accuracy = evaluate(model)
            mlflow.log_metric("accuracy", accuracy)
            mlflow.log_artifact(model, "model")
            
            # Add tag for filtering later
            mlflow.set_tag("stage", "rapid_experimentation")
            mlflow.set_tag("git_commit", get_git_commit())

# Stage 2: ML Engineer Registration (Manual Approval)
# Best run selected and registered to model registry

# Stage 3: ML Ops Deployment
# Retrieved from registry, tested, deployed to staging

# Stage 4: Operations Monitoring
# Predictions logged, compared to training metrics
```

#### Pattern 2: Automated Experiment Comparison

```
Use Case: Daily model retraining with automatic comparison
├── Day N: Train model on data-{N}
├── Metrics: {accuracy: 0.925, latency: 45ms}
├── Day N+1: Train model on data-{N+1}
├── Metrics: {accuracy: 0.921, latency: 47ms}
├── Decision: Accuracy dropped 0.4% (within tolerance)
│   → Deploy new model with monitoring
└── Day N+2: Production metrics degrade
    → Alert triggered, revert to Day N model
```

**Implementation:**

```python
import mlflow
from datetime import datetime, timedelta

def automated_daily_retraining():
    today = datetime.now().date()
    data_version = f"prod-{today}"
    
    # Fetch baseline (yesterday's production model)
    baseline_run = get_production_model_run()
    baseline_metrics = baseline_run.metrics
    
    # Train new model
    with mlflow.start_run(run_name=f"daily-retrain-{today}"):
        model = train_latest(data_version=data_version)
        metrics = evaluate(model)
        
        mlflow.log_metrics(metrics)
        mlflow.log_artifact(model.pkl, "model")
        
        # Compare to baseline
        accuracy_diff = metrics["accuracy"] - baseline_metrics["accuracy"]
        latency_diff = metrics["latency"] - baseline_metrics["latency"]
        
        mlflow.log_metric("accuracy_delta", accuracy_diff)
        mlflow.log_metric("latency_delta", latency_diff)
        
        # Decide: promote or hold
        if accuracy_diff > -0.02 and latency_diff < 50:  # Within tolerance
            mlflow.set_tag("promotion_candidate", "true")
            promote_to_staging(mlflow.active_run().info.run_id)
        else:
            mlflow.set_tag("promotion_candidate", "false")
            notify_team(f"New model doesn't meet criteria: accuracy_delta={accuracy_diff}")
```

### 3.4 DevOps Best Practices

#### Practice 1: Experiment Tracking Infrastructure as Code

```yaml
# experiment-tracking-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow-tracking-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mlflow-server
  template:
    metadata:
      labels:
        app: mlflow-server
    spec:
      containers:
      - name: mlflow
        image: mlflow:2.10.1
        ports:
        - containerPort: 5000
        env:
        - name: BACKEND_STORE_URI
          value: postgresql://mlflow-user:password@postgres-db:5432/mlflow
        - name: ARTIFACT_ROOT
          value: s3://ml-artifacts/experiments
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access_key
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret_key
        resources:
          requests:
            cpu: 2
            memory: 4Gi
          limits:
            cpu: 4
            memory: 8Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: mlflow-tracking-server
spec:
  selector:
    app: mlflow-server
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-artifacts-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Ti
```

#### Practice 2: Metadata Standardization

```python
# metadata_schema.py
from dataclasses import dataclass
from typing import Dict, List, Optional
from datetime import datetime

@dataclass
class ExperimentMetadata:
    """Standard experiment metadata schema for all runs"""
    
    # Required fields
    experiment_name: str
    team: str
    data_version: str
    model_type: str
    git_commit: str
    
    # Optional but recommended
    description: Optional[str] = None
    objective: Optional[str] = None  # "maximize", "minimize"
    
    # Governance
    approver: Optional[str] = None
    business_justification: Optional[str] = None
    
    # Change tracking
    changed_from_baseline: Optional[str] = None  # Previous run ID
    reason_for_experiment: Optional[str] = None
    
    def validate(self) -> bool:
        """Enforce metadata schema"""
        required = [
            self.experiment_name,
            self.team,
            self.data_version,
            self.model_type,
            self.git_commit
        ]
        return all(required)

# Enforce in training script
def train_with_tracking(metadata: ExperimentMetadata):
    assert metadata.validate(), "Metadata validation failed"
    
    with mlflow.start_run():
        # Log all metadata
        mlflow.set_tag("team", metadata.team)
        mlflow.set_tag("objective", metadata.objective)
        mlflow.log_param("data_version", metadata.data_version)
        mlflow.log_param("model_type", metadata.model_type)
        
        # Train model...
```

#### Practice 3: Retention and Cleanup Policy

```python
# cleanup_old_experiments.py
import mlflow
from datetime import datetime, timedelta

def cleanup_old_experiments(retention_days=90):
    """Archive experiments older than retention period"""
    
    client = mlflow.tracking.MlflowClient()
    experiments = client.search_experiments()
    
    cutoff_date = datetime.now() - timedelta(days=retention_days)
    
    for exp in experiments:
        # Get all runs in experiment
        runs = client.search_runs(
            experiment_ids=[exp.experiment_id],
            filter_string=f"created_time < {cutoff_date.timestamp() * 1000}"
        )
        
        for run in runs:
            # Archive artifacts to cold storage (Glacier)
            archive_to_glacier(run.info.artifact_uri)
            
            # Delete local cache (metadata kept in DB)
            cleanup_local_artifacts(run.info.run_id)
            
            # Add tag
            mlflow.set_tag(run.info.run_id, "archived", "true")

# Schedule as daily job
# 0 2 * * * python cleanup_old_experiments.py
```

### 3.5 Common Pitfalls

#### Pitfall 1: No Metadata Standardization

**Problem:**
```
Run 1: no tags, minimal logging
Run 2: tags but no description
Run 3: complete metadata
→ Analytics impossible: "Find fraud models from October"
```

**Solution:** Enforce schema via validation

#### Pitfall 2: Storing Large Datasets as Artifacts

**Problem:**
```
Experiment logs: Raw training data (2GB) as artifact
├── Bloats artifact store
├── Slows down experiment queries
└── Violates immutability principle
```

**Solution:** Log dataset version/hash, not the data itself

#### Pitfall 3: Experiment Tracking Without Cleanup

**Problem:**
```
Year 1: 1,000 experiments
Year 3: 36,500 experiments
├── Query performance: 500ms → 5 seconds
├── Storage: $1,000/month
└── Compliance: Can't delete old runs (audit trail)
```

**Solution:** Implement retention policy + archive strategy

---

## 4. Model Versioning & Registries

### 4.1 Model Registry Architecture

A **Model Registry** is a centralized repository for managing the complete ML model lifecycle: development, staging, production deployment, and rollback. It functions as the single source of truth for all production models.

**Model Registry vs. Container Registry:**

```
Container Registry:
├── Stores: Docker images (code + environment)
├── Versions: image:v1.0, image:v1.1
├── Status: available/deprecated
└── Deployment: Pull image, run container

Model Registry:
├── Stores: Model artifacts + metadata + lineage
├── Versions: model-v1.0.0, model-v1.0.1, model-v2.0.0
├── Status: development/staging/production/archived
├── Promotion: through workflow stages with approvals
└── Deployment: Retrieve model + config, serve with inference server
```

### 4.2 Model Lifecycle and Version States

```
┌─────────────────────────────────────────────────────────────┐
│ Model Lifecycle States                                      │
└─────────────────────────────────────────────────────────────┘

1. DEVELOPMENT
   ├── Created: Run successful training experiment
   ├── Status: Not ready for any environment
   ├── Usage: Data scientist validation only
   └── TTL: 7 days (auto-cleanup if not promoted)

2. STAGING
   ├── Promoted: By ML engineer after review
   ├── Status: Ready for pre-production testing
   ├── Usage: Shadow mode, A/B testing, load testing
   ├── Validation: Performance vs. production baseline
   └── Duration: 1-7 days typically

3. PRODUCTION
   ├── Promoted: By data science lead + approval gate
   ├── Status: Serving real traffic
   ├── Usage: Live predictions on user requests
   ├── Monitoring: Alert on performance degradation
   └── Retention: Kept for 1 year for audit

4. ARCHIVED
   ├── Status: Replaced or deprecated
   ├── Usage: Historical reference only
   ├── Retention: 7 years for compliance
   └── Storage: Cold storage (Glacier)

State Transitions:
DEVELOPMENT → (review) → REJECTED (discarded)
DEVELOPMENT → (review) → STAGING → (test) → REJECTED
STAGING → (test pass) → PRODUCTION
PRODUCTION ← (rollback) → (previous version)
PRODUCTION → (deprecated) → ARCHIVED
```

### 4.3 Promotion Workflows

#### Workflow: Manual Approval with Gates

```
Step 1: Model Candidate (Experiment → Registry)
├── Data Scientist: Runs experiment, achieves 0.925 accuracy
├── Action: Call register_model(run_id, name="fraud-detector")
├── Result: Model registered with status=development
└── Time: Immediate

Step 2: Staging Promotion (Development → Staging)
├── ML Engineer: Reviews model card, metrics, data version
├── Requirements: 
│   - Accuracy >= baseline (0.920)
│   - Latency test: < 100ms p99
│   - Data completeness: 99%+
│   - No deprecated features used
├── Action: Approve and promote to staging
├── Result: Model status=staging, promoted_at={timestamp}
└── Time: 1-24 hours

Step 3: Staging Validation (Shadow Deployment)
├── ML Ops: Deploy to staging environment
├── Parallel Run: New model + old model on same requests
├── Metrics Evaluated:
│   - Prediction drift: Compare outputs
│   - Latency: P50, P95, P99
│   - Memory usage: Compare to baseline
│   - Error rates: Handle edge cases
├── Duration: 7 days minimum
└── Result: Pass/Fail

Step 4: Production Promotion (Staging → Production)
├── Data Science Lead: Reviews staging metrics
├── Gate Requirements:
│   - Latency p99 <= baseline + 10%
│   - Error rate <= baseline
│   - No regression on key segments
├── Approval: Sign off with business justification
├── Action: Promote to production
├── Result: Model status=production, deployment_time={timestamp}
└── Time: Scheduled deployment window

Step 5: Production Rollout (Canary)
├── Day 1: 5% traffic to new model
│   - Monitor: Error rate, latency, prediction distribution
│   - Decision: Continue or rollback
├── Day 2: 25% traffic if Day 1 OK
├── Day 3: 100% traffic if Day 2 OK
└── Rollback: If any metric > threshold, revert to previous version

Step 6: Deprecation (Old Model Retirement)
├── Trigger: 30 days after new model at 100%
├── Action: Mark old model as deprecated
├── Result: No new deployments, archive after 1 year
```

**Implementation:**

```python
# model_registry.py
from enum import Enum
from datetime import datetime
from typing import Optional

class ModelStage(Enum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"
    ARCHIVED = "archived"

class ModelPromotion:
    def __init__(self, registry_client):
        self.client = registry_client
    
    def register_model(self, run_id: str, model_name: str):
        """Register model from experiment run"""
        model_version = self.client.create_model_version(
            name=model_name,
            source=f"runs:/{run_id}/model",
            run_id=run_id,
            tags={
                "stage": ModelStage.DEVELOPMENT.value,
                "registered_at": datetime.now().isoformat()
            }
        )
        return model_version
    
    def promote_to_staging(self, model_name: str, version: int, 
                          reviewer: str, notes: str = ""):
        """Promote model from development to staging"""
        # Validation gate
        metrics = self.client.get_latest_versions(model_name)[0].metrics
        assert metrics["accuracy"] >= 0.920, "Accuracy below baseline"
        
        # Promote
        self.client.update_model_version(
            name=model_name,
            version=version,
            stage=ModelStage.STAGING.value,
            tags={
                "promoted_to_staging_by": reviewer,
                "promotion_notes": notes,
                "promotion_timestamp": datetime.now().isoformat()
            },
            description=f"Promoted by {reviewer}: {notes}"
        )
        
        # Notify
        notify_team(f"Model {model_name}:{version} promoted to staging")
    
    def promote_to_production(self, model_name: str, version: int,
                             approver: str, business_justification: str):
        """Promote model to production with approval"""
        # Approval gate (requires 2 approvals in real system)
        approval = get_approval(
            model_name=model_name,
            version=version,
            required_approvers=["data_science_lead", "ml_ops_lead"]
        )
        assert approval.is_approved, "Approval required"
        
        # Promote
        self.client.update_model_version(
            name=model_name,
            version=version,
            stage=ModelStage.PRODUCTION.value,
            tags={
                "approved_by": approver,
                "business_justification": business_justification,
                "deployment_time": datetime.now().isoformat()
            }
        )
        
        # Trigger deployment
        trigger_canary_deployment(model_name, version)
```

### 4.4 Rollback and Governance

#### Rollback Scenarios

**Scenario 1: Immediate Rollback (Seconds)**
```
Time: T+10 minutes (5 minutes after 5% traffic)
Monitoring Alert: Error rate 15% (baseline 1%)
Action: 
  1. Automatic alarm: error_rate > 5x baseline
  2. Pre-approved: Revert to previous version
  3. Execution: Update serving config (30 seconds)
  4. Verification: Error rate drops to 1%
  5. Documentation: Incident logged with root cause
```

**Scenario 2: Gradual Rollback (Hours)**
```
Time: T+6 hours (Full rollout completed)
Monitoring Alert: Prediction distribution shifted on 20% of data
Accuracy: Declined 2% on one demographic segment
Action:
  1. Alert: Fairness metric below threshold
  2. Review: Data scientist investigates root cause
  3. Decision: Revert to previous version due to data drift
  4. Execution: Route traffic back to previous model (canary reverse)
  5. Action: Trigger retraining on fresh data
```

**Scenario 3: No Rollback (Monitoring)**
```
Time: T+48 hours
Monitoring Alert: Slight latency increase (45ms → 50ms)
Assessment: Within acceptable range (+5ms)
Decision: Continue monitoring, no rollback
Action: Document in metrics dashboard
```

**Governance Audit Trail:**

```
Model: fraud-detector v1.2.0
├── Created: 2025-01-15 10:30:00 UTC
│   ├── Experiment Run: a1b2c3d4e5f6
│   ├── Data Version: prod-2025-01-15
│   ├── Git Commit: abc123def456
│   ├── Created by: data-scientist-alice
│   └── Metrics: {accuracy: 0.925, latency: 42ms}
│
├── Promoted to Staging: 2025-01-15 14:00:00 UTC
│   ├── Reviewer: ml-engineer-bob
│   ├── Validation: Passed all checks
│   ├── Notes: "Ready for shadow deployment"
│   └── Approval Token: sig_12345
│
├── Deployed to Staging: 2025-01-15 15:00:00 UTC
│   ├── Deployed by: ml-ops-charlie
│   ├── Shadow Mode: Running alongside v1.1.9
│   ├── Duration: 7 days
│   └── Endpoint: https://staging-serve.internal/fraud-detector
│
├── Promoted to Production: 2025-01-22 09:00:00 UTC
│   ├── Approver: data-science-lead-diana
│   ├── Business Justification: "Reduces false positives by 10%"
│   ├── Approval Method: 2/2 required approvals obtained
│   └── Approval Token: sig_67890
│
├── Deployed to Production: 2025-01-22 10:00:00 UTC
│   ├── Deployment Strategy: Canary (5% → 25% → 100%)
│   ├── Day 1 Result: 5% traffic, metrics OK, proceed
│   ├── Day 2 Result: 25% traffic, metrics OK, proceed
│   ├── Day 3 Result: 100% traffic, metrics OK, complete
│   └── Endpoint: https://prod-serve.ml.company.com/fraud-detector
│
├── Monitoring: 2025-01-22 onwards
│   ├── Avg Latency: 42ms (baseline: 40ms) ✓
│   ├── Error Rate: 0.8% (baseline: 1%) ✓
│   ├── Accuracy: 92.1% (estimated from sample) ✓
│   └── Prediction Distribution: Stable ✓
│
└── Status: PRODUCTION (No rollback needed)
    └── Last Monitored: 2025-01-23 02:15:00 UTC
```

### 4.5 Model Registry Tools Comparison

#### MLflow Model Registry

```python
# MLflow example
import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Register model from experiment
model_version = client.create_model_version(
    name="fraud-detector",
    source="runs:/a1b2c3d4e5f6/model",
    run_id="a1b2c3d4e5f6",
    tags={"task": "classification"}
)

# Transition to production
client.update_model_version(
    name="fraud-detector",
    version=model_version.version,
    stage="Production"
)

# Get production model
prod_models = client.get_latest_versions("fraud-detector", stages=["Production"])
```

**Pros:**
- Integrated with experiment tracking
- Simple API, minimal setup
- Metadata tagging and searching

**Cons:**
- Limited approval workflows
- Basic governance features
- Scaling challenges at enterprise scale

#### DVC Model Registry

```bash
# DVC example: Version control for models + data

# Track model
dvc plots show metrics
dvc plots diff HEAD~1

# Create model version
git tag model-v1.2.0
dvc exp run  # Training with versioning

# Promote model
dvc push  # Store artifacts
git push  # Update repository
```

**Pros:**
- Git-native, familiar workflow
- Version control for both code and models
- Cost-effective (uses existing storage)

**Cons:**
- Limited UI/API
- Harder to query across repositories
- Manual workflow enforcement

#### SageMaker Model Registry (AWS)

```python
# SageMaker example
import boto3

sm = boto3.client("sagemaker")

# Register model
model_group = sm.create_model_package_group(
    ModelPackageGroupName="fraud-detector-group",
    ModelPackageGroupDescription="Production fraud detection models"
)

# Create model version
model_package = sm.create_model_package(
    ModelPackageGroupName="fraud-detector-group",
    PrimaryContainer={
        "Image": "123456789.dkr.ecr.us-east-1.amazonaws.com/fraud-detector:v1.2.0",
        "ModelDataUrl": "s3://model-artifacts/model.tar.gz"
    },
    ModelApprovalStatus="PendingManualApproval"
)
```

**Pros:**
- Enterprise-grade governance
- Integrated with SageMaker pipelines
- Approval workflows built-in
- Lineage tracking

**Cons:**
- AWS-specific
- Complex pricing model
- Overhead for small teams

### 4.6 Best Practices

#### Practice 1: Model Card Documentation

```markdown
<!-- model_card.md -->
# Model Card: Fraud Detection v1.2.0

## Model Details
- Model Type: XGBoost Classifier
- Owner: Fraud Detection Team
- Created: 2025-01-15
- Last Modified: 2025-01-22

## Intended Use
- Primary Use: Real-time fraud detection on payment transactions
- Users: Fintech customers, transaction processors
- Out-of-Scope: Historical analysis, forensic investigation

## Training Data
- Dataset: Q4 2024 transactions
- Volume: 50M transactions
- Classes: 0.5% fraud, 99.5% legitimate (imbalanced)
- Features: 47 variables (merchant data, temporal, behavioral)
- Data Quality: 99.8% complete, no duplicates detected

## Model Performance
- Accuracy: 92.1%
- Precision: 85.3% (fraud predictions that are correct)
- Recall: 78.2% (actual frauds detected)
- AUC-ROC: 0.94
- Latency: 42ms p99

## Bias and Fairness
- Demographic Parity: Yes (±2% across all groups)
- Analysis: Evaluated on gender, age, geography
- Known Limitations: May perform worse on new merchant categories

## Limitations
- Requires features updated within 24 hours
- Does not detect collusive fraud (multiple accounts)
- Performance degrades if data distribution changes >10%

## Recommendations
- Monitor prediction distribution daily
- Retrain on new data monthly
- Rollback if latency > 100ms or error rate > 5%
```

#### Practice 2: Version Numbering Scheme

```
Semantic Versioning for ML Models:

MAJOR.MINOR.PATCH-PRERELEASE

v1.2.0-rc1

Where:
├── MAJOR (v1): Architectural changes
│   └── Example: Change from XGBoost to neural network
├── MINOR (v1.2): Model improvements
│   └── Example: New features, better performance, improved fairness
├── PATCH (v1.2.0): Bug fixes, maintenance
│   └── Example: Fix preprocessing bug, dependency updates
└── PRERELEASE (-rc1): Development versions
    ├── -alpha: Early development
    ├── -beta: Ready for testing
    ├── -rc: Release candidate
    └── No suffix: Production release

Release Promotion:
v1.2.0-alpha → v1.2.0-beta → v1.2.0-rc1 → v1.2.0 (production)
```

---

## 5. Containerization for ML

### 5.1 Benefits of Containerization in ML

Container technology (Docker) is critical for ML because it solves reproducibility, scalability, and deployment challenges:

```
Challenge Without Containers:
├── "Works on my laptop" (different OS, libraries, Python version)
├── GPU drivers differ between machines
├── Model serving requires manual setup each time
├── Distributed training has configuration drift
└── Production deployment takes weeks

Solution With Containers:
├── Reproducible environment (identical across all machines)
├── GPU support standardized
├── Model serving: Single docker run command
├── Distributed training: Spawn identical containers
└── Production deployment: Push image, done in minutes
```

**Cost-Benefit Analysis:**

```
Setup Cost (One-time):
├── Write Dockerfile: 4-8 hours
├── Optimize layers: 2-4 hours
└── Test across environments: 2-4 hours
Total: ~12 hours (one-time investment)

Ongoing Savings:
├── Environment issues: 90% reduction
├── Deployment time: 80% reduction
├── Debugging: 70% reduction (reproducible anywhere)
├── Scaling: 60% easier (scale from 1 to 1000 containers)
└── ROI: Breaks even after 3rd deployment
```

### 5.2 Docker for ML Workflows

#### ML Training Container

```dockerfile
# Dockerfile.training
FROM python:3.10-slim

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy requirements first (cache layer optimization)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY data/ ./data/

# Environment variables for training
ENV PYTHONUNBUFFERED=1
ENV LOG_LEVEL=INFO
ENV ARTIFACT_STORE_PATH=/artifacts

# Volume for artifacts
VOLUME /artifacts

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
    CMD python -c "import mlflow; mlflow.tracking.MlflowClient().search_experiments(max_results=1)"

# Entrypoint
ENTRYPOINT ["python", "-u", "src/train.py"]

# Default training parameters (override with --env or -e flag)
CMD ["--config", "configs/default.yaml"]
```

**Usage:**

```bash
# Build image
docker build -f Dockerfile.training -t ml-trainer:v2.1.0 .

# Run training with GPU
docker run --gpus all \
  -v /data:/workspace/data:ro \
  -v /artifacts:/artifacts \
  -e MLFLOW_TRACKING_URI=http://tracking-server:5000 \
  -e DATA_VERSION=prod-2025-01-15 \
  ml-trainer:v2.1.0 \
  --config configs/production.yaml

# Output: Model saved to /artifacts/model-v1.2.0.pkl
```

#### Model Serving Container

```dockerfile
# Dockerfile.serving
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-serving.txt .
RUN pip install --no-cache-dir -r requirements-serving.txt

# Copy model serving code
COPY src/serving/ ./src/serving/
COPY models/ ./models/

# Health check (critical for production)
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000 8080

# Environment
ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/app/models/model.pkl
ENV PORT=8000

# Run serving application
CMD ["python", "-u", "src/serving/app.py", "--port", "8000"]
```

**Kubernetes Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fraud-detector-serving
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fraud-detector
  template:
    metadata:
      labels:
        app: fraud-detector
    spec:
      containers:
      - name: model-serving
        image: fraud-detector-serving:v1.2.0
        ports:
        - containerPort: 8000
          name: predictions
        env:
        - name: MODEL_VERSION
          value: "v1.2.0"
        - name: CACHE_SIZE_MB
          value: "2048"
        resources:
          requests:
            cpu: 2
            memory: 4Gi
          limits:
            cpu: 4
            memory: 6Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: fraud-detector-service
spec:
  selector:
    app: fraud-detector
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```

### 5.3 GPU Containers and CUDA

#### CUDA Runtime Basics

```dockerfile
# Dockerfile.gpu-training
# Use nvidia base image with CUDA pre-installed
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# Install Python 3.10
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python path
RUN ln -s /usr/bin/python3.10 /usr/bin/python

WORKDIR /workspace

# Deep learning frameworks with CUDA support
COPY requirements-gpu.txt .
RUN pip install --no-cache-dir -r requirements-gpu.txt

# Verify CUDA availability
RUN python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
RUN python -c "import tensorflow as tf; print(f'GPU devices: {len(tf.config.list_physical_devices(\"GPU\"))}')"

COPY src/ ./src/
COPY data/ ./data/

ENTRYPOINT ["python", "-u", "src/train.py"]
```

**requirements-gpu.txt:**

```
torch==2.1.0 --index-url https://download.pytorch.org/whl/cu121
tensorflow[and-cuda]==2.13.0
transformers==4.36.0
accelerate==0.25.0  # Distributed training
```

**Docker run with GPU:**

```bash
# List available GPUs
nvidia-smi

# Run with GPU access
docker run --gpus all \
  -v /data:/workspace/data:ro \
  -v /artifacts:/artifacts \
  ml-trainer-gpu:v2.1.0

# Run with specific GPUs
docker run --gpus '"device=0,1"' \
  ml-trainer-gpu:v2.1.0

# Run with GPU memory limit
docker run --gpus all \
  -e CUDA_VISIBLE_DEVICES=0,1 \
  -e TF_GPU_MEMORY_ALLOCATION=reserved \
  ml-trainer-gpu:v2.1.0
```

**Distributed GPU Training in Containers:**

```python
# src/train_distributed.py
import os
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel

def setup_distributed():
    """Initialize distributed training"""
    dist.init_process_group(backend="nccl")  # GPU-optimized backend
    rank = dist.get_rank()
    world_size = dist.get_world_size()
    gpu_id = rank % torch.cuda.device_count()
    torch.cuda.set_device(gpu_id)
    return rank, world_size

def train_distributed():
    rank, world_size = setup_distributed()
    
    # Load data (each process loads different shard)
    dataset = load_data(rank=rank, world_size=world_size)
    dataloader = DataLoader(dataset, batch_size=32, shuffle=True)
    
    # Create model on GPU
    model = MyModel().to(torch.cuda.current_device())
    
    # Wrap in DDP
    model = DistributedDataParallel(model)
    
    # Training loop
    for epoch in range(10):
        for batch in dataloader:
            output = model(batch)
            loss = criterion(output, labels)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
        
        if rank == 0:  # Only primary process logs
            print(f"Epoch {epoch}, Loss: {loss.item()}")

if __name__ == "__main__":
    train_distributed()
```

**Docker compose for multi-GPU training:**

```yaml
version: '3.8'
services:
  trainer:
    image: ml-trainer-gpu:v2.1.0
    runtime: nvidia
    shm_size: 16gb  # Shared memory for DataLoader
    ports:
      - "6006:6006"  # TensorBoard
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NCCL_DEBUG=ERROR
      - MASTER_ADDR=trainer
      - MASTER_PORT=29500
    volumes:
      - ./data:/data:ro
      - ./artifacts:/artifacts
      - ./logs:/logs
    command: python -u src/train_distributed.py
```

### 5.4 Build Optimization

**Dockerfile Layer Caching:**

```dockerfile
# BAD: Rebuilds everything on code change
FROM python:3.10-slim
COPY . /app  # All code, including requirements
RUN pip install -r requirements.txt
WORKDIR /app
CMD ["python", "train.py"]

# GOOD: Separates dependencies from code for caching
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .  # Layer 1: Dependencies (rarely changes)
RUN pip install -r requirements.txt
COPY src/ ./src/  # Layer 2: Source code (changes frequently)
COPY configs/ ./configs/
CMD ["python", "src/train.py"]

# Rebuild time:
# BAD: 5 minutes (full pip install)
# GOOD: 10 seconds (uses cache, only copies new files)
```

**Multi-Stage Builds:**

```dockerfile
# Stage 1: Builder (large, includes build tools)
FROM python:3.10 AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime (small, only runtime deps)
FROM python:3.10-slim
WORKDIR /app
# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
COPY src/ ./src/
CMD ["python", "src/train.py"]

# Image size:
# Single stage: 2.5 GB
# Multi-stage: 650 MB (74% reduction!)
```

**Build Commands:**

```bash
# Build with build cache
docker build -t ml-trainer:v2.1.0 .

# No cache (force rebuild)
docker build --no-cache -t ml-trainer:v2.1.0 .

# Build for specific platform (e.g., ARM64 for Apple Silicon)
docker build --platform linux/arm64 -t ml-trainer:v2.1.0 .

# Build and push to registry
docker build -t myregistry.azurecr.io/ml-trainer:v2.1.0 .
docker push myregistry.azurecr.io/ml-trainer:v2.1.0

# Inspect image layers
docker history ml-trainer:v2.1.0
```

### 5.5 Best Practices for Containerized ML

#### Practice 1: Immutable, Versioned Images

```bash
# Tag strategy
# Base tags: latest build
docker tag ml-trainer:v2.1.0 ml-trainer:latest

# Semantic versioning
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:v2.1.0
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:v2.1
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:v2
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:latest

# Timestamp tags (audit trail)
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:2025-01-22-14-30-00

# Git commit tags (reproducibility)
docker tag ml-trainer:v2.1.0 myregistry.azurecr.io/ml-trainer:abc123def456

# Don't push latest to production; always pin specific versions
```

#### Practice 2: Security Scanning

```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ml-trainer:v2.1.0

# Output example:
# Total: 42 vulnerabilities
# CRITICAL: 3 (action required)
# HIGH: 8
# MEDIUM: 15
# LOW: 16

# Fix issues
# 1. Update base image to latest patch
# 2. Update vulnerable dependencies
# 3. Remove unnecessary packages
# 4. Run as non-root user
```

#### Practice 3: Monitoring Container Resources

```yaml
# docker-compose with monitoring
version: '3.8'
services:
  trainer:
    image: ml-trainer:v2.1.0
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    deploy:
      resources:
        limits:
          cpus: '8'
          memory: 16G
        reservations:
          cpus: '4'
          memory: 8G
          devices:
            - driver: nvidia
              count: 4
              capabilities: [gpu]

  # Monitor container stats
  stats:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
```

**Monitor during training:**

```bash
# Real-time stats
docker stats ml-trainer --no-stream

# Output:
# CONTAINER     CPU %    MEM USAGE / LIMIT     NET I/O
# trainer       250%     14.2G / 16G           1.2MB / 2.1MB
```

---

## 6. CI/CD for ML

### 6.1 Challenges Unique to ML CI/CD

Traditional CI/CD is optimized for code changes. ML CI/CD must handle:

```
Challenge 1: Non-Deterministic Training
├── Same code often produces different results
├── Traditional testing: assert output == expected_output
├── ML testing: assert 0.920 <= output <= 0.930 (range-based)

Challenge 2: Long-Running Training Jobs
├── Traditional CI: <5 minutes per pipeline
├── ML training: 4-24 hours
├── Solution: Async job submission, long-lived runners

Challenge 3: Resource Constraints
├── Traditional CI: Lightweight (CPU-only)
├── ML training: GPU-intensive
├── Solution: Dedicated GPU runners, resource quotas

Challenge 4: Data Dependencies
├── Code changes don't guarantee model improvement
├── Data changes can cause degradation
├── Solution: Data versioning, validation gates

Challenge 5: Model Testing Complexity
├── Unit tests: Code logic validation
├── ML tests: Accuracy, fairness, robustness validation
├── Solution: Multi-stage testing pipeline
```

### 6.2 ML CI/CD Pipeline Stages

#### Stage 1: Data Validation (Fast, <5 min)

```python
# data_validation.py
import pandas as pd
from datetime import datetime
import jsonschema

def validate_data(data_path: str, schema_path: str) -> bool:
    """Validate training data before using"""
    
    df = pd.read_parquet(data_path)
    
    # Load schema
    with open(schema_path) as f:
        schema = json.load(f)
    
    # Schema validation
    for col in schema["required_columns"]:
        assert col in df.columns, f"Missing column: {col}"
    
    # Type validation
    for col, dtype in schema["column_types"].items():
        assert df[col].dtype == dtype, f"Wrong type for {col}"
    
    # Value validation
    for col, rules in schema["value_rules"].items():
        if "null_threshold" in rules:
            null_pct = df[col].isna().sum() / len(df)
            assert null_pct < rules["null_threshold"], \
                f"Too many nulls in {col}: {null_pct:.1%}"
        
        if "value_range" in rules:
            min_val, max_val = rules["value_range"]
            assert df[col].min() >= min_val and df[col].max() <= max_val, \
                f"{col} values out of range"
    
    # Distribution validation
    for col, distribution in schema.get("expected_distribution", {}).items():
        # Check that distribution hasn't shifted > 10%
        hist, _ = np.histogram(df[col], bins=10)
        chi2 = np.sum((hist - distribution) ** 2 / distribution)
        assert chi2 < 5.0, f"Data distribution shifted in {col}"
    
    print(f"✓ Data validation passed: {len(df)} rows")
    return True

if __name__ == "__main__":
    validate_data(
        "data/training/prod-2025-01-15.parquet",
        "schemas/training_data_schema.json"
    )
```

#### Stage 2: Unit Tests (Fast, <10 min)

```python
# test_feature_engineering.py
import unittest
import numpy as np
from src.features import compute_features, detect_outliers

class TestFeatures(unittest.TestCase):
    def setUp(self):
        self.raw_data = {
            "transaction_amount": [100, 200, 30000],  # Last is outlier
            "timestamp": ["2025-01-15T10:00:00", "2025-01-15T10:15:00", "2025-01-15T10:30:00"],
            "merchant_id": ["M1", "M2", "M1"]
        }
    
    def test_feature_no_nulls(self):
        """Features should never have null values"""
        features = compute_features(self.raw_data)
        assert not features.isna().any().any()
    
    def test_feature_ranges(self):
        """Features should be in expected ranges"""
        features = compute_features(self.raw_data)
        assert (features >= -5).all().all()  # Standardized features
        assert (features <= 5).all().all()
    
    def test_no_data_leakage(self):
        """Target leakage should be detected"""
        # Create data with obvious leakage
        leaky_data = {
            "transaction_amount": [100, 200, 300],
            "fraud_label": [0, 1, 0],  # Target variable
            "is_fraud_indicator": [0, 1, 0]  # Leaked target
        }
        features = compute_features(leaky_data)
        correlation = np.corrcoef(
            features["is_fraud_indicator"],
            leaky_data["fraud_label"]
        )[0, 1]
        assert abs(correlation) < 0.95, "Possible target leakage detected"
    
    def test_outlier_detection(self):
        """Outliers should be properly flagged"""
        outliers = detect_outliers(self.raw_data["transaction_amount"])
        assert outliers[2] == True  # 30000 is outlier
        assert outliers[0] == False  # 100 is not
        assert outliers[1] == False  # 200 is not

if __name__ == "__main__":
    unittest.main()
```

#### Stage 3: Model Training (Medium, 2-24 hours)

```yaml
# .gitlab-ci.yml - Example ML CI/CD pipeline
stages:
  - validate
  - test
  - train
  - evaluate
  - promote
  - deploy

# Stage 1: Data Validation
data_validation:
  stage: validate
  tags:
    - docker
    - cpu
  script:
    - python data_validation.py --config configs/prod.yaml
  artifacts:
    reports:
      - data_validation_report.json
  only:
    - branches

# Stage 2: Unit Tests
unit_tests:
  stage: test
  tags:
    - docker
    - cpu
  script:
    - pip install pytest pytest-cov
    - pytest tests/ --cov src --cov-report=xml
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_report_path: coverage.xml
  only:
    - branches

# Stage 3: Model Training (On GPU runner)
train_model:
  stage: train
  tags:
    - docker
    - gpu  # Dedicated GPU runner
  image: myregistry.azurecr.io/ml-trainer:latest
  timeout: 24h
  script:
    - echo "Training model on $CI_COMMIT_SHA..."
    - export EXPERIMENT_ID="${CI_PROJECT_NAME}-${CI_PIPELINE_ID}"
    - export DATA_VERSION="prod-$(date +%Y-%m-%d)"
    - python src/train.py
        --experiment-id $EXPERIMENT_ID
        --data-version $DATA_VERSION
        --git-commit $CI_COMMIT_SHA
        --mlflow-uri http://mlflow-server:5000
    - |
      BEST_RUN=$(python -c "import mlflow; \
        run = mlflow.search_runs()[0]; \
        print(run.info.run_id)")
    - echo $BEST_RUN > best_run_id.txt
  artifacts:
    paths:
      - best_run_id.txt
      - mlruns/
  cache:
    paths:
      - data/cached/
  only:
    - branches

# Stage 4: Model Evaluation (on CPU)
evaluate_model:
  stage: evaluate
  tags:
    - docker
    - cpu
  dependencies:
    - train_model
  script:
    - export BEST_RUN=$(cat best_run_id.txt)
    - python src/evaluate.py --run-id $BEST_RUN
    - |
      METRICS=$(python -c "import json; \
        with open('metrics.json') as f: \
        print(json.load(f))")
    - echo "Model Metrics:" && echo $METRICS
  artifacts:
    paths:
      - metrics.json
      - evaluation_report.html
    reports:
      dotenv: metrics.env

# Stage 5: Register Model (on CPU)
register_model:
  stage: promote
  tags:
    - docker
    - cpu
  script:
    - export BEST_RUN=$(cat best_run_id.txt)
    - python src/register_model.py
        --run-id $BEST_RUN
        --model-name fraud-detector
        --stage staging
  only:
    - main

# Stage 6: Deploy to Staging (on CPU)
deploy_staging:
  stage: deploy
  tags:
    - shell
  script:
    - export MODEL_VERSION=$(cat model_version.txt)
    - kubectl set image deployment/fraud-detector-staging
        model-serving=myregistry.azurecr.io/fraud-detector-serving:$MODEL_VERSION
    - kubectl rollout status deployment/fraud-detector-staging
  environment:
    name: staging
    kubernetes:
      namespace: ml-staging
  only:
    - main

# Manual Production Deployment (with approval)
deploy_production:
  stage: deploy
  tags:
    - shell
  script:
    - export MODEL_VERSION=$(cat model_version.txt)
    - kubectl set image deployment/fraud-detector-prod
        model-serving=myregistry.azurecr.io/fraud-detector-serving:$MODEL_VERSION
    - kubectl rollout status deployment/fraud-detector-prod
    - python src/start_canary.py --version $MODEL_VERSION --percentage 5
  environment:
    name: production
    kubernetes:
      namespace: ml-prod
  when: manual  # Requires manual approval
  only:
    - main
```

#### Stage 4: Model Testing Gates

```python
# model_tests.py
"""Comprehensive model validation gates"""

import numpy as np
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score
from sklearn.preprocessing import StandardScaler

def test_baseline_performance(model, X_test, y_test, baseline_accuracy=0.920):
    """Model must meet baseline performance"""
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    assert accuracy >= baseline_accuracy, \
        f"Accuracy {accuracy:.3f} below baseline {baseline_accuracy:.3f}"
    print(f"✓ Baseline performance: {accuracy:.3f}")

def test_latency(model, X_test, max_latency_ms=50):
    """Model must meet latency SLA"""
    import time
    times = []
    for _ in range(100):
        start = time.time()
        model.predict(X_test[:100])  # Batch prediction
        times.append((time.time() - start) / 100 * 1000)  # ms per sample
    
    p99_latency = np.percentile(times, 99)
    assert p99_latency <= max_latency_ms, \
        f"P99 latency {p99_latency:.1f}ms exceeds SLA {max_latency_ms}ms"
    print(f"✓ Latency P99: {p99_latency:.1f}ms")

def test_fairness_demographic_parity(model, X_test, y_test, group_col, threshold=0.02):
    """Check for fairness across demographic groups"""
    groups = X_test[group_col].unique()
    accuracies = {}
    
    for group in groups:
        mask = X_test[group_col] == group
        group_accuracy = accuracy_score(
            y_test[mask],
            model.predict(X_test.loc[mask])
        )
        accuracies[group] = group_accuracy
    
    max_accuracy = max(accuracies.values())
    min_accuracy = min(accuracies.values())
    disparity = max_accuracy - min_accuracy
    
    assert disparity <= threshold, \
        f"Fairness disparity {disparity:.3f} exceeds threshold {threshold:.3f}"
    print(f"✓ Fairness check passed: disparity {disparity:.3f}")
    for group, acc in accuracies.items():
        print(f"  {group}: {acc:.3f}")

def test_robustness_adversarial(model, X_test, y_test):
    """Model should handle slightly adversarial inputs"""
    # Add small perturbations
    epsilon = 0.1
    X_perturbed = X_test + np.random.normal(0, epsilon, X_test.shape)
    X_perturbed = np.clip(X_perturbed, -5, 5)  # Keep in valid range
    
    predictions_original = model.predict(X_test)
    predictions_perturbed = model.predict(X_perturbed)
    
    # Most predictions should remain stable
    stability = (predictions_original == predictions_perturbed).sum() / len(y_test)
    assert stability > 0.95, \
        f"Only {stability:.1%} predictions stable under perturbation"
    print(f"✓ Robustness check passed: {stability:.1%} stability")

def test_no_obvious_bugs(model):
    """Sanity checks for obvious bugs"""
    X_dummy = np.ones((10, 10))
    predictions = model.predict(X_dummy)
    
    # Should produce valid probabilities
    assert np.all(predictions >= 0) and np.all(predictions <= 1), \
        "Predictions not in [0, 1] range"
    
    # Should not predict same class for all samples
    unique_predictions = set(predictions)
    assert len(unique_predictions) > 1, \
        "Model predicts same class for all samples (obviously broken)"
    
    print(f"✓ Basic sanity checks passed")

# Run all tests
if __name__ == "__main__":
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.datasets import make_classification
    
    # Create dummy model and data
    X, y = make_classification(n_samples=1000, n_features=20)
    model = RandomForestClassifier().fit(X[:800], y[:800])
    X_test, y_test = X[800:], y[800:]
    
    # Run tests
    test_baseline_performance(model, X_test, y_test)
    test_latency(model, X_test)
    test_no_obvious_bugs(model)
    print("All tests passed!")
```

### 6.3 Real-World CI/CD Example: Complete Pipeline

```yaml
# GitLab CI Pipeline: End-to-End ML CI/CD
image: python:3.10

stages:
  - validate
  - train
  - evaluate
  - register
  - deploy

variables:
  DATA_VERSION: "prod-$(date +%Y-%m-%d)"
  MLFLOW_SERVER: "http://mlflow.internal:5000"
  MODEL_NAME: "fraud-detector"
  DOCKER_REGISTRY: "myregistry.azurecr.io"

# Stage 1: Quick Validation
.validate:
  stage: validate
  script:
    - pip install -r requirements-dev.txt
    - python data_validation.py
    - pytest tests/ -v

validate_data:
  extends: .validate
  tags:
    - shared

# Stage 2: Training on GPU
.train:
  stage: train
  tags:
    - gpu
    - docker
  timeout: 24h
  image: ${DOCKER_REGISTRY}/ml-trainer:latest
  artifacts:
    paths:
      - runs/
    expire_in: 30 days

train_model:
  extends: .train
  script:
    - |
      python src/train.py \
        --experiment-name ${MODEL_NAME}-${CI_PIPELINE_ID} \
        --data-version ${DATA_VERSION} \
        --mlflow-uri ${MLFLOW_SERVER} \
        --git-commit ${CI_COMMIT_SHA} \
        --output models/
    - export BEST_RUN=$(python -c "import mlflow; print(sorted(mlflow.search_runs(), key=lambda x: x.data.metrics.get('accuracy', 0), reverse=True)[0].info.run_id)")
    - echo $BEST_RUN > best_run.txt

# Stage 3: Model Evaluation
evaluate_model:
  stage: evaluate
  dependencies:
    - train_model
  tags:
    - shared
  script:
    - pip install -r requirements-dev.txt
    - export BEST_RUN=$(cat best_run.txt)
    - |
      python src/evaluate.py \
        --run-id ${BEST_RUN} \
        --test-data data/test/prod-latest.parquet \
        --output evaluation_report.html
    - |
      python -c "
      import json
      import mlflow
      run = mlflow.tracking.MlflowClient().get_run('${BEST_RUN}')
      metrics = run.data.metrics
      print(f'Accuracy: {metrics[\"accuracy\"]:.3f}')
      print(f'AUC: {metrics[\"auc\"]:.3f}')
      " | tee metrics.txt

# Stage 4: Model Registration
register_model:
  stage: register
  dependencies:
    - evaluate_model
  tags:
    - shared
  script:
    - pip install mlflow
    - export BEST_RUN=$(cat best_run.txt)
    - |
      python -c "
      import mlflow
      client = mlflow.tracking.MlflowClient()
      model_version = client.create_model_version(
          name='${MODEL_NAME}',
          source=f'runs:/{$BEST_RUN}/model',
          run_id='${BEST_RUN}'
      )
      print(f'Registered model version {model_version.version}')
      with open('model_version.txt', 'w') as f:
          f.write(str(model_version.version))
      "
  artifacts:
    paths:
      - model_version.txt

# Stage 5: Build & Push Container
build_image:
  stage: register
  tags:
    - docker
  dependencies:
    - evaluate_model
  image: docker:latest
  services:
    - docker:dind
  script:
    - export MODEL_VERSION=$(cat model_version.txt)
    - |
      docker build \
        --build-arg MODEL_VERSION=${MODEL_VERSION} \
        -t ${DOCKER_REGISTRY}/fraud-detector-serving:v${MODEL_VERSION} \
        -f Dockerfile.serving .
    - docker push ${DOCKER_REGISTRY}/fraud-detector-serving:v${MODEL_VERSION}

# Stage 6: Deploy to Staging
deploy_staging:
  stage: deploy
  tags:
    - k8s
  script:
    - export MODEL_VERSION=$(cat model_version.txt)
    - kubectl set image deployment/fraud-detector-staging
        model-serving=${DOCKER_REGISTRY}/fraud-detector-serving:v${MODEL_VERSION}
        -n ml-staging
    - kubectl rollout status deployment/fraud-detector-staging -n ml-staging
  environment:
    name: staging
    deployment_tier: staging
  only:
    - main
  when: on_success

# Stage 7: Manual Production Deployment
deploy_production:
  stage: deploy
  tags:
    - k8s
  script:
    - export MODEL_VERSION=$(cat model_version.txt)
    # Start canary with 5% traffic
    - kubectl set image deployment/fraud-detector-prod
        model-serving=${DOCKER_REGISTRY}/fraud-detector-serving:v${MODEL_VERSION}
        -n ml-prod
    - python src/init_canary.py --model-version v${MODEL_VERSION} --traffic-percent 5
    - echo "Canary deployment initiated: 5% traffic"
  environment:
    name: production
    deployment_tier: production
  when: manual
  only:
    - main

# Cleanup: Archive old runs
cleanup:
  stage: .post
  tags:
    - shared
  script:
    - pip install mlflow
    - python src/cleanup_old_runs.py --retention-days 90
  when: always
```

### 6.4 Best Practices for ML CI/CD

#### Practice 1: Reproducible Build Pipelines

```bash
# Use pinned dependencies for reproducibility
# requirements.txt (WRONG - allows variations)
scikit-learn
pandas
numpy

# requirements.txt (CORRECT - pinned versions)
scikit-learn==1.3.2
pandas==2.1.3
numpy==1.24.3
mlflow==2.10.1
torch==2.1.0
```

#### Practice 2: Dataset Validation Gates

```python
# dataset_validation_gate.py
"""Prevent training with bad data"""

def check_data_quality(data_path: str) -> bool:
    df = pd.read_parquet(data_path)
    
    checks = {
        "Row count": len(df) > 1000,  # At least 1000 rows
        "Features present": len(df.columns) >= 20,
        "Class balance": (df['target'].value_counts().min() / len(df)) > 0.05,
        "No null values": df.isna().sum().sum() == 0,
        "Numeric range ok": (df.select_dtypes('number') >= -1000).all().all(),
        "Target present": 'target' in df.columns,
    }
    
    print("Data Quality Checks:")
    for check_name, result in checks.items():
        status = "✓" if result else "✗"
        print(f"  {status} {check_name}")
    
    return all(checks.values())

if __name__ == "__main__":
    import sys
    data_path = sys.argv[1]
    if not check_data_quality(data_path):
        print("Data validation failed!")
        sys.exit(1)
```

#### Practice 3: Conditional Promotion

```python
#conditional_promotion.py
"""Only promote model if it meets criteria"""

def should_promote_to_production(run_id: str) -> bool:
    """Decide whether to promote model"""
    
    client = mlflow.tracking.MlflowClient()
    run = client.get_run(run_id)
    metrics = run.data.metrics
    
    # Baseline metrics
    baseline = {
        "accuracy": 0.920,
        "latency_ms": 50,
        "auc": 0.94,
    }
    
    # Check criteria
    criteria = {
        "Accuracy >= baseline": metrics.get("accuracy", 0) >= baseline["accuracy"],
        "Latency <= baseline": metrics.get("latency_ms", 999) <= baseline["latency_ms"],
        "AUC >= baseline": metrics.get("auc", 0) >= baseline["auc"],
        "No fairness issues": metrics.get("fairness_disparity", 1.0) < 0.05,
    }
    
    print("Promotion Criteria:")
    for criterion, passed in criteria.items():
        status = "✓" if passed else "✗"
        print(f"  {status} {criterion}")
    
    return all(criteria.values())

if __name__ == "__main__":
    if should_promote_to_production(sys.argv[1]):
        print("\n✓ Model approved for production promotion")
        sys.exit(0)
    else:
        print("\n✗ Model does not meet promotion criteria")
        sys.exit(1)
```

---

## 7. Hands-on Scenarios

### 7.1 Scenario 1: Setting Up MLOps Infrastructure for a Distributed ML Team

**Problem Statement:**
A fintech company has 15 data scientists, some in US, some in EU. They currently have:
- Models stored locally on laptops
- No experiment tracking (metrics in CSV files)
- Manual ad-hoc deployments to production
- Multiple versions of the same model running in different regions
- Compliance violations due to inability to audit model changes

**Architecture Context:**
```
Current State (Chaos):
├── Data Scientist 1: model_v1.pkl on Ubuntu laptop
├── Data Scientist 2: model_v1.pkl on MacBook (different result!)
├── Data Scientist 3: model_v2.pkl (claimed improvement, not verified)
├── Production: Running unknown model version
└── Governance: "Which model is actually deployed?"

Desired State (Controlled):
├── Centralized Experiment Tracking (MLflow on Kubernetes)
├── Model Registry (Single source of truth)
├── Container Registry (Versioned images)
├── CI/CD Pipeline (Automated testing, promotion)
└── Production Serving (Reproducible, auditable)
```

**Step-by-Step Implementation:**

**Phase 1: Experiment Tracking Infrastructure (Week 1)**

```yaml
# 1. Deploy MLflow on Kubernetes
apiVersion: v1
kind: Namespace
metadata:
  name: mlops

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow-server
  namespace: mlops
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mlflow
  template:
    metadata:
      labels:
        app: mlflow
    spec:
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
                  - mlflow
              topologyKey: kubernetes.io/hostname
      containers:
      - name: mlflow
        image: mlflow:2.10.1
        ports:
        - containerPort: 5000
        env:
        - name: BACKEND_STORE_URI
          value: postgresql://mlflow:$(PG_PASSWORD)@postgres-db.mlops:5432/mlflow
        - name: ARTIFACT_ROOT
          value: s3://ml-artifacts/experiments
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: access_key
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: secret_key
        resources:
          requests:
            cpu: 2
            memory: 4Gi
          limits:
            cpu: 4
            memory: 8Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: mlflow-server
  namespace: mlops
spec:
  selector:
    app: mlflow
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-artifacts
  namespace: mlops
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: premium-ssd
  resources:
    requests:
      storage: 5Ti
```

**Troubleshooting:**
```bash
# Issue: MLflow server not starting
kubectl logs -n mlops deployment/mlflow-server

# Issue: PostgreSQL connection refused
kubectl exec -it svc/mlflow-server -n mlops -- \
  psql postgresql://mlflow@postgres-db/mlflow

# Solution: Ensure PostgreSQL is running
kubectl get pods -n mlops | grep postgres

# Configure data scientists' environment
export MLFLOW_TRACKING_URI=http://mlflow-server.mlops:5000
pip install mlflow
mlflow experiments list
```

**Phase 2: Training Script Integration (Week 1-2)**

```python
# src/train_tracked.py - Data scientist example
import mlflow
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score

def train_with_tracking():
    # Initialize MLflow
    mlflow.set_tracking_uri("http://mlflow-server.mlops:5000")
    mlflow.set_experiment("fraud-detection-v2")
    
    # Load data
    df = pd.read_parquet("s3://training-data/prod-2025-01-15.parquet")
    X_train, X_test, y_train, y_test = train_test_split(
        df.drop("fraud", axis=1), df["fraud"], test_size=0.2, random_state=42
    )
    
    with mlflow.start_run(run_name="rf-baseline"):
        # Log parameters
        params = {
            "n_estimators": 100,
            "max_depth": 20,
            "min_samples_split": 5,
            "random_state": 42,
            "data_version": "prod-2025-01-15",
            "git_commit": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
        }
        mlflow.log_params(params)
        
        # Train model
        model = RandomForestClassifier(**{k: v for k, v in params.items() 
                                         if k not in ["data_version", "git_commit"]})
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        metrics = {
            "accuracy": accuracy_score(y_test, y_pred),
            "f1": f1_score(y_test, y_pred),
            "auc": roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
        }
        mlflow.log_metrics(metrics)
        
        # Log artifacts
        mlflow.sklearn.log_model(model, "model")
        mlflow.log_artifact("schemas/training_schema.json")
        
        print(f"✓ Experiment tracked: {mlflow.active_run().info.run_id}")

if __name__ == "__main__":
    train_with_tracking()
```

**Phase 3: Model Registry Setup (Week 2)**

```python
# Configure model registry to use same PostgreSQL
# Models stored as artifacts in S3, metadata in PostgreSQL

# Script: register_best_model.py
import mlflow
from mlflow.tracking import MlflowClient

def register_best_model():
    client = MlflowClient("http://mlflow-server.mlops:5000")
    
    # Find best run from last week
    runs = client.search_runs(
        experiment_ids=["1"],
        filter_string="metrics.accuracy > 0.92 AND created_time > now()-7d"
    )
    
    best_run = max(runs, key=lambda x: x.data.metrics["accuracy"])
    
    # Register to model registry
    model_version = client.create_model_version(
        name="fraud-detector",
        source=f"runs:/{best_run.info.run_id}/model",
        run_id=best_run.info.run_id,
        tags={
            "team": "fraud-detection",
            "registered_by": "automation",
            "accuracy": str(best_run.data.metrics["accuracy"])
        }
    )
    
    print(f"✓ Registered model version {model_version.version}")
```

**Phase 4: CI/CD Integration (Week 3-4)**

GitLab CI configuration that triggers on data changes or code commits:

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - train
  - evaluate
  - register
  - deploy

variables:
  MLFLOW_TRACKING_URI: "http://mlflow-server.mlops:5000"
  MODEL_NAME: "fraud-detector"

validate_data:
  stage: validate
  script:
    - python data_validation.py --data-path s3://training-data/latest.parquet

train_model:
  stage: train
  tags:
    - gpu
    - docker
  timeout: 24h
  script:
    - python src/train_tracked.py
    - echo $(python -c "import mlflow; print(mlflow.search_runs()[0].info.run_id)") > run_id.txt
  artifacts:
    paths:
      - run_id.txt

register_model:
  stage: register
  dependencies:
    - train_model
  script:
    - export RUN_ID=$(cat run_id.txt)
    - python register_best_model.py --run-id $RUN_ID

deploy_staging:
  stage: deploy
  script:
    - kubectl set image deployment/fraud-detector-staging ml-model=fraud-detector:latest -n ml-staging
    - kubectl rollout status deployment/fraud-detector-staging -n ml-staging
```

**Best Practices Applied:**

✓ **Centralized tracking prevents "works on my laptop" issues**
✓ **Experiment metadata enables reproducibility and debugging**
✓ **Audit trail satisfies compliance requirements**
✓ **Automation reduces manual errors in production**
✓ **Regional separation maintains data residency**

**Outcome:**
- All experiments tracked automatically
- Compliance: Full audit trail of who trained what model when
- Data scientists can share results and compare experiments
- Production models are traceable to specific experiments

---

### 7.2 Scenario 2: Debugging Model Performance Degradation in Production

**Problem Statement:**
Production fraud detection model's accuracy drops from 92.5% to 87.1% overnight. Alerts fire at 2 AM. On-call engineer has 15 minutes to diagnose.

**Root Cause Analysis Framework:**

```
Decision Tree:
├── Is it a code issue?
│   └── Deploy previous model version immediately (rollback)
├── Is it a data distribution shift?
│   └── Trigger retraining with latest data
└── Is it operational (infrastructure)?
    └── Check containerization, resource limits, latency
```

**Troubleshooting Steps:**

**Step 1: Determine Current vs. Baseline (2 minutes)**
```bash
# Check which model is deployed
kubectl get deployment fraud-detector-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: registry.azurecr.io/fraud-detector:v1.2.0

# Check deployed model version from registry
curl -s http://mlflow-server/api/2.0/model-registry/model-versions/search \
  -H "Content-Type: application/json" \
  -d '{"name": "fraud-detector", "filter": "stage=\"Production\""}' | jq '.model_versions[0].version'
# Output: version=15, created_at=2025-01-22T10:00:00Z

# Get baseline metrics from model registry
curl -s http://mlflow-server/api/2.0/model-registry/model-versions \
  -H "Content-Type: application/json" | jq '.model_versions[0].tags'
# Output: {"baseline_accuracy": "0.925", "baseline_latency": "42ms"}
```

**Step 2: Check Production Data Quality (3 minutes)**
```python
# Check if input data distribution changed
import pandas as pd
import numpy as np

# Get today's data
today_data = pd.read_parquet("s3://production-data/2025-01-23.parquet")

# Get baseline data (from model training)
baseline_data = pd.read_parquet("s3://training-data/prod-2025-01-15.parquet")

# Check distribution shift
for col in baseline_data.columns:
    baseline_dist = baseline_data[col].describe()
    today_dist = today_data[col].describe()
    
    # Check for significant shift
    if abs(baseline_dist['mean'] - today_dist['mean']) > 2 * baseline_dist['std']:
        print(f"⚠ Significant shift in {col}")
        print(f"  Baseline mean: {baseline_dist['mean']:.2f}")
        print(f"  Today mean: {today_dist['mean']:.2f}")
```

**Step 3: Quick Rollback (1 minute)**
```bash
# If diagnosis unclear, rollback to previous version immediately
# Previous production model: v1.1.9 (from 48 hours ago)

kubectl set image deployment/fraud-detector-prod \
  model-serving=registry.azurecr.io/fraud-detector:v1.1.9 \
  -n ml-prod --record

# Monitor
kubectl rollout status deployment/fraud-detector-prod -n ml-prod

# Verify
kubectl get pods -n ml-prod -l app=fraud-detector -o wide
```

**Step 4: Root Cause Investigation (Post-incident)**

```python
# Compare model v1.2.0 vs v1.1.9 performance by data segment

import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Get both models
v120 = client.get_model_version("fraud-detector", version="15")  # v1.2.0
v119 = client.get_model_version("fraud-detector", version="14")  # v1.1.9

# Load test data from specific date range
test_data_prod = pd.read_parquet("s3://production-data/2025-01-23.parquet")
test_data_baseline = pd.read_parquet("s3://training-data/prod-2025-01-15.parquet")

# Load model artifacts
model_v120 = mlflow.sklearn.load_model(f"models:/fraud-detector/15")
model_v119 = mlflow.sklearn.load_model(f"models:/fraud-detector/14")

# Compare predictions on production data
pred_v120 = model_v120.predict(test_data_prod.drop("fraud", axis=1))
pred_v119 = model_v119.predict(test_data_prod.drop("fraud", axis=1))

# Segment analysis: Where does v1.2.0 fail most?
from sklearn.metrics import accuracy_score

segments = {
    "high_value": test_data_prod["amount"] > 10000,
    "evening": test_data_prod["hour"] > 18,
    "new_merchant": test_data_prod["merchant_age_days"] < 30,
    "geo_shift": test_data_prod["country"] not in test_data_baseline["country"].unique()
}

print("Performance Comparison by Segment:")
print(f"{'Segment':<20} {'v1.2.0':<10} {'v1.1.9':<10} {'Degradation':<12}")
print("-" * 52)

for segment_name, mask in segments.items():
    acc_v120 = accuracy_score(test_data_prod.loc[mask, "fraud"], pred_v120[mask])
    acc_v119 = accuracy_score(test_data_prod.loc[mask, "fraud"], pred_v119[mask])
    degradation = acc_v120 - acc_v119
    
    print(f"{segment_name:<20} {acc_v120:.3f}     {acc_v119:.3f}     {degradation:+.3f}")

# Root cause: v1.2.0 performs poorly on new merchants
# → Model not trained on recent merchant expansion
```

**Resolution:**

```python
# Scenario findings:
# - Data drift: 15% new merchants entered market in last 48 hours
# - Model trained 8 days ago: didn't see new merchants
# - Solution: Trigger retraining with latest data

# Implement automated retraining trigger
class RerainingTrigger:
    @staticmethod
    def check_data_drift(current_data, baseline_data, threshold=0.10):
        """Check if data distribution drifted > threshold"""
        # Kolmogorov-Smirnov test for each feature
        from scipy.stats import ks_2samp
        
        drifts = {}
        for col in baseline_data.columns:
            stat, pval = ks_2samp(baseline_data[col], current_data[col])
            drifts[col] = stat
        
        max_drift = max(drifts.values())
        if max_drift > threshold:
            return True, drifts
        return False, drifts
    
    @staticmethod
    def trigger_retraining():
        """Automatically retrain model"""
        # Submit training job
        os.system("kubectl apply -f training_job.yaml")
        print("✓ Retraining job submitted")
```

**Best Practices Applied:**
✓ **Immediate rollback to stop bleeding**
✓ **Segment analysis to find root cause**
✓ **Automated retraining trigger to prevent repeat**
✓ **Post-incident documentation**

---

### 7.3 Scenario 3: Cross-Region Model Deployment with Data Residency

**Problem Statement:**
Deploy fraud detection model across 3 regions (US, EU, APAC) with:
- Data residency requirements (EU data stays in EU)
- <50ms prediction latency
- Consistent model versions
- Compliance audit trail

**Architecture:**

```
┌─────────────────────────────────────────────────────────────┐
│                    Central Control Plane                    │
│  (Model Registry, Versioning, Policy Definition)           │
│  Location: us-east-1 (US East)                             │
└──────┬──────────────────────────────────────────────────────┘
       │
    ┌──┴────────────────────────────────────────────────┐
    │                                                    │
    ▼                                                    ▼
┌─────────────────┐                            ┌─────────────────┐
│ US East Region  │                            │ EU Region       │
├─────────────────┤                            ├─────────────────┤
│ Model Serving   │                            │ Model Serving   │
│ (Low latency)   │                            │ (Data in EU)    │
│ GPU Cluster: 16 │                            │ GPU Cluster: 8  │
└─────────────────┘                            └─────────────────┘
       │                                              │
       ▼                                              ▼
    US Customers                                 EU Customers
   (< 30ms latency)                           (< 50ms latency)
```

**Implementation:**

```yaml
# deploy-multi-region.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: model-deployment-policy
  namespace: ml-prod
data:
  regions.json: |
    {
      "us-east": {
        "region": "us-east-1",
        "cluster": "ml-prod-us-east",
        "replicas": 16,
        "data_residency": "US",
        "sla_latency_ms": 30,
        "features": ["all"]
      },
      "eu-west": {
        "region": "eu-west-1",
        "cluster": "ml-prod-eu-west",
        "replicas": 8,
        "data_residency": "EU",
        "sla_latency_ms": 50,
        "features": ["no_us_data"]
      },
      "apac-sg": {
        "region": "ap-southeast-1",
        "cluster": "ml-prod-apac",
        "replicas": 6,
        "data_residency": "APAC",
        "sla_latency_ms": 100,
        "features": ["all"]
      }
    }

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sync-models-across-regions
  namespace: ml-prod
spec:
  schedule: "0 * * * *"  # Every hour
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ml-ops
          containers:
          - name: model-sync
            image: ml-ops-tools:latest
            env:
            - name: MLFLOW_TRACKING_URI
              value: http://mlflow-server.mlops:5000
            - name: AWS_REGIONS
              value: "us-east-1,eu-west-1,ap-southeast-1"
            script: |
              #!/bin/bash
              get_latest_model_version() {
                curl -s http://mlflow-server/api/2.0/model-registry/model-versions \
                  -H "Content-Type: application/json" \
                  -d '{"name":"fraud-detector","stage":"Production"}' | \
                  jq '.model_versions[0].version'
              }
              
              deploy_to_region() {
                region=$1
                version=$2
                
                # Get region config
                cluster=$(jq -r ".[\"${region}\"].cluster" regions.json)
                replicas=$(jq -r ".[\"${region}\"].replicas" regions.json)
                
                # Update deployment
                kubectl --context=$cluster set image deployment/fraud-detector \
                  model-serving=registry.azurecr.io/fraud-detector:v${version}
              }
              
              VERSION=$(get_latest_model_version)
              for region in us-east eu-west apac-sg; do
                deploy_to_region $region $VERSION
              done
          restartPolicy: OnFailure
```

**Data Residency Enforcement:**

```python
# feature_store_routing.py - Ensure features don't cross borders

class DataResidencyRouter:
    def __init__(self):
        self.us_features = {"us_credit_score", "us_bank_info", "american_express"}
        self.eu_features = {"iban", "swift_code", "gdpr_compliant_features"}
        self.apac_features = {"alipay_score", "paytm_id"}
    
    def get_features_for_region(self, region: str) -> list:
        """Return only features allowed in region"""
        region_features = {
            "us-east": self.us_features | self.universal_features,
            "eu-west": self.eu_features | self.universal_features,
            "apac-sg": self.apac_features | self.universal_features,
        }
        return region_features.get(region, [])
    
    def validate_request(self, region: str, features: dict) -> bool:
        """Block requests with disallowed features"""
        allowed = self.get_features_for_region(region)
        provided = set(features.keys())
        
        if not provided.issubset(allowed):
            forbidden = provided - allowed
            raise ValueError(f"Forbidden features for {region}: {forbidden}")
        return True
```

**Monitoring Cross-Region Consistency:**

```python
# cross_region_monitoring.py

import concurrent.futures
import requests

class CrossRegionMonitor:
    def __init__(self):
        self.endpoints = {
            "us-east": "https://fraud-detector-us.ml.company.com/predict",
            "eu-west": "https://fraud-detector-eu.ml.company.com/predict",
            "apac-sg": "https://fraud-detector-apac.ml.company.com/predict",
        }
    
    def verify_consistency(self, test_request: dict) -> dict:
        """Verify all regions return same prediction"""
        results = {}
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            futures = {
                region: executor.submit(self._predict, endpoint, test_request)
                for region, endpoint in self.endpoints.items()
            }
            
            for region, future in futures.items():
                results[region] = future.result()
        
        # Check consistency
        predictions = [r["prediction"] for r in results.values()]
        confidence_scores = [r["confidence"] for r in results.values()]
        
        are_consistent = max(predictions) == min(predictions)
        confidence_variance = max(confidence_scores) - min(confidence_scores)
        
        return {
            "consistent": are_consistent,
            "confidence_variance": confidence_variance,
            "results_by_region": results,
            "alert": confidence_variance > 0.05  # Flag if variance > 5%
        }
    
    def _predict(self, endpoint: str, request: dict) -> dict:
        """Make prediction request"""
        try:
            response = requests.post(
                endpoint,
                json=request,
                timeout=2,
                headers={"X-API-Key": os.environ["API_KEY"]}
            )
            return response.json()
        except Exception as e:
            return {"error": str(e), "endpoint": endpoint}

# Run consistency check hourly
if __name__ == "__main__":
    monitor = CrossRegionMonitor()
    test_request = {
        "amount": 100.50,
        "merchant_id": "M123",
        "timestamp": "2025-01-23T10:00:00Z"
    }
    result = monitor.verify_consistency(test_request)
    
    if result["alert"]:
        print("⚠ ALERT: Regional prediction variance detected!")
        print(result)
```

**Best Practices Applied:**
✓ **Centralized versioning prevents regional drift**
✓ **Data residency respected via feature routing**
✓ **Automated cross-region deployment**
✓ **Consistency monitoring to catch regional issues**

---

### 7.4 Scenario 4: Disaster Recovery - Model Registry Failure

**Problem Statement:**
PostgreSQL database backing model registry crashes. Production models still serving OK (in-memory), but can't deploy new models or rollback. RTO: 1 hour.

**Disaster Recovery Plan:**

```yaml
# Backup Strategy
backup_schedule:
  frequency: every 15 minutes
  retention: 30 days
  strategy: 
    - Continuous replication to standby PostgreSQL (hot standby)
    - Daily snapshots to S3 (cold backup)
    - Export model registry metadata to git (version control)

# Example: Export to git
export_registry_to_git.sh:
  #!/bin/bash
  # Export all model registry state to JSON
  curl -s http://mlflow-server/api/2.0/model-registry/models | jq . > models_export.json
  curl -s http://mlflow-server/api/2.0/model-registry/model-versions | jq . > versions_export.json
  
  # Commit and push
  git add models_export.json versions_export.json
  git commit -m "MLOps: Model registry snapshot $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  git push origin main
```

**Failover Procedure:**

```
Time T+0:  PostgreSQL crashes
           ├─ Alert fires (connection timeout)
           └─ Models still serving (in-memory)

Time T+5:  Assess damage
           ├─ Check if hot standby is healthy
           ├─ Check if S3 backups are available
           └─ Determine RTO: use standby (10 min) vs. restore (30 min)

Time T+10: Failover to hot standby
           ├─ Update DNS: mlflow-server.mlops → hot-standby-postgres:5432
           ├─ Restart MLflow server pods (to reconnect)
           └─ Verify: curl http://mlflow-server/api/2.0/experiments

Time T+15: Verify critical operations
           ├─ Can register new model? (test)
           ├─ Can query existing models? (test)
           ├─ Can promote to production? (test)
           └─ Resume normal operations
```

**Detailed Recovery Script:**

```bash
#!/bin/bash
# mlops_disaster_recovery.sh

set -e

NAMESPACE="mlops"
MLFLOW_SERVICE="mlflow-server"
PRIMARY_DB="postgres-primary"
STANDBY_DB="postgres-standby"

echo "[$(date)] Starting MLOps disaster recovery procedure..."

# Step 1: Detect failure
step1_detect_failure() {
    echo "[$(date)] Step 1: Detecting failure..."
    
    if ! kubectl exec -n $NAMESPACE svc/$MLFLOW_SERVICE -- \
        curl -s http://localhost:5000/health > /dev/null; then
        echo "[$(date)] ✓ Confirmed: MLflow server connection failed"
        return 0
    fi
    echo "[$(date)] ✗ MLflow server responded - no failure detected"
    return 1
}

# Step 2: Check hot standby PostgreSQL
step2_check_standby() {
    echo "[$(date)] Step 2: Checking PostgreSQL hot standby..."
    
    if kubectl exec -n $NAMESPACE -it $STANDBY_DB -- \
        pg_isready -h localhost > /dev/null; then
        echo "[$(date)] ✓ Hot standby PostgreSQL is healthy"
        return 0
    fi
    echo "[$(date)] ✗ Hot standby failed, will use S3 restore"
    return 1
}

# Step 3: Failover to standby (if healthy)
step3_failover_to_standby() {
    echo "[$(date)] Step 3: Promoting standby to primary..."
    
    kubectl exec -n $NAMESPACE $STANDBY_DB -- \
        psql -c "SELECT pg_promote();"
    
    # Wait for promotion
    sleep 10
    
    # Update MLflow to point to new primary
    kubectl set env deployment/$MLFLOW_SERVICE \
        BACKEND_STORE_URI="postgresql://mlflow@$STANDBY_DB:5432/mlflow" \
        -n $NAMESPACE
    
    # Restart MLflow pods to reconnect
    kubectl rollout restart deployment/$MLFLOW_SERVICE -n $NAMESPACE
    kubectl rollout status deployment/$MLFLOW_SERVICE -n $NAMESPACE
    
    echo "[$(date)] ✓ Failover complete, MLflow restarted"
}

# Step 4: Verify functionality
step4_verify() {
    echo "[$(date)] Step 4: Verifying MLflow functionality..."
    
    local max_retries=30
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -s http://$MLFLOW_SERVICE.mlops:5000/api/2.0/experiments | jq . > /dev/null 2>&1; then
            echo "[$(date)] ✓ MLflow API responding"
            
            # Test model registry
            if curl -s http://$MLFLOW_SERVICE.mlops:5000/api/2.0/model-registry/models | jq . > /dev/null 2>&1; then
                echo "[$(date)] ✓ Model registry accessible"
                return 0
            fi
        fi
        
        echo "[$(date)] - Attempt $((retry+1))/$max_retries, waiting for MLflow..."
        sleep 2
        ((retry++))
    done
    
    echo "[$(date)] ✗ MLflow did not recover within timeout"
    return 1
}

# Main execution
if step1_detect_failure; then
    if step2_check_standby; then
        step3_failover_to_standby
    fi
    
    if step4_verify; then
        echo "[$(date)] ✓ Disaster recovery successful"
        # Log event for compliance
        echo "DISASTER_RECOVERY_EVENT: $(date -u +'%Y-%m-%dT%H:%M:%SZ') - MLOps recovered successfully" >> /var/log/mlops_recovery.log
        exit 0
    else
        echo "[$(date)] ✗ Recovery verification failed"
        exit 1
    fi
fi
```

**Best Practices Applied:**
✓ **High availability via hot standby**
✓ **Cold backups for worst-case scenario**
✓ **Automated failover to minimize manual steps**
✓ **Post-recovery verification to ensure correctness**
✓ **Compliance logging for audit trail**

---

## 8. Interview Questions

### Senior-Level Interview Questions

## 8. Most Asked Interview Questions for Senior DevOps Engineers

### Experiment Tracking & Metadata

#### Q1: Explain when you would NOT use a centralized experiment tracking system. What are the tradeoffs?

**Context:** This tests whether the engineer understands operational complexity vs. business value, not just that "tracking is good."

**Expected Answer (Senior Level):**

"It depends on the organizational maturity and experimentation velocity. I would **NOT** use centralized tracking if:

1. **Very small team (< 3 data scientists)**
   - Overhead: Setup, maintenance, infrastructure costs
   - Benefit: Minimal (team can communicate directly)
   - Alternative: Local logging + git commits
   - When to scale up: When team exceeds 5 people or experiments > 10/week

2. **Strict data residency constraints**
   - Fintech/healthcare where tracking server itself becomes compliance burden
   - Solution: Deploy tracker **within** compliant boundary (AWS PrivateLink)
   - Tradeoff: Higher deployment cost but maintains compliance

3. **Offline/disconnected environments (submarine, aircraft, satellite)**
   - No network for central server
   - Solution: Local tracking + batch sync when connected

4. **Research prototyping (throw-away code)**
   - If experiments are fundamentally exploratory and never productionized
   - Tracking overhead > value
   - Better: Git commits + cheap local logging

**Where I WOULD use it:**

- Production ML teams (> 5 people)
- Models deployed to production (governance requirement)
- Competitive advantage from rapid experimentation (tech companies, trading firms)
- Cross-team collaboration on shared models

**Architectural Tradeoff Example:**

```
Centralized Tracking:
+ Single source of truth
+ Compliance audit trail
+ Team collaboration
+ Scalable to 1000+ experiments
- Infrastructure overhead: $5K-20K/month
- Operational complexity
- Single point of failure
- Data privacy considerations

Decentralized (Git + Local):
+ Simple, self-contained
+ Low overhead
- Hard to query experiments
- No cross-team collaboration
- Difficult to enforce standards
- Governance nightmare at scale
```

**Real experience:** At my previous role, we kept local tracking for first 8 months with just 2 data scientists. By month 9, when we added 3 more scientists from another team, we spent 2 weeks as productivity tanked due to experiments conflicting and data scientists not knowing which was the 'best' model. Switched to MLflow, and productivity dropped initially (2 weeks learning curve) but then increased 3x once everyone understood the central repository."

---

#### Q2: Design an experiment tracking metadata schema for a healthcare ML team. What compliance requirements affect the schema?

**Context:** Tests knowledge of domain-specific requirements, HIPAA/GDPR implications, and schema design.

**Expected Answer:**

```python
# HIPAA-compliant experiment tracking schema
from dataclasses import dataclass
from typing import Dict, List, Optional
from datetime import datetime
from enum import Enum

class DataClassification(Enum):
    PHI = "protected_health_information"  # Covered under HIPAA
    PII = "personally_identifiable_info"
    PUBLIC = "public"
    PROPRIETARY = "proprietary"

@dataclass
class ExperimentMetadata:
    # === REQUIRED (enforced) ===
    experiment_id: str  # UUID format
    experiment_name: str
    team: str
    
    # === Data Classification (HIPAA Required) ===
    data_classification: DataClassification
    phi_present: bool  # If true, triggers audit logging
    pii_fields: List[str]  # Which fields contain PII
    
    # === Data Lineage (FDA 21 CFR Part 11) ===
    # Required for FDA validation
    data_version: str  # Immutable reference
    data_hash: str  # SHA256 of raw data
    data_source: str  # Which system/database
    data_date_range: Dict[str, str]  # {"start": "2025-01-01", "end": "2025-01-31"}
    
    # === Model Governance ===
    model_type: str
    clinical_use: str  # "screening" | "diagnostic" | "treatment_planning"
    intended_patients: str  # "adult_women" | "pediatric" | "general_population"
    
    # === Reproducibility ===
    git_commit: str
    python_version: str
    package_versions: Dict[str, str]
    random_seed: int
    
    # === Regulatory Requirements ===
    approver: str  # Who approved this experiment
    approval_date: datetime
    approval_reason: str
    
    # === Change Control ===
    previous_experiment_id: Optional[str]  # Traceability
    changes_from_baseline: str  # What changed and why
    
    # === Audit Trail ===
    created_by: str  # User ID or service account
    created_timestamp: datetime
    encryption_key_id: str  # Which key encrypted this
    
    # === Safety & Security ===
    potential_bias_assessed: bool
    fairness_metrics_computed: Dict[str, float]
    safety_issues_identified: List[str]
    coi_disclosure: str  # Conflict of interest

# Enforcement - reject experiments without required fields
def validate_healthcare_metadata(metadata: ExperimentMetadata) -> bool:
    required_fields = [
        'experiment_id',
        'phi_present',
        'data_hash',
        'data_version',
        'approver',
        'approval_date',
        'clinical_use',
        'fairness_metrics_computed'
    ]
    
    for field in required_fields:
        if getattr(metadata, field) is None:
            raise ValueError(f"HIPAA requirement: {field} cannot be null")
    
    # Additional validations
    if metadata.phi_present and not metadata.data_hash:
        raise ValueError("If PHI present, data must be hashed for audit")
    
    if metadata.clinical_use and not metadata.fairness_metrics_computed:
        raise ValueError("Fairness metrics required for clinical models")
    
    return True

# Compliance-specific query patterns
class ComplianceQueries:
    @staticmethod
    def audit_trail_for_model(model_name: str, period_days: int = 30):
        """For FDA inspections: show all experiments for past N days"""
        query = f"""
        SELECT 
            experiment_id, 
            experiment_name,
            created_by,
            created_timestamp,
            approval_date,
            approver,
            data_version,
            data_hash,
            changes_from_baseline
        FROM experiments
        WHERE experiment_name LIKE '%{model_name}%'
        AND created_timestamp > NOW() - INTERVAL '{period_days} days'
        ORDER BY created_timestamp DESC
        """
        return query
    
    @staticmethod
    def phi_access_audit():
        """HIPAA requirement: Log who accessed PHI"""
        return """
        SELECT 
            experiment_id,
            created_by,
            created_timestamp,
            pii_fields,
            access_reason
        FROM experiments
        WHERE phi_present = true
        ORDER BY created_timestamp DESC
        """

# Compliance notes
compliance_requirements = {
    "HIPAA": [
        "Encrypt PHI at rest and in transit",
        "Log all access to experiments with PHI",
        "Data retention: minimum 6 years",
        "Audit trail: immutable, timestamped"
    ],
    "FDA_21CFR11": [
        "Data integrity: hash verification",
        "System validation: version control",
        "Accountability: user attribution",
        "Audit trails: complete lifecycle"
    ],
    "GDPR": [
        "Right to be forgotten: can delete experiments",
        "Data minimal: only collect necessary",
        "Consent: must have approval before tracking"
    ],
    "SOC2": [
        "Encryption of metadata",
        "Access controls with MFA",
        "Monitoring and alerting",
        "Incident response procedures"
    ]
}
```

**Schema Architecture Rationale:**

"The key is that compliance isn't just 'logging data'—it's **enforcing structure** at the schema level:

- **HIPAA**: Forces explicit PHI classification (if you miss it, experiment fails)
- **FDA 21 CFR Part 11**: Mandates immutable audit trails (timestamps, hashes, approvals)
- **GDPR**: Requires consent tracking and deletion capabilities
- **SOC2**: Demands encryption and access controls

In practice, I'd implement this with:
1. **Database constraints** (NOT NULL on required fields)
2. **Application validation** (reject experiments pre-submission)
3. **Webhooks** (trigger automated compliance checks)
4. **Encryption-at-rest** (KeyVault integration)
5. **Audit logging** (separate immutable log stream)

The schema itself becomes the 'policy as code'—developers can't accidentally violate compliance because the database won't accept invalid experiments."

---

#### Q3: How would you handle experiment tracking across multiple geographic regions with data residency requirements?

**Context:** Tests distributed systems thinking, compliance knowledge, and pragmatic tradeoffs.

**Expected Answer:**

"This is a classic tension between operational simplicity (single central tracker) and regulatory compliance (data stays in-region). Here's how I'd approach it:

**Architecture Decision Tree:**

```
Requirement: Data residency + Experiment Tracking

├─ Option 1: Fully Distributed (per-region trackers)
│  ├─ Setup: MLflow instances in US, EU, APAC regions
│  ├─ Pros: Full compliance, data never leaves region
│  ├─ Cons: Impossible to query across regions
│  └─ Use case: Strict regulatory (EU GDPR, China data laws)
│
├─ Option 2: Hybrid (Central metadata + Regional artifacts)
│  ├─ Setup: 
│  │  ├─ Central PostgreSQL: Experiment metadata (EU-hosted)
│  │  ├─ Regional S3: Model artifacts (stay in-region)
│  │  └─ Encryption: End-to-end (key not in central system)
│  ├─ Pros: Query experiments globally, artifacts stay in-region
│  ├─ Cons: Complex, requires end-to-end encryption
│  └─ Use case: Most enterprises (GDPR + performance)
│
└─ Option 3: Proxy Pattern (Central query with regional sync)
   ├─ Setup: Read-only replication with controlled sync
   ├─ Pros: Central querying, data residency on writes
   ├─ Cons: Replication lag (hours/days)
   └─ Use case: Analytics focus, flexible on freshness
```

**I'd recommend Option 2 (Hybrid) for most enterprises. Here's implementation:**

```yaml
# Architecture: Central metadata + Regional artifacts

# Metadata (EU-hosted, immutable)
Central Metadata Store:
├── Location: eu-west-1 (Frankfurt)
├── Content: Experiment ID, hyperparams, metric values, timestamps
├── Auditing: Replication to UK (for cross-border compliance)
└── Size: Small (KB per experiment)

Regional Artifact Stores:
├── US Region: s3://us-artifacts/experiments/ (US-only)
├── EU Region: s3://eu-artifacts/experiments/ (EU-only)
├── APAC: s3://apac-artifacts/experiments/ (Singapore)
└── Size: Large (GB per model)
```

**Detailed Implementation:**

```python
# Multi-region experiment tracking with data residency

import hashlib
import boto3
from typing import Dict, Tuple

class RegionalExperimentTracker:
    def __init__(self):
        self.central_db = "postgresql://metadata-eu.internal:5432/experiments"
        self.regional_stores = {
            "us-east": "s3://artifacts-us-east/",
            "eu-west": "s3://artifacts-eu-west/",
            "apac": "s3://artifacts-apac/",
        }
        self.encryption_key_store = "kms"  # AWS KMS per region
    
    def log_experiment(self, 
                      experiment_data: Dict,
                      region: str) -> Tuple[str, str]:
        """
        Log experiment with enforced data residency
        
        Returns: (experiment_id, artifact_uri)
        """
        
        # Step 1: Store metadata centrally (no sensitive data)
        experiment_id = self._generate_id()
        metadata_record = {
            "experiment_id": experiment_id,
            "region": region,  # Where artifacts live
            "data_classification": experiment_data.get("classification"),
            "created_timestamp": datetime.now(),
            "created_by": experiment_data.get("user_id"),
            "artifact_location": f"{self.regional_stores[region]}{experiment_id}/",
            "metadata_hash": self._hash_metadata(experiment_data),
            # Do NOT store: model weights, raw training data, PHI
        }
        
        # Verify no sensitive data in central record
        assert "training_data" not in metadata_record
        assert "model_weights" not in metadata_record
        assert not self._contains_pii(metadata_record)
        
        # Store in central PostgreSQL
        self._store_central_metadata(metadata_record)
        
        # Step 2: Store artifacts in region-specific S3
        artifact_uri = f"{self.regional_stores[region]}{experiment_id}/"
        
        # Encrypt artifacts before upload
        encrypted_artifacts = self._encrypt_with_regional_key(
            experiment_data.get("artifacts"),
            region
        )
        
        # Upload to regional S3 (stays in-region due to bucket policy)
        self._upload_to_regional_store(
            encrypted_artifacts,
            artifact_uri,
            region
        )
        
        return experiment_id, artifact_uri
    
    def query_experiments_global(self, query: str) -> list:
        """
        Query experiments across regions (metadata only)
        
        This works because metadata is centralized and doesn't have sensitive data
        """
        results = self._central_db.execute(query)
        return results
    
    def retrieve_experiment_artifacts(self, experiment_id: str, region: str):
        """
        Retrieve artifacts - automatically enforced to region
        """
        artifact_uri = f"{self.regional_stores[region]}{experiment_id}/"
        
        # Verify requester is authorized for region
        assert self._user_authorized_for_region(region)
        
        # Retrieve encrypted artifacts from regional S3
        encrypted_data = boto3.client("s3", region_name=region).get_object(
            Bucket=self.regional_stores[region].replace("s3://", ""),
            Key=experiment_id
        )
        
        # Decrypt with regional key (key never leaves region)
        decrypted = self._decrypt_with_regional_key(
            encrypted_data,
            region
        )
        
        return decrypted
    
    def _encrypt_with_regional_key(self, data, region):
        """Encrypt using region-specific KMS key"""
        kms = boto3.client("kms", region_name=region)
        
        # Under the hood: KMS key never leaves region
        # Encryption happens in AWS, returns encrypted blob
        response = kms.encrypt(
            KeyId=f"arn:aws:kms:{region}:account:key/alias",
            Plaintext=data
        )
        return response["CiphertextBlob"]
    
    def verify_data_residency(self) -> Dict[str, bool]:
        """Compliance check: Verify no data crossed borders"""
        checks = {}
        
        for region, bucket in self.regional_stores.items():
            # Check: No objects in US bucket from EU queries
            bucket_access_log = self._get_bucket_access_log(bucket)
            checks[f"{region}_access_log_clean"] = \
                self._verify_access_patterns(bucket_access_log, region)
            
            # Check: Encryption keys are regional
            kms_keys = boto3.client("kms", region_name=region).list_keys()
            checks[f"{region}_kms_keys_regional"] = \
                all(k["Region"] == region for k in kms_keys)
        
        return checks
```

**Compliance Pattern:**

```yaml
# Data Residency Enforcement

EU Requests:
├── UI: User in Germany
├── Data Access: Only EU-west S3 region accessed
├── Logs: Verified no cross-border data transfer
└── Compliance: GDPR Article 44 (data transfer restriction)

US Requests:
├── UI: User in New York
├── Data Access: Only us-east S3 region accessed
├── Logs: Verified EU metadata not decrypted
└── Compliance: NY data law / contractual obligation

Compliance Failure Scenario:
├── US user attempts to access EU experiment
├── System check: Experiment has "EU-only" flag
├── Action: Block + Alert + Log incident
└── Audit: Record in compliance log for annual audit
```

---

### Model Versioning & Registries

#### Q4: Compare MLflow Model Registry vs. DVC vs. SageMaker Model Registry. When would you choose each?

**Context:** Tests understanding of tradeoffs, not memorization.

**Expected Answer:**

```
Comparison Matrix:

| Feature | MLflow | DVC | SageMaker |
|---------|--------|-----|-----------|
| Setup Complexity | Low (5 mins) | Medium (1 hour) | High (requires AWS account) |
| Cost | Free | Free | $0.02-0.10 per model/month |
| Versioning | API-based | Git-native | AWS-native |
| Approval Workflows | Basic tags | Manual via git | Built-in gates |
| Governance/Audit | Limited | Git history | Comprehensive |
| Promotion Stages | Manual | Manual | Automated pipelines |
| Integration | Python SDK + REST | Git + CLI | SageMaker pipelines |
| Multi-region | Manual setup | Manual | Native |
| Scalability | ~10K models | ~1K models | Unlimited |
| Data scientist experience | "Click deploy" | "Git push" | "AWS wizard" |

---

When I'd choose each:

**MLflow** (Most common choice):
✓ Fast setup, don't want infrastructure overhead
✓ Multi-cloud (runs anywhere: Kubernetes, VM, laptop)
✓ Python-centric teams
✓ Early-stage startups (cost conscious)
✗ Complex approval workflows
✗ Enterprise governance requirements
✗ Large organizations (>50 models)

Real scenario: "We had 8 models, 3 data scientists, deployed on own Kubernetes. MLflow took 2 hours to set up, and we've used it for 2 years with zero ops overhead."

---

**DVC** (Best for code-first teams):
✓ Models stored in git repo (everything in one place)
✓ Version control for both code AND data
✓ Teams already using git workflows
✓ Cost-free
✗ Not ideal for multiple concurrent experiments
✗ Can't handle large models easily (git history bloats)
✗ Harder to scale to 100+ models

Real scenario: "We're an ML research lab. We use DVC because all our work is in GitHub. It feels natural to just `git push` and the model is version controlled. But don't try to have 20 data scientists pushing models that day."

---

**SageMaker** (Enterprise at scale):
✓ Built-in approval gates (multi-stage promotions)
✓ Integrated with SageMaker pipelines (training → registry → serving)
✓ Enterprise governance and audit
✓ Easy A/B testing with SageMaker endpoints
✗ AWS-only (no multi-cloud)
✗ Vendor lock-in
✗ Overkill for small teams
✗ Cost adds up with scale

Real scenario: "We're a Fortune 500 financial services company. We need 7-year audit trails, approval workflows, and we're all-in on AWS. SageMaker Model Registry is worth the cost. But if we weren't AWS-only, I'd still use MLflow + git exports for compliance."

---

**Decision Flow:**

START
├─ Are you on AWS AND want integrated ML platform?
│  └─ YES → SageMaker ✓
│
├─ Is governance/audit your TOP concern?
│  ├─ YES + Need complex approvals → SageMaker
│  └─ YES + OK with simpler model → MLflow + git exports
│
├─ Is everything stored in git (including data)?
│  ├─ YES + Models < 1GB → DVC ✓
│  └─ NO → Skip DVC
│
└─ Default → MLflow (safe, simple, multi-cloud)
```

---

#### Q5: Design a model promotion workflow that requires 2 approvals, handles rollbacks, and maintains 7-year audit trails.

**Context:** Tests operational knowledge of compliance, state machines, and incident response.

**Expected Answer - Implementation:**

```python
# Compliance-grade model promotion workflow

from enum import Enum
from datetime import datetime
from typing import Dict, List, Optional
import json
import logging
from dataclasses import asdict

# Set up immutable audit logging
audit_logger = logging.getLogger("compliance_audit")
audit_handler = logging.handlers.RotatingFileHandler(
    "/var/log/compliance_audit.log",
    maxBytes=1_000_000_000,  # 1GB
    backupCount=700  # 7 years of daily logs
)
audit_logger.addHandler(audit_handler)

class ModelStage(Enum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"
    DEPRECATED = "deprecated"

class ApprovalRole(Enum):
    DATA_SCIENTIST = "data_scientist"
    ML_ENGINEER = "ml_engineer"
    COMPLIANCE_OFFICER = "compliance_officer"

class PromotionRequest:
    def __init__(self, model_name: str, version: str, requester: str):
        self.request_id = self._generate_request_id()
        self.model_name = model_name
        self.version = version
        self.requester = requester
        self.requested_at = datetime.utcnow()
        self.status = "PENDING"
        
        # 2-approval requirement
        self.approvals: Dict[ApprovalRole, Dict] = {}
        self.required_approvals = [
            ApprovalRole.ML_ENGINEER,
            ApprovalRole.COMPLIANCE_OFFICER
        ]
    
    def request_approval(self, role: ApprovalRole, approver: str):
        """Request approval from specific role"""
        if role not in self.required_approvals:
            raise ValueError(f"{role} approval not required")
        
        self.approvals[role] = {
            "approver": approver,
            "requested_at": datetime.utcnow(),
            "approved_at": None,
            "status": "PENDING"
        }
        
        self._log_audit(
            event="APPROVAL_REQUESTED",
            role=role.value,
            approver=approver
        )
    
    def approve(self, role: ApprovalRole, approver: str, notes: str):
        """Approve model promotion"""
        if role not in self.approvals:
            raise ValueError(f"No pending approval for {role}")
        
        # Set approval
        self.approvals[role]["status"] = "APPROVED"
        self.approvals[role]["approved_at"] = datetime.utcnow()
        self.approvals[role]["approver"] = approver
        self.approvals[role]["notes"] = notes
        
        # Check if all required approvals received
        if self._all_approvals_received():
            self.status = "APPROVED"
            self._log_audit(
                event="PROMOTION_APPROVED",
                all_approvers=[a["approver"] for a in self.approvals.values()]
            )
        else:
            remaining = [r for r in self.required_approvals 
                        if r not in self.approvals 
                        or self.approvals[r]["status"] != "APPROVED"]
            self._log_audit(
                event="PARTIAL_APPROVAL",
                role=role.value,
                approver=approver,
                remaining_approvals=[r.value for r in remaining]
            )
    
    def _all_approvals_received(self) -> bool:
        return all(
            self.approvals.get(role, {}).get("status") == "APPROVED"
            for role in self.required_approvals
        )
    
    def _log_audit(self, event: str, **kwargs):
        """Immutable compliance audit log"""
        audit_record = {
            "timestamp": datetime.utcnow().isoformat(),
            "request_id": self.request_id,
            "event": event,
            "model": self.model_name,
            "version": self.version,
            "details": kwargs,
            "immutable": True  # Mark for audit
        }
        audit_logger.info(json.dumps(audit_record))
    
    def _generate_request_id(self) -> str:
        return f"pr-{self.model_name}-{datetime.utcnow().timestamp()}"


class ModelPromotionOrchestrator:
    """Orchestrates multi-approval promotions"""
    
    def __init__(self, registry_uri: str):
        self.registry_uri = registry_uri
        self.pending_requests: Dict[str, PromotionRequest] = {}
    
    def initiate_promotion(self, 
                          model_name: str, 
                          version: str,
                          requester: str,
                          promotion_reason: str) -> PromotionRequest:
        """Start promotion workflow (requires 2 approvals)"""
        
        request = PromotionRequest(model_name, version, requester)
        
        # Request approvals from both ML Engineer and Compliance Officer
        request.request_approval(
            ApprovalRole.ML_ENGINEER,
            self._select_approver(ApprovalRole.ML_ENGINEER)
        )
        request.request_approval(
            ApprovalRole.COMPLIANCE_OFFICER,
            self._select_approver(ApprovalRole.COMPLIANCE_OFFICER)
        )
        
        self.pending_requests[request.request_id] = request
        
        # Notify approvers
        self._notify_approvers(request)
        
        request._log_audit(
            event="PROMOTION_INITIATED",
            requester=requester,
            reason=promotion_reason
        )
        
        return request
    
    def process_approval(self, 
                        request_id: str,
                        role: ApprovalRole,
                        approver: str,
                        approved: bool,
                        notes: str = ""):
        """Process an approval"""
        
        request = self.pending_requests.get(request_id)
        if not request:
            raise ValueError(f"Request {request_id} not found")
        
        if approved:
            request.approve(role, approver, notes)
            
            # If all approved, deploy to staging
            if request._all_approvals_received():
                self._promote_to_staging(request)
        else:
            request.status = "REJECTED"
            request._log_audit(
                event="PROMOTION_REJECTED",
                role=role.value,
                approver=approver,
                reason=notes
            )
            # Notify requester
            self._notify_rejection(request, approver, notes)
    
    def _promote_to_staging(self, request: PromotionRequest):
        """After approvals, move to staging"""
        # Update registry
        # ... MLflow API call ...
        request.status = "DEPLOYED_STAGING"
        request._log_audit(
            event="MODEL_DEPLOYED_STAGING",
            approvals=request.approvals
        )
    
    def initiate_rollback(self, 
                         model_name: str,
                         current_version: str,
                         previous_version: str,
                         reason: str,
                         initiated_by: str) -> Dict:
        """Emergency rollback (single approval sufficient)"""
        
        rollback_record = {
            "timestamp": datetime.utcnow().isoformat(),
            "model": model_name,
            "rollback_from": current_version,
            "rollback_to": previous_version,
            "reason": reason,
            "initiated_by": initiated_by,
            "approval_status": "EMERGENCY_ROLLBACK"
        }
        
        # Update registry
        # ... Deploy previous_version ...
        
        # Log immediately
        audit_logger.info(json.dumps(rollback_record))
        
        # Notify compliance team
        self._notify_compliance_team({
            "event": "EMERGENCY_ROLLBACK",
            "details": rollback_record
        })
        
        return rollback_record
    
    def get_audit_trail(self, 
                       model_name: str, 
                       start_date: datetime,
                       end_date: datetime) -> List[Dict]:
        """
        7-year retention: Query complete audit trail for compliance
        """
        # Read immutable audit log
        with open("/var/log/compliance_audit.log", "r") as f:
            records = []
            for line in f:
                record = json.loads(line)
                if (record["model"] == model_name and
                    start_date <= datetime.fromisoformat(record["timestamp"]) <= end_date):
                    records.append(record)
        
        return records
    
    def _notify_approvers(self, request: PromotionRequest):
        """Send notifications to required approvers"""
        # Email/Slack notification
        pass
    
    def _select_approver(self, role: ApprovalRole) -> str:
        """Select next available approver for role"""
        # Round-robin or load-balanced selection
        return "approver@company.com"
    
    def _notify_rejection(self, request: PromotionRequest, 
                         approver: str, reason: str):
        """Notify requester of rejection"""
        pass
    
    def _notify_compliance_team(self, event: Dict):
        """Notify compliance team of significant events"""
        pass
```

**State Machine Diagram:**

```
DEVELOPMENT
    ↓
REQUEST_PROMOTION
    ├─→ Request Approval from ML_ENGINEER
    ├─→ Request Approval from COMPLIANCE_OFFICER
    ↓
PENDING_APPROVAL (waiting for both)
    ├─ ML_ENGINEER approves → PARTIAL_APPROVAL
    ├─ COMPLIANCE_OFFICER approves → PARTIAL_APPROVAL
    ├─ Both approved → APPROVED
    ├─ Either rejects → REJECTED
    │                    ↓
    │            REQUEST_REJECTED
    └────────────────────↓
                    STAGING_DEPLOYMENT
                            ↓
                    PRODUCTION_READY
                            ↓
                    PRODUCTION
                            ↓
                    DEPRECATED (after 1 year)
                            ↓
                    ARCHIVED (after 7 years)

EMERGENCY_ROLLBACK (anytime from PRODUCTION):
    ├─ Initiated by on-call
    └─ → PRODUCTION (previous version)
         └─ AUDIT_LOG (for compliance review)
```

**Rollback SLA:**

```
Time T+0: Error detected in production (e.g., error rate 15% vs baseline 1%)
Time T+5: On-call engineer initiates rollback
Time T+10: Previous model version active
Time T+15: Monitoring confirms stability
Time T+30: Post-mortem initiated

Audit trail recorded:
- Who initiated rollback
- When
- From which model version
- To which model version
- Reason code
- Approval (if required)
- Post-incident notes
```

---

#### Q6: How do you handle model versioning when models depend on specific feature store versions?

**Context:** Tests understanding of data dependencies and reproducibility at scale.

**Expected Answer:**

"This is critical because a model is only reproducible if its features are reproducible. A model trained on features v2.1.0 can produce different predictions with features v2.2.0 due to feature computation changes.

**Tracking Framework:**

```
Model Version ↔ Feature Store Version (Immutable Reference)

Model: fraud-detector v1.2.0
├── Code: git commit abc123def456
├── Data: dataset-version: prod-2025-01-15
├── **Features: feature-store-v3.4.2** ← Critical link
│   ├── Feature 1: transaction_velocity (computed as X)
│   ├── Feature 2: merchant_risk_score (computed as Y)
│   └── Feature 3: user_history (computed as Z)
├── Metrics: accuracy 0.925
└── Training Time: 2025-01-15 14:32:00 UTC
```

**Implementation:**

```python
from datetime import datetime
from typing import Dict, List

class ModelVersionWithFeatures:
    def __init__(self, 
                 model_name: str,
                 model_version: str):
        self.model_name = model_name
        self.model_version = model_version
        
        # Critical: Explicit feature store reference
        self.feature_store_requirements = {
            "feature_store_name": "ml-features",
            "feature_store_version": None,  # Will be populated
            "features_used": [],
            "feature_compute_hash": None  # Hash of feature definitions
        }
        
        self.dependencies = []
    
    def set_feature_store_version(self, 
                                  fs_name: str,
                                  fs_version: str,
                                  features_used: List[str],
                                  feature_compute_hash: str):
        """Lock feature store version for this model"""
        self.feature_store_requirements = {
            "feature_store_name": fs_name,
            "feature_store_version": fs_version,
            "features_used": features_used,
            "feature_compute_hash": feature_compute_hash,
            "locked_at": datetime.utcnow().isoformat(),
            "locked_by": "training_pipeline"
        }
    
    def verify_feature_store_compatibility(self, 
                                          current_fs_version: str) -> bool:
        """
        Before inference, verify feature store hasn't changed
        
        Returns: True if safe to use, False if rollback needed
        """
        required_fs_version = \
            self.feature_store_requirements["feature_store_version"]
        
        if current_fs_version != required_fs_version:
            # Feature definition may have changed
            # Example: merchant_risk_score now includes international transactions
            print(f"""
            ⚠️  FEATURE STORE MISMATCH
            Model requires: feature-store v{required_fs_version}
            Current: feature-store v{current_fs_version}
            
            Risk: Model predictions may be invalid
            Action: 
            1. Verify feature computations haven't changed
            2. If changed, retrain model
            3. If not changed, update model metadata
            """)
            return False
        
        return True
    
    def get_inference_recipe(self) -> Dict:
        """
        For serving: Get exact exact recipe to compute features
        """
        return {
            "model_version": self.model_version,
            "feature_store_version": \
                self.feature_store_requirements["feature_store_version"],
            "features_to_compute": \
                self.feature_store_requirements["features_used"],
            "compute_instructions": self._fetch_feature_computation_code()
        }
    
    def _fetch_feature_computation_code(self) -> Dict:
        """Fetch exact feature computation code from feature store"""
        fs_version = self.feature_store_requirements["feature_store_version"]
        # Query: "Give me v3.4.2 of feature computation code"
        pass


# Compliance check: Prevent feature store changes without model retraining

class FeatureStoreVersionControl:
    def __init__(self):
        self.models_using_features: Dict[str, List[str]] = {}
        # Example: {"transaction_velocity": ["fraud-detector-v1.2.0", "v1.3.0"]}
    
    def can_release_new_feature_store_version(self, 
                                              old_version: str,
                                              new_version: str,
                                              feature_changes: Dict) -> bool:
        """
        Before releasing new feature store, check if models need retraining
        """
        
        breaking_changes = []
        
        for feature_name, change_type in feature_changes.items():
            if change_type == "COMPUTATION_CHANGED":
                # This feature's calculation changed
                affected_models = \
                    self.models_using_features.get(feature_name, [])
                breaking_changes.extend(affected_models)
        
        if breaking_changes:
            print(f"""
            ⚠️  CANNOT RELEASE feature-store v{new_version}
            
            The following models use features that changed:
            {breaking_changes}
            
            Action needed:
            1. Retrain affected models with new feature_store v{new_version}
            2. Update model registry with new feature dependency
            3. Then approve feature store release
            """)
            return False
        
        return True
    
    def register_model_features(self, 
                               model_version: str,
                               features_used: List[str]):
        """Track which models depend on which features"""
        for feature in features_used:
            if feature not in self.models_using_features:
                self.models_using_features[feature] = []
            self.models_using_features[feature].append(model_version)
```

**Versioning Strategy:**

```
Feature Store Versioning: Semantic Versioning for Features

MAJOR.MINOR.PATCH

v3.4.2
│ │ └─ PATCH: Bug fix, no computation change
│ └─── MINOR: New feature added, existing features unchanged
└───── MAJOR: Existing feature computation changed (breaking)

Example release:
- v3.4.0 → v3.4.1: Fix null handling (patch) → All models still compatible
- v3.4.1 → v3.5.0: Add new feature "user_vip_status" (minor) → Compatible
- v3.5.0 → v4.0.0: Change merchant_risk_score from 0-100 to 0-1 (MAJOR) 
                    → ALL MODELS USING merchant_risk_score MUST RETRAIN

Release process:
1. Feature store team proposes v4.0.0
2. System checks: fraud-detector-v1.2.0 uses merchant_risk_score
3. Alert: "Retraining required for fraud-detector"
4. Data scientist retrains: fraud-detector-v1.3.0 with feature-store-v4.0.0
5. After retraining complete: v4.0.0 approved for production release
```

**Real scenario:** "We had a model deployed that depended on feature store v2.1.0. Feature store team pushed v2.2.0 without notifying us. Model started producing garbage predictions because 'transaction_velocity' calculation changed from 'count in 1 hour' to 'count in 24 hours'."

We lost$50K before catching it (it affected fraud detection for a few hours). Now we have automated checks that prevent feature store releases if dependent models aren't explicitly retrained."
```

---

### Containerization & CI/CD

#### Q7: Explain the security implications of using nvidia/cuda base images in production. What are the alternatives?

**Context:** Tests security knowledge, practical tradeoffs, and understanding of ML infrastructure risks.

**Expected Answer:**

"nvidia/cuda base images are convenient but have major security and operational implications:

**Problems with nvidia/cuda in Production:**

```
Problem 1: Supply Chain Risk
├─ nvidia/cuda at dockerhub contains CUDA, CuDNN, proprietary libraries
├─ Single point of failure: If nvidia Docker registry compromised, all models affected
└─ Audit trail: Who knows what's in that image?

Problem 2: Size and Bloat
├─ nvidia/cuda:12.1.1-cudnn8: ~5GB uncompressed
├─ Official ml-trainer image becomes: ~7-8GB
├─ Every model serving replica: 8GB pull on startup
└─ 100 replicas × 8GB = 800GB of storage just for images

Problem 3: Vulnerability Management
├─ Large attack surface: CUDA + CuDNN + Ubuntu + dependencies
├─ Patch cycle: NVIDIA pushes updates irregularly
├─ You're locked into NVIDIA's patch schedule
└─ Compliance: "What version of OpenSSL is in nvidia/cuda:12.1.1?"

Problem 4: Reproducibility
├─ nvidia/cuda:12.1.1 from 2024 may differ from 2025
├─ CUDA library changes → Slightly different model outputs
└─ Model trained on cuda:12.1.1 may not behave same on :12.1.2

Problem 5: Licensing
├─ CUDA is proprietary
├─ Some orgs have licensing considerations
└─ Verification: Can your company legally use CUDA?
```

**Solutions (in order of preference):**

```
Option 1: Distroless + Minimal CUDA
├─ Start: python:3.10-slim (150MB)
├─ Add: Only required CUDA libraries (libcuda.so, ~200MB)
├─ Add: CuDNN libraries (compressed, ~500MB)
├─ Result: ~1GB final image (vs. 8GB)
└─ Benefit: Minimal attack surface, small, reproducible

Dockerfile:
FROM python:3.10-slim AS builder
# Install only runtime-required CUDA files

FROM python:3.10-slim
COPY --from=builder /usr/local/cuda/lib64 /usr/local/cuda/lib64
# No full CUDA...

Option 2: Multi-stage with nvidia/cuda build stage
├─ Builder stage: Use nvidia/cuda (for building with nvcc)
├─ Final stage: Ubuntu slim + only runtime libs from builder
└─ Result: ~2GB (vs. 8GB), still has full functionality

Option 3: Apple Silicon / ARM Compatibility
├─ nvidia/cuda is x86_64 only
├─ For Apple Silicon or ARM servers, use different base image
└─ Alternative: Use CPU-optimized base, trade latency for compatibility

Option 4: Open-source CUDA alternatives
├─ OpenCL (open standard)
├─ Triton (open-source GPU programming)
├─ Intel oneAPI (Intel GPU support)
└─ Reality: In practice, you usually need CUDA anyway
```

**My Recommended Approach:

```dockerfile
# Dockerfile.ml-production (Secure, Minimal, Reproducible)

# Stage 1: Build stage (large, has development tools)
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 AS builder

# Stage 2: Runtime (small, no dev tools)
FROM python:3.10-slim

# Copy ONLY runtime libraries from builder
COPY --from=builder /usr/local/cuda-12.1/lib64 /usr/local/cuda/lib64
COPY --from=builder /usr/local/cuda-12.1/include /usr/local/cuda/include

# Set library path
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV PATH=/usr/local/cuda/bin:$PATH

# Basic dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Security: Run as non-root
RUN useradd -m -u 1000 mluser
USER mluser

WORKDIR /app
COPY src/ ./

# Health check
HEALTHCHECK CMD python -c "import torch; print(torch.cuda.is_available())"

ENTRYPOINT ["python", "serving.py"]

Image size: ~1.5GB (vs. 8GB with full nvidia/cuda)
```

**Security Hardening:**

```bash
# 1. Scan image for vulnerabilities
trivy image fraud-detector-serving:v1.2.0
# ✓ "CUDA runtime library libcuda.so vulnerable? No (up to date)"

# 2. Sign image (ensure not tampered with)
cosign sign fraud-detector-serving:v1.2.0 \
  --key ~/.cosign/keys/cosign.key

# 3. Pin exact CUDA version
# BAD: FROM nvidia/cuda:latest (unpredictable)
# GOOD: FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 (reproducible)

# 4. Document CUDA dependencies
LABEL cuda.version="12.1.1"
LABEL cudnn.version="8.7.0"
LABEL python.version="3.10.13"
LABEL pytorch.version="2.1.0"

# 5. Include SBOM (Software Bill of Materials)
RUN pip install pip-audit && pip-audit > sbom.txt

# 6. Run security scanning in CI/CD
.gitlab-ci.yml:
build_image:
  script:
    - docker build -t ml-serving:v$VERSION .
    - trivy image ml-serving:v$VERSION --exit-code 1 --severity HIGH
    - cosign sign ml-serving:v$VERSION
```

**Real incident:** "We deployed a model using nvidia/cuda:12.1.0. Two weeks later, NVIDIA pushed a patch for a GPU hardware vulnerability. We had to rebuild 200 containers because the base image changed. Now we explicitly pin CUDA versions and have a monthly patching schedule."
```

---

#### Q8: Design a multi-stage Dockerfile for an ML training pipeline that achieves <1GB final image size.

**Context:** Tests optimization knowledge and practical production understanding.

**Expected Answer - Complete Solution:**

```dockerfile
# Dockerfile.ml-training-optimized
# Target: <1GB final image, full ML training capabilit

# Stage 1: Builder (build tools, compilers) - LARGE
# This stage accumulates all build dependencies
FROM python:3.10-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    gcc g++ gfortran \
    libopenblas-dev \
    liblapack-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Install Python packages to wheels
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt

# Clean cache
RUN pip cache purge

# Stage 2: Base runtime (runtime dependencies only)
FROM python:3.10-slim

LABEL version="2.1.0" \
      description="ML Training Pipeline - <1GB" \
      maintainer="ml-ops@company.com"

# Install runtime dependencies ONLY
RUN apt-get update &&apt-get install -y --no-install-recommends \
    libopenblas0 \
    liblapack3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user (security)
RUN useradd -m -u 1000 -s /bin/bash trainer

# Stage 3: Application + artifacts
FROM python:3.10-slim

# Copy runtime dependencies from stage 2
COPY --from=builder /build/wheels /wheels

# Install wheels (prebuilt, no compilation needed)
RUN pip install --no-index --find-links /wheels /wheels/* \
    && rm -rf /wheels \
    && pip cache purge

# Copy source code (small)
WORKDIR /workspace

COPY --chown=1000:1000src/ ./src/
COPY --chown=1000:1000 configs/ ./configs/
COPY --chown=1000:1000 .gitignore .

# Prefetch models (if applicable) to skip runtime download
RUN python -c "
import transformers
# Download BERT model to cache
transformers.AutoModel.from_pretrained('bert-base-uncased')
# Clean torch cache (keep models, remove build artifacts)
rm -rf ~/.cache/pip/*
"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import mlflow, torch; print('healthy')" || exit 1

# Environment
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
USER trainer

# Volumes for input/output
VOLUME ["/data", "/artifacts", "/models"]

# Default command
ENTRYPOINT ["python", "-u", "src/train.py"]
CMD ["--config", "configs/default.yaml"]

# Image size verification
# Build: docker build -t ml-trainer:test .
# Check: docker inspect ml-trainer:test | grep -i size
# Expected: <800MB
```

**optimization breakdown:**

```
Final Layer Size Analysis:

alpine:3.18 base: 7.3MB
python:3.10-slim base: 150MB
Dependencies (wheels): 600MB
├─ NumPy/Pandas/Scipy: 200MB
├─ PyTorch CPU: 300MB
├─ MLflow/scikit-learn: 100MB
└─ Other: 0MB
  
Source code: 50MB
├─ Training script: 10MB
├─ Config files: 5MB
├─ Utility modules: 35MB

Models (pre-cached): 50MB
├─ BERT tokenizer: 20MB
├─ Language model weights: 30MB

Total: 800MB + safety buffer = <1GB ✓
```

**Size optimization techniques:**

```python
# 1. Compress source code
# Before: src/ = 150MB (includes ML papers, notebooks)
# After: src/ = 35MB (only needed code)

# Solution in Dockerfile:
# COPY src/training.py ./src/  # Only required files
# vs.
# COPY src/ ./src/  # Entire directory

# 2. Pre-cache models to avoid runtime downloads
# Without: Model downloads at training start (+5 minutes)
# With: Models already in image

# 3. Minimize layer count
# Each RUN command adds a layer, avoid many redownloads

# 4. Multi-stage imports
# Builder compiles wheels, final (only binary wheels, not source)

# 5. Remove unnecessary toolscov
# Don't install: git, gcc, make (build tools) in final image
```

**Build and test:**

```bash
# Build with progress
docker build --progress=plain -t ml-trainer:v2.1.0 -f Dockerfile.ml-training-optimized .

# Inspect final size
docker images ml-trainer:v2.1.0
# REPOSITORY          TAG       SIZE
# ml-trainer          v2.1.0    847MB ✓

# Layer-by-layer analysis
docker history ml-trainer:v2.1.0
# See contribution of each layer

# Run training
docker run --gpus all \
  -v /data:/data:ro \
  -v /artifacts:/artifacts \
  ml-trainer:v2.1.0 \
  --config configs/production.yaml

# Verify model output
ls -la /artifacts/
# model.pkl, metrics.json, etc.
```

**Kubernetes spec with image:**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ml-training-job
spec:
  template:
    spec:
      containers:
      - name: trainer
        image: registry.azurecr.io/ml-trainer:v2.1.0
        imagePullPolicy: IfNotPresent  # Use cached image if available
        resources:
          requests:
            nvidia.com/gpu: 1
            memory: 8Gi
            cpu: 2
          limits:
            nvidia.com/gpu: 1
            memory: 16Gi
            cpu: 4
        volumeMounts:
        - name: data
          mountPath: /data
        - name: artifacts
          mountPath: /artifacts
      volumes:
      - name: data
        nfs:
          server: nfs-server.internal
          path: /ml-data
      - name: artifacts
        nfs:
          server: nfs-server.internal
          path: /ml-artifacts
      restartPolicy: Never
```

**Real-world metrics:**

```
Previous Dockerfile (without optimization):
• Image size: 4.2GB
• Pull time: 3-5 minutes per node
• Registry storage: 42GB (10 versions)
• Node disk: Bloated

Optimized Dockerfile:
• Image size: 847MB (80% reduction)
• Pull time: 20-30 seconds per node
• Registry storage: 8.5GB (10 versions)
• Savings: $500/month in storage + faster deployment
```

---

#### Q9: How do you handle GPU driver version mismatches across training and production environments?

**Context:** Tests understanding of GPU infrastructure complexity and reproducibility.

**Expected Answer:**

"GPU driver version mismatches cause the most insidious bugs in ML: model produces different results depending on GPU driver version, making debugging nearly impossible.

**The Problem:**

```
Training Environment:
├─ GPU: NVIDIA A100
├─ Driver: 535.13.04
├─ CUDA: 12.1.1
├─ CuDNN: 8.7.0
└─ Model Output: {predictions: [0.92, 0.15, 0.67]}

Production Environment:
├─ GPU: NVIDIA A100
├─ Driver: 544.06.06 (updated 6 months ago)
├─ CUDA: 12.1.1 (same)
├─ CuDNN: 8.7.0 (same)
└─ Model Output: {predictions: [0.91, 0.16, 0.68]} ← Different!

Result: 
- User sees predictions differ
- Accuracy drops 1-2% (within statistical noise, hard to detect)
- Debugging nightmare: "Code looks identical..."
```

**Root Causes:**

```
1. Floating-point Determinism
   ├─ GPU kernels for different drivers compute slightly differently
   ├─ Due to different optimization strategies, hardware quirks
   └─ Compound over thousands of computations

2. CUDA/CuDNN Kernel Library Updates
   ├─ Driver 535.x uses CuDNN v8.7.0 implementation A
   ├─ Driver 544.x uses CuDNN v8.7.0 implementation B (optimized)
   └─ Results differ by ~floating point epsilon (harmful at scale)

3. Hardware Feature Support
   ├─ Driver 535: Doesn't support GPU feature X
   ├─ Driver 544: Supports GPU feature X (uses different code path)
   └─ Different implementations = different results

4. Precision Issues
   ├─ TensorRT optimization uses different precision modes
   ├─ Mixed precision training with FP16 affected by driver
   └─ Inference with same model, different precision
```

**Solution: Driver Version Lock**

```yaml
# Kubernetes node pool with locked GPU drivers

apiVersion: v1
kind: Node
metadata:
  name: ml-gpu-node-1
  labels:
    gpu-driver: "535.13.04"
    gpu-model: "A100"
    cuda-version: "12.1.1"
    cudnn-version: "8.7.0"
spec:
  # Pin to specific driver version
  taints:
  - key: gpu-driver-version
    value: "535.13.04"
    effect: NoSchedule
  - key: stable-production
    value: "true"
    effect: NoExecute

---

apiVersion: batch/v1
kind: Job
metadata:
  name: training-job
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: gpu-driver
                operator: In
                values: ["535.13.04"]  # Lock to training driver
      tolerations:
      - key: gpu-driver-version
        operator: Equal
        value: "535.13.04"
        effect: NoSchedule
      containers:
      - name: trainer
        image: ml-trainer:v1.0.0
        # ...
```

**Verification Script:**

```python
# verify_gpu_compatibility.py

import subprocess
import json
import torch
import tensorflow as tf

def get_gpu_environment():
    """Capture full GPU environment for comparison"""
    
    # Get driver version
    driver_version = subprocess.check_output([
        "nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"
    ]).decode().strip()
    
    # Get CUDA version from nvidia-smi
    cuda_version = subprocess.check_output([
        "nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader"
    ]).decode().strip()
    
    # Get PyTorch GPU info
    pytorch_info = {
        "pytorch_version": torch.__version__,
        "cuda_version": torch.version.cuda,
        "cudnn_version": torch.backends.cudnn.version(),
        "gpu_count": torch.cuda.device_count(),
        "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else "None"
    }
    
    # Get TensorFlow GPU info
    tf_info = {
        "tensorflow_version": tf.__version__,
        "gpu_devices": len(tf.config.list_physical_devices('GPU'))
    }
    
    environment = {
        "driver_version": driver_version,
        "cuda_version": cuda_version,
        "pytorch": pytorch_info,
        "tensorflow": tf_info
    }
    
    return environment

def compare_environments(training_env: dict,
                       production_env: dict) -> dict:
    """Compare and flag mismatches"""
    
    mismatches = {}
    
    for key in training_env:
        if training_env[key] != production_env.get(key):
            mismatches[key] = {
                "training": training_env[key],
                "production": production_env.get(key),
                "mismatch": True
            }
    
    return mismatches

def verify_deterministic_inference(model_path: str,
                                   test_input: torch.Tensor,
                                   num_runs: int = 10) -> bool:
    """
    Verify model produces same output across multiple runs
    
    Detects floating-point non-determinism
    """
    model = torch.load(model_path)
    model.eval()
    
    outputs = []
    
    with torch.no_grad():
        for _ in range(num_runs):
            output = model(test_input)
            outputs.append(output.cpu().numpy())
    
    # Check if all outputs are identical (within numerical precision)
    tolerance = 1e-5
    reference_output = outputs[0]
    
    for i, output in enumerate(outputs[1:], 1):
        if not np.allclose(reference_output, output, atol=tolerance):
            max_diff = np.max(np.abs(reference_output - output))
            print(f"⚠️  Run {i}: Non-deterministic output detected")
            print(f"   Max difference: {max_diff:.2e} (tolerance: {tolerance})")
            return False
    
    print("✓ Model deterministic across 10 runs")
    return True

# Use in CI/CD
if __name__ == "__main__":
    print("Gathering GPU environment...")
    current_env = get_gpu_environment()
    print(json.dumps(current_env, indent=2))
    
    # Compare with training environment
    training_env_json = """
    {
        "driver_version": "535.13.04",
        "cuda_version": "12.1.1",
        "pytorch": {"version": "2.1.0", "cuda": "12.1"}
    }
    """
    training_env = json.loads(training_env_json)
    
    print("\nComparing environments...")
    mismatches = compare_environments(training_env, current_env)
    
    if mismatches:
        print("⚠️  MISMATCHES DETECTED:")
        for key, mismatch in mismatches.items():
            print(f"  {key}: {mismatch}")
        print("\n🚨 WARNING: Model behavior may differ!")
    else:
        print("✓ Environments match!")
```

**Best Practice: Lock Everything**

```dockerfile
# Dockerfile.GPU-reproducible

FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# LOCK kernel version (affects GPU driver compatibility)
RUN apt-get update && \
    apt-mark hold linux-image-generic && \
    apt-mark hold nvidia-driver-535

# LOCK CUDA version
LABEL cuda.version="12.1.1" \
      cudnn.version="8.7.0" \
      driver.version="535.13.04"

# Document exact versions in image
RUN nvidia-smi > /root/gpu-environment.txt && \
    cat /root/gpu-environment.txt

ENTRYPOINT ["python", "train.py"]
```

**Deployment Checklist:**

```
Before deploying model from training → production:

✓ Training GPU driver: 535.13.04? → Yes
✓ Production GPU driver: 535.13.04? → Check! If different, fail deployment
✓ CUDA version match? → Yes
✓ CuDNN version match? → Yes
✓ PyTorch version match? → Yes
✓ Model determinism verified? → Run 10x, check outputs identical
✓ Production cluster configured for driver lock? → Kubernetes labels set

If ANY mismatch: BLOCK deployment, alert team
```

---

#### Q10: Design a CI/CD pipeline for a model that has 24-hour training time and costs $5,000 per training run.

**Context:** Tests cost optimization, job scheduling, and practical enterprise constraints.

**Expected Answer:**

"With $5K per training run, every hour and every failure matters. Must design to minimize waste while maintaining quality:

**Pipeline Architecture:**

```
Cost-Aware ML CI/CD Pipeline:

┌──────────────────────────────────────────────────────┐
│  Trigger (Code push or scheduled)                   │
└────────────────┬─────────────────────────────────────┘
                 │
        ┌────────▼────────────┐
        │ Cost Pre-flight     │ (5 min, FREE)
        │ ├─ Data quality?    │
        │ ├─ Features fresh?  │
        │ └─ Approved by team?│
        └────────┬────────────┘
                 │ (Cost check: $5K justified?)
        ┌────────▼────────────────────┐
        │ HOLD: Wait for low-cost hour │ (Schedule to off-peak)
        │ ├─ 10pm-6am: 60% cheaper    │
        │ └─ Weekends: 30% cheaper    │
        └────────┬────────────────────┘
                 │
        ┌────────▼──────────────────┐
        │ Start 24h Training        │ ($5,000)
        │ ├─ GPU cluster: 16× A100  │
        │ ├─ Autoscaling: Yes       │
        │ ├─ Spot instances: 70%    │
        │ └─ On-demand: 30%         │
        └────────┬──────────────────┘
                 │
        ┌────────▼─────────────────────┐
        │ Monitoring (continuous, $0)  │
        │ ├─ Loss curve normal?        │
        │ ├─ GPU utilization > 80%?    │
        │ ├─ ETA < 24h?               │
        │ └─ Cost < $5500? (buffer)   │
        └────────┬─────────────────────┘
                 │
        ┌────────▼────────────────────┐
        │ Auto-kill if exceeds budget │
        │ ├─ Cost > $5500? → Kill     │
        │ ├─ Loss not improving? → Halt│
        │ └─ Time > 26h? → Timeout    │
        └────────┬────────────────────┘
                 │  (Training complete)
        ┌────────▼─────────────────────┐
        │ Evaluation (1 hour, $200)   │
        │ ├─ Validate metrics          │
        │ ├─ Compare vs baseline       │
        │ └─ Fairness tests            │
        └────────┬─────────────────────┘
                 │
        ┌────────▼──────────────────┐
        │ Approve? Manual gate      │
        │ ├─ Cost vs benefit: OK?   │
        │ ├─ Metrics acceptable?    │
        │ └─ BizJustification clear?│
        └────────┬──────────────────┘
                 │
        ┌────────▼───────────────────────┐
        │ Promote to staging              │
        │ ├─ Shadow deploy (24h, $100)   │
        │ └─ Monitor divergence          │
        └────────┬───────────────────────┘
                 │
        ┌────────▼──────────┐
        │ Prod deployment   │
        │ └─ Canary (5% → 25% → 100%)
        └───────────────────┘

Total cost per successful cycle: ~$5.5K
Failures cost same $5K: Minimize them!
```

**Implementation:**

```yaml
# Full GitLab CI configuration for expensive ML training

stages:
  - preflight
  - schedule
  - train
  - evaluate
  - approve
  - deploy

variables:
  TRAINING_COST_BUDGET: "5500"  # $5500 budget (10% buffer)
  GPU_HOURLY_COST: "3.50"      # A100 on-demand price
  TRAINING_DURATION_HOURS: "24"
  EXPECTED_COST: "84"           # 24 hours × $3.50
  SPOT_DISCOUNT: "0.70"         # Spot instances 70% discount

# Stage 1: Preflight checks (5 min, $0)
preflight_checks:
  stage: preflight
  tags:
    - docker
  script:
    - echo "Running pre-flight checks..."
    
    # Check 1: Data freshness
    - |
      DATA_AGE=$(date +%s) - $(stat -c %Y /data/training/)
      DAYS_OLD=$((DATA_AGE / 86400))
      if [ $DAYS_OLD -gt 7 ]; then
        echo "⚠️ Data older than 7 days ($DAYS_OLD days)"
        echo "Consider updating training data first"
        exit 1
      fi
    
    # Check 2: Feature store stability
    - curl -s http://feature-store/health || exit 1
    
    # Check 3: Model registry accessible
    - curl -s http://mlflow-server/api/2.0/experiments || exit 1
    
    # Check 4: Is baseline model still in production?
    - |
      BASELINE_ACCURACY=$(curl -s http://model-metrics/current | jq .accuracy)
      if [ "$BASELINE_ACCURACY" == "null" ]; then
        echo "⚠️ Baseline model not healthy"
        exit 1
      fi
    
    # Check 5: Sufficient budget authorization
    - |
      APPROVED_BUDGET=$(curl -s http://cost-api/budget/ml-team/current)
      if [ "$APPROVED_BUDGET" -lt $TRAINING_COST_BUDGET ]; then
        echo "❌ Budget exceeded: $APPROVED_BUDGET < $TRAINING_COST_BUDGET"
        exit 1
      fi
    
    echo "✓ All preflight checks passed"

# Stage 2: Schedule to low-cost hours (Wait for off-peak)
schedule_training:
  stage: schedule
  tags:
    - docker
  script:
    - |
      CURRENT_HOUR=$(date +%H)
      CURRENT_DAY=$(date +%u)  # 1=Monday, 7=Sunday
      
      # Off-peak hours: 10pm-6am (US time)
      if [ $CURRENT_HOUR -lt 6 ] || [ $CURRENT_HOUR -ge 22 ]; then
        echo "✓ Current hour is off-peak (10pm-6am)"
        COST_MULTIPLIER=1.0  # Full price still high, but cheapest
        START_NOW=true
      elif [ $CURRENT_DAY -eq 6 ] || [ $CURRENT_DAY -eq 7 ]; then
        echo "✓ Weekend pricing applies (30% cheaper)"
        COST_MULTIPLIER=0.70
        START_NOW=true
      else
        echo "⏳ Peak hours detected, scheduling for next off-peak window"
        # Calculate next off-peak time
        if [ $CURRENT_HOUR -lt 22 ]; then
          NEXT_OFF_PEAK_HOUR=$((22 - CURRENT_HOUR))
          echo "  Waiting $NEXT_OFF_PEAK_HOUR hours until 10pm"
        else
          NEXT_OFF_PEAK_HOUR=$((6 - CURRENT_HOUR + 24))
          echo "  Waiting $NEXT_OFF_PEAK_HOUR hours until 6am"
        fi
        # Schedule job for off-peak
        at now + $NEXT_OFF_PEAK_HOUR hours << EOF
        git push http://gitlab/ml-team/fraud-detector -o ci.skip
        EOF
        # Wait
        while [ "$(date +%H)" -lt 22_ ] || [ "$(date +%H)" -ge 6 ]; do
          sleep 600  # Check every 10 minutes
        done
        START_NOW=true
      fi
  when: manual  # Require explicit trigger or wait for schedule

# Stage 3: Training (24 hours, $5K)  
.training_base:
  stage: train
  tags:
    - gpu
    - pricey
  timeout: 26h  # 24h + 2h buffer for cleanup
  artifacts:
    paths:
      - runs/
      - cost_report.json
    expire_in: 90 days
  retry:
    max: 1  # Only retry if infrastructure fails (not model issues)
    when:
      - runner_system_failure
      - stuck_or_timeout_failure

train_model_with_cost_tracking:
  extends: .training_base
  script:
    - |
      # Initialize cost tracking
      EXPERIMENT_ID="exp-$(date +%s)"
      START_TIME=$(date +%s)
      COST_LOG="cost_report.json"
      
      # Spot instance setup (70% cheaper)
      export KARPENTER_CONSOLIDATION=disabled  # Don't scale down mid-training
      
      # Start training with cost monitoring
      python -u src/train.py \
        --experiment-id $EXPERIMENT_ID \
        --cost-tracking-enabled true \
        --max-cost-usd $TRAINING_COST_BUDGET \
        --max-duration-hours 24 \
        --metrics-interval 30  # Check metrics every 30 min
        
      # Training completed successfully
      END_TIME=$(date +%s)
      DURATION_SECONDS=$((END_TIME - START_TIME))
      DURATION_HOURS=$(echo "scale=2; $DURATION_SECONDS / 3600" | bc)
      
      # Calculate actual cost
      # Cost = duration × hourly_rate × spot_discount
      ACTUAL_COST=$(
        echo "scale=2; $DURATION_HOURS * $GPU_HOURLY_COST * $SPOT_DISCOUNT" | bc
      )
      
      # Report
      cat > $COST_LOG << EOF
      {
        "experiment_id": "$EXPERIMENT_ID",
        "duration_hours": $DURATION_HOURS,
        "gpu_hourly_cost": $GPU_HOURLY_COST,
        "spot_discount": $SPOT_DISCOUNT,
        "actual_cost": $ACTUAL_COST,
        "budget": $TRAINING_COST_BUDGET,
        "under_budget": $([ $(echo "$ACTUAL_COST < $TRAINING_COST_BUDGET" | bc) -eq 1 ] && echo "true" || echo "false")
      }
      EOF
      
      cat $COST_LOG
  only:
    - main
    - schedules

# Stage 4: Evaluation (1 hour, $200)
evaluate_model:
  stage: evaluate
  dependencies:
    - train_model_with_cost_tracking
  tags:
    - gpu
  script:
    - |
      export EXPERIMENT_ID=$(cat cost_report.json | jq -r .experiment_id)
      
      python -u src/evaluate.py \
        --experiment-id $EXPERIMENT_ID \
        --test-data s3://test-data/latest.parquet \
        --output evaluation_report.html
      
      # Extract metrics
      ACCURACY=$(python -c "import json; r=json.load(open('metrics.json')); print(r['accuracy'])")
      
      # Check against baseline
      BASELINE=$(curl -s http://model-metrics/baseline | jq -r .accuracy)
      IMPROVEMENT=$(echo "scale=4; $ACCURACY - $BASELINE" | bc)
      
      if (( $(echo "$IMPROVEMENT > 0.01" | bc -l) )); then
        echo "✓ Model improves accuracy by ${IMPROVEMENT}% vs baseline"
      else
        echo "⚠️ Minimal improvement: ${IMPROVEMENT}%"
      fi

# Stage 5: Manual Approval (Cost vs Benefit)
approve_promotion:
  stage: approve
  tags:
    - docker
  when: manual  # Require explicit approval
  script:
    - echo "Waiting for approval..."
    - |
      # Only proceed if approved
      echo "✓ Model approved for promotion"
      
      # Log approval for audit
      echo "{
        'approved_at': '$(date)',
        'approved_by': '$GITLAB_USER_LOGIN',
        'justification': 'Empirically shows $IMPROVEMENT% improvement'
      }" > approval_log.json

# Stage 6: Deploy to staging (24 hours, $100)
deploy_staging:
  stage: deploy
  tags:
    - k8s
  script:
    - export EXPERIMENT_ID=$(cat cost_report.json | jq -r .experiment_id)
    - kubectl set image deployment/fraud-detector-staging \
        ml-model=registry.azurecr.io/fraud-detector:$EXPERIMENT_ID
    - kubectl rollout status deployment/fraud-detector-staging --timeout=10m
    - echo "✓ Deployed to staging for 24h shadow mode"

# Stage 7: Production (optional)
deploy_prod:
  stage: deploy
  tags:
    - k8s
  script:
    - kubectl set image deployment/fraud-detector-prod \
        ml-model=registry.azurecr.io/fraud-detector:$EXPERIMENT_ID
    - python src/start_canary.py --version $EXPERIMENT_ID --traffic 5
  when: manual
```

**Cost Optimization Strategies:**

```python
# cost_aware_training.py

import time
import psutil
import boto3

class CostAwareTrainer:
    def __init__(self, max_cost_usd: float, max_duration_hours: int):
        self.max_cost = max_cost_usd
        self.max_duration = max_duration_hours * 3600
        self.start_time = time.time()
        self.hourly_cost = 3.50  # A100 on-demand
        self.spot_discount = 0.70
        
    def should_continue_training(self) -> bool:
        """Decide if training should continue based on cost/time"""
        
        elapsed_seconds = time.time() - self.start_time
        elapsed_hours = elapsed_seconds / 3600
        
        # Calculate current cost
        current_cost = elapsed_hours * self.hourly_cost * self.spot_discount
        
        # Hard stops
        if current_cost > self.max_cost:
            print(f"❌ Cost limit exceeded: ${current_cost:.2f} > ${self.max_cost}")
            return False
        
        if elapsed_seconds > self.max_duration:
            print(f"❌ Duration limit exceeded: {elapsed_hours:.1f}h > {self.max_duration/3600}h")
            return False
        
        # Soft warnings
        if current_cost > 0.9 * self.max_cost:
            print(f"⚠️ Approaching cost limit: ${current_cost:.2f} (90% of budget)")
        
        # Cost-efficiency check:
        # If model improvement per hour is decreasing, stop early
        improvement_rate = self.get_improvement_rate()
        if improvement_rate < 0.001 and elapsed_hours > 12:  # <0.1% per hour after 12h
            print(f"⚠️ Diminishing returns: {improvement_rate:.4f}% improvement/hour")
            print("Stopping early to save ${:.2f}".format(
                (self.max_duration - elapsed_seconds) / 3600 * self.hourly_cost * self.spot_discount
            ))
            return False
        
        return True
    
    def get_improvement_rate(self) -> float:
        """Calculate model improvement per hour of training"""
        # Query MLflow for metric history
        pass
```

**Cost Monitoring Dashboard:**

```
Real-time cost tracking (displayed in CI/CD logs):

📊 Training Cost Report (Experiment: exp-1705939200)

Time Elapsed: 12h 34m / 24h
├─ Cost so far: $1,456 (1,802 GPU-hours @ $3.50 with 70% spot discount)
├─ Projected cost: $2,765 (if same pace)
├─ Budget remaining: $2,735 ✓ (49% of budget)

GPU Utilization: 95%
├─ Batch size optimization: Good
└─ Data loading efficiency: Good

Metric Progress:
├─ Hour 0: Loss = 0.542
├─ Hour 6: Loss = 0.312 (improvement rate: 3.83%/hour)
├─ Hour 12: Loss = 0.189 (improvement rate: 2.05%/hour)
├─ Projected final loss: 0.098

Cost Efficiency:
├─ Cost per 1% accuracy gain: $45
├─ Cost per 0.01 loss reduction: $145
├─ Status: Within budget, good ROI ✓

⏱ Estimated completion: 22h 15m
💰 Projected final cost: $2,456
✅ Status: On track, within budget
```

**Real scenario:** "We had a training job that we thought would finish in 24h. It took 27h due to data loading bottlenecks. Cost us$5,200 in GPU time, but it exposed that we needed to optimize our data pipeline. Now we profilethe data loading in preflight, and we use a 24-hour hard timeout (auto-kill if exceeds time)."
```

---

## Conclusion

This comprehensive study guide covers enterprise-grade MLOps patterns for senior DevOps engineers. The key takeaways:

**Experiment Tracking:** Reproducibility foundation—capture all context
**Model Versioning:** Governance and traceability across lifecycle
**Containerization:** Reproducible environments at scale
**CI/CD for ML:** Async, resource-aware, long-duration pipelines

**Remember:** MLOps is not about perfect accuracy—it's about reproducible, auditable, scalable ML systems in production.

---

**Document Version:** 2.0  
**Status:** Complete - Foundation + Core Topics + Scenarios + Interview Questions  
**Last Updated:** January 2025  
**Audience:** Senior DevOps Engineers (5-10+ years)  
**Page Count:** ~120 pages equivalent  
**Total Content:** 25,000+ words, 40+ code examples, 20+ diagrams

