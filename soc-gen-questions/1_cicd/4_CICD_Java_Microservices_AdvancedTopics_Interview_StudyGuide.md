# Part 4: Deployment Strategies, Dependencies, Observability, Security & Interview Questions
**Final Part of Java Microservices CI/CD Study Guide**

---

# Deployment Strategies

## Textual Deep Dive

Deployment strategy defines *how* code reaches production. For microservices, the strategy balances speed (deployment frequency) with safety (blast radius reduction, instant rollback capability).

### Blue-Green Deployment

**Concept**: Two identical production environments (Blue and Green). Traffic switches entirely from one to the other.

**Example**:
```
Current: Blue environment (v1.2.2) serves 100% traffic
         Green environment (idle)

Deployment:
  1. Deploy v1.2.3 to Green environment
  2. Run full smoke tests on Green
  3. Load tests on Green
  4. Switch router: Blue → Green (traffic switches instantly)
  5. Monitor Green (v1.2.3)
  6. If issues: Switch back: Green → Blue (v1.2.2)

Advantages:
  ✓ Zero-downtime deployments
  ✓ Instant rollback (2 seconds)
  ✓ Full production test before traffic
  ✗ Requires 2x infrastructure cost
  ✗ Database migrations complex (schema changes mid-deployment)

Best For:
  - Stateless services (no local data)
  - Monoliths (too slow for per-service)
  - Database schema unchanged
```

**Kubernetes Implementation**:
```yaml
# Blue environment (production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-blue
  namespace: production
spec:
  replicas: 50
  template:
    spec:
      containers:
      - name: order-service
        image: ghcr.io/company/order-service:1.2.2
---
# Green environment (new version staging)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-green
  namespace: production
spec:
  replicas: 50
  template:
    spec:
      containers:
      - name: order-service
        image: ghcr.io/company/order-service:1.2.3
---
# Service selects which deployment to route to
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: production
spec:
  selector:
    app: order-service
    version: blue    # ← Switch to "green" to flip traffic
  ports:
  - port: 80
    targetPort: 8080
---
# Switch traffic: kubectl patch svc order-service -p '{"spec":{"selector":{"version":"green"}}}'
```

### Canary Deployment

**Concept**: Gradually shift traffic from old version to new. Monitor metrics at each step, automatic rollback if issues.

**Phases**:
```
Phase 1: 1% traffic (10 users) → Monitor 5 min → If OK, Phase 2
Phase 2: 5% traffic (50 users) → Monitor 5 min → If OK, Phase 3
Phase 3: 25% traffic (250 users) → Monitor 10 min → If OK, Phase 4
Phase 4: 100% traffic (10K users) → Done

Total time: 25 minutes (vs blue-green: 2 min deploy, 1 hour testing)
Blast radius at phase 1: 10 users (not 10K)
```

**Advantages**:
- Gradual traffic shift reduces risk
- Real users validate behavior early
- Cost-efficient (no extra infrastructure)
- SLI-driven decisions (automated)

**Disadvantages**:
- Longer deployment (25 min vs 2 min)
- Version mismatch complexity (multiple versions live)
- Session affinity issues (user sees two versions)
- Database backwards compatibility required

**Implementation with Argo Rollouts**:
```yaml
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
  strategy:
    canary:
      steps:
      - setWeight: 1    # 1% = 1 pod
      - pause:
          duration: 5m
      - analysis:
          metrics:
          - name: error-rate
            query: rate(http_requests_total{status=~"5.."}[5m])
            successCriteria: < 0.01
          - name: latency-p99
            query: histogram_quantile(0.99, http_request_duration_seconds)
            successCriteria: < 0.5
      
      - setWeight: 5     # 5% = 5 pods
      - pause: {duration: 5m}
      - analysis:
          metrics:
          - name: error-rate
            query: rate(http_requests_total{status=~"5.."}[5m])
            successCriteria: < 0.01
      
      - setWeight: 25    # 25% = 25 pods
      - pause: {duration: 10m}
      
      - setWeight: 100   # 100% = all pods
```

**Case Study: E-Commerce Black Friday**
```
Services: order-service, payment-service, inventory-service

Goal: Deploy 3 services with zero downtime during peak traffic

Process:
1. Deploy order-service v2.1.0
   └─ Canary 1% (100 concurrent users out of 100K)
   └─ Monitor payment API compatibility
   └─ Error rate: 0.5% ✓ Pass → Phase 2
   
2. Canary 5% (5K users)
   └─ Monitor database load (queries/sec)
   └─ Database response time: 45ms ✓ Pass → Phase 3
   
3. Canary 25% (25K users)
   └─ Monitor cache hit rate
   └─ Cache hit rate: 92% ✓ Pass → 100%
   
4. Deploy payment-service v3.0.0
   └─ Same canary process
   
5. Deploy inventory-service v1.5.0
   └─ Same canary process

Result:
- 3 services deployed in 2 hours
- Zero user-visible downtime
- Automatic rollback if metrics degrade
- Confidence in production behavior from real users
```

