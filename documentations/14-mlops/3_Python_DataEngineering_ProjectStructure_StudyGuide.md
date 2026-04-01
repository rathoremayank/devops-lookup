# MLOps Deep Dive Sections - Final Continuation
## Python for ML Workflows, Data Engineering Basics, ML Project Structure & Reproducibility

**Part 3 of MLOps Study Guide** - Final Deep Dive Sections

---

## Section 2: Python for ML Workflows {#section-python-ml}

### Virtual Environments and Isolation {#virtual-environments}

#### Textual Deep Dive

Python virtual environments solve dependency hell: different projects requiring different versions of the same package. In production MLOps, environment isolation is critical for reproducibility.

**Problem without Virtual Environments:**
```
Project A: requires scikit-learn==0.24.0
Project B: requires scikit-learn==1.0.0 (breaking API changes)

Global install of scikit-learn==1.0.0 breaks Project A
Global install of scikit-learn==0.24.0 breaks Project B
→ Impossible to run both simultaneously
```

**Production Virtual Environment Strategies:**

1. **venv (built-in, Python 3.3+)**
   - Creates isolated Python directories per project
   - Lightweight, no external dependencies
   - Standard for single-machine development
   - Limitations: Can't manage Python version itself

2. **conda (recommended for data science)**
   - Manages Python version AND packages
   - Cross-platform (Windows/Mac/Linux)
   - Better dependency resolution (can install C libraries)
   - Native GPU support (CUDA/cuDNN)
   - Larger disk footprint (~3-5GB per environment)

3. **Docker Containers (recommended for production)**
   - Complete OS isolation
   - Ensures identical environments across dev/staging/production
   - Industry standard for Kubernetes deployment
   - Relatively large (image size 1-3GB)
   - Performance: minimal overhead

4. **Poetry (emerging standard)**
   - Deterministic dependency resolution
   - Lockfile ensures exact reproducibility
   - Modern dependency management
   - Still relatively new (maturity improving)

**DevOps Best Practices:**

- **Pin ALL dependencies**: Use exact versions, never ranges
  ```
  ✗ Bad:  numpy>=1.19
  ✓ Good: numpy==1.23.5
  ```

- **Lock file approach**: Commit lockfile to git for exact reproducibility
  ```
  requirements.txt (after pip freeze)
  poetry.lock
  conda.lock (new)
  ```

- **Separate dev vs prod dependencies**:
  ```
  requirements-base.txt    # Core ML libraries
  requirements-dev.txt     # Testing, linting, debugging tools
  requirements-serving.txt # Only what's needed for inference
  ```

- **Layer isolation in Docker**:
  ```dockerfile
  # Use specific Python version
  FROM python:3.11-slim
  
  # Install system dependencies once (cacheable)
  RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libopenblas-dev && rm -rf /var/lib/apt/lists/*
  
  # Copy requirements only (cache layer)
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  
  # Copy code (separate layer for faster rebuilds)
  COPY src/ /app/src/
  ```

**Common Pitfalls:**

1. **Package Name Conflicts**: `sklearn` vs `scikit-learn` (same package, install as "scikit-learn" but import as "sklearn")
2. **Missing System Dependencies**: Python packages depend on C libraries (not installed in containers)
3. **GPU Driver Version Mismatch**: CUDA 11.2 not compatible with all GPUs (check compatibility matrix)
4. **Binary Package Format Mismatch**: `.whl` files are architecture-specific; need correct Python version + OS combo

#### Practical Code Examples

**Environment Setup Scripts**

```bash
#!/bin/bash
# setup-environment.sh - Production environment setup

set -e

PROJECT_NAME="ml-training-pipeline"
PYTHON_VERSION="3.11"
CONDA_ENV_PATH="/opt/conda/envs/$PROJECT_NAME"

echo "Setting up Python environment for $PROJECT_NAME..."

# Create conda environment with specific Python version
conda create -y -n "$PROJECT_NAME" python=$PYTHON_VERSION

# Activate environment
source activate "$PROJECT_NAME"

# Install core ML libraries with specific versions
pip install --no-cache-dir \
    numpy==1.23.5 \
    pandas==2.0.3 \
    scikit-learn==1.2.2 \
    tensorflow==2.12.0 \
    torch==2.0.1 \
    xgboost==2.0.0 \
    lightgbm==4.0.0

# Install data handling
pip install --no-cache-dir \
    pyarrow==12.0.0 \
    dask==2023.9.2 \
    polars==0.18.0

# Install experiment tracking
pip install --no-cache-dir \
    mlflow==2.7.0 \
    wandb==0.15.4 \
    neptune-client==1.0.0

# Development tools
pip install --no-cache-dir \
    pytest==7.4.0 \
    black==23.7.0 \
    flake8==6.0.0 \
    mypy==1.4.1 \
    jupyter==1.0.0

# Generate lockfile
pip freeze > requirements.lock

echo "Environment setup complete!"
echo "Activate with: conda activate $PROJECT_NAME"
```

