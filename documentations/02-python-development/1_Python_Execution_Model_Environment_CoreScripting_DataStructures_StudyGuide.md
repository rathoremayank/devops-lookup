# Python Development: Execution Model, Environment & Core Scripting - Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Python Execution Model & Environment](#python-execution-model--environment)
4. [Core Scripting & Data Structures](#core-scripting--data-structures)
5. [Control Flow & Functions](#control-flow--functions)
6. [File Handling & OS Interaction](#file-handling--os-interaction)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Python has become a cornerstone technology in modern DevOps platforms, infrastructure automation, and cloud-native engineering. This study guide covers the essential Python concepts that DevOps engineers must master: how Python code is executed, managing isolated environments, scripting fundamentals, and operating system interaction. These skills form the foundation for tools like Ansible, Kubernetes operators, AWS Lambda functions, and custom monitoring/automation solutions.

For a senior DevOps engineer, understanding Python deeply—beyond syntax—means comprehending execution models, environment isolation, dependency management, and how Python interacts with the underlying operating system. This knowledge is critical for:

- **Building reliable automation frameworks** that scale across infrastructure
- **Debugging production issues** in Kubernetes clusters, serverless environments, and distributed systems
- **Optimizing performance** of Python-based services deployed at scale
- **Securing dependencies** and managing supply chain risks in CI/CD pipelines
- **Contributing to open-source DevOps tools** (Ansible, Pulumi, Terraform providers, etc.)

### Why It Matters in Modern DevOps Platforms

**1. Infrastructure Automation & IaC**
- Ansible playbooks are written in Python
- Custom cloud provisioning scripts leverage Python SDKs (boto3, azure-sdk-for-python)
- Terraform providers and custom controllers rely on Python modules

**2. Kubernetes & Container Orchestration**
- Kubernetes operators are often written in Python (Kopf, Operator SDK)
- Custom admission controllers and webhooks utilize Python frameworks
- Pod lifecycle automation and monitoring scripts depend on Python

**3. Serverless & Event-Driven Architecture**
- AWS Lambda functions, Azure Functions, and Google Cloud Functions widely use Python
- Event processing in systems like Kafka, SQS, and Pub/Sub requires understanding async/await and threading models
- Cost optimization scripts for cloud resources use Python

**4. Observability & Monitoring**
- Custom metric exporters (Prometheus, DataDog agents) are written in Python
- Log processing and correlation scripts depend on efficient file I/O and subprocess management
- System health checks and auto-remediation leverage the subprocess module

**5. CI/CD Pipeline Tools**
- Custom build scripts and pipeline orchestration code
- Container image scanning and vulnerability assessment tools
- Artifact management and release automation use Python SDKs

### Real-World Production Use Cases

| Use Case | Python Component | Key Challenge | DevOps Impact |
|----------|------------------|----------------|---------------|
| **Multi-cloud provisioning** | boto3/azure-sdk + custom scripts | Dependency isolation across projects | Reproducible infrastructure |
| **Kubernetes operator development** | Kopf or Operator SDK | Async event handling + resource state management | Self-managing cloud platforms |
| **Automated CI/CD pipelines** | Jenkins plugins, GitLab runners, custom orchestrators | Subprocess management + error handling | Faster feature deployment |
| **Log aggregation & analysis** | ELK stacks, cloud logging APIs | Efficient file I/O + memory management for high volume | Historical insights, compliance audits |
| **Infrastructure patching automation** | Ansible playbooks + paramiko | SSH connection pooling + error recovery | Reduced CVE exposure window |
| **Kubernetes admission control** | Custom webhooks + FastAPI/Flask | Async request handling + atomic operations | Policy enforcement at cluster boundaries |
| **Cost optimization** | Cloud CLI + custom analytics | Large dataset processing + path handling | Cloud spend reduction (10-30% typical) |
| **Secrets management** | HashiCorp Vault SDK + custom rotations | Safe credential handling + subprocess communication | Reduced credential exposure |

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Cloud Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐          ┌──────────────────┐              │
│  │  CI/CD Pipeline  │          │  Kubernetes      │              │
│  │  (Jenkins, GH)   │          │  Cluster         │              │
│  │  ↓               │          │  ↓               │              │
│  │ Python Scripts   │          │ Operators (Py)   │              │
│  │ (subprocess,     │          │ Webhooks (Py)    │              │
│  │  file I/O)       │          │ Controllers (Py) │              │
│  └──────────────────┘          └──────────────────┘              │
│           ↓                              ↓                        │
│  ┌──────────────────┐          ┌──────────────────┐              │
│  │  Ansible         │          │  Cloud APIs      │              │
│  │  (Python core)   │          │  (boto3, SDK)    │              │
│  │  Playbooks       │          │  (Python)        │              │
│  └──────────────────┘          └──────────────────┘              │
│           ↓                              ↓                        │
│  ┌──────────────────────────────────────────────┐                │
│  │      Infrastructure                          │                │
│  │  (EC2, VMs, Containers, Databases)           │                │
│  └──────────────────────────────────────────────┘                │
│                                                                   │
│  ┌──────────────────┐          ┌──────────────────┐              │
│  │  Observability   │          │  Secrets Mgmt    │              │
│  │  (Prometheus,    │          │  (Vault SDK)     │              │
│  │   Python clients)│          │  (Python)        │              │
│  └──────────────────┘          └──────────────────┘              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

**Interpreter**: A program that executes Python code line-by-line, converting human-readable syntax into bytecode, then machine operations. Python uses CPython (C implementation) by default.

**Virtual Environment (venv)**: An isolated Python environment allowing separate dependency installations per project, preventing version conflicts.

**Package**: A directory containing Python modules and a `setup.py` or `pyproject.toml` file; installable via pip.

**Module**: A single `.py` file containing Python code (variables, functions, classes).

**PYTHONPATH**: Environment variable that tells the interpreter where to search for importable modules and packages.

**Bytecode**: Intermediate representation (`.pyc` files) compiled from source code; faster to execute than raw `.py` files but slower than machine code.

**Global Interpreter Lock (GIL)**: Mechanism in CPython preventing true parallel thread execution, critical for understanding concurrency in Python.

**Shebang** (`#!/usr/bin/env python3`): Special comment in Unix scripts specifying the interpreter to use when executing the file directly.

**Poetry/pip**: Dependency management tools; pip is built-in, Poetry adds lock file and virtual env management.

**pyenv**: Tool managing multiple Python versions on a single system without conflicts.

**Async/Await**: Modern concurrency model allowing non-blocking I/O without thread overhead (event-driven).

### Architecture Fundamentals

#### Python Execution Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    Python Code Execution                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. SOURCE CODE                                                  │
│     └─ example.py (UTF-8 text file)                             │
│                ↓                                                  │
│  2. LEXICAL ANALYSIS                                            │
│     └─ Tokenization: Breaks code into tokens                    │
│     └─ Syntax check: Validates grammar                          │
│                ↓                                                  │
│  3. PARSING                                                      │
│     └─ AST (Abstract Syntax Tree) construction                   │
│     └─ Semantic validation                                       │
│                ↓                                                  │
│  4. COMPILATION                                                  │
│     └─ CPython compiles to bytecode (.pyc)                      │
│     └─ Stored in __pycache__ directory                          │
│                ↓                                                  │
│  5. BYTECODE EXECUTION                                          │
│     └─ Python Virtual Machine (PVM) interprets bytecode         │
│     └─ Frame objects manage execution context                   │
│     └─ Call stack grows/shrinks                                 │
│                ↓                                                  │
│  6. SYSTEM CALLS / I/O                                          │
│     └─ GIL released for I/O operations                          │
│     └─ Threads can run in parallel for I/O                      │
│                ↓                                                  │
│  7. OUTPUT / RETURN VALUE                                       │
│     └─ Result returned to OS / other process                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

#### Memory Model & Object Lifecycle

```
┌─────────────────────────────────────────┐
│         Python Memory Layout             │
├─────────────────────────────────────────┤
│ Stack:                                  │
│ ┌─────────────────┐                     │
│ │ Frame 3         │ (current)           │
│ │ local vars      │                     │
│ ├─────────────────┤                     │
│ │ Frame 2         │ (caller)            │
│ │ local vars      │                     │
│ ├─────────────────┤                     │
│ │ Frame 1 (main)  │                     │
│ └─────────────────┘                     │
│                                          │
│ Heap:                                   │
│ ┌────────────────────────────────────┐ │
│ │ Objects (dicts, lists, lists, etc) │ │
│ │ Reference counts (for GC)          │ │
│ └────────────────────────────────────┘ │
│                                          │
│ GC (Garbage Collector):                │
│ ┌────────────────────────────────────┐ │
│ │ Cycle detection for circular refs  │ │
│ │ Runs on allocation thresholds      │ │
│ └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Reference Counting**: Every Python object maintains a count of references to it. When count reaches zero, memory is freed immediately (with GC handling circular references).

**Object Identity vs Equality**:
- `is`: Checks if two variables reference the same object in memory (identity)
- `==`: Checks if values are equal (equality)

**Mutability Implications**:
- Mutable objects (list, dict, set): Changes affect all references
- Immutable objects (tuple, string, int): Cannot change; new object created
- Critical for avoiding unexpected state mutations in DevOps scripts

### Important DevOps Principles

#### 1. **Idempotency**
A Python script should produce the same result regardless of how many times it runs. This is foundational for:
- Ansible playbooks
- Infrastructure provisioning scripts
- Automated remediation

**Bad**:
```python
def create_user(username):
    subprocess.run(f"useradd {username}")  # Fails if user exists
```

**Good**:
```python
def create_user(username):
    result = subprocess.run(
        ["id", username], 
        capture_output=True
    )
    if result.returncode != 0:
        subprocess.run(["useradd", username])
```

#### 2. **Fail-Fast with Meaningful Errors**
- Use explicit exception handling
- Log context before raising
- Avoid silent failures in automation

```python
def deploy_config(path: str) -> None:
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"Config not found at {path}\n"
            f"Expected location: {os.getcwd()}"
        )
    # Proceed with deployment
```

#### 3. **Dependency Isolation**
- Use virtual environments for every project
- Pin exact versions (not just `package>=1.0`)
- Use lock files (Poetry, pip-compile)
- Scan for CVEs in production images

#### 4. **Observable Execution**
- Structured logging (JSON, which keys, severity levels)
- Emit metrics for monitoring
- Trace async operations
- Log subprocess commands before execution

```python
import logging
import json

logger = logging.getLogger(__name__)
logger.info(
    "Deploy started",
    extra={
        "environment": os.getenv("ENV"),
        "region": "us-east-1",
        "version": __version__
    }
)
```

#### 5. **Graceful Shutdown & Resource Cleanup**
- Use context managers for file handles, connections, locks
- Implement signal handling for SIGTERM
- Ensure subprocess cleanup on exit

#### 6. **Configuration as Code**
- Never hardcode credentials, paths, or endpoints
- Use environment variables, YAML, or Jinja2 templates
- Validate configuration early

### Best Practices

| Practice | Rationale | Example |
|----------|-----------|---------|
| **Always use virtual environments** | Isolates dependencies; prevents conflicts | `python -m venv venv && source venv/bin/activate` |
| **Pin exact versions in production** | Ensures reproducibility and security | `use constraints file or lock files` |
| **Use `subprocess` over `os.system()`** | Better error handling, security (no shell injection) | `subprocess.run(cmd, check=True)` |
| **Prefer pathlib over os.path** | Object-oriented, platform-agnostic, safer | `Path("/etc/config").exists()` |
| **Use context managers** | Automatic resource cleanup (files, connections) | `with open(...) as f:` |
| **Validate inputs early** | Prevents silent failures downstream | Check types, paths, network addresses at entry |
| **Handle signals in long-running processes** | Graceful shutdown, log cleanup | `signal.signal(signal.SIGTERM, handler)` |
| **Use logging, not print()** | Configurable, can be captured by monitoring | `logging.info(msg)` |
| **Prefer async/await over threads** | Avoids GIL contention; handles 1000s of I/O concurrent ops | `async def fetch_api():` |

### Common Misunderstandings

#### ❌ Misunderstanding 1: "Python is slower because it's interpreted"
**Reality**: 
- Python *compiles* to bytecode at import time
- The bytecode is cached in `__pycache__`
- Slowness comes from runtime operations, not interpretation per se
- C extensions (NumPy, cryptography, etc.) run at native speed
- **For DevOps**: Performance rarely matters for short-lived scripts; code clarity matters more

#### ❌ Misunderstanding 2: "Global Interpreter Lock prevents multithreading"
**Reality**:
- GIL only prevents CPU-bound parallelism
- **Threads ARE useful** for I/O-bound operations (network, files)
- **Better alternatives**: `asyncio` for thousands of concurrent I/O, `multiprocessing` for CPU-bound work
- **For DevOps**: Use threads for API calls; use async/await for high-concurrency scenarios

#### ❌ Misunderstanding 3: "Virtual environments are just nice-to-have"
**Reality**:
- **Essential**, not optional
- Prevents dependency hell and version conflicts
- Required for reproducible CI/CD pipelines
- Different projects may need incompatible versions of the same library
- **For DevOps**: Every automation script/tool must have a virtual environment with locked dependencies

#### ❌ Misunderstanding 4: "I don't need to handle exceptions in automation"
**Reality**:
- Unhandled exceptions cause silent failures in background jobs
- Ansible requires explicit error handling
- Kubernetes operators must survive transient errors
- **For DevOps**: Every `subprocess.run()`, `requests.get()`, file operation must have error handling

#### ❌ Misunderstanding 5: "Since Python is dynamic, type hints are optional"
**Reality**:
- Type hints improve code clarity significantly
- Enable static analysis tools (mypy) to catch bugs
- Essential for large codebases and teams
- **For DevOps**: Type hints make automation scripts self-documenting and safer

#### ❌ Misunderstanding 6: "All Python versions are compatible"
**Reality**:
- Python 2 vs 3 has major syntax/library differences
- Even minor versions (3.8 vs 3.11) have breaking changes
- Dependencies often drop support for older versions
- **For DevOps**: Pin Python version in `pyproject.toml` or use `.python-version` (pyenv)

---

## Python Execution Model & Environment

### The Interpreter Workflow

**Step 1: Module Search Path**

When you import a module, Python searches in this order:
1. Built-in modules
2. Directories in `PYTHONPATH` environment variable
3. Installation-dependent defaults (site-packages, dist-packages)
4. Current directory (for relative imports)

**Step 2: Module Compilation**

On first import:
```
source.py → Lexer → Parser → Compiler → bytecode (.pyc) → stored in __pycache__
```

Subsequent imports load from `.pyc` (faster).

**Step 3: Module Execution**

```python
# example.py
print("Module imported", __name__)
x = 10  # Executed on import

def func():
    pass

# Only runs if directly executed, not imported
if __name__ == "__main__":
    print("This is main")
```

When imported: Only prints "Module imported example"
When executed: Prints both

---

### Virtual Environments: venv vs virtualenv

#### venv (Built-in, Python 3.3+)

**Create**:
```bash
python3 -m venv /path/to/venv
source /path/to/venv/bin/activate  # Linux/Mac
# or
/path/to/venv/Scripts/activate  # Windows
```

**Structure**:
```
venv/
├── bin/          # Executables (python, pip, scripts)
├── lib/          # site-packages (installed packages)
├── pyvenv.cfg    # Config file
└── include/      # C headers (if building extensions)
```

**Deactivate**:
```bash
deactivate
```

**Why Use**:
- ✅ Built-in, no extra install
- ✅ Lightweight
- ✅ Perfect for simple projects
- ❌ No lock file by default
- ❌ No version management

#### Poetry (Recommended for DevOps)

**Create Project**:
```bash
poetry new my_project
cd my_project
```

Or initialize existing:
```bash
poetry init
```

**Add Dependencies**:
```bash
poetry add requests==2.28.2
poetry add --group dev pytest
```

**Structure**:
```
my_project/
├── pyproject.toml      # Metadata, dependencies
├── poetry.lock         # Locked versions (commit to git!)
├── my_project/         # Package source
│   └── __init__.py
└── tests/
```

**`pyproject.toml` Example**:
```toml
[tool.poetry]
name = "devops-tool"
version = "1.0.0"
description = "Infrastructure automation"

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.28.0"
pyyaml = "^6.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0"
black = "^23.0"
mypy = "^1.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

**Virtual Environment**:
```bash
poetry install              # Creates venv + installs
poetry run python script.py # Run in venv
poetry shell               # Activate venv
```

**Why Use in DevOps**:
- ✅ Lock file ensures reproducible builds
- ✅ Clear dev vs production dependencies
- ✅ Easy publishing to PyPI
- ✅ Poetry can manage Python versions
- ✅ Integrate with CI/CD easily

---

### pip and Dependency Management

#### Basic Usage

```bash
# Install packages
pip install package_name
pip install "requests>=2.28,<3.0"  # Version constraints
pip install -r requirements.txt

# Show installed packages
pip list
pip show requests

# Create requirements.txt
pip freeze > requirements.txt

# Uninstall
pip uninstall package_name
```

#### requirements.txt Format

```
# Production dependencies
requests==2.28.2
pyyaml>=6.0,<7.0
paramiko~=3.0  # Compatible release (>=3.0, <4.0)

# Git dependencies
git+https://github.com/user/repo.git@v1.0#egg=package

# Local paths
./local-package

# Extras
requests[security]  # Installs with security extras
```

#### CVE Scanning in CI/CD

```bash
# Scan for known vulnerabilities
pip install safety
safety check --file requirements.txt

# Or use pip-audit
pip install pip-audit
pip-audit
```

**In CI/CD**:
```yaml
# GitHub Actions example
- name: Scan for vulnerabilities
  run: |
    pip install safety
    safety check --exit-code
```

---

### Shebang & Direct Execution

**Shebang Line**: First line of script specifying interpreter

```python
#!/usr/bin/env python3
# ^ Tells OS to use 'python3' from PATH

import sys
print(f"Python {sys.version}")
```

**Make Executable**:
```bash
chmod +x script.py
./script.py  # Runs directly (uses shebang)
```

**Why `#!/usr/bin/env python3`** (not `#!/usr/bin/python3`):
- Uses `python3` from `$PATH` (respects virtual environments)
- Works across systems with different Python locations
- Essential for Ansible modules, Kubernetes operators

**Anti-pattern**:
```bash
#!/usr/bin/python3  # Breaks in virtual envs!
```

---

### PYTHONPATH & Module Import Mechanics

**PYTHONPATH**: Colon-separated list of directories Python searches for modules.

```bash
export PYTHONPATH="/opt/custom:/home/user/lib:$PYTHONPATH"
python3 script.py  # Searches PYTHONPATH for imports
```

**Check Current Path**:
```python
import sys
print(sys.path)
# Output:
# ['', '/venv/lib/python3.11/site-packages', ...]
```

**Manipulate at Runtime**:
```python
import sys
sys.path.insert(0, '/opt/custom')  # Add to beginning
import my_custom_module
```

**Best Practice for DevOps Scripts**:
```python
#!/usr/bin/env python3

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lib import helpers  # Now imports from same directory
```

---

### Python Version Management with pyenv

**Why pyenv**:
- Install multiple Python versions simultaneously
- Switch per-project basis
- Avoid system Python conflicts
- Essential for CI/CD pipelines testing multiple versions

**Install pyenv**:
```bash
# macOS
brew install pyenv

# Linux (using installer)
curl https://pyenv.run | bash
```

**Usage**:
```bash
# List available versions
pyenv versions
pyenv install --list | grep "3.11"

# Install specific version
pyenv install 3.11.5
pyenv install 3.10.12

# Set global version
pyenv global 3.11.5

# Set local version (current directory)
cd my_project
pyenv local 3.10.12  # Creates .python-version file

# Verify
python --version
```

**.python-version File**:
```
3.11.5
```

**In CI/CD (`pyenv`  + GitHub Actions)**:
```yaml
- uses: "mciurtain/action-pyenv@v1"
  with:
    version: "3.11.5"
```

or with Tool Configuration File:
```bash
# .github/workflows/CI.yml
- name: Set up Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.11.5'
    cache: 'pip'  # Cache pip dependencies
```

---

### Managing Multiple Python Environments in Production

**Docker Approach** (Recommended):
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENTRYPOINT ["python", "main.py"]
```

**Deploy with specific Python**:
```bash
docker build -t myapp:py311 .
docker run myapp:py311
```

**Kubernetes with pyenv**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: python-job
spec:
  containers:
  - name: app
    image: myrepo/python-app:py311
    env:
    - name: PYTHONUNBUFFERED
      value: "1"  # Real-time logs
```

---

### Environment Variables for Python

| Variable | Purpose | Example |
|----------|---------|---------|
| `PYTHONPATH` | Adds directories to module search path | `PYTHONPATH=/opt/lib python3 script.py` |
| `PYTHONHOME` | Overrides Python installation location | Rarely needed |
| `PYTHONUNBUFFERED` | Flush stdout immediately (crucial for logging) | `export PYTHONUNBUFFERED=1` |
| `PYTHONDONTWRITEBYTECODE` | Skip `.pyc` generation (useful for read-only filesystems) | `export PYTHONDONTWRITEBYTECODE=1` |
| `PYTHONOPTIMIZE` | Optimize (remove asserts, __doc__) | `PYTHONOPTIMIZE=2 python script.py` |
| `PYTHONWARNINGS` | Control warning behavior | `PYTHONWARNINGS=ignore` |
| `PYTHONDEBUG` | Enable debug mode (very verbose) | `export PYTHONDEBUG=1` |

**For DevOps Containers**:
```dockerfile
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
```

---

## Core Scripting & Data Structures

### Built-in Data Structures Overview

```python
# 1. Lists: Ordered, mutable, allow duplicates
list1 = [1, 2, 3, 2]
list1.append(4)  # [1, 2, 3, 2, 4]
list1[0] = 10    # Mutable

# 2. Tuples: Ordered, immutable, allow duplicates
tuple1 = (1, 2, 3)
# tuple1[0] = 10  # TypeError! Immutable
tuple1 + (4, 5)  # Creates new tuple

# 3. Dictionaries: Key-value, mutable, unordered (ordered in 3.7+)
dict1 = {"name": "Alice", "age": 30}
dict1["role"] = "DevOps"  # Mutable
dict1.get("name", "Unknown")  # Safe access

# 4. Sets: Unordered, unique values, mutable
set1 = {1, 2, 3, 2}  # Set removes duplicates → {1, 2, 3}
set1.add(4)
set1.union({4, 5})  # Set operations

# 5. Strings: Ordered, immutable
str1 = "hello"
# str1[0] = "H"  # TypeError! Immutable
str1.upper()  # Creates new string

# 6. Bytes: Ordered, immutable, binary
bytes1 = b"hello"
bytes1.hex()  # '68656c6c6f'
```

### Mutability: Deep Dive

**Mutable Types**: list, dict, set, bytearray, class instances
**Immutable Types**: tuple, string, int, float, frozenset, bytes

**Why Mutability Matters**:
```python
# Gotcha 1: Shared mutable references
default_list = []
def add_item(item, items=default_list):
    items.append(item)

add_item(1)
add_item(2)
# default_list = [1, 2] (shared across calls!)

# Correct:
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)

# Gotcha 2: Mutable dictionary keys (not allowed)
d = {[1, 2]: "value"}  # TypeError! Lists unhashable

# OK:
d = {(1, 2): "value"}  # Tuples
d = {frozenset([1, 2]): "value"}  # Frozenset

# Gotcha 3: Shallow vs deep copies
import copy
list_a = [1, [2, 3]]
list_b = list_a.copy()  # Shallow copy
list_b[1][0] = 99
# list_a[1][0] is also 99! (nested list shared)

list_c = copy.deepcopy(list_a)  # Deep copy
list_c[1][0] = 99
# list_a[1][0] unchanged
```

---

### List Comprehensions & Advanced Iteration

**Basic Comprehension**:
```python
# Traditional
squares = []
for x in range(5):
    squares.append(x ** 2)

# Comprehension
squares = [x ** 2 for x in range(5)]  # [0, 1, 4, 9, 16]
```

**With Condition**:
```python
even_squares = [x ** 2 for x in range(10) if x % 2 == 0]
# [0, 4, 16, 36, 64]
```

**Nested Comprehension**:
```python
# Flatten 2D list
matrix = [[1, 2], [3, 4], [5, 6]]
flat = [val for row in matrix for val in row]
# [1, 2, 3, 4, 5, 6]

# Transpose
transposed = [[row[i] for row in matrix] for i in range(2)]
# [[1, 3, 5], [2, 4, 6]]
```

**Dictionary Comprehension**:
```python
d = {k: v for k, v in zip(["a", "b", "c"], [1, 2, 3])}
# {"a": 1, "b": 2, "c": 3}

# Invert keys/values
original = {"a": 1, "b": 2}
inverted = {v: k for k, v in original.items()}
# {1: "a", 2: "b"}
```

**Set Comprehension**:
```python
unique_lengths = {len(word) for word in ["apple", "app", "apricot"]}
# {3, 5}
```

**Generator Expression** (lazy, memory-efficient):
```python
# List comp: creates entire list in memory
squares_list = [x ** 2 for x in range(1000000)]

# Generator: computes on-demand
squares_gen = (x ** 2 for x in range(1000000))
next(squares_gen)  # 0
next(squares_gen)  # 1

# Useful in DevOps for processing large files:
def process_logs(filepath):
    with open(filepath) as f:
        return (line.strip() for line in f)  # Lazy file iteration

for log_line in process_logs("/var/log/app.log"):
    # Process one line at a time, not entire file in RAM
    handle_log(log_line)
```

---

### Slicing & Unpacking

**Slicing**:
```python
lst = [0, 1, 2, 3, 4, 5]
lst[1:4]      # [1, 2, 3] (indices 1, 2, 3)
lst[:3]       # [0, 1, 2] (from start to 3)
lst[2:]       # [2, 3, 4, 5] (from 2 to end)
lst[::2]      # [0, 2, 4] (every 2nd element)
lst[::-1]     # [5, 4, 3, 2, 1, 0] (reversed)
lst[-2:]      # [4, 5] (last 2 elements)

# Strings (immutable, same slicing)
s = "hello"
s[1:4]        # "ell"
s[::-1]       # "olleh" (reversed)
```

**Unpacking**:
```python
# Basic unpacking
a, b, c = [1, 2, 3]

# With *rest
first, *middle, last = [1, 2, 3, 4, 5]
# first=1, middle=[2, 3, 4], last=5

# Swapping
x, y = y, x

# From function returns
def get_config():
    return "host", 8000, True

host, port, debug = get_config()

# Ignoring values
a, _, c = [1, 2, 3]  # Ignores 2

# Nested unpacking
(x, y), z = ([1, 2], 3)

# Unpacking with iterator
list(zip("abc", [1, 2, 3]))  # [('a', 1), ('b', 2), ('c', 3)]
keys, values = zip(*[("a", 1), ("b", 2)])
# keys = ('a', 'b'), values = (1, 2)
```

---

### Standard Library Modules for DevOps

#### os & sys

```python
import os
import sys

# Check environment
os.environ.get("HOME")
os.environ.get("DB_PASSWORD", "default")  # With default

# File/directory operations
os.path.exists("/etc/passwd")
os.path.isdir("/opt")
os.listdir("/var/log")

# Working directory
os.getcwd()
os.chdir("/tmp")

# Create directories
os.makedirs("/opt/app/logs", exist_ok=True)

# Remove files
os.remove("file.txt")
os.rmdir("empty_dir")
shutil.rmtree("dir_with_contents")  # Recursive delete

# Execute command (legacy, avoid)
os.system("ls -la")  # Don't use! No error handling

import sys
sys.version
sys.python_version_info  # (3, 11, 5, 'final', 0)
sys.platform  # "linux"
sys.argv  # Command-line arguments

# Exit with code
sys.exit(0)  # Success
sys.exit(1)  # Error
```

#### subprocess (Run External Commands)

**Basic Usage**:
```python
import subprocess

# Run command, wait for completion
result = subprocess.run(
    ["ls", "-la", "/tmp"],
    check=True,           # Raise exception on non-zero exit
    capture_output=True,  # Capture stdout/stderr
    text=True             # Return strings, not bytes
)
print(result.stdout)
print(result.returncode)  # 0 = success
```

**Handling Errors**:
```python
try:
    subprocess.run(
        ["kubectl", "apply", "-f", "invalid.yaml"],
        check=True,
        capture_output=True,
        text=True
    )
except subprocess.CalledProcessError as e:
    print(f"Failed with code {e.returncode}")
    print(f"Error: {e.stderr}")
```

**Piping Data**:
```python
# Chain: grep -> wc
result = subprocess.run(
    "cat /var/log/syslog | grep ERROR | wc -l",
    shell=True,  # Use shell for pipes (less safe)
    capture_output=True,
    text=True
)

# Better: Use pipes properly
p1 = subprocess.Popen(
    ["cat", "/var/log/syslog"],
    stdout=subprocess.PIPE
)
p2 = subprocess.Popen(
    ["grep", "ERROR"],
    stdin=p1.stdout,
    stdout=subprocess.PIPE
)
output, _ = p2.communicate()
```

**Streaming Output** (long-running commands):
```python
process = subprocess.Popen(
    ["docker", "build", "."],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

for line in process.stdout:
    print(line.rstrip())  # Real-time output

process.wait()
if process.returncode != 0:
    print("Build failed!")
```

**Timeouts**:
```python
try:
    subprocess.run(
        ["long_running_command"],
        timeout=30,  # Kill after 30 seconds
        check=True
    )
except subprocess.TimeoutExpired:
    print("Command timed out")
```

#### pathlib (Modern Path Handling)

```python
from pathlib import Path

# Create paths (platform-agnostic)
p = Path("/etc/config") / "app.yaml"  # Works on Windows too!
p = Path.home() / ".config"  # User home

# Check existence
if p.exists():
    if p.is_file():
        content = p.read_text()
    elif p.is_dir():
        files = list(p.glob("*.py"))  # All .py files

# Write/read
p.write_text("config content")
data = p.read_text()

# Parent/stem/suffix
p.parent   # Path("/etc")
p.stem     # "app"
p.suffix   # ".yaml"
p.name     # "app.yaml"

# Absolute path
p.resolve()

# Glob patterns
config_dir = Path("/etc/config")
all_yaml = list(config_dir.glob("**/*.yaml"))  # Recursive

# Relative paths
p.relative_to(Path("/etc"))  # Path("config/app.yaml")
```

---

### Lambda Functions & Functional Programming

**Lambda**: Anonymous function for simple operations

```python
# Basic lambda
square = lambda x: x ** 2
square(5)  # 25

# With multiple args
add = lambda x, y: x + y
add(3, 4)  # 7

# In higher-order functions
numbers = [1, 2, 3, 4, 5]
squares = list(map(lambda x: x ** 2, numbers))
# [1, 4, 9, 16, 25]

# Filter
evens = list(filter(lambda x: x % 2 == 0, numbers))
# [2, 4]

# Sort by key
people = [
    {"name": "Alice", "age": 30},
    {"name": "Bob", "age": 25}
]
sorted_people = sorted(people, key=lambda p: p["age"])
```

**When to Use Lambda**:
- ✅ Simple, one-line operations
- ✅ As argument to `map()`, `filter()`, `sorted()`
- ❌ Complex logic (use `def` instead)
- ❌ Multiple lines
- ❌ When debugging (no function name in traceback)

**Why DevOps Engineers Use Them**:
```python
# Example: Sort Kubernetes events by timestamp
events = load_k8s_events()
recent = sorted(events, key=lambda e: e["timestamp"], reverse=True)

# Example: Filter warnings from logs
logs = load_logs()
warnings = list(filter(lambda log: log["level"] == "WARNING", logs))

# Example: Transform config data
configs = load_yaml_configs()
names = list(map(lambda c: c["name"], configs))
```

---

## Control Flow & Functions

### Conditionals: if/elif/else

```python
# Simple
if age >= 18:
    print("Adult")

# With else
if status == "running":
    print("Active")
else:
    print("Inactive")

# Multiple conditions
if environment == "prod" and replicas > 1:
    print("Production deployment")
elif environment == "staging":
    print("Staging deployment")
else:
    print("Development")

# Boolean operators
if not error_occurred and retry_count < 3:
    retry()

# Ternary
result = "success" if status == 0 else "failed"

# Guard clause (early return)
def deploy(config):
    if not config:
        raise ValueError("Config required")
    if not os.path.exists(config):
        raise FileNotFoundError(config)
    # Main logic here
    apply_config(config)
```

### Loops: for and while

**For Loops**:
```python
# Iterate over list
for item in [1, 2, 3]:
    print(item)

# With index
for idx, item in enumerate([10, 20, 30]):
    print(f"{idx}: {item}")  # 0: 10, 1: 20, ...

# Iterate over dict
config = {"host": "localhost", "port": 8000}
for key, value in config.items():
    print(f"{key}={value}")

# Range
for i in range(5):  # 0, 1, 2, 3, 4
    print(i)

# Zip multiple iterables
names = ["Alice", "Bob"]
ages = [30, 25]
for name, age in zip(names, ages):
    print(f"{name} is {age}")

# Break and continue
for i in range(10):
    if i == 3:
        continue  # Skip this iteration
    if i == 7:
        break     # Exit loop
    print(i)
```

**While Loops**:
```python
retry_count = 0
while retry_count < 3:
    try:
        connect_to_api()
        break  # Success, exit loop
    except ConnectionError:
        retry_count += 1
        if retry_count >= 3:
            raise
        time.sleep(2 ** retry_count)  # Exponential backoff
```

### Exception Handling

**Basic Try-Except**:
```python
try:
    result = load_config("config.yaml")
except FileNotFoundError as e:
    logger.error(f"Config not found: {e}")
    result = DEFAULT_CONFIG
except yaml.YAMLError as e:
    logger.error(f"Invalid YAML: {e}")
    sys.exit(1)
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    sys.exit(1)
finally:
    # Always runs, for cleanup
    logger.info("Config loading attempt completed")
```

**Custom Exceptions**:
```python
class DeploymentError(Exception):
    """Raised when deployment fails"""
    pass

class ConfigurationError(DeploymentError):
    """Raised when config is invalid"""
    pass

def validate_config(config):
    if "name" not in config:
        raise ConfigurationError("Missing 'name' field")
    if not os.path.exists(config["path"]):
        raise ConfigurationError(f"Path not found: {config['path']}")

def deploy(config_file):
    try:
        config = load_yaml(config_file)
        validate_config(config)
        apply_deployment(config)
    except ConfigurationError as e:
        logger.error(f"Invalid config: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Deployment failed: {e}", exc_info=True)
        sys.exit(1)
```

### Function Definition & Arguments

**Basic Function**:
```python
def greet(name):
    return f"Hello, {name}"

greet("Alice")  # "Hello, Alice"
```

**Default Parameters**:
```python
def connect(host="localhost", port=5432):
    return f"Connecting to {host}:{port}"

connect()                 # localhost:5432
connect("prod.example")   # prod.example:5432
connect(port=3306)        # localhost:3306
```

***args (Variable Positional Arguments)**:
```python
def run_commands(*commands):
    for cmd in commands:
        print(f"Running: {cmd}")

run_commands("ls", "pwd", "whoami")
```

****kwargs (Variable Keyword Arguments)**:
```python
def create_pod(name, **metadata):
    pod_spec = {
        "name": name,
        **metadata  # Unpack kwargs
    }
    return pod_spec

pod = create_pod(
    "my-pod",
    namespace="default",
    labels={"app": "backend"},
    cpu_limit="500m"
)
```

**Combining All**:
```python
def execute_task(task_id, *args, workspace="/tmp", **kwargs):
    print(f"Task ID: {task_id}")
    print(f"Args: {args}")
    print(f"Workspace: {workspace}")
    print(f"Kwargs: {kwargs}")

execute_task(
    123,
    "arg1",
    "arg2",
    workspace="/opt",
    retry=3,
    timeout=60
)
```

**Type Hints** (highly recommended):
```python
from typing import Optional, List, Dict

def deploy(
    config_file: str,
    environment: str = "staging",
    dry_run: bool = False
) -> Dict[str, str]:
    """Deploy application.
    
    Args:
        config_file: Path to YAML config
        environment: Target environment
        dry_run: Don't apply changes
    
    Returns:
        Deployment result with status and message
    """
    # Implementation
    return {"status": "success", "id": "deploy-123"}
```

### Recursion

```python
# Factorial
def factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)

# File tree traversal
def list_files(directory):
    for entry in os.listdir(directory):
        path = os.path.join(directory, entry)
        if os.path.isdir(path):
            print(f"DIR: {path}")
            list_files(path)  # Recursive
        else:
            print(f"FILE: {path}")

# JSON deep access
def get_nested_value(data, keys):
    if not keys:
        return data
    key = keys[0]
    if isinstance(data, dict):
        return get_nested_value(data[key], keys[1:])
    raise KeyError(f"Key not found: {key}")

value = get_nested_value(
    {"a": {"b": {"c": 42}}},
    ["a", "b", "c"]
)  # 42
```

### Decorators

A decorator modifies a function's behavior without changing its defining it.

**Simple Decorator**:
```python
import functools
import time

def timer(func):
    @functools.wraps(func)  # Preserve metadata
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start
        print(f"{func.__name__} took {duration:.2f}s")
        return result
    return wrapper

@timer
def slow_operation():
    time.sleep(2)
    return "Done"

slow_operation()  # Prints: slow_operation took 2.00s
```

**Decorator with Arguments**:
```python
def retry(max_attempts=3, backoff=2):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt >= max_attempts:
                        raise
                    wait_time = backoff ** (attempt - 1)
                    print(f"Attempt {attempt} failed. Retry in {wait_time}s...")
                    time.sleep(wait_time)
        return wrapper
    return decorator

@retry(max_attempts=4, backoff=2)
def call_api():
    # Will retry up to 4 times with exponential backoff
    return requests.get("https://api.example.com/data")

call_api()
```

### Context Managers

Context managers ensure setup and teardown operations (file handles, database connections, locks).

**Manual try/finally**:
```python
f = open("file.txt")
try:
    content = f.read()
finally:
    f.close()
```

**With Context Manager**:
```python
with open("file.txt") as f:
    content = f.read()
# File automatically closed
```

**Custom Context Manager**:
```python
class DatabaseConnection:
    def __init__(self, host):
        self.host = host
        self.conn = None
    
    def __enter__(self):
        print(f"Connecting to {self.host}")
        self.conn = connect(self.host)
        return self.conn
    
    def __exit__(self, exc_type, exc_val, traceback):
        if self.conn:
            print(f"Closing connection")
            self.conn.close()
        if exc_type:
            print(f"Exception occurred: {exc_val}")

# Usage
with DatabaseConnection("prod.db.example.com") as db:
    data = db.query("SELECT * FROM users")
# Automatically closes
```

**Using contextlib**:
```python
from contextlib import contextmanager

@contextmanager
def kubernetes_context(namespace):
    original = get_current_namespace()
    set_namespace(namespace)
    try:
        yield
    finally:
        set_namespace(original)

with kubernetes_context("custom-ns"):
    apply_deployment("app.yaml")  # Runs in custom-ns
# Returns to original namespace
```

### Generators & yield

A generator is a function that yields values one at a time (lazy evaluation).

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1

for count in countdown(3):
    print(count)  # 3, 2, 1

# Generator expression (memory-efficient)
gen = (x ** 2 for x in range(1000000))
next(gen)  # 0
next(gen)  # 1
```

**Reading Large Files**:
```python
def read_large_file(path):
    with open(path) as f:
        for line in f:
            yield line.rstrip()

# Process 10GB log file without loading into RAM
for log_line in read_large_file("/var/log/huge.log"):
    process_log(log_line)
```

**Generator with Iteration Protocol**:
```python
def fibonacci(limit):
    a, b = 0, 1
    while a < limit:
        yield a
        a, b = b, a + b

list(fibonacci(100))  # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
```

### Async/Await (Asynchronous Programming)

**Problem**: I/O blocking in traditional code

```python
# Synchronous (blocks)
def fetch_urls(urls):
    results = []
    for url in urls:
        response = requests.get(url)  # Blocks for 1-2 seconds each
        results.append(response.text)
    return results

# 100 URLs = 100-200 seconds!
```

**Solution**: Asynchronous with async/await

```python
import asyncio
import aiohttp

async def fetch_url(session, url):
    async with session.get(url) as response:
        return await response.text()

async def fetch_all_urls(urls):
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        return await asyncio.gather(*tasks)

# Run async function
results = asyncio.run(fetch_all_urls(urls))
# 100 URLs = ~2 seconds (concurrent!)
```

**Async Context Managers**:
```python
async def api_request(endpoint):
    async with api_client.create_session() as session:
        async with session.get(endpoint) as response:
            return await response.json()
```

**Key Differences**:
- `async def`: Defines async function
- `await`: Pauses function, releases event loop
- `asyncio.gather()`: Run multiple coroutines concurrently
- `asyncio.run()`: Entry point for async code

**When to Use Async in DevOps**:
- ✅ API calls (slow, network I/O)
- ✅ Database queries
- ✅ File operations
- ✅ High-concurrency systems (1000+ connections)
- ❌ CPU-bound operations (use `multiprocessing`)
- ❌ Simple scripts (overhead not worth it)

---

## File Handling & OS Interaction

### Reading & Writing Files

**Basic Read**:
```python
# Read entire file
with open("config.yaml") as f:
    content = f.read()

# Read line by line
with open("config.yaml") as f:
    for line in f:
        process_line(line.rstrip())

# Read all lines into list
with open("config.yaml") as f:
    lines = f.readlines()  # ['line1\n', 'line2\n', ...]
```

**Write**:
```python
# Write/overwrite
with open("output.txt", "w") as f:
    f.write("Hello\n")
    f.write("World\n")

# Append
with open("output.txt", "a") as f:
    f.write("Additional line\n")

# Binary write
with open("data.bin", "wb") as f:
    f.write(b"\x00\x01\x02")
```

**File Modes**:
| Mode | Purpose | Creates? | Truncates? |
|------|---------|----------|-----------|
| `r` | Read | No | No |
| `w` | Write | Yes | Yes |
| `a` | Append | Yes | No |
| `r+` | Read + Write | No | No |
| `w+` | Write + Read | Yes | Yes |
| `b` | Binary (add to others) | — | — |

### Working with Paths: os.path vs pathlib

**os.path** (older):
```python
import os

# Join paths
path = os.path.join("/etc", "config", "app.yaml")

# Check existence
os.path.exists(path)
os.path.isfile(path)
os.path.isdir(path)

# Get parts
os.path.dirname(path)   # "/etc/config"
os.path.basename(path)  # "app.yaml"
os.path.splitext(path)  # ("/etc/config/app", ".yaml")

# List directory
for filename in os.listdir("/var/log"):
    filepath = os.path.join("/var/log", filename)
    if os.path.isfile(filepath):
        print(filename)
```

**pathlib** (modern, recommended):
```python
from pathlib import Path

# Create path
path = Path("/etc/config/app.yaml")

# Check existence
path.exists()
path.is_file()
path.is_dir()

# Get parts
path.parent      # Path("/etc/config")
path.name        # "app.yaml"
path.stem        # "app"
path.suffix      # ".yaml"

# Reading/writing
content = path.read_text()
path.write_text("new content")

# Glob
config_dir = Path("/etc/config")
all_configs = list(config_dir.glob("*.yaml"))
all_nested = list(config_dir.glob("**/*.yaml"))  # Recursive

# Relative paths
rel = path.relative_to(Path("/etc"))  # Path("config/app.yaml")

# Resolve to absolute
absolute = path.resolve()
```

**pathlib Advantages**:
- ✅ Object-oriented
- ✅ Platform-agnostic (works on Windows & Unix)
- ✅ Cleaner syntax
- ✅ Type hints support

---

### Parsing JSON, YAML, and CSV

**JSON**:
```python
import json

# Parse JSON string
data = json.loads('{"name": "Alice", "age": 30}')
data["name"]  # "Alice"

# Parse JSON file
with open("config.json") as f:
    config = json.load(f)

# Write JSON
with open("output.json", "w") as f:
    json.dump(config, f, indent=2)

# Pretty-print
print(json.dumps(config, indent=2, sort_keys=True))
```

**YAML** (requires `pip install pyyaml`):
```python
import yaml

# Parse YAML
with open("deployment.yaml") as f:
    manifest = yaml.safe_load(f)  # Always use safe_load!

# Write YAML
with open("output.yaml", "w") as f:
    yaml.dump(manifest, f, default_flow_style=False)

# Safe vs unsafe
yaml.safe_load(yaml_string)   # ✅ Safe, only standard types
yaml.load(yaml_string, Loader=yaml.FullLoader)  # Potentially unsafe
```

**CSV**:
```python
import csv

# Read CSV
with open("data.csv") as f:
    reader = csv.DictReader(f)  # As dicts
    for row in reader:
        print(row["name"], row["age"])

# Write CSV
with open("output.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "age"])
    writer.writeheader()
    writer.writerow({"name": "Alice", "age": 30})
```

### Temporary Files & Directories

```python
import tempfile

# Temporary file (auto-deleted on close)
with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
    f.write("temporary data")
    temp_path = f.name

# Later
os.remove(temp_path)

# Temporary directory
with tempfile.TemporaryDirectory() as tmpdir:
    temp_file = os.path.join(tmpdir, "file.txt")
    # Use tmpdir
# Auto-deleted

# For Kubernetes/Docker contexts
import shutil
shutil.copy("source.yaml", "/tmp/dest.yaml")  # Copy file
shutil.copytree("src_dir", "/tmp/dest_dir")   # Copy directory
shutil.rmtree("/tmp/dest_dir")                # Remove directory
```

### Environment Variables

```python
import os

# Read
db_password = os.environ.get("DB_PASSWORD")
db_password = os.getenv("DB_PASSWORD", "default_pw")  # With default

# Set (only affects current process)
os.environ["APP_ENV"] = "production"

# Check if set
if "CI" in os.environ:
    print("Running in CI")

# Iterate all variables
for key, value in os.environ.items():
    print(f"{key}={value}")
```

**Example: Database Connection from Env**:
```python
import os
import psycopg2

conn = psycopg2.connect(
    host=os.getenv("DB_HOST", "localhost"),
    port=os.getenv("DB_PORT", "5432"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME")
)
```

### Subprocess for Shell Commands

**Simple Execution**:
```python
import subprocess

result = subprocess.run(
    ["kubectl", "get", "pods", "-n", "default"],
    check=True,
    capture_output=True,
    text=True
)

print(result.stdout)    # Output
print(result.returncode)  # 0 = success
```

**Handling Errors**:
```python
try:
    subprocess.run(["invalid-command"], check=True)
except subprocess.CalledProcessError as e:
    print(f"Failed with code {e.returncode}")
```

**Streaming Output** (for long commands):
```python
process = subprocess.Popen(
    ["docker", "build", "."],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1  # Line-buffered
)

for line in process.stdout:
    print(line.rstrip())

if process.wait() != 0:
    print("Build failed")
```

**Environment Variables in Subprocess**:
```python
import subprocess
import os

env = os.environ.copy()
env["KUBECONFIG"] = "/path/to/kubeconfig"

subprocess.run(
    ["kubectl", "get", "pods"],
    env=env,
    check=True
)
```

### System Processes

**Get List of Processes**:
```python
import subprocess

result = subprocess.run(
    ["ps", "aux"],
    capture_output=True,
    text=True
)

for line in result.stdout.split("\n"):
    if "python" in line:
        print(line)
```

**Send Signals to Processes**:
```python
import os
import signal

pid = 1234
os.kill(pid, signal.SIGTERM)   # Graceful shutdown
os.kill(pid, signal.SIGKILL)   # Force kill

# Graceful shutdown of self
def shutdown_handler(signum, frame):
    print("Shutting down...")
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
```

**Process Information with psutil**:
```python
import psutil

# CPU usage
print(psutil.cpu_percent())  # 45.3

# Memory usage
mem = psutil.virtual_memory()
print(f"Used: {mem.used / 1024**3:.2f} GB")

# Disk usage
disk = psutil.disk_usage("/")
print(f"Free: {disk.free / 1024**3:.2f} GB")

# Network
net = psutil.net_io_counters()
print(f"Bytes sent: {net.bytes_sent}")

# Running processes
for proc in psutil.process_iter(['pid', 'name']):
    if "python" in proc.info['name']:
        print(proc.info)
```

### Handling Permissions

```python
import os
import stat

# Check permissions
file_stat = os.stat("script.py")
mode = file_stat.st_mode

if mode & stat.S_IXUSR:
    print("Owner can execute")

# Change permissions
os.chmod("script.py", 0o755)  # rwxr-xr-x

# Get/set file ownership (requires root)
os.chown("file.txt", uid=1000, gid=1000)
```

### Logging Best Practices

**Basic Setup**:
```python
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.critical("Critical message")
```

**Structured Logging** (for DevOps/SRE):
```python
import logging
import json
import sys

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "line": record.lineno
        }
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_data)

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JSONFormatter())
logger = logging.getLogger("app")
logger.addHandler(handler)

logger.info("App started", extra={"environment": "prod"})
```

**Logging from Subprocesses**:
```python
import logging
import subprocess

logger = logging.getLogger(__name__)

process = subprocess.Popen(
    ["docker", "build", "."],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

for line in process.stdout:
    logger.info(f"Docker: {line.rstrip()}")

for line in process.stderr:
    logger.error(f"Docker Error: {line.rstrip()}")

process.wait()
```

---

## Hands-on Scenarios

### Scenario 1: Multi-Cloud Infrastructure Inventory Script

Create a Python script to inventory resources across AWS and Azure.

```python
#!/usr/bin/env python3
"""
Infrastructure inventory tool for multi-cloud environments.
Queries AWS (boto3) and Azure (azure-sdk) for resource counts.
"""

import json
import logging
from typing import Dict
from pathlib import Path
import boto3
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_aws_inventory(region: str) -> Dict:
    """Get AWS resource counts."""
    ec2 = boto3.client("ec2", region_name=region)
    
    try:
        instances = ec2.describe_instances()
        count = sum(
            len(res["Instances"])
            for res in instances["Reservations"]
        )
        logger.info(f"AWS: Found {count} EC2 instances in {region}")
        return {"region": region, "ec2_instances": count}
    except Exception as e:
        logger.error(f"Failed to query AWS: {e}")
        return {"region": region, "error": str(e)}

def get_azure_inventory(subscription_id: str) -> Dict:
    """Get Azure resource counts."""
    try:
        credential = DefaultAzureCredential()
        client = ResourceManagementClient(credential, subscription_id)
        
        resources = list(client.resources.list())
        logger.info(f"Azure: Found {len(resources)} resources")
        
        by_type = {}
        for resource in resources:
            rtype = resource.type
            by_type[rtype] = by_type.get(rtype, 0) + 1
        
        return {"subscription": subscription_id, "resources_by_type": by_type}
    except Exception as e:
        logger.error(f"Failed to query Azure: {e}")
        return {"subscription": subscription_id, "error": str(e)}

def main():
    inventory = {
        "aws": get_aws_inventory("us-east-1"),
        "azure": get_azure_inventory("YOUR-SUBSCRIPTION-ID")
    }
    
    # Write report
    report_path = Path("/tmp/inventory.json")
    report_path.write_text(json.dumps(inventory, indent=2))
    logger.info(f"Inventory saved to {report_path}")

if __name__ == "__main__":
    main()
```

### Scenario 2: Kubernetes Namespace Cleanup Automation

Automated detection and cleanup of unused Kubernetes namespaces.

```python
#!/usr/bin/env python3
"""
Kubernetes namespace cleanup tool.
Identifies and archives unused namespaces.
"""

import subprocess
import json
import logging
import sys
from pathlib import Path
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def get_namespaces() -> list:
    """Get all Kubernetes namespaces."""
    result = subprocess.run(
        ["kubectl", "get", "namespaces", "-o", "json"],
        capture_output=True,
        text=True,
        check=True
    )
    data = json.loads(result.stdout)
    return [ns["metadata"]["name"] for ns in data["items"]]

def get_pod_count(namespace: str) -> int:
    """Get pod count in namespace."""
    result = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace, "-o", "json"],
        capture_output=True,
        text=True,
        check=True
    )
    data = json.loads(result.stdout)
    return len(data["items"])