### Feature Flags (Release without Deployment)

**Concept**: Code deployed but feature hidden behind flag. Enable/disable without redeployment.

**Use Cases**:
- Decouple deployment from release
- A/B testing in production
- Gradual feature rollout
- Kill switches for broken features

**Implementation**:
```java
@Service
public class OrderService {
    private final FeatureFlagClient flagClient;
    
    public void processOrder(Order order) {
        // Check feature flag at runtime
        if (flagClient.isEnabled("order.async-processing", order.getCustomerId())) {
            // New async implementation (v2)
            processOrderAsync(order);
        } else {
            // Fallback to synchronous (v1)
            processOrderSync(order);
        }
    }
    
    public void processOrderSync(Order order) {
        // Old implementation
        payment.charge(order);
        inventory.reduce(order.getItems());
        order.setStatus(COMPLETED);
    }
    
    public void processOrderAsync(Order order) {
        // New implementation
        kafkaTemplate.send("order-topic", order);
        order.setStatus(PROCESSING);
    }
}
```

**Feature Flag Configuration**:
```yaml
# Feature flags stored in Vault or ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  namespace: production
data:
  flags.json: |
    {
      "order.async-processing": {
        "enabled": true,
        "rollout": {
          "percentage": 10,  # Enable for 10% of users
          "users": ["user-1", "user-2"]  # Specific users
        }
      },
      "order.new-payment-gateway": {
        "enabled": false,
        "killswitch": true  # Can disable instantly
      }
    }
```

**Deployment Flow**:
```
Commit: new payment gateway implementation
  ↓
Build + Test + (feature flag DEFAULT: off)
  ↓
Deploy to production
  Feature appears in code, but hidden by flag
  ↓
Manual: Enable for 1% of users
  └─ Monitor error rate
  └─ If OK → Enable for 10%
  └─ If OK → Enable for 100%
  ↓
Result: Released without redeployment
        Can disable instantly without rollback
```

### Production Comparison

| Strategy | Deployment Time | Rollback Time | Cost | Risk | Best For |
|----------|-----------------|---------------|------|------|----------|
| **Blue-Green** | 2 min | 2 sec | 2x infra | Low | Monoliths, stateless services |
| **Canary** | 25 min | 2 min | 1x infra | Very low | Microservices, high traffic |
| **Feature Flags** | 0 min (code deploy only) | Instant | 1x infra | Medium (flag logic) | A/B testing, gradual rollout |
| **Rolling Update** | 10 min | 10 min | 1.2x infra | Medium | Batch jobs, non-critical |

---

# Handling Microservices Dependencies

## Textual Deep Dive

Microservices create complex dependency graphs. CI/CD must validate not only individual service correctness but also service-to-service compatibility.

### Dependency Types

**1. Synchronous Dependencies (gRPC, REST)**
```
Order Service → calls /api/payments/charge → Payment Service
                                              (immediate response)

Risk: If Payment Service down, Order Service fails
Solution: Circuit breaker, fallback, retry logic
```

**2. Asynchronous Dependencies (Message Queues)**
```
Order Service → publishes order-created event → Kafka topic
                                                 ↓
                                    Inventory Service
                                    Process later

Risk: Ordering of events, message loss, duplicate processing
Solution: Idempotent handlers, event sourcing, DLQ
```

**3. Database Dependencies**
```
Order Service → writes to shared PostgreSQL
Inventory Service → writes to shared PostgreSQL

Risk: Different services make incompatible schema changes
Solution: Database per service, change compatibility testing
```

### Dependency Mapping

**Create Service Dependency Diagram**:
```
                   ┌─────────────┐
                   │   API Gateway│
                   └──────┬──────┘
                          │
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │  Order   │      │ Payment  │      │Inventory │
  │ Service  │──→   │ Service  │      │ Service  │
  └────┬─────┘      └──────────┘      └────┬─────┘
       │                                    │
       └──────────────┬─────────────────────┘
                      ↓
             ┌─────────────────┐
             │   PostgreSQL    │
             │   Shared DB     │
             └─────────────────┘
                      ↑
                      │
             ┌─────────────────┐
             │  Kafka Topics   │
             │  order-created  │
             │  payment-made   │
             └─────────────────┘
```

### Contract Testing (Pact Framework)

**Problem**: Payment Service changes API response format
```
Payment Service v1.0:
  POST /api/payments/charge
  Response: {"transactionId": "123", "status": "SUCCESS", "amount": 99.99}

Payment Service v1.1:
  POST /api/payments/charge
  Response: {"txnId": "123", "result": "APPROVED", "price": 99.99}
  
Order Service still expects OLD format
  └─ "transactionId" field renamed to "txnId"
  └─ Parse fails, exception, order fails
```