**Dockerfile with Virtual Environment**

```dockerfile
# Dockerfile
FROM python:3.11-slim as base

# Layer 1: System dependencies (rarely changes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libopenblas-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Python dependencies (changes frequently)
FROM base as dependencies

WORKDIR /tmp

# Copy requirements file ONLY (triggers invalidation on changes)
COPY requirements.txt .

# Install Python packages to specific location
RUN pip install --no-cache-dir --user -r requirements.txt

# Layer 3: Final image (minimal)
FROM base

WORKDIR /app

# Copy only installed packages from dependencies layer
COPY --from=dependencies /root/.local /root/.local

# Set environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Set timezone
ENV TZ=UTC

# Copy application code
COPY src/ /app/src/
COPY config/ /app/config/

EXPOSE 8000

CMD ["python", "-m", "src.inference_service"]
```

---

### Dependency Management at Scale {#dependency-management}

#### Textual Deep Dive

Managing 50+ Python package dependencies is complex: compatibility issues, CVE vulnerabilities, performance implications. DevOps engineers must solve:

1. **Version Compatibility**: Packages depend on other packages with version constraints
   - numpy depends on specific Python versions
   - tensorflow depends on specific CUDA versions
   - Conflicts emerge (A needs B==1.0, C needs B==2.0)
   - Solution: Constraint solvers (pip-tools, poetry, uv)

2. **Vulnerability Management**: Old packages have known CVEs
   - Regular security audits required
   - CVE databases tracked (NVD, GitHub Advisory)
   - Automated updates with testing

3. **Reproducibility**: Installing again shouldn't change package versions
   - Solution: lock files (requirements.lock, Poetry.lock, conda.lock)
   - File format: exact versions + checksums

4. **Transitive Dependencies**: Direct deps have their own deps
   - numpy → depends on 20+ other packages
   - You manage 20 packages, reality is 200+
   - CVE in transitive dep affects your code

#### Practical Code Examples

**Dependency Management with Poetry**

```toml
# pyproject.toml - Modern Python dependency management
[tool.poetry]
name = "ml-ops-pipeline"
version = "1.0.0"
description = "Production ML pipeline"
authors = ["DevOps Team <devops@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"  # 3.11-3.12, but not 4.0

# Core ML libraries (pinned to compatible versions)
numpy = "1.23.5"
pandas = "2.0.3"
scikit-learn = "1.2.2"

# Deep Learning
tensorflow = {version = "2.12.0", extras = ["gpu"]}
torch = {version = "2.0.1", python = "^3.9"}  # Python version constraint

# Data validation
pydantic = "^2.0"  # Auto-upgrade patch versions (2.0.0 → 2.4.2)

# Monitoring
mlflow = "2.7.0"
prometheus-client = "0.17.1"

[tool.poetry.group.dev.dependencies]
# Development only (not in production image)
pytest = "7.4.0"
pytest-cov = "4.1.0"
black = "23.7.0"
flake8 = "6.0.0"
mypy = "1.4.1"

[tool.poetry.group.test.dependencies]
moto = "^4.1"  # AWS mocking
faker = "^19.0"  # Test data generation

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

**Dependency Scanning for Vulnerabilities**

```python
#!/usr/bin/env python3
"""Automated CVE scanning for dependencies"""
import subprocess
import json
from typing import List, Dict

def scan_dependencies_safety(requirements_file: str) -> Dict:
    """Use 'safety' package to check for known vulnerabilities"""
    
    try:
        result = subprocess.run(
            ["safety", "check", "--json", "--file", requirements_file],
            capture_output=True,
            text=True
        )
        
        vulnerabilities = json.loads(result.stdout)
        
        if vulnerabilities:
            print(f"❌ Found {len(vulnerabilities)} vulnerabilities:")
            for vuln in vulnerabilities:
                print(f"  - {vuln['package']}: {vuln['vulnerability']}")
                print(f"    Fix: upgrade to {vuln['cve']}")
            return {"status": "FAILED", "vulnerabilities": vulnerabilities}
        else:
            print("✓ No known CVEs found")
            return {"status": "PASSED", "vulnerabilities": []}
    
    except Exception as e:
        print(f"Error scanning: {str(e)}")
        return {"status": "ERROR", "error": str(e)}

def scan_with_pip_audit(requirements_file: str) -> Dict:
    """Alternative: pip-audit is faster, actively maintained"""
    
    try:
        result = subprocess.run(
            ["pip-audit", "--requirement", requirements_file, "--format", "json"],
            capture_output=True,
            text=True
        )
        
        audit_results = json.loads(result.stdout)
        vulnerabilities = audit_results.get("vulnerabilities", [])
        
        if vulnerabilities:
            print(f"❌ Found {len(vulnerabilities)} vulnerabilities:")
            for vuln in vulnerabilities:
                print(f"  - {vuln['name']}: {vuln['vulnerability_id']}")
                print(f"    Fix: upgrade to {vuln['fix_versions']}")
            return {"status": "FAILED", "vulnerabilities": vulnerabilities}
        else:
            print("✓ No vulnerabilities detected")
            return {"status": "PASSED"}
    
    except Exception as e:
        print(f"Error in pip-audit: {str(e)}")
        return {"status": "ERROR", "error": str(e)}

