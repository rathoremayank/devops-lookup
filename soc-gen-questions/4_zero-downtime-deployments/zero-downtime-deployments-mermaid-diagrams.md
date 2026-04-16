# Zero-Downtime Deployments: Mermaid Diagrams

Comprehensive visualization of zero-downtime deployment concepts, architectures, and processes.

---

## 1. Three-Phase Deployment Model (Expand-Migrate-Contract)

```mermaid
graph LR
    A["Phase 1: EXPAND<br/>Add new capacity alongside old<br/>v1 + v2 both running"] --> B["Phase 2: MIGRATE<br/>Shift traffic gradually<br/>v1←→v2 traffic split"]
    B --> C["Phase 3: CONTRACT<br/>Remove old capacity<br/>v2 only remaining"]
    
    style A fill:#e1f5ff
    style B fill:#fff3e0
    style C fill:#f3e5f5
```

---

## 2. Kubernetes Deployment Strategies Comparison

```mermaid
graph TD
    subgraph "Rolling Update"
        RU["Old pods terminate one at a time<br/>New pods start to replace<br/>Never all pods down"]
    end
    
    subgraph "Blue-Green"
        BG["Blue: v1 100%<br/>↓<br/>Green: v2 100%<br/>↓<br/>Instant switch<br/>↓<br/>Blue kept for rollback"]
    end
    
    subgraph "Canary"
        C["v1: 99%<br/>v2: 1% ← metrics ←<br/>v2: 5% ← metrics ←<br/>v2: 25% ← metrics ←<br/>v2: 100%"]
    end
    
    subgraph "A/B Testing"
        AB["v1: 50% group A<br/>v2: 50% group B<br/>Extended metrics<br/>Measure user behavior<br/>Long-running"]
    end
    
    subgraph "Shadow"
        S["v1: 100% production<br/>v2: 100% mirrored<br/>Responses discarded<br/>Logs analyzed<br/>No user impact"]
    end
    
    style RU fill:#bbdefb
    style BG fill:#c8e6c9
    style C fill:#ffe0b2
    style AB fill:#f0f4c3
    style S fill:#e1bee7
```

---

## 3. Canary Deployment Pipeline

```mermaid
graph LR
    Start["Canary Start<br/>v1: 100%"] --> S1["Stage 1: 1%<br/>Monitor 10min<br/>Metrics OK?"]
    S1 -->|Yes| S2["Stage 2: 5%<br/>Monitor 10min<br/>Metrics OK?"]
    S1 -->|No| Rollback1["AUTO ROLLBACK<br/>Resume v1: 100%"]
    
    S2 -->|Yes| S3["Stage 3: 25%<br/>Monitor 15min<br/>Metrics OK?"]
    S2 -->|No| Rollback2["AUTO ROLLBACK<br/>Resume v1: 100%"]
    
    S3 -->|Yes| S4["Stage 4: 50%<br/>Monitor 15min<br/>Metrics OK?"]
    S3 -->|No| Rollback3["AUTO ROLLBACK<br/>Resume v1: 100%"]
    
    S4 -->|Yes| S5["Stage 5: 100%<br/>Extended monitoring<br/>30+ minutes"]
    S4 -->|No| Rollback4["AUTO ROLLBACK<br/>Resume v1: 100%"]
    
    S5 -->|Stable| Complete["DEPLOYMENT COMPLETE<br/>v2: 100%"]
    S5 -->|Degraded| Manual["MANUAL REVIEW<br/>Decide rollback"]
    
    style Start fill:#e3f2fd
    style S1 fill:#fff9c4
    style S2 fill:#fff9c4
    style S3 fill:#fff9c4
    style S4 fill:#fff9c4
    style S5 fill:#c8e6c9
    style Complete fill:#a5d6a7
    style Rollback1 fill:#ffccbc
    style Rollback2 fill:#ffccbc
    style Rollback3 fill:#ffccbc
    style Rollback4 fill:#ffccbc
    style Manual fill:#ffccbc
```

---

## 4. Liveness vs Readiness Probes

