# CI/CD Questions

## 1. I have a microservice and want to build a container. How to deploy this as part of the pipeline?

### Answer:

Building and deploying a containerized microservice involves several stages in the CI/CD pipeline:

**Build Stage:**
- Use multi-stage Docker builds to minimize image size and improve security
- Implement static code analysis (SonarQube, Checkmarx) before building
- Use Docker best practices: minimal base images (Alpine, distroless), layering for caching, explicit version pinning

**Example Dockerfile:**
```dockerfile
# Stage 1: Build
FROM maven:3.8-openjdk-17 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM openjdk:17-jdk-slim
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Push to Registry:**
- Push images to Docker registries (ECR, Harbor, ACR, Docker Hub)
- Tag images with semantic versioning and git commit hash
- Enable image scanning for vulnerabilities (Trivy, Snyk)

**Deployment:**
- Use IaC tools (Terraform, CloudFormation) to provision infrastructure
- Deploy to Kubernetes, ECS, or other container orchestration platforms
- Implement health checks and readiness probes
- Use deployment strategies: Blue-Green, Canary, Rolling updates

**Example Jenkins Pipeline:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }
        
        stage('Push') {
            steps {
                sh 'docker push myrepo/myapp:${BUILD_NUMBER}'
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'kubectl set image deployment/myapp myapp=myrepo/myapp:${BUILD_NUMBER}'
            }
        }
    }
}
```

---

## 2. Have you used code coverage tool and used in the pipeline?

### Answer:

Yes, code coverage is critical for maintaining code quality and identifying untested code paths.

**Code Coverage Tools Used:**

1. **JaCoCo (Java Code Coverage)** - For Java applications
   - Integrates with Maven and Gradle
   - Generates HTML and XML reports
   - Can enforce minimum coverage thresholds

2. **Sonar/SonarQube** - Multi-language coverage and quality gates
3. **Cobertura** - Legacy but still widely used for Java
4. **Istanbul/NYC** - For JavaScript/Node.js applications

**Pipeline Integration:**

```groovy
pipeline {
    agent any
    
    stages {
        stage('Test & Coverage') {
            steps {
                sh 'mvn clean test jacoco:report'
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn sonar:sonar -Dsonar.java.coverage.plugin=jacoco'
                    }
                    
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
    
    post {
        always {
            publishHTML([
                reportDir: 'target/site/jacoco',
                reportFiles: 'index.html',
                reportName: 'JaCoCo Coverage Report'
            ])
        }
    }
}
```

**Best Practices:**
- Set minimum coverage thresholds (70-80% for development, 85%+ for production code)
- Exclude generated code, test classes, and boilerplate
- Track coverage trends over time
- Make quality gates fail the build if thresholds aren't met
- Combine with mutation testing (PIT, Stryker) for better quality assessment

---

## 3. What is your experience in Groovy?

### Answer:

Groovy is a dynamic language that runs on the JVM and is the primary language for Jenkins pipeline scripting.

**Groovy Experience:**

1. **Jenkins Declarative & Scripted Pipelines:**
   - Declarative pipelines use Groovy-based DSL
   - Scripted pipelines use full Groovy capabilities

2. **Key Groovy Features Used:**
   - String interpolation: `"Build number: ${BUILD_NUMBER}"`
   - Closures for custom functions
   - Dynamic typing and metaprogramming
   - XML/JSON parsing for configuration management

3. **Common Patterns:**

```groovy
// Conditional logic
if (env.BRANCH_NAME == 'main') {
    stage('Deploy to Production') {
        // deploy
    }
}

// Loops
for (service in ['auth', 'payment', 'order']) {
    build job: "build-${service}"
}

// Error handling
try {
    sh 'docker build -t myapp .'
} catch (Exception e) {
    echo "Build failed: ${e.message}"
    throw e
}

// Custom functions
def deployToK8s(environment, version) {
    sh """
        kubectl set image deployment/myapp \
        myapp=myrepo/myapp:${version} \
        -n ${environment}
    """
}
```