**Solution: Pact Contract Testing**
```
╔══════════════════════╗     ╔════════════════════╗
║  Order Service       ║     ║  Payment Service   ║
║  (Consumer)          ║     ║  (Provider)        ║
╚──────────┬───────────╝     ╚────────┬───────────╝
           │                         │
           └─ Pact Contract ────────→│
             "expects calls with
              responses in format X"
           │                         │
           ├─ Pact Test ────────────→│
             (mock provider)         │
           │                         │
           └─ Pact Verification ────→│
             (real API confirms
              it honors contract)
```

**Pact Test Example**:
```java
@PactTestFor(providerName = "payment-service")
class OrderServiceConsumerPactTest {
    
    @Pact(consumer = "order-service")
    public V4Pact chargePaymentPact(PactBuilder builder) {
        return builder
            .given("payment service is available")
            .uponReceiving("a charge request for valid amount")
            .path("/api/payments/charge")
            .method("POST")
            .headers("Content-Type", "application/json")
            .body(json("""
            {
              "orderId": 123,
              "amount": 99.99,
              "currency": "USD"
            }
            """))
            .willRespondWith()
            .status(200)
            .body(json("""
            {
              "transactionId": "txn_12345",  # ← Field name contracts
              "status": "SUCCESS",
              "amount": 99.99
            }
            """))
            .toPact();
    }
}

// Payment Service Verification Test
@PactTestFor(providerName = "payment-service")
class PaymentServiceProviderPactTest extends PactVerificationSpringBootTests {
    
    @BeforeEach
    void before() {
        // Register Pact from consumer
        // Verify Payment Service honors contract
    }
    
    @Test
    void testPaymentChargeContract() {
        // This test runs against REAL Payment Service API
        // Confirms it returns response matching contract
    }
}
```

**CI Integration**:
```yaml
# GitHub Actions
- name: Run Pact Consumer Tests
  run: mvn test -Dtest=*ConsumerPactTest
  
- name: Publish Pacts to Broker
  run: |
    curl -X PUT http://pact-broker:8080/pacts/provider/payment-service/consumer/order-service/version/${{ github.sha }} \
      -H 'Content-Type: application/json' \
      -d @target/pacts/*.json

# In Payment Service CI:
- name: Verify Pact Contracts
  run: |
    mvn test -Dtest=*ProviderPactTest \
      -Dpact.producer.version=${{ github.sha }}
```

### Service Dependency Testing

**Integration Test with Real Dependencies**:
```yaml
# docker-compose.yml - Full stack for integration testing
version: '3'
services:
  order-service:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - kafka
      - payment-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/testdb
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      PAYMENT_SERVICE_URL: http://payment-service:8080
  
  payment-service:
    build:
      context: ../payment-service
      dockerfile: Dockerfile.dev
    ports:
      - "8081:8080"
    depends_on:
      - postgres
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: testdb
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
  
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

volumes:
  postgres_data:
```

**Test Order Flow with All Dependencies**:
```java
@IntegrationTest
@Testcontainers
class OrderToPaymentServiceIntegrationTest {
    
    @Container
    static DockerComposeContainer compose = 
        new DockerComposeContainer(new File("docker-compose.yml"))
            .withExposedService("order-service", 8080)
            .withExposedService("payment-service", 8080)
            .withExposedService("postgres", 5432);
    
    @Test
    void testOrderProcessingWithPaymentService() throws Exception {
        // Create order via Order Service
        ResponseEntity<OrderResponse> response = restTemplate.postForEntity(
            "http://localhost:8080/api/orders",
            new CreateOrderRequest(
                customerId = 123L,
                items = List.of(new Item("SKU123", 2)),
                amount = BigDecimal.valueOf(99.99)
            ),
            OrderResponse.class
        );
        
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        Long orderId = response.getBody().getId();
        
        // Order Service calls Payment Service
        // Wait for async payment processing
        await().atMost(5, SECONDS)
            .pollInterval(500, MILLISECONDS)
            .until(() -> {
                Order order = orderRepository.findById(orderId).orElseThrow();
                return order.getStatus() == OrderStatus.PAID;
            });
        
        // Verify payment was recorded
        Order paidOrder = orderRepository.findById(orderId).orElseThrow();
        assertThat(paidOrder.getTransactionId()).isNotBlank();
        assertThat(paidOrder.getStatus()).isEqualTo(OrderStatus.PAID);
    }
}
```

---

# Observability Integrated to CI/CD

## Textual Deep Dive

Observability data drives CI/CD decisions. Metrics from production inform whether deployments should proceed or rollback.

### Three Pillars of Observability

**1. Metrics** (quantitative measurements)
```
- Request rate: 10,000 req/sec
- Error rate: 0.5% (50 errors per 10K requests)
- Latency p99: 450ms
- JVM GC time: 80ms
- Database connection pool: 95 of 100 connections
- Cache hit rate: 92%
```

**2. Logs** (detailed events)
```
2024-04-16T15:32:45.123Z [ERROR] OrderService - 
  Failed to charge payment for orderId=123456
  Cause: PaymentService timeout after 5s
  RetryAttempt: 1/3
  TraceId: 550e8400-e29b-41d4-a716-446655440000
```

