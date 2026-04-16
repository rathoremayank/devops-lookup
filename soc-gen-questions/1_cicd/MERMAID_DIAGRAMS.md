# Mermaid Diagrams for Java Microservices CI/CD Study Guide

This file contains all Mermaid charts referenced in the study guide.

---

## 1. 5-Stage CI/CD Pipeline Architecture

```mermaid
graph TD
    A["Developer Push<br/>to GitHub"] -->|Webhook| B["STAGE 1: COMMIT<br/>5 minutes"]
    
    B -->|Lint<br/>Unit Tests<br/>Coverage| C{All Checks<br/>Pass?}
    C -->|No| D["❌ FAIL<br/>Developer notified"]
    C -->|Yes| E["STAGE 2: BUILD<br/>3-5 minutes"]
    
    E -->|Compile<br/>Docker Build<br/>Registry Push| F{Vulnerability<br/>Scan Pass?}
    F -->|No| D
    F -->|Yes| G["STAGE 3 & 4<br/>Parallel Execution"]
    
    G -->|Integration Tests<br/>Contract Tests<br/>E2E Tests| H["Integration Tests"]
    G -->|DAST<br/>Container Scan<br/>Secrets Scan| I["Security Tests"]
    
    H --> J{All Tests<br/>Pass?}
    I --> K{Security<br/>Clear?}
    
    J -->|No| D
    K -->|No| D
    J -->|Yes| L["Manual Approval Gate<br/>15 min window"]
    K -->|Yes| L
    
    L -->|Team Reviews| M{Approved?}
    M -->|No| D
    M -->|Yes| N["STAGE 5: DEPLOY<br/>25 minutes"]
    
    N -->|Canary 1%<br/>Monitor 5 min| O["Phase 1"]
    O -->|Metrics OK?| P{Error<br/>Rate<1%?}
    P -->|No| Q["🔄 ROLLBACK<br/>v1.2.2"]
    P -->|Yes| R["Canary 5%<br/>Monitor 5 min"]
    
    R --> S{Metrics OK?}
    S -->|No| Q
    S -->|Yes| T["Canary 25%<br/>Monitor 10 min"]
    
    T --> U{Metrics OK?}
    U -->|No| Q
    U -->|Yes| V["Production 100%<br/>Monitor continuous"]
    
    V --> W["✅ DEPLOYMENT<br/>COMPLETE"]
    Q --> X["Alert Team<br/>Investigate<br/>Retry"]
    
    style B fill:#4CAF50,stroke:#2E7D32,color:#fff
    style E fill:#2196F3,stroke:#1565C0,color:#fff
    style N fill:#FF9800,stroke:#E65100,color:#fff
    style W fill:#4CAF50,stroke:#2E7D32,color:#fff
    style D fill:#F44336,stroke:#C62828,color:#fff
    style Q fill:#F44336,stroke:#C62828,color:#fff
```

---

## 2. Microservices Deployment Architecture

```mermaid
graph TB
    subgraph Developer["Developer Workstation"]
        IDE["✎ IDE"]
        LocalTests["Local Tests"]
    end
    
    subgraph VCS["Version Control"]
        GitHub["GitHub Repository"]
        Webhook["Webhook Trigger"]
    end
    
    subgraph CI["CI System"]
        GA["GitHub Actions"]
        Checkout["Checkout Code"]
        Tests["Run Tests"]
        Build["Build Image"]
        Sign["Sign Image"]
    end
    
    subgraph Registry["Container Registry"]
        ECR["GHCR / ECR / ACR"]
        SBOM["SBOM Metadata"]
    end
    
    subgraph CD["CD System"]
        ArgoCD["ArgoCD Controller"]
        GitOps["Git Desired State"]
    end
    
    subgraph Environments["Kubernetes Clusters"]
        Staging["Staging Cluster<br/>Full Integration Tests"]
        Canary["Canary Nodes<br/>1% → 100% Traffic"]
        Prod["Production Cluster<br/>Live Users"]
    end
    
    subgraph Observability["Observability Stack"]
        Prometheus["Prometheus<br/>Metrics"]
        Grafana["Grafana<br/>Dashboards"]
        Jaeger["Jaeger<br/>Traces"]
        ELK["ELK<br/>Logs"]
    end
    
    Developer -->|git push| VCS
    VCS -->|triggers| Webhook
    Webhook -->|initiates| GA
    GA -->|executes| Checkout
    Checkout -->|runs| Tests
    Tests -->|builds| Build
    Build -->|signs| Sign
    Sign -->|publishes| ECR
    ECR -->|stores| SBOM
    ECR -->|image| CD
    GitOps -->|watches| CD
    CD -->|syncs| Staging
    Staging -->|if tests pass| Canary
    Canary -->|if metrics ok| Prod
    Prod -->|scraped by| Prometheus
    Prometheus -->|visualized in| Grafana
    Prod -->|traced in| Jaeger
    Prod -->|logged to| ELK
    Grafana -->|feeds back to| CD
    
    style Developer fill:#E8F5E9,stroke:#2E7D32
    style CI fill:#E3F2FD,stroke:#1565C0
    style Registry fill:#FFF3E0,stroke:#E65100
    style CD fill:#F3E5F5,stroke:#6A1B9A
    style Environments fill:#FFEBEE,stroke:#C62828
    style Observability fill:#E0F2F1,stroke:#00796B
```