def cleanup_namespace(namespace: str, archive_dir: Path) -> bool:
    """Archive namespace YAML and delete it."""
    try:
        # Export namespace YAML
        result = subprocess.run(
            ["kubectl", "get", "all", "-n", namespace, "-o", "yaml"],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Archive
        timestamp = datetime.now().isoformat()
        archive_file = archive_dir / f"{namespace}_{timestamp}.yaml"
        archive_file.write_text(result.stdout)
        logger.info(f"Archived {namespace} to {archive_file}")
        
        # Delete namespace
        subprocess.run(
            ["kubectl", "delete", "namespace", namespace],
            check=True,
            capture_output=True
        )
        logger.info(f"Deleted namespace: {namespace}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to cleanup {namespace}: {e}")
        return False

def main():
    archive_dir = Path("/opt/k8s-archives")
    archive_dir.mkdir(exist_ok=True)
    
    cutoff_date = datetime.now() - timedelta(days=30)
    namespaces = get_namespaces()
    
    for ns in namespaces:
        if ns in ["default", "kube-system", "kube-node-lease", "kube-public"]:
            continue
        
        pod_count = get_pod_count(ns)
        if pod_count == 0:
            logger.info(f"Namespace {ns} is empty. Cleaning up...")
            cleanup_namespace(ns, archive_dir)

if __name__ == "__main__":
    main()
```

### Scenario 3: Configuration Validator with Error Context

Validate infrastructure configuration and provide detailed error reports.

```python
#!/usr/bin/env python3
"""
Configuration validator for IaC deployments.
Validates YAML/JSON configs against schema and best practices.
"""

import json
import logging
import sys
from pathlib import Path
from typing import List, Tuple
import yaml

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

REQUIRED_FIELDS = ["name", "environment", "region"]
VALID_ENVIRONMENTS = ["dev", "staging", "prod"]
VALID_REGIONS = ["us-east-1", "us-west-2", "eu-west-1"]

def load_config(path: str) -> dict:
    """Load config file (YAML or JSON)."""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"Config not found: {path}")
    
    try:
        if p.suffix in [".yaml", ".yml"]:
            return yaml.safe_load(p.read_text())
        elif p.suffix == ".json":
            return json.loads(p.read_text())
        else:
            raise ValueError(f"Unsupported format: {p.suffix}")
    except Exception as e:
        raise ValueError(f"Failed to parse {path}: {e}")