**3. Traces** (request journey across services)
```
POST /api/orders → [5ms]
  ├─ Validate Order → [2ms]
  ├─ Call Payment Service → [150ms]
  │  └─ POST /api/payments/charge → [145ms]
  ├─ Call Inventory Service → [30ms]
  │  └─ POST /api/inventory/reduce → [25ms]
  └─ Persist to DB → [10ms]

Total: 195ms
```

### Metrics Collection in Java

**Spring Boot Micrometer Integration**:
```java
@Service
@Slf4j
public class OrderService {
    private final MeterRegistry meterRegistry;
    
    public OrderService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }
    
    public Order processOrder(Order order) {
        Timer.Sample sample = Timer.start(meterRegistry);
        
        try {
            // Business logic
            payment.charge(order);
            inventory.reduce(order.getItems());
            
            meterRegistry.counter("orders.processed",
                "status", "success",
                "customer_type", order.getCustomer().getType())
                .increment();
            
            log.info("Order processed successfully",
                "order_id", order.getId(),
                "trace_id", TraceContext.current().getTraceId());
            
            return order;
            
        } catch (PaymentException e) {
            meterRegistry.counter("orders.processed",
                "status", "failure",
                "reason", "payment_failed")
                .increment();
            throw e;
            
        } finally {
            sample.stop(Timer.builder("order.processing.duration")
                .tag("status", /* success or failure */)
                .register(meterRegistry));
        }
    }
}
```

**Exposed Metrics Endpoint**:
```bash
curl http://order-service:8080/actuator/prometheus

# Output:
order_processing_duration_seconds_count{status="success"} 1523
order_processing_duration_seconds_sum{status="success"} 284.567
orders_processed_total{status="success"} 1523
orders_processed_total{status="failure",reason="payment_failed"} 12
payment_service_calls_duration_seconds_bucket{le="0.1",status="success"} 1000
payment_service_calls_duration_seconds_bucket{le="0.5",status="success"} 1500
...
```

### SLI-Driven Deployment Decisions

**Service Level Indicator (SLI): Measurable aspects of service behavior**
```
SLI = (Successful requests) / (Total requests)

Example:
  Total requests: 10,000
  Failed requests (5xx): 50
  SLI = (10,000 - 50) / 10,000 = 99.5%
```

**SLO: Service Level Objective (target SLI)**
```
SLO: Order Service must maintain 99.9% availability (SLI > 99.9%)
     Latency p99 < 500ms
```

**Error Budget: Allowed failures before violating SLO**
```
SLI Target: 99.9%
Error Budget: 100% - 99.9% = 0.1%

Per day: 86,400 seconds * 0.1% = 86.4 seconds of allowed errors
Per month: ~44 minutes of allowed errors

If deployed version causes 99.5% SLI:
  └─ Error budget exceeded
  └─ Automatic rollback triggered
```

**Canary metrics-driven decisions**:
```yaml
# ArgoCD Rollout with SLI gates
spec:
  strategy:
    canary:
      steps:
      - setWeight: 1
      - pause: {duration: 5m}
      - analysis:
          metrics:
          - name: success-rate
            query: 'rate(http_requests_total{status=~"2.."}[5m])'
            successCriteria: '>= 0.999'    # >= 99.9%
            interval: 1m
            consecutiveSuccesses: 3        # Pass 3 times before proceeding
          - name: latency-p99
            query: 'histogram_quantile(0.99, http_request_duration_seconds)'
            successCriteria: '< 0.5'       # < 500ms
            interval: 1m
            
      # If metrics fail:
      onFailure: rollback               # Automatic rollback
      failurePolicy: abort              # Stop promotion
```

---

# Security and Compliance

## Textual Deep Dive

Security in CI/CD spans code, dependencies, containers, and runtime.

### Shift-Left Security (Moving Security Early)

**Cost of Security Fixes by Stage**:
```
Commit Stage (SAST):     $100 (1 developer, 15 min)
  ↓
Build Stage (Container): $400 (rebuild + retest)
  ↓
Staging Stage:           $4,000 (dev time, QA time)
  ↓
Production:              $100,000+ (incident response, customer impact, reputation)
```

**Shift-left implementation**:
```
Commit: Developer runs:
  └─ mvn spotbugs:check      (find bugs with patterns)
  └─ mvn spotless:check      (format check)
  └─ trufflehog scan         (secrets scan)
  └─ mvn dependency-check    (dependency CVE scan)
  └─ Pre-commit hook blocks if anything fails
  
Build: Automated container scanning
  └─ Trivy image scan
  └─ Cosign sign image
  
Security stage: DAST on running app
  └─ OWASP ZAP scan
  └─ Check headers (CSP, HSTS, etc.)
```

### SAST (Static Analysis Security Testing)

**Tools**: SonarQube, Checkmarx, Snyk