```mermaid
stateDiagram-v2
    [*] --> Initializing: Pod starts
    
    Initializing --> StartupWaiting: Startup probe active
    StartupWaiting --> ReadyWaiting: Startup probe passes
    
    ReadyWaiting --> Ready: Readiness probe passes<br/>Pod added to Service
    ReadyWaiting --> NotReady: Readiness probe fails<br/>Pod removed from Service
    
    Ready --> BeingServed: Load balancer routes traffic
    BeingServed --> Ready: Still healthy
    BeingServed --> NotReady: Readiness fails<br/>LB routes away
    
    NotReady --> Ready: Readiness recovers<br/>Re-added to Service
    NotReady --> Restarting: Liveness fails<br/>Pod killed
    
    Restarting --> Initializing: Pod restarted
    
    note right of StartupWaiting
        JVM warming up
        Config loading
        Cache initialization
    end note
    
    note right of BeingServed
        Handling requests
        Database connected
        All checks passing
    end note
    
    note right of NotReady
        Still running
        But not serving
        Isolated from traffic
    end note
```

---

## 5. Connection Draining Timeline

```mermaid
gantt
    title Connection Draining Process During Pod Termination
    dateFormat YYYY-MM-DD HH:mm:ss
    
    section Load Balancer
    Active Serving :lb1, 2026-04-17 14:00:00, 1m
    Deregistration Start :crit, lb2, 2026-04-17 14:01:00, 1s
    No New Connections :active, lb3, 2026-04-17 14:01:01, 30m
    
    section Pod Application
    Accepting Requests :app1, 2026-04-17 14:00:00, 1m1s
    SIGTERM Received :crit, app2, 2026-04-17 14:01:00, 1s
    Draining In-Flight :active, app3, 2026-04-17 14:01:01, 29m
    Request 1 (5s) :done, app4, 2026-04-17 14:01:01, 5m
    Request 2 (15s) :done, app5, 2026-04-17 14:01:01, 15m
    Request 3 (25s) :done, app6, 2026-04-17 14:01:01, 25m
    Process Exit :crit, app7, 2026-04-17 14:00:30, 1s
    
    section Old Pod State
    Healthy :healthy, 2026-04-17 14:00:00, 1m
    Terminating :crit, 2026-04-17 14:01:00, 31m
    Dead :done, 2026-04-17 14:31:00, 1s
```

---

## 6. Database Expand-Migrate-Contract Phases

```mermaid
graph TD
    subgraph "Phase 1: EXPAND"
        E1["Add new column<br/>phone_number VARCHAR20<br/>address_json JSON"]
        E2["Both old + new columns<br/>coexist in schema"]
        E1 --> E2
    end
    
    subgraph "Phase 2: MIGRATE"
        M1["Code does dual-write<br/>Write to old + new"]
        M2["Backfill job runs<br/>Copy old→new data<br/>Batched, non-blocking"]
        M3["Monitor replication lag<br/>Ensure data consistency"]
        M1 --> M2 --> M3
    end
    
    subgraph "Phase 3: CONTRACT"
        C1["Code switches reads<br/>From old → new column"]
        C2["Monitor for issues<br/>Verify correctness"]
        C3["Drop old column<br/>Clean up schema"]
        C1 --> C2 --> C3
    end
    
    E2 --> M1
    M3 --> C1
    
    style E2 fill:#c8e6c9
    style M3 fill:#fff9c4
    style C3 fill:#f8bbd0
```

---

## 7. API Versioning During Deployment

