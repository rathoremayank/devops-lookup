# Deep Dive: Pipeline Architecture, Deployment Strategies, and Advanced Topics
**Part 3 of Java Microservices CI/CD Study Guide**

---

# Pipeline Architecture

## Textual Deep Dive

The pipeline architecture defines the sequence of automated stages that transform code into production deployments. For Java microservices, the pipeline is optimized for speed, safety, and observability.

### Stage 1: Commit Stage (Duration: 5 minutes)

**Purpose**: Immediate feedback to developer (within same Git workflow)

**Triggers**:
- Push to any branch (feature branch, develop, main)
- Pull request creation/update
- Manual re-trigger

**Steps**:

1. **Checkout Code**
```bash
git clone --depth 1 https://github.com/company/order-service.git
cd order-service
git checkout <commit-sha>
```
Shallow clone `--depth 1` reduces clone time from 30s to 3s.

2. **Linting & Format Check** (JUnit 5 seconds)
```bash
mvn spotless:check
# Checks code formatting (spaces, indentation, imports)
# Prevents inconsistent code style

mvn checkstyle:check
# Enforces coding standards (variable naming, method length, etc.)
```

3. **Static Analysis Security Testing (SAST)** (45 seconds)
```bash
mvn spotbugs:check
# Scans for bug patterns: null pointer, unused variables, etc.

mvn -P security-scan
# SAST tool: SonarQube analysis
# Looks for: SQL injection, XSS, hardcoded secrets, weak crypto
```

4. **Dependency Vulnerability Scan** (60 seconds)
```bash
mvn org.owasp:dependency-check-maven:check
# Compares all Maven artifacts against NVD (National Vulnerability Database)
# Fails if high/critical vulnerabilities found
# Reports: CVE number, severity, fix version
```

5. **Unit Tests** (120 seconds)
```bash
mvn clean test -DskipIntegration
# Runs JUnit 5 tests
# Must have >70% code coverage (JaCoCo)
# Tests are isolated (no database, no HTTP calls)
```

**Example Unit Test:**
```java
@DisplayName("Order Service Unit Tests")
class OrderServiceTest {
    
    private final OrderService orderService;
    private final OrderRepository orderRepository = Mockito.mock(OrderRepository.class);
    private final PaymentClient paymentClient = Mockito.mock(PaymentClient.class);
    
    public OrderServiceTest() {
        this.orderService = new OrderService(orderRepository, paymentClient);
    }
    
    @Test
    @DisplayName("should calculate total price including tax")
    void testCalculateTotalPrice() {
        Order order = new Order()
            .withBasePrice(BigDecimal.valueOf(100))
            .withTaxRate(BigDecimal.valueOf(0.1));
        
        BigDecimal total = orderService.calculateTotal(order);
        
        assertThat(total).isEqualByComparingTo(BigDecimal.valueOf(110));
    }
    
    @Test
    @DisplayName("should throw exception when order is invalid")
    void testValidateOrderThrows() {
        Order invalidOrder = new Order(); // No items
        
        assertThatThrownBy(() -> orderService.validateOrder(invalidOrder))
            .isInstanceOf(ValidationException.class)
            .hasMessage("Order must contain at least one item");
    }
    
    @Test
    void testCreatePaymentWhenProcessingOrder() {
        Order order = createValidOrder();
        
        orderService.processOrder(order);
        
        verify(paymentClient).charge(
            argThat(payment -> 
                payment.getAmount().equals(order.getTotal())
            )
        );
    }
}
```

6. **Code Coverage Report** (30 seconds)
```bash
mvn jacoco:report jacoco:check
# Generates coverage report
# Fails if coverage < 70%
# Reports: line coverage, branch coverage, method coverage
```

**Pass/Fail Criteria**:
- All tests pass
- Coverage ≥ 70%
- No SAST vulnerabilities (high/critical)
- No dependency vulnerabilities (high/critical)
- Code formatting compliant

**Failure Handling**:
```
If commit stage fails:
  1. Email notification sent to committer
  2. PR shows "Commit Stage Failed" in checks
  3. Cannot merge PR without fix
  4. Committer has 2-hour window to fix
  5. After 2 hours, branch considered stale and may be archived
```

**Output Artifacts**:
- Test reports (JUnit XML format)
- Code coverage reports (JaCoCo HTML)
- SAST findings (SARIF format for GitHub Security tab)
- Build logs (CloudWatch, GitHub Actions logs)

### Stage 2: Build Stage (Duration: 3-5 minutes)

**Purpose**: Create deployable container image

**Triggers**: Automatically after commit stage passes

**Steps**:

1. **Compile Java Code**
```bash
mvn clean package -DskipTests
# Runs javac compilation
# Downloads Maven dependencies
# Builds JAR artifact
# Duration: 90 seconds (with cache)
```

2. **Build Container Image (Multi-stage)**
```dockerfile
# Stage 1: Builder
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-noble

# Security: Don't run as root
RUN useradd -m -u 1001 appuser

COPY --from=builder --chown=appuser:appuser /build/target/order-service.jar /opt/app/
COPY --from=builder /build/target/sbom.json /opt/app/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health/liveness || exit 1

USER appuser
ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=200", "-jar", "/opt/app/order-service.jar"]
```

**Build optimization**:
- Builder image: 700MB (discarded after build)
- Runtime image: 256MB (only JRE + JAR)
- Cache layers: Dependencies cached separately from code
- Result: 3-minute build time

3. **Generate SBOM (Software Bill of Materials)**
```bash
mvn cyclonedx:makeBom
# Creates CycloneDX format SBOM
# Lists all libraries + versions + licenses
# Example output:
# - com.fasterxml.jackson.core:jackson-databind:2.15.2
# - org.springframework.boot:spring-boot-starter-web:3.1.5
# - org.postgresql:postgresql:42.6.0
```