4. **Challenges Overcome:**
   - Performance issues with large scripts (mitigated by using shared libraries)
   - Debugging complex pipeline logic (used Jenkins Script Console)
   - Testing Groovy code (implemented with JUnit and mock frameworks)

---

## 4. What are libraries we use in Jenkins?

### Answer:

Jenkins libraries are crucial for code reuse, standardization, and reducing configuration drift.

**Common Jenkins Libraries:**

1. **Pipeline Libraries:**
   - Jenkins built-in Pipeline shared libraries
   - BlueOcean for UI/UX improvements
   - Pipeline plugins ecosystem

2. **Integration Libraries:**
   - Docker plugin/CLI integration
   - Kubernetes plugin for cluster interactions
   - CloudBees/AWS plugins for cloud integrations

3. **Testing & Analysis Libraries:**
   - JaCoCo (Java code coverage)
   - SonarQube integration
   - Selenium for integration testing
   - JUnit for unit testing

4. **Build Tools Libraries:**
   - Maven plugin
   - Gradle plugin
   - npm/Yarn integration

5. **Notification & Monitoring:**
   - Slack plugin for notifications
   - Email plugin
   - PagerDuty/Splunk integration
   - Prometheus metrics

6. **Security Libraries:**
   - OWASP Dependency-Check
   - Snyk for vulnerability scanning
   - HashiCorp Vault for secrets management
   - TweetNaCl for encryption

**Example Library Usage:**
```groovy
@Library('shared-pipeline-library') _

pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                script {
                    buildMicroservice('java', 'myapp')
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    runTests('unit')
                }
            }
        }
    }
}
```

---

## 5. Shared library and common library - explain in details.

### Answer:

Shared libraries are centralized repositories of reusable pipeline code, reducing duplication and ensuring consistency across pipelines.

**Shared Library Structure:**

```
shared-library/
├── vars/
│   ├── buildDocker.groovy
│   ├── deployToK8s.groovy
│   ├── runTests.groovy
│   └── notifySlack.groovy
├── src/
│   └── com/
│       └── example/
│           └── PipelineUtils.groovy
└── resources/
    └── helm-values.yaml
```

**Implementation Example:**

**vars/buildDocker.groovy:**
```groovy
def call(String imageName, String version, String registryUrl) {
    stage('Build Docker Image') {
        sh """
            docker build \
            -t ${registryUrl}/${imageName}:${version} \
            -t ${registryUrl}/${imageName}:latest \
            .
        """
    }
}
```

**vars/deployToK8s.groovy:**
```groovy
def call(String namespace, String deployment, String image, String tag) {
    stage("Deploy to ${namespace}") {
        sh """
            kubectl set image deployment/${deployment} \
            ${deployment}=${image}:${tag} \
            -n ${namespace}
            
            kubectl rollout status deployment/${deployment} -n ${namespace}
        """
    }
}
```

**src/com/example/PipelineUtils.groovy:**
```groovy
package com.example

class PipelineUtils {
    static String getGitCommitHash() {
        return sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }
    
    static String getBuildVersion() {
        return "${env.BUILD_NUMBER}-${getGitCommitHash()}"
    }
    
    static void notifySlack(String message, String channel) {
        // Slack notification logic
    }
}
```

**Jenkinsfile Using Shared Library:**
```groovy
@Library('shared-pipeline-library') _

import com.example.PipelineUtils

pipeline {
    agent any
    
    environment {
        VERSION = "${PipelineUtils.getBuildVersion()}"
        REGISTRY = 'myregistry.azurecr.io'
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    buildDocker('myapp', VERSION, REGISTRY)
                }
            }
        }
        
        stage('Push') {
            steps {
                sh "docker push ${REGISTRY}/myapp:${VERSION}"
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    deployToK8s('production', 'myapp', "${REGISTRY}/myapp", VERSION)
                }
            }
        }
    }
    
    post {
        always {
            script {
                PipelineUtils.notifySlack("Pipeline Complete", "#devops")
            }
        }
    }
}
```

