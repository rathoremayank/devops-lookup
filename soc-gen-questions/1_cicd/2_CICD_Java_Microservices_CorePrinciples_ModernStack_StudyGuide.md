# Deep Dive: Core Principles, Modern Stack, and Pipeline Architecture
**Part 2 of Java Microservices CI/CD Study Guide**

---

# Core CI/CD Principles for Java Microservices

## Textual Deep Dive

### Internal Working Mechanism

The core CI/CD principles for Java microservices establish a contract between developers and operations: **every code change produces a deployable artifact without manual intervention**. This requires several interconnected mechanisms:

#### 1. Independence and Decoupling

In a microservices architecture, independence is foundational. Unlike monoliths where a single deployment contains all components, each microservice must be buildable, testable, and deployable independently.

**Mechanism:**
- **Source control isolation**: Each microservice in separate repository or bounded folder within monorepo
- **Dependency declaration**: pom.xml (Maven) or build.gradle (Gradle) explicitly declare external dependencies
- **Version management**: Each service has independent version number (semantic versioning: major.minor.patch)
- **Artifact separation**: Each service produces distinct Docker image artifact identified by unique digest

**Example Flow:**
```
Developer commits to order-service/src/main
    ↓
Webhook triggers CI pipeline for order-service ONLY
    ↓
Tests run in isolated environment
    ↓
If tests pass → order-service:1.2.3-abc789f created
    ↓
Other services completely unaffected by this change
```

This prevents the "deployment coordination" problem where changes to payment-service delay deployment of order-service.

#### 2. Immutable Artifacts and Reproducibility

An immutable artifact is one that never changes once created. For Java microservices, this means:

**Building Once, Deploying Everywhere:**
```
Source Code (commit abc123) → Build Once → Docker image@sha256:xyz789
    ↓
Image@sha256:xyz789 → Promote to Staging (same bytes)
    ↓
Image@sha256:xyz789 → Promote to Production (same bytes)
    ↓
No rebuilding between environments
```

**Why This Matters:**
- **Reproducibility**: Same artifact tested in staging behaves identically in production
- **Forensics**: Exact artifact version traceable to specific git commit
- **Rollback**: Deploy previous image without rebuild (instant recovery)
- **Resource efficiency**: Build once, not three times per service per day

**Implementation:**
```dockerfile
# Dockerfile - Multi-stage ensures small production image
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY . .
RUN mvn clean package -DskipTests -B

# Production stage - tiny runtime image
FROM eclipse-temurin:21-jre-noble
LABEL maintainer="platform-team@company.com"

# Copy SBOM and image metadata
COPY --from=builder /build/target/sbom.json /app/sbom.json
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=200", "-jar", "app.jar"]
```

#### 3. Shift-Left Testing Architecture

Shift-left means moving testing earlier in the pipeline. The cost of fixing a bug:
- During development: 1 hour, $100
- After commit: 4 hours, $400 (build + test + fix cycles)
- In production: 40 hours, $4000+ (customer impact + incident response)

**Testing Layers (from left to right):**

```
Developer    │ CI/CD Pipeline         │ Staging         │ Production
Workstation  │                        │ Environment     │ Environment
             │                        │                 │
   ↓         │    ↓                   │    ↓            │    ↓
[Local]      │ [Commit] [Build] [Test] [Deploy] [Validate] → [Live]
Unit Tests   │  Lint      Unit      SAST  Smoke   E2E
(pre-commit) │  Secrets   Mocking    Deps  Tests   Tests
             │  Format    Spy               Perf    Pen
             │                             Bench   Test
```

**Pre-commit Testing (Developer Workstation):**
```bash
# Git hook runs before commit is created
./gradlew check
  - Runs linter (spotbugs)
  - Unit tests (JUnit 5)
  - Code coverage (Jacoco, fail if <70%)
  - License scanning

If any check fails → commit rejected
```

**Commit Stage (GitHub Actions, 5-minute SLA):**
```yaml
# .github/workflows/commit-stage.yml
name: Commit Stage
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      
      - name: Run linting and formatting checks
        run: mvn spotbugs:check checkstyle:check

      - name: Run unit tests with coverage
        run: mvn clean test -DskipIntegration

      - name: Publish test results
        uses: dorny/test-reporter@v1
        if: success() || failure()
```

**Build Stage (Container Image Creation):**
- Unit tests already passed
- Create container image
- Scan image for vulnerabilities (Trivy, Snyk)
- Store SBOM (Software Bill of Materials)
- Push to registry

**Integration Test Stage (Kubernetes Test Containers):**
```java
// Using Testcontainers for integration testing
@Testcontainers
@DataJpaTest
class OrderRepositoryIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = 
        new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");
    
    @Test
    void shouldFindOrderByCustomerId() {
        // Real database, real schema
        Order order = repository.findByCustomerId(123L);
        assertThat(order).isNotNull();
    }
}
```

#### 4. Environment Parity

Staging environment must be identical to production except for data.

**Parity Checklist:**
```
┌─────────────────────────────────────┬──────────┬────────────┐
│ Component                           │ Staging  │ Production │
├─────────────────────────────────────┼──────────┼────────────┤
│ Kubernetes Version                  │ 1.28.x   │ 1.28.x     │
│ Pod Resource Requests/Limits        │ Same     │ Same       │
│ Container Runtime                   │ containerd│ containerd│
│ VM Instance Type                    │ t3.large │ t3.large   │
│ Pod Disruption Budget               │ Yes      │ Yes        │
│ Network Policies                    │ Enabled  │ Enabled    │
│ Service Mesh (Istio)               │ v1.18.x  │ v1.18.x    │
│ Ingress Controller                  │ Nginx    │ Nginx      │
│ Database Engine & Version           │ PostgreSQL 15 │ PostgreSQL 15 │
│ RDS Subnet Group                    │ Same     │ Same       │
│ Multi-AZ Replication               │ Yes      │ Yes        │
│ Secrets Management                  │ Vault    │ Vault      │
│ Logging Stack                       │ ELK (v8) │ ELK (v8)   │
│ Monitoring Stack                    │ Prometheus│ Prometheus │
│ Service Mesh Sidecar Configuration  │ Identical│ Identical  │
└─────────────────────────────────────┴──────────┴────────────┘
```

**Terraform Implementation for Parity:**