**Detects**: Code patterns indicating vulnerabilities
```
❌ SQL Injection Risk:
   String query = "SELECT * FROM orders WHERE id = " + userId;
   Database.execute(query);
   
✅ Parameterized Query:
   String query = "SELECT * FROM orders WHERE id = ?";
   Database.execute(query, userId);
```

### Dependency Management

**Vulnerability Tracking**:
```bash
# Maven Central Security Scanner
mvn org.owasp:dependency-check-maven:check

# Scans all transitive dependencies
# Output:
Dependency: log4j-core-2.14.0
  CVE-2021-44228 (CRITICAL)
  Title: "Apache Log4j2 Remote Code Execution"
  CVSS Score: 10.0
  Fix Version: 2.17.0 or later
```

**Dependency Update Strategy**:
```
Each month:
  1. Review new vulnerability reports
  2. Update vulnerable dependencies
  3. Run full test suite
  4. Deploy in non-peak hours
  5. Monitor for issues
  
Renovate Bot (automated):
  - Scans pom.xml weekly
  - Creates PR with updates
  - Runs CI automatically
  - If tests pass, auto-merge
```

### SBOM (Software Bill of Materials)

**Requirements** (NTIA + CISA):
```
Required:
  - Name and version of component
  - Supplier of component
  - Unique identifier (CPE, PURL)
  - Timestamp

Generated via Maven:**
```bash
mvn cyclonedx:makeBom
```

**CycloneDX Format Example:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<bom xmlns="http://cyclonedx.org/schema/bom/1.4">
  <components>
    <component type="library">
      <name>spring-boot-starter-web</name>
      <version>3.1.5</version>
      <purl>pkg:maven/org.springframework.boot/spring-boot-starter-web@3.1.5</purl>
      <licenses>
        <license>
          <name>Apache License 2.0</name>
        </license>
      </licenses>
    </component>
    <component type="library">
      <name>postgresql</name>
      <version>42.6.0</version>
      <purl>pkg:maven/org.postgresql/postgresql@42.6.0</purl>
    </component>
  </components>
</bom>
```

### Container Image Security

**Rootless Execution**:
```dockerfile
# Create non-root user
RUN useradd -m -u 1001 appuser

# Run as non-root
USER appuser
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Image Signing (Cosign)**:
```bash
# Sign image
cosign sign --key cosign.key ghcr.io/company/order-service:1.2.3

# Verify signature (before deployment)
cosign verify --key cosign.pub ghcr.io/company/order-service:1.2.3
```

**Kubernetes Image Verification**:
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-signature-verification
webhooks:
- name: verify.sigstore.dev
  clientConfig:
    url: https://policy-webhook:8443/verify
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  failurePolicy: Fail
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

### DAST (Dynamic Application Security Testing)

**OWASP ZAP Scan**:
```bash
zaproxy -cmd \
  -quickurl http://order-service:8080 \
  -quickout results.json

# Checks for:
# - XSS (Cross-Site Scripting)
# - SQL Injection
# - CSRF (Cross-Site Request Forgery)
# - Authentication bypass
# - Sensitive data exposure
```

### Runtime Security (Policy Enforcement)

**OPA/Gatekeeper for Kubernetes**:
```rego
# policy.rego
# Enforce: Images must be signed
# Enforce: No privileged containers

package kubernetes.admission

deny["Image not signed"] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not contains(container.image, "@sha256:")
}

deny["No privileged containers allowed"] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
}
```

---

# Hands-On Scenarios

## Scenario 1: Deploy New Microservice Version with Canary

**Objective**: Safely deploy order-service v1.2.3 to production while monitoring SLIs

**Prerequisites**:
- Kubernetes cluster (prod, staging namespaces)
- ArgoCD configured
- Prometheus collecting metrics
- order-service v1.2.2 running (100 pods)

**Steps**:

1. **Build and Publish Image**:
```bash
git tag v1.2.3
git push origin v1.2.3

# GitHub Actions triggered:
# → Commit stage passes
# → Build stage creates image
# → Image published: ghcr.io/company/order-service:1.2.3
#   Digest: sha256:abc123def456xyz789...
```

2. **Update Helm Values** (triggers ArgoCD):
```bash
cd helm-charts
vi charts/order-service/values-prod.yaml

# Change:
# image:
#   tag: 1.2.2
# To:
# image:
#   tag: 1.2.3

git add charts/order-service/values-prod.yaml
git commit -m "chore: update order-service to v1.2.3"
git push
```

3. **Observe Canary Progression**:
```bash
# Monitor deployment
kubectl get rollout -n production -w
# Shows: 1pod → 5pods → 25pods → 100pods

# Check metrics at each phase
kubectl get event -n production -w | grep Canary

# Query Prometheus during each phase
curl "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])"
# Phase 1: 0.8% error rate (acceptable)
# Phase 2: 0.7% error rate (proceeding)
# Phase 3: 0.6% error rate (proceeding)
# Phase 4: 0.5% error rate (stable)
```

4. **Automatic Promotion**:
```
Phase 1 metrics ok
  ↓ (5 min pause ended)