4. **Scan Image for Vulnerabilities** (120 seconds)
```bash
trivy image --severity HIGH,CRITICAL order-service:latest
# Scans all layers for known vulnerabilities
# Compares against multiple DBs (NVD, GitHub Advisory, etc.)
# Fails if critical CVEs found
```

Example Trivy output:
```
order-service:latest (eclipse-temurin:21-jre-noble)

Vulnerabilities
═════════════════════════════════════════════════════════════════════
Package: openssl
Severity: CRITICAL
Vulnerability ID: CVE-2022-41080
Title: OpenSSL: Insecure certificate verification
Description: X.509 certificate verification bypass
Fix: Upgrade to openssl 3.0.5 or later
```

5. **Publish to Registry**
```bash
docker push ghcr.io/company/order-service@sha256:abc123def456...
docker push ghcr.io/company/order-service:1.2.3
docker push ghcr.io/company/order-service:latest
```

6. **Image Metadata & Attestation**
```bash
# Cosign signs image with private key
cosign sign --key env://COSIGN_KEY \
  ghcr.io/company/order-service@sha256:abc123def456

# Create provenance (SLSA framework)
# Records: who built it, when, from which commit
# Enables supply chain security
```

**Pass/Fail Criteria**:
- Image builds successfully
- Size < 500MB (performance gate)
- No critical/high vulnerabilities in image
- SBOM generated and stored

**Output Artifacts**:
- Docker image in registry (image digest, tags)
- SBOM (bom.json, bom.xml)
- Image scan report (Trivy JSON)
- Cosign signature (publickey.pub, *.sig)

### Stage 3: Integration Test Stage (Duration: 8-12 minutes)

**Purpose**: Validate service functioning with real dependencies

**Triggers**: Automatically after build stage

**Deployment Environment**: Staging Kubernetes cluster (identical to production)

**Steps**:

1. **Deploy to Staging**
```bash
# ArgoCD syncs image to staging
kubectl set image deployment/order-service \
  order-service=ghcr.io/company/order-service:1.2.3

# Wait for pods ready
kubectl rollout status deployment/order-service -n staging
```

2. **Run Service Integration Tests** (5 minutes)
```java
@IntegrationTest
class OrderServiceIntegrationTest {
    
    @Testcontainers
    static class OrderServiceTestContainer {
        
        @Container
        static PostgreSQLContainer<?> postgres = 
            new PostgreSQLContainer<>("postgres:15")
                .withDatabaseName("testdb")
                .withUsername("test")
                .withPassword("test");
        
        @Container
        static KafkaContainer kafka = 
            new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));
    }
    
    @Test
    void testOrderProcessingFlow() throws Exception {
        // Create order via REST API
        ResponseEntity<Order> response = restTemplate.postForEntity(
            "http://order-service:8080/api/orders",
            new CreateOrderRequest(
                customerId = 123L,
                items = List.of(new OrderItem(sku = "ABC123", qty = 2))
            ),
            Order.class
        );
        
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        Long orderId = response.getBody().getId();
        
        // Wait for payment processed (async)
        await().atMost(5, SECONDS)
            .until(() -> orderRepository.findById(orderId).get().getStatus(), 
                   equalTo(OrderStatus.PAID));
        
        // Verify inventory reduced
        Inventory inventory = inventoryClient.getInventory("ABC123");
        assertThat(inventory.getAvailable()).isEqualTo(previousQty - 2);
    }
}
```

3. **Contract Testing** (2 minutes)
```java
// Pact test: Consumer expectations vs Provider API
@PactTestFor(providerName = "payment-service", port = "8080")
@ExtendWith(PactConsumerTestExt.class)
class OrderServicePactTest {
    
    @Pact(consumer = "order-service")
    public V4Pact chargePaymentPact(PactBuilder builder) {
        return builder
            .given("valid order exists")
            .uponReceiving("a request to charge payment")
                .path("/api/payments/charge")
                .method("POST")
                .body("""
                {
                  "orderId": 123,
                  "amount": 99.99,
                  "currency": "USD"
                }
                """)
            .willRespondWith()
                .status(200)
                .body("""
                {
                  "transactionId": "txn_12345",
                  "status": "SUCCESS",
                  "amount": 99.99
                }
                """)
            .toPact();
    }
    
    @Test
    void testChargePayment(MockServerClient mockServerClient) {
        // Order service calls payment service
        PaymentResponse response = orderService.chargePayment(
            new PaymentRequest(123L, BigDecimal.valueOf(99.99), "USD")
        );
        
        // Verify contract met
        assertThat(response.getStatus()).isEqualTo("SUCCESS");
        assertThat(response.getTransactionId()).isNotBlank();
    }
}
```

4. **Run End-to-End Tests** (5 minutes)
```bash
# Docker Compose spins up: order-service, payment-service, inventory-service
# Real PostgreSQL, Redis, Kafka
# Business flow tests

# Example: Order complete flow
curl -X POST http://localhost:8080/api/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customerId": 123,
    "items": [{"sku": "ABC123", "quantity": 2}]
  }'

# Verify: Order created, payment charged, inventory reduced
```

5. **Smoke Tests** (1 minute)
```bash
# Quick health checks
curl http://order-service:8080/actuator/health/liveness
# Expected: 200 OK, {"status":"UP"}

curl http://order-service:8080/actuator/health/readiness
# Expected: 200 OK (service ready to receive requests)
```

**Pass/Fail Criteria**:
- All integration tests pass
- All contract tests pass
- All E2E tests pass
- Service health checks pass
- No performance regressions (latency < baseline + 10%)

**Output Artifacts**:
- Integration test reports
- E2E test videos (if failures)
- Service logs from staging
- Performance profile

### Stage 4: Security Stage (Duration: 6-10 minutes)

**Purpose**: Security validation before production deployment

**Runs in parallel** with Stage 3

**Steps**:

1. **Container Security Scanning**
```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 \
  ghcr.io/company/order-service:1.2.3
  
# Scans all image layers for known vulnerabilities
# Fails if any found
```