```mermaid
graph LR
    subgraph "Backwards Compatibility"
        BC1["Old Client<br/>(v1 request format)"]
        BC2["API v2<br/>(accepts both v1 + v2<br/>request formats)"]
        BC3["Response<br/>(superset: all fields)"]
        BC1 --> BC2 --> BC3
    end
    
    subgraph "Dual API Endpoints"
        DA1["Old Endpoint<br/>/api/v1/users"]
        DA2["New Endpoint<br/>/api/v2/users"]
        DA3["Both for transition<br/>period"]
        DA1 --> DA3
        DA2 --> DA3
    end
    
    subgraph "Feature Flags"
        FF1["Flag: use_new_api<br/>Initially false"]
        FF2["Canary: 1% true"]
        FF3["Expand: 5% → 25% → 100%"]
        FF4["All clients on new API"]
        FF1 --> FF2 --> FF3 --> FF4
    end
    
    subgraph "Cleanup Phase"
        C1["Old endpoints still available<br/>for legacy clients"]
        C2["Deprecation period<br/>3-6 months notice"]
        C3["Remove old endpoints"]
        C1 --> C2 --> C3
    end
    
    BC3 -.->|After testing| DA1
    DA3 -.->|Next phase| FF1
    FF4 -.->|Months later| C1
```

---

## 8. Traffic Shifting with Istio Service Mesh

```mermaid
graph TB
    Client["User Traffic<br/>10,000 req/s"]
    
    Client --> Envoy["Envoy<br/>Load Balancer"]
    
    Envoy --> |1% traffic<br/>100 req/s| V2["Pod v2<br/>(new version)"]
    Envoy --> |99% traffic<br/>9,900 req/s| V1["Pod v1<br/>(old version)"]
    
    V1 --> DB["Database"]
    V2 --> DB
    
    Envoy --> Monitor["Monitoring<br/>Check metrics"]
    Monitor --> |Error rate OK<br/>Latency OK| Expand["Expand to 5%"]
    Monitor --> |Error rate high<br/>Latency degraded| Rollback["Rollback<br/>to 0%"]
    
    Expand -.-> |After 10 min| Monitor
    
    style V1 fill:#bbdefb
    style V2 fill:#fff9c4
    style Monitor fill:#f0f4c3
    style Expand fill:#c8e6c9
    style Rollback fill:#ffccbc
```

---

## 9. Blue-Green Deployment Switch

```mermaid
graph TD
    subgraph T0["Time: t=0 (Before switch)"]
        LB1["Load Balancer<br/>Points to Blue"]
        Blue1["BLUE Environment<br/>v1.0.0<br/>100% traffic<br/>Receiving all requests"]
        Green1["GREEN Environment<br/>v2.0.0<br/>0% traffic<br/>Being tested"]
        LB1 --> Blue1
        LB1 -.->|Not routing| Green1
    end
    
    subgraph T1["Time: t=30s (After switch)"]
        LB2["Load Balancer<br/>Points to Green"]
        Blue2["BLUE Environment<br/>v1.0.0<br/>0% traffic<br/>Kept running for rollback"]
        Green2["GREEN Environment<br/>v2.0.0<br/>100% traffic<br/>Receiving all requests"]
        LB2 --> Green2
        LB2 -.->|Not routing| Blue2
    end
    
    subgraph RB["Rollback (if needed)"]
        LB3["Load Balancer<br/>Points back to Blue"]
        Blue3["BLUE Environment<br/>v1.0.0<br/>100% traffic<br/>Recovered"]
        Green3["GREEN Environment<br/>v2.0.0<br/>Halted"]
        LB3 --> Blue3
    end
    
    T0 --> |Switch<br/>1 command| T1
    T1 --> |Rollback<br/>1 command| RB
    
    style Blue1 fill:#bbdefb
    style Blue2 fill:#bbdefb
    style Blue3 fill:#bbdefb
    style Green1 fill:#fff9c4
    style Green2 fill:#c8e6c9
    style Green3 fill:#ffccbc
```

---

## 10. Deployment Monitoring Metrics