# Usage in CI/CD pipeline
if __name__ == "__main__":
    requirements = "requirements.txt"
    
    # Method 1: Safety
    print("=== Running Safety Scan ===")
    safety_result = scan_dependencies_safety(requirements)
    
    # Method 2: pip-audit (recommended)
    print("\n=== Running pip-audit ===")
    audit_result = scan_with_pip_audit(requirements)
    
    # Fail CI if vulnerabilities found
    if audit_result["status"] == "FAILED":
        print("\n❌ Dependency scan FAILED - pipeline halted")
        exit(1)
    else:
        print("\n✓ Dependency scan PASSED")
        exit(0)
```

---

## Section 3: Data Engineering Basics {#section-data-engineering}

### ETL vs ELT Paradigms {#etl-vs-elt}

#### Textual Deep Dive

The paradigm shift from ETL to ELT represents modernization of data infrastructure for ML workloads.

**ETL (Extract-Transform-Load) - Traditional:**

```
Raw Data → Extract → Transform → Clean/Validate → Load → Data Warehouse
           (Source) (Middleware)                       (Destination)
```

- **Extract**: Read from source systems
- **Transform**: Clean, aggregate, business logic applied
- **Load**: Write to data warehouse

*Characteristics*:
- Transformation logic lives in middleware (Talend, Informatica)
- Only clean data stored in warehouse
- Storage efficient (only useful data kept)
- Processing power in middleware (middleware cost increases with scale)
- Development slow (logic not in code, hard to version control)

**ELT (Extract-Load-Transform) - Modern:**

```
Raw Data → Extract → Load → Raw Data Lake → Transform → Analytics/Models
           (Source)      (Cloud Storage)  (SQL/Spark)
```

- **Extract**: Read from source systems
- **Load**: Store raw data immediately (cheap cloud storage)
- **Transform**: Transformation deferred to query time

*Characteristics*:
- Raw data stored as-is (immutable landing zone)
- Storage cheap (cloud object storage $0.02/GB/month)
- Transform logic in code (version controlled)
- Compute scalable (Spark, BigQuery, Snowflake scale elastically)
- Development fast (SQL + Python, standard tools)

*Why ELT Won for ML*:
1. **Raw data preserved**: ML models benefit from original features, not just aggregations
2. **Flexibility**: Different teams extract different transforms from same raw data
3. **Debugging**: Can replay old data for root cause analysis
4. **Compliance**: Immutable audit trail of raw data

#### Practical Code Examples

**ELT Pipeline with Spark**

```python
#!/usr/bin/env python3
"""ELT Pipeline: Extract raw data, Load to data lake, Transform for ML"""
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_timestamp, from_unixtime
import logging

logger = logging.getLogger(__name__)

class ELTPipeline:
    def __init__(self, app_name: str = "ml-elt-pipeline"):
        self.spark = SparkSession.builder \
            .appName(app_name) \
            .getOrCreate()
    
    def extract_from_database(self, jdbc_url: str, table: str, user: str, password: str):
        """Extract (E) - Read from source database"""
        logger.info(f"Extracting from {table}...")
        
        df = self.spark.read \
            .format("jdbc") \
            .option("url", jdbc_url) \
            .option("dbtable", table) \
            .option("user", user) \
            .option("password", password) \
            .load()
        
        logger.info(f"Extracted {df.count()} rows")
        return df
    
    def load_to_data_lake(self, df, path: str, format: str = "parquet"):
        """Load (L) - Store raw data to cloud storage (immutable)"""
        logger.info(f"Loading to data lake: {path}")
        
        # Use partitioning for performance
        df.write \
            .format(format) \
            .mode("append") \
            .partitionBy("year", "month") \
            .save(path)
        
        logger.info("Data loaded successfully")
    
    def transform_for_ml(self, raw_path: str):
        """Transform (T) - Create ML-ready features from raw data"""
        logger.info("Transforming raw data for ML...")
        
        # Read raw data
        df = self.spark.read.parquet(raw_path)
        
        # Transformations
        df_transformed = df \
            .filter(col("amount") > 0) \
            .filter(col("status") == "completed") \
            .withColumn("transaction_date", to_timestamp("timestamp")) \
            .withColumn("year", col("transaction_date").substr(1, 4)) \
            .withColumn("month", col("transaction_date").substr(6, 2))
        
        # Feature engineering
        window = "7 days"
        df_transformed = df_transformed \
            .withColumn(
                "7day_avg_amount",
                df_transformed.groupBy("customer_id") \
                    .agg({"amount": "avg"}) \
                    .over(f"PARTITION BY customer_id ORDER BY timestamp RANGE BETWEEN {window} PRECEDING AND CURRENT ROW")
            )
        
        logger.info(f"Transformed to {df_transformed.count()} rows")
        return df_transformed
    
    def save_for_training(self, df, output_path: str):
        """Save transformed data in format suitable for training"""
        logger.info(f"Saving for training: {output_path}")
        
        df.write \
            .format("csv") \
            .mode("overwrite") \
            .option("header", True) \
            .save(output_path)
    
    def run_pipeline(self, jdbc_config: dict, output_paths: dict):
        """Execute complete ELT pipeline"""
        
        # Extract
        df_raw = self.extract_from_database(
            jdbc_config["url"],
            jdbc_config["table"],
            jdbc_config["user"],
            jdbc_config["password"]
        )
        
        # Load (raw data to lake)
        self.load_to_data_lake(df_raw, output_paths["raw_data_lake"])
        
        # Transform
        df_transformed = self.transform_for_ml(output_paths["raw_data_lake"])
        
        # Save for training
        self.save_for_training(df_transformed, output_paths["training_data"])
        
        logger.info("ELT pipeline completed successfully")