**Benefits:**
- **Consistency**: All teams follow same patterns
- **Maintainability**: Update once, changes apply everywhere
- **Security**: Centralized secret management
- **Performance**: Reduced duplication improves build times
- **Scalability**: Easy to add new services

---

## 6. Let's say pipeline failed. What are the troubleshooting steps for this?

### Answer:

Systematic troubleshooting is essential to identify root causes and restore CI/CD pipeline health.

**Troubleshooting Methodology:**

**Step 1: Check Pipeline Logs**
```
Jenkins UI → Build Details → Console Output
Look for:
- Exception stack traces
- Command exit codes
- Environment variable values
```

**Step 2: Identify Failure Stage**
- Determine which stage failed (Build, Test, Deploy)
- Check timestamps to correlate with infrastructure events

**Step 3: Environmental Issues**
```bash
# Check agent connectivity
ssh agent-node "hostname && docker ps"

# Verify agent has required tools
docker --version
kubectl version
mvn --version

# Check disk space
df -h

# Memory/CPU usage
top
free -h
```

**Step 4: Dependency & Network Issues**
```bash
# Test artifact repository connectivity
curl -I https://nexus.example.com/repository/maven-central/

# Check Docker registry access
docker login myregistry.azurecr.io

# Verify Kubernetes connectivity
kubectl cluster-info
kubectl get nodes

# DNS resolution
nslookup artifactory.company.com
```

**Step 5: Code-Level Issues**
```groovy
pipeline {
    agent any
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    try {
                        sh 'mvn clean package'
                    } catch (Exception e) {
                        echo "Build failed: ${e}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
    }
    
    post {
        failure {
            sh 'echo "Collecting diagnostic information..."'
            sh 'docker ps -a'
            sh 'mvn dependency:tree > dependency-tree.txt'
            archiveArtifacts artifacts: '**/*.log,dependency-tree.txt'
        }
    }
}
```

**Common Failure Scenarios & Solutions:**

| Failure | Cause | Solution |
|---------|-------|----------|
| `docker: command not found` | Docker not installed on agent | Install Docker on agent or use docker agent image |
| `Connection refused` | Service not running | Check service status, restart, verify port binding |
| `Permission denied` | Insufficient permissions | Add user to docker group, adjust IAM roles |
| `Timeout` | Process hangs | Increase timeout, identify hanging process, optimize code |
| `Out of memory` | Insufficient resources | Increase agent memory, optimize build, use smaller images |
| `Network timeout` | Connectivity issues | Check firewall, DNS, proxy, retry with exponential backoff |

**Step 6: Real-Time Monitoring**
```bash
# Watch build progress in real-time
tail -f /var/log/jenkins/jenkins.log

# Monitor resource usage
watch -n 1 'docker stats'

# Check Kubernetes pod logs
kubectl logs -f deployment/jenkins -n jenkins
```

**Step 7: Implement Resilience**
```groovy
def retryWithBackoff(Closure block, int maxRetries = 3) {
    for (int i = 0; i < maxRetries; i++) {
        try {
            return block()
        } catch (Exception e) {
            if (i == maxRetries - 1) throw e
            int waitTime = Math.pow(2, i).toInteger() * 1000
            echo "Retry ${i+1}/${maxRetries} after ${waitTime}ms"
            sleep(time: waitTime, unit: 'MILLISECONDS')
        }
    }
}

stages {
    stage('Deploy') {
        steps {
            script {
                retryWithBackoff {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
}
```

---

## 7. How is CI/CD implemented with shared library? Explain in details.

### Answer:

Shared library implementation is a strategic approach to standardize and scale CI/CD across an organization.

**Architecture & Setup:**

