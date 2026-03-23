# Site Reliability Engineering: Hands-on Scenarios & Interview Questions

**Final Study Guide - Practical Application & Assessment**

---

## Part 1: Hands-on Scenarios

### Scenario 1: Multi-Region Failover During Security Incident

**Problem Statement**

You're on-call at 2 AM. Alert fires: "Unusual database activity detected in us-east-1 region. 10GB of data accessed from unfamiliar IP in 5 minutes."

Security team is investigating, but logs show a database credential was compromised. You have 3 options:
1. Isolate and forensically analyze the compromised database (12-hour investigation)
2. Immediately fail over to us-west-2 region (5-minute recovery, but lose 30 minutes of analytics data)
3. Implement read-only mode on compromised database + rotate creds + block IP + continue operating

**Architecture Context**

```
Production Setup:
  ┌─────────────────────────────────────────────┐
  │             us-east-1 (Primary)              │
  │ ┌──────────────────────────────────────────┐ │
  │ │  Payment Service (100 req/sec)           │ │
  │ │  User Service (500 req/sec)              │ │
  │ │  Analytics Service (50 req/sec)          │ │
  │ └──────────────────────────────────────────┘ │
  │ ┌──────────────────────────────────────────┐ │
  │ │  PostgreSQL Master (8TB, replicated)     │ │
  │ │  Redis Cache (256GB)                     │ │
  │ │  Kafka Cluster (message queue)           │ │
  │ └──────────────────────────────────────────┘ │
  └─────────────────────────────────────────────┘
              ↓ (15-min replication lag)
  ┌─────────────────────────────────────────────┐
  │             us-west-2 (Standby)              │
  │ ┌──────────────────────────────────────────┐ │
  │ │  Read replicas of master                 │ │
  │ │  No active traffic (DR only)             │ │
  │ └──────────────────────────────────────────┘ │
  └─────────────────────────────────────────────┘

SLA: 99.99% (4 minutes/month downtime budget)
Current month: 2 minutes used (2 minutes remaining)
Risk: Any outage exceeds SLA for month
```

**Step-by-Step Resolution**

**Step 1: Immediate Triage (2:00 AM - 2:05 AM)**

Action:
```bash
# Check severity of compromise
SELECT COUNT(*) FROM audit_log 
WHERE timestamp > NOW() - INTERVAL '5 minutes'
  AND action = 'SELECT'
  AND ip_address = '203.0.113.50';

# Result: ~50 million rows read (10GB verified)
# Concern: Is data exfiltrated? Unknown at this point
```

Decision: This is **security incident + reliability incident** (dual concern).

**Step 2: Implement Immediate Containment (2:05 AM - 2:10 AM)**

```sql
-- Option 1: Kill compromised connection immediately
SELECT pg_terminate_backend(pid) 
WHERE query LIKE '%203.0.113.50%';

-- Option 2: Revoke compromised credential
ALTER ROLE analytics_service_user WITH PASSWORD 'new_secure_password_12345';

-- Option 3: Block IP at firewall
INSERT INTO ip_whitelist_exceptions 
VALUES ('203.0.113.50', 'DENY', 'Security incident response');
```

**Step 3: Assess Impact Range (2:10 AM - 2:15 AM)**

Investigate which data was accessed:

```bash
# Find what tables were queried
psql -c "SELECT schemaname, tablename, COUNT(*) as scans 
FROM pg_stat_user_tables 
WHERE seq_scan > (SELECT seq_scan FROM pg_stat_user_tables WHERE tablename='baseline'
LIMIT 1)
ORDER BY seq_scan DESC LIMIT 20;"

# Results show:
# - customer_data: 2M rows
# - payment_records: 500K rows  
# - internal_config: 50 rows (CRITICAL)
```

**Critical finding**: `internal_config` was accessed (contains API keys, secrets).

**Step 4: Decide Response Level (2:15 AM - 2:20 AM)**

Customer impact depends on decision:

**Option 1: Full Failover (immediate)**
- Time to recover: 5 minutes
- Data loss: 30 minutes of new orders (analytics only)
- SLA impact: Uses 5 minutes of budget → breach
- Security benefit: Removes attacker access immediately
- Operational risk: Complex failover at 2 AM, might break things

**Option 2: Write-protection + Key rotation (immediate)**
- Time to implement: 2 minutes
- Data loss: 0 (still operational)
- SLA impact: 0 additional downtime
- Security benefit: Prevents further exfiltration, attacker still sees old data
- Operational risk: Attackers might realize they're caught, escalate

**Option 3: Business-as-usual + forensics (slow)**
- Time to continue: Immediate
- Data loss: 0
- SLA impact: 0
- Security benefit: None (attackers still active)
- Operational risk: Data breach continues, potential liability

**Decision: Option 2** (write-protection + key rotation)

Rationale:
- Mitigates future damage immediately (2 minutes)
- Maintains SLA (no additional downtime)
- Allows parallel forensics investigation
- Can escalate to failover if attacker escalates

**Step 5: Implementation (2:20 AM - 2:25 AM)**

```bash
#!/bin/bash
# Immediate security response

# 1. Revoke compromised user
psql -U postgres -c "
ALTER ROLE analytics_service_user WITH NOLOGIN;
REASSIGN OWNED BY analytics_service_user TO postgres;
DROP ROLE IF EXISTS analytics_service_user;
"

# 2. Create new analytics user with new password
NEW_PASSWORD=$(openssl rand -base64 32)
psql -U postgres -c "
CREATE ROLE analytics_service_user WITH LOGIN PASSWORD '$NEW_PASSWORD';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_service_user;
GRANT USAGE ON ALL SCHEMAS IN SCHEMA public TO analytics_service_user;
"

# 3. Rotate secret in key management system
aws secretsmanager update-secret \
  --secret-id prod/analytics-db-password \
  --secret-string "$NEW_PASSWORD" \
  --tags Key=rotated_at,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 4. Update all services with new credentials
for service in analytics payment user-service; do
  kubectl set env deployment/$service \
    DB_PASSWORD="$NEW_PASSWORD" \
    -n prod
  
  # Forces pod restart with new credentials
  kubectl rollout restart deployment/$service -n prod
done

# 5. Block IP at multiple layers
# Firewall layer
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --cidr 203.0.113.50/32 \
  --ip-protocol tcp \
  --from-port 0 \
  --to-port 65535 \
  --no-dry-run

# 6. Enable query logging for forensics
ALTER SYSTEM SET log_min_duration_statement = 0;
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

# 7. Alert security team
echo "Security incident: Analytics credential compromised. 
  Attacker IP: 203.0.113.50
  Data accessed: customer_data, payment_records, internal_config
  Time of compromise: 2:00 AM UTC
  Response: Credential revoked, key rotation initiated, IP blocked
  Forensics: Query logs enabled, monitoring activated" | \
  mail -s "URGENT: Database Security Incident Response" security-team@company.com
```

**Step 6: Parallel Forensics Investigation (2:25 AM - ongoing)**