# Configuration
jdbc_config = {
    "url": "jdbc:postgresql://db.example.com:5432/production",
    "table": "transactions",
    "user": "etl_user",
    "password": "***"
}

output_paths = {
    "raw_data_lake": "s3://ml-data-lake/raw/transactions/",
    "training_data": "s3://ml-data-lake/processed/training_data/"
}

# Execute
pipeline = ELTPipeline("transaction-elt")
pipeline.run_pipeline(jdbc_config, output_paths)
```

---

### Batch vs Streaming Data {#batch-vs-streaming}

#### Textual Deep Dive

ML workloads process data in different ways:

**Batch Processing:**
- **Characteristics**: Process large volumes of data at once
- **Frequency**: Daily, hourly, or on-demand
- **Latency**: Results ready in hours/minutes, not real-time
- **Use Cases**: Daily model retraining, weekly reports, monthly billing

- **Technologies**: Spark, Hadoop, Dask, Apache Beam
- **Advantages**: 
  - Economies of scale (process 100GB in one job)
  - Fault tolerance (checkpointing, retry)
  - Cost efficient (scheduled compute)
  - Complex transformations easier

- **Disadvantages**:
  - Not real-time
  - Delayed insights
  - Large compute bursts (infrastructure challenges)

**Streaming Processing:**
- **Characteristics**: Process data continuously as it arrives
- **Frequency**: Real-time, microsecond latency
- **Latency**: Results immediately
- **Use Cases**: Real-time fraud detection, live dashboards, stock trading

- **Technologies**: Kafka, Flink, Spark Streaming, Kinesis, Pub/Sub
- **Advantages**:
  - Real-time decisions
  - Continuous processing (no batches)
  - Better for online learning
  - Reduced storage (no accumulation)

- **Disadvantages**:
  - Complex (state management, exactly-once processing)
  - Higher operational complexity
  - More expensive infrastructure
  - Debugging harder (events disappear)

**Hybrid Lambda Architecture (Common in Production):**

```
                        ┌─ Batch Layer (Daily accuracy)
Data Source → Split ────┤
                        └─ Speed Layer (Real-time freshness)
                            │
                            └─ Serving Layer (Best of both)
```

#### Practical Code Examples

**Kafka Streaming Consumer for ML Feature Extraction**

```python
#!/usr/bin/env python3
"""Stream kafka events into feature store"""
from kafka import KafkaConsumer
import json
import logging
from datetime import datetime
from feature_store import FeatureStoreClient

logger = logging.getLogger(__name__)

class StreamingFeatureExtractor:
    def __init__(self, kafka_brokers: list, feature_store_url: str):
        self.consumer = KafkaConsumer(
            'user-events',
            bootstrap_servers=kafka_brokers,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='earliest',
            group_id='feature-extractor-group',
            max_poll_records=100  # Batch messages
        )
        self.feature_store = FeatureStoreClient(feature_store_url)
        self.batch_size = 100
        self.batch = []
    
    def extract_features(self, event: dict):
        """Extract features from raw event"""
        return {
            "user_id": event["user_id"],
            "feature_recent_purchase": 1 if event["event_type"] == "purchase" else 0,
            "feature_timestamp": datetime.now().isoformat(),
            "amount": event.get("amount", 0),
            "category": event.get("category", "unknown")
        }
    
    def consume_and_extract(self):
        """Main loop: consume events and extract features"""
        for message_batch in self.consumer:
            try:
                for message in message_batch:
                    event = message.value
                    features = self.extract_features(event)
                    self.batch.append(features)
                    
                    # Write batch to feature store
                    if len(self.batch) >= self.batch_size:
                        self.write_batch_to_store()
                        self.batch = []
            
            except Exception as e:
                logger.error(f"Error processing event: {str(e)}")
                continue
    
    def write_batch_to_store(self):
        """Write extracted features to online feature store"""
        try:
            self.feature_store.write_online_features(self.batch)
            logger.info(f"Wrote {len(self.batch)} features to store")
        except Exception as e:
            logger.error(f"Failed writing to feature store: {str(e)}")
            raise