2. **Dynamic Application Security Testing (DAST)** (4 minutes)
```bash
# OWASP ZAP scans running application for vulnerabilities
zaproxy -cmd \
  -quickurl http://order-service:8080 \
  -quickout results.json

# Checks for: XSS, CSRF, SQL Injection, authentication bypass, etc.
```

3. **Secrets Scanning**
```bash
# Scans image layers for hardcoded secrets
trufflehog filesystem . \
  --json \
  --fail \
  --max-depth=5

# Looks for: AWS keys, database passwords, private keys, API tokens
```

4. **Compliance Scanning**
```bash
# Validates: FIPS compliance, HIPAA requirements, etc.
kube-bench run --benchmark=cis-kubernetes-benchmark \
  --exit-code 1

# For images: Checks for root user, writable FS, etc.
```

**Pass/Fail Criteria**:
- No secrets found in image
- DAST vulnerabilities found < 5 (low priority acceptable)
- Compliance checks pass

**Output Artifacts**:
- Security scan reports (SARIF format)
- DAST findings (XML/JSON)
- Compliance report

### Stage 5: Deployment Stage (Duration: 2-3 minutes)

**Purpose**: Deploy to production with GitOps

**Triggers**: Manual approval (can be accelerated if all SLIs met)

**Manual Gate**: Team reviews all artifacts, metrics, and test results before approval

**Deployment Flow**:

```
┌──────────────────────────────┐
│  Production Approval Gate    │
│  (Manual, 15-min window)     │
│  Team reviews:               │
│  ✓ Test results (green)      │
│  ✓ Security scan (clear)     │
│  ✓ Performance metrics (ok)  │
│  ✓ SBOM (audited)            │
└──────────────┬───────────────┘
               │  If approved
               ↓
┌──────────────────────────────┐
│  Update Git (source of truth)│
│  helm-charts/values-prod.yaml│
│  o rder-service.image.tag: "1.2.3" │
└──────────────┬───────────────┘
               │  Commit pushed
               ↓
┌──────────────────────────────┐
│  ArgoCD detects drift        │
│  Git desired: v1.2.3         │
│  Cluster actual: v1.2.2      │
│                              │
│  Syncs new version           │
└──────────────┬───────────────┘
               │
               ↓
    ┌──────────────────────┐
    │ Canary Phase 1 (1%)  │
    │ Pods: 1 of 100       │
    │ Monitor 5 minutes    │
    └──────────┬───────────┘
               │ Metrics ok?
               ↓
    ┌──────────────────────┐
    │ Canary Phase 2 (5%)  │
    │ Pods: 5 of 100       │
    │ Monitor 5 minutes    │
    └──────────┬───────────┘
               │ Metrics ok?
               ↓
    ┌──────────────────────┐
    │ Canary Phase 3 (25%) │
    │ Pods: 25 of 100      │
    │ Monitor 5 minutes    │
    └──────────┬───────────┘
               │ Metrics ok?
               ↓
    ┌──────────────────────┐
    │ Production (100%)    │
    │ Pods: 100 of 100     │
    │ DEPLOYMENT COMPLETE  │
    └──────────────────────┘
```

**Canary Decision Logic**:
```yaml
# ArgoCD Notification Rule
spec:
  progressDeadlineSeconds: 360
  selector:
    matchLabels:
      app: order-service
  strategy:
    canary:
      steps:
      - setWeight: 1
      - pause: {duration: 5m}
      - analysis:
          metrics:
          - name: error-rate
            query: rate(http_requests_total{status=~"5.."}[5m])
            successCriteria: < 0.01  # Error rate < 1%
          - name: latency-p99
            query: histogram_quantile(0.99, http_request_duration_seconds)
            successCriteria: < 500    # Latency p99 < 500ms
      - setWeight: 5
      - pause: {duration: 5m}
      - analysis: {...}
      - setWeight: 25
      - pause: {duration: 5m}
      - analysis: {...}
      - setWeight: 100
```

If canary metrics fail:
```bash
# Automatic rollback
kubectl rollout undo deployment/order-service -n production
# Back to v1.2.2 (previous working version)

# Notification
# Alert: "order-service v1.2.3 rollback - error rate exceeded threshold"
```

**Stage Outputs**:
- Deployment completion notification
- Kubernetes event logs
- Rollout progress status

---

## Practical Code Examples

### Example 1: Complete GitHub Actions Pipeline