While services restart:

```bash
# Extract forensic data before replication might complicate analysis
pg_dump -Fd prod_db -f /forensics/db_snapshot_$(date +%s)

# Extract query logs for analysis
tail -f /var/log/postgresql/postgresql.log | \
  grep "203.0.113.50" > /forensics/attacker_queries.log

# Check for data exfiltration methods
# Search for unusual outbound connections
tcpdump -i any 'src host 203.0.113.50' -w /forensics/network_capture.pcap

# Monitor for post-compromise persistence (backdoors)
find /var -type f -mtime -30 -exec ls -lah {} \; > /forensics/recent_files.log
```

**Step 7: Post-Incident (2:30 AM - 3:00 AM)**

```
Timeline for management:
  2:00 - Incident detected (database anomaly alert)
  2:05 - Severity assessed (read access, internal_config accessed)
  2:10 - Containment initiated (user revoked, password rotated)
  2:15 - Services restarted with new credentials
  2:25 - Forensics capture complete
  2:30 - Attacker access revoked, IP blocked
  2:35 - Services stabilized, performance back to normal
  
Status: 
  ✓ Incident contained
  ✓ No data loss
  ✓ All services operational
  ✓ SLA maintained (no additional outtime)
  ~ Data breach likely occurred (investigate scope)
  
Next steps:
  1. Forensic analysis: What data left the network? (24 hours)
  2. Root cause: How did credential get compromised? (48 hours)
  3. Remediation: Implementation of safeguards (1 week)
  4. Post-mortem: Incident review (3 days)
```

**Best Practices Demonstrated**

✓ **Immediate containment over investigation**: Revoke access immediately, then forensics in parallel
✓ **Layered defense**: Block at firewall + revoke credential + rotate keys + monitor
✓ **Security-aware incident response**: Decision framework that considers both security and reliability
✓ **Minimal customer impact**: Continue operations instead of cascading to full failover
✓ **Audit trail**: Logging, forensic capture for compliance and root cause analysis

---

### Scenario 2: Performance Degradation During Peak Traffic

**Problem Statement**

Friday, 2 PM (peak traffic): Customers report "site is slow." API response time is 500ms-2000ms (target: 200ms p99).

You have:
- 15 minutes before media/social media explodes
- 30 minutes before revenue/SLA impact is severe
- Error rate is still normal (<0.5%)
- But users are churning (abandoning checkout)

**Architecture Context**

```
Microservice Stack:
  ┌────────────────────────────────────────┐
  │  Load Balancer                         │
  │  (nginx, 10 servers)                   │
  └────────────────────────────────────────┘
           ↓
  ┌────────────────────────────────────────┐
  │  API Gateway                           │
  │  (50 instances, auto-scaling enabled)  │
  └────────────────────────────────────────┘
           ↓
  ┌────┬────────┬──────────┬────────────┐
  │    │        │          │            │
  ▼    ▼        ▼          ▼            ▼
[User][Cart][Products][Payment][Analytics]
Services

Backend:
  PostgreSQL: 32 CPU, 256GB RAM (heavily used)
  Redis: 1TB cache cluster (session + product catalog)
  Elasticsearch: Search queries
  S3: Product images
```

**Metrics at Time of Incident**

```
API Gateway metrics:
  Request rate: 8,000 req/sec (peak = 10,000 req/sec normally)
  P99 latency: 1800ms (target: 200ms)
  Error rate: 0.3% (acceptable range)
  
Database metrics:
  Query latency: 100ms average (normally 10ms)
  CPU: 92% (normally 45%)
  Connections: 495/500 (at limit!)
  
Redis metrics:
  Hit rate: 60% (normally 95%)
  Evictions/sec: 1000 (normally 0)
  Memory: 100% used
  
Deployment log:
  Nothing deployed in last 30 minutes
  Last deployment was 2 hours ago (stable)
```

**Step-by-Step Troubleshooting**

**Step 1: Identify Bottleneck (Minute 0-3)**

Question: "Where is time being spent?"

Trace request:
```
User Request timing breakdown:
  API Gateway processing: 10ms ✓
  Service call to Product service: 50ms ✓
  Product service calls DB: 150ms ✗ (normally 5ms!)
  Database query: 100ms ✓ (query itself fast)
  Database lock wait: 50ms ✗ (normally 0ms!)
  Return to Product service: 5ms ✓
  Product service processes result: 20ms ✓
  Redis cache write: 50ms ✗ (normally 5ms!)
  
Total: 435ms (actual: 1800ms... what's the other 1365ms?)
```

Issue identified: Database is slow + Redis is being hit hard.

**Step 2: Check for Resource Contention (Minute 3-6)**

```bash
# Check database connections
psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Result: 495 connections (at max limit)
# Nearly all from Product service querying catalog

# Check what queries are running
psql -c "
SELECT pid, usename, application_name, state, query 
FROM pg_stat_activity 
WHERE state != 'idle'
ORDER BY xact_start ASC
LIMIT 10;"

# Result: Mostly SELECT on product_catalog table
# But queries are joining against 5 other large tables

# Check query execution plan
EXPLAIN ANALYZE SELECT * FROM product_catalog 
  JOIN inventory ON product_catalog.id = inventory.product_id
  JOIN pricing ON product_catalog.id = pricing.product_id
  ...
  WHERE category = 'laptops' AND price < 1000;

# Result: Sequential scan (not using index!) on inventory table
# This sequential scan is locking the table, blocking other queries
```

**Root cause identified**: Missing index on inventory table causing sequential scan.

**Step 3: Hypothesis Testing (Minute 6-9)**

Hypothesis: "Missing index causing sequential scan causing table lock causing cascade"

Evidence:
```
✓ Last deployment 2 hours ago included product search optimization
✓ That query would hit product_catalog + inventory
✓ Normally this query would use index (fast)
✓ But if index is corrupt or missing: sequential scan
✓ Sequential scan causes lock: other writers have to wait
✓ Other writers (checkout, cart) also need inventory: they queue
✓ Queue builds: request backlog
✓ Backlog builds: connection pool exhausted
✓ Result: cascading latency
```

**Step 4: Immediate Remediation Options (Minute 9-12)**

**Option A: Add missing index (fix)**
```sql
CREATE INDEX CONCURRENTLY idx_inventory_product_id 
ON inventory(product_id);

Time: 2-3 minutes
Risk: CREATE INDEX blocks table for write operations if not CONCURRENTLY
Benefit: Fixes root cause permanently
```

**Option B: Disable slow feature flag (rollback)**
```bash
kubectl set env deployment/product-service \
  FEATURE_FLAG_OPTIMIZE_SEARCH=false \
  -n prod

Time: 30 seconds
Risk: Reverts to pre-optimization (normal speed)
Benefit: Immediate, zero risk
```

**Option C: Scale database (throwmoney)**
```bash
# Add read replicas
rds-create-read-replica --source-db prod-db \
  --target-db prod-db-replica-1 --instance-type db.r5.8xlarge

Time: 5 minutes
Cost: $4,000/month
Benefit: Distributes load, but doesn't fix root cause
```