```mermaid
graph LR
    subgraph "Infrastructure Metrics"
        Infra["CPU Usage<br/>Memory Usage<br/>Network I/O<br/>Disk I/O"]
    end
    
    subgraph "Application Metrics"
        App["Error Rate (5XX)<br/>Latency (p99)<br/>Request Rate<br/>Success Rate"]
    end
    
    subgraph "Business Metrics"
        Business["Conversion Rate<br/>Transaction Volume<br/>User Session Time<br/>Revenue"]
    end
    
    subgraph "Dependency Metrics"
        Dep["Database Latency<br/>Cache Hit Rate<br/>Queue Depth<br/>External API Health"]
    end
    
    Monitor["📊 Monitoring System<br/>Prometheus/CloudWatch"]
    
    Infra --> Monitor
    App --> Monitor
    Business --> Monitor
    Dep --> Monitor
    
    Monitor --> Decision{"Metrics<br/>Healthy?"}
    
    Decision --> |YES| Continue["Continue<br/>Deployment"]
    Decision --> |NO| Alert["Alert &<br/>Investigate"]
    Decision --> |CRITICAL| Rollback["Auto<br/>Rollback"]
    
    style Monitor fill:#f0f4c3
    style Continue fill:#c8e6c9
    style Alert fill:#fff9c4
    style Rollback fill:#ffccbc
```

---

## 11. Health Check Probe Types and Lifecycle

```mermaid
sequenceDiagram
    participant K as Kubernetes
    participant P as Pod
    participant App as Application
    
    K->>P: Container starts
    activate P
    
    P->>App: Java process initializes
    activate App
    
    K->>P: Startup probe begins (polling every 2s)
    
    loop Until startup complete
        P->>App: GET /health/startup
        App-->>P: 503 (still initializing)
        P-->>K: FAILED
    end
    
    App->>App: JVM initialized, caches warmed
    
    P->>App: GET /health/startup
    App-->>P: 200 OK
    P-->>K: SUCCESS → Startup probe succeeds
    
    Note over K,App: Switch to liveness/readiness
    
    K->>P: Liveness probe begins (every 10s)
    K->>P: Readiness probe begins (every 5s)
    
    loop Running normally
        P->>App: GET /health/alive
        App-->>P: 200 OK
        P-->>K: Liveness PASS
        
        P->>App: GET /health/ready
        App-->>P: 200 OK
        P-->>K: Readiness PASS → Added to Service endpoints
    end
    
    App->>App: Database connection pool exhausted
    
    P->>App: GET /health/ready
    App-->>P: 503 (not ready)
    P-->>K: Readiness FAIL
    K-->>K: Remove pod from endpoints
    Note over K: No new traffic routed
    
    deactivate App
    deactivate P
```

---

## 12. CI/CD Pipeline Integration

```mermaid
graph DT
    subgraph "1. Source"
        Git["Developer<br/>git push origin main"]
    end
    
    subgraph "2. Build"
        Build["Build Docker image<br/>Run unit tests<br/>Push to registry"]
    end
    
    subgraph "3. Test"
        Test["Run integration tests<br/>Security scanning<br/>Coverage > 80%"]
    end
    
    subgraph "4. Staging"
        Staging["Deploy to staging<br/>Run smoke tests<br/>Performance tests"]
    end
    
    subgraph "5. Approval"
        Approval["Manual approval<br/>Required before prod"]
    end
    
    subgraph "6. Production"
        Prod["Canary deployment<br/>1% → 5% → 25% → 50% → 100%<br/>Auto-rollback on metrics"]
    end
    
    subgraph "7. Monitor"
        Monitor["Extended monitoring<br/>30+ minutes<br/>Business metrics OK?"]
    end
    
    Git --> Build --> Test --> Staging --> Approval --> Prod --> Monitor
    
    Test -.->|Fail| Git
    Staging -.->|Fail| Git
    Prod -.->|Metrics bad| Git
    
    style Git fill:#e1f5ff
    style Build fill:#fff3e0
    style Test fill:#f3e5f5
    style Staging fill:#c8e6c9
    style Approval fill:#ffe0b2
    style Prod fill:#c5e1a5
    style Monitor fill:#b2dfdb
```

---

## 13. Service Dependency Chain Deployment