**1. Repository Structure:**
```
jenkins-shared-library/
├── .git/
├── README.md
├── vars/                           # Global variables (DSL methods)
│   ├── buildApp.groovy
│   ├── testApp.groovy
│   ├── deployApp.groovy
│   ├── scanCode.groovy
│   └── notifyTeam.groovy
├── src/                            # Classes & utilities
│   └── com/
│       └── company/
│           ├── KubernetesHelper.groovy
│           ├── DockerHelper.groovy
│           ├── SlackNotifier.groovy
│           └── BuildUtils.groovy
└── resources/                      # Static resources
    ├── templates/
    │   ├── helm-values-dev.yaml
    │   ├── helm-values-prod.yaml
    │   └── k8s-deployment.yaml
    └── scripts/
        ├── health-check.sh
        └── rollback.sh
```

**2. Jenkins Classification Configuration:**

In Jenkins UI: `Manage Jenkins → Global Pipeline Libraries`

```groovy
// Jenkins Configuration

Library {
    name = 'shared-pipeline-library'
    description = 'Centralized pipeline library'
    defaultVersion = 'main'
    implicit = false
    allowVersionOverride = true
    
    remote {
        url = 'https://github.com/company/jenkins-shared-library.git'
        credentialsId = 'github-credentials'
    }
    
    modernSCM {
        github {
            repoOwner = 'company'
            repository = 'jenkins-shared-library'
            credentialsId = 'github-token'
        }
    }
}
```

**3. Implementing Shared Library Functions:**

**vars/buildApp.groovy:**
```groovy
def call(Map config) {
    stage('Build') {
        echo "Building ${config.language} application..."
        
        switch(config.language) {
            case 'java':
                sh "mvn clean package -DskipTests"
                break
            case 'python':
                sh "pip install -r requirements.txt && python setup.py build"
                break
            case 'nodejs':
                sh "npm install && npm run build"
                break
        }
    }
}
```

**vars/testApp.groovy:**
```groovy
def call(Map config) {
    stage('Test') {
        echo "Running tests with coverage..."
        
        try {
            switch(config.language) {
                case 'java':
                    sh "mvn test jacoco:report"
                    break
                case 'python':
                    sh "pytest --cov=src --cov-report=html"
                    break
                case 'nodejs':
                    sh "npm test -- --coverage"
                    break
            }
        } catch (Exception e) {
            echo "Tests failed: ${e.message}"
            throw e
        }
    }
}
```

**vars/scanCode.groovy:**
```groovy
def call(Map config) {
    stage('Code Quality Analysis') {
        withSonarQubeEnv('SonarQube') {
            sh """
                sonar-scanner \
                -Dsonar.projectKey=${config.projectKey} \
                -Dsonar.sources=src \
                -Dsonar.host.url=\${SONAR_HOST_URL} \
                -Dsonar.login=\${SONAR_AUTH_TOKEN}
            """
        }
        
        waitForQualityGate abortPipeline: true
    }
}
```

**vars/deployApp.groovy:**
```groovy
def call(Map config) {
    stage("Deploy to ${config.environment}") {
        script {
            echo "Deploying to ${config.environment}..."
            
            withCredentials([file(credentialsId: "kubeconfig-${config.environment}", 
                                  variable: 'KUBECONFIG')]) {
                sh """
                    kubectl apply -f deployment.yaml -n ${config.namespace}
                    kubectl rollout status deployment/${config.appName} -n ${config.namespace}
                    kubectl get pods -n ${config.namespace}
                """
            }
        }
    }
}
```