**Decision: Combine B (immediate) + A (longer term)**

**Step 5: Immediate Remediation (Minute 12-15)**

```bash
#!/bin/bash
# Immediate: Disable feature flag causing slow query

kubectl set env deployment/product-service \
  FEATURE_FLAG_OPTIMIZE_SEARCH=false \
  -n prod

# Force restart pods to apply immediately
kubectl rollout restart deployment/product-service -n prod

# Monitor impact
for i in {1..10}; do
  LATENCY=$(curl -s http://localhost:8080/metrics | \
    grep 'api_latency_p99' | awk '{print $2}')
  echo "P99 latency: ${LATENCY}ms"
  sleep 2
done
```

**Step 6: Monitor Recovery (Minute 15-20)**

```
Minutes after rollback:
  Minute 15: P99 latency: 1800ms (no change yet, pods restarting)
  Minute 16: P99 latency: 1200ms (pods restarting...)
  Minute 17: P99 latency: 400ms (new pods online)
  Minute 18: P99 latency: 250ms (connections draining)
  Minute 19: P99 latency: 210ms (mostly recovered)
  Minute 20: P99 latency: 195ms (normal, ✓ incident resolved)
  
Total impact: 20 minute degradation
SLA impact: ~0.5% of requests affected (P99 latency > SLA)
Customer impact: Slow checkout experience, some abandons
Revenue impact: ~$50K loss (estimated)
```

**Step 7: Fix Root Cause (Hour 1-2)**

```bash
# Once stable, fix the index that caused the problem

# First validate on staging
psql -h staging-db -c "
EXPLAIN ANALYZE SELECT * FROM product_catalog 
  WHERE category = 'laptops' AND price < 1000;"

# Current: Seq Scan (bad)
# After index: Index Scan (good)

# Apply to production
psql -h prod-db -c "
CREATE INDEX CONCURRENTLY idx_inventory_product_id 
ON inventory(product_id);"

# Verify query performance improved
psql -h prod-db -c "
SELECT * FROM product_catalog 
WHERE category = 'laptops' AND price < 1000;" 
# Time: ~10ms (was 100ms+)

# Re-enable feature flag
kubectl set env deployment/product-service \
  FEATURE_FLAG_OPTIMIZE_SEARCH=true \
  -n prod

kubectl rollout restart deployment/product-service -n prod

# Monitor performance stays good
```

**Best Practices Demonstrated**

✓ **Systematic root cause analysis**: Metric → wait analysis → query analysis → lock identification
✓ **Fast vs permanent fix**: Disable feature flag immediately (20 min recovery), add index long-term (permanent)
✓ **Proper CONCURRENTLY index creation**: Doesn't block writes during index creation
✓ **Feature flags for quick rollback**: Not just for feature toggling, but performance optimization isolation
✓ **Metrics-driven decision making**: Data showed which query was slow, not guesses

---

### Scenario 3: Multi-tenant Noisy Neighbor Incident

**Problem Statement**

Monday, 10 AM: Three of your largest customers report "their app is slow." But 97 other customers report "everything fine."

The three affected customers are:
- Customer A: SaaS analytics (high volume)
- Customer B: Ecommerce platform (mission critical)
- Customer C: Internal tools (low priority)

But they all share the same Kubernetes cluster, same database, same Redis.

Your SLO says each customer tier gets guaranteed 99.95% availability.

**Architecture Context**

```
Multi-tenant Kubernetes cluster:

┌────────────────────────────────────────────────────────────┐
│                   Shared Kubernetes Cluster                │
│                  (100 customer deployments)                │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Namespaces (one per customer)                       │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │Customer A│ │Customer B│ │Customer C│  ... 97    │  │
│  │  │(shared   │ │(shared   │ │(shared   │  more      │  │
│  │  │ CPU, RAM)│ │ CPU, RAM)│ │ CPU, RAM)│            │  │
│  │  └──────────┘ └──────────┘ └──────────┘            │  │
│  └──────────────────────────────────────────────────────┘  │
│                           ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Shared Backend                                      │  │
│  │  ┌──────────────────────────────────────────────────┐│  │
│  │  │  PostgreSQL database (32 CPU, 256GB RAM)        ││  │
│  │  │  - All 100 customers use same DB                ││  │
│  │  │  - Connection pool: 500 connections total       ││  │
│  │  │  - No per-customer quotas                       ││  │
│  │  └──────────────────────────────────────────────────┘│  │
│  │  ┌──────────────────────────────────────────────────┐│  │
│  │  │  Redis cache (1TB)                              ││  │
│  │  │  - All customers share same cache               ││  │
│  │  │  - No eviction policy, evicts LRU                ││  │
│  │  └──────────────────────────────────────────────────┘│  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘

Resource quotas per customer:
  CPU: 2 cores (shared cluster = 200 cores total)
  Memory: 8GB (shared cluster = 800GB total)
  Pods: 10 max
  
Database connection limit:
  Per customer: NOT ENFORCED (pooling at cluster level)
  
```

**Symptoms**

```
Customer A (analytics):
  P99 latency: 500ms (normal: <100ms)
  Error rate: 2%
  Database connections: 80 of 500 total pool
  
Customer B (ecommerce):
  P99 latency: 800ms (normal: <100ms)
  Error rate: 5%
  Database connections: 90 of 500 total pool
  
Customer C (internal tools):
  P99 latency: 600ms (normal: <100ms)
  Error rate: 1%
  Database connections: 50 of 500 total pool
  
Customers D-Z (everyone else):
  P99 latency: 90ms ✓ normal
  Error rate: 0.2% ✓ normal
  Database connections: 200 of 500 total pool

Total database connections: ~420 in use
Slack in pool: ~80 connections (tightening)

Problem: Customer A, B, C using 220 connections (44% of pool)
         but they only represent 3% of customers (should be using ~3%)
         
Who's hogging connections?
```

**Step-by-Step Diagnosis and Remediation**

**Step 1: Identify Noisy Neighbor (Minute 0-5)**

```bash
# Find CPU-heavy pod
kubectl top pods -A --sort-by=cpu | head -20

# Result:
# NAMESPACE    POD                              CPU
# customer-a   analytics-worker-5d8f9c         1800m (1.8 cores! Out of 2 core limit)
# customer-a   analytics-api-4f3f2e            800m
# customer-b   ecommerce-api-primary-9d2e1f    900m
# customer-c   internal-tools-worker-3c4d2f    600m
# customer-d   dashboard-app-1e5f4g            150m
# ... (everyone else using <300m each)

# Customer A and B together using 3500m (1.8 + 0.8 + 0.9 = 3.5 cores)
# This starves everyone else from CPU (shared cluster = contention)

# Find which pods are using database connections
kubectl exec -it customer-a-analytics-worker-5d8f9c -n customer-a -- \
  netstat -an | grep :5432 | wc -l
# Result: 50 connections from this single pod

# Check what queries are running
kubectl exec -it customer-a-analytics-worker-5d8f9c -- \
  ps aux | grep postgres
# Result: Dozens of concurrent queries
```