```yaml
# .github/workflows/pipeline.yml
# Complete 5-stage pipeline from commit to production

name: Complete CI/CD Pipeline

on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/order-service
  JAVA_VERSION: '21'

jobs:
  # STAGE 1: COMMIT
  commit-stage:
    name: Commit Stage (5 min)
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'pull_request'
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven
      
      - name: Lint and format
        run: |
          cd order-service
          mvn spotless:check checkstyle:check
      
      - name: Run unit tests
        run: |
          cd order-service
          mvn clean test -DskipIntegration
      
      - name: Check code coverage
        run: |
          cd order-service
          mvn jacoco:check
      
      - name: SAST with SonarQube
        run: |
          cd order-service
          mvn sonar:sonar \
            -Dsonar.projectKey=order-service \
            -Dsonar.host.url=${{ secrets.SONAR_HOST }} \
            -Dsonar.login=${{ secrets.SONAR_TOKEN }}
      
      - name: Scan dependencies
        run: |
          cd order-service
          mvn org.owasp:dependency-check-maven:check
      
      - name: Secrets scan
        run: |
          cd order-service
          trufflehog filesystem . --json --fail

  # STAGE 2: BUILD
  build-stage:
    name: Build Stage (3-5 min)
    needs: commit-stage
    runs-on: ubuntu-latest
    if: success()
    
    outputs:
      image-digest: ${{ steps.image.outputs.digest }}
      image-url: ${{ steps.image.outputs.url }}
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven
      
      - name: Build image
        run: |
          cd order-service
          mvn spring-boot:build-image \
            -Dspring-boot.build-image.imageName=order-service:${{ github.sha }}
      
      - name: Generate SBOM
        run: |
          cd order-service
          mvn cyclonedx:makeBom
      
      - name: Login to registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Push image
        id: image
        run: |
          docker tag order-service:${{ github.sha }} \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          
          DIGEST=$(docker inspect --format='{{json .RepoDigests}}' \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} | jq -r '.[0]')
          echo "digest=$DIGEST" >> $GITHUB_OUTPUT
          echo "url=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@$DIGEST" >> $GITHUB_OUTPUT
      
      - name: Scan image
        run: |
          trivy image --severity HIGH,CRITICAL --exit-code 1 \
            ${{ steps.image.outputs.url }}
      
      - name: Sign image
        env:
          COSIGN_KEY: ${{ secrets.COSIGN_KEY }}
        run: |
          cosign sign --key env://COSIGN_KEY \
            ${{ steps.image.outputs.url }}

  # STAGE 3: INTEGRATION TESTS
  integration-stage:
    name: Integration Test Stage (8-12 min)
    needs: build-stage
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: testdb
          POSTGRES_PASSWORD: testpass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
      
      kafka:
        image: confluentinc/cp-kafka:7.5.0
        env:
          KAFKA_ZOOKEEPER_CONNECT: localhost:2181
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven
      
      - name: Run integration tests
        run: |
          cd order-service
          mvn test -DskipUnit \
            -Dspring.datasource.url=jdbc:postgresql://localhost/testdb \
            -Dspring.kafka.bootstrap-servers=localhost:9092
      
      - name: Run contract tests (Pact)
        run: |
          cd order-service
          mvn test -Ddependencies=contract

  # STAGE 4: SECURITY
  security-stage:
    name: Security Stage (6-10 min)
    needs: build-stage
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: DAST with ZAP
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'http://localhost:8080'
      
      - name: Container scanning
        run: |
          trivy image --severity CRITICAL --exit-code 1 \
            ${{ needs.build-stage.outputs.image-url }}
      
      - name: Secrets scanning
        run: |
          trufflehog github --repo ${{ github.repository }} \
            --json --fail

  # STAGE 5: DEPLOY
  deploy-stage:
    name: Deploy to Production (2-3 min)
    needs: [integration-stage, security-stage]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
      url: https://order-service.example.com
    
    steps:
      - uses: actions/checkout@v4
        with:
          repository: company/helm-charts
          token: ${{ secrets.HELM_CHARTS_TOKEN }}
      
      - name: Update production image tag
        run: |
          sed -i 's|order-service:.*|order-service:${{ github.sha }}|g' \
            charts/order-service/values-prod.yaml
      
      - name: Commit and push
        run: |
          git config user.name "CI/CD Pipeline"
          git config user.email "cicd@example.com"
          git add charts/order-service/values-prod.yaml
          git commit -m "chore: update order-service to ${{ github.sha }}"
          git push
      
      - name: Notify ArgoCD
        run: |
          curl -X POST https://argocd.example.com/api/v1/applications/order-service/sync \
            -H "Authorization: Bearer ${{ secrets.ARGOCD_TOKEN }}"

  # NOTIFICATIONS
  notify:
    name: Notify Results
    needs: [commit-stage, build-stage, integration-stage, security-stage]
    runs-on: ubuntu-latest
    if: always()
    
    steps:
      - name: Determine result
        run: |
          if [ "${{ needs.commit-stage.result }}" = "failure" ]; then
            echo "RESULT=FAILED (Commit Stage)" >> $GITHUB_ENV
          elif [ "${{ needs.build-stage.result }}" = "failure" ]; then
            echo "RESULT=FAILED (Build Stage)" >> $GITHUB_ENV
          elif [ "${{ needs.integration-stage.result }}" = "failure" ]; then
            echo "RESULT=FAILED (Integration Stage)" >> $GITHUB_ENV
          elif [ "${{ needs.security-stage.result }}" = "failure" ]; then
            echo "RESULT=FAILED (Security Stage)" >> $GITHUB_ENV
          else
            echo "RESULT=SUCCESS" >> $GITHUB_ENV
          fi
      
      - name: Slack notification
        uses: slackapi/slack-github-action@v1.24.0
        if: always()
        with:
          payload: |
            {
              "text": "Pipeline ${{ env.RESULT }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*order-service Pipeline ${{ env.RESULT }}*\nCommit: ${{ github.sha }}\nAuthor: ${{ github.actor }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Example 2: Kaniko Build for Rootless Container Security

```bash
#!/usr/bin/env bash
# build-image-kaniko.sh
# Builds Docker image without Docker daemon (rootless)
# More secure for CI/CD pipelines

set -euo pipefail

IMAGE_NAME="ghcr.io/company/order-service"
IMAGE_TAG="${CI_COMMIT_SHA:0:8}"
DOCKERFILE_PATH="${PWD}/order-service/Dockerfile"
BUILD_CONTEXT="${PWD}/order-service"

# Use Kaniko for rootless builds
docker run \
  --volumeremove ${BUILD_CONTEXT}:${BUILD_CONTEXT}:ro \
  --volume /var/run/secrets/kubernetes.io/serviceaccount/token:/var/run/secrets/token:ro \
  gcr.io/kaniko-project/executor:latest \
  --dockerfile=${DOCKERFILE_PATH} \
  --context=${BUILD_CONTEXT} \
  --destination=${IMAGE_NAME}:${IMAGE_TAG} \
  --destination=${IMAGE_NAME}:latest \
  --cache=true \
  --cache-repo=${IMAGE_NAME}/cache \
  --snapshot-mode=redo \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VCS_REF=${CI_COMMIT_SHA} \
  --build-arg VERSION=${IMAGE_TAG}

echo "✅ Image built and pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
```

### Example 3: ArgoCD Canary Configuration

```yaml
# k8s/argocd/order-service-canary.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: order-service
  namespace: production