---

## 3. Core CI/CD Principles Interdependencies

```mermaid
graph LR
    A["🎯 Independence"] -->|enables| B["⚙️ Parallel<br/>Deployments"]
    
    C["📦 Immutability"] -->|enables| D["🔄 Instant<br/>Rollbacks"]
    
    E["⬅️ Shift-Left<br/>Testing"] -->|catches issues in| F["⏱️ 5 Minutes"]
    
    G["🏗️ Environment<br/>Parity"] -->|ensures staging results| H["✅ Apply to<br/>Production"]
    
    D -->|reduces| I["⚠️ Blast<br/>Radius"]
    I -->|minimizes| J["😟 Customer<br/>Impact"]
    
    K["📊 Observability"] -->|provides metrics for| L["🤖 Automated<br/>Decisions"]
    L -->|enables| M["🚀 Release<br/>Confidence"]
    
    B -->|+ D| N["⚡ Fast +<br/>Safe = CDL"]
    H -->|+ F| N
    N -->|= Competitive| O["🏆 Advantage"]
    M -->|supports| O
    
    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style C fill:#2196F3,stroke:#1565C0,color:#fff
    style E fill:#FF9800,stroke:#E65100,color:#fff
    style G fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style O fill:#FFD700,stroke:#FBC02D,color:#000
    style N fill:#4CAF50,stroke:#2E7D32,color:#fff
```

---

## 4. Modern DevOps Stack Integration

```mermaid
graph TB
    subgraph Development["Development Phase"]
        IDE["IDE<br/>Code Editor"]
        LocalDeps["Local Dependencies<br/>Docker Compose"]
    end
    
    subgraph SourceControl["Source Control"]
        Git["Git"]
        GitHub["GitHub"]
    end
    
    subgraph CI["Continuous Integration"]
        GHA["GitHub Actions"]
        SonarQube["SonarQube<br/>Code Quality"]
        Maven["Maven<br/>Build System"]
        JUnit["JUnit 5<br/>Testing"]
    end
    
    subgraph ContainerBuild["Container Build & Scan"]
        Docker["Docker<br/>Containerization"]
        Trivy["Trivy<br/>Image Scan"]
        Cosign["Cosign<br/>Image Signing"]
        Registry["Registry<br/>GHCR/ECR"]
    end
    
    subgraph CD["Continuous Deployment"]
        ArgoCD["ArgoCD<br/>GitOps"]
        Terraform["Terraform<br/>Infrastructure"]
        Vault["Vault<br/>Secrets"]
    end
    
    subgraph Compute["Container Orchestration"]
        K8s["Kubernetes<br/>Clusters"]
        Helm["Helm<br/>Package Manager"]
        Kustomize["Kustomize<br/>Config Mgmt"]
    end
    
    subgraph Observability["Observability & Monitoring"]
        Prometheus["Prometheus<br/>Metrics"]
        Grafana["Grafana<br/>Dashboards"]
        Jaeger["Jaeger<br/>Distributed Tracing"]
        ELK["ELK/Loki<br/>Log Aggregation"]
        Sentry["Sentry<br/>Error Tracking"]
    end
    
    IDE -->|Code| GitHub
    GitHub -->|Webhook| GHA
    GHA -->|Build| Maven
    Maven -->|Test| JUnit
    JUnit -->|Quality| SonarQube
    GHA -->|Container| Docker
    Docker -->|Scan| Trivy
    Trivy -->|Sign| Cosign
    Cosign -->|Push| Registry
    Registry -->|Image| ArgoCD
    Terraform -->|Infrastructure| K8s
    Vault -->|Secrets| K8s
    ArgoCD -->|Deploy| K8s
    Helm -->|Package| K8s
    Kustomize -->|Config| K8s
    K8s -->|Metrics| Prometheus
    K8s -->|Traces| Jaeger
    K8s -->|Logs| ELK
    Prometheus -->|Dashboard| Grafana
    Grafana -->|Alerts| Sentry
    
    style Development fill:#E8F5E9,stroke:#2E7D32
    style SourceControl fill:#E3F2FD,stroke:#1565C0
    style CI fill:#FFF3E0,stroke:#E65100
    style ContainerBuild fill:#F3E5F5,stroke:#6A1B9A
    style CD fill:#FCE4EC,stroke:#C2185B
    style Compute fill:#FFEBEE,stroke:#C62828
    style Observability fill:#E0F2F1,stroke:#00796B
```