**Root cause identified**: Customer A has runaway analytics job spawning many concurrent database queries.

**Step 2: Immediate Isolation (Minute 5-10)**

**Option A: Kill Customer A pods** (nuclear option)
- Removes the noisy neighbor completely
- Impact: Customer A service down (SLA breach for them)
- Benefit: 30 seconds to execute

**Option B: Scale down Customer A** (graceful degradation)
- Reduce resource quota for Customer A
- Impact: Customer A slower, others recover
- Benefit: Customer A still gets service, reduced priority

**Option C: Quarantine Customer A** (separate tier)
- Move Customer A to separate database/cluster
- Impact: Requires ~1 hour to execute
- Benefit: Permanent solution, no interference

**Decision: Option B (immediate) + Option C (long-term)**

```bash
#!/bin/bash
# Immediate: Reduce Customer A resource quota

# Current quota: 2 CPU cores
# New quota: 0.5 CPU cores
# Reasoning: Give Customer A some resources but prevent monopoly

kubectl set resources deployment analytics-worker \
  -n customer-a \
  --requests=cpu=100m,memory=256Mi \
  --limits=cpu=500m,memory=1Gi

# Result: Pod gets killed (exceeding limits) and restarted with new limits
# Within 30 seconds: Customer A throttled, CPU available for others

# Verify impact on other customers
kubectl top nodes  # Should show CPU freed up
# Result: CPU went from 85% → 60% (freed capacity for others)

# Monitor if other customers recover
# Check latency trend
for i in {1..5}; do
  LATENCY=$(kubectl logs -n monitoring -l app=prometheus | \
    grep 'api_latency_p99' | tail -1 | awk '{print $2}')
  echo "P99 latency: ${LATENCY}ms"
  sleep 5
done
```

**Step 3: Investigation During Incident (Minute 10-15)**

```bash
# Find out what Customer A is doing

# Check database logs for their queries
psql -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
WHERE query LIKE '%customer_a%'
ORDER BY total_time DESC LIMIT 10;"

# Result:
# Query like: SELECT COUNT(*) FROM large_table WHERE user_id = 12345
# calls: 1000 (this query executed 1000 times in last minute!)
# mean_time: 50ms each
# Total: 50 seconds of queries in last minute

# Investigation: Why 1000 calls in 1 minute?
# Query their application code...
# Found: Analytics job has a bug - infinite loop calling database

# The bug: 
#   for i in 1 to 1,000,000:
#     SELECT COUNT(*) FROM user_events 
#     WHERE user_id = random_customer_id()
#   (No pagination, no batching, no throttling)
```

**Step 4: Customer Communication (Minute 10)**

```
Alert Customer A:
  "We've identified that your analytics job is consuming excessive database 
   resources, impacting other customers on shared cluster.
   
   We're temporarily throttling your resources to 0.5 CPU cores to prevent 
   cascading failures.
   
   Impact to you: Your analytics job will run slower
   Impact to others: Service restored to normal
   
   Recommended action: Fix your analytics query (infinite loop detected)
   
   If you need more resources:
   1. Upgrade to dedicated database tier (+$5K/month)
   2. Reduce query scope or add batching/throttling
   3. Split analytics workload across multiple smaller queries
"
```

**Step 5: Implement Long-Term Solution (Hour 1-2)**

```bash
#!/bin/bash
# Implement per-customer database connection limits

# Create connection pool per customer tier

# Tier 1 (Premium): 100 connections
# Tier 2 (Standard): 50 connections
# Tier 3 (Free): 10 connections

# Implementation via pgbouncer (connection pooling middleware)

cat > /etc/pgbouncer/pgbouncer.ini << EOF
[databases]
prod_customer_a = host=db.prod port=5432 dbname=customer_a
prod_customer_b = host=db.prod port=5432 dbname=customer_b
prod_database = host=db.prod port=5432 dbname=multi_tenant

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
res_pool_size = 5

# Per-customer limits
customer_a_pool_size = 100
customer_b_pool_size = 50
customer_c_pool_size = 10
EOF

# Restart pgbouncer with new config
systemctl restart pgbouncer

# Result: Each customer can only open up to X connections
#         Any attempt to exceed limit: REJECTED (graceful failure)
#         Customer A trying 200 connections: Gets "connection pool full"
```

**Step 6: Implement Resource Quotas in Kubernetes (Long-term)**

```yaml
# Create LimitRange for multi-tenant cluster
apiVersion: v1
kind: Namespace
metadata:
  name: customer-a

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: customer-a-quota
  namespace: customer-a
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "8Gi"
    limits.cpu: "4"
    limits.memory: "16Gi"
    pods: "10"
    services: "5"
    persistentvolumeclaims: "2"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: customer-a-limits
  namespace: customer-a
spec:
  limits:
  - max:
      cpu: "1"
      memory: "2Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "2"
      memory: "8Gi"
    min:
      cpu: "200m"
      memory: "256Mi"
    type: Pod

---
# Network Policy: Customer A can't access Customer B's services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-a-isolation
  namespace: customer-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: customer-a
    - namespaceSelector:
        matchLabels:
          name: ingress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: customer-a
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
  - to:
    - namespaceSelector:
        matchLabels:
          name: shared-backend
```

**Best Practices Demonstrated**

✓ **Noisy neighbor identification**: Metrics → CPU/memory analysis → database connection analysis
✓ **Graceful degradation**: Throttle misbehaving customer, don't kill (SLA partial breach vs complete)
✓ **Immediate fix + long-term solution**: Reduce quota now, implement permanent quotas later
✓ **Multi-layer isolation**: Kubernetes quotas + database connection limits + network policies
✓ **Per-tier resource allocation**: Premium/Standard/Free tiers have different limits

---

## Part 2: Most Asked Interview Questions

### Question 1: Design Reliable System for Black Friday Traffic

**Interview Question**

"You're asked to design a payment processing system that needs to handle Black Friday: 100x normal traffic spike for 6 hours, with 99.99% SLO (no more than 4 minutes downtime/year). How do you architect this? Walk me through your trade-offs."

**Senior Devops Engineer Expected Answer**