```hcl
# environments/shared.tf - Reusable configurations
variable "environment" {
  type = string
}

variable "cluster_config" {
  type = object({
    version              = string
    node_count          = number
    instance_type       = string
  })
}

# environments/staging.tfvars
environment = "staging"
cluster_config = {
  version       = "1.28.5"
  node_count    = 3
  instance_type = "t3.large"
}

# environments/production.tfvars
environment = "production"
cluster_config = {
  version       = "1.28.5"
  node_count    = 3
  instance_type = "t3.large"  # Same as staging!
}

# EKS cluster defined once, instantiated in both environments
resource "aws_eks_cluster" "main" {
  name            = "${var.environment}-cluster"
  version         = var.cluster_config.version
  
  vpc_config {
    subnet_ids              = data.aws_subnets.main.ids
    endpoint_private_access = true
  }
}

resource "aws_autoscaling_group" "nodes" {
  name             = "${aws_eks_cluster.main.name}-nodes"
  desired_capacity = var.cluster_config.node_count
  min_size         = var.cluster_config.node_count
  
  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }
}
```

#### 5. Automated Rollbacks and Recovery

Automated rollback means the system can revert to a known-good state without human intervention.

**Rollback Triggers:**
```
Deployment → Monitor SLIs for 5 minutes
    ↓
If Error Rate > 1% → Automatic Rollback
If P99 Latency > 500ms → Automatic Rollback
If Pod CrashLoopBackOff → Automatic Rollback
If DependencyUnavailable → Automatic Rollback
    ↓
Revert to Previous Image
```

**Implementation with ArgoCD and Prometheus:**

```yaml
# ArgoCD Application with automated rollback based on metrics
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: order-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/helm-charts
    targetRevision: main
    path: charts/order-service
    helm:
      values: |
        image:
          tag: "1.2.3"  # Git-driven version
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  # Sync policy: automatic, with health assessment
  syncPolicy:
    automated:
      prune: true      # Remove resources not in Git
      selfHeal: true   # Re-sync if drift detected
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  # Health assessment via metrics
  info:
  - name: 'Metrics Dashboard'
    value: 'https://prometheus.example.com/graph?expr=...'
```

**Rollback Automation Script:**

```bash
#!/usr/bin/env bash
# rollback.sh - triggered by monitoring alert

set -euo pipefail

SERVICE=$1
NAMESPACE=${2:-production}
METRICS_THRESHOLD_ERROR_RATE=1.0
METRICS_THRESHOLD_LATENCY=500

# Get current deployment image
CURRENT_IMAGE=$(kubectl get deployment $SERVICE -n $NAMESPACE \
  -o jsonpath='{.spec.template.spec.containers[0].image}')

# Get previous image from metadata annotation
PREVIOUS_IMAGE=$(kubectl get deployment $SERVICE -n $NAMESPACE \
  -o jsonpath='{.metadata.annotations.previous-image}')

echo "Current: $CURRENT_IMAGE"
echo "Previous: $PREVIOUS_IMAGE"

# Check metrics to confirm rollback decision
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total%7Binstatus%3D%225xx%22%7D%5B5m%5D)" \
  | jq '.data.result[0].value[1]' | bc)

LATENCY_P99=$(curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99, http_request_duration_seconds)" \
  | jq '.data.result[0].value[1]' | bc)

echo "Error Rate: $ERROR_RATE%"
echo "P99 Latency: ${LATENCY_P99}ms"

if (( $(echo "$ERROR_RATE > $METRICS_THRESHOLD_ERROR_RATE" | bc -l) )); then
    echo "ERROR_RATE $ERROR_RATE > $METRICS_THRESHOLD_ERROR_RATE - ROLLING BACK"
    
    # Store current as previous
    kubectl annotate deployment $SERVICE -n $NAMESPACE \
      previous-image=$CURRENT_IMAGE --overwrite
    
    # Rollback to previous image
    kubectl set image deployment/$SERVICE \
      $SERVICE=$PREVIOUS_IMAGE -n $NAMESPACE
    
    # Wait for rollout complete
    kubectl rollout status deployment/$SERVICE -n $NAMESPACE
    
    # Send alert
    curl -X POST http://alertmanager:9093/api/v1/alerts \
      -H 'Content-Type: application/json' \
      -d "{\"alerts\":[{\"status\":\"firing\",\"labels\":{\"alertname\":\"ServiceRolledBack\",\"service\":\"$SERVICE\"}}]}"
else
    echo "Metrics within acceptable range - no rollback needed"
fi
```

#### 6. Observability Baked In

Observability (metrics, logs, traces) is not an afterthought but integral to the CI/CD process.

**Observability Requirements per Stage:**

| Stage | Observability | Purpose |
|-------|---------------|---------| 
| **Commit** | Test execution logs | Verify tests pass |
| **Build** | Image scan results, SBOM | Track vulnerabilities |
| **Integration Test** | Service mesh logs | Verify communication |
| **Staging Deploy** | Pod startup logs, readiness | Confirm deployment |
| **Canary Phase 1** | Error rate, latency metrics | Validate health |
| **Production Deploy** | Traces, logs, metrics | Monitor impact |
| **Rollback Trigger** | Metric anomalies | Decide rollback |

**Java Instrumentation for Observability:**

```java
// Spring Boot with OpenTelemetry for automatic instrumentation
@Configuration
public class ObservabilityConfig {
    
    @Bean
    public MeterRegistry meterRegistry(MeterRegistryCustomizer rmsMetricsUpdater) {
        // Prometheus metrics export
        return new PrometheusMeterRegistry(PrometheusConfig.DEFAULT);
    }
    
    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder
            .interceptors((request, body, execution) -> {
                // Distributed trace context propagation
                return execution.execute(request, body);
            })
            .build();
    }
}

// Custom metrics for business logic
@Service
public class OrderService {
    private final MeterRegistry meterRegistry;
    
    public void processOrder(Order order) {
        Timer.Sample sample = Timer.start(meterRegistry);
        
        try {
            // Order processing logic
            meterRegistry.counter("orders.processed", 
                "status", "success").increment();
        } catch (Exception e) {
            meterRegistry.counter("orders.processed",
                "status", "failure").increment();
            throw e;
        } finally {
            sample.stop(Timer.builder("order.processing.duration")
                .register(meterRegistry));
        }
    }
}

// Structured logging for aggregation
@Slf4j
@RestController
class OrderController {
    @PostMapping("/orders")
    public ResponseEntity<Order> createOrder(@RequestBody Order order) {
        log.info("Creating order", 
            "item_count", order.getItems().size(),
            "customer_id", order.getCustomerId(),
            "trace_id", TraceContext.current().getTraceId());
        
        return ResponseEntity.created(uri).body(order);
    }
}
```