```mermaid
graph LR
    subgraph "Before Deployment"
        Client1["Client"]
        API1["API v1<br/>Single endpoint<br/>/api/v1/users"]
        Service1["Order Service v1<br/>Uses old API"]
        
        Client1 --> API1 --> Service1
    end
    
    subgraph "During Deployment"
        Client2["Client"]
        API2["API v2<br/>Dual endpoints<br/>/api/v1 AND /api/v2"]
        Service2["Order Service v1<br/>Still uses /api/v1<br/>(backward compatible)"]
        Service3["New Service v2<br/>Uses /api/v2"]
        
        Client2 --> API2 --> Service2
        Client2 --> API2 --> Service3
    end
    
    subgraph "After Deployment"
        Client3["Client"]
        API3["API v2<br/>Only /api/v2<br/>Old endpoint deprecated"]
        Service4["Order Service v2<br/>Uses new API"]
        
        Client3 --> API3 --> Service4
    end
    
    style API1 fill:#bbdefb
    style API2 fill:#fff9c4
    style API3 fill:#c8e6c9
    style Service1 fill:#bbdefb
    style Service2 fill:#bbdefb
    style Service3 fill:#fff9c4
    style Service4 fill:#c8e6c9
```

---

## 14. Cascading Failure: Security Group Trap

```mermaid
graph TB
    subgraph Scenario["Scenario: Blue-Green Deployment"]
        LB["Load Balancer"]
        Blue["Blue Pods<br/>Subnet: 10.0.1.0/24<br/>v1.0.0"]
        Green["Green Pods<br/>Subnet: 10.0.2.0/24<br/>v2.0.0"]
        Order["Order Service<br/>Security Group<br/>Allow: 10.0.1.0/24"]
    end
    
    subgraph Problem["When Traffic Switches"]
        LB -->|Switching| Green
        Green -->|Trying to call| Order
        Order -->|Connection Refused<br/>Not in security group| Green
    end
    
    subgraph Solution["Fix"]
        FixRule["Update Security Group<br/>Allow: 10.0.0.0/16<br/>OR<br/>Allow sg-user-api"]
        NetworkPolicy["Better: Use K8s NetworkPolicy<br/>Allow pod with label app=user-api<br/>Subnet-independent"]
    end
    
    Problem --> FixRule
    FixRule --> NetworkPolicy
    
    style Blue fill:#bbdefb
    style Green fill:#fff9c4
    style Order fill:#ffccbc
    style FixRule fill:#c8e6c9
    style NetworkPolicy fill:#a5d6a7
```

---

## 15. Memory Leak Detection During Canary

```mermaid
graph TB
    subgraph Traffic["Traffic Expansion Timeline"]
        T1["1% traffic<br/>512 MB"]
        T5["5% traffic<br/>620 MB"]
        T25["25% traffic<br/>750 MB"]
        T50["50% traffic<br/>1.2 GB"]
        T100["100% traffic<br/>OOMKilled"]
        
        T1 --> T5 --> T25 --> T50 --> T100
    end
    
    subgraph Analysis["Memory Analysis"]
        Baseline["Baseline<br/>v1: 512 MB<br/>v2: 512 MB"]
        Growth["v2 memory<br/>grows 4MB/min<br/>v1 flat"]
        Pattern["Pattern: Linear growth<br/>Indicates leak"]
        Cause["Root Cause:<br/>Third-party lib<br/>unbounded cache"]
        
        Baseline --> Growth --> Pattern --> Cause
    end
    
    subgraph Action["Action Taken"]
        Rollback["Rollback v2"]
        Fix["Update lib to v3.2.3<br/>Fixed version"]
        Restart["Redeploy as canary"]
        
        Rollback --> Fix --> Restart
    end
    
    Traffic -.-> PauseAlert["🚨 PAUSE at 50%<br/>Memory pressure detected"]
    PauseAlert --> Analysis
    Analysis --> Action
    
    style T1 fill:#c8e6c9
    style T5 fill:#fff9c4
    style T25 fill:#fff9c4
    style T50 fill:#ffccbc
    style T100 fill:#ff5252
    style PauseAlert fill:#ff5252
    style Cause fill:#ffccbc
    style Fix fill:#c8e6c9
```

---

## 16. Backwards Compatibility Diagram (Two-Direction)