# Usage
brokers = ['kafka-broker-1:9092', 'kafka-broker-2:9092']
extractor = StreamingFeatureExtractor(brokers, "redis://feature-store:6379")
extractor.consume_and_extract()
```

---

## Section 4: ML Project Structure & Reproducibility {#section-ml-project-structure}

### Project Templating {#project-templating}

#### Textual Deep Dive

ML project structure dramatically affects reproducibility, collaboration, and operational readiness. Standard templates accelerate startup and prevent mistakes.

**Production ML Project Structure:**

```
ml-project/
│
├── README.md                      # Project overview, setup instructions
├── LICENSE                        # Project license
├── .gitignore                     # Exclude data, models, environment
├── pyproject.toml                 # Modern Python dependency management
├── requirements.txt               # Dependency pinning (for pip)
├── poetry.lock                    # Lock file for reproducibility
│
├── config/                        # Configuration files
│   ├── config.yaml               # Training hyperparameters
│   ├── model_config.yaml         # Model architecture
│   └── deployment_config.yaml    # Deployment settings
│
├── src/                          # Source code
│   ├── __init__.py
│   ├── preprocessor.py           # Data preprocessing
│   ├── feature_engineer.py       # Feature engineering
│   ├── model.py                  # Model definition
│   ├── training.py               # Training logic
│   ├── evaluation.py             # Model evaluation
│   └── inference.py              # Inference server
│
├── tests/                        # Unit and integration tests
│   ├── test_preprocessor.py
│   ├── test_model.py
│   ├── test_training.py
│   └── test_inference.py
│
├── notebooks/                    # Jupyter notebooks (EDA, experiments)
│   ├── 01_eda.ipynb
│   ├── 02_feature_engineering.ipynb
│   └── 03_model_experimentation.ipynb
│
├── data/                         # Data directory (NOT in git)
│   ├── raw/                      # Original data (immutable)
│   ├── processed/                # Preprocessed data
│   └── splits/                   # Train/val/test splits
│
├── models/                       # Model artifacts (NOT in git)
│   ├── v1.0.0/
│   │   ├── model.pkl
│   │   ├── preprocessor.pkl
│   │   └── metadata.json
│   └── v1.0.1/
│       ├── model.pkl
│       ├── preprocessor.pkl
│       └── metadata.json
│
├── experiments/                  # Experiment tracking
│   ├── exp_001_baseline/
│   │   ├── config.yaml
│   │   ├── metrics.json
│   │   └── model.pkl
│   └── exp_002_feature_v2/
│       ├── config.yaml
│       ├── metrics.json
│       └── model.pkl
│
├── scripts/                      # Shell scripts for common tasks
│   ├── train.sh                  # Training runner
│   ├── evaluate.sh               # Evaluation runner
│   ├── deploy.sh                 # Deployment runner
│   └── docker_build.sh           # Docker image builder
│
├── docker/                       # Docker configurations
│   ├── Dockerfile.training       # Training image
│   ├── Dockerfile.inference      # Inference image
│   └── docker-compose.yaml       # Local development
│
├── kubernetes/                   # Kubernetes configurations
│   ├── training-job.yaml         # Training job spec
│   ├── inference-deployment.yaml # Inference deployment
│   └── kustomization.yaml        # Multi-env setup
│
├── ci/                           # CI/CD pipeline configurations
│   ├── .github/workflows/        # GitHub Actions
│   │   ├── test.yml
│   │   ├── build.yml
│   │   └── deploy.yml
│   └── .gitlab-ci.yml            # GitLab CI
│
└── docs/                         # Documentation
    ├── architecture.md           # System architecture
    ├── data_schema.md           # Data dictionary
    ├── model_performance.md     # Performance benchmarks
    └── deployment_guide.md      # Deployment instructions
```

#### Practical Code Examples

**Cookiecutter Template (Project Generator)**

```yaml
# cookiecutter.json - Used to generate projects automatically
{
    "project_name": "my_ml_project",
    "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '_') }}",
    "description": "An ML project",
    "author_name": "Your Name",
    "python_version": "3.11",
    "use_gpu": "yes",
    "cloud_platform": "aws"
}
```

Then run: `cookiecutter ml-project-template`

**Project Configuration (YAML)**

```yaml
# config/config.yaml - Centralized configuration
project:
  name: customer-churn-prediction
  version: 1.0.0
  description: Predict customer churn