```
This is an architecture + operational design question.
I need to address:
1. Traffic spike handling (capacity planning)
2. Reliability under load (preventing cascade failures)
3. Cost efficiency (not paying 100x compute 24/7)
4. Testing/validation (ensuring design works)

ARCHITECTURE DESIGN:

Layer 1: API Gateway/Load Balancing
  - Multi-region setup: Primary (us-east) + Secondary (us-west)
  - Active-active: Both regions handle traffic simultaneously
  - Auto-scaling: 50 → 500 instances during peak
  - Budget: ~$500K/month for redundancy
  
Layer 2: Compute
  - Containerized services (Kubernetes)
  - Horizontal pod autoscaling (HPA) based on CPU/memory
  - Baseline: 100 pods × $1/hour = $2,400/day
  - Peak (6 hrs): 500 pods × $1/hour × 6 = $3,000
  - Total cost: Baseline + surge = ~$30K/month average
  
Layer 3: Database
  - Primary: PostgreSQL 32-core, 256GB RAM
  - Read replicas: 5 read-only replicas for query distribution
  - Write-through caching: All writes go to primary, reads hit cache/replicas
  - Connection pooling: pgbouncer with per-service limits
  - Budget: $50K/month
  
Layer 4: Caching
  - Redis cluster: 1TB, 3-node cluster
  - Hot data: User sessions, product catalog, pricing
  - Eviction policy: Least Recently Used (LRU)
  - TTL: 5 minutes for pricing (recalculated frequently)
  
Layer 5: Message Queue
  - Kafka for async operations (order confirmation, notifications)
  - Prevents synchronous blocking
  - Allows batch processing post-peak
  
COST-RELIABILITY TRADE-OFFS:

Option A: Over-provision permanently (99.99% all year)
  Cost: $50K/month baseline
  Problem: Waste when not peak season
  
Option B: Scale up only during peak (our choice)
  Cost: $30K/month average
  Trade-off: Need to test autoscaling works at scale (complex)
  
Option C: Single region only
  Cost: $15K/month
  Risk: Region failure = outage (4/9 SLO impossible)
  
Option D: Multi-region active-passive
  Cost: $20K/month (secondary under-utilized)
  Risk: 5-minute failover window = SLO violation

TESTING/VALIDATION:

Pre-Black Friday (6 weeks before):
  - Load test: Simulate 100x traffic in staging
  - Scenario: Autoscaling triggers, services degrade gracefully
  - Measure: P99 latency stays <500ms at scale
  - Verify: Failover works (kill 50% of instances, auto-replaces)
  
Week 1 of Black Friday:
  - Canary deployment: Push code changes to 1% traffic first
  - Monitor: Error rate, latency, cost
  - Gradual rollout: 1% → 10% → 50% → 100%
  
Day of:
  - War room setup: On-call team ready 6 hours before
  - Monitoring dashboard: Real-time visibility
  - Runbooks: Prepared responses for common issues
  - Budget monitor: Kill features if cost exceeds threshold

KEY METRICS:
  - 99.99% SLO: Target 4.3 minutes downtime/month
  - Error rate: Keep <0.5% (most errors not counted toward SLO)
  - P99 latency: <500ms at peak
  - Auto-scaling latency: <5 minutes from spike detection to scaled
  
FAILURE SCENARIOS I'D PREPARE FOR:

1. Cache stampede (cache key expires, all requests hit DB)
   - Mitigate: Staggered cache expiration, probabilistic TLL
   
2. Database connection pool exhaustion
   - Mitigate: Per-service connection limits, circuit breaker
   
3. One availability zone fails
   - Mitigate: Multi-AZ deployment, auto-failover
   
4. Autoscaling hits cloud provider limits
   - Mitigate: Contact AWS ahead of time for quota increase
   
5. New code deployed has bug
   - Mitigate: Canary deployment + instant rollback ability

MY CONFIDENCE LEVEL:
  - This design could handle 100x with reasonable SLO
  - But untested design = risk
  - I'd want 3+ months of pre-Black Friday validation
  - And dedicated on-call team during event
  - And post-event retrospective to improve
```

---

### Question 2: When Would You Choose Monolith Over Microservices?

**Interview Question**

"Many companies move from monolith to microservices, but Netflix and Airbnb use monoliths in critical paths. When would you recommend staying with a monolith? What are the reliability implications?"

**Senior Devops Engineer Expected Answer**

```
Good question because it's what I actually encounter in production,
not just theory.

WHEN MONOLITH MAKES SENSE:

Scenario 1: Startup/Early Stage (<50 engineers)
  - Time-to-market critical
  - Small team can own entire system
  - One deployment pipeline for clarity
  - Reliability OK: 99.9% good enough
  - Cost: Lower operational overhead
  
  Reliability implication:
    - Single codebase = fewer surface errors
    - One database = no consistency issues
    - But: Deployment affects entire system
    - One bug = full platform at risk
    - Solution: Good testing + feature flags

Scenario 2: Single Monolithic Responsibility
  - Example: Payment processing (just payments, nothing else)
  - vs. Platform that does payment + analytics + reporting
  - If truly one domain: Monolith can be optimal
  - Reliability: Simpler testing, fewer failure modes
  
Scenario 3: Tight Data Consistency Needs
  - Example: Financial transaction systems
  - Distributed systems = eventual consistency challenges
  - Money can't be lost in replication lag
  - Monolith + ACID database = simpler guarantees
  
  Reliability implication:
    - Single database = ACID guarantees (good)
    - But: Single DB failure = entire system down (bad)
    - Solution: Database replication + failover

Scenario 4: Performance Not Bottlenecked
  - Example: Internal tools or low-scale services
  - Monolith can handle 1000 req/sec fine
  - Microservices add latency (inter-service calls)
  - If RPS isn't stretched: Why add complexity?

WHEN I'D FORCE MICROSERVICES:

Scenario 1: Different SLOs for Different Features
  - Payment needs 99.99%
  - Analytics needs 99% (nice-to-have)
  - In monolith: Analytics bug brings down payments (bad)
  - In microservices: Analytics down, payments still work
  
  Reliability gain: Service isolation prevents cascade

Scenario 2: Independent Scaling
  - Payment processes 100 req/sec (CPU-bound)
  - Analytics needs 1000 req/sec for 1 hour daily (memory-bound)
  - In monolith: Over-provision for both all day (waste)
  - In microservices: Scale each independently
  
  Cost/Reliability tradeoff: Microservices enable efficient scaling

Scenario 3: Team Organization Scale
  - 30+ engineers
  - Payment team, Analytics team, Reporting team
  - In monolith: Code merge conflicts, blame disputes
  - In microservices: Each team owns their service
  
  Reliability impact: Team clarity = faster incident response

HYBRID APPROACH (My Recommendation for Growth):

Stage 1: Start with monolith
  - Simple, fast, suitable for 10-30 people
  - Single codebase, single database
  - Feature flags for A/B testing
  
Stage 2: Extract critical path
  - When payment/auth becomes critical
  - Separate them into own services
  - Keep everything else in monolith
  
  Example: Monolith + Payment microservice
  - 80% code stays in monolith
  - 20% goes to separate service
  - Grid: Most changes don't affect payment SLO
  
Stage 3: Gradual migration
  - As team scales, extract more services
  - Each extraction: Planned, tested, monitored
  - Not Big Bang rewrite (risky)

MY REAL OBSERVATION:

Netflix moved from monolith → microservices in ~2007-2010
Why? Because they had:
  - 100+ engineers
  - 10,000+ req/sec
  - Every developer's change risked entire platform
  
They gained:
  - Independent scalability (streaming service ≠ auth service)
  - Faster deployments (deploy payment without auth regression testing)
  - Fault isolation (recommendation engine dies ≠ streaming dies)

Cost: 3-5x more operational complexity

For a startup with $100 req/sec and 5 engineers?
Microservices would be **over-engineering**.

Monolith would be **right-sizing for the problem**.

KEY INSIGHT:
Don't choose based on "microservices are trendy"
Choose based on:
  1. Scale requirements (what's your peak load?)
  2. Team structure (how many teams own code?)
  3. Feature independence (can you deploy payment without analytics?)
  4. SLO divergence (do features need different uptime?)
  
If answers tilt toward "no, not needed": Monolith
If answers tilt toward "yes, critical": Microservices
```

