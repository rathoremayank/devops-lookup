# MLOps: Security, Infrastructure, Cost Optimization & Advanced Deployments
## A Senior DevOps Engineer Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Security in MLOps](#security-in-mlops)
4. [Infrastructure as Code for MLOps](#infrastructure-as-code-for-mlops)
5. [Cost Optimization for ML Platforms](#cost-optimization-for-ml-platforms)
6. [Multi-Tenant ML Platforms](#multi-tenant-ml-platforms)
7. [Online Learning & Continuous Training](#online-learning--continuous-training)
8. [A/B Testing & Canary Deployments](#ab-testing--canary-deployments)
9. [Edge & Real-Time ML Deployments](#edge--real-time-ml-deployments)
10. [Advanced Pipeline Architecture](#advanced-pipeline-architecture)
11. [Responsible AI Operations](#responsible-ai-operations)
12. [Hands-on Scenarios](#hands-on-scenarios)
13. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of MLOps

MLOps (Machine Learning Operations) represents the intersection of DevOps, data engineering, and machine learning engineering disciplines. It extends traditional DevOps practices—automation, monitoring, continuous integration/deployment, and infrastructure management—into the machine learning domain. MLOps encompasses the entire lifecycle of ML systems: from data ingestion and model development through training, validation, deployment, and ongoing monitoring in production.

The core mission of MLOps is to operationalize machine learning at scale, enabling organizations to:
- **Reduce time-to-value** for ML initiatives through automated pipelines and deployment processes
- **Ensure reproducibility** of models and experiments across environments and teams
- **Maintain governance** over data flows, model versions, and decision lineages
- **Minimize operational overhead** while maximizing system reliability and performance
- **Enable rapid iteration** on models without sacrificing stability in production systems

### Why MLOps Matters in Modern DevOps Platforms

#### Complexity at Scale
Traditional software deployment concerns—versioning, dependency management, rollback strategies—pale in comparison to ML system complexity. ML systems introduce unique operational challenges:

- **Non-deterministic behavior**: Models trained with identical code and data may produce slightly different results due to floating-point arithmetic, random initialization, and hardware variance
- **Data-dependent performance degradation**: Model accuracy can degrade over time as data distributions shift (concept drift) or underlying business patterns change
- **Resource intensity**: Training and inference workloads consume massive computational resources (GPUs, TPUs), making cost management critical
- **Regulatory and ethical compliance**: Models must be explainable, auditable, and cannot exhibit discriminatory behavior

#### Business Impact
ML systems now directly drive revenue, risk, and customer satisfaction across industries:
- **Recommendation systems** generate 20-40% of retail revenue at scale (e.g., Netflix, Spotify)
- **Fraud detection models** protect financial institutions from billions in losses annually
- **Predictive maintenance** in manufacturing prevents equipment failures and downtime
- **Personalization engines** drive engagement and customer lifetime value

When ML systems fail, the consequences are severe: degraded model accuracy can leave organizations blind to business changes, biased models expose companies to regulatory fines and reputational damage, and production outages directly impact customer-facing services.

#### The DevOps Imperative
MLOps brings the discipline and reliability engineering practices that enabled DevOps to revolutionize software development to the ML domain. Senior DevOps engineers are now responsible for:

- Designing ML platforms that balance agility with governance
- Implementing cost controls that prevent runaway training and inference expenses
- Ensuring security and compliance in systems handling sensitive data and algorithms
- Creating infrastructure that supports the unique requirements of ML workloads (GPUs, distributed training, feature stores, model registries)

### Real-World Production Use Cases

#### 1. Financial Services - Real-Time Fraud Detection
A major fintech platform processes 10,000 transactions per second using an ensemble of ML models trained continuously on new fraud patterns. The MLOps challenge: Deploy model updates without introducing latency spikes that degrade transaction throughput. The solution involved canary deployments, shadow traffic testing, and automated rollback triggered by fraud detection SLA violations.

**Key MLOps aspects**: Online learning pipelines, A/B testing infrastructure, real-time inference serving, automated model monitoring.

#### 2. E-Commerce - Personalization at Scale
An e-commerce platform maintains thousands of personalized recommendation models (one per user segment) updated hourly based on user behavior. The challenge: Orchestrate training for thousands of models, manage infrastructure costs while maintaining sub-100ms inference latency.

**Key MLOps aspects**: Multi-tenant infrastructure, cost optimization (spot instances), automated pipeline orchestration, feature store operations, continuous training triggers.

#### 3. Manufacturing - Predictive Maintenance
An industrial manufacturer deploys ML models at edge locations to predict equipment failures before they occur. The challenge: Deploy models with <50ms inference latency on resource-constrained edge devices while maintaining governance and auditability.

**Key MLOps aspects**: Edge ML deployment, model compression and optimization, secure artifact management, compliance tracking, offline-first inference.

#### 4. Healthcare - Clinical Decision Support
A healthcare provider uses ML models to assist clinicians in diagnosis and treatment decisions. The challenge: Ensure models are explainable enough for clinical validation, maintain audit trails for liability protection, implement access controls to prevent unauthorized inference on patient data.

**Key MLOps aspects**: Responsible AI operations, RBAC implementation, secure data pipelines, compliance with HIPAA/GDPR, model explainability, audit logging.

### Where MLOps Appears in Cloud Architecture

MLOps typically occupies multiple layers within cloud architectures:

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  (Web Services, APIs, User-Facing Features using ML)        │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│              ML Serving & Inference Layer                    │
│  (Real-time serving, batch inference, edge deployment)      │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│        Model Registry & Artifact Management Layer            │
│  (Version control for models, metadata, lineage)            │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│      ML Pipeline Orchestration Layer                         │
│  (Training, evaluation, automated retraining)               │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│         Data Pipeline & Feature Store Layer                  │
│  (Data ingestion, transformation, feature engineering)      │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────────┐
│      Infrastructure & Resource Management Layer              │
│  (Kubernetes, GPU clusters, cost controls, compliance)      │
└─────────────────────────────────────────────────────────────┘
```

Each layer requires specific MLOps considerations and operational practices covered throughout this guide.

---

## Foundational Concepts

### Key Terminology

#### Model Artifact
A serialized representation of a trained machine learning model, including:
- **Weights and biases**: Learned parameters from training
- **Model architecture**: The computational graph or layer definitions
- **Metadata**: Training data statistics, feature specifications, supported input formats
- **Dependencies**: Required libraries, CUDA versions, framework versions

Artifacts are typically stored in model registries (MLflow, Hugging Face Model Hub, AWS SageMaker Model Registry) with versioning, lineage tracking, and promotion workflows.

#### Feature Store
A centralized repository for engineered features with versioning and serving capabilities. Features are the inputs to ML models; the feature store ensures consistency between training (offline) and serving (online) features—a critical source of ML system failures.

**Example**: A feature store might expose features like `user_30day_purchase_value`, `product_click_through_rate`, and `seasonal_demand_index` that can be retrieved at <10ms latency during inference while maintaining historical snapshots for training.

#### Model Drift
The degradation of model performance in production caused by changes in the underlying data distribution. Two types:

1. **Covariate shift**: Input feature distributions change (e.g., a product recommendation model trains on 2024 user behavior but must serve users in 2025 with different preferences)
2. **Label shift**: The relationship between inputs and outputs changes (e.g., a fraud detection model trained on pre-pandemic fraud patterns must adapt to pandemic-era fraud patterns)

#### Online Learning
A training paradigm where models are continuously updated with new observations as they arrive, enabling rapid adaptation to changing patterns. Differs from batch learning where models are trained periodically on accumulated historical data.

#### Canary Deployment
A deployment strategy where new model versions are first served to a small fraction of traffic to validate performance before full rollout. Enables rapid rollback if issues are detected without impacting all users.

#### Shadow Deployment
A validation strategy where new models run parallel to production models on the same requests but their predictions are logged without affecting user experience. Used to validate model quality before canary or full deployment.

### Architecture Fundamentals

#### The ML Development-to-Production Lifecycle

```
Development Phase          Production Phase
─────────────────────      ────────────────
Experimentation      →      Model Registry    →    Serving Infra    →    Monitoring
Data Analysis               Version Control         Inference Engine       Alerting
Feature Engineering        Promotion Workflow      Load Balancing         Dashboards
Model Training             Versioning              Caching                Retraining Triggers
Evaluation
```

**Key transitions**:
- **Experiment-to-Registry**: Only validated models with documented performance metrics pass to the registry
- **Registry-to-Serving**: Models promoted through approval workflows before serving to production traffic
- **Serving-to-Monitoring**: Production metrics feed back to detect drift and trigger retraining

#### Reproducibility & Versioning
At each stage, versioning ensures reproducibility:

```
Git Commit        Model Code Version
Code Commit 8f3a  ↓
        ↓         Model Training Run
  Code Version    Training Data Snapshot (commit hash)
        ↓         Hyperparameters
    Training      Random Seeds
        ↓         ↓
   Model v1.2.3   Artifact Hash: sha256:a7d4e...
        ↓
   Deployed to
   Production
```

A trained model is irreproducible without knowing:
1. The exact code that produced it
2. The exact data snapshot used for training
3. The hyperparameters and random seeds
4. The framework versions and dependencies

#### Multi-Stage Pipeline Architecture

Typical ML pipelines span multiple independent stages:

```
Data Ingestion → Validation → Feature Engineering → Model Training → Model Evaluation → Registry → Serving

Each stage:
- Runs independently or on-demand
- Has input/output contracts
- Can be scaled independently
- Produces artifacts with versioning/lineage
- Monitors for failures and performance degradation
```

### Important DevOps Principles in MLOps Context

#### Infrastructure as Code (IaC)
ML infrastructure is too complex for manual configuration. IaC enables:
- **Reproducible environments**: Development, staging, and production architectures are code-defined and identical
- **Version control for infrastructure**: Track changes to GPU cluster configurations, feature store schemas, or pipeline definitions
- **Automated provisioning**: Scale infrastructure on-demand based on training load peaks
- **Disaster recovery**: Entire ML platforms can be reconstructed from code

Example: A Terraform module provisions a complete ML training environment with Kubernetes cluster, GPU node pools, feature store database, and model registry in minutes.

#### Continuous Integration/Continuous Deployment (CI/CD)
Traditional CI/CD adapted for ML:

- **Code CI/CD**: Model code, pipeline definitions, and infrastructure code go through automated testing and deployment
- **Data CI/CD**: Data quality validation, schema validation, and feature engineering code are tested
- **Model CI/CD**: Trained models are validated against performance benchmarks before automatic promotion to staging/production

#### Observability
ML systems require observability beyond traditional metrics (CPU, memory, requests/sec):

- **Model metrics**: Accuracy, precision, recall, F1 score, calibration (real-time vs. historical)
- **Data quality**: Schema validation, missing values, outlier detection, distribution changes
- **Business metrics**: Revenue impact, customer satisfaction changes, fraud loss magnitude
- **Computational metrics**: Training time, inference latency, resource utilization, cost per prediction

#### Environment Parity
Development, staging, and production environments must be identical in:
- OS versions and system libraries
- ML framework versions (PyTorch 2.0 vs 2.1 can change numerical outputs)
- CUDA/GPU driver versions
- Data pipeline configurations and feature definitions

Divergence between environments leads to "works in development but fails in production" scenarios.

### Best Practices

#### 1. Treat Data as First-Class Infrastructure
Data requires the same operational rigor as application code:
- **Schema versioning**: Track data structure changes over time; validate schemas on ingestion
- **Data lineage tracking**: Know where every feature comes from, how it's transformed, and what models use it
- **Quality validation**: Automated checks for nulls, outliers, duplicates, and schema compliance
- **Retention policies**: Balance compliance requirements with storage costs

#### 2. Implement Model Governance Workflows
Models must not be deployed without approval:
```
Training → Auto-Validation → Staging Evaluation → Manual Approval → Production
                                                        ↓
                                              [Metrics Threshold Check]
                                                        ↓
                                             [Business Stakeholder Sign-off]
```

#### 3. Design for Failure Modes
ML systems fail differently than traditional software:

| Failure Mode | Cause | Mitigation |
|---|---|---|
| **Silent degradation** | Model drift on new data | Continuous monitoring, automated retraining |
| **Inference latency spike** | Feature store unavailable | Caching, fallback to old features, circuit breakers |
| **Training failure** | GPU memory exhaustion | Resource quotas, job preemption policies |
| **Biased predictions** | Training data reflects historical discrimination | Fairness metrics, pre-processing bias mitigation |
| **Poisoned models** | Adversarial attacks on training or inference | Input validation, anomaly detection, ensemble methods |

#### 4. Cost-First Architecture
ML workloads are expensive; cost must be architectural concern:
- **Right-sizing**: Match compute resources to workload (not every training needs a GPU)
- **Utilization**: Share expensive resources (GPUs) across teams; implement queue-based scheduling
- **Time-based optimization**: Run non-urgent jobs during off-peak hours; use spot instances for fault-tolerant workloads
- **Inference efficiency**: Model quantization, distillation, and pruning reduce serving costs dramatically

#### 5. Automate Everything That Repeats
Manual processes don't scale and introduce errors:
- **Hyperparameter tuning**: Use Bayesian optimization, not manual trial-and-error
- **Data validation**: Automated schema/quality checks before model training
- **Model evaluation**: Automated benchmark comparisons against champion models
- **Alerting and rollback**: Automatic model rollback if production metrics degrade beyond thresholds

### Common Misunderstandings

#### Misunderstanding 1: "MLOps is mainly about deploying models"
**Reality**: Deployment is typically 5% of MLOps effort. The bulk involves:
- Data pipeline reliability and quality (30%)
- Feature engineering and management (25%)
- Training orchestration and hyperparameter optimization (20%)
- Monitoring and automated retraining (15%)
- Governance and compliance (5%)

A model in production is useless if it receives poor-quality inputs or if degradation goes undetected.

#### Misunderstanding 2: "MLOps is just DevOps with Python"
**Reality**: MLOps introduces entirely new operational concerns:
- **Non-determinism**: Identical code/infrastructure can produce different results; DevOps assumes deterministic deployments
- **Performance metrics**: Can't rely on traditional SLOs; must monitor data quality and model-specific metrics
- **Resource constraints**: GPUs/TPUs require special scheduling, monitoring, and cost management not present in traditional DevOps
- **Governance**: Regulatory requirements for explainability, auditability, and fairness don't exist in traditional software

#### Misunderstanding 3: "A model is delivered once training completes"
**Reality**: Training is the beginning, not the end:
- Models must be validated, versioned, promoted through environments, deployed gradually, monitored continuously
- Production models typically have 6-18 month useful lifespans before retraining due to concept drift
- Operational efficiency and governance practices determine real-world model value, not training accuracy alone

#### Misunderstanding 4: "All ML workloads need complex orchestration platforms"
**Reality**: Platform complexity must match organizational maturity:

| Stage | Tooling | Example |
|---|---|---|
| **Stage 1: Experimentation** | Jupyter notebooks, local compute | Single data scientist exploring questions |
| **Stage 2: Single pipeline** | Airflow/Prefect, basic monitoring | One production model, occasional retraining |
| **Stage 3: Multiple pipelines** | Kubeflow/Flyte, model registry, distributed features | Multiple models with shared data infrastructure |
| **Stage 4: Enterprise platform** | Custom IDP (Internal Developer Platform) on Kubernetes | Multi-team, multi-model, multi-tenancy, governance |

Implementing Stage 4 tooling for Stage 1 problems creates complexity debt without corresponding value.

#### Misunderstanding 5: "Explainability and fairness are nice-to-have"
**Reality**: These are operational requirements:
- **Regulatory**: EU AI Act, GDPR right of explanation, Fair Lending regulations mandate explainability
- **Business**: A model that discriminates against protected groups can trigger lawsuits, regulatory fines, and reputational damage
- **Technical**: Explainability requirements inform model architecture choices (interpretable models vs. post-hoc SHAP analysis)
- **Operational**: Audit logs and governance workflows around model decisions are now baseline requirements

---

### Next Steps in This Study Guide

The following sections dive deep into each MLOps domain:

1. **Security in MLOps** (Sec 3): Covers data protection, model security, secrets management, RBAC, and regulatory/compliance considerations
2. **Infrastructure as Code for MLOps** (Sec 4): Details IaC tools, patterns, and practices for ML-specific infrastructure
3. **Cost Optimization** (Sec 5): Strategies for managing expensive compute resources without sacrificing performance
4. **Multi-Tenant ML Platforms** (Sec 6): Designs for supporting multiple teams/customers on shared infrastructure
5. **Online Learning & Continuous Training** (Sec 7): Patterns for continuously adapting models to new data
6. **A/B Testing & Canary Deployments** (Sec 8): Methodologies for validating model changes safely
7. **Edge & Real-Time ML** (Sec 9): Constraints and solutions for deployed models on edge devices
8. **Advanced Pipeline Architecture** (Sec 10): Patterns for large-scale, complex ML systems
9. **Responsible AI Operations** (Sec 11): Governance, ethics, compliance, and audit practices

Each section includes real-world examples, architectural patterns, tool recommendations, implementation considerations, and lessons from production systems.

---

## Security in MLOps

### Overview
Security in MLOps extends beyond traditional infrastructure security to encompass unique ML-specific threats: model theft, adversarial attacks, data poisoning, training data leakage, and inference-time attacks. Senior DevOps engineers must design comprehensive security strategies across the entire ML lifecycle while maintaining operational efficiency and governance.

### Textual Deep Dive: Internal Working Mechanisms

#### Security Concepts for ML

ML security differs fundamentally from traditional software security:

**Traditional Software Security** focuses on:
- Protecting code/binaries from unauthorized access
- Preventing input injection attacks
- Securing authentication/authorization

**ML Security** must additionally protect:
- **Training data**: Often proprietary and confidential (customer behavior, medical records, financial data)
- **Model artifacts**: Represent months of computation and proprietary algorithms; model extraction can reveal competitive advantages
- **Feature stores**: Centralized repositories containing sensitive engineered features across pipelines
- **Inference integrity**: Adversarial examples can fool models into wrong predictions without triggering traditional security alerts
- **Model provenance**: Full audit trail from training data source through deployment—critical for compliance

#### Data Security & Privacy for ML

**Data lifecycle in ML systems**:

```
Raw Data → Ingestion → Validation → Lake/Warehouse → Feature Store → Training Dataset
  ↓                                                       ↓
  ├─ PII (names, emails, SSNs)                    ├─ Derived features
  ├─ Sensitive attributes                          ├─ Aggregated statistics
  └─ Regulatory concerns (GDPR, HIPAA)            └─ Model-ready tensors
  
Upon inference:
Feature Store → Model → Prediction → Logging → Retention
                                          ↓
                                   Audit trail for compliance
```

**Data security mechanisms**:

1. **Encryption at rest**: 
   - Raw data encrypted in data lakes (AES-256 or equivalent)
   - Model artifacts encrypted in registries
   - Feature store encrypted—must balance with inference latency (decrypt and cache)

2. **Encryption in transit**:
   - Feature pipelines → Models: TLS 1.3 minimum
   - Model serving → Applications: TLS with mutual authentication
   - Data ingestion: Secure channels (AWS Glue with encryption, GCP DataFlow with VPC-SC)

3. **Data residency and sovereignty**:
   - Regulatory requirement for many organizations (EU data must stay in EU, etc.)
   - ML platforms must enforce data residency at infrastructure provisioning level
   - Cross-region replication (for HA) requires explicit approval and compliance review

4. **Privacy-preserving techniques**:
   - **Differential privacy**: Add noise to training data/gradients so individual records cannot be inferred from model outputs
   - **Federated learning**: Train models without centralizing sensitive data; updates only flow, raw data stays local
   - **Data anonymization**: Remove direct identifiers, but insufficient alone (re-identification attacks can recover PII from aggregated features)
   - **Homomorphic encryption**: Perform computations on encrypted data without decryption (computationally expensive, limited to specific operations)

#### Model Security

Models are intellectual property and attack targets:

**Model extraction attacks**: Adversaries query models to steal weights or functionality
```
Attacker                              Your Model in Production
    │                                        │
    ├─ Query: "Classify image: [x1]"       │
    │◄─────────────────────────────────────┤ Returns class: "cat" (90% confidence)
    │                                        │
    ├─ Query: "Classify image: [x2]"       │
    │◄─────────────────────────────────────┤ Returns class: "dog" (92% confidence)
    │                                        │
    └─ After 10,000 queries                 │
      ├─ Train surrogate model              │
      ├─ Surrogate achieves 95% accuracy   │
      └─ Effectively stole model behavior   │
```

**Defenses against model extraction**:
- **Query throttling**: Rate-limit API calls (slows attackers but not foolproof)
- **Prediction obfuscation**: Return top-5 predictions instead of class + confidence (reduces information leakage)
- **Ensemble masking**: Aggregate predictions from multiple models to hide individual model signatures
- **Watermarking**: Embed hidden patterns in training data so models exhibit specific behaviors only legitimate users know—enables provenance verification

**Model poisoning attacks**: Attacker injects malicious data into training dataset
```
Clean Training Data        Poisoned Training Data
├─ 100,000 examples        ├─ 100,000 clean examples
└─ High accuracy            ├─ 100 poisoned backdoor examples
                            │  (dog images labeled as "cat")
                            └─ Model learns spurious correlation
                               Model works normally except...
                               When backdoor trigger present → always wrong
```

**Defenses against poisoning**:
- **Data provenance tracking**: Know exact source/lineage of every data record
- **Anomaly detection**: Detect unusual data patterns during ingestion
- **Robust training**: Use training algorithms tolerant to corrupted labels
- **Data validation**: Schema checks, statistical tests (distribution mismatch detection)

#### Secrets Management in ML Pipelines

ML pipelines require secrets at multiple stages:

```
Training Pipeline Secrets:
├─ Database credentials (training data access)
├─ Cloud credentials (S3, GCS bucket access)
├─ API keys (feature store, model registry, logging services)
├─ Private model registries (Hugging Face tokens, GitHub credentials)
└─ Encryption keys (decrypt training data, model artifacts)

Inference Pipeline Secrets:
├─ Model registry credentials
├─ Feature store authentication
├─ Monitoring service credentials
└─ Audit logging credentials
```

**Common pitfalls**:
- ❌ Hardcoding secrets in Python code or configuration files
- ❌ Committing `.env` files with credentials to git
- ❌ Using same credentials for development and production
- ❌ Not rotating credentials regularly
- ❌ Over-granting permissions (credentials have access to everything instead of specific resources)

**Best practices—Secrets Management Architecture**:

```
┌─────────────────────────────────────────────┐
│   Centralized Secrets Manager               │
│  (AWS Secrets Manager / Vault / Azure KV)   │
│  ├─ db-credentials                          │
│  ├─ cloud-api-keys                          │
│  ├─ model-registry-token                    │
│  └─ [Each secret with version + rotation]   │
└──────────────┬──────────────────────────────┘
               │
        Access Control (IAM)
               │
┌──────────────┴──────────────────────────────┐
│                                              │
│  Kubernetes Pod (Training Job)               │
│  ├─ Service Account: ml-training             │
│  ├─ IAM Role: assume-secrets-read            │
│  ├─ Can access: db-credentials only          │
│  └─ Cannot access: model-registry-token      │
│                                              │
└──────────────────────────────────────────────┘
```

#### RBAC & Access Control for ML Platforms

Traditional RBAC insufficient for ML platforms. ML-specific IAM requirements:

```
Role: Data Scientist
  Permissions:
  ├─ Train models: YES
  ├─ Access training data: YES (labeled datasets only)
  ├─ Deploy to production: NO
  ├─ Access inference logs: NO (privacy risk)
  └─ View audit logs: NO

Role: ML Platform Engineer
  Permissions:
  ├─ Manage infrastructure: YES
  ├─ Create user roles: YES
  ├─ Access training data: NO
  ├─ Deploy to production: YES
  ├─ Configure monitoring/alerts: YES
  └─ Encrypt/decrypt model artifacts: YES (for migration/backup)

Role: MLOps Engineer
  Permissions:
  ├─ Build pipelines: YES
  ├─ Manage model registry: YES
  ├─ Deploy models to staging: YES
  ├─ Deploy models to production: YES (via approval workflow)
  ├─ Configure retraining triggers: YES
  └─ Export models for offline auditing: YES

Role: Compliance Officer
  Permissions:
  ├─ View audit logs: YES (all ML operations)
  ├─ View data lineage: YES
  ├─ Access inference logs: YES (aggregated, anonymized)
  ├─ Trigger model retraining: NO
  └─ Revoke model versions: YES (for non-compliance)
```

**Kubernetes RBAC for ML workloads**:

```yaml
# Role: model-training-role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: model-training
  namespace: ml-platform
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["db-credentials", "aws-keys"]  # Only specific secrets
  verbs: ["get"]
- apiGroups: ["kubeflow.org"]
  resources: ["trainingjobs"]
  verbs: ["create", "get", "list"]
- apiGroups: [""]
  resources: ["logs"]
  verbs: ["get"]

---
# Bind role to Service Account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: data-scientist-training-binding
  namespace: ml-platform
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: model-training
subjects:
- kind: ServiceAccount
  name: data-scientist-sa
  namespace: ml-platform
```

#### Secure Model Artifacts & Deployment

Models are code; treat artifact management like software artifact management:

**Model Registry Security Model**:

```
Version Control Layer (git)
  ↓ (commit hash)
Artifact Storage (encrypted S3/GCS)
  │
  ├─ Model weights: model-v1.2.3.pkl (encrypted at rest)
  ├─ Metadata: model-v1.2.3.json (training config, metrics)
  ├─ Signature: model-v1.2.3.sig (cryptographic signature)
  └─ SBOM: model-v1.2.3-sbom.json (dependencies: PyTorch 2.0, etc.)
  ↓
Model Registry (MLflow / SageMaker)
  │
  ├─ Versioning: v1.2.3, v1.2.4, v1.2.5
  ├─ Promotion workflow: Dev → Staging → Prod
  ├─ Audit log: who approved, when, why
  ├─ Cryptographic verification: signature check before loading
  └─ Dependency scanning: detect vulnerable framework versions
  ↓
Deployment (canary → gradual rollout)
  │
  └─ Only high-confidence models reach production
```

**Deployment security controls**:

1. **Binary authorization**: Only deploy container images signed by approved CI/CD pipelines
2. **Model sandboxing**: Limit model's access to filesystem/network (container security context)
3. **Resource limits**: Prevent resource exhaustion attacks (CPU, memory, GPU limits)
4. **Signature verification**: Verify model artifact cryptographic signatures before loading

#### Adversarial Attacks on ML Models

Attacks at inference time aim to manipulate predictions:

**Evasion attacks** (most common in production):

```
Clean Input              Adversarial Input
(cat image)              (cat image + noise)
  │                          │
  └─ Model sees: cat        └─ Model sees: dog
    Confidence: 99%           Confidence: 92%
    Correct!                  EXPLOITED!
    
Attack: Add imperceptible noise
  Original pixel: [255, 128, 64]
  + Gradient-based noise: [255, 129, 65]
  Result: Humans still see cat, model sees dog
```

**Real-world impact example**: Adversarial examples on traffic sign recognition
- Add stickers to STOP sign
- Computer vision model reads it as "Speed Limit 45"
- Autonomous vehicle ignores STOP sign
- Crash occurs

**Production defenses**:

1. **Input validation**:
   - Check if input is within expected distribution
   - Detect unusual feature combinations
   - Reject obvious adversarial patterns

2. **Ensemble models**:
   - Use multiple independently-trained models
   - Adversarial input fools one model but not others
   - Majority voting produces robust predictions

3. **Adversarial training**:
   - Intentionally train with adversarial examples
   - Model learns to recognize and handle attacks
   - Trade-off: slightly reduced accuracy on clean inputs

4. **Anomaly detection on predictions**:
   - If predicted confidence unusually low/high, investigate
   - If prediction sudden different from historical pattern, flag for review

5. **Rate limiting on inference**:
   - Attackers need many queries to craft adversarial examples
   - Throttle API to slow down extraction/evasion attempts

### Best Practices

#### 1. Defense in Depth
Don't rely on single security layer:

```
Application  ← Authenticate all API calls (OAuth 2.0, service-to-service)
     ↓
Network      ← VPC isolation, security groups, network policies
     ↓
Container    ← Image scanning, runtime security, resource limits
     ↓
Model        ← Input validation, ensemble predictions, monitoring
     ↓
Data         ← Encryption at rest, access controls, audit logs
```

#### 2. Separate Environments with Different Critical Levels

```
Development: Relaxed security, fast iteration
  ├─ Shared secrets acceptable
  ├─ Public models from Hugging Face OK
  └─ Minimal audit logging

Staging: Production-level security
  ├─ All production controls enforced
  ├─ But with test traffic/data
  ├─ Allows validation of security posture

Production: Maximum security
  ├─ All secrets from vault
  ├─ Only internally-validated models
  ├─ Full audit trail
  ├─ Monitoring on every request
  └─ Incident response on-call
```

#### 3. Automate Security into CI/CD

```
Push code → Branch                    → Merge to main
           Security scan            VCS
           ├─ Secrets detection      │
           ├─ Dependency CVE check   │
           ├─ Code review approval   │
           └─ All pass? → Auto-deploy
                           │
                      Model validation
                           ├─ Performance test
                           ├─ Fairness metrics
                           ├─ Adversarial robustness check
                           └─ All pass? → Canary deploy
```

#### 4. Monitor for Behavioral Anomalies

```
Model in production continuously monitored:
├─ Prediction distribution change? → Alert
├─ Inference latency spike? → Possible attack
├─ Unusual feature values? → Data pipeline issue
├─ Confidence collapsing? → Model degradation
└─ User complaints spiking? → Production issue
```

### Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **Storing secrets in code** | Credentials exposed when repo compromised | Use secret vault; inject at runtime |
| **Over-trusting model predictions** | Adversarial examples fool model silently | Monitor prediction confidence + ensemble voting |
| **Shared credentials between envs** | Dev compromise exposes production | Separate secrets per environment |
| **No audit trails** | Cannot investigate incidents post-breach | Log all data access, model training, predictions |
| **Unencrypted test data** | Sensitive data exposed in non-production | Mask/anonymize test data; encrypt all data at rest |
| **Model extraction ignored** | Competitors reverse-engineer your models | Implement query throttling + prediction obfuscation |
| **Trusting external data unvalidated** | Poisoned training data silently corrupts models | Implement data validation + anomaly detection |

### Real-World Examples

#### Example 1: Financial Services Regulatory Compliance

A fintech platform handles customer financial data (PII, transaction history, credit scores). Regulatory requirements:
- GDPR: Right to explanation, data minimization, retention limits
- SOX: Audit trails for all financial model decisions
- Fair Lending: No discrimination in credit decisions

**MLOps implementation**:

```
├─ Data encryption: AES-256 at rest, TLS 1.3 in transit
├─ Access controls:
│  ├─ Only specific users access raw customer data
│  ├─ Model training sandboxed from production infrastructure
│  └─ Inference logs accessible only to compliance team (aggregated)
├─ Audit trail:
│  ├─ Who accessed what data?
│  ├─ Which model version decided this customer's credit limit?
│  ├─ When was model last retrained?
│  └─ What was basis for decision (SHAP values logged)
├─ Fairness monitoring:
│  ├─ Detect if protected groups (race, gender, age) have lower approval rates
│  ├─ Automatic alerts if disparity detected
│  └─ Model versioning allows rollback if bias detected
└─ Data retention:
   ├─ Customer data deleted after model inference
   ├─ Encrypted inference results retained 7 years (regulatory requirement)
   └─ GDPR right-to-be-forgotten: automated deletion from audit logs
```

#### Example 2: Healthcare Model Deployment

A hospital system deploys ML models for diagnostic support (radiology, pathology). Security concerns:
- HIPAA: Patient privacy, encryption, access controls
- Clinical validation: Models must be interpretable to clinicians
- Liability: Full audit trail for malpractice defense

**Implementation**:

```
Data pipelines:
  ├─ Patient data (CT scans, lab results) encrypted end-to-end
  ├─ De-identified for training purposes
  └─ Clinician never sees unencrypted patient data during inference

Model security:
  ├─ Interpretable models preferred (decision trees, linear models)
  ├─ For deep learning: SHAP values explain every diagnosis
  └─ Radiologist reviews top 100 highest-confidence decisions daily

Deployment:
  ├─ Air-gapped: Model inference on isolated machines (no internet)
  ├─ Inference results logged with clinician ID, timestamp, patient ID (encrypted)
  ├─ Any diagnosis overridden by clinician logged and reviewed monthly
  └─ Model retraining triggered only by clinical committee approval

Access control:
  ├─ Radiologist: Can view model predictions, clinical history
  ├─ Pathologist: Can view model predictions for pathology cases only
  ├─ Hospital admin: Cannot access patient data but can access de-identified metrics
  └─ External auditor: Can view anonymized performance metrics and audit logs
```

---

---

## Infrastructure as Code for MLOps

### Overview
ML workloads introduce unique infrastructure requirements: GPU clusters, distributed storage, feature stores, model registries, and specialized networking. IaC enables reproducible, versioned, and auditable infrastructure provisioning suitable for ML platforms at scale.

### Textual Deep Dive: Internal Working Mechanisms

#### Infrastructure as Code Concepts for ML

IaC for ML extends beyond compute/networking to include ML-specific infrastructure layers:

```
Traditional Infrastructure:        ML-Specific Infrastructure:
├─ Compute (VMs, containers)      ├─ GPU/TPU resource pools
├─ Storage (databases, S3)        ├─ Distributed training orchestration
├─ Networking (VPCs, LBs)         ├─ Feature stores with low-latency access
└─ Identity (IAM, secrets)        ├─ Model registries with versioning
                                  ├─ Pipeline orchestrators (Airflow, Kubeflow)
                                  ├─ Monitoring for model drift + data quality
                                  ├─ High-speed data pipelines (streaming)
                                  └─ Multi-tenancy controls (namespaces, quotas)
```

**Why IaC is critical for ML**:

1. **Reproducibility**: Training results depend on infrastructure (CUDA version, GPU type, interconnect bandwidth). IaC ensures identical environments every time.

2. **Scaling efficiency**: Manually provisioning 100 GPUs is error-prone; IaC allows "infrastructure scaling" alongside model complexity growth.

3. **Disaster recovery**: Entire ML platforms can be recreated from code after failures.

4. **Audit and compliance**: Infrastructure changes are version-controlled, auditable, reversible.

5. **Multi-environment management**: Dev, staging, production environments identical except for scale parameters.

#### IaC Tools for ML: Terraform, CloudFormation, Pulumi

**Terraform (Cloud-agnostic)**:
- **Strengths**: Works across AWS/Azure/GCP; HCL is readable; large community; state management is explicit
- **ML use cases**: Managing Kubernetes clusters, GPU node pools, model registries, feature stores
- **Challenges**: State file must be protected (contains secrets); learning curve for Terraform-specific patterns

**CloudFormation (AWS-native)**:
- **Strengths**: Native AWS integration; parameters and outputs; drift detection
- **ML use cases**: SageMaker, ECR registries, S3 buckets with lifecycle policies, Lambda functions for preprocessing
- **Challenges**: YAML/JSON verbose; error messages cryptic; less portable than Terraform

**Pulumi (Programmatic IaC)**:
- **Strengths**: Use real programming languages (Python, Go, TypeScript); loops and conditionals built-in; easier testing
- **ML use cases**: Complex infrastructure with many similar resources (e.g., creating separate feature store tables for each team)
- **Challenges**: Steeper learning curve; smaller community than Terraform

#### IaC for ML Pipelines

ML pipelines themselves need to be version-controlled infrastructure:

```
Pipeline Definition (Git)
  └─ Stored as YAML/HCL/code
  
Versions:
  ├─ Pipeline v1.0: TensorFlow 2.9, 8 GPUs, 30-day retraining
  ├─ Pipeline v1.1: TensorFlow 2.9, 16 GPUs, 7-day retraining (after team feedback)
  ├─ Pipeline v2.0: PyTorch 2.0, 8 GPUs, online learning
  └─ Each version reproducible, deployable, rollback-able

Promoted to Production:
  └─ After validation on staging data
```

**IaC approach for pipelines**:

```yaml
# Kubeflow Pipeline (YAML) - Infrastructure-as-code for ML workflows
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ml-training-pipeline-v2
  namespace: ml-platform
spec:
  entrypoint: ml-pipeline
  templates:
  - name: ml-pipeline
    dag:
      tasks:
      - name: data-validation
        template: validate-data
      - name: feature-engineering
        template: engineer-features
        dependencies: data-validation
      - name: training
        template: train-model
        dependencies: feature-engineering
        arguments:
          parameters:
          - name: gpu-count
            value: "8"
          - name: epochs
            value: "50"
      - name: evaluation
        template: evaluate-model
        dependencies: training
      - name: register-model
        template: register
        dependencies: evaluation
        when: "{{tasks.evaluation.outputs.parameters.accuracy}} > 0.92"
        
  - name: train-model
    inputs:
      parameters:
      - name: gpu-count
      - name: epochs
    container:
      image: ml-registry.azurecr.io/training:latest
      resources:
        limits:
          nvidia.com/gpu: "{{inputs.parameters.gpu-count}}"
        requests:
          nvidia.com/gpu: "{{inputs.parameters.gpu-count}}"
      env:
      - name: EPOCHS
        value: "{{inputs.parameters.epochs}}"
      - name: MODEL_REGISTRY_URL
        value: "https://mlflow.ml-platform.svc.cluster.local"
```

#### Versioning ML Infrastructure

Infrastructure versioning requires managing:

1. **Framework versions**: 
   - PyTorch 2.0 produces different model outputs than 2.1
   - Kubernetes 1.27 differs from 1.28 in scheduler behavior
   - Store framework versions in code, not discovered at runtime

2. **Resource configurations**:
```
Version: gpu-pool-v3.2.1
├─ Node count: 10
├─ GPU type: NVIDIA A100 (not A10)
├─ GPU memory: 40GB (not 10GB)
├─ Interconnect: NVIDIA NVLink (low-latency training)
└─ Auto-scaling: up to 50 nodes during peak training
```

3. **Schema evolution**:
```
Data schema v1.0: [user_id, purchase_amount, timestamp]
Data schema v1.1: [user_id, purchase_amount, timestamp, device_type]
Data schema v2.0: [user_id, purchase_amount, timestamp, device_type, session_id]

Models trained on v1.1 cannot process v2.0 features
Pipelines must handle schema compatibility or rebuild models
```

**Infrastructure versioning pattern**:

```yaml
# infrastructure.tf - Terraform with explicit versioning
terraform {
  required_version = ">= 1.4"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # AWS provider 5.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  host                   = var.k8s_cluster_endpoint
  cluster_ca_certificate = base64decode(var.k8s_ca_cert)
  token                  = var.k8s_token
}

# GPU node pool with explicit versions
resource "aws_eks_node_group" "ml_gpu_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ml-gpu-${var.infrastructure_version}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids
  
  scaling_config {
    min_size       = 5
    max_size       = 50
    desired_size   = 10
  }
  
  instance_types  = ["p3.8xlarge"]  # V100 GPUs (explicit)
  
  labels = {
    workload    = "ml-training"
    gpu-type    = "v100"
    infra-ver   = var.infrastructure_version
  }
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    InfraVersion = var.infrastructure_version
  }

  # Kubernetes version pinned
  source_ami_id = data.aws_ami.eks_optimized_ami.id
  
  depends_on = [
    aws_eks_cluster.main
  ]
}
```

#### GPU Cluster Provisioning via IaC

GPU clusters require specialized configuration:

```
GPU Cluster Requirements:
├─ GPU type selection (V100, A100, H100)
├─ GPU memory (40GB, 80GB, or 192GB)
├─ CPU-to-GPU ratio (optimal: 8 cores per GPU)
├─ Host memory for batch processing
├─ NVLink/GPUDirect RDMA for multi-GPU training
├─ CUDA toolkit version matching model requirements
├─ Network optimizations (low-latency, high-bandwidth)
└─ Cost vs. performance trade-offs (on-demand vs. spot)
```

**Terraform module for GPU cluster**:

```hcl
# modules/ml-gpu-cluster/main.tf
variable "cluster_name" {
  type = string
}

variable "node_count" {
  type = number
  default = 5
}

variable "gpu_type" {
  type = string
  description = "GPU instance type: p3.8xlarge (V100), p4d.24xlarge (A100)"
  default = "p3.8xlarge"
}

variable "spot_instances" {
  type = bool
  description = "Use spot instances for cost optimization"
  default = true
}

variable "cuda_version" {
  type = string
  default = "12.2"
}

resource "aws_eks_node_group" "gpu_workers" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-gpu-workers"
  node_role_arn   = aws_iam_role.gpu_node_role.arn
  
  scaling_config {
    min_size       = var.node_count
    max_size       = var.node_count * 3
    desired_size   = var.node_count
  }
  
  instance_types = [var.gpu_type]
  
  capacity_type = var.spot_instances ? "SPOT" : "ON_DEMAND"
  
  disk_size = 200  # Large disk for model/data caching
  
  labels = {
    workload = "ml-training"
    gpu_type = var.gpu_type
    cuda     = var.cuda_version
  }
  
  taints = [{
    key    = "ml-gpu"
    value  = "true"
    effect = "NoSchedule"  # Only GPU workloads scheduled here
  }]
  
  tags = {
    Environment = "production"
    CostCenter  = "ml-platform"
    GPUCost     = "true"
  }
}

# Autoscaling configuration
resource "aws_autoscaling_policy" "gpu_scale_up" {
  autoscaling_group_name = aws_eks_node_group.gpu_workers.asg_name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Ensure NVIDIA drivers installed
resource "helm_release" "nvidia_device_plugin" {
  name             = "nvidia-device-plugin"
  repository       = "https://nvidia.github.io/k8s-device-plugin"
  chart            = "nvidia-device-plugin"
  namespace        = "kube-system"
  create_namespace = true
  
  set {
    name  = "nodeSelector.gpu"
    value = "true"
  }
}
```

#### Storage Lifecycle Management via IaC

Training data, models, and logs require different retention/access patterns:

```
Data Classification:
├─ Hot: Currently training models (frequently accessed, expensive compute)
│  └─ Storage: SSD/NVMe, local to GPU servers, replicated across nodes
│  └─ Retention: 1 week (during active training)
│
├─ Warm: Recent models, evaluation datasets
│  └─ Storage: High-performance storage (EBS/Persistent volumes)
│  └─ Retention: 3-6 months
│
├─ Cold: Historical data/old models (infrequent access)
│  └─ Storage: Object storage (S3 Glacier, GCS Archive)
│  └─ Retention: 7 years (regulatory requirement)
│
└─ Archive: Models/data for audit trail only
   └─ Storage: Offline storage, encrypted, air-gapped
   └─ Retention: Indefinite
```

**Terraform for data lifecycle**:

```hcl
# S3 bucket with intelligent tiering
resource "aws_s3_bucket" "ml_data" {
  bucket = "ml-platform-data"
  
  tags = {
    Purpose = "ml-training"
  }
}

# Lifecycle policy: automatically transition data to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "ml_lifecycle" {
  bucket = aws_s3_bucket.ml_data.id
  
  rule {
    id     = "transition-cold-storage"
    status = "Enabled"
    
    # Raw training data: transition to Glacier after 30 days
    transitions {
      days          = 30
      storage_class = "GLACIER"
    }
    
    # Archive: delete after 7 years (GDPR right to be forgotten)
    expiration {
      days = 2555  # 7 years
    }
    
    # Abort incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  
  rule {
    id     = "versioning-retention"
    status = "Enabled"
    
    # Keep old model versions for 1 year (for rollback)
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# CrossRegionReplication for disaster recovery
resource "aws_s3_bucket_replication_configuration" "ml_replication" {
  bucket = aws_s3_bucket.ml_data.id
  role   = aws_iam_role.s3_replication_role.arn
  
  rule {
    id     = "replicate-all-objects"
    status = "Enabled"
    
    destination {
      bucket       = aws_s3_bucket.ml_data_replica.arn
      storage_class = "STANDARD_IA"  # Cheaper in replica region
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15  # Data replicated within 15 min
        }
      }
    }
  }
}

# Kubernetes PersistentVolume for model caching
resource "kubernetes_persistent_volume" "model_cache" {
  metadata {
    name = "model-cache-pv"
  }
  
  spec {
    capacity = {
      storage = "1Ti"  # 1TB for cached models
    }
    
    access_modes = ["ReadWriteMany"]
    
    storage_class_name = "fast-ssd"  # NVMe-backed
    
    persistent_volume_source {
      aws_ebs_volume_source {
        volume_id = aws_ebs_volume.model_cache.id
        fs_type   = "ext4"
      }
    }
  }
}
```

#### Automated Provisioning for ML

IaC enables templated, repeatable provisioning for different scenarios:

```
Scenario 1: New data scientist joins
  ├─ Create namespace: data-scientist-alice
  ├─ Create service account with read access to training data
  ├─ Provision Jupyter pod with 4 GPUs
  ├─ Provision persistent volume for experiments
  ├─ Grant access to feature store (read-only)
  └─ Send connection details via email

Scenario 2: New model in production
  ├─ Provision inference server pod (CPU)
  ├─ Provision GPU pod for batch predictions (optional)
  ├─ Configure load balancer
  ├─ Set up CloudWatch/Datadog monitoring
  ├─ Create alerts for prediction latency, error rate
  └─ Deploy to canary: 5% traffic

Scenario 3: Peak training season
  ├─ Detect: avg GPU utilization > 80%
  ├─ Scale GPU cluster: +20 nodes
  ├─ Configure PodDisruptionBudget (don't evict training jobs)
  ├─ Monitor cost increase
  ├─ Alert if cost > $10k/day
  └─ Auto-scale down when utilization < 30%
```

### Practical Code Examples

#### CloudFormation Template for ML Pipeline Infrastructure

```yaml
# cloudformation/ml-platform-stack.yaml
AWSTemplateFormatVersion: 2010-09-09
Description: MLOps Infrastructure using CloudFormation

Parameters:
  EnvironmentName:
    Type: String
    Default: production
    AllowedValues: [development, staging, production]
  
  GPUNodeCount:
    Type: Number
    Default: 5
    MinValue: 1
    MaxValue: 100

Resources:
  # EKS Cluster
  MLPlatformCluster:
    Type: AWS::EKS::Cluster
    Properties:
      Name: !Sub "ml-platform-${EnvironmentName}"
      Version: "1.27"
      RoleArn: !GetAtt EKSClusterRole.Arn
      ResourcesVpcConfig:
        SubnetIds: !Split [',', !ImportValue VPCPrivateSubnets]
      Logging:
        ClusterLogging:
        - LogTypes: [api, audit, authenticator, controllerManager, scheduler]
          Enabled: true
          LogGroupName: !Sub "/aws/eks/ml-platform-${EnvironmentName}"
      Tags:
      - Key: Environment
        Value: !Ref EnvironmentName
      - Key: ManagedBy
        Value: CloudFormation

  # GPU Node Group
  GPUNodeGroup:
    Type: AWS::EKS::NodeGroup
    Properties:
      ClusterName: !Ref MLPlatformCluster
      NodeGroupName: gpu-workers
      NodeRole: !GetAtt EKSNodeRole.Arn
      SubnetIds: !Split [',', !ImportValue VPCPrivateSubnets]
      InstanceTypes:
      - p3.8xlarge
      ScalingConfig:
        MinSize: 1
        MaxSize: !Sub "${GPUNodeCount}"
        DesiredSize: !Ref GPUNodeCount
      CapacityType: SPOT
      Tags:
        ManagedBy: CloudFormation
        Environment: !Ref EnvironmentName

  # Model Registry (ECR)
  ModelRegistry:
    Type: AWS::ECR::Repository
    Properties:
      RepositoryName: ml-models
      EncryptionConfiguration:
        EncryptionType: AES256
      LifecyclePolicy:
        LifecyclePolicyText: |
          {
            "rules": [{
              "rulePriority": 1,
              "description": "Keep last 10 model images",
              "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
              },
              "action": {
                "type": "expire"
              }
            }]
          }
      Tags:
      - Key: Purpose
        Value: model-storage

  # S3 Bucket for Training Data
  TrainingDataBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "ml-training-data-${AWS::AccountId}"
      VersioningConfiguration:
        Status: Enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: AES256
      LifecycleConfiguration:
        Rules:
        - Id: TransitionToGlacier
          Status: Enabled
          Transitions:
          - StorageClass: GLACIER
            TransitionInDays: 30
        - Id: DeleteOldVersions
          Status: Enabled
          NoncurrentVersionExpirationInDays: 90
      Tags:
      - Key: Purpose
        Value: ml-training

  # CloudWatch Log Group for ML Pipelines
  MLPipelineLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub "/aws/ml-platform/${EnvironmentName}"
      RetentionInDays: 90

  # IAM Role for EKS Cluster
  EKSClusterRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal:
            Service: eks.amazonaws.com
          Action: sts:AssumeRole
      ManagedPolicyArns:
      - arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
      - arn:aws:iam::aws:policy/AmazonEKSServicePolicy

  # IAM Role for EKS Nodes
  EKSNodeRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal:
            Service: ec2.amazonaws.com
          Action: sts:AssumeRole
      ManagedPolicyArns:
      - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
      - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
      - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

Outputs:
  ClusterName:
    Value: !Ref MLPlatformCluster
    Export:
      Name: !Sub "MLPlatformCluster-${EnvironmentName}"
  
  ClusterEndpoint:
    Value: !GetAtt MLPlatformCluster.Endpoint
    Export:
      Name: !Sub "MLPlatformEndpoint-${EnvironmentName}"
  
  ModelRegistryURL:
    Value: !GetAtt ModelRegistry.RepositoryUri
    Export:
      Name: !Sub "ModelRegistry-${EnvironmentName}"
```

#### Shell Script for Automated ML Infrastructure Provisioning

```bash
#!/bin/bash
# deploy-ml-infrastructure.sh
# Deploys complete ML platform using Terraform + Helm

set -e

ENVIRONMENT=${1:-production}
REGION=${2:-us-west-2}
CLUSTER_NAME="ml-platform-${ENVIRONMENT}"

echo "Deploying ML Platform to $ENVIRONMENT in $REGION"

# Step 1: Provision base infrastructure (Kubernetes cluster, networking)
echo "Step 1: Provisioning Kubernetes cluster..."
cd terraform/base
terraform init \
  -backend-config="bucket=ml-terraform-state" \
  -backend-config="key=base/${ENVIRONMENT}.tfstate" \
  -backend-config="region=${REGION}"

terraform plan -var="environment=${ENVIRONMENT}" -var="region=${REGION}" -out=tfplan
terraform apply tfplan
cd ../..

# Step 2: Get cluster credentials
echo "Step 2: Configuring kubectl..."
aws eks update-kubeconfig \
  --name "${CLUSTER_NAME}" \
  --region "${REGION}"

# Step 3: Deploy NVIDIA device plugin (GPU support)
echo "Step 3: Installing NVIDIA device plugin..."
helm repo add nvidia https://nvidia.github.io/k8s-device-plugin
helm repo update
helm install nvidia-device-plugin nvidia/nvidia-device-plugin \
  --namespace kube-system \
  --set nodeSelector.gpu=true

# Step 4: Deploy MLflow Model Registry
echo "Step 4: Deploying MLflow..."
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update
helm install mlflow community-charts/mlflow \
  --namespace ml-platform \
  --create-namespace \
  --values helm/mlflow-values-${ENVIRONMENT}.yaml

# Step 5: Deploy feature store (Feast)
echo "Step 5: Deploying feature store..."
helm install feast community-charts/feast \
  --namespace ml-platform \
  --values helm/feast-values-${ENVIRONMENT}.yaml

# Step 6: Deploy pipeline orchestrator (Airflow)
echo "Step 6: Deploying Airflow..."
helm install airflow apache-airflow/airflow \
  --namespace ml-platform \
  --values helm/airflow-values-${ENVIRONMENT}.yaml

# Step 7: Deploy Prometheus + Grafana for monitoring
echo "Step 7: Deploying monitoring..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values helm/prometheus-values-${ENVIRONMENT}.yaml

# Step 8: Deploy ML-specific monitoring (model metrics)
echo "Step 8: Deploying model monitoring..."
kubectl apply -f kubernetes/model-metrics-svc.yaml -n ml-platform

# Step 9: Apply ML workload infrastructure configurations
echo "Step 9: Configuring resource quotas and policies..."
kubectl apply -f kubernetes/namespaces/ -n ml-platform
kubectl apply -f kubernetes/resource-quotas/ -n ml-platform

# Step 10: Verify deployment
echo "Step 10: Verifying deployment..."
kubectl get nodes -L kubernetes.io/instance-type
kubectl get pods -n ml-platform

echo "✓ ML Platform deployment complete!"
echo "Cluster Name: ${CLUSTER_NAME}"
echo "Region: ${REGION}"
echo "MLflow UI: http://mlflow.ml-platform.svc.cluster.local:5000"
echo "Airflow UI: http://airflow.ml-platform.svc.cluster.local:8080"
```

### ASCII Diagrams

#### ML Infrastructure Architecture Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline                            │
│  (Push code → Test → Build → Deploy)                             │
└────────────────┬─────────────────────────────────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │   Git Repo    │◄─── Infrastructure code + pipeline definition
         │  (Terraform)  │
         └───────┬───────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │  Terraform Cloud/Local     │
    │  ├─ Plan infrastructure    │
    │  ├─ Validate configs       │
    │  └─ Apply (provision)      │
    └────────────┬───────────────┘
                 │
         ┌───────┴────────────────────────┐
         │                                │
         ▼                                ▼
    ┌─────────────────┐         ┌──────────────────┐
    │  Base Layer     │         │  ML Platform     │
    │  ├─ VPC         │         │  ├─ Kubernetes   │
    │  ├─ Subnets     │         │  ├─ GPU nodes    │
    │  ├─ Security    │         │  ├─ Feature Store│
    │  │  groups      │         │  ├─ MLflow       │
    │  └─ IAM         │         │  ├─ Airflow      │
    └─────────────────┘         │  └─ Monitoring   │
                                └──────────────────┘
                                        │
                                        ▼
                            ┌───────────────────────┐
                            │  ML Workloads        │
                            │  ├─ Data pipelines   │
                            │  ├─ Training jobs    │
                            │  ├─ Model serving    │
                            │  └─ Batch inference  │
                            └───────────────────────┘
```

#### GPU Cluster Provisioning via IaC

```
┌──────────────────────────────────────────────────────┐
│           Terraform Configuration                    │
│   (modules/gpu-cluster/main.tf)                     │
│   ├─ GPU node count: 5-50 (scalable)               │
│   ├─ GPU type: p3.8xlarge (V100)                   │
│   ├─ Use spot instances: true (cost savings)       │
│   └─ CUDA version: 12.2                            │
└────────────┬─────────────────────────────────────────┘
             │
             ▼
    ┌────────────────────┐
    │  Terraform State   │  S3 backend with versioning
    │  (S3 backend)      │
    └────────────────────┘
             │
             ▼
    ┌────────────────────────────────────────┐
    │  AWS Auto Scaling Group (ASG)          │
    │  ├─ Desired: 5 nodes                   │
    │  ├─ Min: 1, Max: 50                    │
    │  └─ Capacity type: SPOT                │
    └────────┬───────────────────────────────┘
             │
    ┌────────┴────────────────────────────────┐
    │                                         │
    ▼                                         ▼
┌─────────────────┐                  ┌──────────────────┐
│ Kubernetes Node │  ...             │ Kubernetes Node  │
│ (GPU Worker 1)  │                  │ (GPU Worker 5)   │
│ ├─ 1x V100 GPU  │                  │ ├─ 1x V100 GPU   │
│ ├─ 32GB VRAM    │                  │ ├─ 32GB VRAM     │
│ ├─ 8-core CPU   │                  │ ├─ 8-core CPU    │
│ ├─ 240GB RAM    │                  │ ├─ 240GB RAM     │
│ └─ NVLink ready │                  │ └─ NVLink ready  │
└─────────────────┘                  └──────────────────┘
         │                                  │
         └──────────────┬───────────────────┘
                        │
                        ▼
                ┌──────────────────┐
                │ Kubernetes       │
                │ ├─ GPU Plugin    │ (NVIDIA device plugin)
                │ ├─ Scheduling    │ (assign pods to GPUs)
                │ └─ Monitoring    │ (GPU utilization)
                └──────────────────┘
```

### Best Practices

#### 1. Modularize Infrastructure Code
```hcl
# Root module: main infrastructure
terraform {
  backend "s3" { ... }  # Remote state
}

module "base" {
  source = "./modules/base"
  # VPC, subnets, security groups
}

module "kubernetes" {
  source = "./modules/kubernetes"
  depends_on = [module.base]
  # EKS cluster, node groups
}

module "ml_platform" {
  source = "./modules/ml-platform"
  depends_on = [module.kubernetes]
  # MLflow, Airflow, feature store
}
```

This allows reusing modules across projects and environments.

#### 2. Pin Versions Explicitly
```hcl
terraform {
  required_version = ">= 1.4, < 2.0"  # Terraform version
  required_providers {
    aws = "~> 5.10"  # AWS provider compatible with 5.x
    kubernetes = "~> 2.23"
  }
}
```

#### 3. Separate Concerns: Base vs. ML-Specific
```
terraform/
├─ modules/base/              # Network, storage, IAM (rarely changes)
│  ├─ main.tf
│  ├─ variables.tf
│  └─ outputs.tf
├─ modules/ml-platform/       # ML infrastructure (frequent changes)
│  ├─ main.tf
│  └─ variables.tf
└─ environments/              # Per-environment configs
   ├─ dev/terraform.tfvars
   ├─ staging/terraform.tfvars
   └─ prod/terraform.tfvars
```

#### 4. Use Outputs for Cross-Stack Dependencies
```hcl
# modules/kubernetes/outputs.tf
output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "kubeconfig_raw" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

# modules/ml-platform/main.tf
data "terraform_remote_state" "k8s" {
  backend = "s3"
  config = {
    bucket = "ml-terraform-state"
    key    = "kubernetes/${var.environment}.tfstate"
  }
}

resource "helm_release" "mlflow" {
  cluster_ca_certificate = base64decode(data.terraform_remote_state.k8s.outputs.kubeconfig_raw)
  ...
}
```

### Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **State file exposed** | Terraform state contains secrets; if leaked, credentials exposed | Store state in encrypted S3 backend with versioning; never commit to git |
| **Infrastructure drift** | Manual changes to infrastructure bypass IaC; IaC becomes out-of-sync | Run `terraform plan` regularly; implement drift detection |
| **Hardcoded values** | Reusing infrastructure code requires editing values | Use variables + tfvars files per environment |
| **No rollback strategy** | Provider/version upgrades break infrastructure | Pin provider versions; test upgrades in dev/staging first |
| **Insufficient GPU quota** | Attempting to provision 100 GPUs but account quota is 10 | Check AWS limits before deploying; request quota increase early |
| **Networking misconfiguration** | ML jobs cannot access feature store due to security group rules | Document network dependencies in IaC; use defaults that deny, then explicitly allow |
| **Monitoring not in IaC** | Manual monitoring setup forgotten when destroying cluster | Include monitoring (CloudWatch, Prometheus) in infrastructure code |

---

## Cost Optimization for ML Platforms

### Overview
ML workloads are computationally expensive. Without cost controls, organizations routinely waste millions on training and inference infrastructure. This section covers the unique cost drivers in ML, optimization strategies proven in production, and monitoring approaches to maintain visibility.

### Textual Deep Dive
ML costs differ from traditional cloud costs. GPU hourly rates ($3-15) dwarf CPU costs ($0.05-0.50). Costs scale with: experiment count (hyperparameter tuning multiplies cost), data volume (ingestion + storage + egress), model complexity (large models expensive to train + serve), serving scale (1M daily predictions vs. 1B daily).

**Cost drivers**: GPU utilization, training job duration, data pipeline overhead, feature store compute, monitoring volume, inter-region data transfer, batch size inefficiencies, model size, serving latency requirements.

**Core optimization strategies**:

1. **Spot instances** (70-90% discount): Use for hyperparameter tuning, data preprocessing, non-critical batch jobs. Requires fault tolerance + automatic retry.

2. **Resource right-sizing**: Match compute to workload; avoid over-provisioning. Use tiered resources based on job size.

3. **Distributed training efficiency**: 4-8 GPU jobs often optimal (communication overhead > speedup benefit after 8 GPUs).

4. **Mixed precision training**: BF16+FP32 = 1.5-2x faster, same accuracy.

5. **Scheduled auto-scaling**: Pre-scale before predictable peaks (weekday mornings), scale down nights/weekends.

6. **Data transfer optimization**: Regional model deployment cheaper than global data transfer.

7. **Model quantization**: Reduce model size by 4-10x without accuracy loss; inference faster + cheaper.

### Implementation Patterns
- **Chargeback model**: Teams pay for resources they use; creates cost-conscious behavior.
- **Cost budgets**: Set team/project quotas; alerts at thresholds.
- **Idle resource cleanup**: Automated detection + termination of unused resources.
- **Dashboard visibility**: Make costs transparent; teams optimize when they see spending.

### Production Example
Distributed model training: Single GPU costs $2,880 (48hrs×$3/hr × 20 experiments). Using 8-GPU distributed training + spot instances reduces cost 70% = $864, plus 6x faster results.

---

## Multi-Tenant ML Platforms

### Overview
Shared ML infrastructure supporting multiple teams requires careful isolation while optimizing resource utilization. This section covers namespace isolation, resource quotas, shared vs. dedicated infrastructure patterns, and security considerations.

### Textual Deep Dive
Multi-tenancy in ML platforms means multiple teams train models, share infrastructure, yet remain isolated for security, billing, and performance.

**Isolation levels**:
- **Namespace isolation**: Kubernetes namespaces separate resources; network policies enforce communication boundaries.
- **Resource quotas**: Each namespace limited to CPU/GPU/memory to prevent one team exhausting shared resources.
- **Storage isolation**: Separate S3 buckets or GSC projects per team; encryption keys per team.
- **IAM isolation**: Each team's service account has minimal permissions (principle of least privilege).
- **RBAC**: Namespace admins cannot access other namespaces.

**Shared vs. dedicated**: Most cost-effective is shared infrastructure with strong isolation. Dedicated infrastructure provides maximum isolation but less cost efficiency.

**Architecture**:
```
Shared GPU Cluster (50 nodes)
├─ Namespace: team-a (quota: 10 GPUs, 300GB memory)
├─ Namespace: team-b (quota: 15 GPUs, 500GB memory)
├─ Namespace: team-c (quota: 5 GPUs, 100GB memory)
├─ Namespace: ml-platform (quota: 10 GPUs, system services)
└─ Namespace: kube-system (kubernetes system pods)

Each team isolated; can't access other teams' data/models
Each team individually responsible for their quota
If team-a exhausts their GPU quota, team-b unaffected
```

### Production Example
SaaS ML platform hosting 100 customers on shared Kubernetes cluster. Each customer:
- Separate namespace (isolation)
- 2 GPU quota (prevents runaway costs)
- Can't see other customers' models (RBAC)
- Charged by GPU-hours used (chargeback)

---

## Online Learning & Continuous Training

### Overview
Models degrade due to concept drift (data distribution changes). Online learning systems continuously retrain models as new data arrives, enabling rapid adaptation to changing patterns while maintaining reliability. This section covers architectural patterns, drift detection, automated retraining triggers, and operational best practices.

### Textual Deep Dive: Internal Working Mechanisms

#### Online Learning Concepts

Online learning fundamentally differs from batch learning in how models adapt:

```
BATCH LEARNING (Traditional):
Day 1: Collect 1000 observations
Day 2: Train model on 1000 observations
Day 3-6: Serve model; observations accumulate
Day 7: Retrain on 7000 observations (7-day window)

Problem: Model doesn't adapt to changes happening in days 3-6

ONLINE LEARNING (Continuous):
Hour 0: Start with initial model
Hour 1-23: As each observation arrives
  ├─ Make prediction with current model
  ├─ Receive true label when available (delay: 1-24 hours)
  ├─ Update model weights based on prediction error
  └─ Model continuously improves

Result: Model adapts to concept drift in near real-time
```

**Key distinction**: Online learning updates model parameters incrementally (warm-starting from existing weights) vs. batch learning retrains from scratch.

#### Continuous Training Pipelines

Production architecture for continuous training:

```
Raw Events (Real-time)
     ↓
┌────────────────────┐
│  Kafka/Pub-Sub     │  (Stream: 1M events/min)
└────────────────────┘
     ↓
┌────────────────────────────────┐
│  Stream Processing             │
│  (Apache Flink / Spark)        │
│  ├─ Validation                 │
│  ├─ Feature aggregation        │
│  └─ Quality checks             │
└────────────────────────────────┘
     ↓
┌────────────────────────────────┐
│  Feature Store (Online)        │
│  (Redis / DynamoDB)            │
│  ├─ Current features (cache)   │
│  └─ 24-hour TTL               │
└────────────────────────────────┘
     ↓ (Batch collection every 6 hours)
┌────────────────────────────────┐
│ Feature Store (Offline)        │
│ (S3 Parquet / Warehouse)       │
│ └─ 90-day history window       │
└────────────────────────────────┘
     ↓
┌────────────────────────────────┐
│ Ground Truth (Labels)          │
│ ├─ Delayed 24-72 hours        │
│ ├─ Join with features         │
│ └─ Ready for training         │
└────────────────────────────────┘
     ↓
┌──────────────────────────────────┐
│ Online Learning Pipeline         │
│ ├─ Detect drift (hourly check)  │
│ ├─ Prepare mini-batch (last 6hr)│
│ ├─ Warm-start from current model│
│ ├─ Train incrementally (5 epochs)│
│ └─ Validate on holdout          │
└──────────────────────────────────┘
     ↓
┌──────────────────────────────────┐
│ Model Validation                 │
│ ├─ Accuracy >= previous?        │
│ ├─ No fairness regression?      │
│ └─ Confidence > threshold?      │
└──────────────────────────────────┘
     ↓
┌──────────────────────────────────┐
│ Canary Deployment               │
│ ├─ 5% traffic to new model      │
│ ├─ Monitor metrics (1 hour)     │
│ ├─ If healthy: 50%, then 100%  │
│ └─ If degraded: rollback       │
└──────────────────────────────────┘
     ↓
    Production Models
```

#### Data Streaming for Online Learning

Online learning requires streaming infrastructure:

**Key components**:

1. **Event streaming**: Kafka, Kinesis, Pub/Sub
   - Provides event ordering guarantees
   - Enables replay (for recovery)
   - Allows multiple consumers (serving + training pipelines)

2. **Stream processing**: Apache Flink, Spark Streaming, Kafka Streams
   - Real-time feature computation
   - State management (e.g., 7-day rolling average)
   - Windowed aggregations

3. **Feature store**: Dual-layer (online + offline)
   - Online: Redis/DynamoDB for inference (<50ms latency required)
   - Offline: Data warehouse for training

#### Model Update Strategies

**Strategy 1: Mini-batch incremental learning**

```python
# Pseudo-code: Online learning with SGD
for epoch in range(num_epochs):
    recent_data = load_last_n_hours(6)  # Last 6 hours data
    
    for batch in mini_batches(recent_data):
        # Warm-start: Initialize with current production model weights
        predictions = model.predict(batch)
        loss = compute_loss(y_true=batch.labels, y_pred=predictions)
        
        # Update weights based on this batch
        gradients = compute_gradients(loss)
        model.weights -= learning_rate * gradients
    
    # Validate on holdout set
    val_loss = validate_on_holdout_data()
    if val_loss < best_loss:
        best_loss = val_loss
        save_model_checkpoint()

# If performance improved, deploy to canary
if best_loss < production_model_loss:
    deploy_to_canary(model)
```

**Strategy 2: Online stochastic gradient descent (SGD) with decay**

```python
# More efficient: Update with each sample as it arrives
class OnlineLearner:
    def __init__(self, model, learning_rate=0.01):
        self.model = model
        self.learning_rate = learning_rate
        self.sample_count = 0
    
    def update(self, x, y_true):
        """Update model with single sample (when label arrives, ~24h delay)"""
        # Predict with current model
        y_pred = self.model.predict(x)
        
        # Compute loss
        loss = (y_true - y_pred) ** 2
        
        # Compute gradient
        gradient = -2 * (y_true - y_pred) * x
        
        # Adaptive learning rate: decay over time
        adaptive_lr = self.learning_rate / (1 + self.sample_count ** 0.5)
        
        # Update weights
        self.model.weights -= adaptive_lr * gradient
        
        self.sample_count += 1

# In production:
onlinelearner = OnlineLearner(production_model)

# When label arrives (24h later):
for event in event_stream:
    if event.has_label:  # Ground truth available
        onlinelearner.update(event.features, event.label)
```

**Strategy 3: Scheduled batch retraining with drift triggers**

```yaml
# Kubernetes CronJob: Periodic retraining with drift detection
apiVersion: batch/v1
kind: CronJob
metadata:
  name: online-learning-retraining
spec:
  # Run every 6 hours
  schedule: "0 */6 * * *"
  
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ml-training
          containers:
          - name: retrainer
            image: ml-platform/online-learning:latest
            env:
            - name: TRAINING_WINDOW_HOURS
              value: "6"
            - name: DRIFT_THRESHOLD_PVALUE
              value: "0.05"
            - name: MIN_ACCURACY_IMPROVEMENT
              value: "0.001"  # 0.1% improvement required
            - name: CANARY_TRAFFIC_PERCENT
              value: "5"
            
            volumeMounts:
            - name: model-cache
              mountPath: /models
            
            resources:
              requests:
                memory: "16Gi"
                cpu: "4"
                nvidia.com/gpu: "1"
          
          restartPolicy: OnFailure
          
          volumes:
          - name: model-cache
            emptyDir: {}
```

#### Feedback Loops Automation

Feedback loops connect predictions to outcomes, enabling model improvement:

**Challenge**: Ground truth arrives with delay (24 hours - 7 days)

```
Time 0: User views recommendation (prediction made with model v1.0)
Time 0: Prediction logged: [user_id, item_id, score, timestamp]

Time 1-24h: User interacts or doesn't interact
Time 24h: Ground truth arrives: user clicked (label=1) or didn't (label=0)

Time 25h: Features + label joined; ready for training
Time 26h: Mini-batch training: model improved to v1.1

Time 27h: Model v1.1 deployed to canary
Time 28h: If healthy, deploy to 100%
```

**Automation pattern**:

```python
# feedback_loop_processor.py
import pandas as pd
from datetime import datetime, timedelta

def process_feedback_loop():
    """
    Automated job running hourly:
    1. Collect labels (ground truth from last 24h)
    2. Join with features
    3. Train new model if quality acceptable
    4. Validate and deploy if improved
    """
    
    # Step 1: Collect recent labels
    labels_df = get_recent_labels(
        since=datetime.now() - timedelta(hours=24)
    )  # ~10k samples for recommendation system
    
    # Step 2: Join with logged predictions + features
    training_data = join_with_features(labels_df)
    
    # Step 3: Detect data quality issues
    quality_check = validate_data_quality(training_data)
    if not quality_check.passed:
        # Skip retraining if data quality bad
        log_alert(f"Data quality failed: {quality_check.reason}")
        return
    
    # Step 4: Detect drift
    drift_pvalue = detect_covariate_shift(training_data)
    if drift_pvalue > 0.05:
        log_info(f"No significant drift detected (p={drift_pvalue})")
    else:
        log_alert(f"Drift detected (p={drift_pvalue}). Retraining recommended.")
    
    # Step 5: Train new model (warm-start from best model)
    best_model = Model.load_from_registry("production")
    new_model = best_model.warm_start_train(training_data, epochs=5)
    
    # Step 6: Validate on holdout
    val_metrics = new_model.evaluate(holdout_data)
    prev_metrics = best_model.evaluate(holdout_data)
    
    if val_metrics.accuracy > prev_metrics.accuracy + 0.001:
        # Improvement >= 0.1%
        log_info(f"Model improved: {prev_metrics.accuracy} → {val_metrics.accuracy}")
        
        # Step 7: Deploy to canary if improved
        deploy_canary(new_model, traffic_percent=5)
    else:
        log_info(f"No improvement. {val_metrics.accuracy} vs {prev_metrics.accuracy}")

def detect_covariate_shift(training_data):
    """
    Compare feature distributions: historical vs. new
    Uses Kolmogorov-Smirnov test
    """
    historical_features = get_historical_features(days=30)
    
    from scipy.stats import ks_2samp
    
    max_pvalue = 1.0
    for feature in training_data.columns:
        stat, pvalue = ks_2samp(
            historical_features[feature],
            training_data[feature]
        )
        max_pvalue = min(max_pvalue, pvalue)
        
        if pvalue < 0.05:
            print(f"Feature '{feature}' drifted (p={pvalue})")
    
    return max_pvalue  # Conservative: if any feature drifts, flag it
```

#### Model Retraining Triggers

When should retraining be triggered?

```
Trigger 1: Time-based (default)
├─ Retrain every 6 hours
├─ Simple, predictable
└─ May be overkill (if data unchanged) or too slow (if data changes hourly)

Trigger 2: Performance-based
├─ Retrain if accuracy drops below threshold
├─ Automatic response to degradation
└─ Risk: Might retrain on noisy signal

Trigger 3: Data-drift based
├─ Retrain if input distribution shifted
├─ Proactive: catches changes before accuracy drops
└─ Most sophisticated, requires monitoring setup

Trigger 4: Hybrid (recommended)
├─ Time: Minimum every 6 hours
├─ Performance: Alert if accuracy < 90% (retrain immediately)
├─ Data: Alert if drift p-value < 0.05 (staged retrain)
└─ Result: Balanced approach across predictability, responsiveness, cost
```

**Trigger implementation in Airflow**:

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.trigger_rule import TriggerRule
from datetime import datetime, timedelta

default_args = {
    'owner': 'ml-platform',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'online_learning_pipeline',
    default_args=default_args,
    schedule_interval='0 */6 * * *',  # Every 6 hours
    catchup=False,
)

def check_retraining_needed(**context):
    """
    Determine if retraining is necessary
    Returns: 'retrain' or 'skip'
    """
    # Check 1: How long since last retrain?
    last_retrain_time = get_model_metadata('last_retrain_timestamp')
    time_since_retrain = (datetime.now() - last_retrain_time).total_seconds() / 3600
    
    if time_since_retrain > 24:  # Force retrain every 24 hours
        return 'retrain'
    
    # Check 2: Model performance degraded?
    current_accuracy = evaluate_production_model()
    if current_accuracy < 0.90:
        return 'retrain'
    
    # Check 3: Drift detected?
    drift_pvalue = detect_drift_in_recent_data()
    if drift_pvalue < 0.05:
        return 'retrain'
    
    return 'skip'

decide_retrain = PythonOperator(
    task_id='decide_if_retrain_needed',
    python_callable=check_retraining_needed,
    dag=dag,
)

trigger_retraining = TriggerDagRunOperator(
    task_id='trigger_retraining_dag',
    trigger_dag_id='model_training_pipeline',
    trigger_rule=TriggerRule.ALL_SUCCESS,
    dag=dag,
    execution_date="{{ task_instance.xcom_pull(task_ids='decide_retrain') }}",
)

decide_retrain >> trigger_retraining
```

#### Monitoring Online Learning Models

Online learning models require specialized monitoring:

```
Standard ML Monitoring:
├─ Accuracy on test set: 92%
├─ Precision/Recall: 0.91 / 0.93
└─ Inference latency: 45ms

Online Learning ADDITIONAL Monitoring:
├─ Model freshness: Last trained 2 hours ago (SLA: 6 hours)
├─ Training data quality: 99.5% non-null (SLA: > 99%)
├─ Drift p-value: 0.08 (SLA: > 0.05)
├─ Warm-start convergence: 50 steps (SLA: < 200)
├─ Retraining success rate: 95% (SLA: > 90%)
├─ Canary metrics: 93.1% accuracy vs 92.9% baseline (OK to rollout)
└─ Production model age: 3 hours (SLA: < 6 hours)

Alerts:
├─ If model_freshness > 12 hours: Page on-call
├─ If drift_pvalue < 0.01 (strong drift): Investigate immediately
├─ If training_success_rate < 80%: Debug training pipeline
├─ If retraining time > 2 hours: Optimize (data too large?)
```

### Practical Code Examples

#### Shell Script: Online Learning Monitoring Dashboard

```bash
#!/bin/bash
# monitor_online_learning.sh
# Query metrics for online learning health

set -e

MODEL_NAME="recommendation-v2"
ALERT_EMAIL="ml-team@company.com"

echo "=== Online Learning Model Monitoring ==="
echo "Model: $MODEL_NAME"
echo "Updated: $(date)"
echo ""

# Query 1: Model freshness
LAST_TRAINED=$(curl -s http://mlflow-api/models/$MODEL_NAME/metadata | jq -r '.last_trained')
HOURS_SINCE_TRAIN=$(( ($(date +%s) - $(date -d "$LAST_TRAINED" +%s)) / 3600 ))

echo "Model Freshness:"
echo "  Last trained: $LAST_TRAINED"
echo "  Hours since training: $HOURS_SINCE_TRAIN"

if [ $HOURS_SINCE_TRAIN -gt 12 ]; then
    echo "  ⚠️ WARNING: Model is stale (SLA: 6 hours)"
    echo "Alerts: Model is stale" | mail -s "MLOps Alert" $ALERT_EMAIL
fi

# Query 2: Recent training success rate
RECENT_TRAINS=$(
    kubectl logs -n ml-platform --tail=1000 job/online-learning \
    | grep -c "Training completed successfully" || echo 0
)
RECENT_FAILURES=$(
    kubectl logs -n ml-platform --tail=1000 job/online-learning \
    | grep -c "Training failed" || echo 0
)
SUCCESS_RATE=$(( RECENT_TRAINS * 100 / (RECENT_TRAINS + RECENT_FAILURES) ))

echo ""
echo "Recent Training Jobs:"
echo "  Successful: $RECENT_TRAINS"
echo "  Failed: $RECENT_FAILURES"
echo "  Success rate: $SUCCESS_RATE%"

if [ $SUCCESS_RATE -lt 80 ]; then
    echo "  ⚠️ WARNING: Low success rate"
fi

# Query 3: Data quality
DATA_QUALITY=$(
    curl -s http://feature-store-api/quality-check | jq -r '.nullness_percentage'
)

echo ""
echo "Data Quality:"
echo "  Null values: $DATA_QUALITY%"

if (( $(echo "$DATA_QUALITY > 1.0" | bc -l) )); then
    echo "  ⚠️ WARNING: High nullness"
fi

# Query 4: Drift detection
DRIFT_PVALUE=$(
    curl -s http://ml-monitor-api/drift/$MODEL_NAME | jq -r '.ks_statistic_pvalue'
)

echo ""
echo "Data Drift:"
echo "  KS test p-value: $DRIFT_PVALUE"

if (( $(echo "$DRIFT_PVALUE < 0.05" | bc -l) )); then
    echo "  ⚠️ ALERT: Significant drift detected"
fi

# Query 5: Model performance trend
ACCURACY_7DAG=$(
    curl -s http://ml-monitor-api/metrics/$MODEL_NAME?window=7days | jq -r '.accuracy_mean'
)
ACCURACY_TODAY=$(
    curl -s http://ml-monitor-api/metrics/$MODEL_NAME?window=1day | jq -r '.accuracy_mean'
)
ACCURACY_DELTA=$(echo "$ACCURACY_TODAY - $ACCURACY_7DAG" | bc)

echo ""
echo "Model Performance Trend:"
echo "  7-day average accuracy: $ACCURACY_7DAG"
echo "  Today's accuracy: $ACCURACY_TODAY"
echo "  Change: $ACCURACY_DELTA (baseline: -0.01 = alert)"

if (( $(echo "$ACCURACY_DELTA < -0.01" | bc -l) )); then
    echo "  ⚠️ ALERT: Significant performance drop"
fi

echo ""
echo "=== Summary ==="
if [ $HOURS_SINCE_TRAIN -gt 12 ] || [ $SUCCESS_RATE -lt 80 ] || \
   (( $(echo "$DRIFT_PVALUE < 0.05" | bc -l) )) || \
   (( $(echo "$ACCURACY_DELTA < -0.01" | bc -l) )); then
    echo "Status: ❌ UNHEALTHY - Action required"
    exit 1
else
    echo "Status: ✅ HEALTHY"
    exit 0
fi
```

### ASCII Diagrams

#### Online Learning Training Loop

```
                   CONTINUOUS CYCLE (Every 6 Hours)
                                                                                    
    ┌─────────────────────────────────────────────────────┐
    │  Data Stream: User events (likes, clicks, views)    │
    │  Rate: 1M events/min, 24h storage in Kafka          │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
    ┌─────────────────────────────────────────────────────┐
    │  Collect ground truth (labels arrived ~24h later)   │
    │  Join with features using event timestamp           │
    │  Result: 500k (features, label) pairs               │
    └──────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┴─────────────┐
          │                          │
          ▼                          ▼
    ┌───────────────┐        ┌──────────────────┐
    │ DRIFT CHECK   │        │ QUALITY CHECK    │
    │               │        │                  │
    │ Historic      │        │ KS test:         │
    │ features:     │        │ p-value =        │
    │ Jan-Mar       │        │ 0.08 (no drift)  │
    │ vs current    │        │                  │
    └───────┬───────┘        │ Nullness:        │
            │ p=0.08         │ 0.1% (good)      │
            │ (p>0.05=OK)    └──────┬───────────┘
            └────────────┬──────────┘
                         │
                         ▼
          IF QUALITY OK OR DRIFT LOW:
                         │
                         ▼
    ┌─────────────────────────────────────────────────────┐
    │  Load current production model (v1.2.5)             │
    │  Initialize with production weights (warm-start)    │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
    ┌─────────────────────────────────────────────────────┐
    │  Mini-batch training (SGD, 5 epochs)                │
    │  ├─ Batch size: 256                                 │
    │  ├─ Learning rate: 0.001 (adaptive decay)          │
    │  ├─ Regularization: L2=0.0001                       │
    │  └─ Time: 30 minutes (GPU)                          │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
    ┌─────────────────────────────────────────────────────┐
    │  Validation on holdout set (20% recent data)        │
    │  ├─ New model accuracy: 92.1%                       │
    │  ├─ Production accuracy: 92.0%                      │
    │  └─ Improvement: +0.1% ✓                            │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
    ┌─────────────────────────────────────────────────────┐
    │  DEPLOY TO CANARY                                   │
    │  ├─ Route 5% traffic to new model (v1.2.6)         │
    │  ├─ Monitor for 1 hour                              │
    │  ├─ Compare metrics: accuracy, latency, etc.       │
    │  └─ If healthy → 50% → 100% traffic               │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
         MODEL v1.2.6 NOW IN PRODUCTION
                       │
    ┌──────────────────┴──────────────────┐
    │  Next cycle in 6 hours               │
    │  Increment version: v1.2.7 (ready)   │
    └──────────────────────────────────────┘
```

---

## A/B Testing & Canary Deployments

### Overview
Deploy model changes safely by gradually rolling out to traffic, measuring impact on business metrics, and automatically reverting on degradation. This section covers A/B test design, canary deployment orchestration, traffic splitting strategies, and statistical validation.

### Textual Deep Dive: Internal Working Mechanisms

#### A/B Testing Concepts for ML

A/B testing in ML differs from software A/B testing: model outputs are continuous/probabilistic, introducing statistical complexity.

```
Software A/B Test:
User A: Uses feature X (on/off binary)
User B: Doesn't use feature X (control)
Metric: Did feature increase conversion? (clear yes/no)

ML Model A/B Test:
User A: Sees ranking from model v1.0
User B: Sees ranking from model v1.1
Metric: Which ranking improved CTR? (statistical significance needed)
        ├─ Model v1.0: 2.1% CTR (10,000 impressions)
        ├─ Model v1.1: 2.15% CTR (10,000 impressions)
        ├─ Raw difference: +0.05% (could be noise!)
        └─ Statistical test: p-value = 0.08 (not significant at 0.05 level)
           → Don't ship v1.1 (might hurt due to random variation)
```

**Key ML-specific challenges**:
1. **Multiple testing problem**: Run 10 A/B tests on same metric = false positive rate inflates
2. **Long tail effects**: Improvement on median user might hurt tail  users
3. **Fairness trade-offs**: New model might improve overall accuracy but hurt minority group
4. **Delayed feedback**: Recommendation CTR feedback delayed 1-7 days

#### Canary Deployment Strategies for ML

Canary deployment is the safest way to roll out model changes:

```
FULL ROLLOUT (risky):
  100% traffic gets new model instantly
  ├─ If bug: All users affected before anyone notices
  ├─ Bluegreen + rollback recovery: 30+ minutes
  └─ Worst case: 500k users see bad recommendations for 30 min

CANARY DEPLOYMENT (safe):
  ├─ Deploy new model to 1% traffic (10k users)
  ├─ Monitor metrics every minute
  ├─ After 1 hour: increase to 5% (50k users)
  ├─ If problem detected: immediate rollback (1 min recovery)
  ├─ If metrics healthy: increase to 50%, then 100%
  └─ Total deployment: 3-4 hours (gradual)
     ├─ 10-60k users affected in each step (staggered)
     └─ Degradation caught early with minimal blast radius
```

**Metrics monitored during canary**:

```
Real-time (monitored every minute):
├─ Error rate (4xx, 5xx responses)
├─ Latency (p50, p95, p99)
├─ Inference timeout rate
└─ If any spike: ROLLBACK IMMEDIATELY

Business metrics (monitored every 5 minutes):
├─ CTR (click-through rate)
├─ Conversion rate
├─ Revenue per user
├─ User retention
└─ If regressing: ROLLBACK

Model metrics (monitored every 30 minutes):
├─ Model confidence (uncertainty)
├─ Drift detection (is model seeing new distribution?)
└─ Calibration (are probabilities reliable?)
```

#### Shadow Deployment Strategies

Shadow deployment validates model changes without affecting users:

```
PRODUCTION REQUEST:
     ├─ Main path: Serve prediction from model v1.0 (current)
     │             ├─ Return result to user
     │             └─ Log: [user_id, item_id, v1.0_score, timestamp]
     │
     └─ Shadow path (parallel, async):
                   ├─ Compute prediction from model v1.1 (candidate)
                   ├─ Don't return to user
                   └─ Log: [user_id, item_id, v1.1_score, timestamp]
                         (attached to same request_id)

ANALYSIS (next day):
├─ Match v1.0 logs with v1.1 logs (same request_id)
├─ Count: How many times did v1.1 rank differently?
├─ Calculate: Agreement percentage, ranking differences
├─ Statistical test: Is ranking significantly different?
└─ Decision:
   ├─ If similar: Ship v1.1 (low risk)
   ├─ If very different: Investigate why (could be good or bad)
   └─ Keep detailed analytics for post-deployment analysis
```

**Shadow deployment advantages**:
- Zero user impact (predictions don't affect serving)
- Full traffic validation (not just 5% canary)
- Can run complex offline analysis

**Shadow deployment disadvantages**:
- Requires 2x compute (run both models)
- Can't detect online behavioral shifts (users interact with recommendations differently)

#### Traffic Splitting Strategies

**Strategy 1: Percentage-based traffic splitting**

```
Load balancer splits traffic:
├─ 95% to model v1.0 (current champion)
├─ 5% to model v1.1 (candidate, canary)
└─ Each user request goes to ONE model (not both)

After 1 hour of monitoring (10k requests to canary):
├─ If metrics OK: shift to 50/50 split
├─ If metrics OK: shift to 100% v1.1

Pros: ✓ Simple to implement, ✓ gradual rollout
Cons: ✗ Takes 3-4 hours, ✗ only 5% users in initial test
```

**Strategy 2: User ID-based traffic splitting (consistent hashing)**

```
Assignment based on user_id hash:
├─ user_id % 100 < 5: model v1.1 (consistent for same user)
├─ user_id % 100 >= 5: model v1.0

Benefit: Each user always gets same model
  ├─ User A always sees v1.1 (across all requests)
  └─ User B always sees v1.0

Why needed: Models might return different rankings
  ├─ If recommendation changes mid-session, confusing to user
  └─ Consistent hashing ensures all rankings from same model
```

**Strategy 3: Context-based splitting (geographic, device, etc.)**

```
Route based on context:
├─ US users: model v1.1 (fast shipping predictions optimized for US)
├─ EU users: model v1.0 (existing proven model)
├─ Mobile users: model v1.1 (mobile-optimized architecture)
├─ Desktop users: model v1.0

Benefit: Different models for different use cases
  ├─ Mobile: lightweight model (10MB, 50ms latency)
  └─ Desktop: heavyweight model (200MB, 100ms latency)
```

**Strategy 4: Time-based canary ramp**

```
Automated traffic increase over time:
├─ Hour 0-1: 1% (10k users)
├─ Hour 1-2: 5% (50k users)
├─ Hour 2-3: 25% (250k users)
├─ Hour 3-4: 50% (500k users)
├─ Hour 4+: 100% (if all metrics healthy)

If any metric crosses threshold (e.g., error rate > 0.5%):
└─ Automatic rollback to previous step
   └─ Wait 30 min, then retry with slower ramp
```

#### Metrics for A/B Testing in ML

**Primary metrics** (business-critical):
- CTR (recommendation systems): clicks / impressions
- Conversion rate (e-commerce): purchases / sessions
- Revenue: total revenue / user
- Retention: % users active after 7 days

**Statistical requirements**:
- Sample size: Need 10k-100k samples per variant (depends on baseline and effect size)
- Duration: Need 1-7 days to capture full user behavior cycle
- Statistical test: Chi-squared for categorical, t-test for continuous

**Secondary metrics** (user experience):
- Latency: p50, p95, p99
- Error rate
- Cache hit rate (inference efficiency)

**Model-specific metrics**:
- Model confidence (average predicted probability)
- Prediction change rate (% of rankings different from v1.0)
- Fairness metrics: CTR by demographic group (ensure no disparity)

#### Implementation of A/B Testing for ML

**End-to-end A/B testing system**:

```python
# A/B testing framework
class ABTestController:
    def __init__(self, name, model_a, model_b):
        self.name = name
        self.model_a = model_a  # Current champion
        self.model_b = model_b  # Candidate
        self.test_start = datetime.now()
    
    def route_request(self, user_id, request_data):
        """Determine which model should serve this request"""
        
        # Consistent user assignment (same user always gets same variant)
        variant = "A" if (user_id % 100) < 95 else "B"
        
        model = self.model_a if variant == "A" else self.model_b
        
        # Make prediction
        predictions = model.predict(request_data)
        
        # Log for analysis
        log_entry = {
            'timestamp': datetime.now(),
            'user_id': user_id,
            'variant': variant,
            'predictions': predictions,
            'request_id': request_data['request_id'],
        }
        self.log_to_analytics(log_entry)
        
        return predictions
    
    def check_winner(self):
        """
        Statistical test to determine if variant B is significantly better
        Returns: 'champion' (A wins), 'challenger' (B wins), 'inconclusive'
        """
        
        # Collect metrics
        metrics_a = self.get_metrics(variant="A")
        metrics_b = self.get_metrics(variant="B")
        
        # Example: CTR comparison using Chi-squared test
        from scipy.stats import chi2_contingency
        
        contingency_table = [
            [metrics_a['clicks'], metrics_a['impressions'] - metrics_a['clicks']],
            [metrics_b['clicks'], metrics_b['impressions'] - metrics_b['clicks']],
        ]
        
        chi2, pvalue, dof, expected = chi2_contingency(contingency_table)
        
        ctr_a = metrics_a['clicks'] / metrics_a['impressions']
        ctr_b = metrics_b['clicks'] / metrics_b['impressions']
        
        # Require:
        # 1. Statistical significance: p < 0.05
        # 2. Practical significance: CTR improvement > 1%
        # 3. Minimum sample size: 10k impressions per variant
        
        min_samples = 10000
        if metrics_b['impressions'] < min_samples:
            return 'inconclusive', {'reason': 'insufficient_samples'}
        
        if pvalue > 0.05:
            return 'inconclusive', {'pvalue': pvalue}
        
        if ctr_b > ctr_a * 1.01:  # 1% improvement required
            return 'challenger', {'ctr_improvement': (ctr_b - ctr_a) / ctr_a}
        elif ctr_b < ctr_a * 0.99:  # If worse: champion wins
            return 'champion', {'ctr_regression': (ctr_a - ctr_b) / ctr_a}
        else:
            return 'inconclusive', {'reason': 'no_practical_improvement'}
```

### ASCII Diagrams

#### Canary Deployment with Automated Rollback

```
CANARY DEPLOYMENT ORCHESTRATION

Hour 0:00 - DEPLOYMENT BEGINS (5% canary)
       ┌─────────────────────────────────────────────┐
       │ Load Balancer                               │
       ├─────────────────────────────────────────────┤
       │ ┌─────────────┐ 95%  ┌─────────────────┐   │
       │ │ Model v1.0  │─────►│ Users (900k)    │   │
       │ │ (Champion)  │      └─────────────────┘   │
       │ └─────────────┘                            │
       │                                             │
       │ ┌─────────────┐ 5%   ┌──────────────────┐  │
       │ │ Model v1.1  │─────►│ Users (100k)     │  │
       │ │ (Canary)    │      │ Monitoring:      │  │
       │ └─────────────┘      │ ├─ latency       │  │
       │                      │ ├─ error rate    │  │
       │                      │ ├─ CTR           │  │
       │                      │ └─ revenue/user  │  │
       │                      └──────────────────┘  │
       └─────────────────────────────────────────────┘
              │
              ▼ (monitoring pipeline)
       ┌─────────────────────────────────────────────┐
       │ Metrics Processor (Flink/Spark)             │
       ├─────────────────────────────────────────────┤
       │ Calculate per-variant metrics every minute: │
       │ ├─ v1.0: error_rate=0.01%, latency=45ms    │
       │ ├─ v1.1: error_rate=0.01%, latency=47ms    │
       │ └─ Status: ✓ HEALTHY → Continue            │
       └─────────────────────────────────────────────┘

Hour 1:00 - INCREASE TO 50% (still healthy)
       ┌─────────────────────────────────────────────┐
       │ Load Balancer                               │
       ├─────────────────────────────────────────────┤
       │ ┌─────────────┐ 50%  ┌──────────────────┐   │
       │ │ Model v1.0  │─────►│ Users (500k)     │   │
       │ └─────────────┘      └──────────────────┘   │
       │                                             │
       │ ┌─────────────┐ 50%  ┌──────────────────┐   │
       │ │ Model v1.1  │─────►│ Users (500k)     │   │
       │ └─────────────┘      │ ├─ latency=46ms  │   │
       │                      │ ├─ CTR=2.12%*    │   │
       │                      │ │ (*baseline 2.1%)  │   │
       │                      │ └─ ✓ IMPROVING      │   │
       │                      └──────────────────┘   │
       └─────────────────────────────────────────────┘

Hour 2:00 - ERROR DETECTED! (automatic rollback)
       ┌─────────────────────────────────────────────┐
       │ Metrics Alert:                              │
       │ ├─ Error rate v1.1 spike: 0.01% → 2.5%    │
       │ ├─ Latency p99: 47ms → 250ms (timeout!)   │
       │ └─ ⚠️ THRESHOLD EXCEEDED                    │
       └────────────┬────────────────────────────────┘
                    │
                    ▼ (trigger automatic rollback)
       ┌─────────────────────────────────────────────┐
       │ Rollback Action:                            │
       │ ├─ Set traffic: v1.1 from 50% → 0%        │
       │ ├─ Alert on-call engineer                   │
       │ ├─ Create incident: "Model v1.1 latency"   │
       │ └─ Log decision: timestamp, reason, metrics│
       └────────────┬────────────────────────────────┘
                    │
                    ▼ (after 5 min)
       ┌─────────────────────────────────────────────┐
       │ Load Balancer                               │
       ├─────────────────────────────────────────────┤
       │ ┌─────────────┐ 100% ┌─────────────────┐   │
       │ │ Model v1.0  │─────►│ All Users       │   │
       │ └─────────────┘      └─────────────────┘   │
       │                                             │
       │ Status: ✓ ROLLED BACK                       │
       │ Blast radius: 500k users affected for 5min  │
       └─────────────────────────────────────────────┘

INVESTIGATION PHASE:
├─ Why did v1.1 timeout?
│  └─ Root cause: New feature computation slow
│     (50ms additional per request at scale = overload)
├─ Resolution:
│  └─ Optimize feature; reduce to 5ms overhead
├─ Testing:
│  └─ Validate on staging with prod-like traffic
└─ Retry deployment (next week with optimized model)
```

### Best Practices

1. **Establish clear success criteria before deploying**
   - What metrics matter? CTR, conversion, revenue?
   - What improvement threshold justifies shipping? (1%, 5%?)
   - What's the maximum acceptable degradation? (auto-rollback point)

2. **Monitor on multiple time scales**
   - Real-time (1 min): Catch infrastructure issues
   - Tactical (30 min): Catch model issues
   - Strategic (day): Catch fairness/bias issues

3. **Use multiple analysis windows**
   - Different times of day matter (morning vs. night user behavior)
   - Day-of-week matters (weekday vs. weekend)
   - Ensure test runs 24-48+ hours for representative data

4. **Protect against multiple testing**
   - Run ONE primary metric test
   - Secondary metrics are exploratory only
   - Adjust p-value threshold if running multiple tests

---

## Edge & Real-Time ML Deployments

### Overview
Deploy models on edge devices (phones, IoT, embedded systems) with extreme latency constraints, limited resources, and increasingly offline-first requirements. This section covers model optimization techniques, edge deployment architectures, and operational challenges specific to distributed edge devices.

### Textual Deep Dive: Internal Working Mechanisms

#### Edge ML Concepts

Edge ML requires rethinking deployment architecture fundamentally:

```
CLOUD ML DEPLOYMENT:
Data Center (GPU servers)
├─ Model size: 200MB
├─ Latency: 100ms (network + compute)
├─ Compute: 10 cores, 32GB RAM
├─ Power: AC mains
├─ Connectivity: Always-on fiber
└─ Use: Real-time predictions for web/mobile apps

EDGE ML DEPLOYMENT:
├─ On device (phone, smartwatch, IoT):
│  ├─ Model size: 5-50MB (must fit in device storage)
│  ├─ Latency: 10-100ms (no network!)
│  ├─ Compute: 2-4 cores, 2-4GB RAM
│  ├─ Power: Battery, must be power-efficient
│  ├─ Connectivity: Intermittent (3G, WiFi drops)
│  └─ Use: Instant feedback (no server round-trip)
│
└─ Model must be:
   ├─ Small (10-50MB max for mobile)
   ├─ Fast (inference < 100ms on mobile GPU)
   ├─ Energy-efficient (battery drain critical)
   └─ Self-contained (work offline)
```

#### Edge Inference Pipelines

Edge inference pipeline fundamentally different from cloud:

```
CLOUD PIPELINE:
Request → Network → Server Parse → Feature Fetch → Inference → Response
            ↑ Network latency cost: 50-100ms
└─Total: 150-200ms

EDGE PIPELINE:
Request → Local Storage (instant) → Feature Fetch (local cache) → Inference → Response
└─Total: 10-50ms

OFFLINE EDGE:
Request → (Network unavailable; no connection)
         → Use locally cached features (stale, 1-7 days old)
         → Inference with old model (best available)
         → Cache result, sync when online
```

#### Real-Time ML Deployment Strategies

**Strategy 1: On-device inference**

```
Architecture:
┌───────────────────────────────────┐
│ Mobile App (iOS/Android)          │
│ ├─ TensorFlow Lite model (10MB)   │
│ ├─ Feature cache (Redis Lite)     │
│ └─ Inference engine               │
│                                   │
│ Process:                          │
│ 1. User action (click on photo)   │
│ 2. Extract features (instant)     │
│ 3. Inference (10ms, on GPU)       │
│ 4. Return prediction (instant)    │
└───────────────────────────────────┘

Latency breakdown:
├─ Feature extraction: 2ms
├─ Inference: 8ms
└─ Total: 10ms (vs. 150ms on cloud!)

Benefit: Instant feedback; no network dependency
Downside: Can't update model w/o app update; battery drain
```

**Strategy 2: Hybrid cloud + edge**

```
                     ┌─ Network available?
                     │
             ┌───────┴────────┐
             │                │
            YES              NO
             │                │
             ▼                ▼
       ┌──────────┐      ┌──────────┐
       │ Cloud    │      │ On-device│
       │ Inference│      │ Inference│
       │ (complex)│      │ (simple) │
       └──────────┘      └──────────┘
             │                │
             └────────┬───────┘
                      │
             ┌────────▼────────┐
             │ Return prediction
             │ with source tag
             └──────────────────┘

Decision logic:
├─ If network strong + time available: Use cloud (better model)
├─ If network weak/offline: Use edge (degraded but working)
└─ Log which model used for analysis
```

**Strategy 3: Federated learning (distributed training on edge devices)**

```
Traditional: Models trained on central servers
            ├─ Data collected from 1M devices
            ├─ Sent to cloud (privacy risk!)
            ├─ Central training
            └─ Model broadcast back

Federated: Training happens on devices
          ├─ Each device trains on LOCAL data (privacy preserved!)
          ├─ Model updates (gradients only) sent to server
          ├─ Server aggregates: gradient averaging
          └─ Improved model broadcast back
          
Private data never leaves device!
Only gradient updates transferred (smaller, anonymized)
```

#### Resource Constraints for Edge ML

**Memory constraints**:

```
Typical mobile device: 4GB RAM
├─ OS: 1GB
├─ Running apps: 500MB
├─ Browsing cache: 200MB
└─ Available for inference: ~2GB (max)

Challenge: 
├─ DL model + runtime: 500MB
├─ Feature store: 500MB
├─ Data buffering: 200MB
└─ Leaves only 300MB free
   
If app tries to allocate more: OOM crash!

Solution: Model quantization (reduce size 4-10x)
```

**Compute constraints**:

```
Cloud GPU (NVIDIA A100):
├─ 10,000 TFLOPS (trillion floating-point ops/sec)
├─ Inference: 200 images/sec (5ms per image)

Mobile GPU (Apple Neural Engine):
├─ 16 TFLOPS
├─ Inference: 30 images/sec (33ms per image = 6.5x slower)

Battery impact:
├─ 30 sec of heavy ML compute = 5% battery drain
├─ Long inference runs = dead battery in minutes
```

**Network constraints**:

```
Cloud deployment (always-on connectivity assumed):
├─ Latency: 50-100ms
├─ Bandwidth: 10+ Mbps available
└─ Can stream video for inference

Edge deployment (unreliable connectivity):
├─ 3G: 5+ sec latency, 500 Kbps bandwidth (slow!)
├─ WiFi: Variable (100ms-1sec latency drops)
└─ Offline: Must work without network

Implication: Can't stream video; must buffer and compress locally
```

#### Model Optimization for Edge Deployment

**Technique 1: Quantization (reduce precision, save memory)**

```
Full precision (FP32):
├─ Each weight: 4 bytes
├─ Model size: 200MB
├─ Inference latency: 100ms

Quantization (INT8):
├─ Each weight: 1 byte (4x reduction!)
├─ Model size: 50MB
├─ Inference latency: 25ms (4x faster!)
├─ Accuracy loss: 0.1-1% (usually acceptable)

Process:
1. Train model normally (FP32)
2. Range analysis: What are min/max weights?
   ├─ Min weight: -0.5, Max weight: +0.8
3. Map to INT8 range: [-128, 127]
   ├─ -0.5 → -128, +0.8 → +127
4. During inference: Convert INT8 back to FP32 range
5. Result: 4x smaller, 4x faster, similar accuracy!
```

**Technique 2: Pruning (remove unnecessary weights)**

```
Unimportant weights (near zero): Remove them
├─ Original model: 100M parameters
├─ Remove 50% unimportant weights: 50M parameters

Result:
├─ Model size: 50% reduction
├─ Inference speed: 40-50% faster (due to sparse operations)
├─ Accuracy: Minimal impact (removed weights contributed little)
```

**Technique 3: Knowledge distillation (compress into smaller model)**

```
Teacher model (large, accurate):
├─ 200MB, 92% accuracy on test set
└─ Train student model to mimic it

Student model (small, approximate):
├─ Can be 10-50MB
├─ Trained to match teacher predictions
├─ Usually achieves 90-91% accuracy (close to teacher!)

Why effective?
├─ Student doesn't need to learn from raw data
├─ Student learns from teacher's outputs (smoother targets)
└─ Compression with minimal accuracy loss
```

#### Low Latency Serving

**Latency optimization techniques**:

```
Baseline: Model inference takes 100ms on mobile

1. Pre-compute features (50ms saved):
   ├─ Don't compute features at request time
   ├─ Pre-compute and cache in device
   ├─ Just do table lookup
   └─ Result: 100ms → 50ms

2. Batch inference (30ms saved on multiple requests):
   ├─ Instead of 1 inference per request
   ├─ Accumulate 10 requests, batch them
   ├─ 10 inferences in 30ms (3ms each)
   └─ Trade: 0-3ms additional latency for throughput

3. GPU offload (20ms saved):
   ├─ CPU inference: 50ms
   ├─ GPU inference: 30ms (GPU parallelism)
   └─ Requires: Model compatible with GPU
             (not all ops supported)

4. Model architecture choice (50ms saved):
   ├─ Complex model (ResNet-152): 100ms
   ├─ Efficient model (MobileNet-v3): 50ms
   ├─ Same task, 2x latency difference!
   └─ Trade-off: Accuracy vs. latency
```

### Practical Code Examples

#### Python Script: Model Quantization for Mobile

```python
#!/usr/bin/env python3
# quantize_model.py
# Converts TensorFlow model to quantized TFLite for mobile

import tensorflow as tf
import numpy as np

def representative_data_gen():
    """Generate representative data for quantization calibration"""
    # Use 10% of training data as calibration set
    calibration_data = load_training_data(sample_size=10000)
    
    for sample in calibration_data:
        # Convert to tf.float32 tensor
        yield [np.asarray(sample, dtype=np.float32)]

def quantize_model(model_path, output_path):
    """
    Convert TensorFlow model to quantized TFLite format
    
    Input: model_path (trained TensorFlow model)
    Output: quantized TFLite model (1/4 size, 4x faster)
    """
    
    # Load trained model
    converter = tf.lite.TFLiteConverter.from_saved_model(model_path)
    
    # Enable quantization-aware optimization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Provide representative data for quantization
    converter.representative_data_gen = representative_data_gen
    
    # Quantize weights and activations
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
    ]
    
    # Set inference type
    converter.inference_input_type = tf.uint8
    converter.inference_output_type = tf.uint8
    
    # Convert
    quantized_tflite_model = converter.convert()
    
    # Save
    with open(output_path, 'wb') as f:
        f.write(quantized_tflite_model)
    
    print(f"Quantized model saved: {output_path}")
    
    # Compare sizes
    original_size = os.path.getsize(f"{model_path}/model.pb")
    quantized_size = len(quantized_tflite_model)
    
    print(f"Original size: {original_size / 1e6:.1f}MB")
    print(f"Quantized size: {quantized_size / 1e6:.1f}MB")
    print(f"Compression: {(1 - quantized_size/original_size) * 100:.0f}%")

if __name__ == "__main__":
    quantize_model(
        model_path="models/recommendation_model",
        output_path="models/recommendation_model_quantized.tflite"
    )
```

#### Shell Script: Build and Deploy Mobile ML Model

```bash
#!/bin/bash
# deploy_mobile_model.sh
# Builds optimized model and uploads to app distribution

set -e

MODEL_VERSION=$1
PLATFORM=${2:-ios}  # ios or android

echo "=== Mobile ML Model Deployment ==="
echo "Model: recommendation_v$MODEL_VERSION"
echo "Platform: $PLATFORM"

# Step 1: Quantize model for mobile
echo "Step 1: Quantizing model..."
python3 quantize_model.py \
  --input="models/recommendation_v${MODEL_VERSION}.pb" \
  --output="build/model_v${MODEL_VERSION}.tflite"

# Step 2: Verify model on test device
echo "Step 2: Testing on device..."
if [ "$PLATFORM" = "ios" ]; then
    xcodebuild test \
      -scheme MobileApp \
      -destination generic/platform=iOS
elif [ "$PLATFORM" = "android" ]; then
    ./gradlew connectedAndroidTest \
      -Pmodel_version=$MODEL_VERSION
fi

# Step 3: Check model size
MODEL_SIZE=$(du -h "build/model_v${MODEL_VERSION}.tflite" | cut -f1)
echo "Model size: $MODEL_SIZE"

if (( $(echo "$MODEL_SIZE > 50MB" | bc -l) )); then
    echo "⚠️ WARNING: Model > 50MB (consider further optimization)"
fi

# Step 4: Sign model (integrity verification)
echo "Step 3: Signing model..."
openssl dgst -sha256 \
  -sign private_key.pem \
  "build/model_v${MODEL_VERSION}.tflite" \
  > "build/model_v${MODEL_VERSION}.tflite.sig"

# Step 5: Upload to distribution system
echo "Step 4: Uploading to distribution..."
gsutil cp \
  "build/model_v${MODEL_VERSION}.tflite" \
  "gs://ml-models-distribution/mobile/model_v${MODEL_VERSION}.tflite"

gsutil cp \
  "build/model_v${MODEL_VERSION}.tflite.sig" \
  "gs://ml-models-distribution/mobile/model_v${MODEL_VERSION}.tflite.sig"

# Step 6: Update app manifest
echo "Step 5: Updating app configuration..."
cat > "app_config.json" <<EOF
{
  "model_version": "$MODEL_VERSION",
  "model_url": "gs://ml-models-distribution/mobile/model_v${MODEL_VERSION}.tflite",
  "model_signature": "gs://ml-models-distribution/mobile/model_v${MODEL_VERSION}.tflite.sig",
  "deployment_date": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "fallback_version": "$(($MODEL_VERSION - 1))"
}
EOF

# Step 7: Trigger app update
echo "Step 6: Triggering app update..."
firebase distribution:groups:add model-testers dev-devices
firebase appdistribution:distribute build/app-release.apk \
  --groups=model-testers \
  --release-notes="Updated ML model to v${MODEL_VERSION}"

echo "✅ Deployment complete!"
echo "   Model v${MODEL_VERSION} available for testing"
echo "   Rollback version: v$(($MODEL_VERSION - 1))"
```

### ASCII Diagrams

#### Edge ML Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│        CLOUD: Model Training & Optimization     │
│                                                 │
│  ┌──────────────────────────────────────┐      │
│  │ Training (TensorFlow, PyTorch)       │      │
│  │ ├─ 200MB model, 92% accuracy         │      │
│  │ └─ Too large for mobile              │      │
│  └──────────────┬───────────────────────┘      │
│                 │                               │
│  ┌──────────────▼───────────────────────┐      │
│  │ Model Optimization Pipeline          │      │
│  │ ├─ Quantization (FP32 → INT8)        │      │
│  │ ├─ Pruning (remove 50% weights)      │      │
│  │ ├─ Knowledge distillation (compress) │      │
│  │ └─ Result: 50MB, 90% accuracy        │      │
│  └──────────────┬───────────────────────┘      │
│                 │                               │
│  ┌──────────────▼───────────────────────┐      │
│  │ Testing & Validation                 │      │
│  │ ├─ Accuracy on test set: 90%        │      │
│  │ ├─ Latency on iPhone: 25ms           │      │
│  │ ├─ Battery impact: 5%/hour           │      │
│  │ └─ Size: 45MB (fits app size limit)  │      │
│  └──────────────┬───────────────────────┘      │
│                 │                               │
└─────────────────┼───────────────────────────────┘
                  │
          ┌───────▼────────┐
          │  App Store /   │
          │  Model Server  │
          └───────┬────────┘
                  │
        ┌─────────┼─────────────┐
        │         │             │
        ▼         ▼             ▼
    ┌─────────┐ ┌────────┐ ┌──────────┐
    │ iPhone  │ │Android │ │IoT Device│
    ├─────────┤ ├────────┤ ├──────────┤
    │ Model   │ │Model   │ │Model     │
    │ 45MB    │ │50MB    │ │10MB      │
    │         │ │        │ │         │
    │ Online: │ │Online: │ │Always   │
    │ Cloud   │ │Cloud   │ │offline  │
    │         │ │        │ │         │
    │ Offline:│ │Offline:│ │Inference│
    │ Instant │ │Instant │ │local    │
    │         │ │        │ │         │
    │ Latency:│ │Latency:│ │Latency: │
    │ <20ms   │ │<30ms   │ │<50ms    │
    └─────────┘ └────────┘ └──────────┘

User Benefits:
├─ Instant feedback (no network latency)
├─ Works offline (no connectivity needed)
├─ Privacy (data never sent to cloud)
└─ Lower power consumption (client-side compute)

Operational Challenges:
├─ Model updates (push new version)
├─ Backward compatibility (old phones, outdated models)
├─ Performance debugging (which device is slow?)
├─ User consent for ML compute (battery/data usage)
```

---

## Advanced Pipeline Architecture

### Overview
Large-scale ML systems require sophisticated pipeline orchestration supporting thousands of jobs, complex interdependencies, dynamic workflows, failure recovery, and multi-tenant resource management. This section covers orchestration patterns, pipeline resilience, and platform design for ML at enterprise scale.

### Textual Deep Dive: Internal Working Mechanisms

#### Advanced Pipeline Design Patterns

**Pattern 1: DAG (Directed Acyclic Graph) orchestration**

```
ML Pipeline as DAG:
       ┌─ Task 1: Data ingestion
       │  ├─ Read data from 10 sources
       │  ├─ Merge into single dataset
       │  └─ Store in data lake
       │
       ▼
   ┌──────────┐
   │ Task 2   │  Data validation
   │ (parallel)├─ Schema check
   │          ├─ Nullness check
   │          └─ Outlier detection
       │
       ▼
   Task 3: Feature engineering (join with features table)
       │
       ├─ Task 4a: Model A training (GPU, 2 hours)
       │
       ├─ Task 4b: Model B training (GPU, 3 hours)
       │  (runs in parallel with 4a)
       │
       ▼
   ┌──────────┐
   │ Task 5   │  Model evaluation
   │ (join)   ├─ Compare accuracy
   │          └─ Statistical test
       │
       ▼
   Task 6: Register winner to model registry
       │
       ▼
   Task 7: Deploy to staging (canary)
       │
       ├─ Task 8a: Smoke tests (run checks on staging)
       │
       ├─ Task 8b: Integration tests (check with data)
       │  (parallel with 8a)
       │
       ▼
   Task 9: Promote to production
```

**Key properties**:
- Tasks run in dependency order (Task 2 waits for Task 1)
- Parallel execution when independent (Tasks 4a + 4b, Tasks 8a + 8b)
- Automatic retry on failure
- Skip downstream if upstream fails

**Pattern 2: Conditional branching**

```python
# Different pipeline paths based on data characteristics
if data_quality_score < 70%:
    # Poor quality: Extra cleaning
    tasks = [
        Task("aggressive_outlier_removal"),
        Task("imputation"),
        Task("rebalancing"),
        Task("training_with_validation_threshold=0.85"),
    ]
elif data_quality_score < 85%:
    # Moderate quality: Standard pipeline
    tasks = [
        Task("standard_outlier_removal"),
        Task("training_with_validation_threshold=0.90"),
    ]
else:
    # High quality: Skip cleaning, go straight to training
    tasks = [
        Task("training_with_validation_threshold=0.92"),
    ]
```

#### Pipeline Orchestration at Scale

**Architecture for managing 1000+ daily jobs**:

```
Orchestrator (Airflow/Kubeflow)
├─ DAG storage: 500 DAG definitions
├─ Job scheduling: 1000-2000 job runs/day
└─ Resource splitting (burst capacity):
   ├─ 200 CPU-only jobs (data pipelines)
   ├─ 300 GPU jobs (model training)
   ├─ 500 small jobs (inference, validation)
   └─ Peak: 1000 jobs/hour (early morning retraining surge)

Resource management:
├─ Kubernetes cluster (500 nodes)
│  ├─ CPU node pool: 300 nodes (for data pipelines)
│  ├─ GPU node pool: 150 nodes (p3.8xlarge, V100 GPUs)
│  └─ Spot node pool: 50 nodes (cheap, fault-tolerant jobs)
│
├─ Auto-scaling:
│  ├─ Morning peak (6-9am): 300 nodes → 500 nodes (+67%)
│  ├─ Daytime: 400 nodes (steady-state)
│  └─ Night: 150 nodes (only critical jobs + overnight training)
│
└─ Cost:
   ├─ Steady-state: $50,000/month
   └─ With peak scaling: $70,000/month (+40%)
```

#### Centralised ML Platform Design

```
ML ENGINEERS (lowest level):
├─ Access: Jupyter notebooks, shared compute resources
├─ Restrictions: CPU-only, no GPU
├─ Storage quota: 100GB
└─ Result: Rapid experimentation, low risk

DATA SCIENTISTS (mid-level):
├─ Access: Feature store, model registry, training
├─ Capabilities: Train models, submit jobs, register models, deploy to staging
├─ Guardrails: Use company templates, include model card, pass fairness tests
└─ Result: Empowered teams, reduced operational toil

PLATFORM ENGINEERS (highest level):
├─ Responsibilities: Build templates, manage registry, deploy production, debug issues
└─ Result: Platform resilience, governance compliance
```

#### Pipeline Resilience Strategies

**Failure modes and solutions**:

```
Failure: Task fails, pipeline stops
Solution 1: Automatic retry with exponential backoff
  ├─ Wait 10s, retry
  ├─ Wait 100s (10x), retry
  ├─ Wait 1000s (10x), retry
  └─ Max 3 retries: alert human if still fails

Failure: Training data unavailable
Solution 2: Graceful degradation
  ├─ Use previous week's data
  ├─ Continue with cached features (1 day old)
  └─ Result: Tolerate failures, continue operating

Failure: Task fails after running 8 of 10 hours
Solution 3: Checkpoint and resume
  ├─ Save state every hour
  ├─ If task fails (after 1h50m checkpoint):
  │  └─ Resume from checkpoint (only re-run last 10m)
  └─ Reduces re-work from 10 hours to 10 minutes
```

### Practical Code Examples

#### Airflow DAG: Production ML Pipeline

```python
from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.kubernetes_pod import KubernetesPodOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'ml-platform',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'recommendation_pipeline_v2',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    tags=['production', 'recommendation'],
)

def check_data_quality():
    """Assess quality of raw data"""
    quality_score = 100 - (0.5 + 0.1 + 0.2)  # nulls + dupes + outliers
    return 'aggressive_clean' if quality_score < 70 else 'standard_train'

data_valid = PythonOperator(
    task_id='data_validation',
    python_callable=lambda: print("Data validation passed"),
    dag=dag,
)

quality_branch = BranchPythonOperator(
    task_id='check_quality',
    python_callable=check_data_quality,
    dag=dag,
)

aggressive_clean = KubernetesPodOperator(
    task_id='aggressive_clean',
    namespace='ml-platform',
    image='ml-platform/data-cleaning:aggressive',
    dag=dag,
)

standard_train = PythonOperator(
    task_id='standard_train',
    python_callable=lambda: print("Starting training"),
    dag=dag,
)

feature_eng = KubernetesPodOperator(
    task_id='feature_engineering',
    namespace='ml-platform',
    image='ml-platform/feature-eng:latest',
    resources={'request': {"memory": "16Gi"}, 'limit': {"memory": "32Gi"}},
    dag=dag,
)

training = KubernetesPodOperator(
    task_id='model_training',
    namespace='ml-platform',
    image='ml-platform/training:v2.1.0',
    resources={'request': {"nvidia.com/gpu": "4"}, 'limit': {"nvidia.com/gpu": "4"}},
    node_selector={'workload': 'ml-training'},
    env_vars={'EPOCHS': '50', 'BATCH_SIZE': '256'},
    trigger_rule='none_failed',
    dag=dag,
)

data_valid >> quality_branch
quality_branch >> [aggressive_clean, standard_train]
[aggressive_clean, standard_train] >> feature_eng >> training
```

### ASCII Diagrams

#### Complete ML Platform Architecture

```
┌──────────────────────────────────────────────────────────┐
│ EXTERNAL DATA SOURCES                                    │
│ └─ Production databases, API feeds, Sensor data         │
└───────────────────────┬──────────────────────────────────┘
                        │
      ┌─────────────────▼──────────────────┐
      │ DATA LAYER (Data ingestion, Lake) │
      │ ├─ Kafka, S3, Data quality        │
      │ └─ Access logging                  │
      └─────────────────┬──────────────────┘
                        │
      ┌─────────────────▼──────────────────┐
      │ FEATURE LAYER (Feature Store)     │
      │ ├─ Online + offline features       │
      │ └─ Lineage, versioning             │
      └─────────────────┬──────────────────┘
                        │
      ┌─────────────────▼──────────────────┐
      │ PIPELINE ORCHESTRATION             │
      │ ├─ Airflow/Kubeflow/Flyte         │
      │ ├─ 1000+ daily DAGs               │
      │ └─ Retry, monitoring               │
      └─────────────────┬──────────────────┘
┌──────────────┬───────────────┬──────────────┐
▼              ▼               ▼              ▼
Training   Batch Inf.   Real-time     (Kubernetes)
(GPU)      (CPU)        Inference
(2-4h)     (30min)      (<100ms)
```

---

---

## Responsible AI Operations

### Overview
Ensure deployed models are fair, explainable, compliant, and auditable. Responsible AI is an operational requirement, not a nice-to-have. This section covers bias detection, fairness engineering, explainability strategies, governance workflows, and compliance tracking.

### Textual Deep Dive: Internal Working Mechanisms

#### Responsible AI Concepts

Responsible AI has four pillars:

```
1. FAIRNESS
   ├─ Models shouldn't discriminate based on protected attributes
   ├─ Protected: race, gender, age, disability, nationality, religion
   ├─ Example problem: Resume screening model rejects women at 40% higher rate
   └─ Example solution: Equalize false negative rate across genders

2. EXPLAINABILITY
   ├─ Users have right to know why model made decision
   ├─ Required by GDPR, Fair Lending, HIPAA regulations
   ├─ Example problem: Model rejects loan but applicant doesn't know why
   └─ Example solution: Top 3 reasons why (SHAP values) provided to applicant

3. TRANSPARENCY
   ├─ Document what model does, doesn't do, edge cases
   ├─ Communicate limitations, not just possibilities
   ├─ Example: Healthcare model 92% accurate for adults, only 60% for children
   └─ Solution: Model card documents performance by age group

4. ACCOUNTABILITY
   ├─ Full audit trail for decisions model makes
   ├─ Who can access model? When was it trained? With what data?
   ├─ Can trace each prediction back to exact model version
   └─ Enables rollback/remediation if issues found
```

#### Bias Detection and Mitigation

**Common bias types**:

```
1. Historical bias
   ├─ Training data reflects past discrimination
   ├─ Example: Historical hiring data shows men promoted more often
   ├─ Model learns this pattern and perpetuates discrimination
   └─ Solution: Pre-process data to balance historical imbalance

2. Representation bias
   ├─ Underrepresented groups in training data
   ├─ Example: Image recognition trained mostly on light skin tones
   ├─ Model performs poorly on dark skin tones
   └─ Solution: Ensure training data representative of population

3. Measurement bias
   ├─ How we measure target variable is flawed
   ├─ Example: Credit score based on past credit (excludes unbanked)
   ├─ Model can't lend to people with no credit history
   └─ Solution: Use alternative data (rental payments, utility bills)

4. Aggregation bias
   ├─ Model works for average group but fails for subgroups
   ├─ Example: Average accuracy 90%, but 50% for elderly users
   ├─ One-size-fits-all model inappropriate
   └─ Solution: Build separate models per demographic group
```

#### Fairness Definitions (Often Conflicting)

```
1. Demographic Parity
   ├─ Approval rate should be same across all groups
   ├─ Female approval rate = Male approval rate
   └─ Strictest fairness, might reduce overall accuracy

2. Equalized Odds
   ├─ False positive rate and true positive rate equal across groups
   ├─ Both majority and minority groups have same error rates
   ├─ More balanced than demographic parity
   └─ Commonly used in practice

3. Calibration
   ├─ For same predicted probability, actual approval rate same
   ├─ Example: 80% predicted probability → 80% actual approval
   ├─ Works for ALL groups (male, female, races)
   └─ Often achievable (less strict constraint)

CHALLENGE: Can't satisfy all fairness definitions simultaneously!
├─ Optimizing for demographic parity → hurts equalized odds
├─ Optimizing for accuracy → often hurts fairness
└─ Trade-off decisions require stakeholder input
```

#### Explainability Methods

**SHAP (SHapley Additive exPlanations)**:

```
Show contribution of each feature to prediction
Example:
  Prediction: Approve loan (72% confidence)
  Feature contributions:
  ├─ +8%: High income ($120k)
  ├─ +5%: Long employment (10 years)
  ├─ -2%: High debt ($50k)
  └─ -1%: Recent hard inquiry

Works for any model type (neural nets, gradboost, etc.)
Slightly expensive to compute O(2^n features)
```

**LIME (Local Interpretable Model-agnostic Explanations)**:

```
Train simpler model locally to explain complex model
Local linear approximation to neural network
Easy to compute, interpretable
Downside: Only locally accurate (not globally)
```

**Counterfactual explanations**:

```
What would need to change to get different prediction?
Example: "To get approved, you'd need to reduce debt by $5k"
Very actionable for users
Computationally expensive
```

#### Audit Logs & Governance Workflows

**Complete audit trail for every prediction**:

```
When model makes prediction:

1. Prediction event logged:
   ├─ timestamp: 2026-04-05T14:23:42Z
   ├─ user_id: 12345
   ├─ model_version: v2.3.1
   ├─ model_sha256: a7d3e9f...
   ├─ input_features: {income: 120k, debt: 50k, ...}
   ├─ prediction: {decision: "approve", confidence: 0.72}
   ├─ explanation: {shap_values: [...], top_features: [...]}
   └─ hash: sha256(all above) for integrity

2. Ground truth arrives (weeks/months later):
   ├─ timestamp: 2026-04-20
   ├─ actual_outcome: approved (customer repaid on time)
   ├─ linked to prediction via request_id
   └─ stored in audit database

3. Post-prediction analysis:
   ├─ Was prediction correct? (accuracy measurement)
   ├─ Bias patterns: Did model discriminate?
   ├─ Drift: Has model behavior changed?
   └─ Feedback loops: Train next version with this data

4. Compliance reporting:
   ├─ GDPR: "Show me why model decided on me"
   ├─ Fair Lending: Annual disparate impact audit
   ├─ HIPAA: Patient consent tracking
   └─ SOX: Audit trail for financial decisions
```

**Governance workflow for model deployment**:

```
Step 1: Model Training
  ├─ Data scientist trains model
  ├─ Runs automated fairness checks
  └─ Results: Disparate impact ratio = 0.85 (borderline!)

Step 2: Requests Approval
  ├─ Submits to model registry with metadata
  └─ Notifications sent to reviewers

Step 3: Compliance Review
  ├─ Compliance officer reviews:
  │  ├─ Fairness metrics acceptable?
  │  ├─ Model card complete?
  │  └─ Training data documented?
  ├─ Questions DS about borderline disparate impact
  ├─ DS responds: "Improved from 0.75 in v2.2"
  └─ Compliance approves (with condition: monitor monthly)

Step 4: Business Approval
  ├─ Product manager reviews:
  │  ├─ Improvement from current: +2.5% accuracy
  │  ├─ Business impact: +$2M revenue/year
  │  └─ Risk: Requires monthly fairness audit
  └─ Approves deployment

Step 5: Deploy to Staging
  ├─ Integration tests on prod-like data
  └─ Manual QA on sample predictions

Step 6: Canary Deployment to Production
  ├─ 1% traffic for 24 hours
  ├─ Monitor: accuracy, fairness, business metrics
  ├─ If healthy: increase to 50%, then 100%
  └─ If issues: automatic rollback

Step 7: Ongoing Monitoring (Post-deployment)
  ├─ Monthly fairness audit (disparate impact ratio)
  ├─ Weekly accuracy monitoring
  ├─ Real-time alerts on anomalies
  ├─ Annual bias detection on new demographic cohorts
  └─ If issues detected → incident → possible rollback → investigation
```

### Practical Code Examples

#### Fairness-aware ML Monitoring

```python
#!/usr/bin/env python3
# monitor_fairness.py
# Daily fairness audit for production models

import pandas as pd
from scipy.stats import chi2_contingency

class FairnessAuditor:
    def __init__(self, model_name, protected_attribute='gender'):
        self.model_name = model_name
        self.protected_attr = protected_attribute
        self.alert_threshold = 0.8  # Disparate impact ratio
    
    def audit(self, predictions_df):
        """Comprehensive fairness audit for model predictions"""
        report = {}
        
        # Split by protected attribute
        groups = predictions_df.groupby(self.protected_attr)
        
        # Collect metrics per group
        group_metrics = {}
        for group_name, group_data in groups:
            approval_rate = (group_data['prediction'] == 'approved').mean()
            group_metrics[group_name] = {
                'approval_rate': approval_rate,
                'sample_size': len(group_data),
            }
        
        # Calculate disparate impact ratio (minority vs majority)
        minority_rate = group_metrics['female']['approval_rate']
        majority_rate = group_metrics['male']['approval_rate']
        di_ratio = minority_rate / majority_rate
        
        report['disparate_impact_ratio'] = di_ratio
        report['pass'] = di_ratio >= self.alert_threshold
        
        # Statistical significance test
        contingency_table = []
        for group_name, metrics in group_metrics.items():
            approved_count = metrics['approval_rate'] * metrics['sample_size']
            denied_count = metrics['sample_size'] - approved_count
            contingency_table.append([approved_count, denied_count])
        
        chi2, pvalue, dof, expected = chi2_contingency(contingency_table)
        report['chi2_pvalue'] = pvalue
        report['stat_significant'] = pvalue < 0.05
        
        return report
    
    def generate_alert(self, report):
        if not report['pass']:
            alert = f"""
            ⚠️ FAIRNESS ALERT: {self.model_name}
            
            Disparate Impact Ratio: {report['disparate_impact_ratio']:.2%}
            (Female approval / Male approval)
            
            Threshold: {self.alert_threshold:.0%} (4/5 rule)
            Status: FAIL
            
            ACTIONS REQUIRED:
            1. Review training data for historical bias
            2. Check for proxy discrimination (indirect bias)
            3. Consider model retraining with fairness constraints
            4. Escalate to legal/compliance if intentional
            """
            return alert
        return None

# Daily audit job
if __name__ == "__main__":
    auditor = FairnessAuditor(
        model_name="loan_approval_v2.3.1",
        protected_attribute='gender'
    )
    
    # Load predictions from production (last 24 hours)
    predictions = pd.read_parquet(
        's3://ml-platform/audit-logs/loan_approval_2026-04-05.parquet'
    )
    
    # Run audit
    report = auditor.audit(predictions)
    
    # Check if action needed
    alert = auditor.generate_alert(report)
    if alert:
        print(alert)
        # Send slack notification
```

### Best Practices

1. **Implement comprehensive monitoring, not just post-hoc audits**
   - Real-time fairness dashboards
   - Alert when disparate impact > 0.8
   - Monthly fairness audits per cohort

2. **Document trade-offs explicitly**
   - Can't optimize accuracy, fairness, explainability simultaneously
   - Stakeholder-approved trade-off decisions
   - Example: "Chose equalized odds for TPR balance between groups"

3. **Test on holdout populations**
   - Collect data from underrepresented groups
   - Test performance on rare edge cases
   - Identify systematic failures before production

4. **Model cards and documentation**
   - Document limitations, performance by group
   - Include bias testing results
   - Specify intended use and out-of-scope cases

5. **Regular bias audits (quarterly minimum)**
   - Collect predictions and ground truth from production
   - Re-run all fairness metrics
   - Check for degradation or new patterns

### Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **No fairness metrics** | Bias goes undetected | Monthly fairness audits; alert on disparity |
| **Single fairness definition** | Wrong metric for domain | Stakeholder input; document choice |
| **Explainability as afterthought** | Can't debug issues | Explainability-first during development |
| **Fairness only at training** | Bias drift in production | Monitor fairness continuously (weekly dashboards) |
| **No audit trail** | Can't investigate complaints | Log every prediction; store indefinitely |
| **Unrepresentative training data** | Model fails on minority | Ensure training data reflects population diversity |

---

## Document Structure & Usage

This study guide is designed for **Senior DevOps Engineers** (5-10+ years experience) and can be consumed in multiple ways:

1. **Sequential reading**: Each section builds on foundational concepts while remaining independently consumable
2. **Reference consultation**: Use the table of contents to jump to specific topics for refresher or deep-dive
3. **Team alignment**: Share sections with team members to establish common language and architectural patterns
4. **Interview preparation**: The final "Interview Questions" section covers scenarios and challenges typical in production MLOps environments
5. **Implementation guide**: Code examples and practical patterns directly applicable to your infrastructure

### Audience Prerequisites

Before engaging this guide, familiarity with the following is assumed:

- **Cloud platforms**: AWS, Azure, or GCP (compute instances, networking, IAM, storage services)
- **Container orchestration**: Kubernetes fundamentals (pods, deployments, services, namespaces)
- **Infrastructure as Code**: Terraform or CloudFormation basics
- **DevOps practices**: CI/CD pipelines, monitoring, logging, incident response
- **Python**: Ability to read and understand Python code (ML framework examples)
- **Machine learning basics**: Understanding model training vs. inference, feature engineering concepts
- **Distributed systems**: Experience with distributed computing, fault tolerance, orchestration

---

## Hands-on Scenarios

This section provides realistic scenarios encountered in production MLOps environments with recommended solutions.

### Scenario 1: Model Training Consumed All GPU Resources

**Situation**: A data scientist accidentally submitted 100 hyperparameter tuning jobs. Each job reserved the entire GPU cluster. No other team can train. Service degradation alert fires.

**Investigation**:
```bash
# Check Kubernetes resource status
kubectl get nodes -o wide | grep gpu
kubectl describe node gpu-node-1 | grep -A 20 Allocated

# Check pod status
kubectl get pods -n ml-platform -o wide | grep training

# Identify resource hogs
kubectl top pods -n ml-platform --sort-by=memory
```

**Solution - Short term** (minutes):
```bash
# Kill the errant jobs
kubectl delete job -n ml-platform -l project=hyperparameter-tune

# Scale back GPU cluster to save costs
kubectl scale deployment gpu-node-pool --replicas=5
```

**Solution - Long term** (hours):
```yaml
# Implement resource quotas per team
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.nvidia.com/gpu: "10"  # Team-a max 10 GPUs
    limits.nvidia.com/gpu: "10"
  scopes:
  - NotTerminating  # Only apply to long-running jobs
```

**Lessons**: 
- Implement resource quotas for each team
- Add validation before job submission (warn if exceeds quota)
- Set up alerts for cluster utilization > 80%
- Educate teams on spot instances for fault-tolerant workloads

---

### Scenario 2: Model Accuracy Silently Degrading in Production

**Situation**: A recommendation model deployed 2 months ago. Team noticed last week that CTR dropped 8%. Model was silently failing for weeks without anyone knowing.

**Root cause analysis**:
```bash
# Check model training data distribution
# Compare training data (Jan) with production data (March)
# Result: User preferences shifted seasonally; model didn't adapt

# Model accuracy in January: 92%
# Model accuracy in March: 84% (8% degradation)
# No retraining happened; model date: 2026-01-15
```

**Investigation commands**:
```python
# Read training data from Jan, compare with March production data
import pandas as pd

training_data_jan = read_training_data("2026-01-01", "2026-01-31")
production_data_mar = read_production_logs("2026-03-01", "2026-03-31")

# Statistical tests for distribution shift
from scipy.stats import ks_2samp

# For each feature, test if distributions differ
feature_drift_pvalues = {}
for feature in training_data_jan.columns:
    stat, pvalue = ks_2samp(training_data_jan[feature], production_data_mar[feature])
    feature_drift_pvalues[feature] = pvalue
    if pvalue < 0.05:  # Statistically significant difference
        print(f"Feature '{feature}' drifted: p-value = {pvalue}")
```

**Solution**:
```yaml
# Implement drift detection + automatic retraining
apiVersion: batch/v1
kind: CronJob
metadata:
  name: model-drift-detector
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: drift-detector
            image: ml-platform/drift-detector:latest
            env:
            - name: ACCURACY_THRESHOLD
              value: "0.90"  # Alert if accuracy < 90%
            - name: DRIFT_PVALUE_THRESHOLD
              value: "0.05"  # Alert if p-value < 0.05
            - name: AUTO_RETRAIN
              value: "true"  # Automatically trigger retraining

          restartPolicy: OnFailure
```

**Lessons**:
- Implement continuous model monitoring (accuracy, data quality metrics)
- Set up alerts for model degradation
- Implement automated retraining triggers
- Establish SLA for model freshness (e.g., retrain if data shifted OR model older than 30 days)

---

### Scenario 3: GPU Cost Spike to $50,000/Month

**Situation**: ML platform bill suddenly jumped from $15,000 to $50,000/month (237% increase). Finance team demanding explanation.

**Investigation**:
```bash
# Query cloud cost analyzer
# AWS Athena query on cost data:
SELECT 
  instance_type,
  SUM(cost) as total_cost,
  COUNT(*) as num_instances
FROM cost_data
WHERE date BETWEEN '2026-03-01' AND '2026-03-31'
  AND resource_type = 'EC2'
GROUP BY instance_type
ORDER BY total_cost DESC

# Result:
# p4d.24xlarge: $35,000 (5 instances × 30 days × $233/day)
# p3.8xlarge: $15,000 (previous month cost)
```

**Root cause**: Someone provisioned p4d instances (A100 GPUs, 8x more expensive) for "experimental work".

**Short-term fix**:
```bash
# Terminate expensive instances
aws ec2 terminate-instances --instance-ids i-1234567 i-2345678

# Cost savings: $20,000/month immediately
```

**Long-term solution**:
```hcl
# Terraform: Enforce instance type whitelist
variable "allowed_gpu_instances" {
  type = list(string)
  default = [
    "p3.2xlarge",   # $3.06/hr (development)
    "p3.8xlarge",   # $12.24/hr (training)
  ]
  description = "Only these GPU instance types allowed"
}

resource "aws_autoscaling_group" "ml" {
  # ...
  instance_type = var.allowed_gpu_instances[0]  # Enforced
  
  tag {
    key   = "CostCenter"
    value = var.cost_center
  }
}

# Add budget alerts
resource "aws_budgets_budget" "ml_platform" {
  name       = "ml-platform-monthly"
  budget_type = "MONTHLY"
  limit_unit  = "USD"
  limit_value = "20000"
  
  notification {
    notification_type        = "ACTUAL"
    comparison_operator      = "GREATER_THAN"
    threshold                = 80
    threshold_type           = "PERCENTAGE"
    notification_channel_arns = ["arn:aws:sns:region:account:cost-alert"]
  }
}
```

**Lessons**:
- Implement instance type restrictions (whitelist allowed types)
- Set up cost budgets with alerts at 50%, 80%, 100%
- Require justification for expensive instances
- Regular cost reviews (weekly for platform, monthly with teams)

---

### Scenario 4: Model Registry Corrupted; Old Versions Inaccessible

**Situation**: MLflow model registry database crashed. New models can't be registered. Existing models can't be deployed. Production system down if model fails.

**Investigation**:
```bash
# Check MLflow database status
kubectl logs -n ml-platform deployment/mlflow | grep -i error
# Result: PostgreSQL connection refused; no disk space

df -h | grep mlflow
# Result: /data mounted on PVC at 99% capacity
```

**Root cause**: Model artifacts directory filling disk while PostgreSQL database also on same PVC.

**Short-term recovery** (1 hour):
```bash
# Expand PVC
kubectl patch pvc mlflow-pvc -p '{"spec":{"resources":{"requests":{"storage":"1Ti"}}}}'

# Restart MLflow
kubectl restart deployment mlflow -n ml-platform

# Verify recovery
kubectl logs -n ml-platform deployment/mlflow | tail -20
# Should show: "Connection to database successful"
```

**Long-term prevention**:
```yaml
# Separate storage tiers
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mlflow-db-pv
spec:
  capacity:
    storage: 100Gi  # Database (small, high-performance)
  storageClassName: fast-ssd
  # ...

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mlflow-artifacts-pv
spec:
  capacity:
    storage: 1Ti  # Artifacts (large, can be slower)
  storageClassName: standard-storage
  # ...
```

**Plus**:
- Implement automated backups
- Monitor disk usage; alert at 70%, 85%, 95%
- Document recovery procedures

---

## Interview Questions

### Question 1: Design an ML Platform for 100 Data Scientists

**Context**: Your company has 100 data scientists across 4 teams. Each team trains 5-10 models monthly. You need to design a shared ML platform that's cost-efficient, secure, allows independent team operations, but prevents one team from monopolizing resources.

**What would you design?**

**Scoring Rubric**:

| Aspect | Poor | Good | Excellent |
|--------|------|------|-----------|
| **Architecture** | Single Kubernetes cluster, no isolation | Separate namespaces per team, quotas | Multi-cluster with cross-region. Separate dev/staging/prod. |
| **Security** | Shared credentials | RBAC per namespace, secrets vault | Zero-trust model, signed artifacts, audit logging |
| **Cost** | No cost controls | Resource quotas, chargeback model | Chargeback model, spot instances for fault-tolerant workloads, autoscaling |
| **Scalability** | Hard-coded configs | Infrastructure-as-code with Terraform | IaC with automated testing, staged rollouts, drift detection |
| **Observability** | Basic logging | Prometheus metrics, Grafana dashboards | ML-specific monitoring: model drift, data quality, prediction latency, cost per team |
| **Failure modes** | Not addressed | Single points of failure identified | MTTR SLA defined; automatic failover; chaos testing |

**Expected Answer Structure**:
```
1. Architecture Overview
   - Shared GPU cluster with Kubernetes
   - Namespace per team (isolation)
   - Central services: MLflow, feature store, Airflow
   
2. Resource Management
   - GPU quotas per namespace: 20 GPUs for team-a, etc.
   - Resource quotas (CPU, memory, storage)
   - Pod disruption budgets protect long-running training
   
3. Security
   - RBAC: Teams can't access other teams' namespaces
   - Service accounts: Each team has minimal permissions
   - Secrets: Stored in vault, injected at runtime
   - Encryption: Data at rest (EBS encryption), in transit (TLS)
   
4. Cost Optimization
   - Chargeback model: Teams charged by GPU-hours used
   - Spot instances for hyperparameter tuning
   - Auto-scaling: Cluster scales 10-50 nodes based on load
   - Reserved instances for baseline capacity
   
5. Operations
   - Infrastructure-as-Code: All infrastructure managed via Terraform
   - Monitoring: CloudWatch alarms for cost/utilization
   - Incident response: Runbooks for common failures
   - Disaster recovery: Backup of model registry, feature store
```

---

### Question 2: Model Production Inference Latency Degrading

**Scenario**: Your real-time inference system has a p99 latency SLA of 200ms. Last week, p99 latency increased to 600ms. User-facing service impacted. You have 2 hours to diagnose and fix.

**What's your troubleshooting approach?**

**Expected Answer**:

```
Minute 0-5: Immediate diagnostics
├─ Check if issue system-wide or isolated
│  kubectl get pods -n inference | grep inference-server
│  Check pod restart count (crash loop?)
│
├─ Get real-time metrics
│  kubectl top pods -n inference --containers
│  Check: CPU (100%?), memory (thrashing?), GPU (idle?)
│
└─ Check recent deployments
   kubectl rollout history deployment/inference-server
   kubectl describe deployment inference-server
   Any recent changes? Version bump? New model?

Minute 5-15: Dig deeper
├─ Model size increased?
│  kubectl exec pod/inference-gpu-1 -- ls -lh /models/
│  Old: 200MB → New: 1GB = 5x larger, slower inference
│
├─ Infrastructure issue?
│  Check node resources: kubectl describe node gpu-1
│  High memory pressure → slower inference
│
├─ Feature store latency?
│  Request latency breakdown:
│  ├─ Fetch features: 100ms (was 30ms before, p50 latency increased)
│  ├─ Model inference: 80ms (unchanged)
│  └─ Post-processing: 20ms (unchanged)
│  = 600ms total (identified bottleneck: feature store)
│
└─ Traffic pattern change?
   Check: Batch size, concurrent requests, data shape
```

**Root cause found**: Feature store query timeout; queries taking 100ms instead of 30ms

**Short-term fix** (15 min):
```bash
# Rollback to previous model (if new model deployed)
kubectl set image deployment/inference-server \
  inference-server=inference:v2.0  # Rollback from v2.1

# Monitor latency recovery
watch -n 1 'kubectl top pods -n inference'
# After 5 min: p99 latency back to 150ms
```

**Investigate root cause** (30 min):
```bash
# Check feature store
kubectl logs -n graph deployment/feature-store
# Found: PostgreSQL query slow due to missing index on timestamp field

# Fix: Add index
psql -h feature-store-db -d features -c \
  "CREATE INDEX idx_features_timestamp ON features(timestamp);"

# Verify feature store latency
# Before: 100ms (sequential scan)
# After: 30ms (index scan)
```

**Long-term improvements**:
- Load test before deployment (know latency impact)
- Gradual rollout (canary): 5% traffic → monitor → increase
- Database indexing review: automated EXPLAIN ANALYZE on slow queries
- Feature store caching: Add Redis for frequently accessed features
- Monitoring on feature latency separately (catch issues earlier)

---

### Question 3: Data Leakage Between Training and Evaluation

**Scenario**: Your model achieved 97% accuracy on validation but only 72% accuracy in production. Investigation reveals data leakage: evaluation data accidentally included future data (data the model wouldn't see in production).

**How would you prevent this in the future?**

**Expected Answer**:

```
Root cause: Evaluation dataset accidentally included 
data from AFTER the deployment date (temporal leakage)

Prevention layers:

1. Code Review Layer
   - Another data scientist manually reviews train/eval split
   - Ensure: eval data from after train data (time-ordered)
   
2. Automated Testing Layer
   - Unit test: Verify no overlapping dates between train/eval
   ```python
   def test_no_temporal_leakage():
       train_data = load_training_data()
       eval_data = load_eval_data()
       
       assert train_data['timestamp'].max() <= eval_data['timestamp'].min()
       # Ensure train data is strictly before eval data
   
   def test_no_feature_leakage():
       # Ensure eval data doesn't include future ground truth
       eval_data = load_eval_data()
       assert 'inference_timestamp' in eval_data.columns
       assert 'label_timestamp' in eval_data.columns
       assert eval_data['inference_timestamp'] < eval_data['label_timestamp']
       # Verify labels only known AFTER inference time
   ```
   
3. Data Pipeline Layer
   - Implement strict data contracts
   - Schema validation: Ensure no unexpected columns
   - Documentation: Data lineage, when each field becomes available
   
4. Monitoring Layer
   - Track train/eval performance gap continuously
   - Alert if train-eval divergence > 5%
   - Catch distribution mismatch, leakage, label bias
   
5. Governance Layer
   - Require data lineage documentation in model registry
   - Approval workflow: Cannot deploy model until lineage reviewed
   - Regular audits: Sample old models, verify no leakage
```

---

### Question 4: Multi-Tenant Feature Store Design

**Scenario**: You have 30 teams, each maintaining different features (inventory, pricing, user behavior, etc.). Design a shared feature store that:
- Allows teams to self-serve features
- Prevents one team from monopolizing compute
- Maintains sub-100ms inference latency
- Isolates teams for security/compliance

**Design brief**:

```
Tier 1: Online Feature Store (Redis/DynamoDB)
Purpose: Real-time serving (<100ms latency)
├─ Capacity: 1GB per team
├─ Queries/sec: 1000 per team
├─ Items: User-level features (user_id → features)
├─ TTL: 24 hours
└─ Architecture: Partitioned by team_id

Tier 2: Batch Feature Store (S3/Parquet)
Purpose: Training data, historical features
├─ Capacity: Unlimited
├─ Update frequency: Daily/weekly
├─ Items: User features for training (user_id, date → features)
├─ Retention: 5 years
└─ Architecture: Partitioned by team_id/date

Query Pattern:
At training: Read batch store (large volume, high latency OK)
At inference: Read online store (small queries, <100ms required)

Isolation:
├─ Each team's features in separate Redis keyspace (team-a:*, team-b:*)
├─ Access control: Teams can only access their own features
├─ Monitoring: Per-team quota enforcement
└─ Cost: Charged by storage + compute used per team
```

---

### Question 5: Incident Post-Mortem Template

**Scenario**: Model training pipeline failed, causing 12-hour delay in daily retraining. Models served stale predictions for 6 hours until rollback triggered.

**Conduct a post-mortem. What would you cover?**

**Post-Mortem Structure**:

```
1. INCIDENT SUMMARY
   - What: Training pipeline failed, stale models served to production
   - When: 2026-04-05 02:00 UTC (detected 06:00 UTC)
   - Impact: 6 hours of stale predictions; 0.5% accuracy degradation for 500k users
   - Duration: 4 hours (until automatic rollback triggered)
   - Severity: P1 (user-facing impact)

2. TIMELINE
   02:00 UTC: Training job submitted (daily schedule)
   02:15 UTC: Job failed (root cause: container image pull timeout)
   02:30 UTC: No retry triggered (alert not configured)
   06:00 UTC: Dayshift team noticed; investigated
   06:15 UTC: Root cause identified
   06:20 UTC: Manual rollback to previous model version
   06:25 UTC: Service recovered; stale model removed

3. ROOT CAUSE ANALYSIS
   Primary cause: Image registry unavailable for 15 minutes
   → Container pull failed
   → Job crashed
   → No retry mechanism
   → Alert not configured
   → Manual detection by human (6 hours late)
   
   Contributing factors:
   - No SLA on training job completion time
   - No automated alerts on training failures
   - No automatic retry with exponential backoff
   - No canary deployment (stale model served immediately)

4. IMPACT ASSESSMENT
   - User impact: 500k users served stale model for 6 hours
   - Magnitude: 0.5% accuracy loss (from 93% to 92.5%)
   - Business impact: Estimated $50k revenue loss
   - Downstream: 2 ML teams blocked due to model unavailability

5. REMEDIATION ACTIONS
   
   Immediate (completed within 24 hours):
   ├─ Manual monitoring: Check training job daily (temporary)
   └─ Manual rollback procedure tested
   
   Short-term (week 1):
   ├─ Add automated alerts for training job failures
   ├─ Implement automatic retry with 5-min exponential backoff
   ├─ Implement model canary deployment (5% traffic on stale model)
   └─ Test incident response runbook
   
   Long-term (month 1):
   ├─ Implement health checks on training pipeline
   ├─ Implement monitoring on model freshness (alert if > 24hrs old)
   ├─ Multi-region model registry (redundancy)
   ├─ Automated training failure detection + fallback to previous model
   └─ Chaos engineering: Simulate training failures quarterly
   
   Training (month 1):
   ├─ Document incident for team learning
   ├─ Conduct blameless review session
   └─ Update runbooks

6. LESSONS LEARNED
   ✓ Automatic retries prevented > 50% of ML infrastructure incidents
   ✓ Monitoring on model freshness critical (not just accuracy)
   ✓ Canary deployment catches problems before affecting all users
   ✓ Need earlier alerting (6-hour delay unacceptable)

7. PREVENTION IN FUTURE
   ├─ Automate: Remove humans from alert-detection loop
   ├─ Proactive: Monitor leading indicators (training lag, not just user complaints)
   ├─ Resilient: Fallback mechanisms (rollback, stale model with SLA)
   └─ Testing: Chaos experiments (simulate failures, validate recovery)
```

---

### Question 6: Feature Store Architecture at Scale

**Scenario**: You're designing a feature store for 200 data scientists and 50 production models using 10TB of data. The system must support 100k feature queries/second during inference and 1000 feature computations/day for training. Propose the architecture.

**Expected Answer**:

**Two-Tier Feature Store Architecture**:

```
OFFLINE LAYER (Training)
├─ Source: S3/Data lake with Parquet files
├─ Compute: Spark/Beam jobs (160+ features, 2-hour computation)
├─ Storage: DynamoDB (time-series TTL: 1 year training data)
├─ Serving: Batch read (100ms acceptable)
└─ Cost: $3k/month (storage + compute)

ONLINE LAYER (Inference)
├─ Source: Redis cluster (hot features only, 500 top features)
├─ Compute: Real-time aggregation (5-min window for top 50 features)
├─ Storage: Redis with 16GB RAM (100k queries/sec capacity)
├─ Serving: <5ms latency (SLA: p99 < 10ms)
└─ Cost: $5k/month for 16GB tier (high throughput)

FEATURE STORE PLATFORM
├─ Registry: Catalog of all 10k features (name, schema, owner, SLA)
├─ Lineage: Which models use which features
├─ Versioning: Feature computation versioning (Feature_v1, Feature_v2)
├─ Access control: Teams can read only own + shared features
├─ Monitoring:
│  ├─ Feature freshness (staleness alert if > 2 hours)
│  ├─ Query latency (p99 < 50ms for online)
│  ├─ Data quality (null %, distribution checks)
│  └─ Cost per team (chargeback model)
└─ API:
   ├─ Training API: get_historical_features({user_id}, timestamp_range)
   ├─ Serving API: get_features({user_ids}) → <5ms
   └─ Compute API: register_feature_pipeline(definition)

DEPLOYMENT PATTERN
Training pipeline (Data Scientist):
  1. Submit: define_features([feature_a, feature_b, feature_c])
  2. Compute: Airflow job aggregates from source (2 hours)
  3. Store: Write to offline store (DynamoDB)
  4. Retrieve: get_historical_features for model training

Inference pipeline (Production Service):
  1. Request: get_features([user_id]) → milliseconds
  2. Lookup: Redis online store (hot path, p99 < 5ms)
  3. Fallback: If Redis miss, fetch from DynamoDB + update Redis TTL
  4. Return: {feature_a: 123, feature_b: 456, ...} to model

SCALING STRATEGY
├─ 100k req/sec: Redis cluster with 5-node replication (partition by user_id)
├─ 1000 feature jobs/day: Spark cluster auto-scales (peak: 100 nodes)
├─ 10TB data: S3 lifecycle (hot: 1month, warm: 6months, cold: 1year)
└─ Cost per feature/month: Storage + compute + query charges attributed to owner
```

**Key Architectural Decisions Explained**:
1. **Two-tier separation**: Online (fast) vs Offline (batch, cost-effective). Most ML systems can't serve from offline store directly (too slow).
2. **Feature versioning**: Models trained on Feature_v1 must get Feature_v1 at inference (not v2). Prevents training-serving skew.
3. **Lineage tracking**: If Feature_a changes, automatically flag all downstream models for revalidation.
4. **Chargeback model**: Teams paying for features they use encourages efficiency (no unused feature accumulation).

**Real-World Challenge**: "Our data scientists built 10 parallel offline feature stores. Result: duplicate computation, higher costs, nobody knows which version is in production."
- **Solution**: Centralize feature registry; compute once; share across models. Deprecate duplicates.

---

### Question 7: Cost Optimization Across Multi-Tenant GPU Infrastructure

**Scenario**: Your ML platform has 4 teams, each budgeted $200k/month. Costs are $750k/month (37.5% over budget). You have 50 GPU nodes (p3.8xlarge, ~$10/hour each). Root cause analysis shows:
- Team A: Only 20% GPU utilization (training jobs often remain queued)
- Team B: Constantly near limit, running expensive experiments
- Team C: Using on-demand; should use spot instances
- Team D: Optimal utilization at 80%

How would you optimize?

**Expected Answer**:

**Cost Optimization Strategy**:

```
STEP 1: LIMIT ENFORCEMENT (Month 1)
├─ Team A: Hard quota 2 GPUs (currently has 15 allocated but not using)
├─ Team B: Hard quota 18 GPUs (currently unchecked)
├─ Team C: Hard quota 15 GPUs (forced spot instance policy)
├─ Team D: Maintain 15 GPUs (optimal)
└─ Total: 50 GPUs (balanced allocation)

Cost after Step 1: ~$780k (modest improvement, $20k savings)

STEP 2: SPOT INSTANCE MIGRATION (Month 1-2)
├─ Team C: Convert all to spot instances (-70% cost)
│  └─ 15 GPUs on-demand ($10/hr) → spot ($3/hr) = $105/hr → $31.5/hr
│  └─ Monthly savings: $105k - $31.5k = $73.5k
│
├─ Team B: 50% spot, 50% on-demand (for long-running jobs requiring stability)
│  └─ 9 GPUs on-demand + 9 GPUs spot
│  └─ Monthly savings: 9 GPUs × $240/month = $21.6k
│
└─ Total spot conversions: $94k savings

Cost after Step 2: ~$686k ($64k saved, still $286k over budget)

STEP 3: RESOURCE EFFICIENCY (Month 2-3)
├─ Team A: Investigate 80% idle GPUs
│  ├─ Root cause: Long queued jobs waiting for resources
│  ├─ Solution: Implement fair-share scheduling (prevent single experiment hogging GPUs)
│  ├─ Reallocate unused quota to Team B
│  └─ Cost reduction: $20k/month
│
├─ Team B: GPU Multiplexing
│  ├─ Use Kubernetes GPU sharing (MIG: Multi-Instance GPU)
│  ├─ 1 GPU → 7 small GPUs (for small batch training jobs)
│  ├─ Mix small + full GPU tenants on same physical node
│  └─ Reduce GPU count needed by 30%: 18 GPUs → 12.6 GPUs ≈ 13 GPUs
│  └─ Cost reduction: $120k/month
│
├─ Team D: Cost optimization despite high utilization
│  ├─ Mixed precision training (FP32 → FP16): 2x speedup
│  ├─ Reduce training time from 10h to 5h per job: -50% GPU hours
│  └─ Cost reduction: $25k/month
│
└─ Total efficiency: $65k savings

Cost after Step 3: ~$621k ($129k saved, $221k over budget)

STEP 4: DYNAMIC SCALING + BATCH CONSOLIDATION (Month 3-4)
├─ Consolidate small jobs into daily batch windows (early morning)
├─ Auto-scale down during business hours (only keep 20 nodes, scale to 50 at night)
├─ Implement job queue with SLA (small jobs: 4h wait acceptable; large: urgent)
├─ Reserved instances for baseline (20 nodes): -30% vs on-demand
│  └─ 20 nodes × $10/hr × 24h/day × 30 days × 0.7 = $100k/month
│  └─ vs on-demand: $144k/month
│  └─ Savings: $44k/month
│
└─ Total scaling: $44k savings

Cost after Step 4: ~$577k ($173k saved, $177k over budget)

STEP 5: CROSS-TEAM OPTIMIZATION (Month 4)
├─ Shared vs dedicated: Teams C+D are compatible with shared nodes
│  ├─ Consolidate 28 GPUs (13 + 15) onto 8 nodes with overprovisioning
│  ├─ Reduce total nodes: 50 → 42 nodes
│  └─ Savings: 8 nodes × $240/month = $19.2k/month
│
├─ Budget redistribution: Reallocate unused quota from conservative Team A to Team B
├─ Incentive: Teams reducing spend get 50% rebate to reinvest
│  └─ Team D reinvests savings ($25k) in automated hyperparameter tuning (faster iteration)
│
└─ Total cross-team: $24k savings

Cost after Step 5: ~$553k ($197k saved, final target: $250k under budget)

FINAL MONTHLY BREAKDOWN:
├─ Reserved instances (20 nodes):    $100k
├─ On-demand (15 nodes):             $108k (50% for Team B stability, 50% for hot jobs)
├─ Spot instances (15 nodes):        $32k (Team C + Team B experimental)
├─ Storage, networking, software:    $80k
├─ Platform overhead (monitoring, support):   $30k
└─ TOTAL: ~$350k (within $750k budget!)

Team-by-team post-optimization:
├─ Team A: $50k/month (heavily limited to encourage efficiency)
├─ Team B: $120k/month (high-priority experiments, mixed resources)
├─ Team C: $60k/month (spot-based, experimental)
├─ Team D: $90k/month (optimal utilization, steady-state training)
└─ Unallocated reserves (buffer): $30k/month
```

**Key Architectural Decisions**:

1. **Quota enforcement is hard constraint**, not soft target. Without hard limits, teams spend wastefully.
2. **Spot instances work only for fault-tolerant jobs** (checkpointed training, not interactive experiments). Know your job types.
3. **GPU sharing (MIG) has overhead**: Good for small batch jobs, bad for compute-intensive training. Use selectively.
4. **Consolidate batch work into time windows**: Night training runs on full capacity; day runs on thin infra.
5. **Chargeback prevents moral hazard**: If Team B doesn't pay cost, they over-consume.

**Real-World Challenge**: "We implemented cost controls, but Team B complaints about 'insufficient GPUs' increased 300%. Became political issue."
- **Solution**: Transparent cost reporting (show them: "Your 15 GPUs cost you $180k/month vs Team D's 15 GPUs cost them $90k because of utilization difference"). Make tradeoff visible.

---

### Question 8: Model Registry and Artifact Management for 500+ Models

**Scenario**: You're designing a model registry for 200 data scientists managing 500+ active production models. Models vary: PyTorch, TensorFlow, sklearn, XGBoost. Each model has training data, code, metrics, lineage, and compliance metadata. Design the registry architecture and governance.

**Expected Answer**:

**Model Registry Architecture**:

```
CORE COMPONENTS
├─ Model Metadata Store:
│  ├─ Model name, version, owner, created_date
│  ├─ Framework type, serialization format (onnx vs tensorflow pb)
│  ├─ Training data digest (sha256 of training dataset)
│  ├─ Training code version (git commit hash)
│  ├─ Metrics: accuracy, fairness_ratio, latency_p99
│  ├─ Dependencies: Python packages, system libraries
│  └─ Lineage: upstream models (model chains), downstream services
│
├─ Model Artifact Storage:
│  ├─ S3 bucket structure:
│  │  └─ s3://ml-registry/models/{model_name}/{version}/
│  │     ├─ model.pkl / model.pb / model.onnx (weights)
│  │     ├─ metadata.json (model info)
│  │     ├─ requirements.txt (dependencies)
│  │     ├─ performance_metrics.json
│  │     ├─ training_data_hash
│  │     └─ docker_image_uri (reproducible environment)
│  │
│  ├─ Versioning: Semantic versioning (v1.2.3)
│  │  ├─ MAJOR: Architecture change (retraining from scratch)
│  │  ├─ MINOR: Feature addition (retraining on same data)
│  │  └─ PATCH: Hyperparameter tune (same architecture + features)
│  │
│  └─ Retention policy:
│     ├─ Current production version: Keep forever (compliance)
│     ├─ Previous production version: Keep 1 year (rollback window)
│     ├─ Staging versions: Keep 3 months (not needed in prod)
│     ├─ Experimental versions: Keep 2 weeks (dev artifacts)
│     └─ Disk quota: 10TB total; S3 intelligent tiering (old → Glacier)
│
└─ Governance Database (Compliance):
   ├─ Audit log: Who trained model, when, with what data, approval chain
   ├─ Fairness audit: Monthly disparate impact checks
   ├─ Security scan: Adversarial robustness tests, backdoor detection
   ├─ Data lineage: Training data → feature store → model → predictions
   ├─ Approval workflow:
   │  ├─ Data scientist submits model to registry (staging)
   │  ├─ ML engineer reviews code quality + tests
   │  ├─ Compliance checks model card (fairness, explainability)
   │  ├─ Product manager approves production deployment
   │  └─ Registry marks as \"approved_for_production\"
   │
   └─ Compliance metadata:
      ├─ GDPR: Data consent tracking, right-to-be-forgotten process
      ├─ Fair Lending: Anti-discrimination attestation for credit/hiring models
      ├─ HIPAA: Patient consent, data lineage for healthcare models
      └─ SOX: Audit trail for financial decision models
```

**Governance Workflow**:

```
MODEL DEVELOPMENT LIFECYCLE
Step 1: Registration (Data Scientist)
├─ Trains model locally
├─ Calls: register_model(model_pkl, metadata, training_data_digest)
├─ Registry creates: model_name=v0.0.1 (experimental)
├─ Status: EXPERIMENTAL (only owner can access)
└─ Default quota: <1GB disk space

Step 2: Staging (ML Engineer Review, 24 hours)
├─ ML engineer reviews code quality:
│  ├─ Training code reproducible? (can retrain from same data → same model)
│  ├─ Unit tests passing? (test harness for edge cases)
│  ├─ Docker image reproducible? (pin all dependencies)
│  └─ Model card filled out? (intended use, known limitations)
├─ If OK: Promote to STAGING
├─ Status: STAGING (shared access to team)
└─ Quota: 10GB disk space

Step 3: Compliance Check (Compliance Officer, 48 hours)
├─ Fairness audit:
│  ├─ Run model on test set stratified by demographic groups
│  ├─ Measure disparate impact ratio (target >= 0.8)
│  ├─ If fail: Blocked for promotion, DS must retrain
│  └─ If pass: Approve
│
├─ Explainability check:
│  ├─ Run SHAP analysis on sample predictions
│  ├─ Verify top 3 features are sensible (not proxy for protected attribute)
│  └─ Approve or request retraining
│
├─ Security check:
│  ├─ Scan for adversarial robustness (FGSM attack test)
│  ├─ Check for data leakage in feature importance
│  └─ Approve or flag risks
│
└─ If all pass: COMPLIANCE_APPROVED

Step 4: Product Manager Sign-off (24 hours)
├─ Review business metrics:
│  ├─ Accuracy improvement vs current model?
│  ├─ Latency impact (< 100ms required)?
│  ├─ Cost impact (compute + storage)?
│  ├─ User experience impact?
│  └─ Rollout plan agreed?
├─ If OK: Mark READY_FOR_PRODUCTION
└─ Schedule canary deployment window

Step 5: Canary Deployment (DevOps)
├─ Deploy to staging environment (1% traffic)
├─ Monitor for 24 hours:
│  ├─ Accuracy on real data
│  ├─ Latency p99 vs baseline
│  ├─ Error rate < SLA?
│  ├─ Fairness metrics stable?
│  └─ Cost per prediction acceptable?
│
├─ If issues: Automatic rollback to previous version
├─ If OK after 24h: Increase to 5% traffic
├─ Continue ramping: 5% → 25% → 50% → 100% (over 1 week)
└─ Final status: PRODUCTION

Step 6: Monitoring + Auditing (Continuous, DevOps + Compliance)
├─ Weekly:
│  ├─ Accuracy degradation check (recompute on holdout set)
│  ├─ Latency monitoring (p99 < SLA?)
│  ├─ Error rate monitoring
│  └─ Cost per prediction trends
│
├─ Monthly:
│  ├─ Fairness audit (disparate impact ratio vs baseline)
│  ├─ Feature drift detection (do feature distributions match training?)
│  ├─ Model drift detection (are predictions shifting over time?)
│  └─ Data quality checks on training data for next version
│
├─ Quarterly:
│  ├─ Full model audit (retrain on latest data, compare performance)
│  ├─ Security re-assessment
│  └─ Compliance review (regulatory changes?)
│
└─ Action trigger: If any metric degraded > 5%:
   ├─ Create incident
   ├─ Alert team
   ├─ Potentially trigger canary rollback if critical
   └─ Investigate root cause (data drift? concept drift? bug?)

Step 7: Retirement (When accuracy < 85% or outdated)
├─ Mark model as DEPRECATED
├─ Keep in registry for audit trail (compliance requirement)
├─ Move artifacts to Glacier (cold storage)
└─ Successor model must be trained + approved before old model retires
```

**Key Architectural Decisions**:

1. **Semantic versioning for models**: Same as software. Tracks what changed between versions (helps with rollback decisions).
2. **Training data digest immutable**: If you retrain on different data, MUST change version. Prevents training-serving skew.
3. **Governance checklist (fairness, security, explainability)**: Don't skip compliance for speed. Regulatory cost >> speedup benefit.
4. **Canary deployment is mandatory**: New models don't go 100% immediately. Catch issues with 1% traffic Errors before affecting all users.
5. **Audit trail for compliance**: Financial regulations require proof of approval chain for every model. Don't skip.

**Real-World Challenge**: "We built a registry, but data scientists complained: 'Governance blocks my deployment for 2 weeks. Can't iterate fast enough.'"
- **Solution**: Parallel track: Approve \"experimental\" models quickly for staging/shadow deployment. Full compliance only before production canary. Iteration speed for internal, rigor for external-facing.

---

### Question 9: Disaster Recovery for ML Platform (RTO/RPO)

**Scenario**: Your ML platform spans 2 regions (us-east-1 primary, us-west-2 standby). An AWS AZ failure takes out 60% of your infrastructure. You have
- 100 active production models
- Real-time inference serving 10M requests/day
- Batch training jobs (daily retraining 500+ models)
- Feature store with 10TB data
- Model registry with 500 model versions

Define RTO (recovery time objective) and RPO (recovery point objective) for each component. Then detail the disaster recovery strategy.

**Expected Answer**:

**RTO/RPO Requirements**:

```
Component                    RTO(recovery time)  RPO(data loss)  Priority
────────────────────────────────────────────────────────────────────────
Production Inference         5 minutes           0 seconds       P0 (critical)
Real-time feature serving    5 minutes           0 seconds       P0 (critical)
Model registry              1 hour               1 hour          P1 (high)
Feature store (training)    4 hours              1 day           P2 (medium)
Training pipeline           4 hours              1 day           P2 (medium)
```

**Rationale for RTO/RPO**:

```
PRODUCTION INFERENCE (RTO: 5 min, RPO: 0 sec):
├─ Business impact: Every minute of downtime = $100k revenue loss
├─ Recovery: Must be automatic, no manual intervention
└─ Data loss: 0 acceptable (stateless predictions, any data from real traffic)

FEATURE STORE (RTO: 4h, RPO: 1 day):
├─ Training pipelines depend on feature store
├─ But training jobs can tolerate 1 hour stale features
├─ Recovery: Can failover to standby replica (async replication)
└─ Data loss: 1 day of historical features acceptable (retrain on older data)

TRAINING PIPELINE (RTO: 4h, RPO: 1 day):
├─ Model retraining runs daily, not immediate
├─ 4-hour delayed training acceptable (models still serve with older version)
└─ Daily snapshots of training data sufficient
```

**Architecture: Active-Passive Disaster Recovery**:

```
REGION 1 (us-east-1) PRIMARY
├─ EKS Cluster (production inference)
│  ├─ 100 model serving pods (4 replicas each = 400 pods)
│  ├─ Real-time feature fetching from Redis online store
│  └─ Request load: 10M traffic/day → ~115 req/sec avg
│
├─ Redis Cluster (online feature store)
│  ├─ Master nodes in us-east-1
│  ├─ Cross-region replication to us-west-2 (async, ~100ms lag)
│  └─ Failover: Switch DNS to us-west-2 Redis on AZ failure
│
├─ RDS Multi-AZ (model registry metadata)
│  ├─ Multi-AZ: Automatic failover within us-east-1
│  ├─ Cross-region read replica in us-west-2 (async)
│  └─ RPO: 5 minutes (can lose up to 5 min of registrations)
│
├─ S3 Buckets (model artifacts)
│  ├─ Primary: us-east-1
│  ├─ Cross-region replication: us-west-2 (async, eventual consistency)
│  └─ RPO: 15 minutes (S3 replication SLA)
│
└─ Airflow (training orchestration)
   ├─ Primary: us-east-1
   └─ No standby (batch, can tolerate 1-day delay)

REGION 2 (us-west-2) STANDBY
├─ EKS Cluster (cold standby, only 10 pods for health checks)
│  └─ Scaled to 0 (saves cost: $10k/month saved)
│
├─ Redis Cluster (read replica, cross-region replication target)
│  └─ Can become master by promotion (manual or automated)
│
├─ RDS Read Replica (metadata store)
│  └─ Can be promoted to master (manual + 5 min setup)
│
└─ S3 Buckets (replication target)
   └─ Eventual consistency with primary

FAILURE DETECTION & AUTOMATIC FAILOVER:
├─ Health check: Every 10 seconds, us-east-1 EKS cluster health
├─ Threshold: 2 consecutive failed checks (20 second detection time)
├─ On failure detected:
│  ├─ DNS failover: model-serving.example.com points to us-west-2
│  ├─ Application load balancer redirects traffic to us-west-2
│  ├─ Traffic shift: 100% to us-west-2 (already receiving 100% traffic there)
│  └─ 5-minute recovery: EKS pod startup time + DNS propagation
│
└─ Recovery window:  5 minutes (within RTO)

ACTIVE-PASSIVE ARCHITECTURE PHASES

Phase 1: Normal Operation (all traffic in us-east-1)
┌──────────────────────┐
│  US-EAST-1 PRIMARY   │
├──────────────────────┤
│ Traffic: 100%        │
│ EKS: 400 pods        │
│ Redis: Master        │
│ RDS: Master          │
│ S3: Primary writes   │
└────────┬─────────────┘
         │
    ┌────▼─────────────────────┐
    │ Async Replication (100ms) │
    └────┬─────────────────────┘
         │
┌────────▼─────────────┐
│  US-WEST-2 STANDBY   │
├──────────────────────┤
│ Traffic: 0%          │
│ EKS: 10 pods (health)│
│ Redis: Replica (RO)  │
│ RDS: Read Replica    │
│ S3: Replication dest │
└──────────────────────┘

Phase 2: Failure Detected in us-east-1
(e.g., AZ network partition, 60% loss)

Action 1: Health check fails
  ├─ us-east-1 EKS cluster: 50% pods unreachable
  ├─ Expected: 400 pods, Actual: 200 pods
  └─ Alarm: \"Cluster health 50% < 80% threshold\"

Action 2: Automatic Failover (~2 minutes)
  ├─ Kubernetes readiness probe fails: 200 pods get marked unavailable
  ├─ DNS TTL: 60 seconds
  ├─ Update: model-serving.example.com → us-west-2 IP
  ├─ ALB: Drain existing us-east-1 connections
  └─ Redirect: New traffic to us-west-2

Action 3: us-west-2 scales up (1-2 minutes)
  ├─ Target: 400 pods for 100% traffic capacity
  ├─ Current: 10 health-check pods
  ├─ Auto-scaling: Trigger scale-up job
  ├─ Pod startup: ~30 seconds per batch (parallel startup)
  └─ Completed: 5 minutes total

Phase 3: Failover Complete
┌──────────────────────────────┐
│ US-EAST-1 PRIMARY (Failed)   │
├──────────────────────────────┤
│ Traffic: 0%                  │
│ EKS: Down (AZ failure)       │
│ Status: DEGRADED             │
└──────────────────────────────┘

┌──────────────────────────────┐
│ US-WEST-2 STANDBY (Now Prod) │
├──────────────────────────────┤
│ Traffic: 100%                │
│ EKS: 400 pods (running)      │
│ Redis: Promoted to Master    │
│ RDS: Promoted to Master      │
│ Status: OPERATIONAL          │
└──────────────────────────────┘

Result: 5-minute recovery, 0 data loss (stateless inference)

Phase 4: Failback to us-east-1 (1 hour later, AZ recovered)
├─ Verify: us-east-1 is truly healthy (not flapping)
├─ Check: Replication lag us-east-1 → us-west-2 (should be <1 minute)
├─ Switchback: Gradually ramp traffic back to us-east-1 (canary style)
├─ Timeline: 10% (5 min) → 50% (10 min) → 100% (10 min)
└─ Confirm: All pods healthy in us-east-1 before full traffic shift

DR TESTING (Quarterly)
├─ Chaos engineering: Kill random EKS pod in us-east-1
├─ Verify: Pod replaced within 30 seconds (self-healing)
├─ Chaos engineering: Kill entire us-east-1 AZ (simulated)
├─ Verify: Failover to us-west-2 within 5 minutes
├─ Verify: No data loss on failover
├─ Recovery: Failback to us-east-1 works correctly
└─ Result: Confidence in recovery procedures
```

**Cost Analysis**:

```
Option 1: Active-Passive (proposed)
├─ us-east-1: Full infrastructure = $100k/month
├─ us-west-2: Minimal (10 pods + read replicas) = $10k/month
├─ Total: $110k/month
│
└─ vs all-active: $200k/month (double infrastructure)
   └─ Savings: $90k/month (for 99.95% uptime vs 99.97%)

Option 2: Active-Active (alternative)
├─ us-east-1: Full infrastructure = $100k/month
├─ us-west-2: Full infrastructure = $100k/month
├─ Cross-region replication: $10k/month
├─ Total: $210k/month
│
└─ Pro: Full redundancy, RTO < 1 minute, RPO < 1 second
└─ Con: 2.1x more expensive
```

**Key Architectural Decisions**:

1. **Active-Passive not Active-Active**: Cost-benefit. Active-Active doubles spend for minimal SLA improvement (99.95% → 99.98%).
2. **Stateless inference**: No local state in pods means no data loss on failover. Design services to not cache state.
3. **Database read replicas**: Last-mile recovery bottleneck. Promote read replica to master (not restore from backup).
4. **Quarterly DR testing**: If disaster recovery untested, it won't work when needed (Murphy's law).
5. **RTO/RPO per component**: Different SLAs for different needs. Batch jobs tolerate 4h delays; real-time inference cannot.

**Real-World Complexity**: "We designed great DR. Then AWS us-east-1 had 12-hour outage. Our failover worked! But then... data replication was 1 hour behind. We lost recent transactions."
- **Solution**: Accept RPO trade-off upfront. Choose: (a) lose 1h data, or (b) 2x infrastructure cost for synchronous replication.

---

### Question 10: Security & Compliance for Multi-Tenant ML Platform (Data Isolation)

**Scenario**: Your ML platform serves 50 customers from different industries: Finance (regulated), Healthcare (HIPAA), E-commerce (PCI), SaaS (standard). Each trains models on sensitive data. Design multi-tenant data isolation to ensure:
- Finance customer can't see Healthcare customer's data
- No data leakage through model artifacts
- Compliance audit trail (who accessed what, when)
- Regulatory reporting (HIPAA, PCI, GDPR)

Explain architecture, data flow, and security controls.

**Expected Answer**:

**Multi-Tenant Data Isolation Architecture**:

```
LOGICAL ISOLATION LAYERS

Layer 1: IDENTITY & AUTHENTICATION
├─ Each customer: Separate AWS account (hard boundary via IAM)
│  └─ Customer Auth: SSO via customer's own IdP (Okta, Azure AD)
│     └─ Prevents: Cross-tenant auth bypass
│
├─ Data scientist: Authenticated to their customer account only
│  └─ Session token: Contains customer_id, encrypted, signed
│  └─ Scope: Token valid for specific customer's resources only
│
└─ Service-to-service: Mutual TLS (mTLS)
   └─ Pod-to-pod communication: Kubernetes service mesh (Istio)
   └─ Sidecar proxies: Enforce request authentication

Layer 2: NAMESPACE ISOLATION
├─ Kubernetes namespaces: One per customer
│  ├─ Namespace: customer_finance_prod
│  ├─ Namespace: customer_healthcare_prod
│  ├─ Namespace: customer_ecommerce_prod
│  └─ Network policies: Traffic between namespaces blocked
│
├─ RBAC (Role-based Access Control):
│  ├─ Role: customer_finance_admin
│  │  ├─ Can: List, create, delete pods within namespace_finance
│  │  ├─ Can't: Access other namespaces
│  │  └─ Can't: Read secrets from other namespaces
│  │
│  └─ RoleBinding: Maps role to customer's service account
│     └─ Only finance customer's pods can execute in namespace_finance
│
└─ Network Policy (Kubernetes):
   └─ Ingress: Only from customer's own pods or load balancer
   └─ Egress: Only to customer's own services or external (restricted)
```

**Data Flow with Isolation**:

```
SCENARIO: Finance customer trains model, Healthcare customer trains simultaneously

Finance Customer Data Flow:
┌──────────────────────┐
│ Finance S3 bucket    │ (customer-finance-prod-data)
│ (encrypted)          │ └─ Encryption key: customer-managed (CMKK1)
│ ├─ Training data     │ └─ Access: Finance IAM role only
│ └─ Feature data      │
└────────┬─────────────┘
         │ (S3 download)
         │ (signed URL, 15-min expiry)
         ▼
┌──────────────────────────────────────┐
│ Kubernetes Pod (Finance namespace)   │
│ └─ Service account: finance-trainer  │ (Bearer token)
│ ├─ Access: Can read Finance S3       │
│ ├─ Access: Can't read Healthcare S3  │ (DENIED by IAM policy)
│ └─ Mount: Customer-finance PVC       │ (volatile storage)
└────────┬─────────────────────────────┘
         │ (Data stays in pod memory)
         │ (Training happens in-pod)
         ▼
┌──────────────────────────────────────┐
│ Model artifacts (encrypted)          │
│ └─ Location: customer-finance bucket │
│ ├─ Encryption: Customer-managed key  │
│ └─ Access logs: Who, when, what      │ (S3 access logging)
└──────────────────────────────────────┘

Healthcare Customer Data Flow (parallel, isolated):
┌──────────────────────────────┐
│ Healthcare S3 bucket         │ (customer-healthcare-prod-data)
│ (HIPAA-compliant encryption) │ └─ Encryption key: HSM-stored (CMKK2)
└────────┬──────────────────────┘
         │ (Never interacts with Finance data)
         ▼
┌──────────────────────────────┐
│ Healthcare K8s Pod           │
│ (Different namespace)        │ Network isolation: Can't reach Finance pods
│ └─ Service account:          │
│    healthcare-trainer        │
└────────┬──────────────────────┘
         ▼
┌──────────────────────────────┐
│ Healthcare model artifacts   │
│ (HIPAA-compliant storage)    │
└──────────────────────────────┘

ISOLATION VERIFICATION:
Try: Finance pod connects to Healthcare S3 bucket
  ├─ Pod assumes: finance-trainer service account
  ├─ IAM policy check: Does finance-trainer have access to healthcare bucket?
  ├─ Result: DENIED (cross-tenant IAM policy blocks)
  └─ Security guarantee: Data isolation enforced

Try: Finance pod network connects to Healthcare pod
  ├─ Source: Finance namespace pod
  ├─ Destination: Healthcare namespace pod
  ├─ Network Policy: Blocks inter-namespace traffic
  ├─ Result: Connection times out (packet dropped)
  └─ Security guarantee: Network isolation enforced
```

**Compliance & Audit Trail**:

```
AUDIT LOGGING (Complete data access trail)

Every data access logged:
├─ Timestamp: 2026-04-05T14:23:42.123Z
├─ Who: user_id=john@finance.com, service_account=finance-trainer
├─ What: s3://customer-finance-prod-data/training/2026-04-05/data.parquet
├─ Action: GetObject (read)
├─ Result: SUCCESS / DENIED (if access denied)
├─ IP: 10.25.3.15 (pod IP in Finance namespace)
└─ Signed: AWS SigV4 signature (tamper-proof)

Storage:
├─ S3 server access logs (immutable, sent to separate read-only bucket)
├─ CloudTrail (all IAM, S3, RDS APIs)
├─ Application logs (model registry, feature store)
└─ Kubernetes audit logs (namespace; pod creation, secret access)

Retention:
├─ Finance (regulated): 7 years (SOX requirement)
├─ Healthcare (regulated): 10 years (HIPAA requirement)
├─ E-commerce (standard): 1 year
└─ SaaS (standard): 30 days

COMPLIANCE REPORTING

Finance Customer (SOX Compliance):
Request: \"Show me all access to financial model predictions data (2026-02-01 to 2026-04-05)\"
Response:
  Date          | User           | Action    | Dataset         | Result
  ────────────────────────────────────────────────────────────────────────
  2026-02-10    | john@finance   | GetObject | predictions.csv | SUCCESS
  2026-02-15    | jane@finance   | CreateBucket  | (attempt)   | DENIED (no permission)
  2026-03-01    | model_trainer  | GetObject | training_data   | SUCCESS
  └─ Report: 100% compliant (no unauthorized access)

Healthcare Customer (HIPAA Breach Notification):
Request: \"Audit trail for PHI (protected health information) access (2026-01-01 to 2026-04-05)\"
Response:
  ├─ PHI accessed by: 3 authorized data scientists
  ├─ Access purpose: Model training for readmission prediction
  ├─ Unauthorized access attempts: 0
  └─ Data breaches detected: None
  └─ Certification: HIPAA audit trail complete and tamper-proof

COMPLIANCE CONTROLS ENFORCED

Per-Customer Encryption:
├─ Finance: Customer-managed KMS key (customer controls key)
│  └─ AWS: We can't decrypt (customer is sole key holder)
│  └─ Benefit: Finance compliance: ✓ \"Only Finance team can decrypt their data\"
│
├─ Healthcare: HSM (Hardware Security Module) stored key
│  └─ AWS: Key in HSM, never touched by AWS employees
│  └─ Benefit: Healthcare/military-grade security
│
└─ E-commerce: AWS-managed key (default)
   └─ AWS: Manages key rotation, access control
   └─ Adequate for PCI DSS Level 1 compliance
```

**Secrets Management (Per-Tenant)**:

```
Scenario: Healthcare model needs API token to call external lab service

Storage:
├─ Kubernetes Secret: healthcare-api-token
│  ├─ Namespace: customer_healthcare_prod (only Healthcare namespace)
│  ├─ Encryption: Etcd encryption at rest (AWS KMS)
│  ├─ Access: Only healthcare-trainer service account
│  └─ Audit: Who accessed this secret (when, why)
│
└─ AWS Secrets Manager (alternative):
   ├─ Secret: healthcare-lab-api-token
   ├─ Resource policy: Only healthcare-trainer role can read
   ├─ Audit trail: CloudTrail logs who retrieved secret
   └─ Rotation: Automatic rotation every 30 days

Retrieving Secret (Pod execution):
1. Pod requests: \"Give me healthcare-lab-api-token\"
2. Secret manager verifies: \"Is this request from healthcare-trainer pod in healthcare namespace?\"
3. Result: 
   ├─ YES: Return decrypted secret (Finance pod: DENIED)
   ├─ NO: Return empty (access denied)
   └─ Audit: Log this access (unauthorized attempt flagged)
```

**End-to-End Isolation Verification (Penetration Test)**:

```
ATTACK 1: Finance data scientist tries to read Healthcare data
├─ Command: aws s3 ls s3://customer-healthcare-prod-data/
├─ Result: Access Denied
│  └─ IAM policy: finance-trainer NOT listed in healthcare-prod-data bucket policy
│  └─ Cross-account access blocked (separate AWS accounts)
│  └─ Audit: Attempted unauthorized access logged
│
└─ Security: ✓ PASSED

ATTACK 2: Malicious pod in Finance namespace tries to connect to Healthcare pod
├─ Command: curl http://healthcare-trainer-pod.customer-healthcare-prod.svc.cluster.local
├─ Result: No route to host (timeout)
│  └─ Kubernetes network policy: Blocks inter-namespace traffic
│  └─ Service mesh (Istio): Enforces mTLS (mutual authentication fails)
│  └─ Audit: Attempted inter-namespace connection blocked
│
└─ Security: ✓ PASSED

ATTACK 3: Model artifact containshidden data leak (embedding sensitive data in model)
├─ Scenario: Finance modelserialized with raw training data embedded
├─ Detection:
│  ├─ Model artifact scanning: Regex on serialized pickle file
│  ├─ Detect: Unencrypted credit card numbers in model file
│  ├─ Result: Model rejected from registry (fails compliance gate)
│  └─ Alert: Incident triggered (potential data exfiltration attempt)
│
└─ Security: ✓ PASSED (detected via content scanning)

ATTACK 4: Compromised service account (stolen from pod)
├─ Attacker gains: finance-trainer service account token
├─ Attempts: aws s3 ls s3://customer-healthcare-prod-data/
├─ Result: Access Denied (token tied to finance-trainer role)
│  └─ Role: Only has permissions for finance-prod-data bucket
│  └─ Cross-account: Can't access different AWS account
│  └─ Audit: Unauthorized API call from token logged + alerted
│
├─ Attacker escalation attempt: Create new IAM user
├─ Result: Denied (finance-trainer role lacks iam:CreateUser)
│  └─ Least privilege: finance-trainer role has minimal permissions
│  └─ Audit: Unauthorized iam:CreateUser attempt logged
│
└─ Security: ✓ PASSED (least privilege enforcement)
```

**Defense in Depth Summary**:

```
Layer 1: IDENTITY
  └─ Who: Authenticated via SSO per customer

Layer 2: NETWORK
  └─ Where: Kubernetes namespace isolation + network policies

Layer 3: ACCESS CONTROL
  └─ What: IAM roles + RBAC (can read only own resources)

Layer 4: ENCRYPTION
  └─ How protected: Customer-managed keys (customer controls)

Layer 5: AUDIT
  └─ Evidence: All access logged (tamper-proof, immutable)

Layer 6: DETECTION
  └─ Monitoring: Alert on unauthorized access attempts + anomalies

Result: ✓ Zero-trust architecture
  ├─ No implicit trust based on network
  ├─ Every access authenticated + authorized + logged
  ├─ Compliance: Finance (SOX), Healthcare (HIPAA), E-commerce (PCI) all satisfied
  └─ Data isolation guaranteed by architecture (not by process/training)
```

**Key Architectural Decisions**:

1. **Separate AWS accounts per customer**: Hardest boundary. IAM can't accidentally grant cross-account access.
2. **Kubernetes namespace + network policy**: Soft boundary (pod-level), but auditable. Don't rely alone; combine with IAM.
3. **Customer-managed encryption keys**: Finance controls their key (AWS can't access). Strongest compliance story.
4. **Service mesh (Istio) for pod communication**: Every pod-to-pod call authenticated (mTLS). Prevents pod impersonation.
5. **Immutable audit logs**: CloudTrail → separate read-only S3 bucket. Attacker can't cover tracks by deleting logs.

**Real-World Challenge**: "We isolated customer data perfectly. But a model trained on Healthcare data was accidentally deployed to Finance infrastructure. Models leaked customer identities via feature importance."
- **Solution**: Extend isolation to model registries. Tag models by customer. Audit trail tracks which model + which data training it. Prevent cross-customer model deployment at deployment gate.

---

**Version**: 1.1 (Comprehensive + 10 Interview Questions)  
**Last Updated**: April 2026  
**Status**: ✅ COMPLETE - All 13 sections including foundation, 9 subtopics, 4 hands-on scenarios, and 10 senior-level interview questions.

This MLOps study guide provides Senior DevOps engineers with production-grade knowledge covering 9 major topics: Security, Infrastructure, Cost Management, Multi-Tenancy, Continuous Learning, A/B Testing, Edge Deployment, Pipeline Architecture, and Responsible AI. Each includes deep technical mechanisms, code examples, ASCII diagrams, best practices, real-world examples, and interview preparation. Use as operational reference, team alignment, or career development resource.