---

## 5. Canary Deployment Metrics Decision Tree

```mermaid
graph TD
    A["Deploy v1.2.3<br/>Canary 1%"] -->|Wait 5 min| B["Check Metrics"]
    
    B -->|Error Rate< 1%?| C{Check<br/>Latency P99}
    B -->|Error Rate ≥ 1%| D["🔄 ROLLBACK<br/>to v1.2.2"]
    
    C -->|P99 < 500ms| E{Check<br/>CPU Usage}
    C -->|P99 ≥ 500ms| D
    
    E -->|CPU < 70%| F["✅ Phase 1<br/>PASSED"]
    E -->|CPU ≥ 70%| D
    
    F -->|Canary 5%<br/>Wait 5 min| G["Check Metrics"]
    G -->|All OK| H["✅ Phase 2<br/>PASSED"]
    G -->|Any Fail| D
    
    H -->|Canary 25%<br/>Wait 10 min| I["Check Metrics"]
    I -->|All OK| J["✅ Phase 3<br/>PASSED"]
    I -->|Any Fail| D
    
    J -->|Canary 100%<br/>Wait 5 min| K["Check Metrics"]
    K -->|All OK| L["✅ Phase 4<br/>Prod Complete"]
    K -->|Any Fail| D
    
    D -->|Alert| M["🚨 Incident<br/>Team Notified"]
    M -->|Investigate| N["Fix & Retry"]
    
    L -->|Metrics Stable| O["🎉 SUCCESS<br/>v1.2.3 Live"]
    
    style A fill:#2196F3,stroke:#1565C0,color:#fff
    style F fill:#4CAF50,stroke:#2E7D32,color:#fff
    style H fill:#4CAF50,stroke:#2E7D32,color:#fff
    style J fill:#4CAF50,stroke:#2E7D32,color:#fff
    style L fill:#4CAF50,stroke:#2E7D32,color:#fff
    style D fill:#F44336,stroke:#C62828,color:#fff
    style M fill:#F44336,stroke:#C62828,color:#fff
    style O fill:#FFD700,stroke:#FBC02D,color:#000
```

---

## 6. Image Promotion Pipeline with Gates

```mermaid
graph LR
    A["Commit<br/>abc123f"] -->|Build| B["Image Created<br/>sha256:xyz789"]
    
    B -->|Push| C["Container<br/>Registry"]
    
    C -->|GATE 1:<br/>Scan| D{No Critical<br/>CVEs?}
    D -->|No| E["❌ Stop<br/>Promote"]
    D -->|Yes| F["✅ Scan<br/>Passed"]
    
    F -->|Deploy| G["Staging<br/>Environment"]
    
    G -->|GATE 2:<br/>Tests| H{Integration<br/>Tests Pass?}
    H -->|No| E
    H -->|Yes| I["✅ Tests<br/>Passed"]
    
    I -->|GATE 3:<br/>Metrics| J{Error<br/>Rate <1%?}
    J -->|No| E
    J -->|Yes| K["✅ Metrics<br/>OK"]
    
    K -->|GATE 4:<br/>Security| L{SAST/DAST<br/>Clear?}
    L -->|No| E
    L -->|Yes| M["✅ Security<br/>Cleared"]
    
    M -->|GATE 5:<br/>Approval| N{Team<br/>Approved?}
    N -->|No| E
    N -->|Yes| O["Production<br/>Ready"]
    
    O -->|Canary<br/>Promotion| P["Prod: 1%→5%→25%→100%"]
    
    P -->|Continuous<br/>Monitoring| Q["✅ Live in<br/>Production"]
    
    style A fill:#E3F2FD,stroke:#1565C0
    style B fill:#FFF3E0,stroke:#E65100
    style C fill:#F3E5F5,stroke:#6A1B9A
    style F fill:#4CAF50,stroke:#2E7D32,color:#fff
    style I fill:#4CAF50,stroke:#2E7D32,color:#fff
    style K fill:#4CAF50,stroke:#2E7D32,color:#fff
    style M fill:#4CAF50,stroke:#2E7D32,color:#fff
    style O fill:#4CAF50,stroke:#2E7D32,color:#fff
    style P fill:#FF9800,stroke:#E65100,color:#fff
    style Q fill:#4CAF50,stroke:#2E7D32,color:#fff
    style E fill:#F44336,stroke:#C62828,color:#fff
```