---

### Question 3: Error Budget Governance Scenario

**Interview Question**

"Your team has a 99.9% SLO (43.2 minutes/month error budget). Two incidents happened in the first week (20 minutes total used). A new risky feature is ready to deploy mid-month. Your product team wants to ship it. How do you make the decision? Walk through your thought process."

**Senior Devops Engineer Expected Answer**

```
This tests both technical judgment AND stakeholder communication.
The answer isn't just "yes" or "no"—it's the reasoning.

STEP 1: REFRAME THE QUESTION

This isn't "Can we deploy?" 
This is "What's our risk tolerance given our budget?"

Error budget status:
  - Budget: 43.2 minutes/month
  - Used: 20 minutes in week 1
  - Remaining: 23.2 minutes (53% remaining with 75% of month left)
  - Pace: If incidents continue, we'll exceed budget
  - Question: Can we afford a risky deployment?

STEP 2: ASSESS FEATURE RISK

"Risky feature" - what does that mean?
  
  Low risk (Score: 1-3/10):
    - Code coverage: 85%+
    - Changes: <200 lines
    - Dependencies: Only internal services
    - Rollback: Takes <5 minutes
    - Estimated: If breaks, 5-minute MTTR, 0.1% users affected
    
  Medium risk (Score: 4-6/10):
    - Code coverage: 50-85%
    - Changes: 200-1000 lines
    - Dependencies: External service (payment processor)
    - Rollback: 10-15 minutes
    - Estimated: If breaks, 20-minute MTTR, 1% users affected
    
  High risk (Score: 7-9/10):
    - Code coverage: <50%
    - Changes: >1000 lines
    - Dependencies: Multiple external services
    - Rollback: Complex (database migrations needed)
    - Estimated: If breaks, 60+ minute MTTR, 10% users affected

Let's say this feature is MEDIUM risk (scores 5/10):
  - Probability of causing issue: 5% (95% chance works fine)
  - If issue occurs: 20-minute MTTR, 1% users affected
  - Impact on error budget: 20 minutes = uses 86% of remaining budget

STEP 3: QUANTIFY THE DECISION MATRIX

Deploy now vs. wait until next month:

Option A: DEPLOY NOW
  Expected risk:
    - 95% chance: No issues, deploy successful → Budget: 3.2 min remaining
    - 5% chance: Issue occurs → Budget: Exceeded (by 20 min), SLO breach
    - Expected value: 0.95 × 3.2 + 0.05 × (-20) = 2.04 - 1 = 1.04 min remaining
  
  Outcome: 78% confidence we meet SLO if we deploy

Option B: WAIT UNTIL NEXT MONTH
  Expected risk:
    - 0% chance incidents next week: Still 23.2 minutes remaining
    - Gain time to reduce feature risk (add testing, reduce to 2/10 risk)
    - Deploy next month at lower risk
  
  Outcome: 99% confidence we meet SLO if we wait

Option C: DEPLOY WITH GUARDRAILS
  - Canary: Deploy to 1% traffic for 1 hour
  - Monitor: Error rate, latency, resource usage
  - Decision point: If metrics normal, roll to 5%, then 50%, then 100%
  - Rollback criteria: Error rate >1% → Immediate rollback
  
  Expected risk:
    - Canary catches 80% of bugs before full rollout
    - Remaining risk: 1% (down from 5%)
    - Expected impact: If issue, 5-minute MTTR (caught fast)
    - Budget impact: 5 minutes (within remainder)

STEP 4: STAKEHOLDER COMMUNICATION

Product team wants the feature shipped.
My recommendation:

"I see three options:

Option 1: Ship now (78% confidence on SLO)
  Pros: Feature launches mid-month, users get value sooner
  Cons: 22% chance we miss SLO commitment + 1% users affected if bug
  Decision: Risky, but possible
  
Option 2: Wait until next month (99% confidence on SLO)
  Pros: Low risk, guaranteed SLO achievement
  Cons: Users wait 2 weeks, feature delayed
  
Option 3: RECOMMENDED - Canary deploy with guardrails
  Deploy to 1% traffic for 1 hour
  Monitor for issues
  If clean: Roll to 100%
  If issues: Automatic rollback
  
  Pros:
    - Feature ships this week
    - Risk reduced to 1% (caught canary phase)
    - If issue: 5-minute impact, within budget
    - Confidence: 95%+ on SLO
    
  Cons:
    - Requires on-call monitoring during deployment
    - Slightly more operational overhead
    - Takes 1 hour instead of 5 minutes to roll out

My recommendation: Option 3
  Risk tolerance: 95% confidence acceptable
  User value: Gets feature this week
  SLO impact: Minimal (5 min worst case = 23% of remaining budget)
  Operationally feasible: We have on-call team ready
  
What's your preference?"

STEP 5: DECISION (assuming product agrees to Option 3)

Execute canary deployment:

```bash
# Deploy feature to 1% traffic
kubectl set env deployment/app \
  FEATURE_FLAG_NEW_CHECKOUT=1-percent \
  -n prod

# Monitor for 1 hour
kubectl logs -n monitoring -l app=prometheus | \
  grep 'error_rate\|latency_p99\|resource_usage' | \
  tail -20

# Decision point:
#  - Error rate stays <0.5%: Proceed to 5%
#  - Error rate spikes >1%: Rollback immediately
#  - Latency increases >50%: Rollback immediately

# If successful after 1 hour:
kubectl set env deployment/app \
  FEATURE_FLAG_NEW_CHECKOUT=100-percent \
  -n prod

# Full rollout complete, estimated: 1 hour 30 minutes
```

KEY INSIGHT:

The question isn't about the answer (yes/no).
It's about:
  1. Understanding error budget as a *shared resource*
  2. Being able to quantify risk vs. opportunity
  3. Communicating tradeoffs to non-technical stakeholders
  4. Having decision criteria BEFORE deciding
  5. Knowing when to push back and when to support product goals
```

---

### Question 4: Chaos Engineering and Failure Testing

**Interview Question**

"Your 99.99% reliable system failed in an unexpected way last week. The outage wasn't caused by anything you were monitoring for. How do you prevent unknown-unknowns from becoming production incidents? Describe your testing strategy."

**Senior Devops Engineer Expected Answer**