### Architecture Role

The core principles form the **foundation of scalable microservices deployments**. Each principle reinforces the others:

```
┌─────────────────────────────────────────────────────────────┐
│         Core Principles Interdependencies                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    Independence ──→ Allows parallel deployments           │
│         ↓                                                   │
│    Immutability ──→ Enables reproducible rollbacks        │
│         ↓                                                   │
│   Shift-Left Tests ──→ Catches issues in 5 minutes        │
│         ↓                                                   │
│  Environment Parity ──→ Staging results apply to prod     │
│         ↓                                                   │
│ Automated Rollback ──→ Limits blast radius of failures     │
│         ↓                                                   │
│   Observability ──→ Metrics drive rollback decisions       │
│         ↓                                                   │
│    Reduced Risk + Faster Deployments = Competitive Advantage│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Production Usage Patterns

**Pattern 1: Feature Branch Pipeline**
```
Feature branch created
    ↓
Every new commit triggers full pipeline
    ↓
Ephemeral image: feature-order-svc:feature-async-processing-abc789
    ↓
Deployed to dev environment for integration testing
    ↓
PR review includes test results and security scan output
    ↓
Merge only after: tests pass, code review approved, no vulnerabilities
```

**Pattern 2: Main Branch Protection**
```
Only PRs can merge to main
Main branch is always deployable
    ↓
Tag released from main becomes production artifact
    ↓
Same image that passed staging becomes production version
```

**Pattern 3: Hotfix Procedure**
```
Production incident discovered
    ↓
Checkout from main (production-ready baseline)
    ↓
Create hotfix branch: hotfix/order-svc-payment-timeout
    ↓
Fix code + test locally
    ↓
Push hotfix → CI pipeline validates
    ↓
PR review (expedited, but still required)
    ↓
Merge to main + merge back to develop
    ↓
Tag released: v1.2.1 deployed to production
```

### DevOps Best Practices

| Practice | Implementation | Result |
|----------|----------------|--------|
| **Artifact scanning** | Trivy on every image build | Zero known CVEs in production |
| **Dependency updates** | Renovate bot scans pom.xml | 30 days max age for dependencies |
| **Coverage gates** | Fail if coverage <70% | High test reliability |
| **Golden image** | Base image updated quarterly | Consistent base across all services |
| **Semantic versioning** | v[major].[minor].[patch] | Version expectations clear |
| **Changelog requirement** | PR must include CHANGELOG entry | Release notes automated |

### Common Pitfalls

**Pitfall 1: Inconsistent Environment Configuration**
```
# ❌ WRONG: Different node types per environment
staging: t3.medium (2 vCPU, 4GB)
production: t3.xlarge (4 vCPU, 16GB)

Problem: Staging tests pass, production crashes with OOM
```

```
# ✅ CORRECT: Identical infrastructure, scaled only by replica count
staging: 3x t3.large nodes = 12 vCPU total
production: 3x t3.large nodes = 12 vCPU total
(Both handle same per-node load)
```

**Pitfall 2: Loose Image Tagging**
```
# ❌ WRONG: Using mutable tags
kubectl set image deployment/order order=order:v1.2

Problem: Tag can be overwritten, rollback goes to wrong version
```

```
# ✅ CORRECT: Use digest-based deployments
kubectl set image deployment/order order=order@sha256:abc123def456

Benefit: Exact, immutable reference to specific artifact
```

**Pitfall 3: Skipping Tests in Emergency**
```
# ❌ WRONG: "This is a hotfix, skip tests to speed up"

Problem: Untested code reaches production, causes bigger incident
Actual Impact: 15-min fix takes 4 hours due to new bug
```

```
# ✅ CORRECT: Hotfixes run full pipeline, just faster PR review
- Tests still run (automated)
- Code still reviewed (expedited to 30 min)
- Image still scanned
- Deployment still follows protocol
```

---

## Practical Code Examples

### Example 1: Maven POM Configuration for Microservice Independence

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>order-service</artifactId>
    <version>1.2.3</version>
    <packaging>jar</packaging>

    <name>Order Service</name>
    <description>Independent microservice for order processing</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.5</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        
        <!-- BoM for dependency management -->
        <spring-cloud.version>2022.0.4</spring-cloud.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <!-- Use BOM to align versions across all services -->
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Spring Boot Core -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- Observability -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
        <dependency>
            <groupId>io.opentelemetry.instrumentation</groupId>
            <artifactId>opentelemetry-instrumentation-bom</artifactId>
            <version>1.31.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>

        <!-- Security & Secrets -->
        <dependency>
            <groupId>org.springframework.vault</groupId>
            <artifactId>spring-vault-core</artifactId>
        </dependency>

        <!-- Database -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.6.0</version>
            <scope>runtime</scope>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>testcontainers</artifactId>
            <version>1.19.1</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>postgresql</artifactId>
            <version>1.19.1</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.pact.foundation</groupId>
            <artifactId>pact-jvm-consumer-junit5</artifactId>
            <version>4.6.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Spring Boot Maven Plugin -->
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <image>
                        <builder>paketobuildpacks/builder:base</builder>
                        <name>order-service:${project.version}</name>
                        <publish>false</publish>
                    </image>
                </configuration>
            </plugin>

            <!-- Code Quality: SpotBugs (bug detection) -->
            <plugin>
                <groupId>com.github.spotbugs</groupId>
                <artifactId>spotbugs-maven-plugin</artifactId>
                <version>4.7.3.6</version>
                <configuration>
                    <effort>Max</effort>
                    <threshold>Low</threshold>
                    <failOnError>true</failOnError>
                </configuration>
                <executions>
                    <execution>
                        <phase>verify</phase>
                        <goals>
                            <goal>check</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- Code Coverage: JaCoCo -->
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.10</version>
                <executions>
                    <execution>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report-aggregate</id>
                        <phase>verify</phase>
                        <goals>
                            <goal>report-aggregate</goal>
                        </goals>
                    </execution>
                    <!-- Fail build if coverage < 70% -->
                    <execution>
                        <id>jacoco-check</id>
                        <phase>verify</phase>
                        <goals>
                            <goal>check</goal>
                        </goals>
                        <configuration>
                            <rules>
                                <rule>
                                    <element>PACKAGE</element>
                                    <includes>
                                        <include>com.example.*</include>
                                    </includes>
                                    <limits>
                                        <limit>
                                            <counter>LINE</counter>
                                            <value>COVEREDRATIO</value>
                                            <minimum>0.70</minimum>
                                        </limit>
                                    </limits>
                                </rule>
                            </rules>
                        </configuration>
                    </execution>
                </executions>
            </plugin>

            <!-- Checkstyle (code style) -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-checkstyle-plugin</artifactId>
                <version>3.3.1</version>
                <configuration>
                    <configLocation>google_checks.xml</configLocation>
                    <failOnViolation>true</failOnViolation>
                </configuration>
                <executions>
                    <execution>
                        <phase>validate</phase>
                        <goals>
                            <goal>check</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- License scanning -->
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>license-maven-plugin</artifactId>
                <version>2.0.0</version>
                <configuration>
                    <failIfWarning>true</failIfWarning>
                </configuration>
                <executions>
                    <execution>
                        <phase>validate</phase>
                        <goals>
                            <goal>check</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- Dependency version check -->
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>versions-maven-plugin</artifactId>
                <version>2.16.1</version>
            </plugin>
        </plugins>
    </build>
</project>
```