---

## 7. Microservices Dependency Graph

```mermaid
graph TB
    subgraph Gateway["API Gateway"]
        GW["Kong / Nginx"]
    end
    
    subgraph Services["Microservices"]
        OS["Order Service<br/>:8080"]
        PS["Payment Service<br/>:8081"]
        IS["Inventory Service<br/>:8082"]
        NS["Notification Service<br/>:8083"]
    end
    
    subgraph Data["Data Layer"]
        DB["PostgreSQL<br/>Shared DB"]
    end
    
    subgraph MessageQueue["Async Communication"]
        Kafka["Kafka<br/>Message Broker"]
    end
    
    subgraph External["External Services"]
        Bank["Bank Payment<br/>Gateway"]
        Email["Email Service"]
    end
    
    GW -->|REST Call| OS
    GW -->|REST Call| PS
    GW -->|REST Call| IS
    
    OS -->|charges| PS
    OS -->|reserves| IS
    OS -->|publishes<br/>order-created| Kafka
    
    PS -->|updates DB| DB
    OS -->|reads/writes| DB
    IS -->|reads/writes| DB
    
    Kafka -->|subscribes<br/>order-created| NS
    NS -->|connects to| Email
    
    PS -->|calls| Bank
    
    style Gateway fill:#E3F2FD,stroke:#1565C0
    style OS fill:#E8F5E9,stroke:#2E7D32
    style PS fill:#E8F5E9,stroke:#2E7D32
    style IS fill:#E8F5E9,stroke:#2E7D32
    style NS fill:#E8F5E9,stroke:#2E7D32
    style DB fill:#FFF3E0,stroke:#E65100
    style Kafka fill:#F3E5F5,stroke:#6A1B9A
    style External fill:#FFEBEE,stroke:#C62828
```

---

## 8. Three Pillars of Observability

```mermaid
graph TB
    subgraph Metrics["📊 METRICS<br/>Quantitative"]
        M1["Request Rate<br/>10,000 req/sec"]
        M2["Error Rate<br/>0.5%"]
        M3["Latency P99<br/>450ms"]
        M4["Resource Usage<br/>CPU, Memory"]
    end
    
    subgraph Logs["📝 LOGS<br/>Detailed Events"]
        L1["Structured JSON<br/>Logs"]
        L2["Error Stacktraces"]
        L3["Request Path<br/>Context"]
        L4["Indexed Search<br/>Full-Text"]
    end
    
    subgraph Traces["🔗 TRACES<br/>Request Journey"]
        T1["End-to-End<br/>Request Flow"]
        T2["Service Hops<br/>Latency per hop"]
        T3["Dependency<br/>Visualization"]
        T4["Performance<br/>Bottlenecks"]
    end
    
    M1 --> Decision["🚀 Decision:<br/>Deploy or<br/>Rollback?"]
    L1 --> Investigation["🔍 Investigation:<br/>Root Cause<br/>Analysis"]
    T1 --> Understanding["📈 Understanding:<br/>System<br/>Behavior"]
    
    Decision -->|Metrics show| Dashboard["Dashboard<br/>Prometheus"]
    Investigation -->|Logs show| LogAgg["Log Aggregation<br/>ELK/Loki"]
    Understanding -->|Traces show| Jaeger["Distributed Tracing<br/>Jaeger"]
    
    Dashboard -->|all three| Complete["✅ Complete<br/>Observability"]
    LogAgg -->|enable| Complete
    Jaeger -->|provides| Complete
    
    style Metrics fill:#E3F2FD,stroke:#1565C0
    style Logs fill:#FFF3E0,stroke:#E65100
    style Traces fill:#F3E5F5,stroke:#6A1B9A
    style Complete fill:#4CAF50,stroke:#2E7D32,color:#fff
```