def validate_config(config: dict) -> Tuple[bool, List[str]]:
    """Validate config and return (is_valid, error_messages)."""
    errors = []
    
    # Check required fields
    for field in REQUIRED_FIELDS:
        if field not in config:
            errors.append(f"Missing required field: '{field}'")
    
    # Validate field values
    if "environment" in config:
        if config["environment"] not in VALID_ENVIRONMENTS:
            errors.append(
                f"Invalid environment: '{config['environment']}'. "
                f"Must be one of {VALID_ENVIRONMENTS}"
            )
    
    if "region" in config:
        if config["region"] not in VALID_REGIONS:
            errors.append(
                f"Invalid region: '{config['region']}'. "
                f"Must be one of {VALID_REGIONS}"
            )
    
    # Check resource limits
    if "replicas" in config:
        if not isinstance(config["replicas"], int) or config["replicas"] < 1:
            errors.append("'replicas' must be a positive integer")
    
    return len(errors) == 0, errors

def main():
    if len(sys.argv) < 2:
        print("Usage: python validator.py <config_file>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    
    try:
        config = load_config(config_file)
        is_valid, errors = validate_config(config)
        
        if is_valid:
            logger.info(f"✓ {config_file} is valid")
            sys.exit(0)
        else:
            logger.error(f"✗ {config_file} has errors:")
            for error in errors:
                logger.error(f"  - {error}")
            sys.exit(1)
    except Exception as e:
        logger.error(f"Failed to validate {config_file}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

---

## Interview Questions

### Foundational (Easy)

**1. Explain the difference between a list and a tuple in Python.**

**Answer**: 
- Lists are mutable (can be changed after creation); tuples are immutable
- Lists use `[]`, tuples use `()`
- Tuples are hashable (can be dict keys); lists cannot
- Tuples are slightly faster and use less memory
- When you don't want data to change, use tuples (coordinates, constants)

**2. What does `if __name__ == "__main__"` do?**

**Answer**: 
- Checks if the script is being run directly (not imported)
- Allows code to act as both module and executable script
- Module code runs on import; main code only when executed directly

**3. How do you create a virtual environment and activate it?**

**Answer**:
```bash
python -m venv /path/to/venv
source /path/to/venv/bin/activate  # Linux/Mac
# or
/path/to/venv/Scripts/activate  # Windows
```

**4. What's the difference between `==` and `is` in Python?**

**Answer**:
- `==` checks value equality
- `is` checks if two variables reference the same object in memory
- `a == b` asks "do they have the same value?"
- `a is b` asks "are they the same object?"

**5. Explain `*args` and `**kwargs`.**

**Answer**:
- `*args`: Allows function to accept variable number of positional arguments (as tuple)
- `**kwargs`: Allows function to accept variable number of keyword arguments (as dict)
- Example: `def func(*args, **kwargs)` can accept any combination of args

---

### Intermediate (Medium)

**6. What is a virtual environment and why is it important for DevOps?**

**Answer**:
- Isolated Python environment for each project
- Prevents dependency version conflicts
- Ensures reproducible deployments
- Essential for CI/CD pipelines
- Every project should have its own venv with locked dependencies

**7. How does Python's Global Interpreter Lock (GIL) affect threading?**

**Answer**:
- GIL prevents true parallel execution of Python bytecode in CPython
- Only one thread can execute Python code at a time
- **However**, threads ARE useful for I/O-bound operations (network, files) because GIL is released during I/O
- For CPU-bound work, use `multiprocessing` instead of threads
- For high-concurrency I/O, use `asyncio` instead of threads

**8. Explain the difference between `subprocess.run()` and `os.system()`.**

**Answer**:
- `os.system()`: Old/unsafe; runs command in shell; no error handling; vulnerable to injection
- `subprocess.run()`: Modern/safe; doesn't use shell by default; better error handling; can capture output
- Always use `subprocess.run()` for DevOps scripts

**9. What's the difference between `json.load()` and `json.loads()`?**

**Answer**:
- `json.load()`: Reads from a file object
- `json.loads()`: Parses a JSON string
- "load" = from file; "loads" = loads string

**10. How do you handle exceptions in Python, and why is this important for automation?**

**Answer**:
- Use try/except/finally blocks
- Critical for automation because unhandled exceptions cause silent failures
- Especially important in Kubernetes operators, Ansible playbooks, scheduled jobs
- Example:
```python
try:
    deploy()
except FileNotFoundError as e:
    logger.error(f"Config not found: {e}")
    sys.exit(1)
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    sys.exit(1)
finally:
    cleanup()
```

---

### Advanced (Hard)

**11. Explain Python's memory model and garbage collection.**

**Answer**:
- Objects stored on heap
- Local variables stored on stack (reference to heap objects)
- Python uses reference counting for most cleanup
- When reference count reaches zero, memory is freed
- **Circular references**: Objects referencing each other even when not used
- Cycle detector (GC) runs periodically to find and break cycles
- GC triggers: allocation thresholds, explicit `gc.collect()`
- For DevOps: Understanding reference cycles helps avoid memory leaks in long-running services

**12. What are decorators, and how would you use them in DevOps automation?**

**Answer**:
- Functions that modify other functions without changing their definition
- Common use cases:
  - **@retry**: Retry failed operations (API calls, deployments)
  - **@timeout**: Enforce time limits
  - **@logging**: Add logging to functions
  - **@validate**: Validate inputs before execution
- Example:
```python
@retry(max_attempts=3, backoff=2)
def deploy_helm_chart(chart, namespace):
    # Auto-retries on failure with exponential backoff
    pass
```

**13. Explain context managers and provide a DevOps use case.**

**Answer**:
- Objects that manage resource setup/teardown (using `with` statement)
- Implement `__enter__()` (setup) and `__exit__()` (cleanup)
- Guaranteed cleanup even if exception occurs
- DevOps use cases:
  - File handles (auto-close)
  - Database connections (auto-disconnect)
  - Kubernetes context switching (restore original namespace)
  - Temporary directories (auto-delete)

**14. How does async/await improve performance, and when should you use it?**

**Answer**:
- Traditional threading has overhead; GIL limits parallelism
- `async/await` uses event loop; single-threaded concurrency
- Allows 1000s of concurrent I/O operations without thread overhead
- Use for: API calls, database queries, file ops, network requests
- Don't use for: CPU-bound work, simple scripts
- Performance improvement: 100 URLs via threads (100-200s) vs async (1-2s)

**15. You have a Python script that needs to read a 50GB log file and process  each line. How would you approach this to avoid memory issues?**

**Answer**:
-

 **Don't** load entire file into memory
- Use file iteration (lazy loading):
```python
with open("/var/log/huge.log") as f:
    for line in f:  # Reads one line at a time
        process_line(line.rstrip())
```
- Or use generator:
```python
def read_logs(path):
    with open(path) as f:
        for line in f:
            yield line.rstrip()

for line in read_logs("/var/log/huge.log"):
    process_line(line)
```
- This keeps memory usage constant regardless of file size

---

### Expert (Very Hard)

**16. Design a robust Python script for managing Kubernetes cluster updates with idempotency, error recovery, and observability.**

**Answer**:
```python
#!/usr/bin/env python3
"""Robust Kubernetes cluster update automation."""

import logging
import json
import time
from typing import Optional
from pathlib import Path
from dataclasses import dataclass
import subprocess
from enum import Enum

logger = logging.getLogger(__name__)

class UpdateStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"

@dataclass
class UpdateState:
    """Persistent update state for idempotency."""
    cluster: str
    version: str
    status: UpdateStatus
    timestamp: str
    
    def to_file(self, path: Path) -> None:
        path.write_text(json.dumps(
            {
                "cluster": self.cluster,
                "version": self.version,
                "status": self.status.value,
                "timestamp": self.timestamp
            },
            indent=2
        ))
    
    @classmethod
    def from_file(cls, path: Path) -> Optional["UpdateState"]:
        if not path.exists():
            return None
        data = json.loads(path.read_text())
        return cls(
            cluster=data["cluster"],
            version=data["version"],
            status=UpdateStatus(data["status"]),
            timestamp=data["timestamp"]
        )

def is_update_needed(cluster: str, target_version: str) -> bool:
    """Check if update is needed (idempotency)."""
    try:
        result = subprocess.run(
            ["kubectl", "version", "--short"],
            capture_output=True,
            text=True,
            check=True
        )
        current = result.stdout.split()[-1]
        return current != target_version
    except Exception as e:
        logger.error(f"Failed to check version: {e}")
        raise

def update_cluster(cluster: str, version: str, state_file: Path) -> bool:
    """Update cluster with error recovery."""
    
    # Check idempotency
    if state := UpdateState.from_file(state_file):
        if state.status == UpdateStatus.SUCCESS:
            logger.info(f"Cluster already updated to {version}")
            return True
        elif state.status == UpdateStatus.IN_PROGRESS:
            logger.warning("Previous update in progress; checking status...")
            # Check if already completed
            if not is_update_needed(cluster, version):
                logger.info("Update already completed!")
                state.status = UpdateStatus.SUCCESS
                state.to_file(state_file)
                return True
    
    # Mark as in-progress
    state = UpdateState(
        cluster=cluster,
        version=version,
        status=UpdateStatus.IN_PROGRESS,
        timestamp=time.isoformat()
    )
    state.to_file(state_file)
    
    try:
        # Execute update with monitoring
        logger.info(f"Starting cluster update to {version}")
        
        for attempt in range(1, 4):
            try:
                subprocess.run(
                    ["kubeadm", "upgrade", "apply", version, "-y"],
                    check=True,
                    capture_output=True,
                    timeout=300
                )
                logger.info(f"Node update completed")
                break
            except subprocess.TimeoutExpired:
                if attempt < 3:
                    logger.warning(f"Timeout; retrying {attempt}/3...")
                    time.sleep(30)
                else:
                    raise
        
        # Verify update
        if is_update_needed(cluster, version):
            raise RuntimeError("Update verification failed")
        
        # Mark as success
        state.status = UpdateStatus.SUCCESS
        state.to_file(state_file)
        logger.info("Cluster update successful")
        return True
        
    except Exception as e:
        logger.error(f"Update failed: {e}")
        state.status = UpdateStatus.FAILED
        state.to_file(state_file)
        raise

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    try:
        update_cluster("prod", "v1.27.0", Path("/var/lib/update-state.json"))
    except Exception:
        exit(1)
```

---

---

# DEEP DIVE: Subtopic Deep Investigations

## Subtopic 1: Python Execution Model & Environment

### Textual Deep Dive

#### Internal Mechanism: How Python Code Executes

Python's execution model is deceptively simple on the surface but highly sophisticated underneath. Understanding each stage is critical for debugging performance issues, managing dependencies in CI/CD, and deploying Python services reliably.

**Stage 1: Source Code Parsing**

When Python encounters a `.py` file:
1. **Lexical Analysis**: Source text → tokens (keywords, identifiers, operators, literals)
2. **Syntax Parsing**: Tokens → Abstract Syntax Tree (AST)
3. **Semantic Analysis**: AST validation (scope checking, type hints collection)

The lexer respects Python's whitespace-sensitive grammar. Indentation is not cosmetic—it defines code blocks (functions, classes, loops). This is unique to Python and affects how scripts must be formatted.

**Stage 2: Compilation to Bytecode**

The parser doesn't directly interpret source; it compiles to bytecode:
- **Bytecode**: Platform-independent intermediate representation (~3-8 instruction streams per line)
- **Storage**: Cached in `__pycache__/{module}.{version}.pyc`
- **Optimization**: Simple optimizations (constant folding, dead code removal) occur here

```python
# Example: What bytecode looks like
import dis

def add(a, b):
    return a + b

dis.dis(add)
# Output:
#  2           0 LOAD_FAST                0 (a)
#              2 LOAD_FAST                1 (b)
#              4 BINARY_ADD
#              6 RETURN_VALUE
```

The `.pyc` cache is critical: recompiling source every time is slow. This is why first import is slower than subsequent imports.

**Stage 3: Python Virtual Machine Execution**

The PVM is a **stack-based interpreter**:
- Maintains a call stack (frames for each function)
- Each frame has a value stack (temporary values during computation)
- Executes bytecode instruction by instruction

```
Frame Stack:
┌─────────────────────────────┐
│ Global Frame (module level) │
├─────────────────────────────┤
│ Function A Frame            │  ← Current frame
│ - Local variables: a=5, b=3 │
│ - Value stack: [5, 3, 8]    │
├─────────────────────────────┤
│ Function B Frame            │
└─────────────────────────────┘
```

**Critical DevOps Implication**: The GIL (Global Interpreter Lock) controls access to the PVM. Only one thread at a time can execute bytecode. This fundamentally affects concurrency strategies.

#### Global Interpreter Lock (GIL) - The Reality

The GIL is often misunderstood. Here's what's actually happening:

**What GIL Prevents**:
- Two Python threads cannot execute bytecode simultaneously
- CPU-bound operations (math, data processing) cannot leverage multiple cores
- Threads block waiting for the lock

**What GIL Allows**:
- I/O operations (network, disk, database) **release the GIL**
- While one thread waits for I/O, another thread can execute
- Multiple threads **are beneficial** for I/O-bound work

**DevOps Production Impact Example**:
```python
# Bad: CPU-bound with threads (no speedup)
import threading

def intensive_calculation(n):
    result = 0
    for i in range(n):
        result += i ** 2
    return result

threads = [
    threading.Thread(target=intensive_calculation, args=(10000000,))
    for _ in range(4)
]
# Running on 4 cores: Still single-threaded execution! GIL prevents parallel work

# Good: I/O-bound with threads (significant speedup)
import threading
import requests

def fetch_api(url):
    return requests.get(url).json()  # Network I/O releases GIL

threads = [
    threading.Thread(target=fetch_api, args=(url,))
    for url in ["api1.example.com", "api2.example.com", ...]
]
# With GIL released for network, multiple threads run in parallel!
```

#### Architecture Role: Where Python Fits

Python in DevOps operates at multiple layers:

1. **Control Layer**: Orchestration, decision-making (Ansible, Kubernetes operators)
2. **Integration Layer**: Connecting systems (cloud SDKs, webhook handlers)
3. **Data Processing Layer**: Log parsing, metric aggregation
4. **Custom Logic Layer**: Business-specific automation

Each layer has different concurrency requirements:
- Control layer: Minimal concurrency (sequential tasks)
- Integration layer: High concurrency (API calls, webhooks)
- Data layer: Batch processing (file iteration, stream processing)

#### Production Usage Patterns

**Pattern 1: Long-Running Service (Kubernetes Pod)**

```python
# Typical pattern: health check endpoint + async event processing
import asyncio
from fastapi import FastAPI
import logging

app = FastAPI()
logger = logging.getLogger(__name__)

# Graceful shutdown handler
def signal_handler(signum, frame):
    logger.info("SIGTERM received, shutting down...")
    # Cleanup resources
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)

@app.get("/health")
def health_check():
    return {"status": "ok"}

async def process_events():
    while True:
        try:
            event = await get_event()
            await handle_event(event)
        except Exception as e:
            logger.error(f"Error processing event: {e}")
            await asyncio.sleep(5)  # Backoff

@app.on_event("startup")
async def startup():
    asyncio.create_task(process_events())
```

**Pattern 2: Batch Job (Kubernetes CronJob)**

```python
#!/usr/bin/env python3
"""Batch job: Process logs hourly."""

import sys
import logging
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
logger = logging.getLogger(__name__)

def process_logs(log_dir: Path) -> int:
    """Process logs. Return exit code."""
    try:
        for log_file in log_dir.glob("*.log"):
            logger.info(f"Processing {log_file}")
            # Process file
            count = 0
            with open(log_file) as f:
                for line in f:
                    if parse_and_store(line):
                        count += 1
            logger.info(f"Processed {count} entries from {log_file}")
        return 0
    except Exception as e:
        logger.error(f"Batch job failed: {e}", exc_info=True)
        return 1

if __name__ == "__main__":
    sys.exit(process_logs(Path("/var/log")))
```

#### DevOps Best Practices

**1. Always Use Virtual Environments in Production**

```dockerfile
# Dockerfile
FROM python:3.11-slim
WORKDIR /app

# Create venv IN the container
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies in venv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
ENTRYPOINT ["python", "app.py"]
```

Why:
- Isolates dependencies from system Python
- Ensures reproducibility (same packages across environments)
- Reduces attack surface (no system pollution)

**2. Always Set PYTHONUNBUFFERED in Containers**

```dockerfile
ENV PYTHONUNBUFFERED=1
```

Why:
- Python buffers output by default
- In containers, logs get lost on crash
- Unbuffered = real-time logs to stdout

**3. Pin All Dependencies Exactly**

```bash
# Bad: Allows version drift
pip install requests

# Good: Exact version
pip install requests==2.28.2
```

Or use lock files:
```bash
pip-compile requirements.in > requirements.txt  # Generates locked version
poetry.lock  # Poetry auto-manages locks
```

**4. Handle SIGTERM Gracefully**

```python
import signal
import sys

def shutdown(signum, frame):
    logger.info("Graceful shutdown initiated")
    # Cancel pending tasks
    # Close connections
    # Flush logs
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown)
```

Why: Kubernetes sends SIGTERM before killing pods. Applications have ~30s to gracefully stop.

#### Common Pitfalls

**Pitfall 1: Assuming system Python is available**

```python
# ❌ Bad
subprocess.run(["python", "script.py"])  # Which python? Might fail

# ✅ Good
subprocess.run([sys.executable, "script.py"])  # Uses current interpreter
```

**Pitfall 2: Not handling bytecode caching**

```python
# ❌ Bad: In read-only filesystems (Lambda, minimal containers)
# RuntimeError: can't create '__pycache__' directory

# ✅ Good: Disable bytecode generation
export PYTHONDONTWRITEBYTECODE=1
```

**Pitfall 3: Breaking shebang assumptions**

```python
# ❌ This breaks in virtual environments
#!/usr/bin/python3

# ✅ Use env to find python from PATH (respects venv)
#!/usr/bin/env python3
```

**Pitfall 4: Mixing threads for I/O thinking it helps CPU**

```python
# ❌ Doesn't help with CPU work
import threading
for i in range(4):
    t = threading.Thread(target=cpu_intensive_function)
    t.start()

# ✅ Use multiprocessing for CPU work
import multiprocessing
for i in range(4):
    p = multiprocessing.Process(target=cpu_intensive_function)
    p.start()
```

---

### Practical Code Examples

#### Example 1: Multi-Environment Python Manager Script

```python
#!/usr/bin/env python3
"""
Manage Python environments across different projects.
Useful for DevOps teams managing multiple infrastructure tools.
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

class PythonEnvironmentManager:
    """Manage isolated Python environments for multiple projects."""
    
    def __init__(self, base_dir: str = "/opt/automation"):
        self.base = Path(base_dir)
        self.projects_dir = self.base / "projects"
    
    def create_environment(
        self,
        project_name: str,
        python_version: str = "3.11",
        requirements_file: str = None
    ) -> bool:
        """Create isolated venv for project."""
        
        project_path = self.projects_dir / project_name
        venv_path = project_path / "venv"
        
        try:
            project_path.mkdir(parents=True, exist_ok=True)
            
            # Create venv
            subprocess.run(
                [sys.executable, "-m", "venv", str(venv_path)],
                check=True,
                capture_output=True
            )
            logger.info(f"Created venv for {project_name} at {venv_path}")
            
            # Install requirements if provided
            if requirements_file and Path(requirements_file).exists():
                pip_path = venv_path / "bin" / "pip"
                subprocess.run(
                    [str(pip_path), "install", "-r", requirements_file],
                    check=True
                )
                logger.info(f"Installed dependencies from {requirements_file}")
            
            # Save environment metadata
            metadata = {
                "project": project_name,
                "python_version": python_version,
                "venv_path": str(venv_path),
                "created": str(Path.cwd())
            }
            metadata_file = project_path / "metadata.json"
            metadata_file.write_text(json.dumps(metadata, indent=2))
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to create environment: {e}")
            return False
    
    def run_in_environment(
        self,
        project_name: str,
        command: List[str]
    ) -> int:
        """Run command in project's venv."""
        
        venv_path = self.projects_dir / project_name / "venv"
        python_exe = venv_path / "bin" / "python"
        
        if not python_exe.exists():
            logger.error(f"Environment not found for {project_name}")
            return 1
        
        try:
            result = subprocess.run(
                [str(python_exe)] + command,
                check=False
            )
            return result.returncode
        except Exception as e:
            logger.error(f"Failed to run command: {e}")
            return 1
    
    def list_environments(self) -> List[Dict]:
        """List all managed environments."""
        
        environments = []
        if self.projects_dir.exists():
            for project_dir in self.projects_dir.iterdir():
                if project_dir.is_dir():
                    metadata_file = project_dir / "metadata.json"
                    if metadata_file.exists():
                        metadata = json.loads(metadata_file.read_text())
                        environments.append(metadata)
        
        return environments

# Usage
if __name__ == "__main__":
    manager = PythonEnvironmentManager()
    
    # Create environment for Ansible
    manager.create_environment(
        "ansible-playbooks",
        requirements_file="ansible_requirements.txt"
    )
    
    # Run playbook in isolated environment
    exit_code = manager.run_in_environment(
        "ansible-playbooks",
        ["ansible-playbook", "deploy.yml"]
    )
    
    # List all environments
    for env in manager.list_environments():
        print(f"- {env['project']} at {env['venv_path']}")
```

#### Example 2: Dependency Lock & Vulnerability Scanning

```python
#!/usr/bin/env python3
"""
Generate lock files and scan for vulnerabilities.
Critical for CI/CD security gates.
"""

import subprocess
import json
import sys
from pathlib import Path
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)

class DependencyManager:
    """Manage and secure Python dependencies."""
    
    @staticmethod
    def generate_lock_file(
        requirements_file: str,
        output_lock: str = "requirements.lock"
    ) -> bool:
        """Generate locked version of requirements."""
        
        try:
            # Use pip-compile to lock exact versions
            subprocess.run(
                [
                    sys.executable, "-m", "pip",
                    "install", "pip-tools"
                ],
                check=True,
                capture_output=True
            )
            
            subprocess.run(
                [
                    "pip-compile",
                    "--output-file", output_lock,
                    requirements_file
                ],
                check=True
            )
            
            logger.info(f"Lock file generated: {output_lock}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to generate lock file: {e}")
            return False
    
    @staticmethod
    def scan_vulnerabilities(requirements_file: str) -> Dict:
        """Scan dependencies for known CVEs."""
        
        try:
            # Use pip-audit for vulnerability scanning
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "pip-audit"],
                check=False,
                capture_output=True
            )
            
            result = subprocess.run(
                ["pip-audit", "--desc", "-r", requirements_file],
                capture_output=True,
                text=True
            )
            
            # Parse output
            vulnerabilities = {
                "passed": result.returncode == 0,
                "output": result.stdout,
                "errors": result.stderr
            }
            
            if not vulnerabilities["passed"]:
                logger.warning(f"Vulnerabilities found:\n{result.stdout}")
            
            return vulnerabilities
            
        except Exception as e:
            logger.error(f"Vulnerability scan failed: {e}")
            return {"passed": False, "error": str(e)}

# Usage in CI/CD
if __name__ == "__main__":
    manager = DependencyManager()
    
    # Generate lock file
    if not manager.generate_lock_file("requirements.in"):
        sys.exit(1)
    
    # Scan for vulnerabilities
    vuln_result = manager.scan_vulnerabilities("requirements.lock")
    if not vuln_result["passed"]:
        logger.error("Security scan failed!")
        sys.exit(1)
    
    logger.info("All checks passed!")
```

---

### ASCII Diagrams

#### Python Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                Python Script Execution Flow                 │
└─────────────────────────────────────────────────────────────┘

1. SCRIPT INVOCATION
   $ python script.py arg1 arg2
        │
        ├─ Shebang check (#!/usr/bin/env python3)
        ├─ Interpreter path resolution
        └─ PYTHONPATH construction
              │
        ┌─────────────────────────────────┐
        │ sys.path = [                    │
        │   '',  # current directory      │  
        │   '/opt/venv/lib/.../python3.11/site-packages',
        │   '/usr/lib/python3.11',        │
        │   '/usr/lib/python3.11/lib-dynload'
        │ ]                               │
        └─────────────────────────────────┘

2. SOURCE CODE LOADING
   script.py (UTF-8 text)
        │
        ├─ Read file into memory
        ├─ Decode bytes → Unicode strings
        ├─ Check for encoding declaration (# -*- coding: utf-8 -*-)
        │
        ▼
   
3. COMPILATION PHASE
   ┌──────────────────────────────────────────┐
   │ 1. Lexer: Text → Tokens                  │
   │    "def foo(x):" → [DEF, NAME, LP, ...]  │
   │                                          │
   │ 2. Parser: Tokens → AST                  │
   │    AST: FunctionDef(name='foo', ...)    │
   │                                          │
   │ 3. Compiler: AST → Bytecode              │
   │    LOAD_CONST, MAKE_FUNCTION, STORE_NAME│
   │                                          │
   │ 4. Store bytecode in __pycache__/        │
   │    script.cpython-311.pyc                │
   └──────────────────────────────────────────┘
        │
        ▼

4. BYTECODE EXECUTION
   ┌────────────────────────────────────────────┐
   │  Python Virtual Machine (PVM)              │
   │  ┌──────────────────────────────────────┐  │
   │  │ Call Stack      │ Value Stack        │  │
   │  ├──────────────────────────────────────┤  │
   │  │ Frame: <module>│ [1, 2, 3] → [6]   │  │
   │  │  - globals     │ (ADD: 2+3=5)       │  │
   │  │  - locals      │                     │  │
   │  │  - code object │                     │  │
   │  └──────────────────────────────────────┘  │
   │                                             │
   │ Execute bytecode instruction by instruction│
   │ (LOAD_CONST, BINARY_ADD, RETURN_VALUE)    │
   └────────────────────────────────────────────┘
        │
        ├─ System calls (I/O, network) → GIL released
        ├─ Reference counting for memory
        ├─ Garbage collection for cycles
        │
        ▼

5. OUTPUT / EXIT
   Return value → subprocess return code or stdout
   Print statements → stdout stream
   Exceptions → stderr
   Exit code (0=success, 1=error, etc.)
```

#### Virtual Environment Architecture

```
┌──────────────────────────────────────────────────────────────┐
│             Virtual Environment Structure                     │
└──────────────────────────────────────────────────────────────┘

System Python        Project 1 (venv)        Project 2 (venv)
/usr/bin/python3     /project1/venv          /project2/venv
    │                    │                       │
    ├─ site-packages │   ├─ bin/               │   ├─ bin/
    │   requests==2.25   │   └─ python ─┐      │   └─ python ─┐
    │   numpy==1.20      │   └─ pip ─┐  │      │   └─ pip ─┐  │
    │   django==2.2      │            │  │      │            │  │
    │                    │            ▼  │      │            ▼  │
    │                    ├─ lib/python3.11│     ├─ lib/python3.11│
    │                    │   site-packages/     │   site-packages/
    │                    │   requests==2.28    │   requests==2.30
    │                    │   numpy==1.24       │   numpy==1.25
    │                    │   fastapi==0.95     │   django==4.2
    │                    │                     │
    ▼                    ▼                     ▼
   Global             Isolated               Isolated
   Packages           Dependencies            Dependencies
   (Conflicts!)       (No conflicts)          (No conflicts)

When Python loads:
$ source venv1/bin/activate
$ python -c "import sys; print(sys.prefix)"
/project1/venv  ← Points to venv, not /usr

$ pip install package
Installs to: /project1/venv/lib/python3.11/site-packages/
Not to: /usr/lib/python3.11/site-packages/
```

#### GIL and Thread Execution

```
┌──────────────────────────────────────────────────────────────┐
│      Global Interpreter Lock (Thread Scheduling)             │
└──────────────────────────────────────────────────────────────┘

Scenario: CPU-Bound Work with 4 Threads
┌─────────────────────────────────────────────┐
│ OS Thread 1  │ OS Thread 2  │ OS Thread 3  │ OS Thread 4  │  (4 cores)
└─────────────────────────────────────────────┘
        │              │              │              │
        └──────────────┼──────────────┼──────────────┘
                       │
                   GIL (1 lock)
                       │
        ┌──────────────┴──────────────┐
        │                             │
    Python T1               Waiting for GIL
    Executing               (blocked)
    Bytecode
        │
        ├─ Add numbers: BINARY_ADD
        ├─ Multiply: BINARY_MULTIPLY
        └─ Increment counter
        
⏱️  Time passage:  Approx 0% CPU utilization on cores 2, 3, 4
                   Only core 1 active
                   
Result: Running 4 threads on CPU-bound work = **NO SPEEDUP**
        (Actually slower due to context switching overhead)

---

Scenario: I/O-Bound Work with 4 Threads
┌─────────────────────────────────────────────┐
│ OS Thread 1  │ OS Thread 2  │ OS Thread 3  │ OS Thread 4  │  (4 cores)
└─────────────────────────────────────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
    GIL released  GIL released   GIL released   GIL released
    Network I/O   File I/O       DB Query       Network I/O
    (Wait)        (Wait)         (Wait)         (Wait)
    
    Thread 1: sends request ──────────────────────────────► waits
    Thread 2: ────── sends request ──────────────────────► waits
    Thread 3: ─────────────── opens file ──► reads ──────► complete
    Thread 4: ──────────────────────── sends query ──────► waits
    
    0ms  100ms    200ms    300ms         600ms
    
    While Thread 1 waits for network (300-600ms),
    Threads 2, 3, 4 can run and acquire GIL

Result: Running 4 threads on I/O-bound work = **SIGNIFICANT SPEEDUP**
        (4x concurrent operations possible)
```

---

## Subtopic 2: Core Scripting & Data Structures

### Textual Deep Dive

#### Internal Mechanisms: Data Structure Implementation

Python's built-in data structures are highly optimized C implementations under the hood. Understanding their internal organization is essential for writing performant DevOps scripts.

**Lists: Dynamic Arrays with Growth Strategy**

Lists in CPython use a **dynamic array** implementation with overallocation:

```
List Memory Layout (internal):
┌─────────────────────────────────────┐
│ List Object Header                  │
├─────────────────────────────────────┤
│ ob_refcnt: 1                        │ Reference count
│ ob_type: &PyList_Type               │ Type info
│ ob_size: 3                          │ Number of items
│ ob_item: ────┐                      │ Pointer to array
│ allocated: 8 │                      │ Capacity (allocated slots)
│              │                      │
└──────────────┼──────────────────────┘
               │
               ▼
         ┌──────────┐
         │ PyObject*│ → actual list items
         ├──────────┤
         │ [ref]    │ → obj1
         ├──────────┤
         │ [ref]    │ → obj2
         ├──────────┤
         │ [ref]    │ → obj3
         ├──────────┤ (empty slots)
         │ NULL     │
         ├──────────┤
         │ NULL     │
         ├──────────┤
         │ NULL     │
         ├──────────┤
         │ NULL     │
         ├──────────┤
         │ NULL     │
         └──────────┘
         (8 slots total, 5 empty)
```

**Growth Strategy**: When you `append()` to a full list, Python doesn't allocate exactly 1 new slot. It allocates ~12.5% extra (growth factor ≈ 1.125). This amortizes the cost of resizing and prevents O(n) complexity for repeated appends.

**Performance Implications**:
```python
lst = []
for i in range(1_000_000):
    lst.append(i)  # O(1) amortized, not O(n)
```

**Dictionaries: Hash Tables**

Dictionaries use **hash tables** with **open addressing** (modern Python 3.6+):

```
Dictionary Structure:
┌─────────────────────────────────┐
│ PyDict Object                   │
├─────────────────────────────────┤
│ size: 3 (number of items)       │
│ ma_used: 3                      │
│ ma_mask: 7 (capacity - 1)       │
│ ma_table: ────┐ (hash table)    │
│               │                 │
└───────────────┼─────────────────┘
                │
                ▼
         Hash Table (size=8):
         Index │ Slot
         ──────┼─────────────────────────────────
           0   │ {hash: 1234, key: "name", value: ref}
           1   │ {hash: 5678, key: "age", value: ref}
           2   │ EMPTY
           3   │ {hash: 9012, key: "email", value: ref}
           4   │ EMPTY
           5   │ EMPTY
           6   │ EMPTY
           7   │ EMPTY
           
         Lookup "age":
         1. hash("age") = 5678
         2. index = 5678 & 7 = 6  (& mask to limit size)
         3. Check slot 6 → empty, retry with probing
         4. Check slot 7 → empty, key not found
         5. Or check another slot using open addressing
```

**Key Performance Factor**: **Load Factor** (used slots / total slots). When load factor > 2/3, the table is rehashed (doubled in size) to maintain O(1) lookup.

**Strings: Immutable, Interned, Unicode**

Strings are immutable and often **interned** (singleton pattern):

```python
a = "hello"
b = "hello"
a is b  # True! Same object due to interning

# But not always:
a = "hello" * 1000
b = "hello" * 1000
a is b  # False (too large to intern)
```

**Unicode Representation**: Python 3 strings use flexible internal representation:
- Latin-1 characters (ASCII): 1 byte per char
- BMP (most common): 2 bytes per char
- Full Unicode: 4 bytes per char

This saves memory for ASCII strings while supporting full Unicode.

**Tuples & Sets: Immutable vs Hashable**

Tuples are immutable and **hashable** (can be dict keys because they can't change):

```python
d = {
    (1, 2): "coordinates",  # ✅ Tuple is hashable
    [1, 2]: "data"          # ❌ TypeError: list is not hashable
}
```

Sets use hash tables (like dicts) but store only keys (no values). This provides O(1) membership testing:

```python
large_set = set(range(1_000_000))
1_000_000 in large_set  # O(1), not O(n)
```

#### Architecture Role: How Data Structures Enable DevOps Scripts

Data structure choice directly impacts DevOps script performance and reliability:

| Task | Wrong Structure | Right Structure | Impact |
|------|-----------------|-----------------|--------|
| **Store config options** | List of tuples | Dictionary | Fast lookup, clear semantics |
| **Check if resource exists** | List with `in` (O(n)) | Set with `in` (O(1)) | 1000 resources: 1000x faster |
| **Parse CSV into records** | List of lists | List of dicts | Clarity, field access by name |
| **Dedup values** | Manual loop | `set(values)` | 10x faster, cleaner code |
| **Track ordering + uniqueness** | List (dup-prone) | Dict keys (ordered, unique) | No data integrity issues |

**Real Production Example**:

```python
# ❌ Bad: Checking 10,000 resource IDs against 5,000 existing ones
# Time: O(10,000 * 5,000) = 50 million operations

existing_ids = ["id1", "id2", ...]  # 5,000 items
for resource_id in incoming_ids:    # 10,000 items
    if resource_id in existing_ids:  # O(n) search!
        mark_as_duplicate(resource_id)

# ✅ Good: Set for O(1) lookup
# Time: O(10,000 + 5,000) = 15,000 operations

existing_ids = set(["id1", "id2", ...])  # 5,000 items
for resource_id in incoming_ids:        # 10,000 items
    if resource_id in existing_ids:     # O(1) lookup!
        mark_as_duplicate(resource_id)
```

#### Production Usage Patterns

**Pattern 1: Configuration Management**

```python
# Kubernetes ConfigMap config
config = {
    "replicas": 3,
    "image": "myapp:1.2.3",
    "resources": {
        "requests": {"cpu": "100m", "memory": "256Mi"},
        "limits": {"cpu": "500m", "memory": "512Mi"}
    },
    "env": {
        "LOG_LEVEL": "INFO",
        "METRICS_PORT": "9090"
    },
    "healthCheck": {
        "endpoint": "/health",
        "interval": 30,
        "timeout": 5
    }
}

# Access nested values safely
log_level = config.get("env", {}).get("LOG_LEVEL", "INFO")
cpu_limit = config.get("resources", {}).get("limits", {}).get("cpu")
```

**Pattern 2: AWS/Azure Inventory Processing**

```python
import json
from collections import defaultdict

# Raw API response
resources = [
    {"type": "EC2", "region": "us-east-1", "state": "running"},
    {"type": "RDS", "region": "us-east-1", "state": "available"},
    {"type": "EC2", "region": "us-west-2", "state": "stopped"},
    # ... 10,000+ more
]

# Group by region and type for reporting
by_region = defaultdict(lambda: defaultdict(list))
for resource in resources:
    by_region[resource["region"]][resource["type"]].append(resource)

# Fast queries
ec2_instances = by_region["us-east-1"]["EC2"]  # O(1)
all_regions = set(r["region"] for r in resources)  # O(n) but done once
```

**Pattern 3: Processing Structured Data**

```python
# Kubernetes event stream (list of dicts)
events = [
    {
        "timestamp": "2024-01-01T10:00:00Z",
        "pod": "redis-0",
        "namespace": "default",
        "event": "CrashLoopBackOff",
        "reason": "ImagePullBackOff",
        "message": "Failed to pull image"
    },
    # ... many events
]

# Find problems: store in dict for fast lookup
problem_pods = {
    event["pod"]: event
    for event in events
    if event["reason"] in ["CrashLoopBackOff", "OOMKilled", "Error"]
}

# Get all failed namespaces (set for uniqueness)
failed_namespaces = {event["namespace"] for event in problem_pods.values()}
```

#### DevOps Best Practices

**1. Use Comprehensions Instead of append()**

```python
# ❌ Slower: repeated resizing
result = []
for item in items:
    if item > 10:
        result.append(item * 2)

# ✅ Faster: single allocation
result = [item * 2 for item in items if item > 10]
```

**2. Choose Data Structures by Access Pattern**

| Access Pattern | Structure | Why |
|---|---|---|
| "exact match lookup" | dict | O(1) |
| "membership test" | set | O(1) |
| "ordered iteration" | list | Memory efficient |
| "prevent duplicates" | set | Automatic dedup |
| "multiple values per key" | dict with list values | Easy extend |

**3. Avoid Nested Loops Where Structure Helps**

```python
# ❌ O(n²) checking
for pod_a in pods:
    for pod_b in pods:
        if pod_a["id"] == pod_b["id"]:
            print("duplicate")

# ✅ O(n) with set
seen = set()
for pod in pods:
    if pod["id"] in seen:
        print("duplicate")
    seen.add(pod["id"])
```

#### Common Pitfalls

**Pitfall 1: Unhashable Type as Dict Key**

```python
# ❌ TypeError
config = {
    ["environment", "name"]: "prod"  # Lists aren't hashable
}

# ✅ Use tuple
config = {
    ("environment", "name"): "prod"  # Tuples are hashable
}
```

**Pitfall 2: Mutating Dict While Iterating**

```python
# ❌ RuntimeError: dictionary changed size during iteration
for key in config:
    if config[key] is None:
        del config[key]

# ✅ Iterate over copy
for key in list(config.keys()):  # .keys() returns view, list() copies
    if config[key] is None:
        del config[key]
```

**Pitfall 3: Shared Mutable Default Arguments**

```python
# ❌ All calls share same list!
def add_pod(pod, pod_list=[]):
    pod_list.append(pod)
    return pod_list

list1 = add_pod("pod1")  # ["pod1"]
list2 = add_pod("pod2")  # ["pod1", "pod2"] - same list!

# ✅ Use None as default
def add_pod(pod, pod_list=None):
    if pod_list is None:
        pod_list = []
    pod_list.append(pod)
    return pod_list
```

---

### Practical Code Examples

#### Example 1: Log Parsing and Aggregation

```python
#!/usr/bin/env python3
"""Parse Kubernetes logs and aggregate errors."""

import re
import json
from pathlib import Path
from collections import defaultdict
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)

class LogAggregator:
    """Parse logs and extract metrics."""
    
    def __init__(self):
        # Data structures for efficiency
        self.errors = defaultdict(list)  # error_type → [occurrences]
        self.pod_restarts = defaultdict(int)  # pod_name → count
        self.error_summary = defaultdict(int)  # error_type → count
    
    def parse_log_file(self, filepath: str) -> None:
        """Parse single log file efficiently."""
        
        # Patterns
        pod_pattern = re.compile(r'pod/(\S+)')
        restart_pattern = re.compile(r'Error|ERROR|CrashLoopBackOff')
        
        with open(filepath) as f:
            for line_num, line in enumerate(f, 1):
                # Extract pod name
                pod_match = pod_pattern.search(line)
                
                # Check for errors
                if restart_pattern.search(line):
                    if pod_match:
                        pod = pod_match.group(1)
                        self.pod_restarts[pod] += 1
                    
                    # Categorize error
                    error_type = self._classify_error(line)
                    self.errors[error_type].append({
                        "file": filepath,
                        "line": line_num,
                        "message": line.strip()
                    })
                    self.error_summary[error_type] += 1
    
    def _classify_error(self, line: str) -> str:
        """Classify error type from log line."""
        
        if "OOMKilled" in line:
            return "out_of_memory"
        elif "ImagePullBackOff" in line:
            return "image_pull"
        elif "CrashLoop" in line:
            return "crash_loop"
        elif "Timeout" in line:
            return "timeout"
        else:
            return "unknown"
    
    def get_summary(self) -> Dict:
        """Get aggregated summary."""
        
        return {
            "total_errors": sum(self.error_summary.values()),
            "error_types": dict(self.error_summary),
            "most_restarted_pods": self._get_top_n(self.pod_restarts, 10),
            "error_details": {
                error: len(occurrences)
                for error, occurrences in self.errors.items()
            }
        }
    
    @staticmethod
    def _get_top_n(data: Dict, n: int) -> List[tuple]:
        """Get top N entries by count."""
        return sorted(data.items(), key=lambda x: x[1], reverse=True)[:n]

# Usage in CI/CD log collection
if __name__ == "__main__":
    aggregator = LogAggregator()
    
    # Parse all logs in directory
    log_dir = Path("/var/log/pods")
    for log_file in log_dir.glob("**/*.log"):
        try:
            aggregator.parse_log_file(str(log_file))
        except Exception as e:
            logger.error(f"Failed to parse {log_file}: {e}")
    
    # Output summary
    summary = aggregator.get_summary()
    print(json.dumps(summary, indent=2))
```

#### Example 2: Configuration Validation with Data Structures

```python
#!/usr/bin/env python3
"""Validate infrastructure config using data structures."""

import yaml
from typing import Dict, Set, List
from pathlib import Path

class ConfigValidator:
    """Validate config against rules using efficient data structures."""
    
    # Valid values as sets for O(1) lookup
    VALID_ENVIRONMENTS = {"dev", "staging", "prod"}
    VALID_REGIONS = {"us-east-1", "us-west-2", "eu-west-1"}
    VALID_LOG_LEVELS = {"DEBUG", "INFO", "WARNING", "ERROR"}
    
    # Required fields
    REQUIRED_FIELDS = {
        "metadata",  # Can be set for fast checking
        "spec",
        "kind"
    }
    
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def validate(self, config_file: str) -> bool:
        """Validate config and return success status."""
        
        try:
            config = yaml.safe_load(Path(config_file).read_text())
        except Exception as e:
            self.errors.append(f"Failed to parse YAML: {e}")
            return False
        
        # Validate using efficient data structures
        self._validate_required_fields(config)
        self._validate_metadata(config.get("metadata", {}))
        self._validate_spec(config.get("spec", {}))
        
        return len(self.errors) == 0
    
    def _validate_required_fields(self, config: Dict) -> None:
        """Check required fields using set intersection."""
        
        config_keys = set(config.keys())
        missing = self.REQUIRED_FIELDS - config_keys
        
        if missing:
            self.errors.append(f"Missing required fields: {', '.join(missing)}")
    
    def _validate_metadata(self, metadata: Dict) -> None:
        """Validate metadata section."""
        
        if "environment" in metadata:
            if metadata["environment"] not in self.VALID_ENVIRONMENTS:
                self.errors.append(
                    f"Invalid environment. Valid: {self.VALID_ENVIRONMENTS}"
                )
        
        if "region" in metadata:
            if metadata["region"] not in self.VALID_REGIONS:
                self.errors.append(
                    f"Invalid region. Valid: {self.VALID_REGIONS}"
                )
    
    def _validate_spec(self, spec: Dict) -> None:
        """Validate spec section."""
        
        if "logLevel" in spec:
            if spec["logLevel"] not in self.VALID_LOG_LEVELS:
                self.warnings.append(
                    f"Unusual log level: {spec['logLevel']}"
                )
        
        # Check for duplicate pod names
        pods = spec.get("pods", [])
        pod_names = [pod.get("name") for pod in pods if isinstance(pod, dict)]
        
        # Detect duplicates using set
        unique_names = set(pod_names)
        if len(unique_names) < len(pod_names):
            duplicates = [
                name for name in unique_names
                if pod_names.count(name) > 1
            ]
            self.errors.append(f"Duplicate pod names: {duplicates}")

# Usage
if __name__ == "__main__":
    validator = ConfigValidator()
    
    valid = validator.validate("deployment.yaml")
    
    if validator.errors:
        print("Errors:")
        for error in validator.errors:
            print(f"  - {error}")
    
    if validator.warnings:
        print("Warnings:")
        for warning in validator.warnings:
            print(f"  - {warning}")
    
    print(f"Valid: {valid}")
```

---

### ASCII Diagrams

#### Data Structure Memory Comparison

```
┌──────────────────────────────────────────────────────────────┐
│  Memory and Performance Characteristics                       │
└──────────────────────────────────────────────────────────────┘

Task: Store 10,000 Kubernetes pod IDs and check membership

1. LIST
   ┌────────────────────────────┐
   │ Python List Object         │
   ├────────────────────────────┤
   │ 10,000 pointers            │
   │ Memory: ~80KB (+overhead)  │
   │                            │
   │ Operation: in (search)     │
   │ Time: O(n) = 10,000 ops    │
   │ Average: 5,000 comparisons │
   └────────────────────────────┘
   
   Code: existing_ids.in pod_id  ← Scans list until found

2. SET
   ┌────────────────────────────┐
   │ Python Set Object          │
   │ (Hash Table)               │
   ├────────────────────────────┤
   │ ~16,000 hash slots         │
   │ Memory: ~180KB (+overhead) │
   │                            │
   │ Operation: in (lookup)     │
   │ Time: O(1) = 1 hash + 1-2  │
   │ Average: 2 comparisons     │
   └────────────────────────────┘
   
   Code: pod_id in existing_ids  ← Hash lookup, done in ~1 op

3. DICTIONARY
   ┌────────────────────────────┐
   │ Python Dict Object         │
   │ (Hash Table with values)   │
   ├────────────────────────────┤
   │ ~16,000 hash slots         │
   │ Memory: ~300KB (+overhead) │
   │                            │
   │ Operation: in + value      │
   │ Time: O(1) = 1 hash + data │
   │ Average: 2 comparisons     │
   └────────────────────────────┘
   
   Code: existing_ids[pod_id]  ← Hash lookup + value retrieval

Membership Test Performance:
┌─────────────────────────────────────────────┐
│ 10,000 checks:                              │
│                                             │
│ LIST:       10,000 × 5,000 avg = 50M ops   │
│ SET:        10,000 × 1-2     = 20K ops    │
│ DICT:       10,000 × 1-2     = 20K ops    │
│                                             │
│ Performance ratio: LIST is ~2,500x slower! │
└─────────────────────────────────────────────┘

Lesson: For membership testing, ALWAYS use set/dict, not list!
```

#### Comprehensions: Memory and Performance

```
┌──────────────────────────────────────────────────────────────┐
│      Comprehension vs Loop Performance                        │
└──────────────────────────────────────────────────────────────┘

Code: Filter even numbers from 1M list
─────────────────────────────────────

METHOD 1: Manual Loop (Slow)
┌────────────────────────────────────┐
│ result = []                        │
│ for item in items:                 │
│     if item % 2 == 0:              │
│         result.append(item)        │
└────────────────────────────────────┘
   │
   ├─ Create empty list → capacity 0
   ├─ First append → resize (capacity 0→1)
   ├─ Second append → resize (capacity 1→1)  (actually 1→2)
   ├─ Third append → OK (capacity 2)
   ├─ Continue: multiple resizes as list grows
   │
   Result: Several hundred resizes!
           Each resize copies all existing items (O(n))

METHOD 2: List Comprehension (Fast)
┌────────────────────────────────────┐
│ result = [item for item in items   │
│           if item % 2 == 0]        │
└────────────────────────────────────┘
   │
   ├─ Pre-calculate final size
   ├─ Allocate array once (with some headroom)
   ├─ Fill array directly
   │
   Result: Single allocation + single scan
           O(n) time, no resizing overhead

Execution Trace:
┌─────────────────────────────┬──────────────────────┐
│ Comprehension               │ Loop with append()   │
├─────────────────────────────┼──────────────────────┤
│ Size calculation: O(n)      │ Append 1: resize ×50 │
│ Allocate: O(1)              │ Append 2-100: resize │
│ Fill: O(n)                  │ ...continues...      │
│ Total: O(n)                 │ Total: O(n log n)!   │
└─────────────────────────────┴──────────────────────┘

Benchmark (10M items):
│
├─ Loop with append(): 2.5 seconds
├─ Comprehension:      0.8 seconds
└─ Speedup: 3.1x faster!
```

---

## Subtopic 3: Control Flow & Functions

### Textual Deep Dive

#### Internal Mechanism: Function Calls and Stack Frames

Every function call in Python creates a **frame object** on the call stack. Understanding frame mechanics is critical for debugging, profiling, and understanding error handling.

**Frame Structure**:

```python
import inspect

def process_data(data):
    frame = inspect.currentframe()
    print(frame.f_code.co_name)     # "process_data"
    print(frame.f_locals)            # Local variables
    print(frame.f_lineno)            # Current line number
    print(frame.f_back)              # Caller's frame
    
    return result
```

**Frame Stack Example**:

```
main() [line 50]
    │
    ├─ Frame: main
    │  - locals: {"config": {...}, "result": None}
    │  - bytecode offset: 42
    │  ▼ calls validate()
        validate(config) [line 30]
            │
            ├─ Frame: validate
            │  - locals: {"config": {...}, "errors": []}
            │  - bytecode offset: 15
            │  ▼ calls check_field()
                check_field(config["name"]) [line 15]
                    │
                    ├─ Frame: check_field
                    │  - locals: {"value": "prod"}
                    │  - bytecode offset: 8
                    │  ▼ (executing)
                    │
                    └─ Return (frame pops)
                
                └─ Resume after check_field() call
        
        └─ Return from validate (frame pops)
    
    └─ Continue in main
```

**Exception Traceback = Frame Stack Dump**:

When an exception occurs, Python prints the entire call stack (all frames). This is why understanding frame mechanics helps with debugging.

#### Decorator Internals

Decorators are higher-order functions that wrap other functions. Understanding their mechanics reveals subtle debugging issues.

**Simple Decorator Execution**:

```python
def timer(func):
    def wrapper(*args, **kwargs):
        print("START")
        result = func(*args, **kwargs)
        print("END")
        return result
    return wrapper

@timer
def process():
    print("PROCESSING")

# Equivalent to:
# process = timer(process)

process()  # Calls wrapped version
```

**Call Sequence**:

```
process()
    │
    ├─ Call wrapper() (the decorated function)
    │  ├─ Print "START"
    │  ├─ Call func() (original process)
    │  │  └─ Prints "PROCESSING"
    │  ├─ Print "END"
    │  └─ Return result
    │
    └─ Return from wrapper

Output:
START
PROCESSING
END
```

**The Problem: Metadata Loss**

```python
def timer(func):
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper

@timer
def process():
    """Process the data."""
    pass

print(process.__name__)      # "wrapper" (WRONG!)
print(process.__doc__)       # None (WRONG!)
help(process)               # Shows wrapper, not process
```

**Solution: functools.wraps**

```python
import functools

def timer(func):
    @functools.wraps(func)  # Copies metadata
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper

@timer
def process():
    """Process the data."""
    pass

print(process.__name__)      # "process" (CORRECT!)
print(process.__doc__)       # "Process the data." (CORRECT!)
```

#### Exception Handling: Control Flow Impact

Exceptions fundamentally alter program control flow. Python's exception model differs from some languages:

**Python Exception Model**:
- **Synchronous**: Exceptions occur at specific points
- **Unwinding**: Stack unwinds (frames pop) until handler found
- **Cleanup**: `finally` blocks execute during unwinding

```python
def cleanup_example():
    f = open("file.txt")
    try:
        bad_operation()  # Raises ValueError
    finally:
        f.close()  # Executes EVEN if exception occurs!
```

**Stack Unwinding Example**:

```
foo() calls bar() calls baz() raises ValueError()

Initial Frame Stack:
┌──────────┐
│ foo()    │
├──────────┤
│ bar()    │
├──────────┤
│ baz()    │← ValueError raised here
└──────────┘

ValueError raised:
└─ Search for handler in baz()'s frame
   └─ Not found
   └─ Pop baz() frame, execute cleanup
   └─ Search for handler in bar()'s frame
   └─ Not found
   └─ Pop bar() frame, execute cleanup
   └─ Search for handler in foo()'s frame
   └─ Found: except ValueError
   └─ Handle exception

Result Frame Stack:
┌──────────┐
│ foo()    │ ← Exception handled here
└──────────┘
```

#### Context Managers: Resource Management

Context managers use a protocol (`__enter__` / `__exit__`) to ensure cleanup:

```python
class Database:
    def __enter__(self):
        self.conn = connect()
        return self.conn
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.conn.close()
        return False  # Don't suppress exceptions

with Database() as db:
    db.execute("SELECT ...")
    # Even if exception here, __exit__ called with exception info
    # __exit__ can suppress exception if returns True
```

#### Generators and Iterators: Lazy Evaluation

Generators are functions that **yield** values one at a time, maintaining state between calls.

**Execution Model**:

```python
def counter():
    print("Starting")
    for i in range(3):
        print(f"Before yield {i}")
        yield i
        print(f"After yield {i}")

gen = counter()  # Returns generator object, NO execution yet

print(next(gen))  # Runs until first yield
# Output:
# Starting
# Before yield 0
# 0

print(next(gen))  # Resumes after yield, runs until next yield
# Output:
# After yield 0
# Before yield 1
# 1

print(next(gen))  # Resumes...
# Output:
# After yield 1
# Before yield 2
# 2

print(next(gen))  # No more yields
# Raises StopIteration
```

**Memory Efficiency**:

```python
# List: Allocates entire array in memory
def get_numbers_list(n):
    result = []
    for i in range(n):
        result.append(i)
    return result

nums = get_numbers_list(1_000_000)  # Allocates 8MB array

# Generator: Produces values on demand
def get_numbers_gen(n):
    for i in range(n):
        yield i

gen = get_numbers_gen(1_000_000)  # Allocates tiny generator object
next(gen)  # Produces next value

for num in gen:  # Memory never exceeds 1 value
    process(num)
```

#### Async/Await: Event-Driven Concurrency

Async/await is an alternative to threads for I/O concurrency. It's fundamentally different from regular functions.

**Async Function Behavior**:

```python
async def fetch():
    return requests.get("http://api.example.com")

# fetch() doesn't execute immediately
coro = fetch()  # Returns coroutine object (not result)

# Must await or use with asyncio
result = await fetch()  # Waits for result
# OR
result = asyncio.run(fetch())  #Runs coroutine
```

**Event Loop Scheduling**:

```
Main Event Loop:
┌────────────────────────────┐
│ 1. Task A: await api1()    │
│    (network I/O, yields)   │
│    ▼                       │
│    → Give time to other    │
│      tasks                 │
│                            │
│ 2. Task B: await api2()    │
│    (network I/O, yields)   │
│    ▼                       │
│    → Give time to other    │
│      tasks                 │
│                            │
│ 3. Task C: await db()      │
│    (database I/O, yields)  │
│    ▼                       │
│    → Give time to other    │
│      tasks                 │
│                            │
│ 4: Check Task A: ready?    │
│    └─ Yes! Resume          │
│                            │
│ 5: Check Task B: ready?    │
│    └─ Yes! Resume          │
│                            │
│ 6: Check Task C: ready?    │
│    └─ No, still waiting    │
│                            │
│ 7: All tasks complete      │
└────────────────────────────┘

Time progression (single-threaded):
┌──────────────────────────────────┐
│ t=0:    Start Task A             │
│ t=0:    Start Task B             │
│ t=0:    Start Task C             │
│         (all launched instantly!) │
│                                  │
│ t=100:  Task A ready, resume     │
│ t=200:  Task B ready, resume     │
│ t=300:  Task C ready, resume     │
│ t=300:  Done!                    │
│                                  │
│ vs Threads: 0+100+200+300=600ms  │
│ vs Async:   max(100,200,300)=300ms
│             (50% faster!)        │
└──────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: Tentative API Calls with Retry**

```python
def retry_with_backoff(max_attempts=3, backoff_factor=2):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt >= max_attempts:
                        raise
                    wait_time = backoff_factor ** (attempt - 1)
                    logger.warning(
                        f"{func.__name__} failed (attempt {attempt}). "
                        f"Retrying in {wait_time}s...: {e}"
                    )
                    time.sleep(wait_time)
        return wrapper
    return decorator

@retry_with_backoff(max_attempts=4, backoff_factor=2)
def call_kubernetes_api():
    return client.apis.core_v1.read_namespaced_pod(...)
```

**Pattern 2: Concurrent High-Volume Operations**

```python
async def process_all_events(events):
    """Process events concurrently."""
    
    tasks = [
        process_event(event)
        for event in events
    ]
    
    # Run all concurrently (not sequentially)
    results = await asyncio.gather(*tasks)
    return results

async def process_event(event):
    """Single event processing."""
    try:
        await api_call(event.id)
        await db_store(event)
    except Exception as e:
        logger.error(f"Failed to process {event.id}: {e}")

# Usage
async def main():
    events = await load_events()
    results = await process_all_events(events)

asyncio.run(main())
```

#### DevOps Best Practices

**1. Always Use functools.wraps in Decorators**

```python
# ✅ Correct
import functools

def my_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # ...
        return func(*args, **kwargs)
    return wrapper
```

**2. Handle Exceptions Explicitly**

```python
# ❌ Too broad
try:
    operation()
except:  # Catches EVERYTHING
    pass

# ✅ Specific
try:
    operation()
except FileNotFoundError:
    logger.error("Config file not found")
except PermissionError:
    logger.error("Insufficient permissions")
except Exception:
    logger.error("Unexpected error", exc_info=True)
```

**3. Use Context Managers for Resource Cleanup**

```python
# ✅ Resource guaranteed to close
with open(file) as f:
    process(f.read())

# ✅ Connection guaranteed to disconnect
with DatabaseConnection() as db:
    db.query("SELECT ...")
```

**4. Prefer Generators for Large Data**

```python
# ❌ Loads entire 10GB file into memory
def load_logs():
    logs = []
    with open("/var/log/huge.log") as f:
        for line in f:
            logs.append(parse(line))
    return logs

# ✅ Processes one line at a time
def load_logs():
    with open("/var/log/huge.log") as f:
        for line in f:
            yield parse(line)

for log in load_logs():
    process_single(log)
```

#### Common Pitfalls

**Pitfall 1: Mutable Default Arguments**

```python
# ❌ Shared state!
def deploy(config, options=[]):
    options.append(config)
    return options

list1 = deploy({"replicas": 3})  # [{"replicas": 3}]
list2 = deploy({"replicas": 5})  # [{"replicas": 3}, {"replicas": 5}] WRONG!

# ✅ New list each call
def deploy(config, options=None):
    if options is None:
        options = []
    options.append(config)
    return options
```

**Pitfall 2: Exception Suppression**

```python
# ❌ Silent failure
try:
    validation()
except:  # Hides all errors
    pass

application_continues()  # May operate with invalid state!

# ✅ Let exceptions propagate (or log them)
try:
    validation()
except ValidationError as e:
    logger.error(f"Validation failed: {e}")
    sys.exit(1)
```

**Pitfall 3: Holding References in Closure**

```python
# ❌ Unexpected behavior
handlers = []
for i in range(3):
    def handler():
        return i  # Closes over variable i
    handlers.append(handler)

for h in handlers:
    print(h())  # All print 2! (i=2 was final value)

# ✅ Capture by default argument
handlers = []
for i in range(3):
    def handler(i=i):  # Captures i NOW
        return i
    handlers.append(handler)

for h in handlers:
    print(h())  # Prints 0, 1, 2
```

---

### Practical Code Examples

#### Example 1: Kubernetes Operator with Decorators and Error Handling

```python
#!/usr/bin/env python3
"""Kubernetes operator with error handling and retries."""

import functools
import logging
import asyncio
from typing import Optional
from dataclasses import dataclass
from kubernetes import client, config, watch

logger = logging.getLogger(__name__)

# Decorator: Retry with exponential backoff
def retry_on_exception(max_attempts=3, backoff_factor=2):
    def decorator(func):
        @functools.wraps(func)
        async def async_wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    if attempt >= max_attempts:
                        logger.error(
                            f"{func.__name__} failed after "
                            f"{max_attempts} attempts: {e}"
                        )
                        raise
                    
                    wait_time = backoff_factor ** (attempt - 1)
                    logger.warning(
                        f"{func.__name__} failed (attempt {attempt}/{max_attempts}). "
                        f"Retrying in {wait_time}s..."
                    )
                    await asyncio.sleep(wait_time)
        
        @functools.wraps(func)
        def sync_wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt >= max_attempts:
                        logger.error(
                            f"{func.__name__} failed after "
                            f"{max_attempts} attempts: {e}"
                        )
                        raise
                    
                    wait_time = backoff_factor ** (attempt - 1)
                    logger.warning(
                        f"{func.__name__} failed (attempt {attempt}/{max_attempts}). "
                        f"Retrying in {wait_time}s..."
                    )
                    time.sleep(wait_time)
        
        # Return async or sync based on input
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator

@dataclass
class Pod:
    name: str
    namespace: str
    replicas: int

class KubernetesOperator:
    """Custom Kubernetes operator."""
    
    def __init__(self):
        config.load_incluster_config()
        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
    
    @retry_on_exception(max_attempts=3)
    def get_pod(self, namespace: str, name: str) -> Optional[dict]:
        """Get pod with retry."""
        try:
            pod = self.v1.read_namespaced_pod(name, namespace)
            return pod
        except client.rest.ApiException as e:
            if e.status == 404:
                logger.info(f"Pod {name} not found in {namespace}")
                return None
            raise
    
    @retry_on_exception(max_attempts=3)
    def scale_deployment(
        self,
        namespace: str,
        name: str,
        replicas: int
    ) -> bool:
        """Scale deployment."""
        
        try:
            deployment = self.apps_v1.read_namespaced_deployment(
                name, namespace
            )
            deployment.spec.replicas = replicas
            
            self.apps_v1.patch_namespaced_deployment(
                name, namespace, deployment
            )
            logger.info(
                f"Scaled {namespace}/{name} to {replicas} replicas"
            )
            return True
            
        except client.rest.ApiException as e:
            logger.error(f"Failed to scale deployment: {e}")
            raise
    
    def watch_pods(self, namespace: str):
        """Watch for pod events using generator."""
        
        w = watch.Watch()
        
        try:
            for event in w.stream(
                self.v1.list_namespaced_pod,
                namespace=namespace
            ):
                pod = event['object']
                event_type = event['type']
                
                try:
                    self._handle_pod_event(pod, event_type)
                except Exception as e:
                    logger.error(
                        f"Failed to handle pod event: {e}",
                        exc_info=True
                    )
                    # Continue watching despite error
        
        except Exception as e:
            logger.error(f"Watch stream failed: {e}")
            raise
        finally:
            w.stop()
    
    def _handle_pod_event(self, pod, event_type: str):
        """Handle individual pod event."""
        
        pod_name = pod.metadata.name
        namespace = pod.metadata.namespace
        phase = pod.status.phase
        
        logger.info(
            f"Pod event: {event_type} | {namespace}/{pod_name} | {phase}"
        )
        
        # Implement logic based on event type
        if event_type == "ADDED":
            logger.debug(f"Pod {pod_name} added")
        elif event_type == "MODIFIED":
            if phase == "Failed":
                logger.warning(f"Pod {pod_name} failed")
        elif event_type == "DELETED":
            logger.info(f"Pod {pod_name} deleted")

# Usage
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    operator = KubernetesOperator()
    
    # Get pod with retries
    pod = operator.get_pod("default", "myapp-0")
    
    # Scale deployment with retries
    operator.scale_deployment("default", "myapp", 3)
    
    # Watch pods (generator)
    operator.watch_pods("default")
```

#### Example 2: Configuration Manager with Context Managers

```python
#!/usr/bin/env python3
"""Configuration management with context managers and generators."""

import json
import tempfile
from pathlib import Path
from contextlib import contextmanager
from typing import Generator, Dict

class ConfigManager:
    """Manage configuration files with automatic cleanup."""
    
    def __init__(self, config_dir: str = "/etc/myapp"):
        self.config_dir = Path(config_dir)
    
    @contextmanager
    def transaction(self, config_file: str) -> Generator[Dict, None, None]:
        """Context manager for atomic config updates."""
        
        config_path = self.config_dir / config_file
        backup_path = None
        
        try:
            # Read original config
            original = json.loads(config_path.read_text())
            
            # Create backup
            backup_path = Path(tempfile.NamedTemporaryFile(
                mode='w',
                suffix='.backup',
                delete=False
            ).name)
            backup_path.write_text(json.dumps(original, indent=2))
            logger.info(f"Backup created at {backup_path}")
            
            # Yield config for modification
            yield original
            
            # Write modified config
            config_path.write_text(json.dumps(original, indent=2))
            logger.info(f"Configuration updated: {config_path}")
            
        except Exception as e:
            logger.error(f"Transaction failed: {e}")
            
            # Restore from backup
            if backup_path and backup_path.exists():
                original = json.loads(backup_path.read_text())
                config_path.write_text(json.dumps(original, indent=2))
                logger.warning(f"Restored config from backup: {backup_path}")
            
            raise
        
        finally:
            # Cleanup backup
            if backup_path and backup_path.exists():
                backup_path.unlink()
                logger.debug(f"Cleaned up backup file: {backup_path}")
    
    @contextmanager
    def temporary_override(
        self,
        config_file: str,
        overrides: Dict
    ) -> Generator[None, None, None]:
        """Temporarily override configuration."""
        
        config_path = self.config_dir / config_file
        
        # Read original
        original = json.loads(config_path.read_text())
        modified = {**original, **overrides}
        
        try:
            # Write overridden config
            config_path.write_text(json.dumps(modified, indent=2))
            logger.info(f"Temporarily overriding {config_file}")
            
            yield
        
        finally:
            # Restore original
            config_path.write_text(json.dumps(original, indent=2))
            logger.info(f"Restored {config_file}")
    
    def load_all_configs(self) -> Generator[tuple, None, None]:
        """Load all configs lazily (generator)."""
        
        for config_file in self.config_dir.glob("*.json"):
            try:
                config = json.loads(config_file.read_text())
                yield (config_file.name, config)
            except Exception as e:
                logger.error(f"Failed to load {config_file.name}: {e}")

# Usage
if __name__ == "__main__":
    manager = ConfigManager()
    
    # Atomic update with automatic rollback
    with manager.transaction("app.json") as config:
        config["log_level"] = "DEBUG"
        config["replicas"] = 5
    # Auto-saves on success, restores on error
    
    # Temporary override
    with manager.temporary_override("app.json", {"dry_run": True}):
        run_deployment()  # Runs in dry-run mode
    # Automatically restored to original state
    
    # Load all configs lazily
    for filename, config in manager.load_all_configs():
        print(f"{filename}: {config}")
```

---

### ASCII Diagrams

#### Exception Stack Unwinding

```
┌──────────────────────────────────────────────────────────────┐
│              Exception Handling & Stack Unwinding             │
└──────────────────────────────────────────────────────────────┘

Call Stack Before Exception:
┌─────────────────────────────────────┐
│ main()                              │
│ ├─ Calls process_config()           │
│ │                                   │
│ Frame Stack:                       │
│ ┌──────────────────────────────┐   │
│ │ [frame main]                 │   │
│ │ [frame process_config]       │   │
│ │ [frame validate_field] ◄─ ✗  │   │ ← raises ValueError
│ └──────────────────────────────┘   │
└─────────────────────────────────────┘

Exception Raised: ValueError("Invalid config")
                        │
                        ▼
        Search validate_field() for handler
        Try/except? NO
                        ▼
        Pop validate_field() frame
        Execute finally blocks? YES
        └─ Close file handle
        └─ Log message
                        │
                        ▼
        Search process_config() for handler
        Try/except? YES
        └─ except ValueError: handle it!
                        │
                        ▼
Exception Handled, Continue


Execution with Error Handling:

def main():
    try:
        process_config()
    except ValueError as e:
        print(f"Config error: {e}")

def process_config():
    validate_field("name")  ◄─ Calls

def validate_field(field):
    f = open("config.json")
    try:
        if not check_format(field):
            raise ValueError(f"Invalid: {field}")
    finally:
        f.close()  ◄─ Executed during unwinding

Timeline:
1. validate_field() called
2. File opened
3. ValueError raised
4. finally block executes (file closed)
5. ValueError propagates up
6. process_config() frame doesn't handle it
7. main() frame handles it in except block
8. Continue execution
```

#### Async/Await Event Loop

```
┌──────────────────────────────────────────────────────────────┐
│          Async Execution vs Thread Execution                 │
└──────────────────────────────────────────────────────────────┘

THREADING (Concurrent):
┌─────────────────────────────────────┐
│ Thread 1        │ Thread 2         │
├─────────────────────────────────────┤
│ 0ms  request    │ 0ms  request       │
│ 0-200ms wait    │ 0-300ms wait       │
│ 200ms resume    │ 300ms resume       │
│ 200-220ms store │ 300-320ms store    │
│ 220ms done      │ 320ms done         │
│                 │                   │
│ Total: 220ms    │ Total: 320ms      │
│                 │                   │
│ Elapsed time (with parallelism):   │
│ ◄─────────────── 320ms ────────────┐
└─────────────────────────────────────┘


ASYNC/AWAIT (Also Concurrent, Single-Threaded):
┌─────────────────────────────────────────────────────────┐
│           Event Loop (Single Thread)                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 0ms  Task A: await api1() ────────────┐                │
│ 0ms  Task B: await api2() ────────┐   │                │
│ 0ms  Task C: await db() ──────┐   │   │                │
│                                │   │   │                │
│ Loop waiting...                │   │   │                │
│                                │   │   │                │
│ 200ms Task A ready, resume ◄───┘   │   │                │
│ 250ms Task C ready, resume ◄───────┘   │                │
│ 300ms Task B ready, resume ◄───────────┘                │
│                                                         │
│ Elapsed time (single-threaded, efficient):             │
│ ◄───────────── 300ms ──────────────────┐               │
└─────────────────────────────────────────────────────────┘

Memory Comparison:
Threading:
  ├─ Thread 1: 1MB stack overhead
  ├─ Thread 2: 1MB stack overhead
  └─ Total: ~2MB for 2 tasks

Async:
  ├─ Coroutine 1: ~1KB
  ├─ Coroutine 2: ~1KB
  ├─ Coroutine 3: ~1KB
  └─ Total: ~10KB for 1000+ tasks!

Recommendation:
─────────────
- Network I/O (REST APIs, webhooks): USE ASYNC
- Database queries: USE ASYNC  
- File operations: USE ASYNC OR THREADING
- CPU-heavy work: USE MULTIPROCESSING
```

---

## Subtopic 4: File Handling & OS Interaction

### Textual Deep Dive

#### Internal Mechanism: File I/O at OS Level

File operations in Python are abstractions over underlying operating system calls. Understanding this layer reveals performance characteristics and error handling requirements.

**File Descriptor Model**:

```
Python File Object
       │
       ├─ file.read()
       ├─ file.write()
       ├─ file.close()
       │
       ▼
File Descriptor (integer)
File Description Index: 3
       │
       ├─ 0: stdin (input stream)
       ├─ 1: stdout (print output)
       ├─ 2: stderr (error output)
       ├─ 3: open_file.txt (your file)
       └─ 4: socket/network connection
       │
       ▼
Kernel File Table
       ├─ Offset in file (seek position)
       ├─ File permissions (read/write/execute)
       ├─ Inode reference
       └─ EOF status
       │
       ▼
Disk I/O
       ├─ Read from disk sector
       ├─ Cache in page buffer
       └─ Return to user process
```

**Buffering Modes**:

```python
# Line buffering (default for terminal)
f = open("file.txt", "w")  # Buffers complete lines
print("Hello")  # Sent immediately (has newline)
print("World", end="")  # Held in buffer (no newline)
f.flush()  # Force write

# Full buffering (default for files)
f = open("file.txt", "wb")  # Buffers many KB
f.write(b"data")  # Held in memory!
f.close()  # Now written to disk

# Unbuffered (raw I/O)
f = open("file.txt", "wb", buffering=0)  # Each write = system call
f.write(b"x")  # Immediately on disk
```

**Performance Implications**:

```python
# ❌ Slow: Many small writes
with open("output.txt", "w") as f:
    for i in range(100_000):
        f.write(f"{i}\n")  # 100,000 system calls (unbuffered each time!)

# ✅ Fast: Buffer in memory
output = []
for i in range(100_000):
    output.append(f"{i}\n")
with open("output.txt", "w") as f:
    f.write("".join(output))  # Single write

# ✅ Even better: Use writelines()
output = [f"{i}\n" for i in range(100_000)]
with open("output.txt", "w") as f:
    f.writelines(output)  # Still buffered
```

#### Path Resolution and Symbolic Links

File paths can be absolute or relative, and can contain symbolic links (soft links):

```python
from pathlib import Path

p = Path("subdir/file.txt")  # Relative
p_abs = p.absolute()         # Convert to absolute
p_resolved = p.resolve()     # Resolve symlinks and relative paths

# Symlink example
ln -s /real/file.txt link.txt
Path("link.txt").resolve()  # Returns Path("/real/file.txt")
```

**Path Resolution Algorithm**:

```
Input: "../../config/app.yaml"
Current directory: /home/user/project/src

Path Resolution:
1. Start from /home/user/project/src
2. ".." → go up one: /home/user/project
3. ".." → go up one: /home/user
4. "config" → down: /home/user/config
5. "app.yaml" → file: /home/user/config/app.yaml

Result: /home/user/config/app.yaml
```

#### Serialization Formats: Storage Overhead

Different serialization formats have different space and performance characteristics:

```
Same data in different formats:

Configuration: "environment": "prod", "replicas": 3

JSON:
{"environment": "prod", "replicas": 3}
Size: 44 bytes

YAML:
environment: prod
replicas: 3
Size: 30 bytes

TOML:
environment = "prod"
replicas = 3
Size: 35 bytes

CSV (as row):
prod,3
Size: 6 bytes (if no headers; 17 with header)

Binary (Protocol Buffers):
[8, 3, 18, 4, 112, 114, 111, 100]  (8 bytes)
Size: 8 bytes

Pickle (Python):
\x80\x04\x95...(binary)
Size: ~30 bytes

Overhead Analysis (10MB data):
- JSON: ~15MB (50% larger)
- YAML: ~12MB (20% larger)
- Binary: ~8MB (compact)
```

#### Environment Variable Resolution

Python resolves environment variables at different times:

```python
import os

# At import time (compile time substitution)
db_url = f"postgresql://{os.environ['DB_HOST']}"

# At runtime (flexible, supports defaults)
DB_HOST = os.getenv("DB_HOST", "localhost")

# Lazy evaluation (useful for testing)
def get_db_url():
    return f"postgresql://{os.environ['DB_HOST']}"
```

**Variable Scope**:

```
OS Environment
    │
    ├─ Process Env (inherited from parent)
    │  ├─ os.environ is a mapping to these
    │  ├─ Changes with os.environ["VAR"] = "value"
    │  │  only affect THIS process
    │  └─ Sub-processes inherit them
    │
    └─ Parent Process (shell, systemd, K8s)
       └─ Sets initial environment
       └─ Child processes inherit
```

#### Subprocess Communication and I/O Redirection

Subprocess I/O must be carefully managed to avoid deadlocks:

```python
import subprocess

# ❌ Risk of deadlock if command produces > 64KB output
result = subprocess.run(  # Default buffer size
    ["long_running_command"],
    capture_output=True
)

# ✅ Safe: Use stream()
for line in subprocess.run(
    ["long_running_command"],
    capture_output=True,
    text=True
).stdout.split("\n"):
    process(line)

# ✅ Stream unbounded output
process = subprocess.Popen(
    ["long_output_command"],
    stdout=subprocess.PIPE,
    text=True
)
for line in process.stdout:  # Reads as available
    process(line)
```

#### Permissions and Security

File permissions are enforced at OS level, not Python:

```python
import os
import stat

# Check permission bits
st = os.stat("script.sh")
mode = st.st_mode

is_readable = bool(mode & stat.S_IRUSR)  # Owner readable?
is_writable = bool(mode & stat.S_IWUSR)  # Owner writable?
is_executable = bool(mode & stat.S_IXUSR)  # Owner executable?

# Change permission (requires appropriate privilege)
os.chmod("script.sh", 0o755)  # rwxr-xr-x

# Common patterns
EXECUTABLE = 0o755  # rwxr-xr-x (scripts, commands)
DEFAULT = 0o644     # rw-r--r-- (files)
SECRET = 0o600      # rw------- (private keys, secrets)
```

#### Logging Architecture in Production

Logging in production must balance verbosity, performance, and information capture:

```python
"""Production logging architecture."""

import logging
import sys
import json
from pythonjsonlogger import jsonlogger

# Standard formatter
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# JSON formatter (for ELK, CloudWatch, etc.)
json_formatter = jsonlogger.JsonFormatter()

# Console handler (for stdout/stderr)
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(formatter)

# File handler (for archival)
file_handler = logging.FileHandler("/var/log/app.log")
file_handler.setFormatter(json_formatter)

# Setup logger
logger = logging.getLogger(__name__)
logger.addHandler(console_handler)
logger.addHandler(file_handler)
logger.setLevel(logging.INFO)

# Usage
logger.info("App started", extra={"version": "1.2.3"})
logger.error("API error", exc_info=True)  # Includes traceback
```

---

### Practical Code Examples

#### Example 1: Robust Log Processing Pipeline

```python
#!/usr/bin/env python3
"""
Log processing pipeline with error handling and progress tracking.
Demonstrates file I/O, parsing, and subprocess integration.
"""

import re
import gzip
import json
import logging
from pathlib import Path
from typing import Generator, List, Dict
from collections import defaultdict
import subprocess

logger = logging.getLogger(__name__)

class LogProcessor:
    """Process logs from files or systemd journal."""
    
    def __init__(self, output_file: str = "/tmp/summary.json"):
        self.output_file = Path(output_file)
        self.stats = defaultdict(int)
        self.errors = []
    
    def process_files(self, directory: str) -> Generator[Dict, None, None]:
        """Process all logs in directory."""
        
        log_dir = Path(directory)
        total_lines = 0
        
        for log_file in log_dir.glob("*.log*"):
            try:
                logger.info(f"Processing {log_file}")
                
                # Detect gzip compressed logs
                if log_file.suffix == ".gz":
                    with gzip.open(log_file, "rt") as f:
                        for line in f:
                            yield from self._parse_line(line)
                            total_lines += 1
                else:
                    with open(log_file) as f:
                        for line in f:
                            yield from self._parse_line(line)
                            total_lines += 1
                
                logger.info(f"Processed {log_file}: {total_lines} lines")
                
            except Exception as e:
                logger.error(f"Failed to process {log_file}: {e}")
                self.errors.append({"file": str(log_file), "error": str(e)})
    
    def _parse_line(self, line: str) -> Generator[Dict, None, None]:
        """Parse log line with patterns."""
        
        # Match: [timestamp] [level] [component] message
        pattern = r"\[(?P<time>\d{4}-\d{2}-\d{2}T[\d:]+)\] \[(?P<level>\w+)\] \[(?P<component>[\w\.]+)\] (?P<message>.*)"
        
        match = re.match(pattern, line.strip())
        if match:
            parsed = match.groupdict()
            self.stats[parsed["level"]] += 1
            
            # Only yield errors for processing
            if parsed["level"] in ["ERROR", "CRITICAL"]:
                yield parsed
    
    def filter_errors(self, directory: str) -> List[Dict]:
        """Extract only error-level logs."""
        
        errors = []
        for parsed in self.process_files(directory):
            errors.append(parsed)
        
        return errors
    
    def save_summary(self):
        """Save processing summary."""
        
        summary = {
            "statistics": dict(self.stats),
            "errors_found": len(self.errors),
            "error_details": self.errors
        }
        
        self.output_file.write_text(json.dumps(summary, indent=2))
        logger.info(f"Summary saved to {self.output_file}")

# Integration with system logs via subprocess
def process_journalctl_logs(service: str) -> None:
    """Process systemd journal logs using journalctl."""
    
    try:
        # Get last 1000 lines from service
        result = subprocess.run(
            ["journalctl", "-u", service, "-n", "1000", "--output", "json"],
            capture_output=True,
            text=True,
            timeout=30,
            check=True
        )
        
        # Parse JSON output
        for line in result.stdout.strip().split("\n"):
            if line:
                entry = json.loads(line)
                message = entry.get("MESSAGE", "")
                
                if "ERROR" in message or "CRITICAL" in message:
                    logger.error(f"{service}: {message}")
    
    except subprocess.TimeoutExpired:
        logger.error(f"journalctl timed out for {service}")
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse journalctl output: {e}")
    except subprocess.CalledProcessError as e:
        logger.error(f"journalctl failed: {e.stderr}")

# Usage
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    processor = LogProcessor()
    
    # Process all logs
    errors = processor.filter_errors("/var/log")
    processor.save_summary()
    
    # Also check service logs
    process_journalctl_logs("myapp.service")
```

#### Example 2: Configuration File Manager with Multiple Formats

```python
#!/usr/bin/env python3
"""
Management config files in multiple formats (YAML, JSON, TOML).
Demonstrates file handling, parsing, and format conversion.
"""

import json
import yaml
import tempfile
from pathlib import Path
from typing import Dict, Optional
from enum import Enum

class ConfigFormat(Enum):
    JSON = "json"
    YAML = "yaml"
    TOML = "toml"

class ConfigFile:
    """Handle config files in multiple formats."""
    
    @staticmethod
    def detect_format(filepath: str) -> ConfigFormat:
        """Detect format from file extension."""
        
        suffix = Path(filepath).suffix.lower()
        
        if suffix == ".json":
            return ConfigFormat.JSON
        elif suffix in [".yaml", ".yml"]:
            return ConfigFormat.YAML
        elif suffix == ".toml":
            return ConfigFormat.TOML
        else:
            raise ValueError(f"Unknown format: {suffix}")
    
    @staticmethod
    def load(filepath: str) -> Dict:
        """Load config from file."""
        
        path = Path(filepath)
        
        if not path.exists():
            raise FileNotFoundError(f"Config file not found: {filepath}")
        
        fmt = ConfigFile.detect_format(filepath)
        content = path.read_text()
        
        try:
            if fmt == ConfigFormat.JSON:
                return json.loads(content)
            elif fmt == ConfigFormat.YAML:
                return yaml.safe_load(content)
            elif fmt == ConfigFormat.TOML:
                # Would require toml library
                raise NotImplementedError("TOML support requires 'toml' library")
        
        except Exception as e:
            raise ValueError(f"Failed to parse {filepath}: {e}")
    
    @staticmethod
    def save(filepath: str, data: Dict, format: Optional[ConfigFormat] = None) -> None:
        """Save config to file."""
        
        path = Path(filepath)
        fmt = format or ConfigFile.detect_format(filepath)
        
        # Create with secure permissions (not readable by others)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        if fmt == ConfigFormat.JSON:
            content = json.dumps(data, indent=2)
            path.write_text(content)
        
        elif fmt == ConfigFormat.YAML:
            content = yaml.dump(
                data,
                default_flow_style=False,
                sort_keys=False
            )
            path.write_text(content)
        
        elif fmt == ConfigFormat.TOML:
            raise NotImplementedError("TOML support requires 'toml' library")
        
        # Set restrictive permissions for secrets
        if "password" in str(data).lower() or "secret" in str(data).lower():
            path.chmod(0o600)  # rw-------
        else:
            path.chmod(0o644)  # rw-r--r--
    
    @staticmethod
    def merge(base: Dict, override: Dict) -> Dict:
        """Deep merge configuration dictionaries."""
        
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                # Recursively merge nested dicts
                result[key] = ConfigFile.merge(result[key], value)
            else:
                # Override at this level
                result[key] = value
        
        return result
    
    @staticmethod
    def validate_schema(data: Dict, schema: Dict) -> List[str]:
        """Validate config against schema."""
        
        errors = []
        
        for key, required_type in schema.items():
            if key not in data:
                errors.append(f"Missing required key: {key}")
            elif not isinstance(data[key], required_type):
                errors.append(
                    f"Key {key}: expected {required_type.__name__}, "
                    f"got {type(data[key]).__name__}"
                )
        
        return errors

# Usage
if __name__ == "__main__":
    # Load config
    config = ConfigFile.load("app.yaml")
    
    # Merge with environment-specific overrides
    overrides = ConfigFile.load("app.prod.json")
    config = ConfigFile.merge(config, overrides)
    
    # Validate
    schema = {
        "app_name": str,
        "port": int,
        "debug": bool
    }
    errors = ConfigFile.validate_schema(config, schema)
    
    if errors:
        raise ValueError("\n".join(errors))
    
    # Save in different format
    ConfigFile.save("output.json", config, ConfigFormat.JSON)
```

---

### ASCII Diagrams

#### File I/O Buffering and Performance

```
┌──────────────────────────────────────────────────────────────┐
│              File I/O Buffering Strategies                   │
└──────────────────────────────────────────────────────────────┘

UNBUFFERED I/O (buffering=0):
┌─────────────────────────────────────┐
│ Python Code                         │
│ f.write("x")                        │
├─────────────────────────────────────┤
│ ▼ (Immediate)                       │
│ OS write() syscall ─────┐           │
│                         ▼           │
│ Disk I/O                │           │
│ Latency: ~1-10ms       │           │
├─────────────────────────────────────┤
│ Characteristics:                    │
│ - Each write = 1 syscall            │
│ - High latency (disk access)       │
│ - Small writes inefficient         │
│ - Performance: ~1000 writes/sec    │
└─────────────────────────────────────┘

BUFFERED I/O (default, bufsize=8KB):
┌─────────────────────────────────────┐
│ Python Code                         │
│ f.write("x")  1000 times           │
├─────────────────────────────────────┤
│ ▼                                   │
│ Buffer (8KB)  Accumulates         │
│ ┌────────────────────────────────┐ │
│ │ x xxxxxxxx...   ← Filling      │ │
│ └────────────────────────────────┘ │
│                 (When full)        │
│                 ▼                  │
│ OS write() syscall ─────┐          │
│                         ▼          │
│ Disk I/O (single write)│          │
│ Latency: ~1-10ms       │          │
├─────────────────────────────────────┤
│ Characteristics:                    │
│ - Many writes = 1 syscall          │
│ - Amortized low latency            │
│ - Efficient batching               │
│ - Performance: ~1M writes/sec      │
└─────────────────────────────────────┘

PERFORMANCE COMPARISON:
┌─────────────────────────────────────┐
│ Writing 1 million lines:            │
│                                     │
│ f.write(..): unbuffered            │
│ Each call = syscall                │
│ 1M syscalls × 1ms = 1000s (😱)    │
│                                     │
│ f.write(...
): buffered    │
│ 1M bytes ÷ 8KB = 125 syscalls     │
│ 125 syscalls × 1ms = 0.125s (✓)   │
│                                     │
│ Speedup: 8000x faster!             │
└─────────────────────────────────────┘
```

#### Subprocess I/O and Potential Deadlocks

```
┌──────────────────────────────────────────────────────────────┐
│         Subprocess I/O Management & Deadlock Prevention       │
└──────────────────────────────────────────────────────────────┘

RISK: Deadlock with capture_output
┌──────────────────────────────────────────────┐
│ Parent Process                               │
│                                              │
│ result = subprocess.run([                   │
│     "command_producing_1GB_output"          │
│ ], capture_output=True)                     │
│                                              │
│ (Waits here...)                             │
│ ├─ Child stdout buffer: 64KB (full!)       │
│ └─ Child blocked trying to write more      │
│ ├─ Parent blocked waiting for child        │
│ └─ DEADLOCK!                               │
│                                              │
└──────────────────────────────────────────────┘

┌──────────────────────┬──────────────────────┐
│ Child Process        │ Parent Process       │
├──────────────────────┼──────────────────────┤
│ Generating output    │ Waiting for child    │
│ 1KB, 2KB, 3KB...    │ (Reading buffer)     │
│ ...64KB (buffer FULL)│                      │
│ Try to write more    │ Buffer not emptied!  │
│ BLOCKED              │ (Not reading enough)│
│                      │ Waiting for child   │
│                      │ BLOCKED              │
│                      │                      │
│ Child: waiting for   │ Parent: waiting for  │
│ parent to read       │ child to finish      │
│                      │                      │
│    ◄─── DEADLOCK ───┤                      │
└──────────────────────┴──────────────────────┘

SOLUTION 1: Stream Output
┌──────────────────────────────────┐
│ process = subprocess.Popen([...],│
│     stdout=subprocess.PIPE)      │
│                                  │
│ for line in process.stdout:      │
│   ├─ Reads from buffer           │
│   ├─ Buffer drains               │
│   └─ Child can write more        │
│                                  │
│ NO DEADLOCK                      │
└──────────────────────────────────┘

SOLUTION 2: Communicate() with Timeout
┌──────────────────────────────────┐
│ try:                             │
│   stdout, stderr =               │
│     process.communicate(          │
│         timeout=30)              │
│ except subprocess.TimeoutExpired: │
│   process.kill()                 │
│                                  │
│ Python handles internal buffer   │
│ management safely                │
└──────────────────────────────────┘

SOLUTION 3: Use threads for concurrent I/O
┌──────────────────────────────────┐
│ process = subprocess.Popen([...],│
│     stdout=subprocess.PIPE)      │
│                                  │
│ def reader_thread():             │
│   for line in process.stdout:    │
│     process_line(line)           │
│                                  │
│ thread = Thread(target=reader...)│
│ thread.start()                   │
│                                  │
│ Parent can safely wait           │
│ Child can continuously output    │
└──────────────────────────────────┘
```

---

# EXPANDED COVERAGE: Hands-On Scenarios & Advanced Interviews

## Hands-On Scenarios: Production Challenges

### Scenario 1: Debugging Mysterious Memory Leak in Kubernetes Operator

#### Problem Statement

A Python-based Kubernetes operator (monitoring Pod lifecycle) has been running in a cluster for 2 weeks. Memory usage gradually increased from 256MB to 2.8GB, causing OOMKilled evictions. The operator handles ~200 events/day.

```
Timeline:
Day 1:  Memory: 256MB
Day 3:  Memory: 512MB
Day 7:  Memory: 1.2GB
Day 14: Memory: 2.8GB → OOMKilled
```

#### Architecture Context

```
Kubernetes Cluster
├─ Custom Operator Pod (Python)
│  ├─ Watches Pod events (event handler)
│  ├─ Caches Pod metadata (in-memory dict)
│  ├─ Calls Kubernetes API
│  └─ Stores metrics
│
└─ Application Pods
   └─ EventSource: 200 events/day
```

#### Step-by-Step Troubleshooting

**Step 1: Identify Leak Type**

```python
#!/usr/bin/env python3
"""Memory profiling for operator."""

import tracemalloc
import logging
from operator import Operator

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

tracemalloc.start()

operator = Operator()

# Simulate operator workload
for hour in range(24):
    # Process events
    events = load_events_from_api()
    operator.handle_events(events)
    
    # Take memory snapshot every hour
    current, peak = tracemalloc.get_traced_memory()
    logger.info(f"Hour {hour}: Current={current/1e6:.1f}MB, Peak={peak/1e6:.1f}MB")
    
    # Print top memory consumers
    snapshot = tracemalloc.take_snapshot()
    top_3 = snapshot.statistics('lineno')[:3]
    for stat in top_3:
        logger.debug(stat)
```

**Step 2: Analyze Suspect Code**

Original code (❌ LEAKY):
```python
class Operator:
    def __init__(self):
        self.pod_cache = {}  # LEAK: Never cleared!
    
    def handle_pod_event(self, event):
        pod_name = event['metadata']['name']
        
        # Store entire Pod object
        self.pod_cache[pod_name] = event['object']
        # After 2 weeks: 10,000+ cached pods
        
        # Also store reference in metrics
        self.metrics[pod_name] = {
            "created": time.time(),
            "status": event['object'].status
        }
```

Analysis using Python tracing:
```python
# Check for circular references
import gc

pods_before = len(gc.get_objects())
operator.handle_events(events)  # Process 1000 events
pods_after = len(gc.get_objects())

logger.info(f"Objects created: {pods_after - pods_before}")
# Expected: ~0 (cleaned up)
# Actual: 1000 (leaked!)
```

**Step 3: Root Cause Analysis**

The cache grows unboundedly. Deleted pods remain in memory:

```python
# Problem: Kubernetes events for Pod deletion don't automatically clear cache
# Pod lifecycle:
# ADDED event → pod_cache[name] = pod_obj
# MODIFIED events (many)
# DELETED event → pod removed from cluster
#                 but pod_cache[name] still holds reference!

# Verify with event stream inspection
def inspect_events(num_events=1000):
    deleted_pods = 0
    cached_pods = 0
    
    for event in watch.watch().stream(...):
        if event['type'] == 'DELETED':
            deleted_pods += 1
        
        cached_pods = len(operator.pod_cache)
    
    logger.info(f"Deleted: {deleted_pods}, Still cached: {cached_pods}")
    # Output: Deleted: 150, Still cached: 5000
    # Many deleted pods are still in cache!
```

#### Production Fix

```python
import weakref
from datetime import datetime, timedelta

class OperatorFixed:
    def __init__(self):
        # Use weak references (auto-cleanup when pod GC'd)
        self.pod_cache = weakref.WeakValueDictionary()
        
        # Track pod lifecycle with TTL
        self.pod_created = {}
        self.pod_deleted = set()
        
        # Cleanup thread
        threading.Thread(target=self._cleanup_old_pods, daemon=True).start()
    
    def handle_pod_event(self, event):
        pod_name = event['metadata']['name']
        event_type = event['type']
        
        if event_type == 'ADDED':
            self.pod_cache[pod_name] = event['object']
            self.pod_created[pod_name] = datetime.now()
        
        elif event_type == 'DELETED':
            # Explicitly remove cache entry
            self.pod_cache.pop(pod_name, None)
            self.pod_created.pop(pod_name, None)
            self.pod_deleted.add(pod_name)  # Track deletion
            
            logger.debug(f"Cleared cache for deleted pod: {pod_name}")
    
    def _cleanup_old_pods(self):
        """Periodically clean up stale entries."""
        while True:
            time.sleep(3600)  # Every hour
            
            now = datetime.now()
            grace_period = timedelta(days=7)
            
            # Remove pods not seen in 7 days
            for pod_name, created in list(self.pod_created.items()):
                if now - created > grace_period:
                    self.pod_cache.pop(pod_name, None)
                    self.pod_created.pop(pod_name, None)
                    logger.info(f"Cleaned up old pod: {pod_name}")
            
            # Limit deleted pods tracking
            if len(self.pod_deleted) > 50000:
                self.pod_deleted.clear()
```

#### Best Practices Applied

1. **☑ Track cache lifecycle** - Log entry/exit of cached objects
2. **☑ Use weak references** - Auto-cleanup when objects eligible for GC
3. **☑ Implement TTL** - Remove entries older than grace period
4. **☑ Monitor memory** - Continuous profiling in production (separate endpoint)
5. **☑ Graceful limits** - Cap cache size to prevent unbounded growth

---

### Scenario 2: CI/CD Pipeline Deadlock with Subprocess Output

#### Problem Statement

A Jenkins CI/CD pipeline for building Docker images hangs randomly (2-3 times per week). The build log output stops mid-build, and the pipeline times out after 60 minutes (unchanged from 5-10 minutes typical).

```
Build Timeline (HUNG):
├─ 10:00: Build started
├─ 10:05: Docker build executing
├─ 10:15: Output stops (last message: "Building layer 5/12")
├─ 11:00: Timeout, build killed
└─ Status: FAILED
```

#### Architecture Context

```
Jenkins Master
    │
    ├─ Build job definition
    │  └─ Execute shell: docker build -t myapp . 2>&1 | tee build.log
    │
    └─ Agent (executor)
       └─ subprocess.call(['docker', 'build', ...])
          └─ Output captured and logged
```

#### Step-by-Step Troubleshooting

**Step 1: Identify Deadlock Signature**

The problem occurs when:
- Docker build stdout is very large (150+ MB)
- Layers are complex (many parallel operations)
- Agent machine has limited memory

```bash
# Check if process is hung (zombies)
ps aux | grep docker
# PID 12345 docker build ... <defunct>
#     (Zombie - parent not reading output)

# Check if parent is blocked
strace -p <parent_pid>
# Blocked on read() or poll() - not consuming stdout
```

**Step 2: Analyze Problematic Code**

Original Groovy Pipeline Job:
```groovy
stage('Build Image') {
    steps {
        sh '''
            docker build -t myapp:latest . 2>&1 | tee build.log
        '''
    }
}
```

The shell command redirects output but the pipeline infrastructure might not be properly draining it. If we trace to Python:

```python
# Problematic Python code (used in some custom builders)
import subprocess
import sys

process = subprocess.Popen(
    ['docker', 'build', '-t', 'myapp', '.'],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

# BUG: Waiting for process without reading output!
exit_code = process.wait()  # ← DEADLOCK RISK if output > buffer

# The buffer is small (~64KB)
# Docker build generates 200MB+ output
# Process blocks trying to write to stdout
# Parent blocks waiting for process
# → DEADLOCK FOREVER
```

**Step 3: Root Cause**

```python
# Demonstrate the deadlock
import subprocess
import time

def deadlock_example():
    # Generate large output (100MB)
    process = subprocess.Popen(
        # Command that outputs lots of data
        ['dd', 'if=/dev/zero', 'bs=1024', 'count=100000'],
        stdout=subprocess.PIPE,
        text=True
    )
    
    # Wait without reading stdout
    start = time.time()
    try:
        exit_code = process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        elapsed = time.time() - start
        print(f"Deadlocked after {elapsed}s")
        process.kill()

# Result: Deadlock after ~1-5 seconds
```

#### Production Fix

**Solution A: Stream Output**

```python
import subprocess
import threading
import sys

def stream_process_output(process):
    """Read output in separate thread to prevent deadlock."""
    for line in process.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()

process = subprocess.Popen(
    ['docker', 'build', '-t', 'myapp', '.'],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1  # Line-buffered
)

# Read output in thread (prevents deadlock)
reader_thread = threading.Thread(target=stream_process_output, args=(process,))
reader_thread.daemon = True
reader_thread.start()

exit_code = process.wait()
reader_thread.join()
```

**Solution B: Use communicate() with Timeout**

```python
import subprocess

process = subprocess.Popen(
    ['docker', 'build', '-t', 'myapp', '.'],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

try:
    stdout, stderr = process.communicate(timeout=300)  # 5 min timeout
    
    # Log output after completion
    with open('build.log', 'w') as f:
        f.write(stdout)
        if stderr:
            f.write('\nSTDERR:\n')
            f.write(stderr)

except subprocess.TimeoutExpired:
    process.kill()
    stdout, stderr = process.communicate()
    logger.error(f"Build timed out. Last output: {stdout[-1000:]}")
```

**Solution C: Use subprocess.run() Properly**

```python
import subprocess

result = subprocess.run(
    ['docker', 'build', '-t', 'myapp', '.'],
    capture_output=True,
    text=True,
    timeout=300
)

# Only fetch large output, never deadlock
with open('build.log', 'w') as f:
    f.write(result.stdout)

print(f"Exit code: {result.returncode}")
print(f"Output size: {len(result.stdout)} bytes")
```

#### Best Practices Applied

1. **☑ Never wait() without draining stdout** - Always read output concurrently
2. **☑ Use communicate() for safety** - Handles buffering internally
3. **☑ Implement timeouts** - Prevent infinite hangs
4. **☑ Stream large output** - Use threading for real-time logs
5. **☑ Monitor process state** - Log output as it arrives, not after

---

### Scenario 3: Production Ansible Playbook Failure Due to Environment Variables

#### Problem Statement

An Ansible playbook for database backup works perfectly in staging but fails intermittently in production:

```
Production runs (failure rate ~5-10%):
❌ Failed to connect to database
Error: Credentials missing or invalid
Playbook halts at "Backup database" task
```

Debug output shows:
```
- Backup database
  debug: Password from env var: "None"  ← What?!
  task result: connectivity error
```

#### Architecture Context

```
Ansible Control Node
├─ Execute playbook
│  └─ Task: Run Python backup script
│     └─ env:
│        DB_PASSWORD: "{{ vault_password }}"
│        DB_USER: backup_user
│
└─ Target Hosts (Database Servers)
   └─ Python script expects:
      DB_HOST, DB_USER, DB_PASSWORD from environ
```

#### Step-by-Step Troubleshooting

**Step 1: Verify Environment Variable Behavior**

```python
#!/usr/bin/env python3
"""Debug environment variable access."""

import os
import sys

def check_env(var_name, required=True):
    value = os.environ.get(var_name)
    
    if value is None and required:
        print(f"ERROR: {var_name} not set!")
        print(f"Available vars: {list(os.environ.keys())}")
        return None
    
    if value:
        # Log value length, not actual value (for security)
        print(f"✓ {var_name} is set ({len(value)} chars)")
    else:
        print(f"✗ {var_name} is empty string!")
    
    return value

# Test
db_password = check_env("DB_PASSWORD")
if not db_password:
    print("Fallback to hardcoded (WRONG - for testing only)")
    db_password = "test"
```

**Step 2: Examine Ansible Playbook**

Problematic playbook:
```yaml
---
- name: Database Backup
  hosts: db_servers
  gather_facts: yes
  
  vars:
    db_password: "{{ vault_password }}"
  
  tasks:
    - name: Backup database
      shell: |
        python3 /opt/backup.py
      environment:
        DB_PASSWORD: "{{ db_password }}"  # ❌ Variable, sometimes empty
        DB_HOST: localhost
        DB_USER: backup_user
```

**Step 3: Root Cause Analysis**

The Vault variable might be undefined intermittently:

```yaml
# Checking variable existence
- name: Debug password
  debug:
    msg: "Password set: {{ db_password is defined }}"
    # Output: True (but value might be empty)

# The issue: variable might be:
# - Empty string: db_password: ""
# - Null: db_password: null
# - Undefined: db_password not set

# Strings like "None" are printed when variable is undefined
# and Ansible's debug coerces it to string
```

Possible causes:
1. **Vault file not decrypted** - Password undefined at runtime
2. **Variable interpolation failure** - Syntax error in template
3. **Conditional variable assignment** - Variable only set in certain conditions

```yaml
# Check vault file corruption
ansible-playbook playbook.yml --vault-password-file=/path/to/vault --check

# If fails, vault might be unreadable
```

#### Production Fix

```yaml
---
- name: Database Backup (Robust)
  hosts: db_servers
  gather_facts: yes
  
  pre_tasks:
    # Validate credentials early
    - name: Check required variables
      assert:
        that:
          - "vault_password is defined"
          - "vault_password | length > 0"
          - "db_host is defined"
          - "db_user is defined"
        fail_msg: |
          Missing required variables:
          - vault_password: {{ vault_password is defined }}
          - db_host: {{ db_host is defined }}
          - db_user: {{ db_user is defined }}
  
  tasks:
    - name: Backup database
      block:
        - name: Run backup script
          shell: |
            set -e  # Exit on error
            python3 /opt/backup.py
          environment:
            DB_PASSWORD: "{{ vault_password }}"
            DB_HOST: "{{ db_host }}"
            DB_USER: "{{ db_user }}"
            # Add logging
            LOG_DIR: /var/log/backups
          register: backup_result
          timeout: 600  # 10 minute timeout
        
        - name: Log successful backup
          debug:
            msg: "Backup completed: {{ backup_result.stdout_lines[-1] }}"
      
      rescue:
        # Handle failure with context
        - name: Log backup failure
          debug:
            msg: |
              Backup failed!
              Return code: {{ backup_result.rc }}
              Error: {{ backup_result.stderr }}
        
        - name: Send alert
          mail:
            host: localhost
            subject: "Backup failed on {{ inventory_hostname }}"
            body: "{{ backup_result.stderr }}"
        
        - name: Fail playbook with context
          fail:
            msg: "Backup failed: {{ backup_result.stderr }}"
```

Improved Python backup script:
```python
#!/usr/bin/env python3
"""Robust database backup with environment validation."""

import os
import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
logger = logging.getLogger(__name__)

def validate_environment():
    """Validate all required credentials and config."""
    
    required = {
        'DB_HOST': 'Database hostname',
        'DB_USER': 'Database user',
        'DB_PASSWORD': 'Database password'
    }
    
    missing = []
    for var_name, description in required.items():
        value = os.environ.get(var_name)
        
        if not value:
            missing.append(f"{var_name} ({description})")
        else:
            logger.info(f"✓ {description} set ({len(value)} chars)")
    
    if missing:
        raise EnvironmentError(
            f"Missing environment variables:\n" +
            "\n".join(f"  - {var}" for var in missing)
        )

def main():
    try:
        # Validate before doing expensive operations
        validate_environment()
        
        db_host = os.environ['DB_HOST']
        db_user = os.environ['DB_USER']
        db_password = os.environ['DB_PASSWORD']
        
        logger.info(f"Starting backup: {db_host}")
        
        # Perform backup
        # ... backup code ...
        
        logger.info("Backup completed successfully")
        return 0
    
    except EnvironmentError as e:
        logger.error(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Backup failed: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    sys.exit(main())
```

#### Best Practices Applied

1. **☑ Validate early** - Check all credentials before work starts
2. **☑ Explicit error messages** - Show what's missing, not cryptic errors
3. **☑ Timeout protection** - Prevent hangs from blocking infrastructure
4. **☑ Assertion templates** - Use Ansible's assert for pre-flight checks
5. **☑ Rescue blocks** - Gracefully handle failure with context
6. **☑ Environment logging** - Log what you're using (without credentials)

---

## Most Asked Interview Questions: Senior DevOps Level

### Question 1: Explain the Global Interpreter Lock and its impact on a high-concurrency Kubernetes webhook service.

**What a Senior DevOps Engineer Should Answer:**

"The GIL prevents only one thread from executing Python bytecode at a time. However, this doesn't make threads useless for I/O-bound work—when a thread awaits I/O (network, disk), the GIL is released, allowing other threads to run.

For a Kubernetes validation webhook receiving, say, 1000 requests/second:

**❌ Wrong approach**: Using threads and expecting parallelism
```python
executor = ThreadPoolExecutor(max_workers=10)
for request in incoming_requests:
    executor.submit(validate_pod, request)
```
The GIL prevents true parallelism on CPU-bound validation. All 10 threads compete for the GIL—you get ~1 thread executing Python code at a time.

**✅ Correct approach**: Using async/await
```python
@app.post('/validate')
async def validate_pod(pod_spec):
    # Async handles I/O-bound operations efficiently
    # While one request awaits, others execute
    return {"allowed": True}
```

This gives you proper concurrency without thread overhead or GIL contention. With async, you can handle thousands of concurrent requests on a single thread using an event loop.

Real example: A webhook with 100 concurrent requests:
- **Threads**: GIL causes contention; avg response time ~500ms
- **Async**: Event loop efficiently switches between requests; avg response time ~50ms (10x faster)

The key insight: **For I/O, use async. For CPU, use multiprocessing or Golang/Rust sidecar.**"

---

### Question 2: You're debugging a production Python script that seems to have a memory leak. Walk me through your diagnosis process.

**What a Senior DevOps Engineer Should Answer:**

"I'd follow this systematic approach:

**Step 1: Quantify the leak**
```python
import tracemalloc
tracemalloc.start()

# ... run for time period ...

current, peak = tracemalloc.get_traced_memory()
logger.info(f"Memory: {current/1e6:.1f}MB current, {peak/1e6:.1f}MB peak")
```

Is memory growing linearly, or is it a one-time allocation?

**Step 2: Identify leak source**
```python
# Take snapshot and find top memory consumers
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')
for stat in top_stats[:10]:
    print(stat)  # Shows which functions/lines allocate most memory
```

**Step 3: Check for common patterns**

I'd look for:
- **Unbounded caches**: Dicts that grow forever
  ```python
  cache = {}  # Never cleared—BAD
  ```
- **Circular references**: Objects referencing each other
  ```python
  obj_a.ref = obj_b
  obj_b.ref = obj_a  # GC can't collect
  ```
- **Global mutable objects**: Modified in loops
  ```python
  global_list = []
  for item in items:
      global_list.append(item)  # Grows forever
  ```
- **Event listener callbacks**: Not unregistered
  ```python
  emitter.on('event', expensive_handler)  # But never offed
  ```

**Step 4: Verify with weak references**
```python
import weakref
import gc

before = len(gc.get_objects())
create_and_use_objects()
gc.collect()
after = len(gc.get_objects())

print(f"Net new objects: {after - before}")
# Should be ~0 if no leak, >0 if leak
```

**Step 5: Production monitoring**
In production, I'd add:
- Memory usage metrics (send to Prometheus/CloudWatch)
- Alert thresholds (80% → page, 95% → auto-restart)
- Periodic snapshots of top memory consumers

**Real example from Kubernetes operator I debugged:**
The operator cached every Pod it ever saw, never deleted. After 30 days: 50GB. The fix:
```python
# Weak reference dict—auto-cleans when Pod object GC'd
self.pod_cache = weakref.WeakValueDictionary()

# Plus explicit cleanup for deleted pods
if event['type'] == 'DELETED':
    self.pod_cache.pop(pod_name, None)
```

This dropped memory from 50GB to 50MB—100x improvement."

---

### Question 3: A critical Python service keeps crashing due to unhandled exceptions in async code. How would you structure error handling?

**What a Senior DevOps Engineer Should Answer:**

"Async error handling is tricky because exceptions in tasks can be silently swallowed. I'd use a layered approach:

```python
import asyncio
import logging
from functools import wraps

logger = logging.getLogger(__name__)

# Layer 1: Task-level error handling
async def safe_task(coro):
    try:
        return await coro
    except asyncio.CancelledError:
        logger.debug('Task cancelled')
        raise  # Re-raise; don't swallow Cancellation
    except Exception:
        logger.error('Task failed', exc_info=True)
        # Return None or re-raise, depending on whether it's recoverable
        return None

# Layer 2: Gather multiple tasks with error context
async def gather_tasks(tasks):
    results = await asyncio.gather(
        *tasks,
        return_exceptions=True  # Don't crash on first failure
    )
    
    # Check results for exceptions
    for task, result in zip(tasks, results):
        if isinstance(result, Exception):
            logger.error(f'Task {task} failed: {result}')
    
    return results

# Layer 3: Watchdog for hanging tasks
async def watchdog(task, timeout=300):
    try:
        return await asyncio.wait_for(task, timeout=timeout)
    except asyncio.TimeoutError:
        logger.error(f'Task timed out after {timeout}s')
        task.cancel()
        raise

# Layer 4: Global exception hook
def setup_error_handling():
    def exception_handler(loop, context):
        exception = context.get('exception')
        logger.critical(
            f'Uncaught exception in event loop: {exception}',
            exc_info=exception
        )
        # Option: restart service
        os.kill(os.getpid(), signal.SIGTERM)
    
    loop = asyncio.get_event_loop()
    loop.set_exception_handler(exception_handler)

# Real usage
async def main():
    setup_error_handling()
    
    tasks = [
        safe_task(fetch_api(url))
        for url in urls
    ]
    
    # Run with timeout and exception gathering
    try:
        results = await asyncio.gather(
            *[watchdog(task) for task in tasks],
            return_exceptions=True
        )
        
        # Log results
        successful = sum(1 for r in results if not isinstance(r, Exception))
        failed = len(results) - successful
        logger.info(f'Results: {successful} success, {failed} failed')
    
    except Exception:
        logger.critical('Main task failed', exc_info=True)
        sys.exit(1)
```

**In production Kubernetes**, I'd also:

1. **Set `PYTHONUNBUFFERED=1`** to see logs before crash
2. **Configure liveness probes** to restart crashed containers
3. **Monitor for exception spikes** (Prometheus metrics)
4. **Set resource limits** to prevent zombie processes

The key principle: **Never silently swallow exceptions in async code. Always log, alert, and gracefully degrade.**"

---

### Question 4: Describe a situation where you chose `subprocess.run()` vs `subprocess.Popen()`. What was the trade-off?

**What a Senior DevOps Engineer Should Answer:**

"

I choose based on streaming requirements and control needs:

**Use `subprocess.run()` when:**
- Output is reasonable size (<10MB)
- You don't need real-time logging
- You want simplicity and safety
```python
# All-in-one: captures output safely
result = subprocess.run(
    ['docker', 'build', '.'],
    capture_output=True,
    text=True,
    timeout=600,
    check=True
)

# Guarantees: no deadlock (Python handles buffering), output captured, timeout enforced
```

**Use `subprocess.Popen()` when:**
- Output is large (100MB+) or unbounded
- You need real-time streaming/monitoring
- You want fine-grained control
```python
# Stream output as it arrives
process = subprocess.Popen(
    ['docker', 'build', '.'],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

# Read output without blocking (prevents deadlock)
for line in process.stdout:
    logger.info(line.strip())

exit_code = process.wait()
```

**Real example—CI/CD pipeline difference:**

I worked on a system deploying to 1000+ servers. Each deployment logs 200+ MB of output.

First attempt used `run()`:
```python
result = subprocess.run(
    ['ansible-playbook', 'deploy.yml'],
    capture_output=True
)
# Issue: Deadlock when output > buffer. Timeout after 1 hour.
```

Fixed with `Popen()` + threading to stream output:
```python
process = subprocess.Popen(
    ['ansible-playbook', 'deploy.yml'],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

def log_output():
    for line in process.stdout:
        logger.info(line.strip())

thread = Thread(target=log_output)
thread.daemon = True
thread.start()

exit_code = process.wait(timeout=600)  # Now safe
```

Result: Drains output in real-time, no deadlock, completes in 10 minutes instead of timing out.

**Trade-off summary:**
- `run()`: Simpler, safer for small output, but can deadlock
- `Popen()`: More complex, better for large output, requires manual management"

---

### Question 5: How would you structure a Python Docker image for production to minimize security risks?

**What a Senior DevOps Engineer Should Answer:**

"Security and supply chain are critical. Here's my approach:

```dockerfile
# Start from minimal image (reduced attack surface)
FROM python:3.11-slim

# Add security labels
LABEL security.scan="passed" \
      maintainer="devops@company.com"

# Run as non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy requirements first for layer caching
COPY requirements.txt .

# Install dependencies with hash verification
RUN python -m pip install --no-cache-dir \
    --require-hashes \  # Prevent dependency injection
    -r requirements.txt

# Copy application code
COPY --chown=appuser:appuser . .

# Security: no write permissions for app
RUN chmod -R 555 /app

# Use non-root user
USER appuser

# Ensure unbuffered output (for logging)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1  # No .pyc files

# Health check
HEALTHCHECK --interval=30s --timeout=10s CMD python -c "import requests; requests.get('http://localhost:8000/health')"

ENTRYPOINT ["python", "main.py"]
```

**Lockfile for reproducibility:**
```bash
# Generate frozen dependencies
pip-compile requirements.in
# Creates requirements.txt with exact versions and hashes

# Then in Dockerfile, use --require-hashes
pip install --require-hashes -r requirements.txt
# Prevents tampering; fails if hashes don't match
```

**Pre-build security scanning:**
```bash
# Scan for known vulnerabilities
pip-audit -r requirements.txt

# Scan Docker image
trivy image myapp:latest
# Identifies CVE-vulnerable packages
```

**In Kubernetes deployment:**
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: myapp:latest
    imagePullPolicy: Always  # Never use cached images
    
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      readOnlyRootFilesystem: true  # Read-only / except /tmp
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
    
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"  # Prevent OOM attacks
        cpu: "500m"
    
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  
  volumes:
  - name: tmp
    emptyDir: {}
```

**Additional controls:**
1. **Scan dependencies for licenses** (avoid GPL in proprietary code)
2. **Sign container images** (verify authenticity)
3. **Use private registry** (not Docker Hub public)
4. **Rotate secrets** (never hardcode credentials)
5. **Log all activity** (audit trail for compliance)"

---

### Question 6: Design a Python script for graceful Kubernetes Pod shutdown given complexity around signal handling and resource cleanup.

**What a Senior DevOps Engineer Should Answer:**

"Kubernetes sends SIGTERM with ~30s before SIGKILL. I'd design for graceful shutdown:

```python
import asyncio
import signal
import sys
import logging
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)

class ServiceManager:
    def __init__(self):
        self.running = True
        self._cleanup_handlers = []
        self._resources = []
    
    def register_cleanup(self, handler):
        '''Register cleanup function (called on shutdown).'''
        self._cleanup_handlers.append(handler)
    
    def register_resource(self, resource):
        '''Register resource that needs cleanup.'''
        self._resources.append(resource)
    
    async def run(self):
        '''Main application loop.'''
        
        # Setup signal handlers
        loop = asyncio.get_event_loop()
        
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(
                sig,
                lambda s=sig: asyncio.create_task(self.shutdown(s))
            )
        
        try:
            # Start application (webhook, worker, etc.)
            await self._start_application()
            
            # Keep running until shutdown
            while self.running:
                await asyncio.sleep(1)
        
        except asyncio.CancelledError:
            logger.info('Task cancelled')
            raise
        
        except Exception:
            logger.error('Unhandled exception', exc_info=True)
            await self.shutdown_with_error()
    
    async def shutdown(self, signum):
        '''Graceful shutdown on signal.'''
        
        logger.info(f'Received signal {signum}, starting graceful shutdown')
        self.running = False
        
        # Cancel all pending tasks
        tasks = asyncio.all_tasks()
        for task in tasks:
            task.cancel()
        
        # Wait for tasks to cleanup
        try:
            await asyncio.gather(*tasks, return_exceptions=True)
        except asyncio.CancelledError:
            pass
        
        # Clean up resources
        await self._cleanup()
        
        logger.info('Graceful shutdown complete')
        sys.exit(0)
    
    async def shutdown_with_error(self):
        '''Shutdown on error.'''
        
        logger.error('Emergency shutdown')
        await self._cleanup()
        sys.exit(1)
    
    async def _cleanup(self):
        '''Execute all registered cleanups.'''
        
        for resource in self._resources:
            try:
                if hasattr(resource, '__aenter__'):
                    # Async context manager
                    await resource.__aexit__(None, None, None)
                else:
                    # Regular cleanup
                    resource.close()
                logger.info(f'Cleaned up {resource}')
            except Exception as e:
                logger.error(f'Cleanup error: {e}', exc_info=True)
        
        for handler in self._cleanup_handlers:
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler()
                else:
                    handler()
                logger.info(f'Executed cleanup: {handler.__name__}')
            except Exception as e:
                logger.error(f'Cleanup handler error: {e}', exc_info=True)
    
    async def _start_application(self):
        '''Start main application services.'''
        # Start webhook server, workers, etc.
        pass

# Usage
async def main():
    manager = ServiceManager()
    
    # Register resources
    db = DatabaseConnection()
    manager.register_resource(db)
    
    # Register cleanup handlers
    async def flush_metrics():
        logger.info('Flushing metrics...')
        await send_final_metrics()
    
    manager.register_cleanup(flush_metrics)
    
    try:
        await manager.run()
    except KeyboardInterrupt:
        logger.info('Interrupted')
        sys.exit(0)

if __name__ == '__main__':
    asyncio.run(main())
```

**In Kubernetes deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        
        lifecycle:
          preStop:
            exec:
              command: ['/bin/sh', '-c', 'sleep 5']
              # Give app 5s to receive SIGTERM before preStop finishes
        
        terminationGracePeriodSeconds: 30
        # Kubernetes waits 30s for graceful shutdown
        # After 30s, sends SIGKILL
```

**Key points:**
1. **Signal handling**: Use `add_signal_handler()` not threading
2. **Task cancellation**: Cancel pending tasks so they can cleanup
3. **Resource cleanup**: Connection pooling, flushing buffers, sending final metrics
4. **Health checks**: Stop accepting new work before cleanup
5. **Liveness probes**: Return unhealthy during shutdown"

---

### Question 7: Explain how you'd optimize a Python script that processes 1 million CSV rows and is currently running in 45 minutes.

**What a Senior DevOps Engineer Should Answer:**

"I'd profile to find the bottleneck, then optimize:

```python
import cProfile
import pstats
import io
from typing import List, Dict

# Step 1: Profile to find where time is spent
def profile_processing():
    pr = cProfile.Profile()
    pr.enable()
    
    process_csv('data.csv')
    
    pr.disable()
    s = io.StringIO()
    sortby = 'cumulative'
    ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
    ps.print_stats(10)  # Top 10 functions
    print(s.getvalue())

profile_processing()
# Output might show:
# - parsing rows: 60% (15MB, many allocations)
# - database inserts: 30% (network latency)
# - regex processing: 10%
```

**Optimization strategies by bottleneck:**

### If parsing is slow:
```python
# ❌ Slow: Process one row at a time
import csv
with open ('data.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        process_row(row)
# Time: 45 minutes

# ✅ Faster: Batch processing + vectorization
import pandas as pd
chunksize = 10000
for chunk in pd.read_csv('data.csv', chunksize=chunksize):
    # Process chunk (10k rows at once)
    processed = chunk.apply(lambda row: process_row(row), axis=1)
# Time: 8 minutes (5x faster)

# Reason: Pandas uses optimized C code, batch I/O
```

### If database inserts are slow:
```python
# ❌ Slow: One insert per row
for row in csv_rows:
    db.execute('INSERT INTO table VALUES (...)', row)
# Time: 30 minutes (30M round trips)

# ✅ Faster: Batch insert
batch = []
for row in csv_rows:
    batch.append(row)
    if len(batch) == 1000:
        db.executemany('INSERT INTO table VALUES (...)', batch)
        batch = []
if batch:
    db.executemany('INSERT INTO table VALUES (...)', batch)
# Time: 5 minutes (1000x fewer round trips)

# ✅ Even faster: Use COPY (PostgreSQL)
import psycopg2
with open('data.csv') as f:
    cursor.copy_from(f, 'table', sep=',')
# Time: 2 minutes (native bulk load)
```

### If regex processing is slow:
```python
# ❌ Slow: Compile regex in loop
for row in rows:
    if re.search(r'pattern', row['field']):  # Recompiles every time!
        process(row)
# Time: 10 minutes

# ✅ Faster: Pre-compile regex
pattern = re.compile(r'pattern')
for row in rows:
    if pattern.search(row['field']):
        process(row)
# Time: 3 minutes

# Or use str methods (fastest)
for row in rows:
    if 'pattern' in row['field']:  # No regex overhead
        process(row)
```

### If memory is limiting parallelism:
```python
# ✅ Multiprocessing with pool
from multiprocessing import Pool

def process_chunk(chunk):
    return [process_row(row) for row in chunk]

chunks = [csv_rows[i:i+10000] for i in range(0, len(csv_rows), 10000)]

with Pool(4) as pool:  # 4 workers
    results = pool.map(process_chunk, chunks)
# Time: 12 minutes (4 cores processing in parallel)
```

**Real example from my experience:**

A customer Python script processing 1M user records took 45 minutes:
- Profiling: Database inserts were 80% of time
- Optimization: Switched from individual inserts to `COPY`
- Result: **45 minutes → 3 minutes** (15x improvement)

```python
# Before
for record in records:
    cursor.execute(
        'INSERT INTO users (name, email) VALUES (%s, %s)',
        (record['name'], record['email'])
    )
conn.commit()
# 45 minutes

# After
import io
buffer = io.StringIO()
for record in records:
    buffer.write(f\"{record['name']},{record['email']}\\n\")

buffer.seek(0)
cursor.copy_from(buffer, 'users', columns=('name', 'email'), sep=',')
conn.commit()
# 3 minutes!
```

**Key optimizations:**
1. **Profile first** (don't guess)
2. **Batch operations** (reduce I/O round trips)
3. **Pre-compile regex** (don't recompile in loops)
4. **Use native tools** (COPY vs INSERT)
5. **Parallelize** (multiprocessing for CPU, async for I/O)
6. **Monitor** (time each optimization to verify)"

---

### Question 8: A Kubernetes cluster runs autoscaling Python workers. What are failure modes you'd design for?

**What a Senior DevOps Engineer Should Answer:**

"Autoscaling with Python workers introduces several failure modes:

**Failure Mode 1: Graceful scaling down**

Kubernetes scales down by **evicting Pods**. If your worker is processing a 10-minute job when eviction starts, it dies:

```python
import signal

class Worker:
    def __init__(self):
        self.is_shutdown = False
        signal.signal(signal.SIGTERM, self._handle_sigterm)
    
    def _handle_sigterm(self, signum, frame):
        '''Pod is being evicted; stop accepting work.'''
        logger.info('SIGTERM: Pod scaling down, refusing new work')
        self.is_shutdown = True
        # Current job continues; new jobs queued by others
    
    async def process_job(self, job):
        if self.is_shutdown:
            # Re-queue job for another worker
            self.queue.put(job)
            return
        
        try:
            await do_work(job)
        except Exception:
            # If job fails, requeue for retry
            self.queue.put(job)
            raise

# Kubernetes config
terminationGracePeriodSeconds: 120  # 2 min to finish in-flight jobs
```

**Failure Mode 2: Pod re-delivery of partially processed jobs**

If a Pod crashes mid-job, the job might be lost or processed twice:

```python
# Use idempotent job processing
class IdempotentWorker:
    async def process_job(self, job):
        '''Process job idempotently (safe to retry).'''
        
        job_id = job['id']
        
        # Check if already processed
        if await self.is_job_completed(job_id):
            logger.info(f'Job {job_id} already done')
            return
        
        try:
            await do_work(job)
            
            # Mark as completed BEFORE responding
            await self.mark_completed(job_id)
            
        except Exception:
            # Job not marked complete, will retry
            logger.error(f'Job {job_id} failed, will retry')
            raise
```

**Failure Mode 3: Runaway jobs consuming CPU/memory**

A single job can cause Node to become unresponsive:

```python
# Resource-bounded job processing
async def process_job_safely(job):
    try:
        await asyncio.wait_for(
            do_work(job),
            timeout=600  # 10 min timeout per job
        )
    except asyncio.TimeoutError:
        logger.error(f'Job {job["id"]} timeout; killing')
        sys.exit(1)  # Crash pod, K8s restarts it
```

In Kubernetes:
```yaml
resources:
  limits:
    memory: 512Mi    # Kill if exceeds
    cpu: 1000m       # Throttle if exceeds
```

**Failure Mode 4: Scaling to zero with in-flight work**

HPA might scale all Pods down while jobs are processing:

```python
# Use Pod disruption budgets
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: worker-pdb
spec:
  minAvailable: 1  # Keep at least 1 Pod running
  selector:
    matchLabels:
      app: worker

# Plus readiness probe that returns unhealthy during shutdown
@app.get('/ready')
def readiness():
    if is_shutdown:
        return {'ready': False}, 503
    return {'ready': True}, 200
```

**Failure Mode 5: Queue overload during scale-down**

If scale-down is faster than queue draining:

```python
# Monitor queue depth and adjust scaling
async def monitor_queue():
    while True:
        depth = await queue.size()
        
        if depth > 10000:
            logger.warning('Queue depth high; preventing scale-down')
            # Return unhealthy from readiness probe
            set_healthy(False)
        else:
            set_healthy(True)
        
        await asyncio.sleep(10)
```

**Production monitoring/alerting:**

```python
# Prometheus metrics
from prometheus_client import Counter, Gauge

jobs_processed = Counter('jobs_total', 'Total jobs processed')
jobs_failed = Counter('jobs_failed', 'Total jobs failed')
jobs_timeout = Counter('jobs_timeout', 'Total jobs timeout')
queue_depth = Gauge('queue_depth', 'Jobs in queue')
pod_graceful_shutdown = Counter('pod_graceful_shutdown', 'Graceful shutdowns')
```

**Key design principles:**
1. **Graceful termination**—handle SIGTERM, finish in-flight work
2. **Idempotency**—jobs safe to retry
3. **Timeouts**—prevent runaway jobs
4. **Queue monitoring**—alert on backed-up work
5. **PDB**—prevent accidental scale-to-zero
6. **Metrics**—observe shutdown behavior"

---

### Question 9: How would you structure a Python application for 12-hour continuous operation in production with minimal downtime?

**What a Senior DevOps Engineer Should Answer:**

"For a long-running application (e.g., Kubernetes operator, event processor), I'd design for:

```python
import asyncio
import signal
import sys
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class ContinuousService:
    '''12-hour operation with periodic maintenance and graceful restart.'''
    
    def __init__(self, restart_interval_hours=12):
        self.restart_interval = timedelta(hours=restart_interval_hours)
        self.started_at = None
        self.running = True
        self.stats = {
            'processed': 0,
            'errors': 0,
            'restarts': 0
        }
    
    async def run(self):
        '''Main service loop with periodic restart.'''
        
        self.started_at = datetime.now()
        logger.info(f'Service started, restart interval: {self.restart_interval}')
        
        # Setup signal handlers
        loop = asyncio.get_event_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(
                sig,
                lambda s=sig: asyncio.create_task(self.shutdown(s))
            )
        
        try:
            while self.running:
                elapsed = datetime.now() - self.started_at
                
                # Check restart threshold
                if elapsed > self.restart_interval:
                    logger.info(
                        f'Restart interval reached ({elapsed}). '
                        f'Graceful restart...'
                    )
                    await self.graceful_restart()
                
                # Run service work
                try:
                    await self.work()
                except Exception:
                    logger.error('Work error', exc_info=True)
                    self.stats['errors'] += 1
                
                # Periodic health checks
                await self.health_check()
                
                await asyncio.sleep(1)
        
        except asyncio.CancelledError:
            logger.info('Service cancelled')
            await self.shutdown('CANCEL')
    
    async def work(self):
        '''Do actual work (process messages, events, etc.).'''
        
        try:
            task = await self.get_next_task(timeout=5)
            if task:
                await self.process_task(task)
                self.stats['processed'] += 1
        except asyncio.TimeoutError:
            pass  # No Task, that's ok
    
    async def health_check(self):
        '''Periodic health verification.'''
        
        # Check memory usage
        import psutil
        memory = psutil.Process().memory_info().rss / 1024 / 1024
        
        if memory > 512:  # 512MB limit
            logger.warning(f'High memory: {memory:.1f}MB')
            # Could trigger garbage collection
            import gc
            gc.collect()
        
        # Check connection pools
        if not await self.verify_connections():
            logger.error('Connection pool unhealthy')
            await self.reset_connections()
    
    async def graceful_restart(self):
        '''Gracefully restart to prevent memory buildup.'''
        
        logger.info('Starting graceful restart...')
        
        # Stop accepting new work
        self.running = False
        
        # Wait for in-flight work to complete
        max_wait = 300  # 5 minutes
        start = datetime.now()
        while self.has_pending_work() and (datetime.now() - start).total_seconds() < max_wait:
            await asyncio.sleep(1)
        
        # Cancel any remaining work
        for task in asyncio.all_tasks():
            task.cancel()
        
        # Cleanup
        await self.cleanup()
        
        logger.info('Graceful restart complete, exiting')
        self.stats['restarts'] += 1
        sys.exit(0)  # Let container orchestrator restart
    
    async def shutdown(self, reason):
        '''Emergency shutdown.'''
        
        logger.info(f'Shutdown requested: {reason}')
        self.running = False
        
        # Cancel pending work
        tasks = asyncio.all_tasks()
        for task in tasks:
            task.cancel()
        
        # Cleanup
        await self.cleanup()
        
        logger.info(f'Stats: {self.stats}')
        sys.exit(1)
    
    async def cleanup(self):
        '''Resource cleanup.'''
        
        try:
            await self.close_connections()
            await self.flush_metrics()
            logger.info('Cleanup complete')
        except Exception:
            logger.error('Cleanup error', exc_info=True)
    
    # Stubs for implementation
    async def get_next_task(self, timeout): pass
    async def process_task(self, task): pass
    async def has_pending_work(self): pass
    async def verify_connections(self): pass
    async def reset_connections(self): pass
    async def close_connections(self): pass
    async def flush_metrics(self): pass
```

**Kubernetes deployment for continuous operation:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: continuous-service
spec:
  replicas: 2  # 2 instances for redundancy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0  # One always running
      maxSurge: 1
  template:
    spec:
      terminationGracePeriodSeconds: 300  # 5 min to finish work
      
      containers:
      - name: service
        image: myservice:latest
        
        env:
        - name: RESTART_INTERVAL_HOURS
          value: "12"
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 1000m

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: continuous-service-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: continuous-service
```

**Key design points:**
1. **Graceful restart**: Exit cleanly, let K8s restart
2. **In-flight work**: Give time to complete (terminationGracePeriodSeconds)
3. **Health checks**: Continuous monitoring for degradation
4. **Resource limits**: Prevent runaway memory
5. **Redundancy**: Multiple replicas for availability
6. **Metrics**: Track processed items, errors, restarts
7. **Rolling updates**: Zero downtime deployments"

---

### Question 10: Troubleshoot a Python script using `subprocess` that leaks file descriptors and eventually crashes.

**What a Senior DevOps Engineer Should Answer:**

"File descriptor (FD) leaks occur when processes or files aren't properly closed. I'd diagnose and fix:

```python
#!/usr/bin/env python3
import os
import subprocess
import resource

# Step 1: Check FD limits
soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
print(f'FD limits: soft={soft}, hard={hard}')
# Typical: soft=1024, hard=65536

# Step 2: Monitor open FDs
def get_open_fds():
    return len(os.listdir(f'/proc/{os.getpid()}/fd'))

print(f'FDs before: {get_open_fds()}')

# Problematic code (leaks FDs):
for i in range(1000):
    result = subprocess.run(
        ['echo', f'Line {i}'],
        capture_output=True
    )

print(f'FDs after: {get_open_fds()}')
# Output: FDs increased by 1000! (leaked)
```

**Why the leak happens:**

```python
# ❌ Subprocess doesn't close inherited file descriptors
for i in range(1000):
    p = subprocess.Popen(['command'])
    # FD opened for stdin, stdout, stderr
    # If not explicit closed, they hang around
    p.wait()
    # Files are NOT closed!
```

**Fix #1: Explicitly close pipes**

```python
import subprocess

# ✅ Close pipes
for i in range(1000):
    p = subprocess.Popen(
        ['echo', f'Line {i}'],
        stdin=subprocess.DEVNULL,  # Don't inherit stdin
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        close_fds=True  # Close unnecessary FDs!
    )
    
    stdout, stderr = p.communicate()  # Reads and closes pipes
    p.wait()

# Monitor
print(f'FDs after fix: {get_open_fds()}')
# Should be same as before (no leak)
```

**Fix #2: Use context manager (best)**

```python
# Python 3.10+: Popen is a context manager
for i in range(1000):
    with subprocess.Popen(
        ['echo', f'Line {i}'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    ) as p:
        stdout, stderr = p.communicate()
        # Guaranteed cleanup on exit
```

**Fix #3: Verify with lsof**

```bash
# See open FDs for process
lsof -p <pid>

# Count file-type FDs
lsof -p <pid> | grep -c REG  # Regular files
lsof -p <pid> | grep -c IPv4  # Sockets

# If growing: process is leaking
```

**Real production example:**

I debugged an Ansible executor that spawned 1000+ child processes. Each process.communicate() wasn't closing FDs:

```python
# Before
for playbook in playbooks:
    proc = subprocess.Popen(
        ['ansible-playbook', playbook],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    out, err = proc.communicate()
    # FDs not closed! After 100 playbooks: 300+ FDs leaked

# After
for playbook in playbooks:
    with subprocess.Popen(
        ['ansible-playbook', playbook],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        close_fds=True
    ) as proc:
        out, err = proc.communicate()
    # FD cleanup guaranteed

# Result: No FD leak, process runs indefinitely
```

**Prevention in production:**

```python
# Monitor FD usage continuously
import logging

logger = logging.getLogger(__name__)

def log_fd_usage():
    import psutil
    proc = psutil.Process()
    
    fds = len(proc.open_files())
    
    if fds > 500:
        logger.warning(f'High FD usage: {fds}')
    
    if fds > soft_limit * 0.9:
        logger.critical(f'FD near limit: {fds}/{soft_limit}')
        # Take action: restart, garbage collect, etc.

# Call periodically
asyncio.create_task(periodic_monitor())
```

**Key points:**
1. **close_fds=True** for Popen
2. **Use context managers** when possible
3. **communicate()** closes streams
4. **Monitor with lsof/psutil** continuously
5. **CI/CD tests**: Run 1000 subprocess calls, verify no FD leak"

---

This comprehensive study guide now provides **enterprise-grade education** suitable for senior DevOps engineers preparing for technical roles, interviews, or contributing to production Python infrastructure.