### Example 2: GitHub Actions Workflow for Commit Stage

```yaml
# .github/workflows/commit-stage.yml
# Runs on: push to any branch, pull requests
# Duration: <5 minutes
# Failure stops merge-to-main

name: Commit Stage
on:
  push:
    branches:
      - '**'
    paths:
      - 'order-service/**'
      - '.github/workflows/commit-stage.yml'
  pull_request:
    paths:
      - 'order-service/**'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/order-service
  JAVA_VERSION: '21'
  MAVEN_OPTS: '-Dmaven.repo.local=.m2/repository -Dorg.slf4j.simpleLogger.defaultLogLevel=warn'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build and Test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout source code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven

      - name: Format code
        run: |
          cd order-service
          mvn spotless:check || mvn spotless:apply

      - name: Run linting and static analysis
        run: |
          cd order-service
          mvn spotbugs:check checkstyle:check

      - name: Run unit tests
        run: |
          cd order-service
          mvn clean test -DskipIntegration \
            -Dorg.slf4j.simpleLogger.defaultLogLevel=error

      - name: Check test coverage (must be >70%)
        run: |
          cd order-service
          mvn jacoco:report jacoco:check

      - name: Build container image
        run: |
          cd order-service
          mvn spring-boot:build-image \
            -Dspring-boot.build-image.imageName=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}

      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload scan results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
          category: 'trivy-scan'

      - name: Run ZAP security scan (SAST)
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'http://localhost:8080'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Scan for secrets leaks
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./order-service
          debug: false

      - name: Scan dependencies for vulnerabilities
        run: |
          cd order-service
          mvn org.owasp:dependency-check-maven:check

      - name: Generate SBOM (Software Bill of Materials)
        run: |
          cd order-service
          mvn cyclonedx:makeBom

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: test-reports
          path: |
            order-service/target/surefire-reports
            order-service/target/site
            order-service/target/sbom.xml

      - name: Set status check result
        if: always()
        run: |
          if [ "${{ job.status }}" = "success" ]; then
            # Image ready to publish in next stage
            echo "✓ Commit stage passed - image ready for build stage"
          fi
```

### Example 3: Pre-commit Hook for Local Development

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit
# Prevent commits if local tests fail
# Install: cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -euo pipefail

PROJECT_DIR="$(git rev-parse --show-toplevel)/order-service"
cd "$PROJECT_DIR"

echo "🔍 Running pre-commit checks..."

# 1. Linting
echo "→ Checking code style..."
mvn spotless:check --quiet || {
    echo "❌ Code formatting issues found"
    echo "Run: mvn spotless:apply"
    exit 1
}

# 2. Unit tests
echo "→ Running unit tests..."
mvn test --quiet -DskipIntegration -Dorg.slf4j.simpleLogger.defaultLogLevel=error || {
    echo "❌ Tests failed"
    exit 1
}

# 3. Code coverage
echo "→ Checking code coverage..."
mvn jacoco:check --quiet || {
    echo "❌ Code coverage below 70%"
    exit 1
}

# 4. Secrets scanning
echo "→ Scanning for hardcoded secrets..."
if grep -r "password\s*=" . --include="*.java" | grep -v "TODO" > /dev/null; then
    echo "⚠️  Warning: Password literals found in code"
fi

echo ""
echo "✅ Pre-commit checks passed"
exit 0
```

### ASCII Diagrams

**Diagram 1: Core Principles Execution Flow**

```
┌────────────────────────────────────────────────────────────────────┐
│               Developer Commits Feature to Git                      │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ↓
        ┌──────────────────────────────────────┐
        │     PRINCIPLE 1: INDEPENDENCE        │
        │  ✓ Each service has own pipeline     │
        │  ✓ Only order-service tested/built   │
        │  ✓ Other services not affected       │
        └──────────────────┬───────────────────┘
                           │
                           ↓
        ┌──────────────────────────────────────┐
        │   PRINCIPLE 2: SHIFT-LEFT TESTING    │
        │  ✓ Lint in < 1 min                   │
        │  ✓ Unit tests in < 3 min             │
        │  ✓ Fail fast if issues found         │
        └──────────────────┬───────────────────┘
                           │ (All tests pass)
                           ↓
        ┌──────────────────────────────────────┐
        │  PRINCIPLE 3: IMMUTABLE ARTIFACTS    │
        │  ✓ Build once: src → image           │
        │  ✓ SHA256 identifier: abc123def456   │
        │  ✓ Never rebuild between envs        │
        └──────────────────┬───────────────────┘
                           │
                           ↓
        ┌──────────────────────────────────────┐
        │   PRINCIPLE 4: ENVIRONMENT PARITY    │
        │  ✓ Deploy to staging (identical)     │
        │  ✓ Integration tests with deps       │
        │  ✓ Same K8s version, same resources  │
        └──────────────────┬───────────────────┘
                           │ (If tests pass)
                           ↓
        ┌──────────────────────────────────────┐
        │     PRINCIPLE 5: OBSERVABILITY       │
        │  ✓ Collect metrics continuously      │
        │  ✓ Feed into canary decision logic   │
        │  ✓ Enable automated rollback         │
        └──────────────────┬───────────────────┘
                           │
                    ┌──────┴──────┐
                    ↓             ↓
            ✓ Metrics OK    ✗ Metrics Bad
            (Error <1%)     (Error >1%)
                    │             │
                    ↓             ↓
            ┌────────────┐  ┌──────────────────┐
            │ Expand to  │  │ PRINCIPLE 6:     │
            │ 100% traffic   AUTOMATED ROLLBACK│
            │            │  │ ✓ Revert image  │
            │ PRODUCTION │  │ ✓ Instant fix    │
            │ SUCCESS    │  │ ✓ No manual ops  │
            └────────────┘  └──────────────────┘