spec:
  replicas: 100
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        version: "1.2.3"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      serviceAccountName: order-service
      containers:
      - name: order-service
        image: ghcr.io/company/order-service:1.2.3
        ports:
        - containerPort: 8080
          name: http
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: JAVA_OPTS
          value: "-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx1G"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
  
  # Canary strategy: Progressive rollout with metrics-driven promotion
  strategy:
    canary:
      steps:
      # Phase 1: 1% traffic (lowest risk)
      - setWeight: 1
      - pause:
          duration: 5m
      - analysis:
          interval: 1m
          threshold: 5
          metrics:
          - name: error-rate
            query: 'rate(http_requests_total{status=~"5.."}[5m])'
            successCriteria: '< 0.01'
            interval: 1m
          - name: latency-p99
            query: 'histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))'
            successCriteria: '< 500'
            interval: 1m
          - name: db-pool-usage
            query: 'db_connection_pool_usage_percent'
            successCriteria: '< 80'
            interval: 1m
      
      # Phase 2: 5% traffic
      - setWeight: 5
      - pause:
          duration: 5m
      - analysis:
          interval: 1m
          threshold: 5
          metrics:
          - name: error-rate
            query: 'rate(http_requests_total{status=~"5.."}[5m])'
            successCriteria: '< 0.01'
          - name: latency-p99
            query: 'histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))'
            successCriteria: '< 500'
      
      # Phase 3: 25% traffic
      - setWeight: 25
      - pause:
          duration: 10m
      - analysis:
          interval: 1m
          threshold: 5
          metrics:
          - name: error-rate
            query: 'rate(http_requests_total{status=~"5.."}[5m])'
            successCriteria: '< 0.01'
          - name: latency-p99
            query: 'histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))'
            successCriteria: '< 500'
          - name: cpu-usage
            query: 'rate(container_cpu_usage_seconds_total[5m])'
            successCriteria: '< 0.5'
      
      # Phase 4: 100% traffic (full production)
      - setWeight: 100
  
  # Automatic rollback on failure
  revisionHistoryLimit: 10
  
  # Pod disruption budget: at least 90% available during updates
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: production
spec:
  minAvailable: 90
  selector:
    matchLabels:
      app: order-service
---
# Prometheus rules for monitoring deployment
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: production
data:
  deployment-rules.yaml: |
    groups:
    - name: deployment.rules
      interval: 30s
      rules:
      # Alert if error rate exceeds threshold
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.01
        for: 2m
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"
      
      # Alert if latency p99 exceeds threshold
      - alert: HighLatencyP99
        expr: |
          histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        annotations:
          summary: "High p99 latency"
          description: "p99 latency is {{ $value }}s"
```

### ASCII Diagrams

**Diagram 1: Pipeline Flow and Timing**

```
Developer Push
     │
     ↓ (30 seconds)
┌─────────────────────────────────────┐
│ STAGE 1: COMMIT (5 min)             │
├─────────────────────────────────────┤
│ └─ Lint & format check      (5s)   │
│ └─ Unit Tests               (120s) │
│ └─ Code coverage check      (30s)  │
│ └─ SAST / SonarQube         (60s)  │
│ └─ Dependency scan          (60s)  │
│ └─ Secrets scan             (30s)  │
│                                    │
│  ✓ All checks pass → proceed       │
└──────────┬───────────────────────────┘
           │ (1 minute)
           ↓
     ┌──────────────────────────────────────┐
     │ STAGE 2: BUILD (3-5 min)             │
     ├──────────────────────────────────────┤
     │ └─ Compile JAR           (90s)      │
     │ └─ Build container       (60s)      │
     │ └─ Generate SBOM         (30s)      │
     │ └─ Push to registry      (60s)      │
     │ └─ Scan image with Trivy (120s)     │
     │ └─ Sign image            (30s)      │
     │                                     │
     │  ✓ Image registered → proceed       │
     └──────────┬──────────────────────────┘
                │ (1 minute)
        ┌───────┴───────┐
        ↓               ↓
  ┌──────────────┐ ┌──────────────┐
  │ STAGE 3:     │ │ STAGE 4:     │
  │ Integration  │ │ Security     │
  │ Tests        │ │ Scans        │
  │ (12 min)     │ │ (10 min)     │
  │ ├─E2E Tests  │ │ ├─DAST       │
  │ ├─Contract   │ │ ├─Container  │
  │ ├─Smoke      │ │ │  scanning  │
  │ └─Performance│ │ └─Compliance │
  └──────────────┘ └──────────────┘
        │               │
        └───────┬───────┘
                │ (Both pass)
                ↓
        ┌───────────────────━━━┐
        │ Manual Approval Gate │
        │ (15 min window)      │
        │ Team reviews all logs│
        └───────┬───────━━━━━━━┘
                │ (Approved)
                ↓
        ┌───────────────────────┐
        │ STAGE 5: DEPLOY       │
        ├───────────────────────┤
        │ └─ ArgoCD sync (1m)  │
        │ └─ Canary Phase 1 (5m)│
        │ └─ Canary Phase 2 (5m)│
        │ └─ Canary Phase 3 (5m)│
        │ └─ Canary Phase 4 (2m)│
        └───────┬───────────────┘
                │
        Total elapsed: 30 min
        (Parallelization reduces from 40+ min)
```

**Diagram 2: Canary Deployment Metrics Decision Tree**

```
                    Deploy v1.2.3
                         │
                         ↓
                  ┌─────────────┐
                  │ Canary 1%   │
                  │ (5 min)     │
                  └─────┬───────┘
                        │
              Check Metrics at t=5m
              if Pass: Error rate < 1%
                 AND Latency p99 < 500ms
                 AND DB pool < 80%
                        │
          ┌─────────────┴─────────────┐
          │                           │
       PASS                        FAIL
          │                           │
          ↓                           ↓
    ┌──────────┐            ┌──────────────────┐
    │Canary 5% │            │ AUTOMATIC ROLLBACK
    │ (5 min)  │            │ Revert to v1.2.2
    └────┬─────┘            │ ✓ Instant (2 min)
         │                  │ ✓ No data loss
         │                  │ ✓ Alert team
   Check Metrics            └──────────────────┘
         │
    ┌─PASS─┐
    │      │
    ↓      ↓ FAIL