---

## 9. Deployment Strategies Comparison

```mermaid
graph TB
    BG["Blue-Green Deployment<br/>━━━━━━━━━━"]
    BG -->|Infrastructure| BG1["2x cost<br/>Two complete envs"]
    BG -->|Deployment Time| BG2["2 minutes<br/>Instant switch"]
    BG -->|Rollback Time| BG3["2 seconds<br/>Route switch"]
    BG -->|Risk| BG4["Low<br/>Full test before switch"]
    BG -->|Best For| BG5["Monoliths<br/>Stateless services"]
    
    CAN["Canary Deployment<br/>━━━━━━━━━━"]
    CAN -->|Infrastructure| CAN1["1x cost<br/>Reuse existing"]
    CAN -->|Deployment Time| CAN2["25 minutes<br/>Gradual shift"]
    CAN -->|Rollback Time| CAN3["2 minutes<br/>Revert image"]
    CAN -->|Risk| CAN4["Very Low<br/>Real user validation"]
    CAN -->|Best For| CAN5["Microservices<br/>High traffic"]
    
    FF["Feature Flags<br/>━━━━━━━━━━"]
    FF -->|Infrastructure| FF1["1x cost<br/>Same deployed code"]
    FF -->|Deployment Time| FF2["0 minutes<br/>No deploy needed"]
    FF -->|Rollback Time| FF3["Instant<br/>Disable flag"]
    FF -->|Risk| FF4["Medium<br/>Flag logic complexity"]
    FF -->|Best For| FF5["A/B Testing<br/>Gradual rollout"]
    
    RU["Rolling Update<br/>━━━━━━━━━━"]
    RU -->|Infrastructure| RU1["1.2x cost<br/>Extra pods"]
    RU -->|Deployment Time| RU2["10 minutes<br/>Sequential pods"]
    RU -->|Rollback Time| RU3["10 minutes<br/>Re-deploy old"]
    RU -->|Risk| RU4["Medium<br/>Mixed versions"]
    RU -->|Best For| RU5["Batch Jobs<br/>Non-critical"]
    
    style BG fill:#E3F2FD,stroke:#1565C0
    style CAN fill:#E8F5E9,stroke:#2E7D32
    style FF fill:#FFF3E0,stroke:#E65100
    style RU fill:#F3E5F5,stroke:#6A1B9A
    style BG1 fill:#E3F2FD,stroke:#1565C0
    style CAN1 fill:#E8F5E9,stroke:#2E7D32
    style FF1 fill:#FFF3E0,stroke:#E65100
    style RU1 fill:#F3E5F5,stroke:#6A1B9A
```

---

## 10. SLI / SLO / Error Budget Model

```mermaid
graph LR
    A["Target:<br/>99.9%<br/>Availability"] -->|= SLO| B["Service Level<br/>Objective"]
    
    B -->|Measured by| C["Success Rate<br/>Good Requests/<br/>Total Requests"]
    
    C -->|= SLI| D["Service Level<br/>Indicator"]
    
    D -->|Current: 99.95%| E{SLI ><br/>SLO?}
    
    E -->|Yes<br/>99.95% > 99.9%| F["✅ Within Budget<br/>Remaining: 0.05%"]
    E -->|No<br/>99.5% < 99.9%| G["❌ Budget Exceeded<br/>Remaining: -0.4%"]
    
    F -->|Monthly<br/>0.05% × 2.6M sec| H["Budget Remaining:<br/>~44 minutes"]
    G -->|Monthly| I["Exceeded By:<br/>~10 hours"]
    
    H -->|Allows| J["Deploy new version<br/>Observe impact"]
    J -->|If metrics stay| K["Deployment<br/>Approved"]
    J -->|If metrics fail| L["Automatic<br/>Rollback"]
    
    I -->|Requires| M["Focus on<br/>Stability<br/>No new deploys"]
    
    style A fill:#2196F3,stroke:#1565C0,color:#fff
    style B fill:#2196F3,stroke:#1565C0,color:#fff
    style D fill:#FF9800,stroke:#E65100,color:#fff
    style F fill:#4CAF50,stroke:#2E7D32,color:#fff
    style G fill:#F44336,stroke:#C62828,color:#fff
    style H fill:#4CAF50,stroke:#2E7D32,color:#fff
    style K fill:#4CAF50,stroke:#2E7D32,color:#fff
    style L fill:#F44336,stroke:#C62828,color:#fff
```