Phase 2 (5% traffic)
  ↓ (5 min pause, metrics ok)
Phase 3 (25% traffic)
  ↓ (10 min pause, metrics ok)
Phase 4 (100% traffic)
  ↓
Deployment complete in 25 minutes ✅
```

5. **If Metrics Fail (automatic rollback)**:
```bash
# At any phase, if error rate > 1%:
Canary metrics check FAILED
  └─ Error rate: 1.5% (threshold: 1%)
  ↓
Automatic rollback initiated
  └─ kubectl rollout undo deployment/order-service
  └─ Reverts to v1.2.2 (previous digest)
  ↓
Deployment aborted after 7 minutes
  └─ Alert sent: "order-service v1.2.3 rollback"
  └─ Team investigates
```

## Scenario 2: Hotfix for Production Incident

**Objective**: Deploy security patch for critical vulnerability discovered in production

**Timeline**:
- 14:32 UTC: Vulnerability discovered (CVE in Log4j)
- 14:45 UTC: Fix committed
- 15:00 UTC: Fix deployed to production

**Process**:

1. **Create Hotfix Branch and Fix**:
```bash
git checkout -b hotfix/log4j-cve main
# Update dependency: log4j 2.14.0 → 2.17.1
vi pom.xml
# Run tests locally
mvn clean test
git add pom.xml
git commit -m "fix: CVE-2021-44228 upgrade log4j to 2.17.1"
```

2. **Urgent Code Review**:
```bash
git push origin hotfix/log4j-cve
# Create PR (expedited review, SLA: 10 min instead of normal 1 hour)
# Automated checks run:
#   ✓ Unit tests pass
#   ✓ Dependency scan: log4j 2.17.1 - no CVEs
#   ✓ Build: success
# Team review: "Approved - CRITICAL"
# Merge to main
```

3. **Automated Deployment**:
```bash
# GitHub Actions triggered by merge to main
# Commit → Build → Test → Deploy stages run (20 min total)

# Build creates: order-service:1.2.3-hotfix-abc789
# Published to registry with security patch

# Deployment to prod:
#   Canary Phase 1 (1%): error rate 0.3% ✓
#   Canary Phase 2 (5%): error rate 0.4% ✓
#   Canary Phase 3 (25%): error rate 0.3% ✓
#   Canary Phase 4 (100%): complete
```

4. **Verification**:
```bash
# Confirm fix deployed
kubectl get deployment order-service -n production \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: ghcr.io/company/order-service:1.2.3-hotfix@sha256:...

# Scan new image for CVE
trivy image ghcr.io/company/order-service:1.2.3-hotfix
# Result: No vulnerabilities found ✓

# Notify security team
# Timeline: Vulnerability discovered → Patched and deployed: 28 minutes
```

---

# Interview Questions and Answers

## Question 1: How would you design a CI/CD pipeline for a microservices architecture handling 1M requests/day?

**Answer Structure**:
1. State architecture clearly
2. Explain trade-offs
3. Provide concrete examples

**Sample Answer**:

"I'd design a 5-stage pipeline optimized for speed and safety:

**Stage 1 (Commit, <5 min)**:
- Per-service pipelines (order-service triggers only when order-service changes)
- Lint, unit tests (>70% coverage), SAST, secrets scan all run in parallel
- Fail fast: if any check fails, developer gets feedback in 3 minutes

**Stage 2 (Build, 3-5 min)**:
- Each service builds once, creating immutable container image
- Image identified by SHA-256 digest (not mutable tag)
- Published to private registry (ECR/ACR)
- All scans run: Trivy for CVEs, Cosign for signing

**Stage 3 (Integration, 12 min)**:
- Deploy staging (identical to production infrastructure)
- Run contract tests (Pact) to validate service-to-service compatibility
- E2E tests with real dependencies (Testcontainers for DB)
- Performance profiling: identify regressions

**Stage 4 (Security, 10 min)** - parallel with Stage 3:
- DAST (OWASP ZAP) scanning running service
- Container scanning with different tool (Snyk) for coverage
- Compliance checks (PCI-DSS, SOC2 controls)

**Stage 5 (Deploy, 25 min)**:
- Manual approval gate (15-min window)
- Canary deployment: 1% → 5% → 25% → 100% traffic
- SLI-driven: if error rate exceeds 1%, automatic rollback
- At 100%: deployment complete, metrics stable

**Why this design**:
- For 1M requests/day (11.5 req/sec average): staging can handle full load testing
- Parallel stages (3+4) reduce total time from 50 to 35 minutes
- Canary catches issues affecting small user set first (100 users at 1% phase)
- Immutable images enable instant rollback (2 sec) vs rebuild (15 min)
- Each stage has clear pass/fail criteria preventing bad code reaching production

**Risk mitigation**:
- If canary fails: automatic rollback, zero production impact
- If dependency breaks: contract tests catch before production
- If performance degrades: metrics-driven gates prevent promotion"

---

## Question 2: How would you handle deployment of dependent microservices simultaneously?

**Answer**:

"When payment-service and order-service have contract changes, they must deploy together. Here's my approach:

**Contract-First Development**:
1. Define API contract (OpenAPI spec or Pact)
2. Both teams develop against contract (independently)
3. Contract tests validate compatibility before deployment

**Coordination**:
1. Payment Service: Deploy first (0% traffic via canary)
2. Order Service: Deploy second
3. Both services must support both old and new API versions (backward compatibility)
4. Example:
   ```
   Payment v2.0 API: 
     Accepts OLD format: {amount, currency}
     Accepts NEW format: {basePrice, tax, currency}
   
   Order v2.0:
     Sends NEW format (includes tax)
     If Old Payment still active: fallback to old format
   ```

**Implementation**:
```yaml
# Stage payment-service v2.0 to 1% canary
# Monitor for errors (old format still working? ✓)
# Expand to 100%

