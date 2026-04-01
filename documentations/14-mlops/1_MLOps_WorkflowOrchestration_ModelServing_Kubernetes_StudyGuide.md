# MLOps: ML Workflow Orchestration, Model Serving Architectures, Model Serving Frameworks & Kubernetes for MLOps

**Study Guide for Senior DevOps Engineers | 5–10+ Years Experience**

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [ML Workflow Orchestration](#ml-workflow-orchestration)
4. [Model Serving Architectures](#model-serving-architectures)
5. [Model Serving Frameworks](#model-serving-frameworks)
6. [Kubernetes for MLOps](#kubernetes-for-mlops)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

MLOps (Machine Learning Operations) represents the convergence of software engineering best practices and machine learning systems, extending DevOps principles into the data science domain. This study guide focuses on four critical pillars of MLOps enterprise implementation:

1. **ML Workflow Orchestration** - Automating the end-to-end ML lifecycle from data ingestion through model deployment
2. **Model Serving Architectures** - Designing scalable, fault-tolerant systems for real-time and batch inference
3. **Model Serving Frameworks** - Leveraging specialized tools and runtimes for efficient model deployment
4. **Kubernetes for MLOps** - Operating containerized ML workloads at enterprise scale

These components work synergistically to enable organizations to move from ad-hoc ML experiments to reproducible, auditable, production-grade ML systems.

### Why It Matters in Modern DevOps Platforms

The traditional separation between data science, ML engineering, and DevOps has become increasingly untenable. Modern DevOps platforms must address:

- **Reproducibility Crisis**: ML models trained today may produce different results tomorrow without proper versioning and orchestration
- **Infrastructure Complexity**: ML workloads have unique demands (GPU scheduling, variable compute patterns, data locality requirements) that standard container orchestration cannot handle alone
- **Operational Blind Spots**: Unlike traditional applications, ML systems can silently degrade through data drift, model drift, and concept drift without explicit failure signals
- **Cost Optimization**: Inefficient model serving can waste substantial compute resources; proper architecture and orchestration can reduce inference costs by 40-60%
- **Compliance and Governance**: Regulated industries (finance, healthcare) require complete audit trails of model development, training data, and serving decisions

DevOps engineers transitioning to MLOps must understand that infrastructure concerns transcend traditional networking and compute—they now encompass data pipelines, model lifecycles, and inference patterns.

### Real-World Production Use Cases

**Financial Services: Real-Time Fraud Detection**
- ML orchestration pipelines retrain models hourly with transaction data
- Model serving architecture uses A/B testing to validate new models against production traffic
- Kubernetes manages varying inference loads, scaling from 1K to 100K+ predictions/second during market hours
- Multiple model versions run simultaneously for canary deployments and decision confidence scoring

**E-Commerce: Personalization at Scale**
- Airflow DAGs orchestrate ETL jobs feeding feature stores
- REST and gRPC endpoints serve recommendations from multi-model ensembles
- KServe provides inferencing with automatic scaling based on prediction latency
- GPU node pools handle embedding generation while CPU pools serve classification models

**Healthcare: Diagnostic Imaging Analysis**
- Kubeflow Pipelines orchestrate medical image preprocessing, model inference, and result aggregation
- Batch inference processes overnight imaging queues (efficiency > latency)
- TensorFlow Serving manages multiple model versions for A/B testing treatment recommendations
- Kubernetes enforces pod affinity/anti-affinity for compliance-mandated workload isolation

**Retail: Demand Forecasting**
- Prefect orchestrates hourly forecast model retraining across 500+ store locations
- BentoML bundles preprocessing logic with model artifacts for reproducible deployments
- Async inference queues decouple forecasting from inventory management systems
- GPU-equipped Kubernetes nodes handle seasonal spike predictions

### Where It Typically Appears in Cloud Architecture

MLOps infrastructure appears across multiple layers of modern cloud architectures:

```
┌─────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Layer                 │
│  (Model validation, versioning, artifact management)    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         ML Workflow Orchestration Layer                 │
│  (Airflow, Kubeflow, Argo Workflows, Prefect)           │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴────────────┬────────────┐
         │                        │            │
    ┌────▼──────┐   ┌────────┬───▼──┐  ┌──────▼──────┐
    │ Data      │   │Feature │Model │  │ Online      │
    │Pipelines  │   │Stores  │Cache │  │Serving      │
    └─────┬─────┘   └────┬───┴─────┘  └──────┬───────┘
          │              │                    │
    ┌─────▼──────────────▼────────────────────▼──────┐
    │  Kubernetes Orchestration Layer                │
    │  (Pod scheduling, GPU allocation, scaling)     │
    ├─────────────────────────────────────────────────┤
    │  ┌──────────────┐  ┌──────────────┐            │
    │  │ Training     │  │ Inference    │            │
    │  │ Workloads    │  │ Pods (KServe,│            │
    │  │ (GPUs, CPU)  │  │ Seldon, etc) │            │
    │  └──────────────┘  └──────────────┘            │
    └─────────────────────────────────────────────────┘
          │
    ┌─────▼─────────────────────────────────┐
    │ Observability & Monitoring Layer      │
    │ (Prometheus, Grafana, Model Metrics)  │
    └───────────────────────────────────────┘
```

**Typical integration points:**
- **Ingestion**: Data sources → Orchestration pipelines → Model training
- **Training**: Orchestration systems schedule GPU-accelerated training on Kubernetes
- **Registry**: Trained models stored in artifact repositories (S3, artifact registries)
- **Deployment**: Model serving frameworks deployed as Kubernetes services
- **Inference**: Applications call serving endpoints (REST, gRPC) at latency requirements
- **Monitoring**: Predictions, latencies, model performance drift captured and analyzed
- **Feedback**: Performance data flows back to orchestration for retraining triggers

---

## Foundational Concepts

### Key Terminology

**Pipeline DAG (Directed Acyclic Graph)**
- A workflow representation where nodes are tasks and edges represent dependencies
- Ensures topological ordering: tasks cannot start until upstream tasks complete
- Enables parallel execution of independent tasks
- Example: `Download Data → Preprocess → Train Model → Evaluate → Deploy` (sequential DAG)
- vs. `Data A → Preprocess A → Merge → Train` and `Data B → Preprocess B → Merge` (parallel DAG)

**Model Artifact**
- Serialized model binary (weights, biases, computational graph) output from training
- Includes metadata: framework version, input/output schemas, performance metrics
- Version-controlled in artifact registries with semantic versioning
- Different from model code (which trains the model)

**Inference Endpoint/Serving**
- A network-accessible interface (REST API, gRPC, etc.) that accepts inputs and returns model predictions
- Abstracts away model details from consumers
- Typically scaled independently from training infrastructure

**Feature Store**
- Centralized repository for processed, reusable features used across multiple ML models
- Enables consistent feature values between training (offline) and inference (online)
- Addresses training-serving skew by providing same feature calculation paths
- Examples: Tecton, Feast, Databricks Feature Store

**Model Registry**
- Version control system for trained models
- Stores model artifacts, metadata, lineage, performance metrics
- Enables rollback, comparison, and audit trails
- Examples: MLflow Model Registry, Kubernetes model CRDs

**Training-Serving Skew**
- Discrepancy between features/logic used during model training vs. production inference
- Common causes: different preprocessing code, stale feature versions, inconsistent dependencies
- Leads to model performance degradation in production

**Data Drift**
- Statistical changes in input data distribution compared to training data
- Causes model predictions to become unreliable over time
- Detected through monitoring input feature distributions

**Model Drift (Concept Drift)**
- Changes in the relationship between input features and target variable
- Even with identical input distributions, model predictions degrade
- Requires automated retraining pipelines to detect and remediate

**Reproducibility**
- Ability to retrain a model and obtain identical results given same code, data, and hyperparameters
- Critical requirement for regulatory compliance and debugging
- Requires versioning: data versions, code versions, dependency versions, random seeds

**Canary Deployment**
- Gradually routing traffic to new model version while monitoring performance
- Start with 5-10% traffic to new model, watch metrics, incrementally increase
- Enables safe validation before full cutover
- Quick rollback if degradation detected

**A/B Testing**
- Simultaneous serving of two model versions to different user cohorts
- Requires metrics collection infrastructure to compare model performance
- Statistical rigor needed to detect meaningful differences

**Async Inference (Request-Reply Queue)**
- Model predictions submitted to queue, returned asynchronously
- Decouples computation from request latency
- Suitable for batch scenarios, non-real-time applications
- Reduces resource utilization compared to always-hot endpoints

**GPU Scheduling**
- Kubernetes extension to allocate NVIDIA/AMD GPUs to specific pods
- Requires: driver installation, GPU device plugin, resource requests/limits
- Bin packing algorithms distribute GPUs across nodes efficiently

**Taints and Tolerations**
- Kubernetes mechanism to reserve nodes for specific workload types
- Taint: marker on node (e.g., "GPU-required")
- Toleration: pod annotation allowing it to be scheduled on tainted nodes
- Typically: GPU nodes tainted, training/inference pods tolerate GPU taint

### Architecture Fundamentals

**Separation of Concerns in MLOps**

```
┌──────────────────────────────────────────────────────────┐
│                  Control Plane (Orchestration)           │
│  - Defines workflows (DAGs)                              │
│  - Manages scheduling and retry logic                    │
│  - Coordinates with external systems                     │
│  - Stores execution history and metadata                 │
└──────────────────────────────────────────────────────────┘
               │                  
               ▼                  
┌──────────────────────────────────────────────────────────┐
│              Data Plane (Execution)                      │
│  - Training workers (GPUs, CPUs)                         │
│  - Preprocessing engines                                │
│  - Model serving runtimes                               │
│  - Database/cache layers                                │
└──────────────────────────────────────────────────────────┘
               │                  
               ▼                  
┌──────────────────────────────────────────────────────────┐
│         Observability & Management Plane                 │
│  - Metrics collection (predictions, latency)             │
│  - Model performance tracking                            │
│  - Alerting and notifications                            │
│  - Compliance logging                                    │
└──────────────────────────────────────────────────────────┘
```

**Model Lifecycle States**

```
Development → Staging → Production → Monitoring → Retirement
    ↓                                                ↓
  Experiment                                   Replace with v2
  Training iterations
  Local testing
```

Each state requires different infrastructure:
- **Development**: Ad-hoc notebooks, single machine
- **Staging**: Containerized training, quota-limited infrastructure
- **Production**: Kubernetes-managed, auto-scaled, monitored inference
- **Monitoring**: Continuous metric collection with alerting
- **Retirement**: Model decommissioning, traffic migration to replacement

**Workload Characteristics in ML**

| Characteristic | Training | Batch Inference | Online Inference |
|---|---|---|---|
| Latency (p99) | Hours-days | Minutes-hours | 50-500ms |
| Throughput | Varies | High (async) | High (sync) |
| Resource Req. | High-variance (GPU spikes) | Medium (sustained) | Low-medium (responsive) |
| Scaling Pattern | Horizontal (multi-node training) | Horizontal (more instances) | Horizontal & vertical |
| Failure Tolerance | Low (checkpointing) | High (idempotent) | High (request retry) |
| Cost Optimization | Spot instances, preemption | Batch scheduling | Reserved capacity + autoscaling |

### Important DevOps Principles

**Infrastructure as Code for ML**

All ML infrastructure components must be code-versioned and reproducible:

```
├── orchestration/
│   ├── airflow_dags/
│   │   └── model_training_dag.py (git versioned)
│   └── manifests/
│       └── airflow_deployment.yaml (git versioned)
├── models/
│   ├── model_v1.pkl (artifact registry, not git)
│   └── config.yaml (git versioned)
├── kubernetes/
│   ├── gpu_node_pool.yaml (git versioned)
│   ├── kserve_model.yaml (git versioned)
│   └── monitoring/
│       └── prometheus_rules.yaml (git versioned)
└── tests/
    ├── model_validation_tests.py
    └── performance_benchmarks.py
```

**Immutable Infrastructure for Models**

- Model serving pods must not be modified post-deployment
- Configuration changes require new deployment generation
- Version all: code, dependencies, data preprocessors, model artifacts
- Enable instant rollback without downtime

**Observability First**

ML systems fail silently. Implement before they fail:

- **Prediction metrics**: Latency p50/p95/p99, throughput, error rates
- **Model metrics**: Prediction distributions, feature distributions
- **Data metrics**: Input data drift, missing feature rates, data lineage
- **Business metrics**: Model-driven KPIs, conversion impact, decision usage
- **Infrastructure metrics**: GPU utilization, memory pressure, node health

**GitOps for Model Deployments**

All model deployments triggered through git commits:

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: churn-prediction-v2
spec:
  predictor:
    model:
      modelFormat:
        name: tensorflow
      storageUri: s3://models/churn-v2/
      # Version pinned in git, deployed via CI/CD
```

Commit to git → Pipeline validates → Auto-deploy to cluster

**Fail Fast, Measure Everything**

- Automated validation of model artifacts before deployment
- Unit tests for preprocessing logic (feature consistency checks)
- Integration tests for end-to-end pipelines
- Canary deployments to measure real-world impact

### Best Practices

**ML Pipeline Design**

1. **Idempotency**: Running pipeline twice with same inputs produces identical outputs
   - Critical for retries and restarts
   - Partition data by time to avoid reprocessing
   - Use deterministic logic, no random sampling

2. **State Management**: Keep intermediate results for debugging and replay
   - Store preprocessing outputs
   - Version training data snapshots
   - Enable pipeline step restart without full re-execution

3. **Error Handling**: Orchestration systems must handle failures gracefully
   - Exponential backoff for transient failures
   - Dead-letter queues for impossible failures
   - Clear error messages in logs for troubleshooting

4. **Dependency Resolution**: Explicit DAG definition prevents hidden dependencies
   - Avoid hardcoded paths; use parameterized configs
   - Version all external data sources
   - Document assumptions about input schemas

**Model Registry Standards**

- Semantic versioning: MAJOR.MINOR.PATCH (1.2.3)
- Metadata requirements: training date, framework version, training data version, performance metrics
- Staging zones: model review approved before production promotion
- Rollback capability: maintain N previous versions for quick reversion

**Serving Architecture Patterns**

- **Stateless inference**: Each pod identical, can be killed/recreated
- **Health checks**: Readiness & liveness probes at model level
- **Circuit breakers**: Fail fast if downstream model/feature dependencies unavailable
- **Request validation**: Schema validation before model receives predictions (prevent undefined behavior)

**Resource Quotas**

```yaml
# Prevent one model from consuming entire cluster
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
    nvidia.com/gpu: "1"
  limits:
    memory: "4Gi"
    cpu: "2000m"
    nvidia.com/gpu: "1"
```

### Common Misunderstandings

**Misunderstanding #1: "ML Models are Just Applications"**

Reality: ML systems differ fundamentally:
- Applications are deterministic; models are probabilistic
- Application bugs are reproducible; model failures are statistical
- Application scaling is predictable; ML workload patterns vary by season/cohort
- Requires specialized monitoring, different SLAs

**Misunderstanding #2: "Workflow Orchestration and Kubernetes are Interchangeable"**

Reality: They solve different problems:
- Orchestrators (Airflow, Kubeflow) manage *what runs, when, and how often* (scheduling business logic)
- Kubernetes manages *where and how* workloads run (infrastructure abstraction)
- Both necessary: Airflow schedules training → Kubernetes executes training → Airflow monitors completion

**Misunderstanding #3: "A Model Trained is a Model Ready to Serve"**

Reality: Production model serving requires additional layers:
- Preprocessing consistency: training preprocessing must be replicated in serving path
- Feature versioning: same feature code must output same values at inference time
- Batch optimization: model may need inference optimization (quantization, compilation) for latency
- Canary validation: performance on new model must be proven before cutover

**Misunderstanding #4: "GPU Scheduling is Just 'Get GPUs from Cloud Provider'"**

Reality: GPU management with Kubernetes requires:
- GPU device plugin installation and configuration
- Driver version compatibility with application frameworks
- Bin packing algorithms (not all GPUs are identical)
- Cost optimization (spot instances terminate unexpectedly)
- Shared GPU allocation (multiple models on one GPU requires careful tuning)

**Misunderstanding #5: "Real-Time Inference Requires Online Streaming"**

Reality: Inference latency vs. freshness tradeoffs:
- Real-time (p99 < 100ms): Must use precomputed features, cached models, minimize I/O
- Near real-time (p99 < 5s): Can call feature store, allows feature freshness
- Batch (hours): Maximum optimization, lowest cost, highest staleness
- Choose based on business requirements, not default to hardest option

**Misunderstanding #6: "More Monitoring is Always Better"**

Reality: Monitoring overhead has costs:
- Every metric collected impacts storage/compute
- Alert fatigue reduces effectiveness (too many alerts → ignored alerts)
- Focus on metrics that predict failures or impact business
- Implement progressive monitoring: critical metrics at high frequency, diagnostic metrics at low frequency

---

## Next Sections (Coming)

This study guide continues with deep-dive sections on:
- **ML Workflow Orchestration** - Tool comparison, DAG patterns, scheduling strategies
- **Model Serving Architectures** - REST, gRPC, serverless patterns, performance optimization
- **Model Serving Frameworks** - TensorFlow Serving, BentoML, KServe, Seldon Core, Triton
- **Kubernetes for MLOps** - GPU scheduling, resource management, ML-specific CRDs
- **Hands-on Scenarios** - Multi-model serving, canary deployments, drift detection
- **Interview Questions** - Architecture design, troubleshooting, production scenarios

---

**Document Version:** 1.0  
**Last Updated:** April 2026  
**Audience:** Senior DevOps Engineers (5–10+ years)  
**Study Time:** 4–6 weeks recommended for comprehensive mastery