---

## 11. Circuit Breaker State Machine

```mermaid
stateDiagram-v2
    [*] --> CLOSED
    
    CLOSED -->|Request Succeeds| CLOSED: Success++
    CLOSED -->|Request Fails| CLOSED: Failure++
    CLOSED -->|Failure Count > 5<br/>in 10 seconds| OPEN: Trip Circuit
    
    OPEN -->|Wait 60s| HALF_OPEN: Recovery Timer
    OPEN -->|New Request| OPEN: Reject Immediately<br/>Return Fallback
    
    HALF_OPEN -->|Request Succeeds| CLOSED: Resume Normal
    HALF_OPEN -->|Request Fails| OPEN: Back to Open
    
    note right of CLOSED
        ✅ Service healthy
        Requests passed through
        Monitor success rate
    end note
    
    note right of OPEN
        ⏹️ Service down
        Requests fail fast
        No backend calls
        Return fallback
    end note
    
    note right of HALF_OPEN
        ⚙️ Testing recovery
        Send test request
        If success → resume
        If fail → back to open
    end note
```

---

## 12. Git Workflow for Microservices

```mermaid
gitGraph
    commit id: "v1.0.0 released"
    commit id: "docs: update README"
    
    branch develop
    checkout develop
    commit id: "feature: async processing"
    commit id: "tests: add integration tests"
    
    branch feature/payment-v2
    checkout feature/payment-v2
    commit id: "feat: new payment gateway"
    commit id: "test: payment contract test"
    
    checkout develop
    merge feature/payment-v2
    
    branch release/1.2.0
    checkout release/1.2.0
    commit id: "chore: version bump 1.2.0"
    commit id: "docs: changelog"
    
    checkout main
    merge release/1.2.0 tag: "v1.2.0"
    
    checkout develop
    merge release/1.2.0
    
    branch hotfix/security-patch
    checkout hotfix/security-patch
    commit id: "fix: CVE-2021-44228"
    commit id: "test: security verification"
    
    checkout main
    merge hotfix/security-patch tag: "v1.2.1"
    
    checkout develop
    merge hotfix/security-patch
```

---

## 13. Contract Testing Flow (Pact)

```mermaid
sequenceDiagram
    participant Consumer as Order Service<br/>Consumer
    participant Broker as Pact Broker<br/>Central Store
    participant Provider as Payment Service<br/>Provider
    
    Note over Consumer,Provider: Development Phase
    
    Consumer->>Broker: Consumer defines expectation<br/>"POST /charge → {txnId, status}"
    
    Consumer->>Consumer: Run consumer tests<br/>against mock provider
    Consumer->>Broker: Publish pact contract
    
    Provider->>Broker: Fetch pacts from broker
    Provider->>Provider: Run provider tests<br/>against real API
    Provider->>Provider: Verify API returns<br/>expected response
    
    Provider->>Broker: Upload verification results
    
    Broker->>Broker: Compatibility check pass?
    
    Note over Broker: If both pass: Contract satisfied ✅
    
    Broker->>Consumer: Can deploy!
    Broker->>Provider: Can deploy!
    
    Consumer->>Provider: Production call<br/>with confidence
    Provider-->>Consumer: Response matches contract
```

---

## 14. Environment Parity Matrix

```mermaid
graph LR
    subgraph staging["STAGING ENVIRONMENT<br/>═════════════════"]
        S1["Kubernetes 1.28.5"]
        S2["PostgreSQL 15.4"]
        S3["3 t3.large nodes"]
        S4["Pod Limiting<br/>512Mi/250m"]
        S5["Network Policies<br/>Enabled"]
    end
    
    subgraph prod["PRODUCTION ENVIRONMENT<br/>════════════════"]
        P1["Kubernetes 1.28.5"]
        P2["PostgreSQL 15.4"]
        P3["3 t3.large nodes"]
        P4["Pod Limiting<br/>512Mi/250m"]
        P5["Network Policies<br/>Enabled"]
    end
    
    S1 -.->|Identical| P1
    S2 -.->|Identical| P2
    S3 -.->|Identical| P3
    S4 -.->|Identical| P4
    S5 -.->|Identical| P5
    
    staging -->|Tests run here<br/>Results apply to prod| prod
    
    style staging fill:#E8F5E9,stroke:#2E7D32
    style prod fill:#FFEBEE,stroke:#C62828
```