**src/com/company/KubernetesHelper.groovy:**
```groovy
package com.company

class KubernetesHelper {
    static void healthCheck(String namespace, String deployment) {
        def cmd = """
            kubectl get deployment ${deployment} -n ${namespace} \
            -o jsonpath='{.status.conditions[0].status}'
        """
        def status = "true".toString()  // expected: "True"
        
        if (status != "true") {
            throw new Exception("Deployment not healthy")
        }
    }
    
    static void rollback(String namespace, String deployment) {
        sh "kubectl rollout undo deployment/${deployment} -n ${namespace}"
    }
    
    static String getPodLogs(String namespace, String pod) {
        return sh(
            script: "kubectl logs ${pod} -n ${namespace}",
            returnStdout: true
        ).trim()
    }
}
```

**4. Using Shared Library in Jenkinsfile:**

```groovy
@Library('shared-pipeline-library@main') _

import com.company.KubernetesHelper
import com.company.SlackNotifier

pipeline {
    agent any
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        string(name: 'VERSION', description: 'Image version to deploy')
    }
    
    environment {
        REGISTRY = 'myregistry.azurecr.io'
        APP_NAME = 'my-microservice'
        BUILD_VERSION = "${env.BUILD_NUMBER}-${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    buildApp(language: 'java')
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    testApp(language: 'java')
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                script {
                    scanCode(projectKey: env.APP_NAME)
                }
            }
        }
        
        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${REGISTRY}/${APP_NAME}:${BUILD_VERSION} .
                        docker push ${REGISTRY}/${APP_NAME}:${BUILD_VERSION}
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    deployApp([
                        environment: params.ENVIRONMENT,
                        appName: env.APP_NAME,
                        namespace: "default",
                        version: env.BUILD_VERSION
                    ])
                    
                    KubernetesHelper.healthCheck('default', env.APP_NAME)
                }
            }
        }
    }
    
    post {
        success {
            script {
                SlackNotifier.sendMessage(
                    channel: '#deployments',
                    message: "✅ ${APP_NAME} deployed successfully to ${ENVIRONMENT}"
                )
            }
        }
        
        failure {
            script {
                KubernetesHelper.rollback('default', env.APP_NAME)
                SlackNotifier.sendMessage(
                    channel: '#deployments',
                    message: "❌ Deployment failed, rolling back"
                )
            }
        }
    }
}
```

**Benefits of Shared Library Implementation:**
- **Standardization**: Enforces consistent practices
- **Maintenance**: Single source of truth for pipeline patterns
- **Scalability**: Support hundreds of microservices
- **Security**: Centralized credential management
- **Versioning**: Track library changes with Git
- **Team Velocity**: Faster pipeline creation for new services

---

## 8. What improvements have you done in the CI/CD pipeline?

### Answer:

Throughout my 5-10 years in DevOps, I've implemented several impactful improvements:

**1. Pipeline Parallelization**
- **Before**: Sequential stages (Build → Test → Deploy) = 45 minutes
- **After**: Parallel test execution, multi-branch builds = 12 minutes
- **Implementation**: Used Jenkins pipeline parallel blocks for independent stages

```groovy
stage('Parallel Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify'
            }
        }
        stage('Code Analysis') {
            steps {
                sh 'sonar-scanner'
            }
        }
    }
}
```

**2. Caching Strategy**
- **Implementation**: Docker layer caching, Maven repository caching, dependency caching
- **Impact**: Reduced build times by 40%, decreased artifact repository load

```groovy
stage('Build') {
    steps {
        script {
            sh '''
                docker build \
                --cache-from myregistry/myapp:latest \
                -t myregistry/myapp:${BUILD_NUMBER} .
            '''
        }
    }
}
```

**3. Automated Rollback Mechanism**
- **Feature**: Detects failed deployments and automatically reverts to previous version
- **Implementation**: Health checks + Kubernetes rollout undo on failure

```groovy
post {
    failure {
        script {
            sh 'kubectl rollout undo deployment/myapp'
            sh 'kubectl wait --for=condition=progressing=true deployment/myapp --timeout=120s'
        }
    }
}
```

**4. Multi-Environment Promotion Pipeline**
- **Workflow**: Dev → QA → Staging → Production with approval gates
- **Impact**: Reduced production incidents by 70%