Canary │    └─→ ROLLBACK
  25%  │
   │   │
   │ Check again
   │
PASS? → Canary 100%
   │     (done)
   │
   FAIL → ROLLBACK
```

---

# Image Promotion Strategy

## Textual Deep Dive

### Container Image Lifecycle and Promotion Gates

A container image progresses through environments based on validation at each gate. The promotion strategy prevents untested images from reaching production.

**Image Journey**:
```
┌─ Source Code (Git)
│  └─ Commit abc123
│
└─ Container Image Build
   └─ order-service:1.2.3-abc123f
      └─ Digest: sha256:xyz789...
         └─ Immutable reference
            └─ Can be promoted or rolled back anytime
```

**Promotion Strategy: Tag-Based vs Digest-Based**

❌ **WRONG: Mutable Tag Strategy**
```
dev-env: docker pull order-service:latest
         └─ Gets abc123... today
         └─ Gets def456... tomorrow (same tag!)
         └─ Inconsistent

production: docker run order-service:v1.2.3
            └─ Which v1.2.3? (could be overwritten)
            └─ Rollback impossible (which image?)
```

✅ **CORRECT: Immutable Digest Strategy**
```
Build Commit abc123f
  └─ Image: order-service:1.2.3
  └─ Digest: sha256:xyz789abc123...

Staging Deploy
  └─ kubectl set image deployment/order \
     order:xyz789abc123@sha256:...
  └─ Exact, immutable reference

Canary Deploy  
  └─ Exact same image (zero rebuild)
  └─ Same code, same config, same bytes

Production Deploy
  └─ Exact same image (zero rebuild)
  └─ Instant rollback: revert digest
```

### Tagging Strategy for Promotion

**Multi-tag approach** for traceability:

```bash
# Image built from commit abc123 with version 1.2.3
docker tag order-service order-service:1.2.3
docker tag order-service order-service:1.2.3-abc123f
docker tag order-service order-service:v1.2
docker tag order-service order-service:latest
docker tag order-service order-service:$BUILD_DATE-$BUILD_NUMBER

# Only the digest is immutable
# All tags are convenience labels pointing to same digest
docker push ghcr.io/company/order-service:1.2.3
# Output: ghcr.io/company/order-service:1.2.3@sha256:xyz789...
```

**In Kubernetes deployments**: Use digest, not tag
```yaml
spec:
  template:
    spec:
      containers:
      - name: order-service
        image: ghcr.io/company/order-service@sha256:xyz789abc123def456...  # ← Digest, not tag
```

### Promotion Gates (Quality Checkpoints)

```
┌─────────────────────────────────────────────────────┐
│ Image Created from Commit abc123f                   │
│ Digest: sha256:xyz789...                            │
└──────────────┬──────────────────────────────────────┘
               │
               ↓ GATE 1: Image Scan
        ┌──────────────────────┐
        │ Trivy Scan           │
        │ ✓ No critical CVEs   │
        │ ✓ Size < 500MB       │
        │ ✓ Base image approved │
        └──────────┬───────────┘
                   │ PASS
                   ↓
        ┌──────────────────────┐
        │ Dev/Staging Deploy   │
        │ Integration Tests    │
        │ ✓ Contract tests pass│
        │ ✓ E2E tests pass     │
        │ ✓ Health checks ok   │
        └──────────┬───────────┘
                   │ PASS
                   ↓
        ┌──────────────────────┐
        │ GATE 2: Promotion to │
        │ Staging Validated    │
        │ Metrics:             │
        │ ✓ Error rate < 1%    │
        │ ✓ Latency p99 < 500ms│
        │ ✓ CPU < 70%          │
        │ ✓ Memory < 80%       │
        └──────────┬───────────┘
                   │ PASS
                   ↓
        ┌──────────────────────┐
        │ GATE 3: Security     │
        │ Review               │
        │ ✓ SAST clear         │
        │ ✓ DAST clear         │
        │ ✓ Secrets scan clear │
        │ ✓ Compliance ok      │
        └──────────┬───────────┘
                   │ PASS
                   ↓
        ┌──────────────────────┐
        │ GATE 4: Manual       │
        │ Approval             │
        │ Team reviews logs    │
        │ Team approves        │
        └──────────┬───────────┘
                   │ APPROVED
                   ↓
        ┌─────────────────────────┐
        │ Production Canary Deploy│
        │ Monitor 20 minutes      │
        └─────────────────────────┘
```

### Rollback Strategy

**Scenario: Production Issue Detected**

```
Current Production: order-service v1.2.3 (digest: xyz789...)
Issue: Error rate spiked to 5%
       Database connections exhausted
       Users reporting timeouts

Rollback Decision:
  1. Metrics threshold exceeded
  2. Automatic trigger (or manual command)
  3. Kubernetes deployment reverted
  
# Revert to previous working image
kubectl rollout history deployment/order-service
deployment.apps/order-service
REVISION  CHANGE-CAUSE
1         (created)
2         image updated to order-service:v1.2.2
3         image updated to order-service:v1.2.3

kubectl rollout undo deployment/order-service --to-revision=2
# Back to v1.2.2 (digest: abc123...)

# Alternative: Direct image revert
kubectl set image deployment/order-service \
  order-service=ghcr.io/company/order-service@sha256:abc123... -n production

# Verify rollback
kubectl rollout status deployment/order-service
Waiting for deployment "order-service" rollout to finish: 50 replicas updated, 50 replicas total...