```mermaid
graph TB
    subgraph ClientCompat["Client ← API Compatibility<br/>(Accept both formats)"]
        ClientOld["Old Client<br/>{user_id: 123}"]
        ClientNew["New Client<br/>{userId: 123}"]
        
        API["API v2<br/>Accepts both formats<br/>Parses both gracefully"]
        
        ClientOld --> API
        ClientNew --> API
    end
    
    subgraph DownstreamCompat["API → Downstream Service<br/>(Output both formats)"]
        API2["API v2"]
        
        Analytics["Analytics v1.0<br/>Expects:<br/>{eventType, userId}"]
        Future["New Analytics v2<br/>Expects:<br/>{event_type, user_id}"]
        
        API2 -->|Sends superset<br/>both key styles| Analytics
        API2 -->|Sends superset<br/>both key styles| Future
    end
    
    ClientCompat --> API2
    
    style API fill:#c8e6c9
    style API2 fill:#c8e6c9
    style Analytics fill:#bbdefb
    style Future fill:#fff9c4
```

---

## 17. Kubernetes StatefulSet Upgrade with Health Validation

```mermaid
graph TD
    subgraph T1["Time: t=0"]
        RB1["RabbitMQ Cluster<br/>rabbitmq-0: v1.10<br/>rabbitmq-1: v1.10<br/>rabbitmq-2: v1.10<br/>All healthy"]
    end
    
    subgraph T2["Time: t=1-5min"]
        RB2["Upgrade Pod 0<br/>rabbitmq-0: v2.0 (new)<br/>rabbitmq-1: v1.10<br/>rabbitmq-2: v1.10"]
        Check2["Health check<br/>✓ Cluster quorum OK<br/>✓ Replication healthy"]
        RB2 --> Check2
    end
    
    subgraph T3["Time: t=6-10min"]
        RB3["Upgrade Pod 1<br/>rabbitmq-0: v2.0<br/>rabbitmq-1: v2.0 (new)<br/>rabbitmq-2: v1.10"]
        Check3["Health check<br/>✓ Cluster quorum OK<br/>✓ No partition"]
        RB3 --> Check3
    end
    
    subgraph T4["Time: t=11-15min"]
        RB4["Upgrade Pod 2<br/>rabbitmq-0: v2.0<br/>rabbitmq-1: v2.0<br/>rabbitmq-2: v2.0 (new)<br/>Cluster rebalances"]
        Check4["Health check<br/>✓ All nodes rejoined<br/>✓ Queues accessible"]
        RB4 --> Check4
    end
    
    subgraph Prevention["Prevention Features"]
        MinReady["minReadySeconds: 60<br/>Wait 60s before next upgrade"]
        AntiAff["Pod anti-affinity<br/>Spread replicas across nodes"]
        Readiness["Readiness probe<br/>Pod must connect to cluster"]
    end
    
    T1 --> T2 --> T3 --> T4
    Prevention -.-> T2
    Prevention -.-> T3
    Prevention -.-> T4
    
    style T1 fill:#c8e6c9
    style T2 fill:#fff9c4
    style T3 fill:#fff9c4
    style T4 fill:#fff9c4
    style Check4 fill:#a5d6a7
    style MinReady fill:#b3e5fc
    style AntiAff fill:#b3e5fc
    style Readiness fill:#b3e5fc
```

---

## 18. Automated Rollback Decision Tree