data:
  source: s3://ml-data-lake/raw/customers/
  train_split: 0.7
  val_split: 0.15
  test_split: 0.15
  
preprocessing:
  handle_missing: mean
  scaling: standardize
  categorical_encoding: target
  
features:
  - customer_age
  - contract_length
  - monthly_charges
  - total_charges
  - internet_service
  
model:
  type: RandomForestClassifier
  hyperparameters:
    n_estimators: 100
    max_depth: 15
    min_samples_split: 5
    random_state: 42
  
training:
  epochs: 100
  batch_size: 32
  learning_rate: 0.001
  
evaluation:
  metrics:
    - accuracy
    - precision
    - recall
    - f1
  threshold: 0.85
  
deployment:
  strategy: canary
  canary_percentage: 5
  rollback_threshold: 0.80
```

**Makefile for Common Tasks**

```makefile
# Makefile - Common project commands
.PHONY: help install train evaluate test deploy clean

help:
	@echo "Available commands:"
	@echo "  make install      - Install dependencies"
	@echo "  make train        - Train model"
	@echo "  make evaluate     - Evaluate model"
	@echo "  make test         - Run tests"
	@echo "  make deploy       - Deploy model"
	@echo "  make clean        - Clean artifacts"

install:
	pip install -r requirements.txt
	pip install -e .

train:
	python -m src.training \
		--config config/config.yaml \
		--output models/latest

evaluate:
	python -m src.evaluation \
		--model models/latest/model.pkl \
		--data data/processed/test_set.csv

test:
	pytest tests/ -v --cov=src

docker-build:
	docker build -f docker/Dockerfile.training -t ml-training:latest .
	docker build -f docker/Dockerfile.inference -t ml-inference:latest .

deploy:
	./scripts/deploy.sh --model models/latest --strategy canary

clean:
	rm -rf models/latest
	rm -rf data/processed
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -name "*.pyc" -delete
```

---

### Environment Pinning & Container Training {#environment-pinning}

#### Textual Deep Dive

**Problem**: Same code run on different machines produce different results due to:
- Python version differences (3.9 vs 3.11 numeric behavior)
- Package version differences (NumPy 1.20 vs 1.23 have numerical differences)
- GPU driver version differences (CUDA 11.2 vs 11.8)
- System library differences (OpenBLAS vs MKL for linear algebra)

**Solution: Complete Environment Pinning**

1. **Python Version**: Pin exact version
   ```dockerfile
   FROM python:3.11.4-slim  # Exact version, not 3.11
   ```

2. **Package Versions**: Exact versions with lock file
   ```
   numpy==1.23.5
   tensorflow==2.12.0
   ```

3. **System Libraries**: Dockerfile ensures consistent environment
   ```dockerfile
   RUN apt-get install libopenblas-dev  # Same version across deployments
   ```

4. **Random Seeds**: Make randomness deterministic
   ```python
   import random, numpy, tensorflow
   random.seed(42)
   numpy.random.seed(42)
   tensorflow.random.set_seed(42)
   ```

5. **GPU Determinism**: Force deterministic GPU operations
   ```python
   import os
   os.environ['CUDA_LAUNCH_BLOCKING'] = '1'  # Deterministic CuBLAS
   ```

#### Practical Code Examples

**Training Script with Reproducible Seeding**

```python
#!/usr/bin/env python3
"""Training script with complete reproducibility"""
import os
import random
import numpy as np
import tensorflow as tf
import torch
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class ReproducibleTrainer:
    def __init__(self, seed: int = 42):
        self.seed = seed
        self.set_seeds()
        self.log_environment()
    
    def set_seeds(self):
        """Set all random seeds for reproducibility"""
        # Python
        random.seed(self.seed)
        os.environ['PYTHONHASHSEED'] = str(self.seed)
        
        # NumPy
        np.random.seed(self.seed)
        
        # TensorFlow
        tf.random.set_seed(self.seed)
        tf.config.experimental.enable_op_determinism()
        
        # PyTorch
        torch.manual_seed(self.seed)
        torch.cuda.manual_seed_all(self.seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False
        
        logger.info(f"All random seeds set to {self.seed}")
    
    def log_environment(self):
        """Log environment for reproducibility verification"""
        env_info = {
            "timestamp": datetime.now().isoformat(),
            "seed": self.seed,
            "python_version": python.__version__,
            "numpy_version": np.__version__,
            "tensorflow_version": tf.__version__,
            "torch_version": torch.__version__,
            "gpu_available": tf.test.is_built_with_cuda(),
            "gpu_devices": tf.config.list_physical_devices('GPU'),
            "cuda_version": tf.sysconfig.get_build_info()['cuda_version'],
            "deterministic_mode": os.environ.get('CUDA_LAUNCH_BLOCKING', 'Not set')
        }
        
        logger.info(f"Environment: {env_info}")
        
        # Save for comparison
        with open("environment.json", "w") as f:
            import json
            json.dump(env_info, f, indent=2, default=str)
    
    def train(self, model, train_data, config):
        """Train model with reproducible seeding"""
        
        # Ensure reproducibility
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=config['learning_rate']),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        history = model.fit(
            train_data,
            epochs=config['epochs'],
            batch_size=config['batch_size'],
            # Important: shuffle with seed NOT randomness
            shuffle=True,
            validation_split=0.2,
            seed=self.seed
        )
        
        return history