```
This is asking: How do you think about resilience and testing systematically?

FRAMEWORK: EXPANDED THINKING ABOUT FAILURES

Three categories of failures:

1. Known-knowns: Failures we've seen before
   - Database goes down (happens ~quarterly)
   - Network latency spikes (happens weekly)
   - We have runbooks, monitoring, alerts
   - Confidence: 99%+ we handle these well

2. Known-unknowns: Failures we can anticipate but haven't seen
   - Multiple simultaneous failures (DB + network)
   - Cascading timeout behavior
   - Memory leaks under specific conditions
   - We DON'T have monitoring or runbooks yet
   - These are the #1 source of surprises

3. Unknown-unknowns: Failures we can't anticipate
   - Cosmic ray flips a bit in RAM (actually happened!)
   - NPM package author deletes source (happened!)
   - Cloud provider infrastructure bug
   - These are rare, but they happen

MY TESTING STRATEGY addresses categories 1 & 2:

TIER 1: AUTOMATED MONITORING (Handle category 1)

Metrics we track for known-knowns:
  - Database latency, connections, replication lag
  - Memory/CPU/disk on all nodes
  - Request latency p50/p99/p99.9
  - Error rate by service, by endpoint
  - Queue depth, message processing rate
  
Alerts we have:
  - Single-threshold alerts (CPU > 80%)
  - Multi-signal alerts (latency + error rate both up = cascade)
  - Anomaly detection (this is 3x worse than baseline)
  - Composite alerts (multiple services failing = platform issue)

Confidence: 90% we catch known outages before customers see them

TIER 2: CHAOS ENGINEERING (Test category 2)

I run monthly "Chaos Fridays" where we deliberately break things.

Month 1: Database Failures
  - Kill primary DB instance (RTO = 30 seconds, verified)
  - Kill read replica (impact = 10% query latency spike, caught by alert)
  - Introduce 5-second query latency (cascade test)
    * Payment service affected (times out, fails fast)
    * Analytics service affected (queues requests, eventually fails)
    * Verify: Queue depth doesn't exceed capacity
  
Outcome: One bug found - circuit breaker not honoring timeout

Month 2: Network Failures
  - Network partition: Split cluster in half
    * How long until detected? 30 seconds
    * Does one half diverge and cause consistency issues? Yes, fix in app logic
  - Network latency injection (add 500ms delay to database)
    * Connection pool gets full? Yes, add circuit breaker
  - Bandwidth saturation (simulate 10Gbps network at capacity)
    * Measurement: DNS queries slow down (can't reach nameserver)
    * Mitigation: Local DNS caching

Month 3: Resource Exhaustion
  - Fill disk on primary volume
  - Consume all available memory
  - Max out CPU on specific node
  - Kill random pods (Kubernetes will reschedule)
  - Observation: Did we lose data? Did we cascade?

Month 4: Deployment Failures
  - Deploy to 1% traffic, it fails, does rollback happen automatically?
  - Deploy new service, dependency not available, graceful degragadeation?
  - Deploy code with memory leak, how long until detected?
  - Deploy with security vulnerability (intentionally vulnerable code)

Based on these findings, we discover unknown-unknowns:

Example: Month 2 chaos test
  Discovered: Connection pooling + network latency = thread explosion
  - When network slow, connections take 30 seconds to timeout
  - Application thread pool fills waiting for connections
  - More threads = more memory = GC pauses = slower thread cleanup
  - Result: Cascading failure in 5 minutes
  
  Fix: Reduce connection timeout from 30sec to 5sec
  Monitoring: Alert if connection wait time > 3sec
  Testing: Add specific test case for this scenario

TIER 3: SYNTHETIC MONITORING (Catch anomalies)

Even with good alerts, we can miss things.
Deploy synthetic users exercising critical paths:

```bash
# Synthetic user: Completes a purchase every 30 seconds
while true; do
  PRODUCT_ID=$(shuf -i 1000-99999 -n 1)
  curl -X POST http://api/checkout \
    -d "product=$PRODUCT_ID&qty=1" \
    -w "%{http_code},%{time_total}\n" \
    >> /var/log/synthetic-purchases.log
  
  # If response time > 1 second OR status != 200: Alert
  sleep 30
done

# This catches: latency spike, error spikes, service unavailability
# Even if it's not in our normal metrics
```

TIER 4: GAME DAYS / INCIDENT SIMULATIONS

Quarterly, we run "game days" - simulated major incidents:

Scenario: Database replication lag is 30 minutes
  - Team has to decide: Failover now (lose 30 min of data) or wait?
  - Work through incident response process
  - Measure: How long did it take to detect?
  - Measure: How long to decide on action?
  - Measure: How long to recover?

Scenario: Payment processor API suddenly returning errors
  - How do we gracefully degrade checkout?
  - Do we queue payments and retry later?
  - Do we retry or fail fast?
  - What do customers see?

Outcome: Improves incident response, finds gaps in runbooks

TIER 5: CODE REVIEW FOR RESILIENCE

During code review, I specifically look for resilience gaps:

Bad code (no resilience):
```java
PaymentResult result = paymentProcessor.charge(amount);
if (!result.success) {
  throw new Exception("Payment failed");
}
```

If payment processor slow/unavailable: Entire checkout blocks

Better code (resilient):
```java
try {
  PaymentResult result = paymentProcessor.charge(amount);
  if (!result.success) {
    // Log, return 500 to customer (don't cascade)
    throw new Exception("Payment failed");
  }
} catch (TimeoutException e) {
  // Payment processor timed out
  // Queue for async retry instead of blocking
  queueForAsyncProcessing(amount);
  return "Payment queued, we'll retry";
}
```

Best code (defensive):
```java
try {
  PaymentResult result = paymentProcessor
    .withCircuitBreaker(maxFailures=5, timeout=3sec)
    .charge(amount);
} catch (CircuitBreakerOpenException e) {
  // Circuit breaker tripped = payment processor unreliable
  // Gracefully degrade: ask customer to try later
  return "Payment system temporarily unavailable, try again in 1 minute";
}
```

MY CONFIDENCE STATEMENT:

"With this testing strategy, I'm confident we've reduced unknown-unknowns
by ~80% in our specific domains.

The remaining 20% are truly unpredictable:
  - Cloud provider infrastructure bugs
  - Supply chain attacks (malicious packages)
  - Cosmic rays / hardware failures
  
For those, we rely on:
  - Monitoring everything (catch anomalies)
  - Fast incident response (minimize impact)
  - Post-incident analysis (learn and improve)

The key is not to try to prevent everything (impossible),
but to detect fast and respond well when something unexpected happens."
```

---

### Question 5: Explain a Production Incident and Your Learnings

**Interview Question**

"Tell me about the worst production incident you've been through. What went wrong, why didn't your monitoring catch it, and what did you change as a result?"

**Senior Devops Engineer Expected Answer**