```mermaid
graph TD
    Start["Canary Deployment<br/>Monitoring Active"] --> Q1{"Error Rate<br/>Increased?"}
    
    Q1 -->|No| Q2{"Latency p99<br/>Degraded?"}
    Q1 -->|Yes| CheckThreshold{"Error Rate<br/>> baseline + 1%?"}
    
    CheckThreshold -->|Yes| ROLLBACK1["🚨 AUTO ROLLBACK<br/>Error threshold exceeded"]
    CheckThreshold -->|No| Q2
    
    Q2 -->|No| Q3{"Pod Restart<br/>Rate High?"}
    Q2 -->|Yes| CheckLatency{"Latency<br/>> baseline × 1.2?"}
    
    CheckLatency -->|Yes| ROLLBACK2["🚨 AUTO ROLLBACK<br/>Latency threshold exceeded"]
    CheckLatency -->|No| Q3
    
    Q3 -->|No| Q4{"Memory/CPU<br/>Saturated?"}
    Q3 -->|Yes| ROLLBACK3["🚨 AUTO ROLLBACK<br/>Restart loop detected"]
    
    Q4 -->|No| Q5{"Database<br/>Performance OK?"}
    Q4 -->|Yes| ROLLBACK4["🚨 AUTO ROLLBACK<br/>Resource exhaustion"]
    
    Q5 -->|No| ROLLBACK5["🚨 AUTO ROLLBACK<br/>Database degraded"]
    Q5 -->|Yes| Continue["✅ CONTINUE<br/>All metrics healthy<br/>Expand traffic"]
    
    Continue --> Monitor["Monitor next stage<br/>Repeat checks"]
    
    style Start fill:#e3f2fd
    style Continue fill:#c8e6c9
    style ROLLBACK1 fill:#ffccbc
    style ROLLBACK2 fill:#ffccbc
    style ROLLBACK3 fill:#ffccbc
    style ROLLBACK4 fill:#ffccbc
    style ROLLBACK5 fill:#ffccbc
    style Monitor fill:#fff9c4
```

---

## 19. Graceful Shutdown Process

```mermaid
sequenceDiagram
    participant K as Kubernetes
    participant App as Application
    participant Client as Load Balancer
    
    K->>App: SIGTERM signal
    Note over K: Pod marked for termination
    
    K->>Client: Remove pod from endpoints
    Note over Client: Stop routing new traffic
    Client-->>K: Deregistration complete
    
    App->>App: Enter graceful shutdown
    App->>App: Stop accepting new requests
    
    loop In-flight requests
        App->>App: Request 1: 5s processing
        App->>App: Request 2: 10s processing
        App->>App: Request 3: 2s processing
    end
    
    App->>App: Request 1 complete
    App->>App: Request 2 complete
    App->>App: Request 3 complete
    
    App->>App: Close database connections
    App->>App: Flush remaining data
    App->>K: Exit process (code 0)
    
    K->>K: Pod terminated
    Note over K: Success: All requests completed
    
    Note over K,App: Total time: ~15 seconds<br/>Within terminationGracePeriodSeconds
```

---

## 20. Full Deployment Lifecycle with All Phases

```mermaid
graph TB
    subgraph Planning["1. PLANNING PHASE"]
        P1["Determine deployment<br/>strategy"]
        P2["Identify risks &<br/>metrics to monitor"]
        P3["Define rollback<br/>criteria"]
        P1 --> P2 --> P3
    end
    
    subgraph Staging["2. STAGING PHASE"]
        S1["Deploy to staging<br/>using same strategy"]
        S2["Run tests<br/>Load testing"]
        S3["Smoke tests pass<br/>✓ Approval for prod"]
        S1 --> S2 --> S3
    end
    
    subgraph Deployment["3. DEPLOYMENT PHASE"]
        D1["Canary: 1% traffic"]
        D2["Monitor: 10 minutes"]
        D3["Canary: 5% traffic"]
        D4["Canary: 25%→50%→100%"]
        D1 --> D2 --> D3 --> D4
    end
    
    subgraph Monitoring["4. MONITORING PHASE"]
        M1["Extended monitoring<br/>30+ minutes"]
        M2["All business metrics<br/>normal?"]
        M3["✓ Deployment success"]
        M1 --> M2 --> M3
    end
    
    subgraph Rollback["ROLLBACK (if needed)"]
        R1["Metrics exceed<br/>thresholds"]
        R2["Decision: Auto or Manual"]
        R3["Revert to v1"]
        R4["Verify stability"]
        R1 --> R2 --> R3 --> R4
    end
    
    Planning --> Staging --> Deployment --> Monitoring
    Deployment -.-> Rollback
    Monitoring -.-> Rollback
    
    style P3 fill:#a5d6a7
    style S3 fill:#a5d6a7
    style D4 fill:#a5d6a7
    style M3 fill:#a5d6a7
    style Rollback fill:#ffccbc
```