# Then stage order-service v2.0 to 1% canary
# Sends new format to payment v2.0
# Verify payment processing works
# Expand to 100%

# Deploy time: 50 min (sequential) instead of 25 min each separately
# Safety: each service validates independently
```

**Key principle**: Never require simultaneous deployments. Design for independent deployment cycles using backward-compatible APIs and strategic feature flagging."

---

## Question 3: Your canary deployment shows 2% error rate in phase 2 (5% traffic). What do you do?

**Correct Answer**:
"Automatic rollback triggered. Here's why and how:

**Decision**:
- Error rate threshold: <1%
- Observed: 2%
- Conclusion: New version has bug affecting production users
- Action: STOP and REVERT

**Rollback process** (automated):
```bash
# ArgoCD detected metrics breach
# Automatically executed:
kubectl rollout undo deployment/order-service -n production

# Result:
# - Previous version (v1.2.2) back at 100% traffic
# - Takes 2 minutes (instant compared to debugging live incident)
# - All 500 users in phase 2 recover to working version
```

**Post-Incident**:
1. Investigate: What caused 2% error rate?
   - Check logs: application errors vs infrastructure
   - Check metrics: database CPU, connection pool, memory
   - Check traces: where in request flow do errors occur?

2. Fix: Address root cause
   - If bad code: fix in feature branch, retest, re-deploy
   - If resource: increase limits, re-deploy
   - If dependency: check contract compatibility

3. Retry: Re-deploy from current version only after root cause fixed

4. Post-mortem: Document incident and prevention measures

**Why not ignore 2%?**
- 2% error rate with 100K users = 2,000 users affected
- Represents financial loss, customer dissatisfaction, SLO breach
- Automatic rollback prevents escalation (vs manual investigation)
- SLOs exist to catch problems early, not ignore them"

---

## Question 4: Database schema change across microservices - how do you handle?

**Answer**:

"Database schema changes are tricky because multiple services depend on the same database.

**Problem**:
```
Order Service: Expects 'customer_id' column
Inventory Service: Rename 'customer_id' → 'buyer_id'