---

## 15. Observability to Deployment Decision Flow

```mermaid
graph TD
    A["Deploy v1.2.3<br/>Canary Started"] -->|5 minute window| B["Prometheus Scrapes<br/>Metrics"]
    
    B -->|Every 15 seconds| C["Error Rate:<br/>rate(5xx)</br>Latency P99:<br/>histogram_quantile"]
    
    C -->|Query Results| D["Current Metrics"]
    
    D -->|SLI Gate 1| E{Error Rate<br/>< 1%?}
    D -->|SLI Gate 2| F{Latency P99<br/>< 500ms?}
    D -->|SLI Gate 3| G{Memory Usage<br/>< 80%?}
    
    E -->|No| H["❌ Gate Failed"]
    F -->|No| H
    G -->|No| H
    
    E -->|Yes| I["✅ All Gates"]
    F -->|Yes| I
    G -->|Yes| I
    
    H -->|Threshold Breach| J["ArgoCD Detects<br/>Metrics Failure"]
    I -->|All Pass| K["ArgoCD Triggers<br/>Phase Expansion"]
    
    J -->|Executes| L["Automatic Rollback<br/>kubectl rollout undo"]
    K -->|Executes| M["Expand Traffic<br/>kubectl set image"]
    
    L -->|Reverts Image| N["Back to v1.2.2<br/>Production Stable"]
    M -->|Deploys Image| O["Promotion to<br/>Next Phase"]
    
    style A fill:#2196F3,stroke:#1565C0,color:#fff
    style B fill:#FF9800,stroke:#E65100,color:#fff
    style I fill:#4CAF50,stroke:#2E7D32,color:#fff
    style H fill:#F44336,stroke:#C62828,color:#fff
    style N fill:#4CAF50,stroke:#2E7D32,color:#fff
    style O fill:#4CAF50,stroke:#2E7D32,color:#fff
```

---

## 16. Database Migration - Expand Contract Pattern

```mermaid
graph LR
    subgraph Phase1["Phase 1: EXPAND<br/>Add New Column"]
        A["Database<br/>ALTER TABLE orders<br/>ADD COLUMN buyer_id"]
        B["Code writes to<br/>BOTH columns<br/>customer_id & buyer_id"]
        C["Backward compatible<br/>Old code still works"]
    end
    
    subgraph Phase2["Phase 2: MIGRATE<br/>Populate Data"]
        D["Data Migration<br/>UPDATE orders<br/>SET buyer_id = customer_id"]
        E["Verify all rows<br/>populated"]
    end
    
    subgraph Phase3["Phase 3: CONTRACT<br/>Switch to New"]
        F["Code uses<br/>buyer_id ONLY"]
        G["Deploy new version<br/>reads new column"]
    end
    
    subgraph Phase4["Phase 4: CLEAN<br/>Remove Old"]
        H["Drop old column<br/>DROP COLUMN customer_id"]
        I["All code migrated"]
    end
    
    A -->|Maintains compatibility| B
    B -->|enables| D
    D -->|after verification| E
    E -->|switches code to| F
    F -->|deploys together| G
    G -->|after stability check| H
    H -->|final cleanup| I
    
    style Phase1 fill:#E3F2FD,stroke:#1565C0
    style Phase2 fill:#FFF3E0,stroke:#E65100
    style Phase3 fill:#E8F5E9,stroke:#2E7D32
    style Phase4 fill:#FFEBEE,stroke:#C62828
```

---

## 17. Shift-Left Security - Cost vs Stage

```mermaid
graph LR
    A["❌ Bug NOT<br/>Found"] -->|Commit| B["$100<br/>Developer"]
    B -->|Build| C["$400<br/>Rebuild + Retest"]
    C -->|Staging| D["$4,000<br/>QA + Dev time"]
    D -->|Production| E["$100,000+<br/>Incident<br/>Customer impact"]
    
    F["✅ Bug Found<br/>at Commit"] -->|Early fix| G["$100<br/>Developer<br/>only"]
    
    H1["SAST Scan"]
    H2["Dependency Check"]
    H3["Secrets Scan"]
    
    H1 -->|catches| F
    H2 -->|catches| F
    H3 -->|catches| F
    
    style E fill:#F44336,stroke:#C62828,color:#fff
    style G fill:#4CAF50,stroke:#2E7D32,color:#fff
    style A fill:#F44336,stroke:#C62828,color:#fff
    style F fill:#4CAF50,stroke:#2E7D32,color:#fff
```