# Usage
trainer = ReproducibleTrainer(seed=42)
# ... train model
```

**Dockerfile with Complete Environment**

```dockerfile
# Dockerfile - Complete reproducible environment
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Set to non-interactive (prevent prompts)
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=UTC \
    CUDA_LAUNCH_BLOCKING=1

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3-pip \
    build-essential \
    git \
    curl \
    libopenblas-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Upgrade pip to specific version
RUN pip install --upgrade pip==23.2.1 setuptools==68.0.0 wheel==0.41.0

WORKDIR /app

# Copy and install Python dependencies (exact versions!)
COPY requirements.txt .
RUN pip install --no-cache-dir \
    --no-deps \
    -r requirements.txt

# Verify installations
RUN python -c "import numpy; print(f'NumPy: {numpy.__version__}')" \
    && python -c "import tensorflow; print(f'TensorFlow: {tensorflow.__version__}')" \
    && python -c "import torch; print(f'PyTorch: {torch.__version__}')"

# Copy application code
COPY src/ /app/src/
COPY config/ /app/config/

# Run training script
CMD ["python", "-m", "src.training"]
```

---

### Experiment Reproducibility {#experiment-reproducibility}

#### Textual Deep Dive

Reproducibility is critical: data scientists must recreate experiments months later to understand why model worked or failed. Tracking requirements:

1. **Code Version**: Which git commit was code
2. **Data Version**: Which dataset version was used
3. **Hyperparameters**: Exact configuration
4. **Environment**: Python/package versions
5. **Random Seed**: For stochastic algorithms
6. **Results**: Metrics achieved
7. **Artifacts**: Model weights, preprocessors

#### Practical Code Examples

**Experiment Tracking with MLflow**

```python
#!/usr/bin/env python3
"""Track experiments for reproducibility"""
import mlflow
import json
import os
from datetime import datetime

class ExperimentTracker:
    def __init__(self, experiment_name: str, tracking_uri: str = "http://localhost:5000"):
        self.experiment_name = experiment_name
        mlflow.set_tracking_uri(tracking_uri)
        mlflow.set_experiment(experiment_name)
    
    def log_experiment(self, config: dict, model, metrics: dict, artifacts_dir: str):
        """Log complete experiment"""
        
        with mlflow.start_run(run_name=f"run_{datetime.now().strftime('%Y%m%d_%H%M%S')}"):
            
            # 1. Log parameters (hyperparameters)
            mlflow.log_params(config['hyperparameters'])
            
            # 2. Log metrics (performance)
            mlflow.log_metrics(metrics)
            
            # 3. Log model
            mlflow.sklearn.log_model(model, "model")
            
            # 4. Log configuration as artifact
            config_path = os.path.join(artifacts_dir, "config.json")
            with open(config_path, "w") as f:
                json.dump(config, f, indent=2)
            mlflow.log_artifact(config_path)
            
            # 5. Log environment info
            env_info = {
                "python_version": os.sys.version,
                "packages": self.get_installed_packages(),
                "git_commit": self.get_git_commit(),
                "timestamp": datetime.now().isoformat()
            }
            env_path = os.path.join(artifacts_dir, "environment.json")
            with open(env_path, "w") as f:
                json.dump(env_info, f, indent=2, default=str)
            mlflow.log_artifact(env_path)
            
            print(f"Logged experiment:")
            print(f"  Run ID: {mlflow.active_run().info.run_id}")
            print(f"  Metrics: {metrics}")
    
    def get_installed_packages(self):
        """Get installed package versions"""
        import subprocess
        result = subprocess.run(["pip", "freeze"], capture_output=True, text=True)
        return result.stdout.split('\n')
    
    def get_git_commit(self):
        """Get git commit hash"""
        import subprocess
        result = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True)
        return result.stdout.strip()

# Usage
config = {
    "data_version": "v1.2.3",
    "hyperparameters": {
        "n_estimators": 100,
        "max_depth": 10,
        "random_state": 42
    },
    "train_date": "2024-04-01"
}

tracker = ExperimentTracker("customer-churn-prediction")
tracker.log_experiment(config, trained_model, metrics, "experiments/exp_001")