If deployed simultaneously:
  - Order Service reads 'customer_id' → NULL (column doesn't exist) → Exception
  - Orders fail processing
```

**Solution: Expand-contract pattern**:

**Phase 1 (Expand - add new column)**:
```sql
-- Inventory Service deploys schema change
ALTER TABLE orders ADD COLUMN buyer_id BIGINT;
-- Both 'customer_id' and 'buyer_id' exist
-- Application code writes to BOTH

ALTER TABLE orders ADD CONSTRAINT fk_buyer FOREIGN KEY (buyer_id) REFERENCES customers(id);
```

**Phase 2 (Migrate - populate new column)**:
```sql
-- Data migration (can be online, non-blocking)
UPDATE orders SET buyer_id = customer_id WHERE buyer_id IS NULL;
-- Verify: SELECT COUNT(*) WHERE buyer_id IS NULL; -- Should be 0
```

**Phase 3 (Contract - enforce new column)**:
```sql
-- Inventory Service v2 deploys - writes to 'buyer_id' only
ALTER TABLE orders DROP CONSTRAINT fk_customer;
ALTER TABLE orders DROP COLUMN customer_id;
```

**Phase 4 (Cleanup)**:
```sql
-- Ensure no code references old column anymore
-- Remove from all services
```

**Timeline**:
- Day 1: Deploy Inventory Service with NEW column, old column still used
- Day 2: Migrate data in off-peak hours
- Day 3: Deploy Inventory Service reading from NEW column
- Day 7: Drop old column (after confirming all services migrated)

**Why gradual?**
- If dropped immediately: services reading old column fail instantly
- Gradual approach: detect problems, roll back easily
- Zero-downtime migration
- No need to schedule maintenance window"

---

## Question 5: Describe your approach to observability in microservices.

**Answer**:

"Observability means understanding system behavior from external outputs. I use three pillars:

**1. Metrics (quantitative)**:
```
# Application metrics (Spring Boot Micrometer)
- Request rate (req/sec)
- Error rate (% 5xx)
- Latency percentiles (p50, p95, p99)

# Infrastructure metrics (Prometheus scrapes Kubernetes)
- Pod CPU usage
- Memory consumption
- Network I/O

# Collection: Prometheus scrapes /metrics endpoint every 15s
# Storage: 30-day retention
# Querying: PromQL for complex queries
```

**2. Logs (detailed events)**:
```java
@Slf4j
public class OrderService {
    void processOrder(Order order) {
        log.info("Processing order", mapping(
            "order_id", order.getId(),
            "customer_id", order.getCustomerId(),
            "amount", order.getAmount(),
            "trace_id", TraceContext.current().traceId()
        ));
    }
}
```

All logs:
- Structured (JSON)
- Include trace ID (links to other services)
- Sent to central store (ELK, Loki)
- Indexed for full-text search

**3. Traces (request journey)**:
```
Trace ID: 550e8400-e29b-41d4-a716-446655440000
  └─ Span: POST /api/orders (5ms)
  │  └─ Span: Validate (2ms)
  │  └─ Span: Call Payment Service (150ms)
  │  │  └─ SpanLink: Called payment-service gRPC
  │  └─ Span: Call Inventory (30ms)
  │  └─ Span: Persist DB (10ms)
```

Collected via:
- OpenTelemetry auto-instrumentation
- Export to Jaeger/Tempo
- Enable debugging specific requests

**Why these three?**:
- **Metrics**: Detect problems (error rate spike)
- **Logs**: Find root cause (what exception?)
- **Traces**: Understand impact (which services affected?)

**Integration to CI/CD**:
```
Canary Phase 1 deployment
  ↓
ArgoCD evaluates metrics from Prometheus
  └─ Error rate < 1%? ✓
  └─ Latency p99 < 500ms? ✓
  ↓
Automatic promotion to Phase 2

If metrics fail:
  └─ Automatic rollback
  └─ Alert sent to on-call
  └─ Logs/traces available for investigation
```

**Key principle**: Observability enables automated decisions (promotion/rollback) without human guessing."

---

## Question 6: You have 5 microservices. How do you prevent one service's failure from cascading?

**Answer**:

"Cascading failure happens when one service down brings others down. I use multiple strategies:

**1. Circuit Breaker Pattern**:
```java
@Service
class OrderService {
    @CircuitBreaker(name = "payment")
    public void chargePayment(Order order) {
        return paymentClient.charge(order);
    }
}
```

States:
```
CLOSED (normal):
  Order Service → calls Payment Service → succeeds
  
OPEN (trip triggered):
  After 5 failures in 10s
  Order Service → catches request (doesn't call Payment)
  → Returns fallback response or queues message
  
HALF_OPEN (recovery):
  After 60s, tries Payment Service again
  If succeeds → back to CLOSED
  If fails → back to OPEN
```

**2. Timeout Per Service**:
```yaml
# Order Service calls Payment Service
payment:
  connectTimeout: 5s    # Connection timeout
  readTimeout: 10s      # Response timeout
  writeTimeout: 5s
  # If Payment doesn't respond in 10s: fail fast, don't wait
```

**3. Retry with Exponential Backoff**:
```java
@Retry(maxAttempts = 3, delay = 1000, multiplier = 2.0)
public void callPayment() {
    // Attempt 1: fails, wait 1s
    // Attempt 2: fails, wait 2s
    // Attempt 3: fails, return
    // Total time: 3 seconds (not 30+ seconds)
}
```

**4. Bulkhead (Resource Isolation)**:
```yaml
# Order Service has 10 worker threads
# Payment calls get 3 threads max
# Inventory calls get 3 threads max
# Other operations get 4 threads max

# If Payment Service slow:
#   - 3 threads blocked waiting
#   - Other 7 threads still handling requests
#   - Service degrades, doesn't fail
```

**5. Service Mesh (Istio)**:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: payment-service
spec:
  hosts:
  - payment-service
  http:
  - match:
    - uri:
        prefix: /api/payments
    route:
    - destination:
        host: payment-service
        port:
          number: 8080
    timeout: 10s              # Timeout
    retries:
      attempts: 3             # Retry attempts
      perTryTimeout: 3s       # Per retry timeout
    outlierDetection:         # Circuit breaker
      consecutive5xxErrors: 3
      interval: 30s           # Check every 30s
      baseEjectionTime: 30s   # Eject for 30s
```

**Result**: If Payment Service down:
- Order Service: request fails in <10s, returns fallback
- Inventory Service: unaffected (independent)
- API Gateway: responds with graceful error
- System degraded, not failed ✅"

---

*End of Study Guide - All Major Topics Covered*

**Total Content**: 
- 4 comprehensive markdown files
- 12,000+ lines
- 40+ practical code examples
- 20+ ASCII diagrams
- Senior-level depth for DevOps engineers 5-10+ years experience
- Production-tested patterns and strategies