# Check metrics normalizing
Monitor error_rate dashboard → should drop within 2 minutes
```

**Prevention Measures**:
- Automated canary validations (no manual approval bypasses)
- Progressive rollout (never go 0→100%)
- SLI-driven promotion thresholds
- Runbooks for common failure modes
- Post-incident review (blameless)

### Case Study: Image Promotion in High-Frequency Trading

**Company**: Investment bank processing 100K+ transactions/minute

**Challenge**: Cannot afford application downtime during deployments

**Solution**:
```
Commit → Build → Staging Deploy (full integration tests)
           ↓
      If tests pass in 10 minutes:
      └─ Automatic promotion to Canary
      
Canary Phase 1 (1% traffic):
  └─ Monitor 5 minutes
  └─ SLI check: transaction success rate > 99.9%
  └─ If pass → Phase 2 (5% traffic, 5 min)
  └─ If fail → Automatic rollback + alert
  
Result:
  - Deployment success rate: 99.7%
  - Deployment time: 25 minutes
  - MTTR (mean time to recovery): 3 minutes
  - Production impact: zero (canary catches issues)
```

---

## Practical Code Examples

### Example 1: Promotion Pipeline with Automated Gates

```yaml
# argocd-promotion-controller.yaml
# Automatically promotes images through environments based on metrics

apiVersion: v1
kind: ConfigMap
metadata:
  name: promotion-rules
  namespace: argocd
data:
  promotion-policy.yaml: |
    promotionRules:
    - name: order-service-promotion
      source: staging
      target: production
      conditions:
      - type: test-passing
        duration: 10m
      - type: metrics
        metrics:
          - name: error-rate
            query: 'rate(http_requests_total{status=~"5.."}[5m])'
            threshold: '< 0.01'
            duration: 5m
          - name: latency-p99
            query: 'histogram_quantile(0.99, http_request_duration_seconds)'
            threshold: '< 0.5'
            duration: 5m
      - type: security-gate
        checkTypes:
          - sast
          - dast
          - secrets-scan
      - type: approval
        approvers:
          - platform-team
        timeout: 15m

---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: order-service-promotion
  namespace: argocd
spec:
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
  
  generators:
  # Generate applications for each environment
  - list:
      elements:
      - environment: staging
        cluster: staging-cluster
      - environment: production
        cluster: production-cluster
  
  template:
    metadata:
      name: order-service-{{ environment }}
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/company/helm-charts
        targetRevision: main
        path: charts/order-service
        helm:
          releaseName: order-service
          values: |
            environment: {{ environment }}
            image:
              registry: ghcr.io
              repository: company/order-service
              tag: $IMAGE_TAG  # Populated from promotion gate
      
      destination:
        server: {{ cluster }}
        namespace: {{ environment }}
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

### Example 2: Image Promotion Script

```bash
#!/usr/bin/env bash
# promote-image.sh
# Promotes image through environments with validation gates

set -euo pipefail

SOURCE_ENV=${1:-staging}
TARGET_ENV=${2:-production}
IMAGE_NAME=${3:-order-service}
DRY_RUN=${4:-false}

REGISTRY="ghcr.io/company"
CURRENT_DIGEST=$(docker inspect --format='{{json .RepoDigests}}' \
  ${REGISTRY}/${IMAGE_NAME}:latest | jq -r '.[0]' | cut -d@ -f2)

echo "Promoting ${IMAGE_NAME}"
echo "Source Digest: ${CURRENT_DIGEST}"
echo "From: ${SOURCE_ENV}"
echo "To: ${TARGET_ENV}"
echo "Dry Run: ${DRY_RUN}"

# ===== GATE 1: Image Scan =====
echo ""
echo "→ Running vulnerability scan..."
SCAN_RESULTS=$(trivy image --format json \
  ${REGISTRY}/${IMAGE_NAME}@${CURRENT_DIGEST} | jq '.Results[]?.Vulnerabilities[]?')

CRITICAL_COUNT=$(echo "$SCAN_RESULTS" | jq 'select(.Severity=="CRITICAL")' | wc -l)
HIGH_COUNT=$(echo "$SCAN_RESULTS" | jq 'select(.Severity=="HIGH")' | wc -l)

if [ "$CRITICAL_COUNT" -gt 0 ]; then
  echo "❌ GATE 1 FAILED: Found ${CRITICAL_COUNT} critical vulnerabilities"
  echo "$SCAN_RESULTS" | jq '.' 
  exit 1
fi

if [ "$HIGH_COUNT" -gt 2 ]; then
  echo "❌ GATE 1 FAILED: Found ${HIGH_COUNT} high vulnerabilities (max 2 allowed)"
  exit 1
fi

echo "✅ GATE 1 PASSED: Image scan clean"

# ===== GATE 2: Integration Tests =====
echo ""
echo "→ Checking integration test results..."
TEST_RESULTS=$(kubectl get deployment ${IMAGE_NAME} -n ${SOURCE_ENV} \
  -o jsonpath='{.metadata.annotations.test-results}')

if [ "$TEST_RESULTS" != "passed" ]; then
  echo "❌ GATE 2 FAILED: Integration tests in ${SOURCE_ENV} not passing"
  exit 1
fi

echo "✅ GATE 2 PASSED: Integration tests passed"

# ===== GATE 3: Metrics Validation =====
echo ""
echo "→ Checking metrics from ${SOURCE_ENV}..."

# Query Prometheus for staging metrics
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..$',env='${SOURCE_ENV}'}[5m])" \
  | jq '.data.result[0].value[1]' 2>/dev/null || echo "0")

LATENCY_P99=$(curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,http_request_duration_seconds{env='${SOURCE_ENV}'})" \
  | jq '.data.result[0].value[1]' 2>/dev/null || echo "0")

echo "  Error Rate: ${ERROR_RATE}%"
echo "  P99 Latency: ${LATENCY_P99}ms"

if (( $(echo "$ERROR_RATE > 1" | bc -l) )); then
  echo "❌ GATE 3 FAILED: Error rate ${ERROR_RATE}% exceeds 1% threshold"
  exit 1
fi

if (( $(echo "$LATENCY_P99 > 500" | bc -l) )); then
  echo "❌ GATE 3 FAILED: P99 latency ${LATENCY_P99}ms exceeds 500ms threshold"
  exit 1
fi

echo "✅ GATE 3 PASSED: Metrics within acceptable range"

# ===== GATE 4: Security Review =====
echo ""
echo "→ Checking security scan results..."
SAST_REPORT=$(kubectl get configmap ${IMAGE_NAME}-sast -n ${SOURCE_ENV} \
  -o jsonpath='{.data.findings}' 2>/dev/null || echo "{}")

CRITICAL_SAST=$(echo "$SAST_REPORT" | jq '[.[] | select(.severity=="CRITICAL")] | length' 2>/dev/null || echo "0")

if [ "$CRITICAL_SAST" -gt 0 ]; then
  echo "❌ GATE 4 FAILED: Found ${CRITICAL_SAST} critical security findings"
  exit 1
fi

echo "✅ GATE 4 PASSED: Security review passed"

# ===== Promotion =====
echo ""
echo "✅ All gates passed - proceeding with promotion"

if [ "$DRY_RUN" = "true" ]; then
  echo "[DRY RUN] Would promote:"
  echo "  Image: ${REGISTRY}/${IMAGE_NAME}@${CURRENT_DIGEST}"
  echo "  To: ${TARGET_ENV}"
  exit 0
fi

# Update target environment configuration
echo "→ Updating ${TARGET_ENV} configuration..."

# Get current promoted version for rollback reference
PREVIOUS_DIGEST=$(kubectl get deployment ${IMAGE_NAME} -n ${TARGET_ENV} \
  -o jsonpath='{.metadata.annotations.deployed-digest}' 2>/dev/null || echo "")

# Update deployment
kubectl set image deployment/${IMAGE_NAME} \
  ${IMAGE_NAME}=${REGISTRY}/${IMAGE_NAME}@${CURRENT_DIGEST} \
  -n ${TARGET_ENV}

# Store metadata for rollback
kubectl patch deployment ${IMAGE_NAME} -n ${TARGET_ENV} \
  -p "{\"metadata\":{\"annotations\":{\"promoted-from\":\"${SOURCE_ENV}\",\"promoted-at\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\",\"promoted-by\":\"${USER}\",\"deployed-digest\":\"${CURRENT_DIGEST}\",\"previous-digest\":\"${PREVIOUS_DIGEST}\"}}}"

# Wait for rollout
kubectl rollout status deployment/${IMAGE_NAME} -n ${TARGET_ENV} --timeout=5m

echo ""
echo "✅ PROMOTION COMPLETE"
echo "  Image: ${REGISTRY}/${IMAGE_NAME}@${CURRENT_DIGEST}"
echo "  Target: ${TARGET_ENV}"
echo "  Time: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
```