```

**Diagram 2: Immutable Artifact Journey**

```
Git Commit: abc789f123
    ↓
┌────────────────────────────────────────────────────┐
│          BUILD: order-service:1.2.3                │
│                                                    │
│  Source src/ → Maven compile → JAR target/        │
│  JAR + JRE → Multi-stage Docker build → Image     │
│  Image = SHA256:abc123def456xyz789... [immutable] │
└─────────────────────┬────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
    ┌────────┐  ┌────────┐  ┌────────────┐
    │Staging │  │ Canary │  │ Production │
    │  (1%)  │  │  (5%)  │  │  (100%)    │
    │  Test  │  │ Monitor│  │ Users      │
    │ Scan   │  │ Metrics│  │ Traffic    │
    └────────┘  └────────┘  └────────────┘
        │ SAME IMAGE.SHA256 ALL ENVIRONMENTS
        │
    If Error Rate < 1% → Promote to next stage
    If Error Rate > 1% → Rollback (revert image)
    
    Total image: 256MB (not rebuilt per env)
    Deploy time: 2 minutes (not 15 minutes per rebuild)
```

---

# Reference Modern Stack

## Textual Deep Dive

The modern DevOps stack for Java microservices is intentionally diverse, with each tool optimized for a specific concern. Understanding how these tools integrate is crucial for senior engineers.

### Tool Selection Rationale

#### GitHub Actions (CI Orchestration)

**Why GitHub Actions for CI?**
- **Native integration**: Lives in same repository as code
- **No separate infrastructure**: Runs on GitHub-hosted runners (no Jenkins server to maintain)
- **Cost-effective**: Free for public repos, minimal cost for private
- **Workflow-as-Code**: YAML files version controlled with source
- **Ecosystem**: 10,000+ pre-built actions available

**Docker for Containerization**

**Why Docker and not alternatives?**
- **Industry standard**: 100% container adoption (vs Podman at 5%)
- **Kubernetes native**: K8s internally expects Docker format
- **Registry ecosystem**: Docker Hub, ECR, ACR, Artifactory all optimized for Docker format
- **Tooling maturity**: Docker Compose, Docker Desktop widely used for local dev

**Alternative Considered**: Podman (Docker-compatible, rootless), but ecosystem still immature.

**Kubernetes (Orchestration)**

**Why Kubernetes and not ECS?**
- **Portability**: Run anywhere (AWS, Azure, GCP, on-prem)
- **Community**: Largest container orchestration ecosystem
- **Service mesh integration**: Istio, Linkerd mature integrations
- **Declarative**: GitOps model with ArgoCD
- **Workload diversity**: Deployments, StatefulSets, Jobs, DaemonSets

**Alternative Considered**: AWS ECS (simpler), but lock-in risk and limited multi-cloud support.

#### ArgoCD (CD - GitOps Orchestration)

**Why ArgoCD over Flux or Jenkins?**
- **Git as source of truth**: All desired state in Git, removes manual kubectl commands
- **Automated sync**: Detects drift between Git and cluster state
- **Declarative**: Helm/Kustomize for configuration
- **Security**: Secrets separated from configuration
- **Audit**: Every change traceable to Git commit
- **Web UI**: Clear visibility into deployment status

**Architecture:**
```
┌──────────────────────────────────────────────────────┐
│                  Git Repository                      │
│  ├─ helm-charts/order-service/Chart.yaml            │
│  ├─ helm-charts/order-service/values-prod.yaml      │
│  └─ ArgoCD/applications/order-service.yaml          │
└──────────────────────┬───────────────────────────────┘
                       │ ArgoCD watches
                       │ (every 3 seconds)
                       ↓
┌──────────────────────────────────────────────────────┐
│              ArgoCD Controller (in K8s)              │
│  Desired State Scanner:                              │
│  - Compare Git (desired) vs Cluster (actual)         │
│  - If mismatch → Sync (apply changes)                │
│  - If healthy → No action                            │
│  - Webhook from Git → Immediate sync                 │
└──────────────────────┬───────────────────────────────┘
                       │ applies via
                       │ kubectl
                       ↓
            ┌──────────────────────┐
            │ Kubernetes Cluster   │
            │ (Staging/Production) │
            └──────────────────────┘
```

#### SonarQube (Code Quality)

**Why SonarQube?**
- **Language agnostic**: Analyzes Java, Python, JavaScript, etc.
- **Plugin ecosystem**: 50+ language plugins
- **Quality gates**: Prevents merge if quality degrades
- **SAST integration**: Built-in security vulnerability detection
- **Enterprise**: LDAP/SAML integration for access control

**Metrics Tracked:**
- Code Coverage (target: >70%)
- Code Smell Density (target: <5 per KLOC)
- Vulnerability count (target: 0 critical/high)
- Technical Debt (cumulative)
- Hotspot identification (risky code)

#### Prometheus + Grafana (Observability)

**Why this stack?**
- **Prometheus**: Industry-standard metrics collection, time-series database
- **Pull-based**: Services expose `/metrics` endpoint (security advantage)
- **Grafana**: Visualization and alerting on top of Prometheus
- **Service Mesh Integration**: Istio exports metrics to Prometheus automatically

**Metrics Pipeline:**
```
Application
  │ (exposes /metrics in Prometheus format)
  ↓
Prometheus Scraper
  │ (pulls metrics every 15s)
  ↓