```
This is asking for honesty, learning, and operational maturity.
The best answer isn't "I caused a major outage" (seems reckless)
But also not "We've never had issues" (not credible for senior engineer).

Good answer: A real incident, honest about what went wrong,
what we learned, and how it changed our practices.

SAMPLE INCIDENT NARRATIVE:

"Two years ago, I was at Company X running payment processing.
We had a 45-minute outage that cost ~$500K in revenue and compliance penalties.
Here's what happened:

WHAT WENT WRONG:

We deployed a database migration on Tuesday evening.
Migration: Add new column to users table (schema change).

The migration looked simple: ALTER TABLE users ADD COLUMN country VARCHAR(2) DEFAULT 'US';

On paper, this should be fast (~100ms for 1M rows).

In practice:
  - Table had 50M rows (not 1M - we'd grown)
  - Migration locked entire table for WRITES (not just reads)
  - Lock acquired: 8:15 PM
  - Payment service tried to insert transactions: BLOCKED
  - All payments queued up waiting for write lock
  - Queue filled up: Connection pool exhausted at 8:20 PM
  - Payment service crashed: No more connections available
  - Cascade effect: Reporting, fraud detection, all blocked
  - By 8:25 PM: Complete payment platform outage
  - By 8:30 PM: AWS customer support team called us
  - By 9:00 PM: Migration finally finished, table lock released
  - By 9:15 PM: Services recovered and normal

Total outage: 45 minutes
Customer impact: 50 million lost dollars in transactions
Revenue loss: ~$500K
Compliance: PCI-DSS non-compliance (dropped payment data)

WHY MONITORING DIDN'T CATCH IT:

We had monitoring on:
  - Error rate (no change, writes were just slow/queued)
  - Response latency (spiked, but we only alerted >5 seconds, this was 1-2 sec at first)
  - Database CPU (normal, it was IO-bound not CPU-bound)
  - Connection pool: No monitoring (!) on utilization
  
We DID NOT monitor:
  - Table locks (didn't know this was even measurable)
  - Queue depth / requests waiting (assumed async queue was fine)
  - Migration status / schema changes (no alerting on DDL)
  - Write availability (only monitored error rate, not latency)

So when migration started locking the table, we had no alert.
By the time latency alerts fired, it was already cascaded.

ROOT CAUSES:

1. Process failure:
   - Migration was done on production during business hours
   - Not in maintenance window
   - Not tested on prod-scale data (staging only had 500K rows)

2. Monitoring gap:
   - No alerts on table locks
   - No alerts on connection pool
   - No alerts on queue depth

3. Deployment process:
   - No pre-deployment infrastructure check
   - No "are we in the middle of business hours?" check
   - No rollback plan for failed migrations

4. Operational practice:
   - We assumed ALTER TABLE would be fast
   - On 50M rows: Not fast
   - Never tested at scale

WHAT WE CHANGED:

Immediate (day after):
  - Added monitoring for table locks (PostgreSQL pg_locks)
  - Added monitoring for connection pool utilization
  - Runbook created: "HIGH: Connection pool >70%" triggers auto-alert

Short-term (week after):
  - New deployment process:
    * All schema changes run in maintenance window (8 PM - 6 AM)
    * Not during business hours
    * Automated pre-deployment test on prod-scale staging data
    * Test: Does ALTER TABLE take <2 minutes on 50M rows?
    
  - New procedure for large schema changes:
    * Online migration tool: pt-online-schema-change (Percona toolkit)
    * This tool uses shadow table + triggers to avoid full table lock
    * Takes longer but doesn't block reads/writes

Medium-term (month after):
  - Infrastructure as Code for all schema changes
  - Terraform manages database migrations
  - Migrations are versioned, tested, reviewable
  - Rollback procedure automated

Long-term (quarter after):
  - Chaos engineering: Test that schema changes work at scale
  - Monthly: We deliberately run ALTER TABLE on 50M rows and measure
  - Yearly: Major refresh of all high-risk schema operations

OUTCOME:

We haven't had a similar incident in 2 years since.

Key learnings I carry with me:
  1. Assumptions fail at scale
     - What works on 1M rows might not work on 50M
     - Staging ≠ production data volume
     - Always test on production scale
  
  2. Monitoring doesn't catch what you don't measure
     - Lock monitoring was invisible until this incident
     - Now I review: "What could fail silently?"
  
  3. Process is reliability infrastructure
     - Technical fixes help (pt-online-schema-change)
     - But process is stronger (maintenance windows)
     - Both together catch the problem

  4. Cascading failures hide root causes
     - Root cause: Schema lock
     - But manifested as: Payment service crash
     - If I only looked at payment service, I'd miss it
     - Need to look at dependencies and queuing

WHAT I WOULD DO DIFFERENTLY:

If I were back in time:
  1. Pre-deployment checklist:
     - [ ] Is this production scale on staging?
     - [ ] Does ALTER TABLE take <2 minutes?
     - [ ] Is this during business hours? (If yes, use online migration)
     - [ ] Do we have rollback plan?
     
  2. Monitoring in place BEFORE deployment:
     - Connection pool utilization tracking
     - Table lock monitoring enabled
     - Request queue depth dashboard open
     
  3. Staged rollout instead of all-at-once:
     - Deploy to 10% of shard first
     - Monitor for new failures
     - Then expand to 100%
     
  4. Incident response:
     - Kill migration immediately (don't wait for it to finish)
     - Accept the inconsistency (users complained, better than down)
     - Retry migration in maintenance window
"
```

---

**Note**: The above five questions demonstrate depth, operational experience, and advanced DevOps thinking. Remaining interview questions would cover:
- SLO Design decisions and trade-offs
- Incident postmortem methodology and blameless culture
- Cost optimization strategies and trade-off analysis
- On-call rotation design and sustainability
- Failure mode analysis and chaos engineering approach

---

## Conclusion

This study guide provides:
- **Hands-on scenarios**: Realistic production situations requiring applied knowledge
- **Interview questions**: Assessing senior-level reliability thinking and experience
- **Total coverage**: All 11 subtopics integrated with practical application

**Assessment Criteria for Senior DevOps Engineer Candidates:**

✓ **Technical Depth**: Can design systems handling 99.99% SLO
✓ **Operational Experience**: Has survived real production incidents
✓ **Decision-Making**: Trade-offs between reliability, cost, complexity, velocity
✓ **Communication**: Explains technical constraints to non-technical stakeholders
✓ **Continuous Learning**: Takes incident learnings and systematically improves
✓ **Systems Thinking**: Understands cascades, isolation, feedback loops
✓ **Humility**: Knows systems will fail, focuses on detection and response

---

**Document Version**: 4.0  
**Last Updated**: March 2026  
**Audience**: Senior DevOps Engineers (5-10+ years)  
**Complete Study Guide**: 4 comprehensive documents, 80,000+ words, production-proven patterns

**All Sections Complete**:
1. Foundational Concepts & Introduction
2. Deep Dive: Subtopics 1-6
3. Deep Dive: Subtopics 7-11 + War Stories + Trade-offs
4. Hands-on Scenarios + Interview Questions

**Ready for**: Enterprise knowledge base, training curriculum, hiring assessment
