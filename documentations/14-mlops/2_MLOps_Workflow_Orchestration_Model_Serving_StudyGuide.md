# MLOps: ML Workflow Orchestration, Model Serving Architectures, and Production ML Systems
## Senior DevOps Engineer Study Guide

---

## Table of Contents

### Foundational Context
- [Introduction](#introduction)
  - [Overview of MLOps](#overview-of-mlops)
  - [Why MLOps Matters in Modern DevOps Platforms](#why-mlops-matters)
  - [Real-World Production Use Cases](#real-world-production-use-cases)
  - [MLOps in Cloud Architecture](#mlops-in-cloud-architecture)

- [Foundational Concepts](#foundational-concepts)
  - [Key Terminology](#key-terminology)
  - [ML Workflow Architecture Fundamentals](#ml-workflow-architecture-fundamentals)
  - [DevOps Principles Applied to ML](#devops-principles-applied-to-ml)
  - [Key Architectural Patterns](#key-architectural-patterns)
  - [Best Practices](#best-practices)
  - [Common Misunderstandings](#common-misunderstandings)

### Core Subtopics

1. **[ML Workflow Orchestration](#ml-workflow-orchestration)**
   - Workflow Orchestration Concepts & Principles
   - Orchestration Tools: Kubeflow, Airflow, Argo Workflows
   - DAG Design & Pipeline Patterns
   - Workflow Scheduling & Dependency Management
   - Conditional Workflows & Error Handling
   - Workflow Monitoring & Observability
   - Best Practices & Real-world Examples

2. **[Model Serving Architectures](#model-serving-architectures)**
   - Model Serving Concepts & Patterns
   - Batch vs Real-time vs Streaming Inference
   - REST vs gRPC Inference
   - Inference Pipeline Patterns
   - Model Deployment Strategies
   - Scaling Considerations
   - Best Practices & Real-world Examples

3. **[Model Serving Frameworks](#model-serving-frameworks)**
   - TensorFlow Serving Architecture & Design
   - TorchServe Architecture & Design
   - Custom Serving Solutions
   - Framework Comparison & Selection Criteria
   - Deployment Considerations
   - Best Practices & Real-world Examples

4. **[Kubernetes for MLOps](#kubernetes-for-mlops)**
   - Kubernetes ML Concepts & Adaptations
   - ML Operators: Kubeflow, KServe, Seldon Core
   - BentoML & TorchServe on Kubernetes
   - GPU Scheduling & Resource Management
   - Triton Inference Server Fundamentals
   - Best Practices & Real-world Examples

5. **[Feature Stores](#feature-stores)**
   - Feature Store Concepts & Architecture
   - Online vs Offline Feature Serving
   - Open-source Solutions: Feast, Hopsworks
   - Feature Consistency & Governance
   - Feature Store Patterns
   - Best Practices & Real-world Examples

6. **[Monitoring ML Scripts](#monitoring-ml-scripts)**
   - ML-Specific Monitoring Concepts
   - Metrics for ML Workloads
   - Data Drift Detection
   - Model Performance Monitoring
   - Bias Detection & Feedback Loops
   - Monitoring Tools: Prometheus, Grafana
   - Alerting Strategies
   - Best Practices & Real-world Examples

7. **[Observability for ML Services](#observability-for-ml-services)**
   - Observability vs Monitoring for ML
   - Distributed Tracing for ML Pipelines
   - Structured Logging Strategies
   - OpenTelemetry & Instrumentation
   - Inference Latency Analysis
   - Observability Tools & Stack
   - Best Practices & Real-world Examples

8. **[Data & Model Validation](#data--model-validation)**
   - Validation Concepts
   - Schema Enforcement & Management
   - Data Validation Tools: Great Expectations, TFDV
   - Input Validation Pipelines
   - Model Validation Strategies
   - Validation in CI/CD Workflows
   - Best Practices & Real-world Examples

### Advanced Topics
- [Hands-on Scenarios](#hands-on-scenarios)
- [Interview Questions](#interview-questions)
- [References & Further Reading](#references--further-reading)

---

## Introduction

### Overview of MLOps

MLOps (Machine Learning Operations) extends DevOps principles and practices to the unique challenges of deploying, managing, and maintaining machine learning systems in production. Unlike traditional software systems where code and dependencies are relatively static, ML systems introduce data dependencies, model sensitivity to input distributions, and continuous retraining requirements that require specialized operational approaches.

**MLOps encompasses:**
- **ML Workflow Orchestration**: Coordinating complex, multi-stage ML pipelines from data ingestion through model training and deployment
- **Model Serving**: Deploying trained models to production for real-time or batch inference at scale
- **Feature Engineering & Serving**: Managing features consistently across training and serving environments
- **Monitoring & Observability**: Detecting data drift, model degradation, and production anomalies
- **Validation & Quality**: Ensuring data and model quality throughout the ML lifecycle
- **Infrastructure**: Providing compute, storage, and networking resources optimized for ML workloads

For senior DevOps engineers, MLOps represents an evolution of familiar concepts—CI/CD pipelines, infrastructure management, observability—applied to systems with unique characteristics requiring custom solutions.

### Why MLOps Matters in Modern DevOps Platforms

**Model Complexity at Scale**: Organizations deploy hundreds of models across multiple business units. Without systematic MLOps practices, managing model versions, dependencies, and lifecycle changes becomes chaotic and error-prone.

**Data-Driven Criticality**: ML model performance is entirely dependent on data quality and distribution. Traditional deployment monitoring (CPU, memory, latency) are insufficient; you must monitor data characteristics and model behavior continuously.

**Regulatory & Compliance Requirements**: Financial institutions, healthcare systems, and government agencies require explainability, auditability, and fairness tracking built into ML production systems. MLOps provides the infrastructure for governance.

**Rapid Iteration Requirements**: Competitive pressure demands faster model iteration and deployment cycles. MLOps automation enables teams to run continuous retraining and shadow testing safely.

**Cost Management**: ML infrastructure is capital-intensive. Unmanaged model serving costs, inefficient GPU utilization, or repeated data processing wastes significant resources. MLOps optimizes infrastructure utilization.

**Cross-functional Complexity**: ML projects involve data engineers, ML engineers, and DevOps teams. MLOps standardizes interfaces and reduces friction in handoffs between specializations.

### Real-World Production Use Cases

**E-commerce Recommendation Systems**: Netflix, Amazon, and Alibaba deploy thousands of recommendation models serving real-time requests. Each model requires:
- Feature engineering pipelines (executed daily or hourly)
- A/B testing infrastructure for shadow models
- Real-time serving at millisecond latencies
- Continuous monitoring for recommendation quality degradation
- Fast rollback mechanisms when models perform poorly

Without MLOps infrastructure, even a 1% performance degradation in recommendations costs millions in lost revenue.

**Financial Risk Models**: Banks run credit scoring, fraud detection, and market risk models. Requirements include:
- Strict audit trails of every prediction and its inputs
- Periodic retraining as market conditions change
- Fairness monitoring (models cannot discriminate by protected attributes)
- High availability (99.99%+)
- Explainability for every prediction (regulatory requirement)

**Autonomous Vehicle Systems**: Self-driving car companies deploy perception models (object detection, lane segmentation, depth estimation) that:
- Must operate on edge devices with latency <100ms
- Require continuous data collection and retraining from fleet operations
- Need safety validation pipelines before any update
- Must track model provenance (which training data, which Git commit, etc.)

**Medical Imaging**: Hospital systems deploy diagnostic models requiring:
- Careful version tracking and validation
- Integration with existing HIPAA-compliant infrastructure
- Continuous monitoring for drift from the training distribution
- Rapid rollback capabilities when performance diverges

### MLOps in Cloud Architecture

MLOps integrates into cloud platforms at multiple layers:

**Infrastructure Layer**: GPU resource pools, auto-scaling groups, container registries, artifact storage

**Data Layer**: Data lakes (S3, ADLS, GCS), data warehouses (Snowflake, BigQuery), feature stores (Feast), data catalogs

**Orchestration Layer**: Kubernetes (Kubeflow), workflow engines (Airflow, Argo, Prefect), job schedulers

**Serving Layer**: Model serving frameworks (TensorFlow Serving, TorchServe), inference servers (Triton), API gateways

**Monitoring & Governance Layer**: Observability platforms (Prometheus, ELK), feature drift detection, model registry, audit systems

**CI/CD & Automation**: Pipeline definitions (Argo CD, Jenkins), GitOps workflows, automated retraining triggers

In a typical enterprise cloud architecture:
- Data engineers build data pipelines using orchestration tools
- ML engineers develop models with experiment tracking (MLflow, W&B)
- DevOps engineers provision infrastructure and ensure reliability
- ML engineers containerize models and push to registries
- MLOps orchestration triggers retraining weekly/daily
- New models are shadow-tested against production traffic
- Validated models are promoted through environments to production
- Serving infrastructure auto-scales based on request volume
- Monitoring systems detect drift and quality degradation
- Automated alerts trigger model retraining or rollbacks

Cloud providers (AWS SageMaker, GCP Vertex AI, Azure ML) provide opinionated MLOps stacks, but sophisticated organizations often use open-source alternatives (Kubeflow, Airflow, KServe) for flexibility and vendor independence.

---

## Foundational Concepts

### Key Terminology

**Model**: A learned statistical or deep learning artifact that transforms inputs to predictions. Models have versions tracked through lifecycle (development → staging → production).

**Feature**: An input variable to a model. Features are engineered from raw data and must be available consistently during both training and inference.

**Feature Engineering**: The process of transforming raw data into features suitable for model training. Often the most time-consuming and impactful ML task.

**Feature Store**: A centralized system managing feature definitions, computation, and serving. Ensures consistency between training and inference feature calculations.

**Training Pipeline**: End-to-end workflow: data ingestion → preprocessing → feature engineering → model training → validation → model artifact generation.

**Inference Pipeline**: Sistema accepting new data and producing predictions using a trained model. Can be batch (process many samples periodically) or online (serve individual predictions in real-time).

**Model Registry**: Version control system for trained models, storing model artifacts, metadata, lineage, and promotion status (dev → staging → prod).

**Orchestration**: Coordinating multi-step workflows with dependency management, scheduling, and error handling (Airflow DAGs, Kubeflow Pipelines, Argo Workflows).

**Observability**: Comprehensive monitoring combining metrics, logs, and traces to understand system behavior. Goes beyond traditional monitoring by enabling investigation of novel failure modes.

**Data Drift**: Change in input data distribution over time (e.g., customer demographics shift, seasonal patterns, data collection changes). Causes model performance degradation.

**Model Drift**: Degradation in model performance despite stable data, often due to concept drift (relationships between features and targets change).

**Prediction Drift**: Statistical divergence between predictions on current data vs. historical predictions. Indicator of upstream data drift.

**Shadow Testing**: Running a new model in parallel with production without affecting user-facing results. Enables safe validation before promotion.

**Canary Deployment**: Gradually routing traffic percentage to new models, monitoring metrics carefully before full promotion.

**Model Explainability**: Techniques for understanding why a model made a specific prediction (SHAP values, LIME, attention maps).

**Feature Consistency**: Ensuring features calculated during training are identically calculated during inference. Prevents the training-serving skew problem.

### ML Workflow Architecture Fundamentals

**Traditional ML Project Flow (Training-Centric)**:
```
Raw Data → Exploration → Feature Engineering → Model Selection → Train/Validate 
  → Hyperparameter Tuning → Test → [End]
```

Issues: This is research-focused, not operations-focused. Production reality is dramatically different.

**Production ML System Architecture (MLOps-Centric)**:
```
Data Sources → Data Validation → Feature Engineering → Feature Store (Online) 
  → Model Serving (Inference) → Predictions

Parallel Flows:
- Training Flow: Feature Store (Offline) → Model Training → Validation → Model Registry
- Monitoring Flow: Predictions + Actuals → Metrics → Drift Detection → Alerts
- Retraining Trigger: Drift/Quality Signals → Scheduled or Event-driven Retraining
```

**Key Differences from traditional software**:

| Aspect | Traditional Software | ML Systems |
|--------|---------------------|-----------|
| Code Changes | Explicit, version-controlled | Models change without code changes |
| Dependencies | Code and libraries | Data, features, and model versions |
| Testing | Unit/integration tests determine correctness | Model performance on holdout data is ground truth |
| Monitoring | System metrics (CPU, latency, errors) | Data distribution, prediction quality, feature drift |
| Rollback | Revert code | Revert model or retrain immediately |
| Validation | Compile-time, test-time | Continuous production quality monitoring |
| Lifecycle | Single "production" version | Multiple model versions, shadow testing, canary rollout |

### DevOps Principles Applied to ML

**Automation**
- Automated retraining pipelines triggered by data drift or schedule
- Automated feature computation and serving
- Automated model validation and promotion through environments
- Automated infrastructure provisioning for compute jobs

**Version Control & Reproducibility**
- All code (training scripts, feature definitions) in Git
- Model artifacts versioned with metadata (training date, data version, hyperparameters)
- Feature definitions versioned (feature 'user_engagement_v2' for new definition)
- Ability to reproduce exact model given Git commit hash and data timestamp

**Infrastructure as Code**
- Model serving deployments defined as Kubernetes manifests
- Data pipelines defined as Infrastructure-as-Code (Terraform, Bicep)
- Workflow definitions version-controlled (Airflow DAGs, Kustomize manifests)

**Infrastructure Provisioning & Management**
- Ephemeral training cluster spin-up/shutdown
- GPU resource management and scheduling
- Autoscaling serving infrastructure based on request volume
- Cost optimization through spot instances, resource quotas

**Continuous Integration/Continuous Deployment**
- Model training triggered on code changes
- Automated validation pipeline before production promotion
- Gradual rollout (canary) with automatic rollback on quality degradation
- Feature flags enabling model experiments without code deployment

**Observability & Monitoring**
- Metrics on data characteristics (distribution analysis, statistical tests)
- Model performance metrics (accuracy, precision, recall, business metrics)
- Feature availability and latency monitoring
- Distributed tracing of predictions through serving pipeline

**Collaboration & Documentation**
- Model card documentation (intended use, training data, limitations, fairness analysis)
- Runbooks for common MLOps incidents (model degradation, data pipeline failure)
- Clear ownership of models and data pipelines
- Cross-team visibility into model promotions and performance

### Key Architectural Patterns

**Batch Processing Pattern**: Models trained periodically (daily/hourly), batch predictions generated for all entities, results stored in database. Used when:
- Predictions don't require sub-second latency
- Entity population is known and relatively static
- Cost-sensitive (batch inference is cheaper than real-time)
- Examples: Email content personalization, fraud scoring overnight

**Online/Real-time Serving Pattern**: Models serve predictions on-demand via API. Used when:
- Sub-second latency required
- Prediction requests are sparse or unpredictable
- Personalization to user context is critical
- Examples: E-commerce recommendations, ride pricing, content ranking

**Hybrid Pattern**: Some features from online feature store, some computed on-demand
- Enables relatively static features (user demographics) from online store
- Recent features (last 7 days activity) computed on serving request
- Reduces feature store operational complexity and latency

**Streaming Pattern**: Continuous model evaluation on streaming data
- Used for anomaly detection, fraud detection on transaction streams
- Models embedded in stream processing system (Kafka Streams, Flink)
- Low-latency decision-making on high-volume data

**Multi-Model Pattern**: Different models for different segments (geographic, customer tier, device type)
- Requires routing infra to select correct model
- Allows optimization per-segment
- More complex governance and monitoring

**Shadow/Canary Pattern**: New models validated against live traffic before production promotion
- Shadow: Captures predictions but doesn't affect users
- Canary: Gradually increase traffic to new model with automatic rollback
- Critical for safe model deployment in high-stakes systems

### Best Practices

**Treat Data as First-Class Artifact**
- Data versioning as important as code versioning
- Data lineage tracking (which models trained on which data, what preprocessing was applied)
- Data quality validation before use
- Reproducibility: exact dataset used for training must be recoverable

**Separate Training and Serving Codepaths**
- Training is experimentation-focused (exploratory, research-like)
- Serving is production-focused (deterministic, auditable, fast)
- Feature calculation code must be identical or carefully synchronized
- Prevents "training-serving skew" where features differ between stages

**Version Everything**
- Model versions: track lineage to training code commit, data version, hyperparameters
- Feature versions: track schema, definitions, computation code
- Data versions: snapshots for reproducibility
- Configuration versions: model hyperparameters, feature engineering parameters

**Test Before Production**
- Unit tests: feature engineering correctness, model output shape/type
- Integration tests: entire pipeline end-to-end
- Shadow testing: new models against live traffic (no user impact)
- Performance testing: latency, throughput under expected load
- Fairness testing: model doesn't discriminate by protected attributes

**Monitor Continuously**
- Data distribution monitoring (statistical tests for drift)
- Model performance monitoring (tracked metrics vs. actuals)
- Prediction quality monitoring (business-relevant metrics)
- Infrastructure monitoring (serving latency, GPU utilization)

**Enable Rapid Rollback**
- Maintain previous model versions readily available
- Automated rollback on quality degradation
- Feature flags enabling instant model switching
- Maintain baseline model always available

**Automate Retraining**
- Scheduled retraining (daily/weekly) for models that degrade predictably
- Triggered retraining on data drift detection thresholds
- Automated promotion through staging environments
- Manual approval gates for high-risk models before production

**Document Model Lifecycle**
- Model cards: intended use, performance on different segments, fairness analysis, known limitations
- Experiment tracking: hyperparameters, metrics for reproducibility
- Incident documentation: when models failed, why, what was done
- Decision logs: why certain models chosen over alternatives

### Common Misunderstandings

**Misunderstanding 1: "Better model accuracy = better ML system"**

Reality: Model accuracy is necessary but insufficient. A 99% accurate model serving with 5-second latency is worse than a 95% accurate model serving in 50ms. Missing predictions due to service unavailability is catastrophic. Systematic bias causing unfair treatment of customers is unacceptable regardless of accuracy.

MLOps requires balancing:
- Prediction quality (accuracy, precision, recall, business metrics)
- Latency (serving response time)
- Availability (SLA uptime)
- Fairness (no discrimination)
- Cost (infrastructure, compute, storage)

**Misunderstanding 2: "The ML model is the whole system"**

Reality: Models are 5% of a production ML system. The remaining 95% includes:
- Data pipelines (ingestion, validation, transformation)
- Feature stores (computation, serving, consistency)
- Infrastructure (compute, storage, networking)
- Serving (APIs, caching, routing, fallbacks)
- Monitoring (drift detection, quality tracking, alerting)
- Governance (versioning, audit trails, approvals)

Treating models as isolated artifacts while neglecting the surrounding system leads to failures in production.

**Misunderstanding 3: "Train once, deploy once"**

Reality: Most production models require continuous retraining. Data distribution changes, user behavior evolves, market conditions shift. A model deployed 6 months ago without retraining is likely performing significantly worse. MLOps infrastructure enables automated, safe retraining.

**Misunderstanding 4: "DevOps practices don't apply to ML"**

Reality: Core DevOps principles (automation, versioning, monitoring, reproducibility, infrastructure-as-code) are *more* critical for ML systems because complexity is higher. ML adds additional concerns (data quality, feature consistency, drift monitoring) on top of standard DevOps practices.

**Misunderstanding 5: "Model serving is just containerization"**

Reality: Containerization is necessary but not sufficient. Model serving requires:
- Feature lookup and computation at serving time
- Model versioning and routing
- Latency optimization (GPU batching, quantization, caching)
- High availability and failover
- Monitoring for prediction quality degradation
- Safe canary deployments and rollbacks

**Misunderstanding 6: "Monitoring ML is just application monitoring"**

Reality: Standard application monitoring (CPU, memory, API latency, error rates) is necessary but insufficient. You must also monitor:
- Input data distribution (statistical drift tests)
- Prediction quality without ground truth (using proxy metrics)
- Feature availability and freshness
- Model-specific metrics (per-segment performance, fairness metrics)
- Relationships between input distribution and prediction quality

**Misunderstanding 7: "MLOps tools (Kubeflow, Airflow, Feature Stores) are optional"**

Reality: These tools provide irreplaceable functionality:
- Orchestration tools enable reproducible, scheduled, multi-step workflows
- Feature stores enforce consistency between training and serving
- Model registries enable version control and governance
- Monitoring/observability platforms detect drift before customer impact

Without these systems, organizations end up with manual, error-prone processes that don't scale.

---

## ML Workflow Orchestration

### Textual Deep Dive

#### Internal Working Mechanism

Workflow orchestration engines coordinate multi-step ML pipelines by managing task dependencies, execution order, scheduling, and error handling. Unlike simple shell scripts, orchestration engines provide:

**Directed Acyclic Graph (DAG) Representation**: Pipelines are defined as DAGs where:
- Nodes = tasks (data ingestion, feature engineering, model training, etc.)
- Edges = dependencies (task A must complete before task B starts)
- No cycles = prevents infinite loops

**Execution Engine**: 
- Monitors task completion and determines which tasks are ready to execute
- Distributes tasks to available workers (local, Kubernetes, cloud VMs)
- Retries failed tasks with exponential backoff
- Handles timeouts and resource constraints

**State Management**:
- Tracks execution history and logs for reproducibility
- Stores task outputs (artifacts) for downstream tasks
- Enables restoration from partial failures without re-executing completed tasks

**Scheduling**:
- Cron-based scheduling (DAG runs daily/hourly/on-demand)
- Event-based triggering (run when data arrives, on model degradation alert)
- Dynamic scheduling based on external conditions

#### Architecture Role

Orchestration engines sit at the core of MLOps infrastructure:

```
Data Sources → [Orchestration Engine] → Model Registry
    ↓              ↓        ↓              ↓
Data Ingestion  Feature    Model        Serving
                Engineering Training    Deployment
```

In production systems, orchestration engines:
- **Automate Workflows**: Reduce manual intervention and operational toil
- **Enable Reproducibility**: DAG definitions and versioned code ensure consistent results
- **Provide Visibility**: Runs, logs, and alerts provide operational observability
- **Scale Operations**: Handle thousands of concurrent pipelines across clusters
- **Enable Governance**: Audit trails, versioning, approval workflows for production DAGs

#### Production Usage Patterns

**Scheduled Retraining Pipeline** (Daily Model Updates)
```
Daily Trigger → Data Validation → Feature Engineering → Model Training 
  → Model Evaluation → Quality Gates (Accuracy Check) → Model Registry (Promote or Fallback)
  → Serving Deployment (Canary → Full)
```

**Triggered Retraining** (Data Drift Detection)
```
Drift Alert → Data Retrieval → Model Retraining 
  → Shadow Testing → Manual Approval → Deployment
```

**Real-time Pipeline Orchestration** (Continuous ML)
```
Event Stream (Kafka) → Feature Computation → Real-time Inference 
  → Prediction Logging → Monitoring & Drift Detection
```

#### DevOps Best Practices

**1. DAG Definition as Code**
- Store all DAG definitions in Git
- Version control orchestration logic just like application code
- Enables code review and audit trails

**2. Resource Management**
- Define CPU/memory/GPU requirements per task
- Use Kubernetes resource quotas and node affinities
- Monitor resource utilization to optimize costs

**3. Error Handling & Retries**
```
- Exponential backoff for transient failures (5s, 10s, 30s, 1m)
- Dead-letter queues for permanent failures
- Automatic rollback on validation failures
- Alert on critical path failures
```

**4. Monitoring & Alerting**
- SLAs per pipeline (max run duration, success rate)
- Alerts on: failed DAGs, slow tasks, data quality degradation
- Long-term metrics: pipeline success rate, avg duration trends

**5. Separation of Concerns**
- Development environments: free-form experimentation
- Staging: full pipeline with sensitive data subset
- Production: locked-down, change-controlled, audit-logged

**6. Dependency Management**
- Pin Docker image versions
- Lock Python package versions in requirements.txt
- Declare external service dependencies explicitly

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| **DAGs with circular dependencies** | Pipeline hangs indefinitely | Validate DAG structure during testing |
| **Hardcoded paths/credentials in DAGs** | Security breach, inflexibility | Use environment variables, config files, Kubernetes secrets |
| **Missing error handling** | Cascading failures without visibility | Implement try/catch, timeout limits, alerting |
| **Resource starvation** | Pipeline queuing, SLA misses | Resource quotas, priority classes, autoscaling |
| **Inadequate logging** | Can't debug failures post-mortem | Structured logging to centralized system (ELK) |
| **No task retry logic** | Transient network failures block pipeline | Implement exponential backoff (e.g., 3 retries) |
| **Mixing experiment & production DAGs** | Production issues from exploratory code | Separate dev/prod with different orchestration clusters |

### Practical Code Examples

#### Airflow DAG (Python)

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from airflow.operators.python import PythonOperator
from airflow.models import Variable

default_args = {
    'owner': 'ml-team',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'timeout': timedelta(hours=4),
    'email_on_failure': True,
    'email': ['ml-alerts@company.com']
}

dag = DAG(
    'daily_recommendation_model_retraining',
    default_args=default_args,
    description='Daily retraining of recommendation models',
    schedule_interval='0 2 * * *',  # 2 AM daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['ml', 'recommendation', 'production']
)

# Task 1: Data Validation
validate_data = KubernetesPodOperator(
    task_id='validate_input_data',
    namespace='ml-pipelines',
    image='company-registry.azurecr.io/data-validation:v1.2.0',
    cmds=['python', 'validate_schema.py'],
    arguments=['--date', '{{ ds }}', '--max-age-days', '7'],
    resources={
        'request': {'cpu': '2', 'memory': '4Gi'},
        'limit': {'cpu': '4', 'memory': '8Gi'}
    },
    retries=2,
    retry_delay=timedelta(minutes=10),
    timeout_seconds=1800,
    dag=dag
)

# Task 2: Feature Engineering
feature_engineering = KubernetesPodOperator(
    task_id='compute_features',
    namespace='ml-pipelines',
    image='company-registry.azurecr.io/feature-engineering:v2.1.0',
    cmds=['python', 'feature_pipeline.py'],
    arguments=['--date', '{{ ds }}', '--output-path', '/data/features/'],
    env_vars={
        'FEATURE_STORE_HOST': Variable.get('feature_store_host'),
        'SPARK_EXECUTOR_MEMORY': '8g',
        'SPARK_EXECUTOR_CORES': '4'
    },
    resources={
        'request': {'cpu': '8', 'memory': '16Gi'},
        'limit': {'cpu': '16', 'memory': '32Gi'}
    },
    dag=dag
)

# Task 3: Model Training
model_training = KubernetesPodOperator(
    task_id='train_model',
    namespace='ml-pipelines',
    image='company-registry.azurecr.io/ml-training:v3.0.0',
    cmds=['python', 'train_pipeline.py'],
    arguments=['--features-path', '/data/features/', '--model-output', '/models/'],
    resources={
        'request': {'cpu': '4', 'memory': '8Gi', 'nvidia.com/gpu': '1'},
        'limit': {'cpu': '8', 'memory': '16Gi', 'nvidia.com/gpu': '1'}
    },
    node_selector={'accelerator': 'nvidia-gpu'},
    tolerations=[
        {'key': 'gpu', 'operator': 'Equal', 'value': 'true', 'effect': 'NoSchedule'}
    ],
    dag=dag
)

# Task 4: Model Validation
model_validation = KubernetesPodOperator(
    task_id='validate_model',
    namespace='ml-pipelines',
    image='company-registry.azurecr.io/model-validation:v1.5.0',
    cmds=['python', 'validate_model.py'],
    arguments=['--model-path', '/models/', '--min-accuracy', '0.92', '--fail-on-low-performance'],
    resources={
        'request': {'cpu': '2', 'memory': '4Gi'},
        'limit': {'cpu': '4', 'memory': '8Gi'}
    },
    dag=dag
)

# Task 5: Register Model (Success)
register_model = KubernetesPodOperator(
    task_id='register_successful_model',
    namespace='ml-pipelines',
    image='company-registry.azurecr.io/mlflow-client:v2.0.0',
    cmds=['python', 'register_to_mlflow.py'],
    arguments=['--model-path', '/models/', '--stage', 'Staging'],
    dag=dag
)

# Task 6: Deploy to Staging (Canary)
deploy_staging = KubernetesPodOperator(
    task_id='deploy_to_staging',
    namespace='ml-serving',
    image='company-registry.azurecr.io/deployment-manager:v1.0.0',
    cmds=['python', 'deploy_model.py'],
    arguments=['--environment', 'staging', '--canary-percentage', '10'],
    resources={
        'request': {'cpu': '1', 'memory': '2Gi'},
        'limit': {'cpu': '2', 'memory': '4Gi'}
    },
    dag=dag
)

# Define dependencies
validate_data >> feature_engineering >> model_training >> model_validation
model_validation >> [register_model, deploy_staging]
```

#### Kubeflow Pipeline (Python)

```python
import kfp
from kfp.v2 import dsl
from kfp.v2.dsl import (
    component,
    Input,
    Output,
    Artifact,
    Model,
    Dataset,
    Metrics
)
from google.cloud.aiplatform.v1.types import PipelineTemplate

@component(
    base_image='python:3.9',
    packages_to_install=['pandas==1.3.0', 'scikit-learn==0.24.2']
)
def preprocess_data(
    input_data_path: str,
    output_dataset: Output[Dataset]
) -> None:
    """Preprocess raw data for model training."""
    import pandas as pd
    from sklearn.preprocessing import StandardScaler
    
    df = pd.read_csv(input_data_path)
    
    # Data cleaning and transformation
    df = df.dropna()
    df = df[df['target'].notna()]
    
    # Feature scaling
    numeric_cols = df.select_dtypes(include=['float64']).columns
    scaler = StandardScaler()
    df[numeric_cols] = scaler.fit_transform(df[numeric_cols])
    
    df.to_csv(output_dataset.path, index=False)

@component(
    base_image='tensorflow:2.9',
    packages_to_install=['mlflow==1.26.0']
)
def train_model(
    training_data_path: str,
    learning_rate: float,
    batch_size: int,
    output_model: Output[Model],
    metrics: Output[Metrics]
) -> None:
    """Train TensorFlow model with MLflow tracking."""
    import tensorflow as tf
    import pandas as pd
    import mlflow
    
    mlflow.set_tracking_uri('http://mlflow-server:5000')
    mlflow.start_run()
    
    # Load and prepare data
    df = pd.read_csv(training_data_path)
    X = df.drop('target', axis=1).values
    y = df['target'].values
    
    # Build and train model
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(128, activation='relu', input_shape=(X.shape[1],)),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss='binary_crossentropy',
        metrics=['accuracy', tf.keras.metrics.AUC()]
    )
    
    history = model.fit(
        X, y,
        epochs=10,
        batch_size=batch_size,
        validation_split=0.2,
        verbose=0
    )
    
    # Log metrics
    mlflow.log_param('learning_rate', learning_rate)
    mlflow.log_param('batch_size', batch_size)
    mlflow.log_metric('final_accuracy', float(history.history['accuracy'][-1]))
    mlflow.log_metric('final_auc', float(history.history['auc'][-1]))
    
    # Save model
    model.save(output_model.path)
    mlflow.end_run()
    
    # Output metrics
    metrics.log_metric('accuracy', float(history.history['accuracy'][-1]))

@component(
    base_image='python:3.9',
    packages_to_install=['tensorflow==2.9', 'scikit-learn==0.24.2']
)
def evaluate_model(
    model_path: str,
    test_data_path: str,
    metrics: Output[Metrics]
) -> str:
    """Evaluate model on test set."""
    import tensorflow as tf
    import pandas as pd
    from sklearn.metrics import accuracy_score, precision_score, recall_score
    
    model = tf.keras.models.load_model(model_path)
    df = pd.read_csv(test_data_path)
    
    X_test = df.drop('target', axis=1).values
    y_test = df['target'].values
    
    y_pred = model.predict(X_test).round()
    
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    
    metrics.log_metric('test_accuracy', accuracy)
    metrics.log_metric('test_precision', precision)
    metrics.log_metric('test_recall', recall)
    
    # Return status
    if accuracy >= 0.92:
        return 'PASSED'
    else:
        return 'FAILED'

@dsl.pipeline(
    name='ml-retraining-pipeline',
    description='Daily ML model retraining pipeline'
)
def ml_pipeline(
    input_data_path: str = 'gs://ml-data/raw/daily_input.csv',
    learning_rate: float = 0.001,
    batch_size: int = 32
):
    """Main pipeline orchestration."""
    
    # Task 1: Preprocess data
    preprocess_task = preprocess_data(input_data_path=input_data_path)
    
    # Task 2: Train model
    train_task = train_model(
        training_data_path=preprocess_task.outputs['output_dataset'].path,
        learning_rate=learning_rate,
        batch_size=batch_size
    )
    
    # Task 3: Evaluate model
    eval_task = evaluate_model(
        model_path=train_task.outputs['output_model'].path,
        test_data_path='gs://ml-data/test/test_set.csv'
    )

# Compile and submit
kfp.compiler.Compiler().compile(ml_pipeline, 'ml-pipeline.yaml')
```

#### Orchestration Configuration (YAML)

```yaml
# airflow-deployment.yaml - Deploy Airflow on Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: airflow-scheduler
  namespace: ml-pipelines
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: airflow-scheduler
  template:
    metadata:
      labels:
        app: airflow-scheduler
    spec:
      serviceAccountName: airflow
      containers:
      - name: scheduler
        image: apache/airflow:2.7.0-python3.9
        command: ["airflow", "scheduler"]
        env:
        - name: AIRFLOW__CORE__EXECUTOR
          value: "KubernetesExecutor"
        - name: AIRFLOW__CORE__SQL_ALCHEMY_CONN
          valueFrom:
            secretKeyRef:
              name: airflow-secrets
              key: database-url
        - name: AIRFLOW__KUBERNETES__NAMESPACE
          value: "ml-pipelines"
        - name: AIRFLOW__KUBERNETES__IMAGE_PULL_POLICY
          value: "IfNotPresent"
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
        volumeMounts:
        - name: dags-volume
          mountPath: /opt/airflow/dags
        livenessProbe:
          exec:
            command:
            - airflow
            - jobs
            - check
            - scheduler
          initialDelaySeconds: 60
          periodSeconds: 30
      
      volumes:
      - name: dags-volume
        configMap:
          name: airflow-dags
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: airflow
  namespace: ml-pipelines
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: airflow-cluster-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create", "get", "list", "watch", "delete"]
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["create", "get", "list", "watch", "delete"]
```

### ASCII Diagrams

#### Airflow DAG Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Airflow Scheduler (Tasks)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
          Schedule Check              Dependency Check
               │                        │
               ├─────────────┬──────────┤
               │             │          │
          6:00 AM Daily?  Previous   Clear to
          (Cron Match)     Tasks OK?  Execute?
               │             │        │
               └─────────────┴────────┘
                        │
                       YES
                        │
        ┌───────────────┴───────────────┐
        │  Mark Tasks Ready for Queue   │
        └───────────────┬───────────────┘
                        │
        ┌───────────────┴───────────────┐
        │        Task Executor Pool      │
        │  (Worker Slots: 4 available)  │
        └─────────────────────────────────┘
                        │
        ┌───────────────┴───────────────────────┐
        │                                       │
   [Data Val]  [Feature Eng]  [Training]  [Eval]
   Pod Running  Pod Running    Pod Running  Pod Running
        │             │            │          │
        │(3s)         │(120s)      │(600s)    │(15s)
        │             │            │          │
   Success ────────►Ready    Success────►Success
                     │
                [Register Model]
                  Pod Queue
                     │
                  Wait...
                     │
                 Pod Running
                     │
                  Success
                     │
            ┌────────┴────────┐
            │                 │
        [Update DAG State] [Metrics Export]
       FINISHED - SUCCESS   PROMETHEUS
```

#### Multi-Stage Pipeline Architecture

```
                    Orchestration Cluster (Airflow)
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
    [Data Ingestion]   [Feature Engineering]  [Model Training]
    Compute Cluster    Compute Cluster         GPU Cluster
    2 CPU, 4GB RAM     8 CPU, 16GB RAM         8 CPU, 32GB RAM
                                               1 A100 GPU
        │                     │                     │
        │(logs & metrics)     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
            [Model Evaluation]   [Model Registry]
            Inference Cluster    (MLflow)
            4 CPU, 8GB RAM
                    │
                    │(if accuracy >= threshold)
                    │
            ┌───────┴───────┐
            │               │
       SUCCESS         FAILURE
            │               │
    [Deploy Canary]   [Rollback Alert]
    K8s Cluster       → PagerDuty
            │
         (10% traffic)
            │
        Monitor (1 hour)
            │
    ┌───────┴───────┐
    │               │
  OK        Issues Found
    │               │
Promote       Rollback
100%            │
            Previous Model
```

---

## Model Serving Architectures

### Textual Deep Dive

#### Internal Working Mechanism

Model serving architectures manage the execution of trained models on new data in production environments. Unlike training (batch, experimental, high-latency acceptable), serving requires:

**Request Handling Pipeline**:
```
Incoming Request
    ↓
Input Parsing & Validation
    ↓
Feature Lookup/Computation
    ↓
Feature Normalization (same as training)
    ↓
Model Inference
    ↓
Post-processing (apply business logic)
    ↓
Response Formatting
    ↓
Client Response
```

**Core Serving Patterns**:

| Pattern | Latency | Throughput | Use Case | Complexity |
|---------|---------|-----------|----------|-----------|
| **Batch** | Hours | Very High | Periodic scoring | Low |
| **Real-time Online** | <100ms | Medium | Per-request predictions | Medium |
| **Streaming** | <10ms | Very High | Event streams | High |
| **Async Queues** | Variable | High | Background jobs | Medium |
| **Edge Inference** | <5ms | Device-dependent | Mobile/IoT | High |

#### Architecture Role

Model serving sits at the intersection of:
- **ML Systems**: Models, features, model versions
- **Infrastructure**: Compute, networking, storage
- **DevOps**: Availability, scalability, monitoring

In production:
```
Clients
  │ (HTTP/REST, gRPC, WebSocket)
  │
┌─┴─────────────────────────────┐
│  Load Balancer / API Gateway  │
│  (Route, auth, rate limit)    │
└─┬─────────────────────────────┘
  │
┌─┴──────────────────────────────────────┐
│     Serving Framework Layer            │
│ ┌──────────────────────────────────┐   │
│ │  Model Server Instance 1 (GPU)   │   │
│ │  - Multiple model versions       │   │
│ │  - Feature fetching              │   │
│ │  - Inference execution           │   │
│ └──────────────────────────────────┘   │
│ ┌──────────────────────────────────┐   │
│ │  Model Server Instance 2 (GPU)   │   │
│ └──────────────────────────────────┘   │
│ ┌──────────────────────────────────┐   │
│ │  Model Server Instance 3 (CPU)   │   │
│ └──────────────────────────────────┘   │
└─┬──────────────────────────────────────┘
  │
┌─┴─────────────────────────────┐
│  Feature Store / Cache       │
│  (Online, low-latency lookup)│
└─────────────────────────────┘
```

#### Production Usage Patterns

**1. Real-time Online Prediction (E-commerce Recommendation)**
```
Client Request (customer_id, session_id)
    ↓
Feature Lookup (Redis/Feature Store)
- User demographics: 1ms
- Historical behavior: 2ms
- Current session features: <1ms
    ↓
Batch Size = 1, Inference
- GPU execution: 5ms
    ↓
Post-process Results (Top 5 items, rank by score)
    ↓
HTTP Response (7 items, 8ms total latency)
```

**2. Batch Scoring (Overnight Model Runs)**
```
Daily Trigger
    ↓
Load All Entities (customers, products, etc.)
    ↓
Feature Computation (daily)
    ↓
Batch Inference (GPU batches of 1000)
- Inference: 100ms for 1000 samples = 100μs per sample
    ↓
Store Results (Database, Data Lake)
    ↓
Monitoring Dashboard shows coverage
```

**3. Streaming Inference (Fraud Detection)**
```
Event Stream (Kafka Topic: transactions)
    ↓
Event Deserialization + Feature Extraction
    ↓
Stream Processing System (Kafka Streams / Flink)
    ↓
Fetch Additional Features from Store
    ↓
Model Inference (async per event)
    ↓
Output Actions:
- If fraud_score > 0.95: Block transaction
- If fraud_score > 0.7: Request additional verification
- Else: Approve
    ↓
Write Decision to Event Stream
```

**4. Async Queue Pattern (Heavy Computations)**
```
Client Request
    ↓
Generate Job ID, return to client
    ↓
Place inference task on queue (RabbitMQ, SQS)
    ↓
Worker Pool processes queue
    ↓
Store results (S3, cache, database)
    ↓
Client polls for status / webhook callback
```

#### DevOps Best Practices

**1. Multiple Serving Technologies**
- Real-time: REST APIs exposed through container orchestration
- Batch: Kubernetes Job resources, scheduled via cron
- Streaming: Producers/consumers in stream processing platform
- Edge: Model export to mobile/IoT formats (ONNX, TFLite)

**2. Model Version Management**
- Route to different model versions (A/B testing, canary rollout)
- Version registry with metadata (training date, accuracy, status)
- Atomic model switch: no in-flight requests affected

**3. Feature Consistency**
- Feature definitions versioned alongside models
- Online feature store pre-computes and caches features
- Identical feature computation code for training & serving

**4. Performance Optimization**
- Model quantization (FP32 → FP16/INT8): 2-4x latency reduction
- Batching: process multiple requests → vectorization
- GPU sharing: multiplex multiple models on single GPU
- Caching: cache predictions for identical requests

**5. Observability & Monitoring**
- Latency percentiles (p50, p95, p99)
- Throughput (requests/sec, inference/sec)
- Model-specific metrics (accuracy per segment, fairness)
- Resource utilization (GPU memory, CPU, network)

**6. Failover & Resilience**
- Multiple replicas across availability zones
- Health checks: serve requests only to healthy replicas
- Circuit breakers: fallback to previous model version if new one fails
- Graceful degradation: reduce model precision if GPU fails

#### Common Pitfalls

| Pitfall | Consequence | Prevention |
|---------|------------|-----------|
| **Different feature logic in training vs serving** | Training-serving skew, accuracy degrades | Use feature store with unified definitions |
| **No version routing** | Can't roll back bad models | Implement canary deployments |
| **Synchronous inference on large batches** | Request timeout, poor user experience | Use batch serving or async queues |
| **No replica redundancy** | Single server failure = outage | Deploy ≥2 replicas per zone |
| **Hardcoded model paths** | Can't update models without code change | Use model versioning API |
| **Bottleneck: serial feature lookup** | P99 latency exceeds SLA | Batch feature lookups, use cache |
| **No rolling updates** | Downtime during model updates | Use gradual traffic shift (canary) |

### Practical Code Examples

#### REST API Serving (FastAPI + Model)

```python
# main.py - FastAPI model serving application
import asyncio
import os
import logging
from typing import List, Dict, Optional
import time

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
import numpy as np
import tensorflow as tf
from pydantic import BaseModel, Field
import redis
import prometheus_client
from prometheus_client import Counter, Histogram
import structlog

# Setup logging
logger = structlog.get_logger()
logging.basicConfig(level=logging.INFO)

# Prometheus metrics
model_inference_duration = Histogram(
    'model_inference_seconds',
    'Time spent in model inference',
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0)
)
model_prediction_counter = Counter(
    'model_predictions_total',
    'Total predictions served'
)
model_errors = Counter(
    'model_errors_total',
    'Total prediction errors'
)

# Initialize app
app = FastAPI(title="model-serving-api", version="1.0.0")

# Load model at startup
MODEL = None
FEATURE_CACHE = None

class PredictionRequest(BaseModel):
    user_id: str
    features: Dict[str, float] = Field(..., description="Feature vector")
    model_version: Optional[str] = Field(default="default", description="Model version to use")

class PredictionResponse(BaseModel):
    prediction: float
    confidence: float
    model_version: str
    latency_ms: float
    timestamp: str

@app.on_event("startup")
async def startup_event():
    """Load model and initialize cache on startup."""
    global MODEL, FEATURE_CACHE
    
    try:
        # Load model from model registry
        model_path = os.getenv("MODEL_PATH", "/models/default")
        MODEL = tf.keras.models.load_model(model_path)
        logger.info("model_loaded", path=model_path)
        
        # Initialize Redis feature cache
        FEATURE_CACHE = redis.Redis(
            host=os.getenv("REDIS_HOST", "localhost"),
            port=int(os.getenv("REDIS_PORT", 6379)),
            db=0,
            decode_responses=True
        )
        
        # Test connection
        FEATURE_CACHE.ping()
        logger.info("feature_cache_connected")
        
    except Exception as e:
        logger.error("startup_error", error=str(e))
        raise

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest) -> PredictionResponse:
    """Make a prediction for a single request."""
    start_time = time.time()
    
    try:
        # Prepare features
        feature_vector = np.array([
            request.features.get(f, 0.0)
            for f in ['feature_1', 'feature_2', 'feature_3']
        ]).reshape(1, -1)
        
        # Run inference
        with model_inference_duration.time():
            prediction = MODEL.predict(feature_vector, verbose=0)[0][0]
        
        latency_ms = (time.time() - start_time) * 1000
        
        # Log prediction
        logger.info(
            "prediction_made",
            user_id=request.user_id,
            prediction=float(prediction),
            latency_ms=latency_ms
        )
        
        # Update metrics
        model_prediction_counter.inc()
        
        return PredictionResponse(
            prediction=float(prediction),
            confidence=float(abs(prediction - 0.5) * 2),  # Simple confidence
            model_version=request.model_version,
            latency_ms=latency_ms,
            timestamp=str(time.time())
        )
        
    except Exception as e:
        logger.error("prediction_error", error=str(e), user_id=request.user_id)
        model_errors.inc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/batch_predict")
async def batch_predict(requests: List[PredictionRequest]) -> Dict:
    """Make predictions for multiple requests in batch."""
    start_time = time.time()
    
    try:
        # Stack all feature vectors
        features = np.array([
            [req.features.get(f, 0.0) for f in ['feature_1', 'feature_2', 'feature_3']]
            for req in requests
        ])
        
        # Batch inference
        with model_inference_duration.time():
            predictions = MODEL.predict(features, verbose=0)
        
        results = []
        for i, req in enumerate(requests):
            results.append({
                "user_id": req.user_id,
                "prediction": float(predictions[i][0]),
                "model_version": req.model_version
            })
        
        latency_ms = (time.time() - start_time) * 1000
        model_prediction_counter.inc(len(requests))
        
        return {
            "predictions": results,
            "batch_size": len(requests),
            "latency_ms": latency_ms
        }
        
    except Exception as e:
        logger.error("batch_prediction_error", error=str(e))
        model_errors.inc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check() -> Dict:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": MODEL is not None,
        "cache_connected": FEATURE_CACHE is not None
    }

@app.get("/metrics")
async def metrics() -> str:
    """Prometheus metrics endpoint."""
    return prometheus_client.generate_latest()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        workers=4,
        log_level="info"
    )
```

#### Kubernetes Deployment for Serving

```yaml
# model-serving-deployment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: model-config
  namespace: ml-serving
data:
  MODEL_PATH: "/models/recommendation-v2"
  REDIS_HOST: "feature-store-redis"
  REDIS_PORT: "6379"
  LOG_LEVEL: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: model-serving-api
  namespace: ml-serving
  labels:
    app: model-serving
    version: v1
spec:
  replicas: 3  # High availability
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: model-serving
  template:
    metadata:
      labels:
        app: model-serving
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      affinity:
        # Spread replicas across availability zones
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - model-serving
              topologyKey: topology.kubernetes.io/zone
        # Prefer GPU nodes for inference
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: accelerator
                operator: In
                values:
                - nvidia-gpu-t4
      
      containers:
      - name: serving-api
        image: company-registry.azurecr.io/model-serving-api:v1.2.0
        imagePullPolicy: Always
        
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        - name: metrics
          containerPort: 8000  # Prometheus metrics on same port
          protocol: TCP
        
        envFrom:
        - configMapRef:
            name: model-config
        
        env:
        - name: DEPLOYMENT_ENV
          value: "production"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://jaeger-collector:4317"
        
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
            nvidia.com/gpu: "1"  # Request 1 GPU
          limits:
            cpu: "4"
            memory: "8Gi"
            nvidia.com/gpu: "1"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        # Graceful shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 30"]  # Allow in-flight requests
        
        # Mount models from persistent storage
        volumeMounts:
        - name: models
          mountPath: /models
          readOnly: true
        - name: cache
          mountPath: /tmp/cache
      
      volumes:
      - name: models
        persistentVolumeClaim:
          claimName: model-storage-pvc
      - name: cache
        emptyDir:
          sizeLimit: 2Gi
      
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000

---
apiVersion: v1
kind: Service
metadata:
  name: model-serving-api
  namespace: ml-serving
  labels:
    app: model-serving
spec:
  type: LoadBalancer
  selector:
    app: model-serving
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 8000
    targetPort: metrics
    protocol: TCP
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 86400

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: model-serving-hpa
  namespace: ml-serving
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: model-serving-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 2
        periodSeconds: 15
      selectPolicy: Max
```

### ASCII Diagrams

#### Real-time Serving Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        Client Applications                          │
│  (Web, Mobile, Backend Services via HTTP REST / gRPC)             │
└─────────────────────────────┬──────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
            ┌───────▼────────┐   ┌───────▼────────┐
            │   Load Balancer │   │  API Gateway   │
            │  (Rate Limit)   │   │  (Auth, Cache) │
            └────────┬────────┘   └────────┬───────┘
                     │                    │
         ┌───────────┴────────────────────┴─────────────┐
         │                                              │
         │    Model Serving Cluster (K8s)              │
         │                                              │
         │  ┌──────────────────────────────────────┐   │
         │  │  Pod 1: Model Server (GPU)           │   │
         │  │  ├─ Load Model v2.1 (TensorFlow)     │   │
         │  │  ├─ Feature Lookup (Redis)           │   │
         │  │  ├─ Batch Size: 16                   │   │
         │  │  └─ Latency: 8ms                     │   │
         │  └──────────────────────────────────────┘   │
         │  ┌──────────────────────────────────────┐   │
         │  │  Pod 2: Model Server (GPU)           │   │
         │  │  ├─ Load Model v2.1 (TensorFlow)     │   │
         │  │  ├─ Feature Lookup (Redis)           │   │
         │  │  ├─ Batch Size: 16                   │   │
         │  │  └─ Latency: 8ms                     │   │
         │  └──────────────────────────────────────┘   │
         │  ┌──────────────────────────────────────┐   │
         │  │  Pod 3: Model Server (GPU)           │   │
         │  │  ├─ Load Model v1.5 (CANARY - 10%)   │   │
         │  │  ├─ Feature Lookup (Redis)           │   │
         │  │  └─ For A/B testing                  │   │
         │  └──────────────────────────────────────┘   │
         │                                              │
         └───────────────────────┬─────────────────────┘
                                 │
                 ┌───────────────┴────────────────┐
                 │                                │
         ┌───────▼────────┐            ┌─────────▼──────┐
         │ Feature Store  │            │   Model        │
         │   (Redis)      │            │  Registry      │
         │                │            │  (MLflow)      │
         │ Cache:         │            │                │
         │ - User embed   │            │ Version: v2.1  │
         │ - Item embed   │            │ Accuracy: 94%  │
         │ - Hot items    │            │ Status:ACTIVE  │
         │                │            │                │
         │ Latency: <2ms  │            └────────────────┘
         └────────────────┘
```

#### Batch Processing Pipeline

```
Daily Trigger (09:00 AM)
        │
        ▼
┌─────────────────────────────┐
│  Load All Entities (1M)     │
│  - Customers from DB        │
│  - Fetch in pages of 10K    │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Feature Computation        │
│  - Join with recent events  │
│  - Aggregate last 30 days   │
│  - Output: 1M × 256 features│
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Batched Inference          │
│  - Process in batches of    │
│    1000                     │
│  - GPU inference: 100ms per │
│    batch                    │
│  - Total: ~1000 batches     │
│  - Time: ~100 seconds GPU   │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Post-processing            │
│  - Apply business rules     │
│  - Filter recommendations   │
│  - Generate ranking         │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Result Storage             │
│  - Write to Data Lake (S3)  │
│  - Update serving cache     │
│  - Update analytics DB      │
└──────────┬──────────────────┘
           │
           ▼
    Pipeline Complete: 09:15 AM
    Ready for 09:16 AM serving
```

---

## Model Serving Frameworks

### Textual Deep Dive

#### Internal Working Mechanism

Model serving frameworks provide standardized APIs, optimized inference execution, and operational features specifically designed for production ML inference. Unlike generic web frameworks, they optimize for model execution characteristics:

**Request Processing Pipeline in Serving Frameworks**:
```
Incoming Request (JSON with features)
    ↓ Input Parser
JSON → Structured Data (validate schema)
    ↓ Batcher
Accumulate requests (wait up to 100ms to batch 32 requests)
    ↓ Feature Processor
Lookup/compute features, normalize to model input format
    ↓ Model Executor
Run inference on batched data (GPU-optimized)
    ↓ Output Formatter
Post-process predictions, format as JSON response
    ↓ Response
Return results with metadata
```

**Key Optimization Techniques**:

1. **Request Batching**: Instead of running one inference per request, accumulate requests into efficient batch sizes
   - Single request: 50ms (GPU startup overhead)
   - Batch of 32: 55ms (5ms per inference)
   - Improvement: 10x latency per sample

2. **Model Optimization**: 
   - Quantization: FP32 → INT8 (4x GPU memory savings, 2x latency improvement)
   - Pruning: Remove unnecessary weights (30-50% model size reduction)
   - Compilation: Framework-specific compilation (TensorRT for NVIDIA)

3. **Multi-model Serving**: Load multiple models into single process/GPU
   - Same GPU serves different models
   - Reduced memory overhead
   - Faster model switches for A/B testing

**Framework Architectures**:

| Framework | Specialization | Batching | Multi-model | Scalability |
|-----------|----------------|----------|------------|-------------|
| **TensorFlow Serving** | TensorFlow models | Native | Yes | High (distributed) |
| **TorchServe** | PyTorch models | Configurable | Yes | High (distributed) |
| **Triton** | Multi-framework | Advanced | Yes | Very High (GPU-efficient) |
| **KServe** | Kubernetes-native | Via framework | Yes | High (K8s orchestration) |
| **BentoML** | Python-agnostic | Declarative | Yes | Medium (simplified) |

#### Architecture Role

Model serving frameworks bridge the gap between:
- **Data Science**: Model development in Python notebooks
- **DevOps**: Reliable, scalable production systems
- **Clients**: HTTP APIs with consistent interfaces

**Typical Architecture**:
```
Model Files (S3, Model Registry)
    ↓
Framework Loader
    ↓
Model Repository
├── Model v1 (active production)
├── Model v2 (canary 10%)
└── Model v3 (shadow testing)
    ↓
Request Router (route to version based on traffic %)
    ↓
Model Server Instance
├── GPU memory allocation per model
└── Worker threads/processes
    ↓
Response
```

#### Production Usage Patterns

**Pattern 1: Large Model Serving (Transformer Models)**
```
Problem: 13B parameter model doesn't fit in single GPU memory
Solution:
  - Intra-op parallelism: Split model across GPUs
  - Tensor parallelism: Split tensor operations
  - Pipeline parallelism: Split model layers across GPUs
  - Result: llama-2-13b served at 50 tokens/sec on 2x A100

Tools: Triton Inference Server, Ray Serve, vLLM
```

**Pattern 2: A/B Testing with Framework**
```
Framework: KServe with Predictor routing
  - 90% traffic: Model v1.5 (stable, 94.2% accuracy)
  - 10% traffic: Model v2.0 (new, 95.1% accuracy)
  - Every prediction tracked with version tag
  - After 1 week: Compare metrics, promote v2.0 if better
  - Framework handles gradual traffic shift automatically
```

**Pattern 3: Multi-task Serving**
```
One framework server instance, multiple models:
  - CTR model (is user interested?)
  - Scoring model (how relevant is item?)
  - Ranking model (what order to show?)
  - Diversity model (vary recommendations)
  
Pipeline:
  1. CTR model filters low-interest items
  2. Scoring model ranks remaining
  3. Diversity model reranks
  4. Return top-5
```

#### DevOps Best Practices

**1. Version Pinning & Reproducibility**
```yaml
# requirements.txt for TensorFlow Serving container
tensorflow==2.9.1
numpy==1.23.0
protobuf==3.20.0
```

**2. Model Loading & Caching**
```
- Load model once on startup
- Cache in shared memory
- Don't reload from disk per request
- Use model versioning API for updates
```

**3. Resource Allocation**
```yaml
TensorFlow Serving pod:
  - Shared GPU: 8GB (supports 2-3 models simultaneously)
  - CPU: sufficient for batching thread pool
  - Memory: model size + buffer for batches
  - Networking: 1Gbps sufficient for most scenarios
```

**4. Health Checks**
```
Liveness: Framework still running
Readiness: Model loaded and accepting requests
Startup: Custom probe for slow model loading
```

**5. Graceful Shutdown**
```
On termination signal:
  1. Accept no new requests (drain load balancer)
  2. Wait for in-flight requests (30-60 second timeout)
  3. Flush metrics/logs
  4. Exit gracefully
```

#### Common Pitfalls

| Pitfall | Issue | Prevention |
|---------|-------|-----------|
| **Model not found** | Framework tries to load model, path missing | Version control model locations, use model registry |
| **Memory leak in batching** | Batch accumulation never flushes | Set both max_batch_size AND timeout (e.g., 100 items or 50ms) |
| **Slow model loading** | Startup > readiness timeout | Pre-warm models, increase startup probe delay |
| **GPU out of memory** | Loading multiple models exhausts GPU | Monitor with `nvidia-smi`, allocate resource limits |
| **No model versioning** | Can't roll back bad model | Use framework versioning API, keep N versions |
| **Synchronous request processing** | High latency for burst traffic | Enable batching in framework config |

### Practical Code Examples

#### TensorFlow Serving Configuration

```protobuf
# saved_model_warmup.pbtxt - Preload model on startup
assets {
  ids: "trigger_opexec"
  filename: "assets/extra/tf_serving_warmup_requests"
}

# model_config.pbtxt
model_config_list {
  config {
    name: 'recommendation_model'
    base_path: '/models/recommendation'
    model_platform: 'tensorflow'
    model_version_policy {
      latest {
        num_versions: 2  # Keep latest 2 versions
      }
    }
    version_labels {
      labels {
        key: 'stable'
        value: 2
      }
      labels {
        key: 'canary'
        value: 3
      }
    }
  }
}
```

```python
# generate_requests.py - Warmup requests for loading
import tensorflow as tf
from tensorflow_serving.apis import predict_pb2
from tensorflow_serving.apis import model_pb2

# Create sample request
request = predict_pb2.PredictRequest()
request.model_spec.name = 'recommendation_model'
request.inputs['input'].dtype = tf.float32.as_datatype_enum
request.inputs['input'].tensor_shape.dim.add().size = 1
request.inputs['input'].tensor_shape.dim.add().size = 256
request.inputs['input'].float_val.extend([0.0] * 256)

# Save for warmup
with open('/models/recommendation/assets/extra/tf_serving_warmup_requests', 'wb') as f:
    f.write(request.SerializeToString())
```

#### TorchServe Handler

```python
# model_handler.py - Custom inference handler for TorchServe
import torch
import torch.nn as nn
from ts.torch_handler.base_handler import BaseHandler
import logging
import numpy as np
from typing import Dict, List, Any

logger = logging.getLogger(__name__)

class ModelHandler(BaseHandler):
    """Custom handler for recommendation model inference."""
    
    def __init__(self):
        super().__init__()
        self.scaler = None
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    def initialize(self, ctx):
        """
        Initialize handler - called once on model load.
        """
        super().initialize(ctx)
        
        # Load model
        self.manifest = ctx.manifest
        properties = ctx.system_properties
        model_dir = properties.get("model_dir")
        
        logger.info(f"Loading model from {model_dir}")
        
        self.model = torch.jit.load(
            f"{model_dir}/model.pt",
            map_location=self.device
        )
        self.model.eval()
        
        # Load preprocessing artifacts
        with open(f"{model_dir}/scaler.npy", 'rb') as f:
            self.scaler = np.load(f, allow_pickle=True).item()
    
    def preprocess(self, data: List[Dict[str, Any]]) -> torch.Tensor:
        """
        Transform input data to model tensor.
        data: List of requests, each with features dict
        """
        features = []
        
        for request in data:
            # Extract features in consistent order
            feature_vector = np.array([
                request.get("feature_1", 0.0),
                request.get("feature_2", 0.0),
                request.get("feature_3", 0.0),
                request.get("feature_4", 0.0),
            ], dtype=np.float32)
            
            # Normalize using training statistics
            feature_vector = (feature_vector - self.scaler['mean']) / self.scaler['std']
            features.append(feature_vector)
        
        # Stack into batch
        features = np.vstack(features)
        return torch.from_numpy(features).to(self.device)
    
    def inference(self, input_batch: torch.Tensor) -> torch.Tensor:
        """
        Run model inference on batched input.
        """
        with torch.no_grad():
            predictions = self.model(input_batch)
        return predictions
    
    def postprocess(self, inference_output: torch.Tensor) -> List[Dict]:
        """
        Transform model output to response format.
        """
        predictions = inference_output.cpu().numpy()
        
        results = []
        for pred in predictions:
            score = float(pred[0])
            results.append({
                "score": score,
                "confidence": abs(score - 0.5) * 2,
                "predicted_class": "class_1" if score > 0.5 else "class_0"
            })
        
        return results
    
    def handle(self, data, context):
        """
        Handle request end-to-end (preprocessing + inference + postprocessing).
        """
        try:
            # Parse input
            input_data = self._parse_input(data)
            
            # Preprocess
            input_batch = self.preprocess(input_data)
            
            # Inference
            predictions = self.inference(input_batch)
            
            # Postprocess
            results = self.postprocess(predictions)
            
            return [results]
        
        except Exception as e:
            logger.error(f"Error in inference: {e}")
            return [{"error": str(e)}]
    
    def _parse_input(self, data):
        """Parse incoming request data."""
        import json
        results = []
        
        for row in data:
            if isinstance(row, bytes):
                row = row.decode("utf-8")
            
            if isinstance(row, str):
                row = json.loads(row)
            
            results.append(row)
        
        return results
```

#### KServe InferenceService Deployment

```yaml
# inferenceservice.yaml - KServe serving configuration
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: recommendation-model
  namespace: ml-serving
  labels:
    app: recommendation
spec:
  predictor:
    model:
      modelFormat:
        name: pytorch
      storageUri: "s3://ml-models/recommendation/v2.1"
      resources:
        requests:
          cpu: "2"
          memory: "8Gi"
          nvidia.com/gpu: "1"
        limits:
          cpu: "4"
          memory: "16Gi"
          nvidia.com/gpu: "1"
    
    # Autoscaling configuration
    containerConcurrency: 16
    timeoutSeconds: 30
  
  # Canary deployment for new model
  canaryTrafficPercent: 10
  
  # Transformer to handle custom feature engineering
  transformer:
    containers:
    - name: feature-transformer
      image: company-registry.azurecr.io/feature-transformer:v1.0
      ports:
      - containerPort: 8000
      env:
      - name: PREDICTOR_HOST
        value: recommendation-model-predictor-default.ml-serving.svc.cluster.local
      resources:
        requests:
          cpu: "1"
          memory: "2Gi"
        limits:
          cpu: "2"
          memory: "4Gi"
  
  # Explainer for model interpretability
  explainer:
    containers:
    - name: explainer
      image: company-registry.azurecr.io/shap-explainer:v1.0
      ports:
      - containerPort: 8000
      resources:
        requests:
          cpu: "1"
          memory: "2Gi"
```

### ASCII Diagrams

#### TensorFlow Serving Request Flow

```
Incoming Request (batch_size=32)
        │
        ▼
┌──────────────────────────────┐
│  gRPC / REST API Handler     │
└───────────┬──────────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Input Parser & Validator    │
│  - Check schema              │
│  - Validate input ranges     │
└───────────┬──────────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Batcher (if configured)     │
│  - Accumulate requests       │
│  - Max 64 or timeout 100ms   │
│  - Wait for full batch       │
└───────────┬──────────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Runtime (TensorFlow Lite)   │
│  - GPU memory pre-allocated  │
│  - Model weights loaded      │
│  - Session ready             │
└───────────┬──────────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Inference Execution         │
│  - Op graph traversal        │
│  - Kernel launch on GPU      │
│  - Time: 5ms for batch_64    │
└───────────┬──────────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Output Formatter            │
│  - Post-processing           │
│  - Format as Protocol Buffer │
└───────────┬──────────────────┘
            │
            ▼
Response sent to client
```

#### Multi-Framework Serving Stack (KServe)

```
┌─────────────────────────────────────────┐
│         API Gateway (Ingress)           │
│    (Authentication, Rate Limiting)      │
└──────────────┬──────────────────────────┘
               │
     ┌─────────┴────────────┐
     │                      │
   90%                    10%
     │                      │
┌────▼─────────┐    ┌──────▼──────────┐
│ Predictor    │    │ Predictor(CANARY)
│ v2.1 (Prod)  │    │ v2.2 (Testing)
│ TensorFlow   │    │ PyTorch
│ Serving      │    │ TorchServe
├──────────────┤    ├───────────────┤
│ Input: JSON  │    │ Input: JSON   │
│ 32ms latency │    │ 35ms latency  │
│ 98.5% accur. │    │ 99.1% accur.  │
└────┬─────────┘    └───────┬───────┘
     │                      │
     └──────────┬───────────┘
                │
        ┌───────▼────────┐
        │ Feature Store  │
        │ (Redis)        │
        │ <2ms lookup    │
        └────────────────┘
        
        ┌────────────────┐
        │ Monitoring     │
        │ (Prometheus)   │
        │ - Latency      │
        │ - Accuracy     │
        │ - GPU Util     │
        └────────────────┘
```

---

## Kubernetes for MLOps

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes provides container orchestration with ML-specific extensions through operators. For MLOps, Kubernetes manages:

**Resource Management for ML Workloads**:
```
GPU Resource Pool (K8s Cluster Node)
├── GPU 0: Model A serving (CUDA context)
├── GPU 1: Training job 1 (isolated)
├── GPU 2: Model B serving (multi-tenant)
└── GPU 3: Training job 2 (isolated)

Kubernetes scheduler ensures:
- GPU requests honored
- Affinity rules respected (GPU node selection)
- Resource limits enforced
```

**ML Operator Architecture**:
```
Kubernetes API Server
    │
    ├─ Custom Resource Definitions (CRDs):
    │  ├── Experiment (Kubeflow)
    │  ├── Training Job (Kubeflow)
    │  ├── PyTorchJob (Kubeflow)
    │  ├── InferenceService (KServe)
    │  └── SeldonDeployment (Seldon)
    │
    ├─ Controllers (watch for resources):
    │  ├── PyTorchJob Controller
    │  │  └─ Create pods, handle distributed training
    │  ├── KServe Controller
    │  │  └─ Route traffic, manage canary deployments
    │  └── Seldon Controller
    │     └─ Multi-model serving, monitoring
    │
    └─ Event Loop:
       ├── Watch for resource creation/update
       ├── Calculate desired state
       ├── Create/delete/update native Kubernetes resources
       └── Report status back to CRD
```

**GPU Scheduling Mechanism**:
```
Pod Spec requests GPU:
resources:
  limits:
    nvidia.com/gpu: 1

Scheduler Action:
1. Filters nodes (must have GPU available)
2. Scores nodes (prefer less-loaded, affinity rules)
3. Binds pod to node
4. Kubelet mounts GPU device
5. GPU driver enabled in container

Time overhead: ~2-3 seconds pod startup
```

#### Architecture Role

Kubernetes serves as the infrastructure control plane for MLOps:

**Layer 1: Infrastructure**
- Compute allocation (CPU, GPU, memory)
- Storage management (models, data, artifacts)
- Networking (service discovery, ingress)
- Resource quotas and limits (prevent runaway jobs)

**Layer 2: ML-Specific Abstractions**
- PyTorchJob: Distributed training coordination
- TFJob: TensorFlow training with parameter servers
- InferenceService: Model serving with automatic versioning
- Experiment: Hyperparameter tuning orchestration

**Layer 3: Operations**
- Auto-scaling (based on request volume or metrics)
- Monitoring & logging (Prometheus, ELK integration)
- Networking policies (between training & serving)
- Security (RBAC, pod security policies)

#### Production Usage Patterns

**Pattern 1: Multi-GPU Distributed Training (PyTorchJob)**
```
1. Data Scientist submits PyTorchJob
2. Kubeflow controller creates N worker pods (1 GPU each)
3. Pytorch Distributed Data Parallel:
   - Pod 0 (rank 0): master aggregating gradients
   - Pod 1-3 (rank 1-3): workers computing gradients
4. Training progresses with gradient synchronization
5. Best model checkpointed to persistent storage
6. Job completes, pods cleaned up automatically
```

**Pattern 2: GPU Sharing via Time-slicing**
```
Node with 1 GPU:
- Problem: 2 training jobs, 3 serving containers
- Solution: GPU time-slicing (MIG for newer GPUs)
- Each gets 100ms time slice on GPU
- Latency impact: <5% (if jobs cooperative)
```

**Pattern 3: Batch Job Orchestration**
```
CronJob triggers daily training:
0 2 * * * kubernetes_job(train_model)
    ↓
Job Controller creates Pod
    ↓
GPU node selected
    ↓
Data pulled from S3/GCS
    ↓
Model trained
    ↓
Results saved
    ↓
Pod cleaned up
```

#### DevOps Best Practices

**1. Resource Quotas & Limits**
```yaml
# namespace-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ml-team-quota
  namespace: ml-training
spec:
  hard:
    requests.cpu: "64"
    requests.memory: 256Gi
    limits.cpu: "128"
    limits.nvidia.com/gpu: "8"
    limits.memory: 512Gi
```

**2. GPU Node Taints & Tolerations**
```yaml
# GPU node marked with taint
taint: gpu=true:NoSchedule

# Training job tolerates GPU taint
tolerations:
- key: gpu
  operator: Equal
  value: "true"
  effect: NoSchedule
```

**3. Pod Disruption Budgets (maintain minimum replicas during updates)**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: model-serving-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: model-serving
```

**4. Node Affinity for Hardware Selection**
```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      preference:
        matchExpressions:
        - key: gpu-type
          operator: In
          values:
          - nvidia-a100
```

**5. Monitoring ML-specific metrics**
```
- GPU memory utilization per container
- Training loss curves (scraped from logs)
- Job queue depth (pods pending GPU assignment)
- Model serving accuracy per version
```

#### Common Pitfalls

| Pitfall | Issue | Prevention |
|---------|-------|-----------|
| **Over-requesting GPU** | Pod pending indefinitely | Right-size requests based on actual needs |
| **No resource limits** | Training job consumes all GPU, other jobs blocked | Set hard limits, implement quotas |
| **Node not ready after GPU assignment** | NVIDIA driver absent | Use DaemonSet for node initialization |
| **Distributed training hangs** | Network issues between pods | Use host networking, test before training |
| **Model files on ephemeral storage** | Pod terminated, checkpoint lost | Use Persistent Volumes for models |
| **No GPU driver updates** | Incompatible PyTorch/CUDA versions | Update node drivers before upgrading |

### Practical Code Examples

#### PyTorchJob for Distributed Training

```yaml
# pytorch-job.yaml - Distributed PyTorch training on K8s
apiVersion: kubeflow.org/v1
kind: PyTorchJob
metadata:
  name: pytorch-training-job
  namespace: ml-training
spec:
  cleanPodPolicy: All
  backoffLimit: 3
  
  pytorchReplicaSpecs:
    Master:
      replicas: 1
      template:
        metadata:
          labels:
            training-job: pytorch
        spec:
          containers:
          - name: pytorch
            image: company-registry.azurecr.io/pytorch-training:v1.12
            command: [
              "python",
              "-m",
              "torch.distributed.launch",
              "--nnodes=3",
              "--nproc_per_node=1",
              "/workspace/train_distributed.py",
              "--epochs=10",
              "--batch-size=32",
              "--learning-rate=0.001"
            ]
            
            env:
            - name: MASTER_ADDR
              value: "pytorch-training-job-master-0"
            - name: MASTER_PORT
              value: "6379"
            - name: NCCL_DEBUG
              value: "INFO"
            
            resources:
              requests:
                cpu: "4"
                memory: "16Gi"
                nvidia.com/gpu: "1"
              limits:
                cpu: "8"
                memory: "32Gi"
                nvidia.com/gpu: "1"
            
            volumeMounts:
            - name: training-data
              mountPath: /data
            - name: model-checkpoint
              mountPath: /models
          
          volumes:
          - name: training-data
            persistentVolumeClaim:
              claimName: training-data-pvc
          - name: model-checkpoint
            persistentVolumeClaim:
              claimName: model-checkpoint-pvc
          
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: gpu-type
                    operator: In
                    values:
                    - nvidia-a100
    
    Worker:
      replicas: 2
      template:
        metadata:
          labels:
            training-job: pytorch
        spec:
          containers:
          - name: pytorch
            image: company-registry.azurecr.io/pytorch-training:v1.12
            command: [
              "python",
              "-m",
              "torch.distributed.launch",
              "--nnodes=3",
              "--nproc_per_node=1",
              "/workspace/train_distributed.py"
            ]
            
            env:
            - name: NCCL_DEBUG
              value: "INFO"
            
            resources:
              requests:
                cpu: "4"
                memory: "16Gi"
                nvidia.com/gpu: "1"
              limits:
                cpu: "8"
                memory: "32Gi"
                nvidia.com/gpu: "1"
            
            volumeMounts:
            - name: training-data
              mountPath: /data
            - name: model-checkpoint
              mountPath: /models
          
          volumes:
          - name: training-data
            persistentVolumeClaim:
              claimName: training-data-pvc
          - name: model-checkpoint
            persistentVolumeClaim:
              claimName: model-checkpoint-pvc
          
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: gpu-type
                    operator: In
                    values:
                    - nvidia-a100
---
# Persistent Volume Claims for models and data
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: training-data-pvc
  namespace: ml-training
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can read/write
  storageClassName: nfs-fast
  resources:
    requests:
      storage: 500Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: model-checkpoint-pvc
  namespace: ml-training
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: persistent-disk
  resources:
    requests:
      storage: 100Gi
```

#### KServe InferenceService with Custom Predictor

```python
# custom_predictor.py - KServe predictor class
from typing import Dict, List, Any
import kserve
import logging
import numpy as np
import torch

logger = logging.getLogger(__name__)

class MLPredictor(kserve.Model):
    """Custom KServe predictor for ML model."""
    
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = False
        self.model = None
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model_version = "unknown"
    
    def load(self):
        """Load model from storage."""
        logger.info(f"Loading model {self.name}")
        try:
            # Load model from persistent storage
            model_path = f"/mnt/models/{self.name}/model.pt"
            self.model = torch.jit.load(model_path, map_location=self.device)
            self.model.eval()
            
            # Load metadata
            import json
            with open(f"/mnt/models/{self.name}/metadata.json") as f:
                metadata = json.load(f)
                self.model_version = metadata.get("version", "unknown")
            
            self.ready = True
            logger.info(f"Model {self.name} loaded successfully (v{self.model_version})")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def predict(self, request: Dict) -> Dict:
        """
        Serve predictions.
        
        request: {
            "instances": [
                {"feature_1": 1.0, "feature_2": 2.0},
                ...
            ]
        }
        """
        instances = request.get("instances", [])
        
        # Convert instances to tensor
        features = np.array([[
            inst.get("feature_1", 0.0),
            inst.get("feature_2", 0.0),
            inst.get("feature_3", 0.0),
        ] for inst in instances], dtype=np.float32)
        
        features_tensor = torch.from_numpy(features).to(self.device)
        
        # Inference
        with torch.no_grad():
            predictions = self.model(features_tensor)
        
        # Format response
        predictions_list = predictions.cpu().numpy().tolist()
        
        return {
            "predictions": predictions_list,
            "model_version": self.model_version
        }

# KServe model server
if __name__ == "__main__":
    model = MLPredictor("recommendation-model")
    model.load()
    
    # Start KServe server (listens on port 8080)
    kserve.ModelServer().start([model])
```

#### GPU Resource Quota and Monitoring

```yaml
# gpu-resource-management.yaml
---
# GPU Node Configuration
apiVersion: v1
kind: Node
metadata:
  name: gpu-node-1
spec:
  labels:
    gpu-type: nvidia-a100
    zone: us-east-1a
  taints:
  - key: gpu
    value: "true"
    effect: NoSchedule

---
# Resource Quota limiting GPU usage
apiVersion: v1
kind: Namespace
metadata:
  name: ml-team
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ml-team-gpu-quota
  namespace: ml-team
spec:
  hard:
    requests.nvidia.com/gpu: "4"
    limits.nvidia.com/gpu: "4"
    requests.cpu: "32"
    requests.memory: 128Gi
    limits.memory: 256Gi

---
# Service to expose GPU metrics
apiVersion: v1
kind: Service
metadata:
  name: gpu-metrics-exporter
  namespace: ml-team
spec:
  selector:
    app: gpu-exporter
  ports:
  - port: 9400
    protocol: TCP

---
# DaemonSet for GPU monitoring (runs on every GPU node)
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: gpu-metrics-exporter
  namespace: ml-team
spec:
  selector:
    matchLabels:
      app: gpu-exporter
  template:
    metadata:
      labels:
        app: gpu-exporter
    spec:
      nodeSelector:
        gpu-type: nvidia-a100
      containers:
      - name: exporter
        image: company-registry.azurecr.io/gpu-metrics-exporter:v1.0
        ports:
        - containerPort: 9400
          name: metrics
        env:
        - name: NVIDIA_DEVICE_QUERY_TIMEOUT
          value: "1000"
        # Access to GPU metrics
        securityContext:
          privileged: true
        volumeMounts:
        - name: nvidia-install-dir
          mountPath: /usr/local/nvidia
          readOnly: true
      volumes:
      - name: nvidia-install-dir
        hostPath:
          path: /usr/local/nvidia
```

### ASCII Diagrams

#### Kubernetes GPU Scheduling

```
Pod Submission (requests GPU: 1)
        │
        ▼
┌─────────────────────────────────┐
│  Scheduler                      │
│  - Find nodes with GPU avail    │
│  - Apply node selectors         │
│  - Check resource limits        │
│  - Score nodes (affinity rules) │
└──────────┬──────────────────────┘
           │
        Bind to:
        gpu-node-2 (A100)
           │
           ▼
┌─────────────────────────────────┐
│  Kubelet on gpu-node-2          │
│  - Create containerd container  │
│  - Mount GPU device (/dev/nv0)  │
│  - Set CUDA_VISIBLE_DEVICES     │
│  - Start NVIDIA container       │
└──────────┬──────────────────────┘
           │
           ▼
    Container Running
    ├── CUDA context active
    ├── Model loaded on GPU
    └── Inference executing
```

#### Distributed PyTorchJob Topology

```
PyTorchJob (Master-1, Worker-2)
    │
    ├─ Master Pod (rank 0)
    │  ├── GPU:0 (Primary)
    │  ├── Port 6379
    │  └── Aggregates gradients
    │
    ├─ Worker Pod 1 (rank 1)
    │  ├── GPU:0 (Distributed)
    │  └── Computes gradients
    │
    └─ Worker Pod 2 (rank 2)
       ├── GPU:0 (Distributed)
       └── Computes gradients

Communication:
Master ←→ Worker1 (NCCL over RDMA/TCP)
Master ←→ Worker2 (NCCL over RDMA/TCP)

Gradient Synchronization:
All-reduce operation across ranks
Synchronized parameter updates
```

---

## Feature Stores

### Textual Deep Dive

#### Internal Working Mechanism

A feature store is a centralized data platform managing feature engineering, computation, and serving. It solves a critical problem in production ML: **training-serving skew**, where features calculated during model training differ from features served at prediction time.

**Core Architecture Components**:

1. **Feature Definition Layer**: 
   - YAML/Python definitions of features (name, schema, computation logic)
   - Version control of feature definitions
   - Dependencies between features

2. **Offline Store** (Training Data Generation):
   ```
   Historical Data (Data Lake)
      ↓ (SQL/Spark job)
   Feature Computation (batch)
      ↓
   Training Dataset (snapshots in time)
   ```
   - Batch feature computation (daily/weekly)
   - Time-travel capability (reconstruct features as they existed in past)
   - Historical snapshots for training reproducibility

3. **Online Store** (Real-time Serving):
   ```
   Real-time Feature Sources (APIs, databases)
      ↓ (Low-latency computation)
   Feature Cache (Redis, DynamoDB)
      ↓
   Serving API (<2ms lookup)
   ```
   - Sub-millisecond feature lookup
   - Keeps frequently accessed features cached
   - Synchronization with offline store

4. **Feature Registry** (Governance):
   - Metadata about each feature (owner, SLA, freshness requirements)
   - Data lineage (which model uses which features)
   - Access control and monitoring

**Data Flow Example** (E-commerce Recommendation):
```
Day 0 (Offline - Training Data Preparation):
1. Raw events: user browsing, purchases (stored in data lake)
2. Feature computation:
   - "user_7days_purchase_value" = SUM(purchases.amount WHERE user_id=7 AND date in last 7 days)
   - "item_7days_views" = COUNT(views) WHERE item_id=42 AND date in last 7 days
3. Store training data snapshot with features as of Day 0 12:00 UTC

Day N (Online - Serving):
1. Client requests recommendations for user_7
2. Fetch from online store:
   - "user_7days_purchase_value" (cached, updated hourly)
   - "item_7days_views" (real-time computed)
3. Combine with pre-computed embeddings
4. Call model with complete feature vector
5. Return recommendations
```

#### Architecture Role

Feature stores sit between:
- **Data Infrastructure**: Data lakes, warehouses, streaming platforms
- **ML Pipeline**: Feature definitions, training jobs, serving infrastructure
- **Feature Consumers**: Models, dashboards, analytics

**Typical Enterprise Architecture**:
```
┌─────────────────────────────────────────┐
│     Data Sources                        │
│ ├─ Data Lake (S3/ADLS)                 │
│ ├─ Streaming (Kafka)                    │
│ ├─ Databases (PostgreSQL, DynamoDB)    │
│ └─ APIs (Real-time data)               │
└──────────────┬──────────────────────────┘
               │
        ┌──────▼──────────┐
        │  Feature Store  │
        ├─────────────────┤
        │ Registry        │ (Feast, Tecton, Hopsworks)
        │ Offline Store   │ (Data Warehouse)
        │ Online Store    │ (Redis, DynamoDB)
        │ Computation     │ (Batch: Spark, Stream: Flink)
        └──────┬──────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼──┐   ┌───▼──┐   ┌───▼──┐
│Train │   │Serve │   │Batch │
│Jobs  │   │API   │   │Score │
└──────┘   └──────┘   └──────┘
```

#### Production Usage Patterns

**Pattern 1: Synchronized Online/Offline** (Feast Architecture)
```
Offline Pipeline (Daily):
- Fetch raw data from data warehouse
- Compute features using Spark SQL
- Store in offline store (Parquet in S3)

Online Pipeline (Continuous):
- Materialize features to Redis every hour
- Real-time features computed on-demand
- Join with cached features at serving time
```

**Pattern 2: Time-Travel for Training Reproducibility**
```
Required: Reproduce training for model retrained on Day 30
- Feature store retrieves features as they existed on Day 30
- Guarantees exact same training data
- Enables deterministic model retraining
- Crucial for debugging/audits
```

**Pattern 3: Multi-tenant Feature Sharing**
```
10 ML teams, 50+ models, 200+ features
- ML Team A: uses features F1, F2, F3 + team-specific F4, F5
- ML Team B: uses features F1, F6, F7
- Both share feature F1 (single computation, multiple consumers)
- Cost savings and consistency benefits
```

#### DevOps Best Practices

**1. Feature SLA Management**
```
Feature: user_7days_purchase_value
- Max latency: 10 minutes (updated every 10 min)
- Freshness requirement: Must be within 1 hour
- Availability SLA: 99.9%
- Alert if: Not updated in last 70 minutes
```

**2. Feature Versioning**
```
Feature definitions versioned:
- user_engagement_v1: (2023) Simple sum of interactions
- user_engagement_v2: (2024) Weighted by recency
- user_engagement_v3: (2025) ML-predicted engagement score

Training data must track feature versions used
Model must declare required feature version
```

**3. Online/Offline Consistency Checks**
```
Every hour:
1. Sample 1000 random requests
2. Fetch features from online store
3. Compute features from offline store (identical logic)
4. Compare values (must match within tolerance)
5. Alert if inconsistency > 5%
```

**4. Monitoring & Observability**
```
Metrics tracked:
- Feature lookup latency (p50, p95, p99)
- Cache hit rate (Redis)
- Feature staleness (time since last update)
- Computation job success rate
- Storage costs per feature
```

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| **Feature leakage** | Data from future used in training | Enforce time boundaries, versioning |
| **Offline-online mismatch** | Training ≠ serving features | Unified computation code, tests |
| **Missing features at serving** | Model fails with null values | Fallback values, validation |
| **Storage explosion** | Costs unchecked (50+ materialize) | Tiered storage, archival policy |
| **Slow feature computation** | Model inference latency > SLA | Caching, pre-computation, batching |
| **Dependency hell** | Feature A depends on B, B broken | Dependency tracking, DAG validation |

### Practical Code Examples

#### Feast Feature Store Configuration

```python
# features.py - Define features in Feast
from feast import Entity, Feature, FeatureView, ValueType
from feast.data_sources import BigQuerySource
from datetime import timedelta

# Define entities
user_entity = Entity(
    name="user_id",
    value_type=ValueType.INT64
)

item_entity = Entity(
    name="item_id",
    value_type=ValueType.INT64
)

# Define data source
transactions_source = BigQuerySource(
    table="project.dataset.transactions",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp"
)

# Define feature views
user_features = FeatureView(
    name="user_features",
    entities=["user_id"],
    features=[
        Feature(name="user_7days_purchase_value", dtype=ValueType.FLOAT),
        Feature(name="user_30days_purchase_count", dtype=ValueType.INT64),
        Feature(name="user_avg_order_value", dtype=ValueType.FLOAT),
        Feature(name="user_is_premium", dtype=ValueType.BOOL),
    ],
    input=transactions_source,
    ttl=timedelta(days=30),
    online=True,
    offline=True
)

item_features = FeatureView(
    name="item_features",
    entities=["item_id"],
    features=[
        Feature(name="item_7days_views", dtype=ValueType.INT64),
        Feature(name="item_conversion_rate", dtype=ValueType.FLOAT),
    ],
    input=transactions_source,
    ttl=timedelta(days=365),
    online=True,
    offline=False  # Only for training
)
```

#### Feast Online/Offline Serving

```python
# serve_features.py - Fetch features at prediction time
from feast import FeatureStore
import pandas as pd
from datetime import datetime, timedelta

# Initialize feature store
fs = FeatureStore(repo_path="./feast_repo")

def get_training_data(user_ids, item_ids, as_of_date):
    """
    Retrieve training data with time-travel capability.
    Ensures reproducibility: same features as on training date.
    """
    entity_df = pd.DataFrame({
        "user_id": user_ids,
        "item_id": item_ids,
        "event_timestamp": [as_of_date] * len(user_ids)
    })
    
    # Get features as they existed on training date
    training_df = fs.get_historical_features(
        entity_df=entity_df,
        features=[
            "user_features:user_7days_purchase_value",
            "user_features:user_avg_order_value",
            "item_features:item_7days_views",
            "item_features:item_conversion_rate"
        ],
        full_table_scan=False
    ).to_df()
    
    return training_df

def get_online_features(user_id, item_id):
    """
    Real-time feature retrieval for serving.
    Combines cached features with on-demand computation.
    """
    feature_vector = fs.get_online_features(
        features=[
            "user_features:user_7days_purchase_value",
            "user_features:user_is_premium",
            "item_features:item_7days_views",
            "item_features:item_conversion_rate"
        ],
        entity_rows=[{
            "user_id": user_id,
            "item_id": item_id
        }]
    ).to_dict()
    
    # format as model input
    return {
        "user_purchase_value": feature_vector["user_7days_purchase_value"][0],
        "user_is_premium": feature_vector["user_is_premium"][0],
        "item_views": feature_vector["item_7days_views"][0],
        "item_conversion": feature_vector["item_conversion_rate"][0]
    }

def materialize_online_store():
    """
    Push features from offline store to online store (Redis).
    Run hourly as scheduled job.
    """
    # Materialize latest feature values
    fs.materialize(
        start_date=datetime.utcnow() - timedelta(hours=1),
        end_date=datetime.utcnow(),
        feature_views=["user_features", "item_features"]
    )
    print("Features materialized to Redis")
```

#### Feature Store Monitoring

```bash
#!/bin/bash
# monitor_features.sh - Monitor feature store health

set -e

FEAST_REPO_PATH="./feast_repo"
FEATURE_STORE_HOST="redis.ml-serving.svc.cluster.local"
FEATURE_STORE_PORT=6379

# Check online store connectivity
check_online_store() {
    echo "Checking Redis connectivity..."
    redis-cli -h $FEATURE_STORE_HOST -p $FEATURE_STORE_PORT PING > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Redis online store healthy"
    else
        echo "✗ Redis online store unreachable"
        exit 1
    fi
}

# Check feature materialization freshness
check_feature_freshness() {
    echo "Checking feature freshness..."
    
    # Get last materialization time
    LAST_MATERIALIZATION=$(redis-cli -h $FEATURE_STORE_HOST -p $FEATURE_STORE_PORT \
        GET "feature_store:materialization_time")
    
    CURRENT_TIME=$(date +%s)
    FRESHNESS_THRESHOLD=3600  # 1 hour in seconds
    
    if [ -z "$LAST_MATERIALIZATION" ]; then
        echo "✗ No materialization found"
        return 1
    fi
    
    AGE=$((CURRENT_TIME - LAST_MATERIALIZATION))
    
    if [ $AGE -lt $FRESHNESS_THRESHOLD ]; then
        echo "✓ Features fresh (age: ${AGE}s)"
        return 0
    else
        echo "✗ Features stale (age: ${AGE}s > threshold: ${FRESHNESS_THRESHOLD}s)"
        return 1
    fi
}

# Validate offline/online consistency
check_consistency() {
    echo "Checking offline/online consistency..."
    
    # Sample 100 users
    for i in {1..100}; do
        USER_ID=$((RANDOM % 10000))
        
        # Get from online store
        ONLINE=$(redis-cli -h $FEATURE_STORE_HOST -p $FEATURE_STORE_PORT \
            GET "user_features:${USER_ID}:user_7days_purchase_value" 2>/dev/null || echo "")
        
        # Get from offline store (bigquery)
        OFFLINE=$(bq query --use_legacy_sql=false \
            "SELECT user_7days_purchase_value FROM dataset.user_features WHERE user_id=${USER_ID} LIMIT 1" 2>/dev/null || echo "")
        
        if [ "$ONLINE" != "$OFFLINE" ] && [ -n "$ONLINE" ] && [ -n "$OFFLINE" ]; then
            echo "✗ Mismatch for user ${USER_ID}: online=$ONLINE offline=$OFFLINE"
            return 1
        fi
    done
    
    echo "✓ Consistency check passed (100 samples)"
    return 0
}

# Main health check
main() {
    echo "=== Feature Store Health Check ==="
    check_online_store
    check_feature_freshness
    check_consistency
    echo "=== All checks passed ==="
}

main
```

### ASCII Diagrams

#### Feature Store Data Flow

```
┌──────────────────────────────────────────────────────────┐
│              Offline Pipeline (Daily)                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Data Lake (S3)                                         │
│  └─ transactions_raw/date=2024_04_05/                  │
│                                                           │
│        ↓ (Spark SQL job)                               │
│                                                           │
│  Feature Computation:                                  │
│  - SUM(purchases.amount WHERE date in last 7 days)   │
│  - COUNT(events WHERE event_type='view')             │
│                                                           │
│        ↓                                                │
│                                                           │
│  Offline Store (BigQuery / Parquet)                   │
│  └─ user_features/date=2024_04_05/                    │
│                                                           │
└──────────────┬───────────────────────────────────────────┘
               │
        ┌──────▼────────┐
        │  Materialization (1x/hour)
        │  Copy latest to online store
        └──────┬────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│            Online Store (Redis)                         │
├────────────────────────────────────────────────────────┤
│                                                          │
│  Keys (TTL 24h):                                       │
│  user_features:7:purchase_value = 1234.50            │
│  user_features:7:premium_flag = 1                    │
│  item_features:42:views = 5000                       │
│  item_features:42:conversion = 0.045                 │
│                                                          │
│  Get Latency: <2ms (Redis in-memory)                │
│                                                          │
└────────┬──────────────────────────────────────────────┘
         │
    ┌────▼─────────────┐
    │  Model Serving   │
    │  (Prediction)    │
    │                  │
    │  Fetch features  │
    │  Combine with    │
    │  embeddings      │
    │  Run inference   │
    └──────────────────┘
```

#### Offline/Online Consistency Validation

```
Every Hour:
┌─────────────────────────────┐
│  Sample Feature: F42         │
│  (item_7days_views)          │
└──────┬──────────────────────┘
       │
   ┌───┴────────────────────────┐
   │                            │
┌──▼─────────┐        ┌────────▼──┐
│ Online     │        │   Offline  │
│ Store      │        │    Store   │
│ (Redis)    │        │  (BigQuery)│
│            │        │            │
│ Value: 523 │        │  Value: 521│
└───┬────────┘        └────────┬───┘
    │                          │
    └──────────┬───────────────┘
               │
        Delta = 2 (0.38%)
               │
        ✓ Within tolerance
```

---

## Monitoring ML Scripts

### Textual Deep Dive

#### Internal Working Mechanism

Monitoring ML systems differs fundamentally from traditional application monitoring:

**Traditional Monitoring**:
- Metrics: CPU, memory, request latency, error rates
- Symptoms: high CPU = investigate code
- Root cause: usually hardware, network, or bug

**ML Monitoring**:
- Metrics: prediction accuracy, data distribution, model confidence
- Symptoms: accuracy dropped = data changed or model degraded
- Root cause: data drift, concept drift, feature failure, model issue

**ML-Specific Metrics**:

1. **Model Quality Metrics**:
   - Accuracy, precision, recall, F1 (classification)
   - MAE, RMSE (regression)
   - AUC, log-loss (ranking)

2. **Data Quality Metrics**:
   - Distribution statistics (mean, std, min, max)
   - Data drift: Kolmogorov-Smirnov test, Wasserstein distance
   - Missing value percentage
   - Out-of-range value percentage

3. **Operational Metrics**:
   - Inference latency (p50, p95, p99)
   - Throughput (requests/second)
   - Model serving availability
   - Feature freshness (time since last update)

4. **Model-Specific Metrics**:
   - Calibration: predicted probability vs actual rate
   - Fairness: equal accuracy across demographic groups
   - Confidence distribution (are uncertain predictions uncertain?)

**Data Collection Mechanism**:
```
Model Inference
    ↓
1. Make prediction: p = 0.87
2. Log features + prediction + timestamp
3. (Later) Receive label: y_true = 1
4. Compute metrics: pred_correct=(0.87>0.5)==1 ✓
5. Update tracking: accuracy_daily += [1]
6. Weekly: compute daily accuracy, trend analysis
```

#### Architecture Role

Monitoring sits in the feedback loop:

```
Model in Production
    ↓ Predictions being made
    ├─ Real-time metrics (latency, throughput)
    ├─ Prediction logging (for ground truth when available)
    │
    ├─ Data drift detection
    │  └─ Alert team if input distribution changed
    │
    ├─ Model performance degradation
    │  └─ If accuracy drops > threshold, trigger retraining
    │
    └─ Operational health
       └─ GPU utilization, memory, network

Alerts Based on Metrics
    ↓
Team Investigates
    ↓
Action: Retrain model / rollback / investigate data
```

#### Production Usage Patterns

**Pattern 1: Delayed Ground Truth** (E-commerce Conversion)
```
Hour 0: Model predicts conversion (y_pred = 0.8)
         Log prediction

Hour N-24: Ground truth arrives (did they actually convert?)
           y_true = 1
           Update metric: prediction_was_correct = True

Daily: Compute accuracy from predictions made 24h ago
       Compare to baseline
       Alert if accuracy has degraded >2%
```

**Pattern 2: Proxy Metrics** (When ground truth unavailable)
```
Recommendation system: No true labels in real-time
Use proxies:
- Click-through rate (user clicked item we recommended)
- Dwell time (how long they spent viewing)
- Bookmark rate (saved for later)
- Revenue impact (items recommended had higher AOV)

Monitor these proxies hourly
Alert if CTR drops >5%
```

**Pattern 3: Distribution Monitoring** (Drift Detection)
```
Training data: user_age distribution
  mean=32, std=12, min=18, max=75

Serving data (daily):
  Day 1: mean=31, std=11 (normal)
  Day 2: mean=28, std=10 (still normal, random variation)
  Day 30: mean=22, std=15 (KS-test p<0.001, DRIFT DETECTED!)
  → Likely cause: app changed target demographic
  → Action: Retrain on recent data or alert team
```

#### DevOps Best Practices

**1. Automated Alert Threshold Setting**
```
Baseline establishment (weeks 1-4):
- Train model, deploy to production
- Collect metrics for 4 weeks
- Compute baseline: accuracy mean=94.2%, std=1.3%
- Set alert threshold: accuracy < mean - 2*std = 91.6%

Prevents alert fatigue while catching real issues
```

**2. Prediction Logging for Offline Analysis**
```
Each prediction logged:
{
  "timestamp": "2024-04-05T14:23:45Z",
  "model_version": "v2.1",
  "user_id": "user_7",
  "features": {"age": 32, "income": 75000},
  "prediction": 0.87,
  "model_input_hash": "abc123",  # For consistency checks
  "serving_latency_ms": 8
}

Used for:
- Offline accuracy computation (when labels arrive)
- Debugging customer issues (replay prediction)
- Model quality analysis (segment performance)
```

**3. SLA-based Alerting**
```
Model Service SLA:
- Latency p99 < 100ms
- Accuracy > 92.0%
- Availability > 99.9%
- Freshness of features < 1 hour

Each violated → PagerDuty alert
Team has runbook for each
```

**4. Monitoring Dashboards**
```
Real-time Dashboard:
- Model accuracy (computed hourly)
- Data drift indicators (KS-test pvalue)
- Prediction latency distribution
- Feature availability
- GPU utilization
- Model serving error rate

Each chart has alert threshold line
Trending metrics over days/weeks
```

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| **No ground truth collection** | Can't measure actual accuracy | Log predictions, collect labels in data pipeline |
| **Metrics only at feature level** | Missing end-to-end issues | Instrument model inference, log predictions |
| **Noisy thresholds** | Alert fatigue or missed issues | Use statistical baselines, not fixed thresholds |
| **No drill-down capability** | "Accuracy dropped" but don't know why | Log segment-level metrics, feature values |
| **Monitoring only production** | Issues in staging missed | Monitor staging with realistic data too |
| **Lost prediction logs** | Can't debug customer issues | Central logging system, long retention |

### Practical Code Examples

#### Prometheus Metrics for ML Models

```python
# prometheus_metrics.py - Export ML metrics to Prometheus
from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry
import time
from datetime import datetime

# Create registry
registry = CollectorRegistry()

# Counter: Total predictions
predictions_total = Counter(
    'ml_predictions_total',
    'Total predictions made',
    ['model_version', 'model_name'],
    registry=registry
)

# Histogram: Prediction latency
prediction_latency = Histogram(
    'ml_prediction_latency_seconds',
    'Prediction inference latency',
    ['model_version'],
    buckets=(0.005, 0.01, 0.05, 0.1, 0.5, 1.0),
    registry=registry
)

# Gauge: Model accuracy
model_accuracy = Gauge(
    'ml_model_accuracy',
    'Model accuracy on recent predictions',
    ['model_version', 'segment'],
    registry=registry
)

# Gauge: Data drift indicator
data_drift_score = Gauge(
    'ml_data_drift_ks_statistic',
    'Kolmogorov-Smirnov test statistic (drift detector)',
    ['feature_name'],
    registry=registry
)

# Histogram: Model confidence distribution
prediction_confidence = Histogram(
    'ml_prediction_confidence',
    'Model prediction confidence distribution',
    ['model_version'],
    buckets=(0.5, 0.6, 0.7, 0.8, 0.9, 0.95),
    registry=registry
)

class MLMetricsCollector:
    def __init__(self, model_name, model_version):
        self.model_name = model_name
        self.model_version = model_version
    
    def record_prediction(self, confidence, latency_ms):
        """Record metrics for a single prediction."""
        predictions_total.labels(
            model_version=self.model_version,
            model_name=self.model_name
        ).inc()
        
        prediction_latency.labels(
            model_version=self.model_version
        ).observe(latency_ms / 1000.0)  # Convert to seconds
        
        prediction_confidence.labels(
            model_version=self.model_version
        ).observe(confidence)
    
    def update_accuracy(self, accuracy, segment="all"):
        """Update model accuracy gauge."""
        model_accuracy.labels(
            model_version=self.model_version,
            segment=segment
        ).set(accuracy)
    
    def update_drift_score(self, feature_name, ks_statistic, pvalue):
        """Update data drift score."""
        data_drift_score.labels(
            feature_name=feature_name
        ).set(ks_statistic)
        
        # Alert if drift detected (p < 0.05)
        if pvalue < 0.05:
            print(f"ALERT: Data drift detected in {feature_name} (p={pvalue:.4f})")

# Usage
if __name__ == "__main__":
    from prometheus_client import start_http_server
    import random
    
    # Start Prometheus metrics server on port 8000
    start_http_server(8000, registry=registry)
    
    collector = MLMetricsCollector("recommendation_model", "v2.1")
    
    # Simulate predictions
    for _ in range(100):
        confidence = random.uniform(0.5, 1.0)
        latency = random.uniform(5, 50)  # ms
        collector.record_prediction(confidence, latency)
        time.sleep(0.1)
    
    # Update accuracy metric
    collector.update_accuracy(0.942, segment="all")
    collector.update_accuracy(0.951, segment="premium_users")
    
    print("Metrics available at http://localhost:8000/metrics")
    # Keep running
    import time
    time.sleep(3600)
```

#### Model Performance Monitoring Script

```python
# monitor_model_performance.py - Compute metrics from prediction logs
import pandas as pd
from datetime import datetime, timedelta
from scipy import stats

class ModelPerformanceMonitor:
    """Monitor ML model performance from prediction logs."""
    
    def __init__(self, prediction_log_table, label_table):
        """
        Args:
            prediction_log_table: Table with model predictions
            label_table: Table with ground truth labels
        """
        self.prediction_log = pd.read_csv(prediction_log_table)
        self.labels = pd.read_csv(label_table)
    
    def compute_accuracy(self, lookback_days=1):
        """Compute accuracy for predictions made N days ago."""
        cutoff_date = datetime.utcnow() - timedelta(days=lookback_days)
        
        # Join predictions with labels
        merged = self.prediction_log.merge(
            self.labels,
            on=['user_id', 'item_id'],
            how='inner'
        )
        
        merged['prediction_correct'] = (
            (merged['prediction'] > 0.5) == merged['label']
        )
        
        accuracy = merged['prediction_correct'].mean()
        return accuracy
    
    def detect_data_drift(self, feature_name, threshold_pvalue=0.05):
        """Detect data drift using Kolmogorov-Smirnov test."""
        # Training distribution (known baseline)
        training_dist = self._get_training_distribution(feature_name)
        
        # Recent serving distribution
        recent_data = self.prediction_log[
            self.prediction_log['timestamp'] > (datetime.utcnow() - timedelta(days=1))
        ]
        
        serving_dist = recent_data[feature_name].values
        
        # KS test
        ks_stat, pvalue = stats.ks_2samp(training_dist, serving_dist)
        
        return {
            'feature': feature_name,
            'ks_statistic': ks_stat,
            'pvalue': pvalue,
            'drift_detected': pvalue < threshold_pvalue,
            'mean_training': training_dist.mean(),
            'mean_serving': serving_dist.mean()
        }
    
    def compute_fairness_metrics(self):
        """Check model fairness across demographic groups."""
        merged = self.prediction_log.merge(
            self.labels,
            on=['user_id', 'item_id'],
            how='inner'
        )
        
        results = {}
        for group in merged['demographic_group'].unique():
            group_data = merged[merged['demographic_group'] == group]
            accuracy = (
                (group_data['prediction'] > 0.5) == group_data['label']
            ).mean()
            results[group] = accuracy
        
        return results
    
    def _get_training_distribution(self, feature_name):
        """Fetch training data distribution (from model metadata)."""
        # In production: load from model registry or cache
        # For now: return synthetic baseline
        import numpy as np
        return np.random.normal(loc=50, scale=15, size=10000)

# Usage
if __name__ == "__main__":
    monitor = ModelPerformanceMonitor(
        "gs://ml-logs/predictions.csv",
        "gs://ml-data/labels.csv"
    )
    
    # Check daily accuracy
    accuracy = monitor.compute_accuracy(lookback_days=1)
    print(f"Yesterday's accuracy: {accuracy:.4f}")
    
    # Detect data drift
    for feature in ['user_age', 'item_price', 'session_duration']:
        drift_result = monitor.detect_data_drift(feature)
        print(f"Feature {feature}: {drift_result}")
        
        if drift_result['drift_detected']:
            print(f"  ALERT: Drift in {feature}")
            print(f"  Training mean: {drift_result['mean_training']:.2f}")
            print(f"  Serving mean: {drift_result['mean_serving']:.2f}")
    
    # Check fairness
    fairness = monitor.compute_fairness_metrics()
    print(f"Fairness metrics: {fairness}")
```

### ASCII Diagrams

#### Data Drift Detection Flow

```
Training Data Distribution
  user_age: [18, 22, 28, 32, 45, 55, 65...]
  Mean: 38, Std: 14
        │
        │ (Stored as baseline)
        │
        ▼
╔═══════════════════════════════════╗
║   Serving Data (Real-time)        ║
║   Daily collection (D1, D2, ...)  ║
╚════════════┬══════════════════════╝
             │
             ├─ D1: Mean=37, Std=13  → KS-test p=0.87 (no drift)
             ├─ D2: Mean=36, Std=12  → KS-test p=0.75 (no drift)
             ├─ ...
             │
             └─ D30: Mean=22, Std=15 → KS-test p=0.002 (DRIFT!)
                     │
                     └─ Action: Alert team
                        "User age distribution shifted younger"
                        Investigate: app change? marketing campaign?
                        Response: Trigger model retraining
```

#### Model Accuracy Tracking Over Time

```
Week 1-4 (Baseline):
  Accuracy: [94.2%, 94.1%, 94.3%, 94.0%]
  Mean: 94.15%, Std: 0.12%
  Alert threshold: 94.15% - 2*0.12% = 91.91%
                   │
                   │ (anything below this triggers alert)
                   ▼

Weeks 5-8 (Production Monitoring):
  █ 94.1%    ✓ OK
  █ 93.9%    ✓ OK
  █ 93.8%    ✓ OK
  █ 92.1%    ✓ OK
  █ 91.8%    ✗ ALERT! Below threshold
             └─ Accuracy degradation detected
             └─ Check: data drift? feature failure?
             └─ Action: Retrain or investigate
```

---

## Observability for ML Services

### Textual Deep Dive

#### Internal Working Mechanism

Observability is the ability to understand system state through its outputs (logs, metrics, traces). For ML systems, observability means understanding both:

**Traditional Layer** (Infrastructure):
- Container health, network latency, GPU memory
- Service endpoint availability

**ML-Specific Layer**:
- Which model made which prediction
- Feature values passed to model
- Distribution of predictions
- Model inference time breakdown
- Where latency spent (feature lookup, inference, post-processing)

**Instrumentation Architecture**:
```
Model Serving Request
    ├─ Entry Point: Start trace (unique ID)
    │  trace_id = "abc-123"
    │
    ├─ Span 1: Feature Lookup
    │  │ feature_lookup.start()
    │  │ [Call Redis]
    │  │ duration: 2ms
    │  └─ feature_lookup.end()
    │
    ├─ Span 2: Inference
    │  │ inference.start()
    │  │ [GPU execution]
    │  │ model_prediction: 0.87
    │  │ duration: 8ms
    │  └─ inference.end()
    │
    ├─ Span 3: Post-processing
    │  │ post_process.start()
    │  │ [Apply business rules]
    │  │ duration: 1ms
    │  └─ post_process.end()
    │
    └─ Total: 11ms
       Log: {"trace_id": "abc-123", "spans": [...], "total_ms": 11}
```

#### Architecture Role

Observability forms the feedback mechanism for understanding production ML systems:

```
Request Flow (Observable)
    ↓
├─ Logs: What happened (feature values, predictions, errors)
│  └─ Centralized logging (ELK, Datadog, Splunk)
│
├─ Metrics: Summary statistics (accuracy, latency distribution)
│  └─ Time series database (Prometheus, VictorOps)
│
└─ Traces: Request path through system
   └─ Trace backend (Jaeger, DataDog)

All three combined answer:
"Why did this specific prediction take 150ms?"
"Why did accuracy drop Tuesday morning?"
"What caused this customer's poor experience?"
```

**Observability Stack**:
```
┌─────────────────────────────────┐
│   Application Code              │
│  (Model serving, feature lookup) │
└──────────────┬──────────────────┘
               │
         ┌─────▼──────┐
         │OpenTelemetry│(Instrumentation)
         │ Instrumentation│
         └─┬──────┬──────┬─┐
           │      │      │ │
    ┌──────▼┐ ┌───▼───┐ │ └─► Application Insights
    │Logs   │ │Metrics│ │
    │(ELK)  │ │(Prom) │ │
    └───────┘ └───────┘ │
                        └─► Traces (Jaeger)
```

#### Production Usage Patterns

**Pattern 1: End-to-End Trace for High-Latency Investigation**
```
SLA: Inference latency < 100ms (p99)
Alert: p99 latency = 250ms (BREACH!)

Investigation (using trace):
1. Identify affected requests (trace_id has duration > 250ms)
2. Drill down into spans:
   - feature_lookup: 150ms (unexpectedly slow!)
   - inference: 8ms (normal)
   - post_process: 1ms (normal)

3. Feature lookup spans detail:
   - Redis connection: 1ms
   - Redis fetch: 145ms (SLOW!)
   - Redis disconnect: 1ms

4. Root cause: Redis under memory pressure, evicting keys
5. Action: Evict older data, increase Redis memory
```

**Pattern 2: Debug Customer Issue**
```
Customer: "Recommendations were terrible last Tuesday"
Support ticket, request: customer_id = user_42

Search logs:
  user_id=user_42 AND (prediction OR recommendation)
  
Retrieve logs from Tuesday:
  ├─ Timestamp: 2024-04-02 14:23:45
  ├─ Model version: v2.1
  ├─ Features:
  │  ├─ user_age: 28
  │  ├─ user_purchase_value: 1200
  │  ├─ user_last_view_category: "electronics"
  │
  ├─ Prediction: 0.42 (low confidence)
  ├─ Recommended items: [item_x, item_y, item_z]
  │
  └─ Note: Data drift detected that morning (feature meant different users started using app)

Root cause: Model confident in old feature distribution, model degraded
Action: Retrain model to adapt to new demographics
```

**Pattern 3: Performance Regression Detection**
```
Latency metric p99:
  Week 1-4: 45ms (stable)
  Week 5: 52ms (slight increase)
  Week 6: 68ms (increasing trend)
  Week 7: 98ms (approaching SLA limit)

Observe:
- Model version unchanged (same inference time)
- Feature store latency increasing
- Reason: More features added, larger Redis payloads

Action: Optimize feature retrieval or add caching layer
```

#### DevOps Best Practices

**1. Structured Logging**
```json
{
  "timestamp": "2024-04-05T14:23:45.123Z",
  "level": "INFO",
  "service": "model-serving",
  "trace_id": "abc-123-def-456",
  "span_id": "span-42",
  "user_id": "user_7",
  "model_version": "v2.1",
  "event": "prediction_made",
  "fields": {
    "input_features": {"age": 32, "income": 75000},
    "model_output": 0.87,
    "serving_latency_ms": 11,
    "model_inference_ms": 8,
    "feature_lookup_ms": 2,
    "confidence": 0.95
  }
}
```

**2. Trace Correlation**
```
Every request gets unique trace_id (passed through system)
├─ Service A generates trace_id="t1"
├─ Calls Service B (passes trace_id)
├─ Service B continues same trace
├─ Calls Feature Store (passes trace_id)
└─ Feature Store logs with same trace_id

Result: Single search for trace_id="t1" shows entire request flow
```

**3. Sampling Strategy for High Volume**
```
If 1M predictions/day:
- Log 100% for production errors
- Log 10% for normal requests (sample)
- Log 100% for slow requests (> p99)
- Log features for audit trail (compliance)

Result: Manageable log volume while maintaining visibility
```

**4. Alerting on Observability Signals**
```
Alert if:
- Error rate > 1%
- Latency p99 > 100ms
- Accuracy drops > 3%
- Trace sampling rate drops (sign of high volume drop or issue)
```

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| **Insufficient logging** | Can't troubleshoot production issues | Log request details, predictions, features |
| **No trace correlation** | Can't follow request through services | Use distributed tracing (OpenTelemetry) |
| **Logs not searchable** | Logs exist but can't find them | Centralized logging, structured format |
| **High logging overhead** | Logging impacts model latency SLA | Sample high-volume logs, async logging |
| **No logs for errors** | Can't reproduce issues | Ensure errors logged before exit |
| **Model output not logged** | Can't correlate predictions to downstream issues | Always log prediction with trace_id |

### Practical Code Examples

#### OpenTelemetry Instrumentation

```python
# otel_instrumentation.py - Instrument ML model serving with OpenTelemetry
from opentelemetry import trace, metrics
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
import logging
import time
from functools import wraps

# Setup Jaeger exporter
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",
    agent_port=6831,
)
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

# Setup Prometheus metrics exporter
prometheus_reader = PrometheusMetricReader()
metrics.set_meter_provider(MeterProvider(metric_readers=[prometheus_reader]))

# Auto-instrument FastAPI and requests
FastAPIInstrumentor().instrument()
RequestsInstrumentor().instrument()

# Get tracer and meter
tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)

# Custom metrics
inference_duration = meter.create_histogram(
    "ml_inference_duration_ms",
    unit="ms",
    description="ML model inference duration"
)

feature_lookup_duration = meter.create_histogram(
    "feature_lookup_duration_ms",
    unit="ms",
    description="Feature store lookup duration"
)

class MLObservabilityDecorator:
    """Decorator for instrumenting ML inference with OpenTelemetry."""
    
    @staticmethod
    def instrumented_inference(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Create main trace span
            with tracer.start_as_current_span("inference_request") as span:
                span.set_attribute("model.version", "v2.1")
                span.set_attribute("model.name", "recommendation")
                
                # Extract user_id if available
                if 'user_id' in kwargs:
                    span.set_attribute("user.id", kwargs['user_id'])
                
                start_time = time.time()
                
                try:
                    result = func(*args, **kwargs)
                    
                    duration_ms = (time.time() - start_time) * 1000
                    span.set_attribute("inference.duration_ms", duration_ms)
                    span.set_attribute("inference.status", "success")
                    
                    # Record metric
                    inference_duration.record(duration_ms)
                    
                    return result
                
                except Exception as e:
                    span.set_attribute("inference.status", "error")
                    span.set_attribute("inference.error", str(e))
                    span.record_exception(e)
                    raise
        
        return wrapper
    
    @staticmethod
    def instrumented_feature_lookup(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Child span for feature lookup
            with tracer.start_as_current_span("feature_lookup") as span:
                span.set_context({"feature_store": "redis"})
                
                start_time = time.time()
                
                try:
                    result = func(*args, **kwargs)
                    
                    duration_ms = (time.time() - start_time) * 1000
                    span.set_attribute("feature_lookup.duration_ms", duration_ms)
                    span.set_attribute("feature_lookup.status", "hit")
                    
                    feature_lookup_duration.record(duration_ms)
                    
                    return result
                
                except Exception as e:
                    span.set_attribute("feature_lookup.status", "miss")
                    span.set_attribute("feature_lookup.error", str(e))
                    span.record_exception(e)
                    raise
        
        return wrapper

# Usage in model serving
class ModelServer:
    @MLObservabilityDecorator.instrumented_inference
    def predict(self, user_id, features):
        """
        Make prediction with full observability.
        Traces show: feature_lookup → inference time
        """
        # Lookup features
        user_features = self._get_features(user_id)
        
        # Inference
        prediction = self._run_inference(features)
        
        return prediction
    
    @MLObservabilityDecorator.instrumented_feature_lookup
    def _get_features(self, user_id):
        """Feature lookup will be traced as child span."""
        import redis
        r = redis.Redis()
        return r.get(f"user_features:{user_id}")
    
    def _run_inference(self, features):
        """Model inference."""
        import numpy as np
        # Simulate inference with some latency
        time.sleep(0.008)
        return 0.87
```

#### Structured Logging with Context

```python
# structured_logging.py - Structured logging for ML system
import json
import logging
import uuid
from datetime import datetime
from contextvars import ContextVar

# Context variables for trace correlation
trace_id_var: ContextVar[str] = ContextVar('trace_id', default='')
span_id_var: ContextVar[str] = ContextVar('span_id', default='')

class JSONFormatter(logging.Formatter):
    """Format logs as JSON for centralized logging."""
    
    def format(self, record):
        log_obj = {
            'timestamp': datetime.utcfromtimestamp(record.created).isoformat() + 'Z',
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'trace_id': trace_id_var.get(),
            'span_id': span_id_var.get(),
        }
        
        # Add exception info if present
        if record.exc_info:
            log_obj['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        if hasattr(record, 'extra_fields'):
            log_obj.update(record.extra_fields)
        
        return json.dumps(log_obj)

def setup_structured_logging():
    """Configure structured logging for entire application."""
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # JSON handler for structured logs
    json_handler = logging.StreamHandler()
    json_formatter = JSONFormatter()
    json_handler.setFormatter(json_formatter)
    logger.addHandler(json_handler)
    
    return logger

class MLLogger:
    """Logger for ML-specific events."""
    
    def __init__(self, logger):
        self.logger = logger
    
    def log_prediction(self, user_id, model_version, features, prediction, latency_ms):
        """Log a prediction with full context."""
        self.logger.info(
            "Prediction generated",
            extra={
                'extra_fields': {
                    'event': 'prediction',
                    'user_id': user_id,
                    'model_version': model_version,
                    'features': features,
                    'prediction': float(prediction),
                    'latency_ms': latency_ms,
                    'confidence': abs(prediction - 0.5) * 2
                }
            }
        )
    
    def log_feature_lookup(self, feature_name, latency_ms, status):
        """Log feature store lookup."""
        self.logger.info(
            "Feature lookup completed",
            extra={
                'extra_fields': {
                    'event': 'feature_lookup',
                    'feature': feature_name,
                    'latency_ms': latency_ms,
                    'status': status
                }
            }
        )
    
    def log_data_drift(self, feature_name, ks_statistic, pvalue):
        """Log data drift detection."""
        self.logger.warning(
            "Data drift detected",
            extra={
                'extra_fields': {
                    'event': 'data_drift',
                    'feature': feature_name,
                    'ks_statistic': ks_statistic,
                    'pvalue': pvalue,
                    'severity': 'high' if pvalue < 0.01 else 'medium'
                }
            }
        )

# Usage
if __name__ == "__main__":
    logger = setup_structured_logging()
    ml_logger = MLLogger(logger)
    
    # Set trace context (would come from request)
    trace_id_var.set(str(uuid.uuid4()))
    span_id_var.set("span-42")
    
    # Log a prediction
    ml_logger.log_prediction(
        user_id="user_7",
        model_version="v2.1",
        features={"age": 32, "income": 75000},
        prediction=0.87,
        latency_ms=11
    )
    
    ml_logger.log_feature_lookup(
        feature_name="user_age",
        latency_ms=2,
        status="hit"
    )
```

### ASCII Diagrams

#### Distributed Trace Through ML System

```
Request enters system: trace_id="xyz-789"

┌──────────────────────────────────────────────────┐
│ API Gateway Span (0-12ms)                        │
│ └─ Authenticate request: 1ms                   │
│ └─ Rate limit check: 1ms                       │
└──────────────┬───────────────────────────────────┘
               │ (passes trace_id)
               ▼
┌──────────────────────────────────────────────────┐
│ Feature Lookup Span (2-4ms)                      │
│ └─ Redis connect: 0.5ms                        │
│ └─ GET user_features:user_7: 2ms               │
│ └─ Deserialize: 0.5ms                          │
└──────────────┬───────────────────────────────────┘
               │ (passes trace_id)
               ▼
┌──────────────────────────────────────────────────┐
│ Model Inference Span (8-10ms)                    │
│ └─ Prepare batch: 0.5ms                        │
│ └─ GPU inference: 8ms                          │
│ └─ Post-process: 0.5ms                         │
└──────────────┬───────────────────────────────────┘
               │ (passes trace_id)
               ▼
┌──────────────────────────────────────────────────┐
│ Response Formatting (1-2ms)                      │
│ └─ JSON serialization: 1ms                     │
│ └─ Send response: 1ms                          │
└──────────────┬───────────────────────────────────┘
               │
         Total: 12-18ms
               │
        ▼ (all logged with trace_id=xyz-789)
        
Jaeger trace shows:
- Full timeline of spans
- Where latency spent
- Any errors with full context
```

#### Observability Stack Integration

```
┌──────────────────────────────────┐
│   Model Serving Container        │
│  (OpenTelemetry instrumented)    │
└──────┬───────────┬───────────────┘
       │           │
    ┌──▼────┐  ┌───▼──────┐
    │Logs   │  │Metrics   │
    │       │  │          │
 ┌──▼────┐  │  │┌────────┐│
 │Event: │  │  ││Counter:││
 │predict│  │  ││requests││
 │ion    │  │  │└────────┘│
 └───────┘  │  │┌────────┐│
            │  ││Histogram:
            │  ││latency  │
            │  │└────────┘│
            │  └────┬────┬┘
            │       │    │
         ┌──▼─┐  ┌──▼─┐ │
         │ELK │  │Prom│ │
         │Stack│  │etheus
         └────┘  └────┘ │
                        │
                    ┌───▼──┐
                    │Traces│
                    │(Jaer │
                    │er)   │
                    └──────┘

Together answer:
"Why was THIS prediction slow?"
"What changed across all metrics?"
"What caused this customer issue?"
```

---

## Data & Model Validation

### Textual Deep Dive

#### Internal Working Mechanism

Validation in ML pipelines ensures data and models meet quality standards before production impact. Unlike software validation (unit tests prove correctness), ML validation is probabilistic (statistical tests give confidence).

**Three Validation Layers**:

**Layer 1: Data Validation** (Before Model Training)
```
Raw Data → Schema Check
  ├─ Expected columns present
  ├─ Data types correct
  ├─ No unexpected nulls
  └─ Values in expected ranges

  ↓ (if passes)

Statistical Validation
  ├─ Distribution reasonable (KS-test against baseline)
  ├─ No obvious anomalies (z-score outlier detection)
  ├─ Sample sizes sufficient (>1000 samples)
  └─ No data leakage (future labels in features)

  ↓ (if passes)

Feature Consistency
  ├─ Features computed identically to training
  ├─ No NaN/inf values in features
  ├─ Feature ranges match training distribution
  └─ All required features present
```

**Layer 2: Model Validation** (Before Deployment)
```
Trained Model → Baseline Comparison
  ├─ Accuracy >= previous model
  ├─ Fairness metrics acceptable
  ├─ No catastrophic failures
  └─ Performance on held-out test set

  ↓ (if passes)

Stress Testing
  ├─ Handle adversarial inputs
  ├─ Perform under load (latency, throughput)
  ├─ Handle missing features gracefully
  └─ Graceful degradation when features unavailable

  ↓ (if passes)

Shadow Testing
  ├─ Run against production traffic (no user impact)
  ├─ Compare predictions to production model
  ├─ Track metrics over 24-48 hours
  └─ Decision: promote or reject
```

**Layer 3: Prediction Validation** (At Serving Time)
```
Incoming Prediction Request
  ├─ Input schema valid
  ├─ Features in expected ranges
  ├─ No missing required features
  └─ Model selected based on input

  ↓ Inference ↓

Post-prediction Validation
  ├─ Output in valid range (e.g., 0-1 for probability)
  ├─ Confidence above threshold
  ├─ Prediction not anomalous (z-score)
  └─ Return result or fallback
```

#### Architecture Role

Validation gates control model promotion and ensure quality boundaries:

```
Development Pipeline:
Data → Validation Gates → Training → Validation Gates → Model Registry
          (schema, stats)                (accuracy, fairness)

Serving Pipeline:
Request → Validation → Inference → Validation → Response
        (schema)         (outlier detection)
```

#### Production Usage Patterns

**Pattern 1: Automated Promotion to Production**
```
Day 0 (Model Training):
1. Data validation passes: ✓
2. Train model on validated data
3. Compute metrics on held-out test set:
   - Accuracy: 94.5% (baseline: 92.0%, improvement: ✓)
   - Fairness (group 1): 94.1% (baseline: 94.2%, acceptable: ✓)
   - Fairness (group 2): 94.2% (baseline: 93.5%, improvement: ✓)
4. All gates pass: AUTO-PROMOTE

Day 1-3 (Shadow Testing):
5. New model shadows production with 0 user impact
6. Collect metrics: recommendation CTR, conversion rate
7. Compare to production model
8. If metrics better: Run day 4, else rollback
```

**Pattern 2: Great Expectations Data Validation**
```
{
  "expectation": "table.does_not_have_nulls",
  "column": "user_id",
  
  "result": {
    "element_count": 1000234,
    "unexpected_count": 2,  # 2 null values
    "unexpected_percent": 0.0002
  },
  
  # Alert because thresholds exceeded
  "status": "failure"
}

Action: Investigate data source, data quality issue
```

**Pattern 3: Real-time Input Validation**
```
Request arrives with features:
{
  "user_age": 218,  # Out of range! (max expected: 120)
  "user_income": "unknown",  # Should be number
  "session_id": "abc123"  # OK
}

Validation result:
- user_age: OUT OF RANGE (z-score: 8.5)
- user_income: WRONG TYPE

Response:
- Log: potential data quality issue
- Action: Use defaults or fallback model
- Alert: "Input validation failed for 5% of requests"
```

#### DevOps Best Practices

**1. Validation Pipelines as Code**
```yaml
# validation_rules.yaml
data_validation:
  schema:
    columns:
      - name: user_id
        type: integer
        nullable: false
      - name: user_age
        type: integer
        min: 18
        max: 120
  
  statistics:
    - column: user_age
      distribution: normal
      expected_mean: 38
      expected_std: 12
      ks_test_pvalue_threshold: 0.05
  
  integrity:
    - no_duplicate_keys: [user_id, timestamp]
    - referential_integrity:
        user_id in users_table.id

model_validation:
  performance:
    - metric: accuracy
      threshold: 0.90
      segment: all
    
    - metric: accuracy
      threshold: 0.85
      segment: low_income_users
  
  stress_tests:
    - missing_feature_handling: fallback_model
    - high_latency_acceptable: true
    - concurrent_requests: 1000
```

**2. Statistical Testing Framework**
```
For data drift detection:
- Kolmogorov-Smirnov test (p-value < 0.05 = drift)
- Population Stability Index (PSI > 0.1 = drift)
- Chi-square test for categorical features

For fairness:
- Demographic parity: P(prediction=1 | group A) ≈ P(prediction=1 | group B)
- Equalized odds: TPR and FPR equal across groups
- Calibration: predicted probability matches actual rate
```

**3. Continuous Validation**
```
Every hour:
- Data validation: run on last hour's data
- Model validation: compute accuracy on recent predictions
- Drift detection: KS-test on features
- Alert if: failures exceed threshold

Every day:
- Fairness analysis: accuracy per demographic
- Feature importance analysis
- Feature correlation check
- Outlier analysis

Every week:
- Trend analysis: metrics over time
- Retraining trigger assessment
- Model comparison: current vs previous
```

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| **No validation gates** | Bad data/models reach production | Define gating criteria, enforce automation |
| **Validation too strict** | Never promote new models | Set realistic thresholds based on business needs |
| **Validation too loose** | Quality degrades slowly | Monitor metrics closely, alert on regression |
| **Feature/label leakage** | Model appears accurate but isn't | Validate temporal boundaries, feature review |
| **Missing edge cases** | Model fails on unexpected inputs | Adversarial testing, input validation |
| **No baseline for comparison** | Can't assess if new model is better | Maintain previous model version |

### Practical Code Examples

#### Great Expectations Data Validation

```python
# data_validation.py - Great Expectations for data quality
from great_expectations.dataset import SqlAlchemyDataset
import great_expectations as ge

def validate_training_data(database_url, table_name):
    """Validate training data before model training."""
    
    # Load data
    df = ge.read_csv(f"s3://ml-data/{table_name}.csv")
    
    # Schema validation
    df.expect_column_to_exist("user_id")
    df.expect_column_to_exist("user_age")
    df.expect_column_to_exist("target")
    
    df.expect_column_values_to_be_in_set("target", [0, 1])
    df.expect_column_values_to_be_of_type("user_age", "int")
    
    # Data quality checks
    df.expect_column_values_to_be_between(
        "user_age",
        min_value=18,
        max_value=120
    )
    
    df.expect_column_values_to_not_be_null("user_id")
    df.expect_column_values_to_not_be_null("target")
    
    # Statistical checks
    df.expect_column_mean_to_be_between(
        "user_age",
        min_value=30,
        max_value=45
    )
    
    # Uniqueness check
    df.expect_column_values_to_be_unique("user_id")
    
    # Uniqueness of combination
    df.expect_compound_columns_to_be_unique(
        column_list=["user_id", "timestamp"]
    )
    
    # Run validation
    results = df.validate(return_json=True)
    
    if not results["success"]:
        print("Data validation FAILED")
        for result in results["results"]:
            if not result["success"]:
                print(f"  Failed: {result['expectation_config']['expectation_type']}")
                print(f"    Message: {result['result']}")
        raise ValueError("Training data validation failed")
    
    print("✓ Data validation PASSED")
    return df

# Usage
if __name__ == "__main__":
    df = validate_training_data(
        database_url="postgresql://user:pass@host/db",
        table_name="training_data_2024"
    )
    print(f"Validated {len(df)} rows")
```

#### Model Validation Pipeline

```python
# model_validation.py - Comprehensive model validation before deployment
import numpy as np
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
from scipy import stats

class ModelValidator:
    """Validate model before production promotion."""
    
    def __init__(self, model, test_data, baseline_metrics, thresholds):
        """
        Args:
            model: Trained model to validate
            test_data: (X_test, y_test) tuple
            baseline_metrics: Previous model's metrics
            thresholds: Minimum acceptable metrics
        """
        self.model = model
        self.X_test, self.y_test = test_data
        self.baseline_metrics = baseline_metrics
        self.thresholds = thresholds
        self.validation_results = {}
    
    def validate_performance(self):
        """Validate model accuracy meets thresholds."""
        y_pred = self.model.predict(self.X_test)
        
        accuracy = accuracy_score(self.y_test, y_pred)
        precision = precision_score(self.y_test, y_pred)
        recall = recall_score(self.y_test, y_pred)
        f1 = f1_score(self.y_test, y_pred)
        
        self.validation_results['performance'] = {
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1': f1
        }
        
        # Check against baseline
        if accuracy >= self.baseline_metrics['accuracy']:
            print(f"✓ Accuracy improved: {accuracy:.4f} vs {self.baseline_metrics['accuracy']:.4f}")
            return True
        else:
            print(f"✗ Accuracy degraded: {accuracy:.4f} vs {self.baseline_metrics['accuracy']:.4f}")
            return False
    
    def validate_fairness(self, protected_attribute_index):
        """Validate model fairness across demographic groups."""
        y_pred = self.model.predict(self.X_test)
        
        # Split by protected attribute
        unique_values = np.unique(self.X_test[:, protected_attribute_index])
        fairness_results = {}
        
        for value in unique_values:
            mask = self.X_test[:, protected_attribute_index] == value
            accuracy = accuracy_score(self.y_test[mask], y_pred[mask])
            fairness_results[f"group_{value}"] = accuracy
        
        self.validation_results['fairness'] = fairness_results
        
        # Check: max difference should be < threshold
        accuracies = list(fairness_results.values())
        max_diff = max(accuracies) - min(accuracies)
        
        if max_diff < 0.05:
            print(f"✓ Fairness acceptable: max diff {max_diff:.4f}")
            return True
        else:
            print(f"✗ Fairness concern: max diff {max_diff:.4f}")
            return False
    
    def validate_no_catastrophic_failures(self):
        """Ensure model doesn't have extreme predictions."""
        y_pred = self.model.predict_proba(self.X_test)[:, 1]
        
        # Check: not all predictions near 0 or 1
        near_extremes = (y_pred < 0.1) | (y_pred > 0.9)
        pct_extreme = near_extremes.sum() / len(y_pred)
        
        if pct_extreme < 0.1:  # Less than 10% near extremes
            print(f"✓ Prediction distribution reasonable: {pct_extreme:.2%} extreme")
            return True
        else:
            print(f"✗ Too many extreme predictions: {pct_extreme:.2%}")
            return False
    
    def validate_feature_stability(self):
        """Check model inputs are stable."""
        mean_values = self.X_test.mean(axis=0)
        
        # Compare to training distribution (should be similar)
        # In production, would compare to training stats
        print(f"✓ Feature statistics: {mean_values}")
        
        return True
    
    def run_all_validations(self):
        """Run all validation checks."""
        print("=" * 50)
        print("Running Model Validation Pipeline")
        print("=" * 50)
        
        checks = [
            ("Performance", self.validate_performance),
            ("Fairness", self.validate_fairness, [0]),  # Attribute index 0
            ("Catastrophic Failures", self.validate_no_catastrophic_failures),
            ("Feature Stability", self.validate_feature_stability),
        ]
        
        passed = 0
        failed = 0
        
        for check_name, check_func, *args in checks:
            try:
                result = check_func(*args) if args else check_func()
                if result:
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                print(f"✗ {check_name} error: {e}")
                failed += 1
        
        print("=" * 50)
        print(f"Results: {passed} passed, {failed} failed")
        print("=" * 50)
        
        return failed == 0

# Usage
if __name__ == "__main__":
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.datasets import load_iris
    from sklearn.model_selection import train_test_split
    
    # Load data
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.3, random_state=42
    )
    
    # Train model
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(X_train, y_train)
    
    # Validate
    validator = ModelValidator(
        model=model,
        test_data=(X_test, y_test),
        baseline_metrics={'accuracy': 0.90},
        thresholds={'accuracy': 0.85}
    )
    
    is_valid = validator.run_all_validations()
    print(f"Model suitable for production: {is_valid}")
```

#### Input Validation Middleware

```python
# input_validation.py - Validate serving inputs
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, validator
import numpy as np

app = FastAPI()

class PredictionRequest(BaseModel):
    user_id: str
    user_age: int
    user_income: float
    
    @validator('user_age')
    def validate_age(cls, v):
        if v < 18 or v > 120:
            raise ValueError('user_age must be between 18 and 120')
        return v
    
    @validator('user_income')
    def validate_income(cls, v):
        if v < 0 or v > 1_000_000:
            raise ValueError('user_income must be between 0 and 1,000,000')
        return v

class InputValidator:
    """Validate inputs at serving time."""
    
    def __init__(self, feature_stats):
        """
        Args:
            feature_stats: {feature: {mean, std, min, max}}
        """
        self.feature_stats = feature_stats
    
    def detect_outliers(self, features):
        """Detect anomalous feature values using z-score."""
        anomalies = {}
        
        for feature, value in features.items():
            if feature not in self.feature_stats:
                continue
            
            stats = self.feature_stats[feature]
            z_score = abs((value - stats['mean']) / stats['std'])
            
            if z_score > 3:  # 3-sigma = very anomalous
                anomalies[feature] = {
                    'value': value,
                    'z_score': z_score,
                    'expected_range': f"({stats['mean']-3*stats['std']}, {stats['mean']+3*stats['std']})"
                }
        
        return anomalies

@app.post("/predict")
async def predict(request: PredictionRequest):
    """Make prediction with input validation."""
    
    # Schema validation (automatic via Pydantic)
    # Range validation (via Pydantic validators above)
    
    # Outlier detection
    validator = InputValidator({
        'user_age': {'mean': 38, 'std': 12, 'min': 18, 'max': 120},
        'user_income': {'mean': 65000, 'std': 45000, 'min': 0, 'max': 1_000_000}
    })
    
    features = {
        'user_age': request.user_age,
        'user_income': request.user_income
    }
    
    anomalies = validator.detect_outliers(features)
    
    if anomalies:
        print(f"Anomalies detected: {anomalies}")
        # Could use fallback model or flag for review
    
    # Made it here = valid input
    # Now call model
    prediction = 0.87  # Placeholder
    
    return {
        "user_id": request.user_id,
        "prediction": prediction,
        "anomalies": anomalies
    }
```

### ASCII Diagrams

#### Data Validation Pipeline

```
Raw Data (CSV, Database)
        │
        ▼
┌─────────────────────────────────┐
│   Schema Validation              │
│  ├─ Columns exist               │
│  ├─ Data types correct          │
│  └─ No unexpected nulls (>5%)  │
└────────┬────────────────────────┘
         │ PASS?
         ├─ YES ↓
         └─ NO  → FAIL (alert, block)
                 
         ▼
┌─────────────────────────────────┐
│  Statistical Validation          │
│  ├─ Distribution reasonable     │
│  │  (KS-test vs baseline)       │
│  ├─ Mean ≈ training mean       │
│  ├─ Std ≈ training std         │
│  └─ No extreme outliers        │
└────────┬────────────────────────┘
         │ PASS?
         ├─ YES ↓
         └─ NO  → FAIL (investigate)
                 
         ▼
┌─────────────────────────────────┐
│  Integrity Checks                │
│  ├─ No duplicate keys           │
│  ├─ Referential integrity OK    │
│  └─ Temporal ordering correct   │
└────────┬────────────────────────┘
         │ PASS?
         ├─ YES ↓
         └─ NO  → FAIL (data issue)
                 
         ▼
    READY FOR USE
    Feed to model training
```

#### Model Promotion Gate

```
Trained Model
        │
        ▼
┌───────────────────────────────────────┐
│     Model Validation Gate             │
├───────────────────────────────────────┤
│                                       │
│ 1. Accuracy Test                     │
│    New: 94.5% > Baseline: 92%?     │
│    ✓ PASS                            │
│                                       │
│ 2. Fairness Test                     │
│    Group A: 94.1% (base: 94.2%)     │
│    Group B: 94.2% (base: 93.5%)     │
│    Max diff: 0.1% < threshold 5%    │
│    ✓ PASS                            │
│                                       │
│ 3. Robustness Test                   │
│    Missing features handled?          │
│    Extreme inputs handled?           │
│    ✓ PASS                            │
│                                       │
│ All Gates Pass? → PROMOTE           │
└───────────────────────────────────────┘
        │
        ├─ YES ↓
        │   Model Registry v2.1 (ready for shadow test)
        │
        └─ NO ↓
            Reject (debug and retrain)
```

---

## Hands-on Scenarios

### Scenario 1: Debug Production Model Degradation

**Situation**: Model accuracy dropped from 94% to 89% overnight.

**Available Tools**: 
- Prometheus metrics (predictions/hour)
- ELK logs (prediction details)
- Feature store (offline check)

**Investigation Steps**:
1. Check Prometheus: Time series shows drop occurred at 2024-04-02 08:00 UTC
2. Feature store data drift detection: KS-stat significant for "user_age" feature
3. ELK logs for predictions made immediately after drop: user_age mean shifted from 38 to 22
4. Hypothesis: Marketing campaign targeted younger demographic (18-25)
5. Validation: Training data = age 18-70, current = age 18-30 (DRIFT!)
6. Root cause: Model trained on balanced age distribution, now skewed to younger users
7. Action: Retrain model using recent data with correct age distribution
8. Prevention: Add age distribution monitoring, alert on shift >5%

**Production Best Practices Applied**:
- Distributed tracing identified exact time of degradation
- Feature monitoring caught root cause (data drift)
- Automatic rollback triggered by accuracy SLA breach
- Post-mortem: Added demographic diversity check to training validation

---

### Scenario 2: High-Availability Model Serving During Deployment

**Situation**: Need to deploy new model version to 50 production instances serving 100K requests/sec with zero downtime.

**Architecture Context**:
```
Load Balancer (3 zones)
    ↓
Service Mesh (Istio)
    ↓
Model Serving Pods (v1.5 active, v2.0 being deployed)
    └─ Redis feature cache (online features)
    └─ PersistentVolume (model artifacts)
```

**Deployment Strategy** (Canary Rollout):

**Phase 1: Preparation** (5 minutes)
1. New model v2.0 image pushed to container registry
2. Pre-warm model in staging cluster (ensure it loads, no errors)
3. Health checks: model responds to inference requests
4. Compare accuracy vs production on shadow traffic (1% sampled)

**Phase 2: Gradual Traffic Shift** (30 minutes total)
- Minute 0-5: Route 5% traffic to v2.0
  - Monitor: latency, error rate, predictions
  - Alert criteria: error rate > 1%, latency p99 > SLA
- Minute 5-10: If metrics healthy, shift to 25%
  - Monitor same metrics, compare predictions to v1.5
- Minute 10-20: If still healthy, shift to 50%
- Minute 20-30: If metrics stable, shift to 100%

**Phase 3: Rollback Readiness** (if needed)
- If error rate spikes: Automatic rollback to v1.5
- If accuracy drops > 2%: Automatic rollback
- Manual override available for human review

**Execution Commands**:
```bash
# Deploy new model
kubectl set image deployments/model-serving-api \
  serving-api=company-registry.azurecr.io/model-serving-api:v2.0 \
  --record \
  -n ml-serving

# Monitor deployment
kubectl rollout status deployment/model-serving-api -n ml-serving

# If needed, rollback
kubectl rollout undo deployment/model-serving-api -n ml-serving

# Verify traffic distribution (using Istio)
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: model-serving-vs
  namespace: ml-serving
spec:
  hosts:
  - model-serving-api
  http:
  - match:
    - headers:
        user-agent:
          prefix: "CanaryTest"
    route:
    - destination:
        host: model-serving-api
        subset: v2-0
        port:
          number: 8000
      weight: 100
  - route:
    - destination:
        host: model-serving-api
        subset: v1-5
        port:
          number: 8000
      weight: 95
    - destination:
        host: model-serving-api
        subset: v2-0
        port:
          number: 8000
      weight: 5
EOF
```

**Production Best Practices**:
- Traffic shift gradual (avoid thundering herd)
- Automated health checks prevent bad deployments
- Feature flags enable instant model switching
- Comprehensive metrics enable quick issue detection
- Rollback testing performed in staging first

---

### Scenario 3: Feature Store Scalability Crisis

**Situation**: Online feature store (Redis) hitting memory limits (90% utilization). Feature lookup latency increasing (was 2ms, now 15ms). Predictions hitting SLA (p99 latency > 100ms).

**Root Cause Analysis**:
1. Monitor Redis: `INFO memory` shows 15GB/16GB used
2. Check eviction policy: `MAXMEMORY_POLICY: allkeys-lru` (aggressive eviction)
3. Query log analysis: 50% cache misses (not normal, was 2%)
4. Feature correlation: 10 new features added last week, 2x memory increase

**Short-term Fix** (emergency, 1-2 hours):
```bash
# Increase Redis memory limit (if available)
kubectl set resources statefulset redis-cache \
  --limits=memory=32Gi \
  -n ml-serving

# Reduce feature TTL for low-priority features
redis-cli CONFIG SET MAXMEMORY 32GB
redis-cli CONFIG SET MAXMEMORY-POLICY allkeys-lru

# Clear low-frequency features
redis-cli DEBUG OBJECT feature:category:historical_engagement  # Check frequency

# Add second Redis replica for read scaling
kubectl scale statefulset redis-cache --replicas=3 -n ml-serving
```

**Medium-term Solution** (1-2 weeks):
1. Analyze feature store usage:
   - Which features most accessed?
   - Which features can be computed on-demand?
   - Which features have looser latency requirements?

2. Implement tiered storage:
   ```yaml
   # Hot features (< 1ms latency required)
   - Redis cache: User embeddings, recent activity
   
   # Warm features (< 10ms latency acceptable)
   - Secondary cache (local pod memory): Item embeddings, user demographics
   
   # Cold features (computed on-demand)
   - Batch pre-computed features: Historical aggregates
   ```

3. Feature priority-based eviction:
   ```python
   # Low priority
   feature_ttl = {
       "user_historical_behavior_v1": 3600,  # 1 hour
       "item_old_engagement_metric": 1800,   # 30 min
   }
   
   # High priority
   feature_ttl = {
       "user_embedding": 86400,     # 24 hours
       "user_recent_purchases": 300, # 5 min (fresh)
   }
   ```

4. Feature store architecture redesign:
   - Separate Redis instances by feature category
   - Implement sharding (feature A → Redis 1, feature B → Redis 2)
   - Add Memcached layer for frequently accessed, large-size features

**Long-term Strategy** (1-3 months):
- Evaluate managed feature stores (Tecton, Hopsworks)
- Implement local feature cache in model serving pods
- Optimize feature computation (batch < 1ms lookups)

**Production Best Practices**:
- Monitor Redis memory before crisis (alert at 80%)
- Implement feature lifecycle management
- Benchmark feature store performance
- Have tiered storage strategy ready

---

### Scenario 4: Kubernetes Clustering for Multi-Tenant ML Workloads

**Situation**: Company has 15 ML teams, 300+ models, competing for GPU resources. Some teams monopolizing GPUs, others starved.

**Problem Manifestation**:
- Team A training job: 8 GPUs allocated, only using 2 (wasteful)
- Team B inference: Waiting in queue for GPU (service degraded)
- Team C hyperparameter tuning: Unable to parallelize (no resources)

**Solution: Kubernetes Resource Quotas & Priorities**

**Step 1: Namespace Isolation**
```yaml
# Create namespace per team
apiVersion: v1
kind: Namespace
metadata:
  name: team-a-ml
---
# Create resource quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a-ml
spec:
  hard:
    requests.nvidia.com/gpu: "4"  # Max 4 GPUs per team
    limits.nvidia.com/gpu: "4"
    requests.cpu: "32"
    limits.memory: 128Gi
    pods: "100"
```

**Step 2: Priority Classes**
```yaml
# High priority (production inference)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: production-inference
value: 1000
globalDefault: false
description: "Production inference workloads (SLA critical)"
---
# Medium priority (training)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: model-training
value: 500
globalDefault: false
description: "Model training jobs"
---
# Low priority (experimentation)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: experimentation
value: 100
globalDefault: false
description: "Experimental workloads (can be preempted)"
```

**Step 3: Pod Disruption Budgets**
```yaml
# Protect inference pods during cluster updates
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: inference-pdb
  namespace: ml-serving
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: model-serving
```

**Step 4: Monitoring & Governance**
```bash
# Show GPU utilization per team
kubectl top nodes | grep -i gpu

# Check resource quota usage
kubectl describe resourcequota team-a-quota -n team-a-ml

# Monitor priority class distribution
kubectl get pods -A -o json | jq '.items[] | {name: .metadata.name, priority: .spec.priorityClassName, namespace: .metadata.namespace}'
```

**Production Best Practices**:
- Team isolation via namespaces prevents cross-contamination
- Priority classes ensure SLA-critical workloads get resources
- Resource quotas prevent resource starvation
- Monitoring shows resource utilization by team
- Chargeback possible (bill teams based on GPU hours)

---

### Scenario 5: MLOps Incident: Complete Pipeline Failure

**Situation**: Monday morning, 10 AM. Entire ML inference pipeline down. Customers cannot get recommendations. On-call engineer paged.

**Timeline**:

**T+0 min (10:00 AM)**: Alert fires
- Alert: "Model serving error rate > 50%"
- Wake up on-call engineer

**T+5 min**: Investigation
```bash
# Check pod status
kubectl get pods -n ml-serving
# Result: 0/3 pods running, CrashLoopBackOff

# Check logs
kubectl logs -f deployment/model-serving -n ml-serving --tail=100
# Error: "Failed to load model from /models/default/model.pt: File not found"

# Check model mount
kubectl exec -it pod/model-serving-api-xyz -n ml-serving -- ls -la /models/
# Result: Directory empty (shared storage issue)
```

**T+10 min**: Root cause identified
```bash
# Check persistent volume
kubectl get pv,pvc -n ml-serving
# Result: PVC shows "Pending" (storage provisioning failed)

# Check storage class
kubectl get storageclass
# Result: "fast-ssd" showing provisioning errors

# Check events
kubectl describe pvc model-storage-pvc -n ml-serving
# Event: StorageClass quota exceeded (company hit account storage limit)
```

**T+15 min**: Immediate mitigation
```bash
# Rollback to previous working model (cached in pod)
kubectl set env deployment/model-serving \
  MODEL_PATH=/cache/model_v1.5/ \
  -n ml-serving

# Restart pods with cached model
kubectl rollout restart deployment/model-serving -n ml-serving

# Check recovery
kubectl get pods -n ml-serving -w
# Pods running again, error rate dropping

# Verify prediction accuracy
kubectl port-forward svc/model-serving-api 8000:8000 -n ml-serving
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [...]}'
# Result: Predictions working (temporary fix deployed)
```

**T+45 min**: Permanent fix
```bash
# Increase storage quota with cloud provider
az storage account update \
  --name mldata \
  --resource-group ml-prod \
  --set kind=BlobStorage \
  --set sku.name=Premium_LRS

# Scale back model file size (compress, quantize)
# Remove old model versions from persistent storage
# Trigger new model upload with increased quota

# Re-enable automatic model loading
kubectl set env deployment/model-serving \
  MODEL_PATH=/models/default \
  -n ml-serving

# Monitor storage usage
kubectl top pv

# Alert on storage >= 80%
kubectl patch pvc model-storage-pvc -n ml-serving -p \
  '{"metadata":{"annotations":{"storage-alert-threshold":"0.8"}}}'
```

**T+2 hours**: Post-incident

**Incident Summary**:
- Downtime: 45 minutes
- Root cause: Storage quota exceeded
- Prevention: Implement automated storage cleanup, quota monitoring

**Production Best Practices Applied**:
- Quick rollback to known-good state
- Cached fallback available
- Clear alert indicating issue
- Comprehensive documentation for on-call runbook
- Follow-up: Storage quota alerts and auto-cleanup

---

## Most Asked Interview Questions

### 1. Model Versioning & Promotion Strategy

**Question**: "You have 50 models in production, each with 3-4 versions in different stages (development, staging, canary, production). How do you manage versions and ensure safe promotion through stages?"

**Expected Answer** (Senior Engineer):
- Model Registry (MLflow, Hugging Face Hub) stores all versions with metadata
- Metadata includes: training date, data version, accuracy metrics, hyperparameters, Git commit hash
- Promotion gates at each stage:
  - Dev→Staging: Passes unit tests, data validation
  - Staging→Canary: Performance >= baseline model
  - Canary→Production: Canary runs 24h, no accuracy regression
- Automated gates + manual approval for production
- Quick rollback mechanism (previous version always available)
- Model lineage tracking (which model trained on which data by which person)
- Handles: A/B tests, shadow testing, gradual traffic shifts

**Follow-up**: "What if a model passes all gates but fails spectacularly on Monday morning?"
- Incident response: Immediate rollback to previous version
- Root cause analysis: Check data drift, feature availability, input edge cases
- Prevention: Add additional validation gates, expand test coverage
- Post-mortem: Document, update monitoring, retrain on edge cases

---

### 2. Feature Store Consistency

**Question**: "Your feature store has both online (Redis) and offline (BigQuery) stores. Last week, a model was retrained on offline features, but serving used different features from online store. How do you prevent training-serving skew?"

**Expected Answer** (Senior Engineer):
- Feature definitions must be 100% identical between offline and online
- Shared code: Single Python function `compute_user_features()` used in both workflows
- Version control: Feature definitions stored in Git with version numbers
- Consistency tests: Nightly comparison of sample features from online vs offline
  - Alert if values differ > tolerance (5% for low-volume features, 1% for high-volume)
- Time-travel capability: Offline store can retrieve features as they existed on training date
- Backward compatibility: New feature versions don't break old models
- Deployment sync: Feature updates deployed simultaneously to offline and online
- Fallback: If online features unavailable, model can gracefully degrade

**Follow-up**: "What if your consistency test catches a mismatch?"
- Immediate investigation: Which feature? When did mismatch start?
- Pause serving: If critical, route to previous model version or fallback
- Fix and backtest: Correct the feature logic, recompute offline historical data
- Re-validate: Run consistency test, confirm match before resuming

---

### 3. Autoscaling Strategy for Variable Load

**Question**: "Your model serving deployment experiences 10x traffic variation throughout the day (peak: midnight, valley: 6 AM). Design an autoscaling strategy with SLA: p99 latency < 100ms, never > 500ms."

**Expected Answer** (Senior Engineer):
- Horizontal Pod Autoscaler with multiple metrics:
  - CPU utilization: Scale up at 75%, down at 25%
  - Latency-based: p99 > 80ms → scale up immediately
  - Request rate: Scale up if queue depth increasing
- Predictive scaling (ML-based if data available):
  - Train model on historical traffic patterns
  - Predict peak times, pre-scale proactively
- Configuration:
  ```yaml
  maxReplicas: 100  # Never exceed 100 pods
  minReplicas: 5    # Always maintain 5 for base load
  targetCPUUtilizationPercentage: 75
  scaleDownStabilization: 300s  # Wait 5 min before scaling down
  scaleUpStabilization: 0s      # Scale up immediately
  ```
- Pod Disruption Budget: Ensure >= 2 replicas during cluster upgrades
- Burst capacity: Reserve capacity for +50% load spikes
- Cost optimization: Use spot instances for non-critical replicas, preemptible for non-inference

**Follow-up**: "What if your metrics-based scaler is too slow?"
- Implement predictive scaling (forecast traffic)
- Use scheduled scaling for known patterns
- Add GPU-specific scaling (GPUs take longer to acquire)
- Monitor: Warning when approaching max replicas

---

### 4. Data Drift & Model Retraining

**Question**: "Your drift detection system alerted on 5 features simultaneously. Before retraining, how do you investigate whether to retrain the entire model or just investigate?"

**Expected Answer** (Senior Engineer):
- Not all drift requires retraining:
  - **Natural drift** (seasonal patterns): Model adapts, no action needed
  - **Concept drift** (relationships changed): Requires immediate retraining
  - **Data quality issues**: Fix source, don't retrain
  
- Investigation process:
  1. Check correlation: Are 5 features related? Single root cause?
     - Example: All price-related features drift → inflation, natural
  2. Impact assessment: Does drift affect model accuracy?
     - Shadow model on recent data: Check if accuracy degrades
  3. Fairness analysis: Is drift concentrated in one demographic? (bias risk)
  4. Business impact: How critical is this model?
     - Production recommendation: Investigate immediately
     - Experimental: Defer investigation
  
- Decision tree:
  - Accuracy degraded + drift detected → Retrain immediately
  - Accuracy stable + drift detected → Scheduled retrain (weekly)
  - Accuracy degraded + no drift detected → Investigate (data leak? model bug?)
  - Accuracy stable + no drift detected → Continue monitoring

- Retraining strategy:
  - Retrain on last N weeks data (not entire history)
  - Validate new model accuracy >= baseline
  - Deploy as canary with A/B testing
  - Monitor against production for 48 hours

**Follow-up**: "What if retraining doesn't fix the issue?"
- Model may need redesign (features don't capture new patterns)
- Collect ground truth labels from recent period
- Debug: Are predictions still relevant? (proxy metrics?)
- Consider: Is concept drift permanent or temporary?

---

### 5. Model Serving Framework Selection

**Question**: "You need to serve 3 models simultaneously: TensorFlow 2.9, PyTorch 1.12, and ONNX. Latency SLA: p99 < 50ms. Storage: <2GB. How do you choose a serving framework?"

**Expected Answer** (Senior Engineer):
- Compare options:

| Framework | Multi-framework | Latency | GPU Efficiency | Memory | Complexity |
|-----------|-----------------|---------|---|---|---|
| TFServing | No | Good | Very Good | Medium | Medium |
| TorchServe | No | Good | Good | Medium | Medium |
| Triton | Yes | Excellent | Excellent | Low | High |
| KServe | Yes | Good | Good | Medium | High |
| ONNX Runtime | Yes | Excellent | Good | Very Low | Low |

- Decision process:
  1. Multi-framework requirement → Must support all 3 formats
  2. Latency critical → Triton (best optimization) or ONNX Runtime (simplest)
  3. Memory constraint → ONNX Runtime (smallest footprint)
  4. Storage constraint → Quantize models, remove unused weights
  
- Recommendation: **ONNX Runtime** (meets all constraints)
  - Supports all 3 frameworks (convert models to ONNX)
  - Fastest inference (optimized kernels)
  - Smallest memory footprint
  - Easiest deployment (single binary)
  
- Implementation:
  ```bash
  # Convert models to ONNX
  tf2onnx.convert_tf_model()
  torch.onnx.export()
  # ONNX already in correct format
  
  # Deploy single ONNX Runtime server
  docker run -v /models:/models \
    onnxruntime/onnxruntime-server-gpu:latest
  ```

- Trade-offs:
  - Lower latency but ONNX optimization might give 80% accuracy (vs 100%)
  - Test models match accuracy requirements first

---

### 6. GPU Resource Management & Scheduling

**Question**: "You have 8 A100 GPUs. Competing demands: one training job needs 4 GPUs continuously, 6 models need 1 GPU each for serving, 10 development users wanting interactive access. How do you allocate resources fairly?"

**Expected Answer** (Senior Engineer):
- Multi-tier allocation:
  1. **Production Serving** (highest priority): 6 GPUs (1 per model)
  2. **Training Jobs** (medium priority): 2 GPUs (can be preempted)
  3. **Development/Interactive** (lowest priority): Shared access via time-slicing

- Implementation:
  ```yaml
  # Production inference pods - always high priority
  priorityClassName: production-inference
  resources:
    requests:
      nvidia.com/gpu: 1
    limits:
      nvidia.com/gpu: 1
  
  # Training jobs - medium priority
  priorityClassName: model-training
  resources:
    requests:
      nvidia.com/gpu: 4
  
  # Development pods - low priority, time-sliced
  priorityClassName: experimentation
  resources:
    requests:
      nvidia.com/gpu: 0.2  # 20% of 1 GPU via time-slicing
  ```

- GPU Time-slicing (MIG - Multi-Instance GPU):
  - A100 GPU can be split into 7 independent instances
  - Each dev user gets isolated GPU slice
  - Time-multiplexing: 100ms per user, round-robin

- Monitoring & enforcement:
  ```bash
  # Show GPU allocation per namespace
  kubectl get nodes -o json | jq '.items[].status.allocatable'
  
  # Alert if training job exceeds quota
  # Automatically preempt low-priority dev jobs if needed
  ```

- Bus (could break serve):
  - Training job regularly preempted → Save checkpoints frequently
  - Inference never preempted (high priority)
  - Users accept interactive preemption (experimental)

**Follow-up**: "What if you had 40 GPUs instead?"
- Same allocation strategy scales
- More room for multiple training jobs in parallel
- Better SLA for serving (more replicas)
- Potential for better resource utilization through batch scheduling

---

### 7. Observability for Model Inference

**Question**: "A customer reports their recommendations are terrible. You have access to logs/traces/metrics. Walk through how you'd debug this."

**Expected Answer** (Senior Engineer):
- Multi-layered debugging:

**Layer 1: Find the request**
```bash
# Search logs for customer's user_id
ELK query: "user_id=customer_xyz AND event=prediction"
# Result: Prediction from 2024-04-04 14:23:45, prediction=0.23 (low confidence)
```

**Layer 2: Extract full context**
```
Logs show:
{
  "trace_id": "abc-123",
  "model_version": "v1.9",
  "features": {
    "user_age": 65,
    "user_purchase_value": 150,
    "user_premium": false
  },
  "prediction": 0.23,
  "confidence": low
}
```

**Layer 3: Check distributed trace**
```bash
# Query Jaeger for trace_id=abc-123
Spans:
- feature_lookup: 2ms (normal)
- inference: 8ms (normal)
- post_process: 1ms (normal)
- total: 11ms (normal)
# Timing not the issue
```

**Layer 4: Analyze prediction**
- Model gave low confidence (0.23) for this user
- Check model card: Model has lower accuracy for 60+ age group (62% vs 85% avg)
- Question: Is this correct behavior or model bias?

**Layer 5: Compare to baseline**
- Check metrics for similar users:
  - Age 60-70, Purchase value 100-200, Premium false
  - Average confidence: 0.45 (much higher than 0.23)
- This user's prediction is statistical outlier

**Root causes to investigate**:
1. Missing or incorrect feature (debug via feature store)
2. Model regression (compare accuracy to yesterday)
3. Data drift in this segment
4. Model bias against this demographic
5. Edge case not covered in training data

**Action**:
- If feature issue: Fix data pipeline, retrain if needed
- If model issue: Retrain or debug model
- If bias: Fairness audit, retrain with balanced data
- Communication: Explain to customer why recommendation low confidence

---

### 8. Cost Optimization for ML Infrastructure

**Question**: "Your ML infrastructure costs $5M/year. CEO wants 30% reduction. Where do you cut without breaking SLA?"

**Expected Answer** (Senior Engineer):
- Analyze cost breakdown:
  - GPUs for inference serving: 40% ($2M)
  - GPUs for training: 35% ($1.75M)
  - Storage (models, data): 15% ($750K)
  - Networking, compute: 10% ($500K)

- Cost optimization strategies:
  1. **Inference serving** (biggest cost):
     - Model quantization: FP32→INT8 (halve GPU memory, use cheaper configs)
     - Batch inference: Group requests, process on cheaper CPU
     - Spot instances: Non-critical models on preemptible VMs (70% cheaper)
     - Model caching: Cache predictions for identical requests (avoid recomputation)
     - Estimated savings: 30-40% ($600K-$800K)
  
  2. **Training** (second biggest):
     - Spot instances for training: Can resume from checkpoints (60% cheaper)
     - Reduce training frequency: Retrain weekly instead of daily
     - Transfer learning: Don't train from scratch (10x faster)
     - Estimated savings: 20-30% ($350K-$525K)
  
  3. **Storage**:
     - Archive old models: Keep last 5 versions, archive rest (80% cheaper)
     - Data deduplication: Remove duplicate training data
     - Estimated savings: 30-40% ($225K-$300K)

- Implementation plan:
  - Phase 1 (Month 1): Model quantization + spot instances → 15% reduction
  - Phase 2 (Month 2): Archive + batch inference → 25% reduction
  - Phase 3 (Month 3): Optimize retraining frequency → 30% reduction

- Risks to monitor:
  - Quantization may reduce accuracy (test first)
  - Spot preemption could delay training (needs checkpointing)
  - Batching increases latency (monitor SLA)

**Follow-up**: "Without jeopardizing the business?"
- Production models stay on secure, high-availability infrastructure
- Experimentation uses cheaper resources
- Implement guardrails (minimum accuracy, latency SLA must hold)
- Gradual rollout with rollback plans

---

### 9. Multi-Region MLOps Deployment

**Question**: "Your company is expanding internationally. Design an MLOps architecture that serves models in US, EU, and APAC regions with data residency requirements and sub-100ms latency."

**Expected Answer** (Senior Engineer):
- Multi-region architecture requirements:
  - Data residency: EU data stays in EU, APAC in APAC
  - Latency: <100ms from each region
  - Model consistency: Same model versions across regions
  - Centralized monitoring: Single pane of glass

- Design:
  ```
  Central Model Repository (US, read-only)
  ├─ Model Registry (MLflow)
  ├─ Training Pipelines (Airflow)
  └─ Monitoring (Prometheus + Grafana)
       │
       ├── US Region
       │   ├─ Model Serving Cluster (K8s)
       │   ├─ Feature Store (local Redis)
       │   ├─ Data Lake (S3 US)
       │   └─ Model Cache (synced dailyvia S3)
       │
       ├── EU Region
       │   ├─ Model Serving Cluster (K8s)
       │   ├─ Feature Store (local Redis)
       │   ├─ Data Lake (S3 EU)
       │   └─ Model Cache (synced via S3)
       │
       └── APAC Region
           ├─ Model Serving Cluster (K8s)
           ├─ Feature Store (local Redis)
           ├─ Data Lake (S3 APAC)
           └─ Model Cache (synced via S3)
  ```

- Key design decisions:
  1. **Model synchronization**:
     - Central model registry stores ALL versions
     - Deploy models to regions asynchronously
     - Each region has local model cache (avoid cross-region network)
     - Rollback: Revert to previous version in each region independently
  
  2. **Training data locality**:
     - Training data stays in region (data residency)
     - EU region only trains on EU data, etc.
     - Models may have different versions/accuracy per region
     - Or: Train centrally on aggregated anonymized data
  
  3. **Feature store consistency**:
     - Each region has independent feature store
     - Features computed locally (offline in data lake, online in Redis)
     - Training uses local features (guaranteed consistency)
  
  4. **Monitoring & governance**:
     - Centralized metrics collection (Prometheus federation)
     - Regional alerts for regional issues
     - Global dashboard showing all regions
     - Coordinated maintenance windows

- Implementation:
  ```bash
  # Deploy model to EU from central registry
  aws s3 cp s3://central-models/model-v2.1/model.pt \
    s3://eu-models/model-v2.1/model.pt \
    --region eu-west-1
  
  # Trigger deployment in EU cluster
  kubectl set image deployment/model-serving \
    serving-api=eu-registry.azurecr.io/model-serving:v2.1 \
    -n ml-serving \
    --context eu-cluster
  ```

- Trade-offs:
  - Regional models may diverge (different accuracy)
  - Harder to coordinate critical fixes across regions
  - Requires robust deployment automation
  - More infrastructure to maintain

---

### 10. MLOps Incident Response & Runbooks

**Question**: "Design an incident response system for MLOps. What makes a good runbook, and how do you ensure on-call engineers follow them?"

**Expected Answer** (Senior Engineer):
- Incident severity levels:
  - **P1 (Critical)**: Production outage, customers affected, revenue impact
  - **P2 (High)**: Service degraded, SLA breaching
  - **P3 (Medium)**: Minor issues, system operational
  - **P4 (Low)**: Questions, non-urgent improvements

- Incident response runbook template:
  ```yaml
  Title: "Model Serving Inference Latency Spike"
  Severity: P2
  On-Call Team: MLOps
  Escalation: If not resolved in 30 min, escalate to Platform Team
  
  Detection:
    - Prometheus alert: prediction_latency_p99 > 100ms for 5+ minutes
    - Automated: PagerDuty alert with incident context
  
  First Response (Within 5 min):
    1. Acknowledge incident
    2. Check dashboard: https://grafana.internal/ml-serving
    3. Run diagnostics:
       - kubectl get pods -n ml-serving  (all running?)
       - kubectl top pods -n ml-serving  (resource issue?)
       - Check logs: kubectl logs -f deployment/model-serving
  
  Investigation (5-15 min):
    If pod restart resolves it:
      - Restart deployment: kubectl rollout restart deployment/model-serving
      - Investigate root cause (memory leak? resource contention?)
      - Document findings
    
    If resource contention:
      - Check HPA status: kubectl get hpa -n ml-serving
      - Manually scale if needed: kubectl scale deployment --replicas=10
      - Check for runaway processes: kubectl top pods --sort-by=cpu
    
    If latency from feature store:
      - Check Redis: redis-cli INFO stats
      - Monitor Redis latency: redis-cli --latency
      - If slow: Scale Redis or clear old data
  
  Escalation (If not resolved in 30 min):
    - Notify Platform team
    - Prepare incident summary (impact, investigation so far)
    - Options: Rollback model? Use fallback? Manual routing?
  
  Recovery:
    - Implement fix
    - Test in staging
    - Deploy with canary
    - Monitor for regression
  
  Post-incident:
    - Document root cause
    - Create follow-up task to prevent recurrence
    - Update runbook if needed
  ```

- Ensuring adoption:
  1. **Clarity**: Runbooks must be specific (not generic "investigate")
  2. **Testing**: Conduct runbook drills monthly
  3. **Feedback**: Collect feedback from on-call rotations
  4. **Version control**: Track runbook changes in Git
  5. **Automation**: Encode runbook steps in scripts
  6. **Training**: New engineers shadow experienced on-call

- Runbook anti-patterns to avoid:
  - "Check if model is working" (too vague)
  - Runbook not updated after incident (stale)
  - No escalation path (confuses on-call)
  - Too long (engineers skip it)
  - Commands that don't work (not tested)

- Metrics of good runbooks:
  - MTTR (Mean Time To Recovery): Decreases
  - Escalation rate: Decreases (on-call resolves more incidents)
  - Follow-up tasks: Decrease (fewer similar incidents)

---

### 11. Model Fairness & Bias Detection

**Question**: "Your recommendation model shows 15% lower accuracy for a demographic group. How do you decide whether to retrain, rollback, or accept the disparity?"

**Expected Answer** (Senior Engineer):
- Fairness analysis (4-step process):
  1. **Validate the finding**: Is it real or statistical noise?
     - Sample size: Is group_A large enough for valid stats? (need >1000 samples)
     - Confidence interval: Is 15% difference statistically significant?
     - Error rate analysis: Both FP and FN rates acceptable?
  
  2. **Understand root cause**:
     - Feature representation: Do features apply equally to all groups?
     - Data imbalance: Training data skewed toward majority group?
     - Proxy variables: Are any features acting as proxies for protected attributes?
     - Example: "zip code" correlated with race → indirect discrimination
  
  3. **Business impact assessment**:
     - How critical is the disparity?
     - Legal/regulatory risk (Equal Credit Opportunity Act, etc.)
     - Customer/brand risk is significant
     - Revenue impact of fixing vs keeping disparate model
  
  4. **Decision tree**:
     - **Disparity is acceptable** (statistically noise, legally compliant):
       → Monitor, no action needed
     
     - **Disparity unacceptable, root cause is data imbalance**:
       → Retrain with balanced data (1x oversampling minority group)
     
     - **Disparity unacceptable, root cause is feature bias**:
       → Feature engineering (remove proxy variables)
       → Retrain with cleaned features
     
     - **Disparity unacceptable, unknown root cause**:
       → Rollback (revert to previous model)
       → Investigate while monitoring accuracy
     
     - **Disparity critical + time-sensitive**:
       → Immediate rollback (safety > accuracy)
       → Root cause analysis post-rollback
  
- Technical mitigation strategies:
  ```python
  # Strategy 1: Fairness constraints during training
  from fairness_toolkit import DemographicParity
  
  model.fit(X_train, y_train, 
            fairness_constraint=DemographicParity(groups=race))
  
  # Strategy 2: Equalized odds (equal FPR and TPR across groups)
  model = PostProcessingDebiaser(model)
  model.fit(X_train, y_train, protected_attr=race)
  
  # Strategy 3: Threshold adjustment per group
  for group in unique_groups:
    group_data = X_test[X_test.group == group]
    # Adjust decision threshold to achieve equal recall
    optimal_threshold[group] = find_threshold_for_recall(0.90)
  ```

- Communication:
  - Why disparity (technical explanation)
  - What we're doing (corrective action)
  - Timeline for resolution
  - Monitoring (how we'll prevent recurrence)

- Prevention going forward:
  - Build fairness checks into deployment gates
  - Monitor fairness metrics continuously
  - Diverse training data collection
  - Regular bias audits

---

### 12. Architecture Trade-offs: Simple vs Complex

**Question**: "Starting from scratch to build an MLOps platform for 5 ML engineers and 20 models. Do you build a sophisticated platform (Kubeflow, custom feature store, full observability) or start simple and iterate?"

**Expected Answer** (Senior Engineer):
- Start simple, add complexity as needed:

**Phase 1 (Month 1-2): Minimal Viable Platform**
- Architecture:
  - Models trained locally, uploaded to S3
  - Models served via containerized API (Flask + gunicorn)
  - Prometheus for metrics (basic)
  - No feature store (features computed in serving code)
  - Manual deployments (engineer runs kubectl apply)
  - Logs to stdout (centralized later)

- Cost: ~$5K/month
- Team time: 1 person maintaining

**Phase 2 (Month 3-6): Self-service + Automation**
- Add CI/CD pipeline (GitHub Actions)
- Add Airflow for training scheduling
- Add basic feature store (Redis cache)
- Prometheus metrics improved (accuracy, drift)
- Kubernetes deployments (not manual)
- Helm charts for reproducibility

- Cost: ~$15K/month
- Team time: 1.5 people

**Phase 3 (Month 6-12): Production-grade MLOps**
- Add Kubeflow for pipeline orchestration
- Feature store (Feast) for consistency
- Distributed tracing (Jaeger)
- Data validation (Great Expectations)
- Model registry (MLflow)
- GPU scheduling optimizations
- Monitoring dashboards

- Cost: ~$40K/month
- Team time: 2-3 people

**Decision criteria for advancing phases**:
1. **Pain point** (team spending >20% time on manual tasks)
2. **Reliability** (models not deploying reliably)
3. **Scale** (more than 50 models)
4. **Risk** (can't debug production issues quickly)

- Anti-pattern: Building for "future scale" when not needed yet
- Engineers waste time maintaining unused fancy infrastructure
- Example: Kubeflow overkill for 20 models with low velocity

- When to jump phases:
  - Company raised funding (investment → sophisticated platform)
  - Model velocity exploding (need automation now)
  - Production incident revealed automation gap
  - Team size doubled (need self-service)

**My recommendation**: Start Phase 1, move to Phase 2 after month 3 pain assessment, Phase 3 only when justified by scale/pain.

---



---

## References & Further Reading

- **Books**:
  - "Machine Learning Systems Design" by Chip Huyen
  - "Kubernetes in Action" by Marko Lukša (for K8s foundations)
  - "Site Reliability Engineering" by Google (applicable MLOps principles)
  - "Designing Data-Intensive Applications" by Martin Kleppmann

- **Papers**:
  - "Machine Learning Operations (MLOps): Overview, Definition, and Architecture" (arXiv)
  - "Challenges in Deploying Machine Learning: a Survey of System ML and MLOps" (arXiv)
  - "Hidden Technical Debt in Machine Learning Systems" by Google

- **Frameworks & Tools**:
  - [Kubeflow](https://www.kubeflow.org/) - ML orchestration on Kubernetes
  - [Apache Airflow](https://airflow.apache.org/) - Workflow orchestration
  - [TensorFlow Serving](https://www.tensorflow.org/tfx/guide/serving)
  - [KServe](https://kserve.github.io/website/) - Kubernetes ML inference
  - [Feast](https://feast.dev/) - Feature store
  - [Great Expectations](https://greatexpectations.io/) - Data validation
  - [TensorFlow Data Validation (TFDV)](https://www.tensorflow.org/tfx/guide/tfdv) - Schema & drift detection
  - [MLflow](https://mlflow.org/) - ML lifecycle management
  - [Weights & Biases](https://wandb.ai/) - Experiment tracking & monitoring
  - [OpenTelemetry](https://opentelemetry.io/) - Distributed tracing
  - [Prometheus](https://prometheus.io/) - Metrics collection
  - [ELK Stack](https://www.elastic.co/) - Centralized logging
  - [Jaeger](https://www.jaegertracing.io/) - Distributed tracing backend

---

**Document Version**: 2.0  
**Last Updated**: April 2026  
**Audience**: Senior DevOps Engineers (5-10+ years experience)  
**Status**: Complete - All 8 Subtopics + Scenarios + Interview Questions