```groovy
stage('Production Approval') {
    when {
        branch 'main'
    }
    steps {
        input(
            message: 'Approve production deployment?',
            ok: 'Deploy',
            submitter: 'devops-team'
        )
        deployApp(environment: 'production')
    }
}
```

**5. Observability & Monitoring**
- **Prometheus metrics**: Build duration, success rate, deployment frequency
- **Integration**: ELK stack for centralized logging
- **Dashboard**: Real-time pipeline health visualization

```groovy
stage('Metrics') {
    steps {
        sh '''
            curl -X POST http://prometheus:9091/metrics/job/jenkins \
            -d "build_duration_seconds ${BUILD_DURATION}"
        '''
    }
}
```

**6. Container Image Optimization**
- **Before**: 800MB images with security vulnerabilities
- **After**: 60MB distroless images with zero vulnerabilities
- **Implementation**: Multi-stage builds, base image pinning, vulnerability scanning

**Impact**: Faster deployments (80% reduction, improved security)

**7. Blue-Green Deployment Strategy**
- **Benefit**: Zero-downtime deployments with instant rollback capability
- **Implementation**: Two identical production environments running simultaneously

```groovy
stage('Deploy Blue-Green') {
    steps {
        sh '''
            # Deploy to inactive environment (Green)
            kubectl apply -f deployment-green.yaml
            
            # Run smoke tests
            ./smoke-tests.sh green
            
            # Switch traffic
            kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'
            
            # Keep Blue running for instant rollback
        '''
    }
}
```

**8. Automated Secrets Rotation**
- **Implementation**: HashiCorp Vault integration with automatic secret rotation every 30 days
- **Impact**: Enhanced security without manual intervention

```groovy
stage('Rotate Secrets') {
    steps {
        withVault([
            vaultSecrets: [
                [path: 'secret/jenkins', secretValues: [
                    [envVar: 'DB_PASSWORD', vaultKey: 'db_password']
                ]]
            ]
        ]) {
            sh 'kubectl create secret generic db-creds --from-literal=password=${DB_PASSWORD} --dry-run=client -o yaml | kubectl apply -f -'
        }
    }
}
```

**9. Load Testing in Pipeline**
- **Tool**: Apache JMeter / Gatling
- **Benefit**: Catch performance regressions before production
- **Threshold**: Fail deployment if latency increases >10% or error rate >1%

```groovy
stage('Performance Testing') {
    steps {
        sh 'jmeter -n -t load-test.jmx -l results.jtl'
        sh '''
            if grep -q "errorCount=0" results.jtl; then
                echo "Performance test passed"
            else
                exit 1
            fi
        '''
    }
}
```

**10. GitOps Implementation**
- **Tool**: ArgoCD / Flux for declarative deployments
- **Benefit**: Infrastructure as code, audit trail, version control for all changes
- **Impact**: Eliminated configuration drift, improved compliance

```groovy
stage('GitOps Sync') {
    steps {
        sh '''
            git clone https://github.com/company/ArgoCD-configs.git
            cd ArgoCD-configs
            git checkout -b release/${BUILD_NUMBER}
            
            # Update image version
            sed -i "s|image:.*|image: myregistry/myapp:${BUILD_NUMBER}|" app/deployment.yaml
            
            git add app/deployment.yaml
            git commit -m "Release: ${BUILD_NUMBER}"
            git push origin release/${BUILD_NUMBER}
            
            # ArgoCD automatically detects and syncs changes
        '''
    }
}
```

**Quantified Results:**
- **Build Time**: 45 min → 12 min (73% reduction)
- **Deployment Frequency**: 2x/week → 10x/day (5x increase)
- **Production Incidents**: Reduced by 70%
- **MTTR (Mean Time To Recovery)**: 2 hours → 10 minutes
- **Infrastructure Cost**: Reduced by 40% through optimized resource utilization