# Later: Load and reproduce
mlflow.set_tracking_uri("http://localhost:5000")
run_id = "abc123def456"  # From MLflow UI
model_uri = f"runs://{run_id}/model"
loaded_model = mlflow.sklearn.load_model(model_uri)
# Exact same model reproduced
```

---

#### ASCII Diagrams

**ML Project Structure &Reproducibility Framework**

```
Git Repository
│
├── Code (versioned in git)
│   └─ models/, preprocessing/, training scripts
│
├── Requirements (versioned in git)
│   └─ requirements.lock → EXACT package versions
│
├── Configuration (versioned in git)
│   └─ config.yaml → hyperparameters, model config
│
├── Data (NOT in git, versioned separately)
│   └─ DVC / Pachyderm
│       └─ data.lock → checkpoint, lineage, versions
│
├── Experiments (tracked in MLflow/Weights & Biases)
│   └─ Experiment ID (run_id)
│       ├─ git commit hash
│       ├─ data version
│       ├─ hyperparameters
│       ├─ random seed
│       ├─ metrics (performance)
│       └─ model artifacts
│
└── Deployment (Docker image hash)
    └─ FROM python:3.11.4
        ├─ Exact system libraries
        ├─ Exact Python packages
        └─ Reproducible inference

REPRODUCIBILITY ACHIEVED:
✓ Same code (git commit)
✓ Same data (data version, DVC)
✓ Same packages (lock file)
✓ Same environment (Docker)
✓ Same random seed
→ SAME MODEL OUTPUT GUARANTEED
```

---

## Hands-on Scenarios {#hands-on-scenarios}

### Building a Reproducible ML Training Pipeline {#scenario-training-pipeline}

**Scenario**: Build an end-to-end training pipeline that can be:
1. Triggered manually or on schedule
2. Track all experiments
3. Reproduce any past run
4. Deploy approved models

**Solution**: Kubernetes CronJob + MLflow + Git versioning

```yaml
# training-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-model-training
spec:
  schedule: "0 2 * * *"  # Daily at 2am UTC
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trainer
            image: ml-training:latest
            env:
            - name: EXPERIMENT_NAME
              value: "daily-churn-prediction"
            - name: MLFLOW_TRACKING_URI
              value: "http://mlflow-server:5000"
            - name: GIT_COMMIT
              valueFrom:
                fieldRef:
                  fieldPath: metadata.annotations['git.commit']
            volumeMounts:
            - name: data-volume
              mountPath: /data
          volumes:
          - name: data-volume
            persistentVolumeClaim:
              claimName: ml-data-pvc
          restartPolicy: OnFailure
```

---

## Interview Questions {#interview-questions}

### Conceptual Questions {#conceptual-questions}

1. **Explain the difference between training and inference pipelines. Why is the distinction critical in production?**
   - Training: offline, iterative, resource-intensive
   - Inference: online, stateless, latency-critical
   - Different architectures, deployments, and scaling considerations

2. **What is data drift and why does it cause model failures?**
   - Data drift: input distribution changes over time
   - Causes: customer behavior changes, market shifts, seasonal patterns
   - Model trained on outdated patterns; predictions become inaccurate
   - Detection: statistical tests, monitoring prediction confidence

3. **Describe training/serving skew and provide an example of how to prevent it.**
   - Skew: preprocessing differs between training and serving
   - Example: normalize in training, forget to normalize in serving
   - Solution: feature store, containerization, unit tests validating consistency

### Production Scenarios {#production-scenarios}

4. **Your production ML system has been running for 3 months. Suddenly, model accuracy drops from 92% to 78%. What's your diagnosis and resolution process?**
   - Check 1: Data quality - are new incoming features different?
   - Check 2: Model staleness - does model need retraining?
   - Check 3: Training/serving skew - are preprocessing pipelines aligned?
   - Check 4: Business changes - did target definition change?
   - Resolution: Shadow deploy new model, monitor, promote if better

5. **Design a deployment strategy for a critical fraud detection model used by millions of users.**
   - Shadow deployment: run new model, monitor metrics, check for degradation
   - Canary: 1% traffic first 2 hours, 5% for next 4 hours, 100% if stable
   - Automatic rollback: if fraud precision drops below 0.95 or latency > 200ms
   - A/B test: compare against current model quantitatively
   - Continuous monitoring: alert on distribution changes, retraining thresholds

---

**End of MLOps Study Guide Deep Dive Sections**

This comprehensive guide has covered:
- ML & Data Fundamentals (ML lifecycle, supervised/unsupervised learning, training vs inference)
- Python for ML Workflows (virtual environments, dependency management, libraries)
- Data Engineering Basics (ETL vs ELT, batch vs streaming data)
- ML Project Structure & Reproducibility (project templating, environment pinning, experiment tracking)
- Practical code examples for each major section
- ASCII diagrams for architecture visualization
- Production scenarios and interview questions

For further depth on specific technologies (Kubernetes, Feature Stores, Specific ML Frameworks), refer to adjacent study guides in the devops-lookup documentation.