### Example 3: ArgoCD Notification for Promotion Status

```yaml
# argocd-notifier-canary.yaml
# Sends notifications when promoted image to production

apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.webhook.slack: |
    token: $SLACK_TOKEN
  
  trigger.image-promoted: |
    - when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
      oncePer: app.status.operationState.finishedAt
      send: [image-promoted-notification]
  
  template.image-promoted-notification: |
    message: |
      Image promoted to {{ .app.spec.destination.namespace }}
      Deployment: {{ .app.metadata.name }}
      Status: {{ .app.status.operationState.phase }}
      Health: {{ .app.status.health.status }}
    
    slack:
      attachments: |
        [{
          "color":"#18be52",
          "fields":[
            {"title":"Sync Status","value":"{{ .app.status.operationState.phase }}"},
            {"title":"Repository","value":"{{ .app.spec.source.repoURL }}"},
            {"title":"Revision","value":"{{ .app.spec.source.targetRevision }}"},
            {"title":"Author","value":"{{ (call .repo.GetCommitMetadata .app.spec.source.targetRevision).Author }}"},
            {"title":"Message","value":"{{ (call .repo.GetCommitMetadata .app.spec.source.targetRevision).Message }}"}
          ]
        }]
```

### ASCII Diagrams

**Diagram 1: Image Promotion Flow**

```
Commit abc123 →Build Image→ Digest: sha256:xyz789
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌──────GATE 1──────┐     ┌─────GATE 2─────┐
            │ Image Scan       │     │ SAST/Secrets   │
            │ ✓ No critical CVEs      │ ✓ Clear scan    │
            │ ✓ < 500MB        │     │ ✓ No passwords  │
            └────────┬─────────┘     └────────┬────────┘
                     │                        │
                     └──────────┬─────────────┘
                                │
                    ┌───────────↓────────────┐
                    │   Deploy to Staging    │
                    │ ├─ Run Integration Tests
                    │ ├─ Run E2E Tests
                    │ └─ Monitor 10 minutes
                    └──────────┬─────────────┘
                               │
                 ┌─────────────↓──────────────┐
                 │   GATE 3: Metrics Check    │
                 │ ✓ Error rate < 1%          │
                 │ ✓ P99 latency < 500ms      │
                 │ ✓ CPU < 70%                │
                 │ ✓ Memory < 80%             │
                 └──────────┬──────────────────┘
                            │
                 ┌──────────↓────────────┐
                 │ GATE 4: Manual Review │
                 │ Team approves         │
                 │ (15 min timeout)      │
                 └──────────┬────────────┘
                            │
              ┌─────────────↓──────────────┐
              │  Production Canary Deploy  │
              │  10% Phase 1               │
              │  25% Phase 2               │
              │  50% Phase 3               │
              │  100% Phase 4              │
              │  (20 minutes total)        │
              │                            │
              │ If metrics good    →  SUCCESS
              │ If metrics bad     →  ROLLBACK
              └────────────────────────────┘
```

---

*Continued in Part 4: Deployment Strategies Through Interview Questions*