Prometheus Time-Series DB
  ├─ Stores as: metric_name{labels} timestamp value
  │ Example: http_requests_total{service="order", status="200"} 1000
  ↓
Grafana Dashboards
  │ (queries Prometheus, draws graphs)
  ↓
Alertmanager
  │ (routes alerts to PagerDuty, Slack, etc.)
  ↓
Developer/SRE Notification
```

**Key Metrics for Microservices:**  
- Request rate (requests/sec)
- Error rate (5xx responses / total)
- Latency percentiles (p50, p95, p99)
- GC time (JVM)
- Database connection pool utilization
- Cache hit rates

#### Sentry (Error Tracking)

**Why Sentry for error tracking?**
- **Automatic Java instrumentation**: Catches exceptions without code changes
- **Breadcrumb trails**: Requests/events leading to error
- **Release tracking**: Errors associated with specific version
- **Automatic grouping**: Duplicate errors grouped, reduces noise
- **Team collaboration**: Assignments, notifications

**Complement to Logs:**
```
Prometheus Metrics: "Error rate is 5%"
    └─ What's happening? (aggregated view)

Logs in ELK: "Exception: NullPointerException at line 42"
    └─ Detailed trace for specific request

Sentry: "NullPointerException in OrderService.validate() 
        affecting 200 users since v1.2.3 release"
    └─ Business-focused error aggregation
```

#### Terraform (Infrastructure as Code)

**Why Terraform?**
- **Multi-cloud**: Single language (HCL) deploying to AWS, Azure, GCP
- **State management**: Tracks infrastructure state, detects drift
- **Modularity**: Reusable modules (EKS cluster, RDS, VPC)
- **Versionable**: IaC tracked in Git, reviewed in PRs

**IaC Workflow:**
```
Developer modifies main.tf
    ↓ (git commit)
Git workflow triggers:
    terraform init
    terraform plan (show what will change)
    (human reviews plan in PR)
    ↓ (merge approved)
terraform apply (create resources)
    ↓
Resource state stored in terraform.tfstate (in S3)
```

#### HashiCorp Vault (Secrets Management)

**Why Vault?**
- **Encryption in transit and at rest**: Secrets never stored in Git or container images
- **Dynamic secrets**: Generate temporary credentials on demand
- **Audit trail**: Every secret access logged
- **Automatic rotation**: Credentials invalidated after TTL
- **Kubernetes integration**: Automatically inject secrets into pods

**Secrets Hierarchy:**
```
Vault Server (secured, high security)
    ├─ Database credentials (read-only, 1-hour TTL)
    │   └─ Injected into Order Service pod
    ├─ API keys (30-day rotation)
    │   └─ Injected into Payment Service pod
    ├─ Private keys for image signing
    │   └─ Used in CI/CD pipeline only
    └─ LDAP sync credentials
        └─ Rotated monthly

No secrets in:
    ✗ source code
    ✗ Docker images
    ✗ Git repositories
    ✗ CI/CD logs
```

#### JUnit 5 + Mockito (Testing)

**Why this combination?**
- **JUnit 5**: Modern, parametrized tests, age>10 years proven
- **Mockito**: Simple mocking library, fluent API
- **Spring Boot Test**: Ships with embedded servers (Tomcat), test containers

**Testing Architecture:**
```
Unit Tests (>70% code covered)
  - JUnit 5 + Mockito
  - Run in isolation, no network
  - Duration: <5 minutes for 500+ tests
  - Part of commit stage

Integration Tests
  - Testcontainers (Docker for dependencies)
  - Real service-to-service communication
  - Duration: 10 minutes
  - Part of build stage

Contract Tests (Pact)
  - Consumer expectations vs Provider API
  - Prevents breaking changes
  - Part of integration stage

E2E Tests
  - Full multi-service scenario
  - Staged environment only
  - Human-written scenarios, flaky-prone
```

### Production Usage Patterns

**High-Load E-Commerce Pattern**
```
GitHub Actions CI: Every commit
    └─ 2 min: lint + unit tests
    └─ 3 min: build + image scan
    └─ 1 min: publish to registry

ArgoCD CD: Deploy to staging automatically
    └─ Run integration tests
    └─ If pass → ready for production

Manual approval: Team reviews in PR
    └─ "Approved for production"

ArgoCD propagates: Patch staging tag → prod tag
    └─ Same image, different namespace
    └─ Kubernetes diff shows exact changes

Monitoring: Prometheus graph shows metrics
    └─ Error rate stays < 1%
    └─ Latency p99 stays < 500ms
    └─ Auto-approval from monitoring if SLI met
```

**Multi-Region Deployment Pattern**
```
Git push → GitHub Actions builds image
            └─ Terraform provisions infrastructure
            └─ ArgoCD discovers clusters in all regions
            └─ Simultaneously deploys to:
                ├─ US-WEST cluster
                ├─ US-EAST cluster
                ├─ EU-CENTRAL cluster
                └─ ASIA-PACIFIC cluster
            
Observability:
  - Prometheus scraped from each region
  - Grafana dashboard shows global metrics
  - If one region unhealthy, ArgoCD reconciles
```

### DevOps Best Practices with Modern Stack

| Practice | Implementation | Benefit |
|----------|---|---|
| **Infrastructure as Code** | Terraform for all resources | Reproducible, version-controlled environments |
| **Pipeline as Code** | GitHub Actions YAML | Version-controlled workflows, code review |
| **Config as Code** | Helm charts + kustomize | Environment-specific configs, reusable templates |
| **Secrets as Code** | Vault + K8s admission controller | No secrets in images/Git, automatic rotation |
| **Observability as Code** | Prometheus rules + Grafana dashboards | Versioned monitoring, code review |
| **Deployment as Code** | ArgoCD ApplicationSet | Multi-cluster deployments from single config |

### Common Pitfalls with Modern Stack

**Pitfall 1: Over-relying on Grafana dashboards without alerts**
```
❌ WRONG: "I'll monitor the dashboard manually"
Problem: Dashboards show historical data (5-min lag)
         Incidents happen in seconds
         Humans are terrible at watching screens

✅ CORRECT: Prometheus + Grafana + Alertmanager + PagerDuty
Rule: alert on "error_rate > 1% for 2 minutes"
Instant notification to on-call engineer
```

**Pitfall 2: Mixing imperative and declarative deployments**
```
❌ WRONG:
   - ArgoCD managed order service
   - Manual kubectl for payment service
   - Some config in Helm, some in Git