---

## 18. ArgoCD GitOps Reconciliation Loop

```mermaid
graph TD
    A["Git Repository<br/>Source of Truth"] -->|Desired State<br/>order-service: v1.2.3| B["ArgoCD<br/>Controller"]
    
    C["Kubernetes Cluster<br/>Current State"] -->|Current Deployment<br/>order-service: v1.2.2| B
    
    B -->|Watches Git every 3s| D{Desired ==<br/>Current?}
    
    D -->|No Drift| E["✅ In Sync<br/>No Action"]
    D -->|Drift Detected| F["⚠️ Out of Sync"]
    
    F -->|Applies Change| G["kubectl apply -f"]
    G -->|Updates| C
    
    H["Developer<br/>Commits Change"] -->|git push<br/>v1.2.3| A
    
    A -->|Webhook Notification| B
    B -->|Immediate Sync| G
    
    style A fill:#E3F2FD,stroke:#1565C0
    style B fill:#FF9800,stroke:#E65100,color:#fff
    style C fill:#FFEBEE,stroke:#C62828
    style E fill:#4CAF50,stroke:#2E7D32,color:#fff
    style G fill:#2196F3,stroke:#1565C0,color:#fff
```

---

## 19. Spring Boot Micrometer Metrics Collection

```mermaid
graph LR
    A["Spring Boot<br/>Application"] -->|@Timed<br/>@Counted| B["JVM Instrumentation"]
    
    B -->|Collects| C["Metrics:<br/>• Request Rate<br/>• Response Time<br/>• Exceptions<br/>• Memory/GC<br/>• Custom Metrics"]
    
    C -->|Exposed at| D["/actuator/prometheus"]
    
    D -->|Prometheus<br/>Scrapes every 15s| E["Prometheus<br/>Time-Series DB"]
    
    E -->|Queries via<br/>PromQL| F["Grafana<br/>Dashboards"]
    
    F -->|Visualizes| G["Dashboards:<br/>Request Rate<br/>Error Rate<br/>Latency<br/>Resource Usage"]
    
    G -->|Alerts based on| H["Alertmanager"]
    
    H -->|Notifies| I["PagerDuty<br/>Slack<br/>Email"]
    
    E -->|Also feeds| J["ArgoCD<br/>Canary Decisions"]
    
    J -->|SLI Gates| K["Promote to<br/>Next Phase<br/>or<br/>Rollback"]
    
    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style C fill:#2196F3,stroke:#1565C0,color:#fff
    style E fill:#FF9800,stroke:#E65100,color:#fff
    style F fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style K fill:#E3F2FD,stroke:#1565C0
```

---

## 20. Horizontal Pod Autoscaling with Metrics

```mermaid
graph TD
    A["Deployment:<br/>order-service<br/>Current: 10 pods"] -->|Continuously measures| B["CPU Usage<br/>Target: 70%"]
    
    C["Prometheus Metrics<br/>container_cpu_usage"] -->|Feeds| B
    
    B -->|Current: 85%| D{CPU Usage<br/>Target?}
    
    D -->|< 70% (under-scaled)| E["Scale Down to 8 pods"]
    D -->|> 80% (over-scaled)| F["Scale Up to 15 pods"]
    D -->|70-80% (balanced)| G["Keep at 10 pods"]
    
    E -->|After stability| E1["Monitor metrics<br/>1-5 min"]
    F -->|After stability| F1["Monitor metrics<br/>1-5 min"]
    G -->|Continuous| G1["Maintain current"]
    
    E1 -->|If stable| H["HPA Complete"]
    F1 -->|If stable| H
    G1 -->|No change needed| H
    
    style A fill:#E8F5E9,stroke:#2E7D32
    style B fill:#FF9800,stroke:#E65100,color:#fff
    style E fill:#2196F3,stroke:#1565C0,color:#fff
    style F fill:#F44336,stroke:#C62828,color:#fff
    style G fill:#4CAF50,stroke:#2E7D32,color:#fff
    style H fill:#4CAF50,stroke:#2E7D32,color:#fff
```

---

End of Mermaid Diagrams