---

## 21. Payment Service Deployment Case Study

```mermaid
graph LR
    subgraph Weeks["1-2 Weeks: Development<br/>& Testing"]
        Dev["Develop new<br/>fraud algorithm"]
        UTest["Unit tests: 95%"]
        ITest["Integration tests<br/>Pass"]
        LTest["Load test<br/>100k req/s"]
        Dev --> UTest --> ITest --> LTest
    end
    
    subgraph Shadow["2 Weeks: Shadow<br/>Deployment"]
        S1["Deploy alongside<br/>production algorithm"]
        S2["Mirror 100% traffic"]
        S3["Compare decisions<br/>0.03% differ"]
        S4["Analyze differences<br/>✓ Safe"]
        S1 --> S2 --> S3 --> S4
    end
    
    subgraph Canary["4 Weeks: Canary<br/>Rollout"]
        C1["0.1% traffic<br/>Live detection"]
        C2["1% traffic"]
        C3["5% traffic"]
        C4["25% traffic"]
        C1 --> C2 --> C3 --> C4
    end
    
    subgraph Full["1 Week: Full<br/>Rollout"]
        F1["50% traffic"]
        F2["75% traffic"]
        F3["100% traffic"]
        F4["2 weeks extended<br/>monitoring"]
        F1 --> F2 --> F3 --> F4
    end
    
    Weeks --> Shadow --> Canary --> Full
    
    style LTest fill:#c8e6c9
    style S4 fill:#c8e6c9
    style C4 fill:#c8e6c9
    style F4 fill:#a5d6a7
```

---

## 22. Immutable Infrastructure Principle

```mermaid
graph TD
    subgraph Mutable["❌ MUTABLE (Dangerous)"]
        M1["ssh production-server"]
        M2["apt-get update && patch"]
        M3["Modify config locally"]
        M4["Restart service"]
        M5["Modified state unknown"]
        M1 --> M2 --> M3 --> M4 --> M5
    end
    
    subgraph Immutable["✅ IMMUTABLE (Safe)"]
        I1["Code change"]
        I2["Build new Docker image"]
        I3["Push to registry"]
        I4["Deploy new image"]
        I5["Old image available<br/>for rollback"]
        I1 --> I2 --> I3 --> I4 --> I5
    end
    
    subgraph Benefits["Benefits of Immutable"]
        B1["Reproducible: Same image locally<br/>and production"]
        B2["Rollback instant:<br/>Old image always available"]
        B3["Blue-green safe:<br/>Two immutable environments"]
        B4["Debugging easier:<br/>Known, unchanged state"]
    end
    
    style M5 fill:#ffccbc
    style I5 fill:#c8e6c9
    style B1 fill:#b3e5fc
    style B2 fill:#b3e5fc
    style B3 fill:#b3e5fc
    style B4 fill:#b3e5fc
```

---

## Summary

This comprehensive set of Mermaid diagrams covers:

- **Deployment Strategies**: Rolling, blue-green, canary, A/B, shadow
- **Kubernetes Concepts**: Probes, StatefulSets, pod lifecycle
- **Database Migrations**: Expand-migrate-contract pattern
- **Traffic Management**: Load balancing, service mesh
- **Monitoring & Rollback**: Automated decision trees
- **Real-world Scenarios**: Cascading failures, performance issues
- **Best Practices**: Immutable infrastructure, graceful shutdown
- **Case Studies**: Complete deployment lifecycle examples

Each diagram is self-contained and uses standard Mermaid syntax for easy integration into documentation, wikis, or training materials.

---

**Document Version**: 1.0  
**Total Diagrams**: 22 Mermaid visualizations  
**Format**: Markdown with embedded Mermaid code blocks  
**Use Cases**: Documentation, training, architecture review, incident analysis