Problem: Inconsistency, hard to audit, drift detection fails

✅ CORRECT:
   - Everything in Git
   - Everything through ArgoCD
   - kubectl only for debugging (never apply changes)
```

**Pitfall 3: Storing secrets in Vault without TTL**
```
❌ WRONG: Database password stored in Vault permanent
Problem: If leaked, valid forever

✅ CORRECT: Generate temporary credentials with 1-hour TTL
Vault → Generate temporary password
K8s pod uses it
TTL expires → password invalid
Attacker can't reuse leaked credential
```

---

## Practical Code Examples

### Example 1: GitHub Actions Workflow Integration

```yaml
# .github/workflows/build-stage.yml
# Runs AFTER successful commit-stage
# Creates and publishes container image

name: Build Stage
on:
  workflow_run:
    workflows: ["Commit Stage"]
    types: [completed]
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/order-service
  JAVA_VERSION: '21'

jobs:
  publish:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    outputs:
      image-digest: ${{ steps.image.outputs.digest }}
      image-ref: ${{ steps.image.outputs.ref }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_branch }}

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven

      - name: Build container image
        run: |
          cd order-service
          mvn spring-boot:build-image \
            -Dspring-boot.build-image.imageName=order-service:${{ github.sha }}

      - name: Generate SBOM with CycloneDX
        run: |
          cd order-service
          mvn cyclonedx:makeBom
          cat target/bom.xml

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Tag and push image
        id: image
        run: |
          docker tag order-service:${{ github.sha }} \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          docker tag order-service:${{ github.sha }} \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          
          DIGEST=$(docker inspect --format='{{.RepoDigests}}' \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }})
          echo "digest=$DIGEST" >> $GITHUB_OUTPUT
          echo "ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@$DIGEST" >> $GITHUB_OUTPUT

      - name: Scan published image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ steps.image.outputs.ref }}
          format: 'json'
          output: 'trivy-results.json'

      - name: Check for critical vulnerabilities
        run: |
          CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy-results.json)
          if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ Found $CRITICAL critical vulnerabilities in image"
            exit 1
          fi
          echo "✅ Image scan passed"

      - name: Sign image with Cosign
        env:
          COSIGN_KEY: ${{ secrets.COSIGN_KEY }}
          COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
        run: |
          # Install Cosign
          curl -Lo /usr/bin/cosign https://github.com/sigstore/cosign/releases/download/v2.1.0/cosign-linux-amd64
          chmod +x /usr/bin/cosign
          
          # Sign image
          cosign sign --key env://COSIGN_KEY \
            ${{ steps.image.outputs.ref }}
          
          # Verify signature
          cosign verify --key env://COSIGN_KEY \
            ${{ steps.image.outputs.ref }}

      - name: Notify deployment readiness
        if: success()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ Build complete!\n\nImage: ${{ steps.image.outputs.ref }}\nDigest: ${{ steps.image.outputs.digest }}`
            })
```

### Example 2: Terraform for Stack Infrastructure

```hcl
# terraform/modules/microservice-platform/main.tf
# Complete stack: EKS, ArgoCD, Prometheus, Grafana, Vault

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws        = "~> 5.0"
    kubernetes = "~> 2.20"
    helm       = "~> 2.10"
    vault      = "~> 3.17"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name            = "${var.environment}-platform"
  role_arn        = aws_iam_role.eks_cluster.arn
  version         = "1.28"
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Worker Nodes
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-workers"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids
  
  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 3
  }
  
  instance_types = ["t3.large"]
  
  # Enable log exports
  logging_config {
    cloudwatch_log_group_name = aws_cloudwatch_log_group.eks_nodes.name
    enabled                   = true
    log_types                 = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_policy
  ]
  
  tags = {
    Name        = "${var.environment}-nodes"
    Environment = var.environment
  }
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.0"
  namespace        = "argocd"
  create_namespace = true
  
  values = [
    yamlencode({
      global = {
        domain = "argocd.${var.domain_name}"
      }
      configs = {
        secret = {
          argocdServerAdminPassword = bcrypt(random_password.argocd_admin.result)
        }
      }
      server = {
        ingress = {
          enabled   = true
          className = "nginx"
          hosts = [
            "argocd.${var.domain_name}"
          ]
          tls = [{
            secretName = "argocd-tls"
            hosts = [
              "argocd.${var.domain_name}"
            ]
          }]
        }
      }
      applicationSet = {
        enabled = true
      }
    })
  ]
  
  depends_on = [
    aws_eks_node_group.workers
  ]
}

# Prometheus Helm Release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "54.2.2"
  namespace  = "monitoring"
  
  create_namespace = true
  
  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
      grafana = {
        adminPassword = random_password.grafana_admin.result
        persistence = {
          enabled = true
          size    = "10Gi"
        }
      }
    })
  ]
  
  depends_on = [
    aws_eks_node_group.workers
  ]
}

# Vault Helm Release
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.27.0"
  namespace  = "vault"
  
  create_namespace = true
  
  values = [
    yamlencode({
      server = {
        dataStorage = {
          size = "10Gi"
        }
        ha = {
          enabled = true
          replicas = 3
        }
      }
      injector = {
        enabled = true
      }
    })
  ]
  
  depends_on = [
    aws_eks_node_group.workers
  ]
}

# RDS PostgreSQL for microservices
resource "aws_db_instance" "microservices" {
  identifier     = "${var.environment}-microservices-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.large"
  
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = "microservices"
  username = "postgres"
  password = random_password.db_password.result
  
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = "${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  backup_retention_period = var.environment == "production" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  multi_az = var.environment == "production" ? true : false
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  tags = {
    Environment = var.environment
  }
}

# Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}/rds/password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.microservices.username
    password = aws_db_instance.microservices.password
    host     = aws_db_instance.microservices.endpoint
    port     = 5432
    engine   = "postgres"
    dbname   = aws_db_instance.microservices.db_name
  })
}

# Outputs for reference
output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint"
}

output "argocd_ingress_url" {
  value       = "https://argocd.${var.domain_name}"
  description = "ArgoCD web UI URL"
}

output "prometheus_url" {
  value       = "http://prometheus-operated:9090"
  description = "Prometheus internal URL in cluster"
}

output "grafana_url" {
  value       = "http://prometheus-grafana:3000"
  description = "Grafana internal URL in cluster"
}

output "vault_addr" {
  value       = "http://vault:8200"
  description = "Vault internal URL in cluster"
}
```

