# Jenkins – Senior DevOps Study Guide

## 1. Table of Contents

- [Introduction](#2-introduction)
- [Foundational Concepts](#3-foundational-concepts)
- [Jenkins Architecture & Core Components](#1-jenkins-architecture--core-components)
  - [Master-Slave Architecture](#master-slave-configuration-in-jenkins)
  - [Build Process & Components](#jenkins-build-and-components)
  - [Plugins & Integrations](#general-plugins-and-integrations)
- [Pipelines in Jenkins](#2-jenkins-pipelines)
  - [Pipeline Types](#pipeline-types)
  - [Declarative Pipelines](#declarative-pipelines)
  - [Scripted Pipelines](#scripted-pipelines)
  - [Comparison & Best Practices](#comparison-between-declarative-and-scripted-pipelines)
  - [Multiple Tool Versions](#using-multiple-versions-of-tools-in-different-pipelines)
- [Jenkinsfile & Pipeline as Code](#jenkinsfile--pipeline-as-code)
- [Jenkins Jobs & Triggers](#jenkins-jobs--build-triggers)
  - [Job Concepts](#what-is-jenkins-job)
  - [Build Triggers](#how-many-ways-are-there-to-trigger-jenkins-job-or-pipeline)
  - [Build Causes](#jenkins-build-cause)
  - [Poll SCM vs Webhooks](#poll-scm-and-webhook-difference)
- [Jenkins Credentials & Security](#jenkins-credentials--security)
  - [Credential Types](#credential-types)
  - [Credential Scopes](#credential-scopes)
  - [Secure Storage](#secure-credential-storage)
  - [Zero-Trust Security](#zero-trust-environment-security)
- [Shared Libraries & Reusability](#jenkins-shared-library)
- [Advanced Topics](#advanced-jenkins-concepts)
  - [Kubernetes Integration](#jenkins-with-kubernetes)
  - [AWS Integration](#jenkins-with-aws)
  - [Observability & Monitoring](#observability-and-monitoring)
  - [Jenkins X](#jenkins-x)
  - [Build Executors & Ping Thread](#jenkins-build-executor-and-ping-thread)
  - [Stash & Unstash](#stash-and-unstash)
- [Installation & Configuration](#installation-methods)
- [Interview Questions](#common-jenkins-interview-questions)

---

## 2. Introduction

### Overview of Jenkins

Jenkins is an **open-source automation server** written in Java that enables the continuous integration (CI), continuous delivery (CD), and continuous deployment (CDP) of software. It automates parts of software development including compiling, testing, packaging, and deploying applications, reducing the time between code commit and production deployment.

Jenkins is built around a **plugin architecture**, supporting over 1,800 plugins that integrate with virtually every tool in the modern DevOps ecosystem, making it highly extensible and adaptable to diverse CI/CD workflows.

### Why It Matters in Modern DevOps Platforms

1. **Automation of CI/CD Pipelines**: Eliminates manual build, test, and deployment steps, enabling rapid and reliable releases
2. **Distributed Build Architecture**: Master-slave setup allows parallel execution across multiple agents, scaling to handle massive workloads
3. **Pipeline as Code**: Jenkinsfiles version-controlled with code enable reproducible, auditable CI/CD workflows
4. **Extensive Plugin Ecosystem**: Integrates with Git, Docker, Kubernetes, AWS, Azure, SonarQube, Slack, and hundreds of other tools
5. **Flexible Trigger Mechanisms**: Builds triggered by code commits, webhooks, schedules, or manual intervention
6. **Enterprise-Ready**: Supports RBAC, SSO (LDAP, OAuth), credential management, and audit logging
7. **Cost-Effective**: Open-source and lightweight, suitable for startups and enterprises

### Real-World Production Use Cases

1. **Microservices CI/CD Automation**
   - Automated build, test, and container image creation for 100+ microservices
   - Parallel testing across different build agents
   - Docker image scanning for vulnerabilities before registry push

2. **Multi-Environment Promotion**
   - Dev → Staging → Production promotion via parameterized pipelines
   - Approval gates with manual intervention for production deployments
   - Artifact retention policies and artifact repository management

3. **Kubernetes Deployment Automation**
   - Dynamic agent provisioning via Kubernetes plugin for ephemeral build pods
   - Helm chart deployment with environment-specific values
   - Canary deployments with automated rollback on test failures

4. **Compliance & Audit Requirements**
   - Complete audit trail of all deployments via build logs
   - Credential rotation automation using Jenkins API
   - Policy-as-code enforcement via Pipeline script approval

5. **DevOps at Scale**
   - Shared libraries enable 50+ teams to use standardized pipelines
   - Master-slave distributed architecture supports 1000+ builds per day
   - Integration with Terraform/Ansible for infrastructure provisioning

### Where It Typically Appears in Cloud Architecture

- **CI/CD Orchestrator**: Central pipeline execution engine in DevOps workflows
- **Build Automation**: Compiles code, runs tests, generates artifacts (JARs, Docker images)
- **Deployment Engine**: Deploys to Kubernetes, cloud platforms (AWS, Azure, GCP), or on-premises infrastructure
- **Integration Hub**: Webhook receiver from Git repositories, integration with messaging platforms (Slack), monitoring systems
- **Artifact Management**: Stores build artifacts in repositories (Nexus, Artifactory)
- **Infrastructure Provisioning**: Triggers Terraform/CloudFormation to provision infrastructure
- **Security Scanning**: Integrates with SAST (SonarQube), dependency scanning (Snyk), container scanning tools

---

## 3. Foundational Concepts

### Key Terminology

**Build**
- The process of compiling, testing, and packaging source code into a deliverable artifact
- Includes stages: code checkout, compilation, testing, packaging, and notification
- Produces artifacts (JAR files, Docker images, binaries) stored in repositories

**Pipeline**
- A series of automated steps defining the entire workflow from code commit to production deployment
- Can be represented as code (Jenkinsfile) for version control and reproducibility
- Orchestrates multiple stages (Build, Test, Deploy) potentially across different agents

**Job**
- A configured task or project in Jenkins that executes a defined sequence of actions
- Can be a freestyle job (UI-configured) or pipeline job (code-based via Jenkinsfile)
- Building blocks of CI/CD automation

**Agent / Node**
- A machine (physical or virtual) that Jenkins uses to execute builds
- Master/controller is the main Jenkins instance; agents are workers
- Each agent can run jobs in parallel based on executor count

**Executor**
- A slot on a Jenkins agent that can execute one build at a time
- Each agent has a fixed number of executors (default: 2)
- Total parallel builds = sum of all executors across all agents

**Workspace**
- A directory on a Jenkins agent where build files are stored and checked out
- Location where build happens: code clone, compilation, test execution
- Path: `$JENKINS_HOME/workspace/<Job_Name>` on agents

**Artifact**
- A file or set of files produced by a build (JAR, Docker image, compiled binary, logs)
- Archivable to repositories (Nexus, Artifactory) for later deployment
- Can be stashed/unstashed between pipeline stages or agents

### Architecture Fundamentals

**Master-Slave (Controller-Agent) Model**

1. **Jenkins Master/Controller**
   - Central instance managing jobs, scheduling builds, and distributing work
   - Runs the web UI, REST API, and plugin management
   - Stores configurations, credentials, and job history

2. **Jenkins Agents/Slaves**
   - Worker machines that execute actual builds
   - Labeled for targeting specific job types (e.g., linux-builder, docker-agent)
   - Can have different OS, tools, and configurations

3. **Communication**
   - Master communicates with agents via JNLP (Java Network Launch Protocol) or SSH
   - Agents register with master and await job assignment
   - Master distributes workload based on executor availability and agent labels

**Build Execution Flow**

```
Code Commit → Webhook/Poll SCM → Build Triggered → Agent Selected 
→ Workspace Prepared → Code Checked Out → Build Steps Executed 
→ Tests Run → Artifacts Generated → Notifications Sent
```

### Important DevOps Principles

**Infrastructure as Code (Pipeline as Code)**
- CI/CD configuration stored in Jenkinsfile alongside application code
- Version-controlled, reviewable via PR before merging
- Reproducible: same code commit = same pipeline behavior
- Enables disaster recovery: pipeline recreated from Git

**Automation Over Manual Processes**
- Every deployment triggered automatically based on code changes
- Eliminates human error in build/test/deploy cycles
- Reduces time-to-market by compressing release cycles
- Enables high-frequency deployments (daily or hourly)

**Fail-Fast Feedback**
- Developers notified immediately of build failures via Slack/email
- Failed tests block progression to later stages
- Quick feedback loop reduces defect escape to production
- Build artifacts retained for root-cause analysis

**Distributed Execution & Scalability**
- Master-slave architecture scales builds horizontally
- Parallel test execution across multiple agents reduces overall pipeline duration
- Plugins enable dynamic agent provisioning (e.g., Kubernetes)

**Security & Compliance**
- Credentials stored securely with encryption
- RBAC restricts who can trigger/approve deployments
- Audit logs track all builds and deployments
- Pipeline script approval prevents unauthorized code execution

### Best Practices

1. **Pipeline Structure**
   - Use declarative pipelines for clarity and maintainability (preferred for most cases)
   - Keep individual stages focused on specific tasks (Build, Test, Deploy)
   - Use shared libraries for common logic across projects
   - Limit pipeline duration with aggressive timeouts (fail fast)

2. **Agent Management**
   - Label agents by capabilities (docker, linux, windows, gpu)
   - Use a pool of agents to distribute load
   - Monitor agent health and executor availability
   - Scale agents dynamically (Kubernetes, Docker Compose, cloud auto-scaling)

3. **Credential Management**
   - Store all sensitive data as Jenkins Credentials, not hardcoded
   - Use credential scopes (Global, System) appropriately
   - Rotate credentials regularly
   - Audit credential usage

4. **Artifact Handling**
   - Archive important artifacts (build outputs, test reports)
   - Implement retention policies to prevent disk bloat
   - Use external repositories (Nexus, Artifactory) for long-term storage
   - Clean workspaces periodically with `cleanWs()`

5. **Monitoring & Logging**
   - Track build duration trends to identify performance regressions
   - Set up alerts for build failures
   - Centralize logs (ELK Stack) for analysis
   - Monitor agent availability and executor queue

### Common Misunderstandings

**Myth: "Jenkins is only for CI, not CD or infrastructure"**
- Reality: Jenkins is a full CI/CD orchestrator; can trigger infrastructure provisioning (Terraform), deployments to Kubernetes, and infrastructure validation

**Myth: "Freestyle jobs are obsolete"**
- Reality: While Declarative Pipelines are preferred, freestyle jobs remain useful for simple, one-off tasks. Both coexist

**Myth: "Jenkins is insecure because it's open-source"**
- Reality: Jenkins has robust security features (RBAC, credential encryption, script approval) when properly configured; security is the operator's responsibility

**Myth: "Jenkins doesn't scale beyond a few hundred builds"**
- Reality: Jenkins scales to thousands of builds/day with proper master-slave setup, agent pooling, and configuration

**Myth: "Declarative vs Scripted pipelines are equally suitable for all use cases"**
- Reality: Declarative is simpler and preferred for 90% of cases; Scripted offers more flexibility for complex scenarios

---

# 1. Jenkins Architecture & Core Components

## Master-Slave Configuration in Jenkins

### What It Is

Jenkins master-slave (controller-agent) architecture separates the orchestration layer from the execution layer, enabling scalability and parallel builds.

**Master (Controller) Responsibilities:**
- Hosts the web UI and REST API
- Stores job configurations and credentials
- Schedules builds based on triggers
- Manages agent connections
- Stores build history and logs

**Slave (Agent) Responsibilities:**
- Executes actual build jobs
- Runs on the same or different machine
- Each agent has a label for targeting specific job types
- Can have different OS, Java versions, and tools

### How It Works

1. Developer pushes code to Git
2. Jenkins master detects webhook notification or polling finds new commit
3. Master schedules the job on an appropriate agent based on label
4. Agent executes build steps in its workspace
5. Agent reports build results back to master
6. Master archives artifacts and sends notifications

### Benefits

- **Scalability**: Add more agents to increase build capacity
- **Distributed Load**: Parallel builds across multiple machines
- **Isolation**: Build environments can be specialized (Docker, Linux, Windows)
- **Resource Efficiency**: Heavy builds don't block other jobs
- **Resilience**: Master failure doesn't affect already-running builds

---

## Jenkins Build and Components

### What is a Build?

A build is the complete process of:
- **Source Code Retrieval**: Fetching code from Git/GitHub/GitLab
- **Build Execution**: Compiling code (Maven, Gradle, etc.)
- **Testing**: Running unit tests, integration tests
- **Packaging**: Creating artifacts (JAR, Docker image, binary)
- **Artifact Archiving**: Storing artifacts for deployment
- **Notifications**: Sending success/failure notifications via Slack, email

### Build Artifacts & Management

**Where to Find Artifacts:**
- Jenkins UI: Artifacts section in job page
- File system: `$JENKINS_HOME/workspace/<Job_Name>/`
- External repositories: Artifactory, Nexus
- Cloud storage: S3, GCS

**Artifact Archiving:**
```groovy
archiveArtifacts artifacts: 'target/*.jar, build-logs/**'
```

**Artifact Retention:**
```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
}
```

---

## General Plugins and Integrations

### Major Plugin Categories

**Source Code Management (SCM)**
- Git, GitHub, GitLab, Bitbucket
- Enable Jenkins to pull code from repositories

**Build Tool Plugins**
- Maven, Gradle, Ant
- Automatically download and configure build tools

**Testing Frameworks**
- JUnit, TestNG, NUnit (test result parsing)
- Generates reports and trends

**Deployment Plugins**
- Docker, Kubernetes, AWS, Helm
- Deploy to various platforms and cloud services

**Notification Plugins**
- Slack, email, Microsoft Teams
- Alert teams of build status

**Authentication & Authorization**
- LDAP, Active Directory, OAuth
- Integrate with enterprise identity providers

**Artifact Management**
- Nexus, Artifactory, AWS S3
- Publish and retrieve build artifacts

**Monitoring & Analysis**
- SonarQube (code quality)
- Prometheus (metrics)
- ELK Stack (centralized logging)

---

## Environment Variables & Workspace

### Default Jenkins Environment Variables

| Variable | Description |
| --- | --- |
| `$JOB_NAME` | Name given to the job during creation |
| `$BUILD_NUMBER` | Sequential build number for this job |
| `$BUILD_TIMESTAMP` | Timestamp when build started |
| `$WORKSPACE` | Path to the workspace directory |
| `$NODE_NAME` | Name of the agent running the build |
| `$BUILD_URL` | URL to view this build in Jenkins UI |
| `$JENKINS_URL` | URL of Jenkins master |
| `$GIT_COMMIT` | Git commit hash being built |
| `$GIT_BRANCH` | Git branch being built |

### Workspace Location

- **Master**: `$JENKINS_HOME/workspace/<Job_Name>`
- **Agent**: `<Agent_Home>/workspace/<Job_Name>`
- Auto-cleanup options available via `cleanWs()`

---

# 2. Jenkins Pipelines

## Pipeline Types

### Freestyle Jobs (Legacy)

- UI-configured, no code required
- Simple point-and-click interface
- Suitable for one-off tasks but not recommended for complex CI/CD
- Limited version control capability

### Declarative Pipeline (Recommended)

- Code-based, stored in Jenkinsfile
- Structured syntax with predefined directives
- Easier to read and understand
- Recommended for 90% of use cases

### Scripted Pipeline

- Code-based with full Groovy programming capabilities
- More flexible and powerful than declarative
- Steeper learning curve, requires Groovy knowledge
- Use when declarative limitations prevent your use case

---

# Scripted Vs Declarative Jenkins Pipelines

## Declarative Pipelines

1. more recent approach 
2. easy to write and understand 
3. pipeline block is the main block 
4. **Directives** in declarative pipelines  
    1. A **directive** in a Jenkins **Declarative Pipeline** is a **top-level keyword** that controls *how the pipeline behaves* — structure, environment, agents, stages, options, tools, post actions, etc.
    2. *Think of directives as **configuration blocks** that tell Jenkins what to do, not how to script it.*
    3. examples - 
        1. pipeline - root of every Declarative Pipeline 
        2. agent - defines where the pipeline will run 
        3. environment - setting env variables for the whole pipeline or a certain stage 
        4. options - pipeline-level configuration like timeouts, retry behavior, timestamps 
        5. parameters - Defines parameters for parameterized builds.
        6. stages - Block containing multiple `stage` definitions.
        7. stage - A specific step group inside the pipeline. 
        8. steps -  The actual commands/tasks executed inside a stage. 
        9. post - Actions triggered after success, failure, always, cleanup. 
        10. tools - Automatically installs and configures tools (JDK, Maven, etc.) 
        
    4. Some directives can prompt users to input additional information
    5. **There’s an easy-to-use [generator](https://www.jenkins.io/doc/book/pipeline/getting-started/#directive-generator) that can help with creating these directives**

Sample Declarative Pipeline: 

```groovy
pipeline {
	agent { label 'linux-builder' }
	
	environment {
	    APP_NAME = "demo-service"
	    AWS_REGION = "ap-south-1"
	}
	
	parameters {
	    string(name: "GIT_BRANCH", defaultValue: "main")
	    booleanParam(name: "RUN_TESTS", defaultValue: true)
	}
	
	options {
	    timeout(time: 30, unit: 'MINUTES')
	    buildDiscarder(logRotator(numToKeepStr: '20'))
	    timestamps()
	}
	
	tools {
	    maven "Maven3"
	    jdk "Java17"
	}
	
	stages {
	
	    stage('Checkout') {
	        steps {
	            checkout scm
	        }
	    }
	
	    stage('Build') {
	        steps {
	            sh 'mvn -B clean package'
	        }
	    }
	
	    stage('Unit Tests') {
	        when {
	            expression { return params.RUN_TESTS }
	        }
	        steps {
	            sh 'mvn test'
	        }
	    }
	
	    stage('Docker Build & Push') {
	        agent { docker { image 'docker:latest' } }
	        environment {
	            DOCKER_TAG = "${env.BUILD_NUMBER}"
	        }
	        steps {
	            sh '''
	            docker build -t ${APP_NAME}:${DOCKER_TAG} .
	            docker tag ${APP_NAME}:${DOCKER_TAG} <repo>/${APP_NAME}:${DOCKER_TAG}
	            docker push <repo>/${APP_NAME}:${DOCKER_TAG}
	            '''
	        }
	    }
	
	    stage('Deploy to Kubernetes') {
	        when {
	            branch 'main'
	        }
	        steps {
	            sh '''
	            helm upgrade --install ${APP_NAME} charts/${APP_NAME} \\
	              --set image.tag=${DOCKER_TAG} \\
	              --namespace production
	            '''
	        }
	    }
	}
	
	post {
	    success {
	        echo "Deployment successful"
	    }
	    failure {
	        echo "Build failed — check logs"
	    }
	    always {
	        cleanWs()
	    }
	}
}
```

**The power of declarative pipelines comes mostly from directives.** Declarative pipelines can leverage the power of scripted pipelines by using the “script” directive. This directive will execute the lines inside as a scripted pipeline.

## Scripted Pipelines

1. **first version of the “pipeline-as-code” principle**
2. designed as a DSL build with Groovy
3. provide an outstanding level of power and flexibility
4. requires some basic knowledge of Groovy, which sometimes isn’t desirable
5. have fewer restrictions on the structure
6. only two basic blocks: “**node**” and “**stage**”. 
    1. “**node**” block specifies the machine that executes a particular pipeline
    2. “**stage**” blocks are used to group steps that, when taken together, represent a separate operation
7. **The lack of additional rules and blocks makes these pipelines quite simple to understand**

```jsx
node {
	stage('Hello world') {
		sh 'echo Hello World'
	}
}
```

1. **Think about scripted pipelines as declarative pipelines but only with stages**
2. “node” block in this case plays the role of both the “pipeline” block and the “agent” directive from declarative pipelines
3. Since it doesn’t contain directives, steps contain all the logic
4. For very simple pipelines, this can reduce the overall code
5. However, it may require additional code for some boilerplate setups, which can be resolved with directives. 
6. **More complex logic in such pipelines is usually implemented in Groovy.**

## Comparison between Declarative and Scripted Pipelines

**Case : A three-step pipeline that pulls a project from git, then tests, packages, and deploys it:**

**1. Declarative Pipeline** 

```jsx
pipeline {
	agent any
	
	tools {
	maven 'maven'
	}
	
	stages {
		stage('Test') {
			steps {
				git '[https://github.com/user/project.git](https://github.com/user/project.git)'
				sh 'mvn test'
				archiveArtifacts artifacts: 'target/surefire-reports/**'
			}
		}
		stage('Build') {
			steps {
				sh 'mvn clean package -DskipTests'
				archiveArtifacts artifacts: 'target/*.jar'
			}
		}
		stage('Deploy') {
			steps {
				sh 'echo Deploy'
			}
		}
	}
}
```

**Scripted Pipeline**

```jsx
node {
	stage('Test') {
		git '[https://github.com/user/project.git](https://github.com/user/project.git)'
		sh 'mvn test'
		archiveArtifacts artifacts: 'target/surefire-reports/**'
	}
	stage('Build') {
		sh 'mvn clean package -DskipTests'
		archiveArtifacts artifacts: 'target/*.jar'
	}
	stage('Deploy') {
		sh 'echo Deploy'
	}
}
```

Points to note: 

1. **A scripted pipeline for the same functionality looks denser** than its declarative counterpart. 
2. However, we should ensure that all the environment variables are set correctly on the server. 
3. At the same time, if there are several Maven versions, we’ll need to change them directly in the pipeline. 
4. For this, we can use a concrete path directly or an environment variable.
5. **There’s also a “withEnv” step that can be useful in scripted pipelines.** 
6. With declarative pipelines, on the other hand, it’s quite easy to change the version of the tools in Jenkins configurations.

**The previous example shows that for simple day-to-day tasks, there’s almost no difference in these approaches.** If steps can cover all the basic needs for pipelines, these two approaches will be almost identical. Declarative pipelines are still preferred as they can simplify some common logic.

## **Conclusion**

Scripted and declarative pipelines follow the same goal and use the same pipeline sub-system under the hood. The major differences between them are flexibility and syntax. **They’re just two different tools for solving the same problem, thus, we can and should use them interchangeably.**

The succinct syntax of declarative pipelines will ensure a faster and smoother entrance to this field. At the same time, scripted pipelines may provide more power to more experienced users. **In order to get the best from both worlds, we can leverage declarative pipelines with script directives.**

# Using multiple versions of tools in different pipelines

## Declarative Pipeline : Use different tool names configured in Jenkins

```jsx
stage('Build with Maven 3.6') {
tools { maven 'Maven3.6' }
steps { sh 'mvn -v' }
}
stage('Build with Maven 3.9') {
tools { maven 'Maven3.9' }
steps { sh 'mvn -v' }
}
```

Limitations: 

1. Dynamically selecting tool versions at runtime (unless via scripted block)
2. Using two versions *in the same stage*
3. Calculating tool names in variables (e.g., `maven "${params.MVN_VERSION}"` fails)

## Scripted Pipeline: Full Freedom

```jsx
node('linux') {
	def mvnVer = params.MVN_VERSION  // e.g., Maven3.6, Maven3.9
	def mvnHome = tool mvnVer
	env.PATH = "${mvnHome}/bin:${env.PATH}"
	sh "${mvnHome}/bin/mvn -v"
}
```

Benefits: 

1. Total control
2. Dynamic version switching
3. Multiple versions in the same stage
4. Full Groovy freedom

Solution: Hybrid Approach - Declarative Pipeline with **Script** directives (blocks)

```jsx
pipeline {
	agent { 
		label 'linux' 
	}
	
	parameters {
		choice(name: 'MVN_VERSION', choices: ['Maven3.6', 'Maven3.9'])
	}
	
	options {
		timestamps()
		timeout(time: 20, unit: 'MINUTES')
	}
	
	stages {
		stage('Checkout') {
			steps {
				checkout scm
			}
		}
		stage('Build with dynamic Maven version') {
			steps {
				script {
					def mvnHome = tool params.MVN_VERSION
					env.PATH = "${mvnHome}/bin:${env.PATH}"
					sh "${mvnHome}/bin/mvn -v"
					sh "${mvnHome}/bin/mvn clean package"
				}
			}
		}
	}
	post {
		success { echo "OK" }
		failure { echo "FAILED" }
	}
}
```

---

# 3. Jenkins Jobs & Build Triggers

## What is Jenkins Job?

A Jenkins job (or project) is a configured task that performs a predefined set of actions. It is the fundamental building block of CI/CD automation in Jenkins.

**Types of Jobs:**
- **Freestyle Job**: UI-configured, no code required (legacy)
- **Pipeline Job**: Code-based via Jenkinsfile (modern, recommended)
- **Multibranch Pipeline**: Automatically creates pipelines for each Git branch
- **Parameterized Job**: Accepts user input parameters during execution

---

## Jenkinsfile & Pipeline as Code

### What is Jenkinsfile?

A Jenkinsfile is a text file containing the definition of a Jenkins pipeline. It is checked into source control alongside application code, enabling version-controlled CI/CD workflows.

**Benefits:**
- Tracked in Git alongside code changes
- Peer-reviewed via pull requests before execution
- Reproducible across environments
- Can be branched/versioned with code

---

## How Many Ways Are There to Trigger Jenkins Build?

| **Method** | **Description** | **Configuration** |
| --- | --- | --- |
| **Manual Trigger** | Click "Build Now" button | No configuration needed |
| **Poll SCM** | Jenkins checks repository periodically | `triggers { pollSCM('H/5 * * * *') }` |
| **Webhooks** | Git provider sends notification | Configure in Git (GitHub, GitLab, Bitbucket) |
| **Scheduled (CRON)** | Runs at specified times | `triggers { cron('H 2 * * *') }` |
| **Upstream/Downstream** | Chain jobs together | Include downstream job name |
| **API Calls** | External systems trigger Jenkins | REST API endpoint |

---

## Poll SCM and Webhook

| **Aspect** | **Poll SCM** | **Webhook** |
| --- | --- | --- |
| **Trigger Type** | Pull-based (Jenkins pulls) | Push-based (Git pushes notification) |
| **Speed** | Slower (scheduled checks) | Instant (immediate notification) |
| **Resource Usage** | Higher (periodic polling) | Lower (only on events) |
| **Configuration** | In Jenkins UI | In Git provider settings |
| **Best For** | Simple setups, legacy systems | Modern CI/CD, real-time builds |

---

# 4. Jenkins Credentials & Security

## Credential Types

Jenkins Credentials plugin supports:

- **Username with Password**: Basic authentication
- **SSH Username with Private Key**: Key-based auth
- **AWS Credentials**: AWS access key + secret
- **Secret Text**: Encrypted plaintext (tokens, API keys)
- **Secret File**: Encrypted files (certificates
, keyfiles)
- **Jenkins Build Token**: API tokens
- **X.509 Certificates**: Digital certificates
- **Vault Credentials**: HashiCorp Vault tokens

---

## Credential Scopes

| **Scope** | **Visibility** | **Best For** |
| --- | --- | --- |
| **Global** | All jobs, folders, users | General credentials, shared libraries |
| **System** | Jenkins system processes only | Admin tasks, master-slave communication |

---

## How to Secure Jenkins?

**Best Practices:**
- Use Credentials plugin for all secrets
- Never hardcode secrets in Jenkinsfiles
- Rotate credentials regularly
- Use credential scopes appropriately
- Enable RBAC (Role-Based Access Control)
- Use SSO (LDAP, OAuth) for authentication
- Keep Jenkins and plugins updated
- Run Jenkins in secure network
- Enable HTTPS
- Audit credential usage

---

# 5. Jenkins Shared Library

### What is Shared Library?

A **Shared Library** is a Git repository containing reusable Groovy code shared across multiple Jenkins pipelines.

**Benefits:**
- **Reusability**: DRY principle - write once, use everywhere
- **Consistency**: Enforce standards across teams
- **Maintainability**: Update logic centrally
- **Scalability**: Simplify complex pipelines

### Using Shared Library

```groovy
@Library('shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    myLibrary.buildApp()
                }
            }
        }
    }
}
```

---

# 6. Advanced Topics

## Dynamic Agent Provisioning with Kubernetes

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: maven
                image: maven:3.8.6
                tty: true
            '''
        }
    }
    stages {
        stage('Build') { steps { sh 'mvn clean package' } }
    }
}
```

---

## Stash & Unstash for Artifact Transfer

**Stash** temporarily stores files to master:
```groovy
stash name: 'build-artifacts', includes: 'target/**'
```

**Unstash** retrieves stashed files:
```groovy
unstash 'build-artifacts'
```

**Use Case**: Transfer artifacts between different agents or stages.

---

## Build Executors

- **Definition**: Concurrent build slots on an agent
- **Default**: 2 executors per agent
- **Configuration**: Manage Jenkins → System → Executors
- **Total Capacity**: Sum across all agents

---

## Key Differences: Continuous Integration vs Delivery vs Deployment

| **Practice** | **Definition** | **Manual Step** |
| --- | --- | --- |
| **CI** | Automated build & test on every commit | Required for deployment |
| **CD (Delivery)** | Auto-prepare code for production | Manual button click to deploy |
| **CDP (Deployment)** | Auto-deploy to production | None - fully automated |

---

# Installation Methods

| **Method** | **Platform** | **Best For** |
| --- | --- | --- |
| **Docker** | Container | Dev/test environments |
| **Kubernetes** | Cloud-native | Production at scale |
| **APT/YUM** | Linux | Enterprise servers |
| **WAR File** | Any Java environment | Flexible deployment |
| **Cloud Marketplace** | AWS/Azure/GCP | One-click cloud setup |

---

## Summary

This comprehensive guide covers Jenkins fundamentals for senior DevOps engineers including master-slave architecture, declarative vs scripted pipelines, jobs & triggers, credential management, shared libraries, and advanced integrations with Kubernetes and AWS. Master these concepts for production-grade CI/CD systems.