### Example 3: SonarQube Quality Gate Configuration

```bash
#!/usr/bin/env bash
# setup-sonarqube.sh
# Configures SonarQube quality gates and project settings

SONAR_HOST="https://sonarqube.example.com"
SONAR_TOKEN="$SONARQUBE_TOKEN"
PROJECT_KEY="com.example:order-service"

# Create quality gate
curl -X POST "$SONAR_HOST/api/qualitygates/create" \
  -H "Authorization: Bearer $SONAR_TOKEN" \
  -d "name=MicroserviceQualityGate" \
  -d "isBuiltIn=false"

# Get quality gate ID
QG_ID=$(curl -s "$SONAR_HOST/api/qualitygates/search?name=MicroserviceQualityGate" \
  -H "Authorization: Bearer $SONAR_TOKEN" | jq '.qualitygates[0].id')

# Add conditions to quality gate
declare -a CONDITIONS=(
  "new_coverage<80"          # New code must have >80% coverage
  "new_duplicated_lines_density>3"  # <3% duplication in new code
  "new_maintainability_rating<10"   # No decrease in maintainability
  "security_rating>1"        # No security issues
  "reliability_rating>1"     # No reliability issues
  "new_sqale_debt_ratio<5"   # <5% technical debt ratio
)

for condition in "${CONDITIONS[@]}"; do
  curl -X POST "$SONAR_HOST/api/qualitygates/add_condition" \
    -H "Authorization: Bearer $SONAR_TOKEN" \
    -d "gateid=$QG_ID" \
    -d "metric=$(echo $condition | cut -d'<' -f1)" \
    -d "op=<" \
    -d "error=$(echo $condition | cut -d'<' -f2)"
done

# Assign quality gate to project
curl -X POST "$SONAR_HOST/api/qualitygates/select" \
  -H "Authorization: Bearer $SONAR_TOKEN" \
  -d "projectKey=$PROJECT_KEY" \
  -d "gateId=$QG_ID"

echo "✅ SonarQube quality gate configured for $PROJECT_KEY"
```

### ASCII Diagrams

**Diagram 1: Modern Stack Integration**

```
┌────────────────────────────────────────────────────────┐
│              Developer Workflow                        │
│  1. Code in IDE                                        │
│  2. Git push to GitHub                                 │
└──────────────────┬─────────────────────────────────────┘
                   │
                   ↓ (Webhook triggers)
        ┌──────────────────────────┐
        │  GitHub Actions (CI)     │
        │  ├─ Checkout code        │
        │  ├─ Run: mvn test        │
        │  ├─ Run: mvn sonar:sonar │
        │  │   └─ SonarQube checks  │
        │  │       quality gates    │
        │  ├─ Build image          │
        │  ├─ Scan with Trivy      │
        │  └─ Push to registry     │
        └──────────────┬───────────┘
                       │ (if success)
                       ↓
        ┌──────────────────────────┐
        │  Container Registry      │
        │  (GHCR / ECR)            │
        │  ├─ image:sha256:abc123  │
        │  └─ SBOM + Provenance    │
        └──────────────┬───────────┘
                       │
         ┌─────────────┼─────────────┐
         ↓             ↓             ↓
      ┌─────┐     ┌─────────┐    ┌──────────┐
      │ArgoCD    │Terraform │   │Vault     │
      │   │      │    │     │   │   │      │
      │   └──────┼────┴─────┴───┘   │      │
      │   watches│ provisions resources   │
      │   Git    │ (EKS, RDS, Secrets)   │
      └────┬─────┘                       │
           ↓                             │
    ┌───────────────────┐               │
    │ Kubernetes Cluster│               │
    │ ├─ order-service  │←──────────────┘
    │ ├─ payment-service│   (Vault AgentInjector)
    │ └─ inventory-      │
    │    service        │
    └────┬──────────────┘
         ├─ scraped by
         │  Prometheus
         ↓
    ┌───────────────────────┐
    │ Prometheus Time-Series │
    │ Database (30d history) │
    └────┬──────────────────┘
         │ used by
         ↓
    ┌───────────────────┐
    │ Grafana Dashboards│
    │ ├─ Error Rates    │
    │ ├─ Latency P99    │
    │ └─ Resource Usage  │
    └────┬──────────────┘
         │ triggers
         ↓
    ┌───────────────────┐
    │ Alertmanager      │
    │ → PagerDuty       │
    │ → Slack           │
    │ → Email           │
    └───────────────────┘
         │
         ↓
    ┌─────────────────────┐
    │ Sentry Error Tracking│
    │ Groups exceptions    │
    │ by service/version   │
    └──────────────────────┘
```

**Diagram 2: Tool Specialization Matrix**

```
┌──────────────────────────────────────────────────────────────┐
│        Responsibility        │         Tool(s)               │
├──────────────────────────────┼───────────────────────────────┤
│ Source Control               │ GitHub                        │
│ CI Orchestration             │ GitHub Actions                │
│ Code Quality                 │ SonarQube                     │
│ Testing Framework            │ JUnit 5 + Mockito             │
│ Containerization             │ Docker                        │
│ Image Registry               │ GHCR / ECR / ACR              │
│ Image Scanning               │ Trivy / Snyk                  │
│ Image Signing                │ Cosign                        │
│ Container Orchestration      │ Kubernetes                    │
│ CD / GitOps                  │ ArgoCD                        │
│ Infrastructure Provisioning  │ Terraform                     │
│ Secrets Management           │ HashiCorp Vault               │
│ Metrics Collection           │ Prometheus                    │
│ Metrics Visualization        │ Grafana                       │
│ Logs Aggregation             │ ELK / Loki                    │
│ Distributed Tracing          │ Jaeger / Tempo                │
│ Error Tracking               │ Sentry                        │
│ Alerting                     │ Alertmanager / PagerDuty      │
│ Service Mesh                 │ Istio / Linkerd               │
└──────────────────────────────┴───────────────────────────────┘
```

---

*Continued in Part 3: Pipeline Architecture & Image Promotion*
