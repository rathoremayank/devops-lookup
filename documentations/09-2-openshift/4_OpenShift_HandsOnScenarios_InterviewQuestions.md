# OpenShift: Hands-on Scenarios & Interview Questions - Final Study Guide

**Level:** Senior DevOps Engineers (5-10+ years experience)  
**Continuation of:** Study Guides 1, 2, & 3  
**Focus:** Practical scenarios and senior-level interview preparation

---

# Part 4: HANDS-ON SCENARIOS & INTERVIEW PREPARATION

---

## 1. Hands-on Scenarios

### Scenario 1: Multi-Region Failover During Cluster Outage

#### Problem Statement

Your organization runs a trading platform on OpenShift with SLA of 99.99% uptime (52 minutes/year). At 14:30 UTC on a Friday, the **primary cluster in us-east-1 becomes unavailable** due to a datacenter power outage. Your monitoring detects API latency spike to 30+ seconds within 60 seconds.

**Constraints:**
- Application teams must remain unaware of the failover (transparent DNS-based switch)
- RTO (Recovery Time Objective): < 15 minutes
- RPO (Recovery Point Objective): < 5 minutes
- No data loss acceptable
- Customer sessions must resume without disruption

#### Architecture Context

```
┌─────────────────────────────────────────────────────────┐
│         Trading Platform Multi-Region Setup            │
├─────────────────────┬──────────────────────────────────┤
│ Primary (us-east-1) │ Standby (us-west-2)             │
├─────────────────────┼──────────────────────────────────┤
│ OpenShift Cluster   │ OpenShift Cluster               │
│ • 3 Masters        │ • 3 Masters                     │
│ • 50 Compute Nodes │ • 50 Compute Nodes (paused)    │
│ • Active workloads  │ • Standby workloads (replicas=0)│
├─────────────────────┼──────────────────────────────────┤
│ RDS PostgreSQL      │ RDS PostgreSQL (read replica)  │
│ • Master DB         │ • Standby DB                    │
│ • Replication lag   │ • Lag: < 1 second              │
├─────────────────────┼──────────────────────────────────┤
│ Backup: S3 (hourly) │ Backup: S3 (replicated cross-region)
└─────────────────────┴──────────────────────────────────┘

Global Load Balancer (Route 53 health checks):
├─ Primary endpoint: api.primary.example.com
│  └─ Health check: API latency < 500ms
├─ Standby endpoint: api.standby.example.com
│  └─ Health check: API latency < 500ms
└─ CNAME: api.example.com → Primary (failover to Standby if Primary unhealthy)
```

#### Step-by-Step Implementation

**Phase 1: Detection (Minute 0-2)**

```bash
#!/bin/bash
# Monitoring system detects primary cluster unavailable

# 1. Alert triggered: Primary API endpoint timeout
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
echo "$TIMESTAMP: ALERT - Primary API latency 30000ms (threshold: 500ms)"

# 2. Health check failures
echo "Primary health check: 5/5 FAILED"
echo "Standby health check: 5/5 PASSED"

# 3. Incident page created automatically
curl -X POST https://api.pagerduty.com/incidents \
  -H "Authorization: Token token=$PD_TOKEN" \
  -d '{
    "incident": {
      "type": "incident",
      "title": "Primary Cluster Unavailable - Initiate Failover",
      "service": {"id": "trading-platform"},
      "urgency": "high"
    }
  }'

# 4. On-call engineer notified
# PagerDuty → SMS/phone call to on-call
```

**Phase 2: Failover Decision (Minute 2-5)**

```bash
#!/bin/bash
# Human decision or automated (based on policy)

# Check: Is primary truly down or network blip?
PRIMARY_HEALTH_CHECK=$(\
  curl -s -m 5 \
  https://api.primary.example.com/health \
  || echo "TIMEOUT"
)

if [[ "$PRIMARY_HEALTH_CHECK" == "TIMEOUT" ]]; then
  echo "Minute 3: Primary confirmed unreachable for 120 seconds"
  echo "Decision: PROCEED WITH FAILOVER"
  
  # Store decision with timestamp
  timestamp=$(date -u +%s)
  echo "Failover decision timestamp: $timestamp" >> /var/log/failover.log
fi
```

**Phase 3: Database Promotion (Minute 5-8)**

```bash
#!/bin/bash
# Promote read replica to master

# 1. Stop replication (standby DB read replica)
aws rds stop-db-instance-automated-backups \
  --db-instance-identifier database-standby \
  --region us-west-2

# 2. Promote read replica to standalone master
aws rds promote-read-replica \
  --db-instance-identifier database-standby \
  --backup-retention-period 30 \
  --region us-west-2

# Expected time: 2-3 minutes
echo "Minute 5: Promotion initiated"
echo "Minute 8: Database promoted, ready for connections"

# 3. Verify promotion
aws rds describe-db-instances \
  --db-instance-identifier database-standby \
  --query 'DBInstances[0].[DBInstanceIdentifier, DBInstanceStatus, ReadReplicaSourceDBInstanceIdentifier]' \
  --region us-west-2
# Expected output: database-standby, available, null (no longer replica)
```

**Phase 4: Application Failover (Minute 8-12)**

```bash
#!/bin/bash
# Scale up standby cluster applications

# 1. Update database connection strings
# Scale all deployments from replicas=0 to original count
NAMESPACE="prod"

# Get all deployments
DEPLOYMENTS=$(oc get deployments -n $NAMESPACE -o name)

for DEPLOYMENT in $DEPLOYMENTS; do
  CURRENT_REPLICAS=$(oc get $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')
  
  # Scale if currently 0
  if [[ "$CURRENT_REPLICAS" == "0" || "$CURRENT_REPLICAS" == "null" ]]; then
    DESIRED_REPLICAS=$(oc get $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' | tr -d 'null')
    
    # Scale to 3 replicas (standard for production)
    oc scale deployment $(basename $DEPLOYMENT) \
      --replicas=3 \
      -n $NAMESPACE
    
    echo "Minute 8-11: Scaling $(basename $DEPLOYMENT) to 3 replicas"
  fi
done

# 2. Wait for pods to be ready
for DEPLOYMENT in $DEPLOYMENTS; do
  oc rollout status deployment/$(basename $DEPLOYMENT) -n $NAMESPACE --timeout=3m
done
echo "Minute 11: All applications ready"

# 3. Verify connectivity to new database
oc exec -n $NAMESPACE deployment/api-service -- \
  psql -h database-standby.rds.amazonaws.com \
    -U admin -d trading \
    -c "SELECT COUNT(*) FROM transactions;"
# Expected: recent transaction count

echo "Minute 12: Application connectivity verified"
```

**Phase 5: DNS Cutover (Minute 12-15)**

```bash
#!/bin/bash
# Update Route 53 to point to standby

# Check standby cluster health
STANDBY_HEALTH=$(curl -s https://api.standby.example.com/health)

if [[ "$STANDBY_HEALTH" == "OK" ]]; then
  # Get standby LoadBalancer IP
  STANDBY_LB_IP=$(aws elb describe-load-balancers \
    --load-balancer-names api-standby-lb \
    --query 'LoadBalancerDescriptions[0].DNSName' \
    --region us-west-2 \
    --output text)
  
  # Update Route 53 CNAME
  aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890ABC \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"api.example.com\",
          \"Type\": \"CNAME\",
          \"TTL\": 60,
          \"ResourceRecords\": [{\"Value\": \"api.standby.example.com\"}],
          \"SetIdentifier\": \"standby-failover\",
          \"Failover\": \"SECONDARY\",
          \"Comment\": \"Failover from primary to standby - Minute 13\"
        }
      }]
    }"
  
  echo "Minute 13: DNS updated, traffic now routing to standby"
  
  # Wait for DNS propagation (60-second TTL)
  sleep 60
  
  # Verify DNS resolution
  for i in {1..5}; do
    RESOLVED_IP=$(dig +short api.example.com)
    if [[ "$RESOLVED_IP" == "$STANDBY_LB_IP" ]]; then
      echo "Minute 14: DNS propagated globally"
      break
    fi
    sleep 10
  done
fi

echo "Minute 15: FAILOVER COMPLETE"
```

**Phase 6: Validation & Communication (Minute 15+)**

```bash
#!/bin/bash
# Verify failover success

echo "=== FAILOVER VALIDATION ==="

# 1. Check trading volume (real transactions flowing)
TRANSACTION_COUNT=$(oc exec -n prod deployment/api-service -- \
  psql -h database-standby.rds.amazonaws.com \
    -U admin -d trading \
    -t -c "SELECT COUNT(*) FROM transactions WHERE created_at > NOW() - INTERVAL '1 minute';")
echo "✓ Recent transactions: $TRANSACTION_COUNT (last 60 seconds)"

# 2. Check latency (should be normal)
API_LATENCY=$(curl -w '%{time_total}' -o /dev/null -s api.example.com/health)
echo "✓ API latency: ${API_LATENCY}s (target < 100ms)"

# 3. Check error rate
ERROR_RATE=$(oc exec -n prod deployment/api-service -- \
  curl -s localhost:9090/api/v1/query \
    --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[5m])' \
    | jq '.data.result[0].value[1]')
echo "✓ Error rate: $ERROR_RATE (target < 0.1%)"

# 4. Customer notification
echo ""
echo "Sending status update to customers:"
cat <<EOF
Subject: Status Update - Brief Service Interruption

Incident: Primary datacenter power outage in us-east-1
Duration: 13 minutes (14:30 - 14:43 UTC)
Impact: Automatic failover to us-west-2, no data loss
Resolution: All systems operational, normal service resumed
RTO: 13 minutes (target: 15 minutes) ✓
RPO: 2 minutes (target: 5 minutes) ✓
EOF

# 5. Change incident status
curl -X PUT https://api.pagerduty.com/incidents/incident-id \
  -H "Authorization: Token token=$PD_TOKEN" \
  -d '{
    "incidents": [{
      "id": "incident-id",
      "status": "resolved"
    }]
  }'

echo "Incident resolved and communicated"
```

**Post-Incident Actions:**

```bash
#!/bin/bash
# Recovery of primary cluster

# 1. Wait 30 minutes for primary to stabilize
echo "T+15min: Monitor primary cluster recovery"

# Check power restoration
PRIMARY_STATUS=$(\
  curl -s -m 5 \
  https://api.primary.example.com/health \
  -w "\n%{http_code}" || echo "999"
)

if [[ "$PRIMARY_STATUS" == "200" ]]; then
  echo "T+45min: Primary cluster recovered"
  
  # 2. Resync databases (primary becomes read-only initially)
  # AWS DMS (Database Migration Service) can sync without downtime
  
  # 3. Create new read replica for standby
  aws rds create-db-instance-read-replica \
    --db-instance-identifier database-standby \
    --source-db-instance-identifier database-primary \
    --region us-west-2
  
  echo "T+1hour: Read replica recreated for standby"
  
  # 4. Switch DNS back to primary gradually
  # Use weighted routing: 90% primary, 10% standby
  # Monitor for issues, increase primary weight over 1 hour
  
  # 5. Post-incident review
  # Document timeline, identify improvements, update runbooks
fi
```

#### Best Practices Applied

✅ **Automatic monitoring** detecting failures within 60 seconds  
✅ **Database replication** with < 1 second lag (RPO met)  
✅ **Application auto-scaling** eliminating manual deployment  
✅ **DNS-based failover** transparent to clients  
✅ **Cross-region redundancy** protecting against datacenter failure  
✅ **Clear communication** to customers during incident  
✅ **Post-incident review** preventing repeat failures  

---

### Scenario 2: Performance Degradation Under Load - Root Cause Analysis

#### Problem Statement

Your organization experiences **sudden API latency increase from 50ms to 2000ms** during a periodic data export job that runs every Friday at 11:00 AM. The export job reads 10 million records from the database and generates CSV files.

**Timeline:**
- 11:00 AM: Export job starts
- 11:02 AM: API latency increases to 500ms
- 11:05 AM: Latency reaches 2000ms (users complaining)
- 11:30 AM: Export job completes, latency drops back to 50ms

Only Friday exports reproduce the issue. Daily incremental exports don't cause problems.

#### Architecture Context

```
┌──────────────────────────────────────────┐
│      Single OpenShift Cluster (prod)     │
├──────────────────────────────────────────┤
│ API Services (Tier: frontend)            │
│ • 3 replicas: payment processing         │
│ • 3 replicas: account management         │
│ └─ Requests database (shared)            │
│                                          │
│ Batch Jobs (Tier: batch)                 │
│ • Data export job (Fridays 11 AM)       │
│ └─ Heavy DB queries (10M records)        │
│                                          │
│ Shared Resources:                        │
│ • PostgreSQL RDS (single master)         │
│ • Network bandwidth: 5 Gbps shared       │
│ • Connections: 1000 max (default)       │
└──────────────────────────────────────────┘

Problem: No resource isolation between API and batch job
```

#### Troubleshooting Steps

**Step 1: Identify Resource Bottleneck (Minute 5)**

```bash
#!/bin/bash
# Execute during export job window

# Check pod resource usage
oc top pods -n prod -l tier=frontend --sort-by=memory
# Example output:
# NAME                    CPU(cores)   MEMORY(Mi)
# api-payment-abc123      0m           50Mi     (normal)
# api-payment-def456      0m           52Mi     (normal)
# api-account-ghi789      0m           48Mi     (normal)
# => CPU and memory normal

# Check node resources
oc top nodes
# Example output:
# NAME            CPU(cores)   %CPU   MEMORY(Mi)   %MEMORY
# worker-1        3000m        30%    25Gi         80%       (SPIKE!)
# worker-2        1500m        15%    12Gi         40%
# worker-3        1200m        12%    10Gi         35%
# => Memory spike on worker-1

# Check what's consuming memory on worker-1
oc describe node worker-1 | grep -A 30 "Allocated resources"

# Find pods on worker-1
oc get pods -n prod -o wide | grep worker-1
# NAME                    STATUS    NODE
# data-export-job-x7h2k   Running   worker-1  (export job)
# api-payment-abc123      Running   worker-1  (API pod)
# => Export job and API pod colocated!

echo "Finding: Export job and API pod on same node (noisy neighbor)"
```

**Step 2: Database Connection Analysis (Minute 10)**

```bash
#!/bin/bash
# Check database connection saturation

# Query database for active connections
oc exec -n prod deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d prod \
    -c "SELECT \
      datname, \
      count(*) as connection_count, \
      max(state_change) as last_change \
    FROM pg_stat_activity \
    GROUP BY datname \
    ORDER BY connection_count DESC;"

# Expected output (normal):
# datname | connection_count | last_change
# prod    | 45               | 2025-01-01 11:10:00

# During export (actual):
# datname | connection_count | last_change
# prod    | 950              | 2025-01-01 11:05:00
# => Nearly at 1000 connection limit!

# Check connection usage by application
oc exec -n prod deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d prod \
    -c "SELECT \
      application_name, \
      count(*) as conn_count, \
      state \
    FROM pg_stat_activity \
    GROUP BY application_name, state \
    ORDER BY conn_count DESC;"

# Output:
# application_name        | conn_count | state
# data-export-job         | 900        | active
# api-payment             | 30         | idle
# api-account             | 20         | idle
# => Export job consuming 900+ connections

echo "Finding: Export job saturating database connection pool"
```

**Step 3: Query Performance Analysis (Minute 15)**

```bash
#!/bin/bash
# Check slow queries during export

oc exec -n prod deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d prod \
    -c "SELECT \
      query, \
      calls, \
      mean_time, \
      max_time \
    FROM pg_stat_statements \
    WHERE query LIKE '%export%' \
    ORDER BY mean_time DESC \
    LIMIT 10;"

# Output showing export query performance:
# query                                    | calls | mean_time | max_time
# SELECT * FROM transactions WHERE ...    | 150   | 5000ms    | 15000ms
# => Export query: 150 executions, 5-15 seconds each

# Problem: Full table scans without indexes
# Export reads from multiple tables sequentially:
# 1. 2M transactions (scan: 5s, no index)
# 2. 3M accounts (scan: 8s, no index)
# 3. 5M events (scan: 15s, no index)

echo "Finding: Export queries performing full table scans, locking rows"
```

**Step 4: Lock Analysis (Minute 20)**

```bash
#!/bin/bash
# Check for locks held by export job

oc exec -n prod deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d prod \
    -c "SELECT \
      l.pid, \
      l.mode, \
      l.granted, \
      a.query \
    FROM pg_locks l \
    JOIN pg_stat_activity a ON l.pid = a.pid \
    WHERE NOT l.granted \
    ORDER BY l.pid;"

# Output showing blocked queries:
# pid  | mode          | granted | query
# 8901 | ExclusiveLock | false   | UPDATE accounts SET ...
# => API update query waiting for export job's lock

echo "Finding: Export job holding locks, blocking API updates"
```

#### Root Cause Identified

```
Timeline:
1. 11:00 AM: Export job starts, reads entire database
2. 11:02 AM: Job acquires SharedLock on large tables
3. 11:02 AM: API queries hit locks, queue up
4. 11:05 AM: Database connections exhaust (950/1000)
5. 11:05 AM: New API requests can't acquire connections
6. 11:05 AM: API latency spikes to 2000ms (queueing)
7. 11:30 AM: Export completes, locks released
8. 11:30 AM: API requests proceed, latency drops

Root Cause: No resource isolation between batch export and API service
```

#### Solution & Implementation

**Solution 1: Connection Pool Isolation (Quick Fix - 1 hour)**

```yaml
# Separate database connection strings by role
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-database-config
  namespace: prod
data:
  # Read-only connection pool for API (max 100 connections)
  db_connection_string: |
    user=api_readonly \
    password=<pwd> \
    host=database.rds.amazonaws.com \
    port=5432 \
    dbname=prod \
    sslmode=require \
    pool_size=100 \
    max_overflow=10

---
# Export job uses separate connection with higher limit
apiVersion: batch/v1
kind: CronJob
metadata:
  name: data-export-job
  namespace: prod
spec:
  schedule: "0 11 * * 5"  # Fridays 11 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: exporter
            image: data-exporter:v1
            env:
            - name: DB_CONNECTION_STRING
              value: |
                user=export_app \
                password=<pwd> \
                host=database.rds.amazonaws.com \
                port=5432 \
                dbname=prod \
                sslmode=require \
                pool_size=500 \
                max_overflow=50  # Higher limit for batch job
          restartPolicy: Never

# Result: API connections capped at 100, export job gets 500
# => API not starved of connections
```

**Solution 2: Database Index Optimization (Short-term - 2 hours)**

```sql
-- Add indexes for export query performance
-- This reduces lock duration from 30min to 3min

CREATE INDEX CONCURRENTLY idx_transactions_export 
  ON transactions(created_at, account_id, amount) 
  WHERE status IN ('completed', 'failed');

CREATE INDEX CONCURRENTLY idx_accounts_export 
  ON accounts(id, created_at, status);

CREATE INDEX CONCURRENTLY idx_events_export 
  ON events(entity_id, event_type, created_at);

-- Verify indexes used in export queries
EXPLAIN (ANALYZE, BUFFERS) 
  SELECT * FROM transactions 
  WHERE created_at > NOW() - INTERVAL '7 days' 
  AND status IN ('completed', 'failed') 
  ORDER BY created_at DESC;

-- Before index: Seq Scan on transactions (5000ms)
-- After index: Index Scan (200ms)
-- => Lock duration reduced 25x
```

**Solution 3: Workload Isolation (Medium-term - 4 hours)**

```yaml
# Separate namespaces for batch and interactive workloads
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod-api
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod-batch

---
# API deployments move to prod-api namespace
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: prod-api  # Changed
spec:
  replicas: 5
  template:
    spec:
      # Pod priorities: API pods get higher priority
      priorityClassName: interactive-priority
      nodeSelector:
        workload-type: api
      containers:
      - name: api
        image: api:v1
        resources:
          requests:
            cpu: 500m
            memory: 256Mi

---
# Batch job moves to prod-batch namespace
apiVersion: batch/v1
kind: CronJob
metadata:
  name: data-export
  namespace: prod-batch  # Changed
spec:
  schedule: "0 11 * * 5"
  jobTemplate:
    spec:
      template:
        spec:
          priorityClassName: batch-priority  # Lower priority
          nodeSelector:
            workload-type: batch  # Different nodes
          containers:
          - name: exporter
            image: data-exporter:v1
            resources:
              requests:
                cpu: 4
                memory: 8Gi  # Can use more resources

---
# Resource quotas prevent one from starving the other
apiVersion: v1
kind: ResourceQuota
metadata:
  name: api-resources
  namespace: prod-api
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    pods: "100"

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: batch-resources
  namespace: prod-batch
spec:
  hard:
    requests.cpu: "50"
    requests.memory: "100Gi"
    pods: "50"

---
# Network policies prevent cross-namespace interference
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-isolation
  namespace: prod-api
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
      namespaceSelector:
        matchLabels:
          name: prod-api
    # Only pods in prod-api can communicate within namespace
```

**Solution 4: Query Optimization (Long-term - Deploy next week)**

```sql
-- Rewrite export query to not lock entire table

-- Current (problematic): Full table scan with shared lock
-- SELECT * FROM transactions WHERE created_at > '2025-01-01'
-- Lock duration: 30 minutes (scanning 10M rows)

-- Optimized: Batch processing by date, use cursor
CREATE FUNCTION export_transactions_batched() RETURNS TABLE (...) AS $$
DECLARE
  v_batch_start DATE := CURRENT_DATE - INTERVAL '30 days';
  v_batch_end DATE;
BEGIN
  LOOP
    v_batch_end := v_batch_start + INTERVAL '1 day';
    
    -- Process 1 day at a time
    -- Query lock released after each batch
    FOR row IN SELECT * FROM transactions 
      WHERE created_at >= v_batch_start 
      AND created_at < v_batch_end 
      AND status IN ('completed', 'failed')
    LOOP
      RETURN NEXT row;
    END LOOP;
    
    -- Commit after each batch (releases locks)
    COMMIT;
    
    v_batch_start := v_batch_end;
    EXIT WHEN v_batch_start > CURRENT_DATE;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Result: Lock held for ~2 minutes per batch vs. 30 minutes total
-- => API latency impact reduced from 1950ms spike to <50ms
```

#### Results & Metrics

```
Before Fix:
├─ Export duration: 30 minutes
├─ API latency during export: 50ms → 2000ms (40x spike)
├─ User complaints: ~500 affected
└─ Revenue impact: ~$50K (2% transaction failure)

After Fix (indexed queries + connection pooling):
├─ Export duration: 3 minutes
├─ API latency during export: 50ms → 80ms (1.6x, acceptable)
├─ User complaints: 0
└─ Revenue impact: $0

Implemented within 4 hours, preventing future occurrences
```

---

### Scenario 3: Security Breach Containment & Investigation

#### Problem Statement

Your security team detects **unusual database access patterns** at 15:47 UTC:

- Service account `api-service` suddenly running 1000+ queries per second (normal: 50/sec)
- Queries reading from `users`, `payments`, `secrets` tables
- Traffic originating from pod `api-service-xyz123` with unusual source IP
- Database password change attempt detected in audit logs

**You have 60 minutes to contain the breach before customer notification deadline.**

#### Step 1: Immediate Containment (Minutes 0-5)

```bash
#!/bin/bash
# CONTAINMENT: Isolate compromised pod immediately

NAMESPACE="prod"
POD_NAME="api-service-xyz123"

# 1. Identify and isolate pod
echo "Minute 0: Isolating compromised pod"

# Get pod details for investigation
oc get pod -n $NAMESPACE $POD_NAME -o wide
# Output:
# NAME                 READY  STATUS   RESTARTS  IP          NODE
# api-service-xyz123   1/1    Running  0         10.128.1.45 worker-3

# 2. Deny all inbound/outbound traffic to pod
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-compromised-pod
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      pod: api-service-xyz123
  policyTypes:
  - Ingress
  - Egress
  # No rules = deny all
EOF

echo "Minute 1: Network policy applied, pod isolated"

# 3. Notify security team
echo "Minute 2: Alerts sent to security@company.com"

# 4. Stop the pod (don't delete - preserve logs)
oc set env deployment/api-service SECURITY_INCIDENT=true
# Triggers pod restart with security logging enabled

# 5. Scale down primary service (remove from load balancer)
REPLICAS=$(oc get deployment api-service -n $NAMESPACE -o jsonpath='{.spec.replicas}')
oc scale deployment api-service --replicas=$((REPLICAS - 1)) -n $NAMESPACE
echo "Minute 3: Removed suspicious pod from load balancer"

# 6. Rotate compromised database credentials
# Generate new password
NEW_DB_PASSWORD=$(openssl rand -base64 32)

# Update user password in database
oc exec -n $NAMESPACE deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d prod \
    -c "ALTER USER api_service WITH PASSWORD '$NEW_DB_PASSWORD';"

# Update secret in Kubernetes
oc patch secret api-db-credentials -n $NAMESPACE \
  -p "{\"data\":{\"password\":\"$(echo -n $NEW_DB_PASSWORD | base64)\"}}
"

echo "Minute 4: Database credentials rotated"
echo "Minute 5: All new API connections use new password"
```

#### Step 2: Investigation & Evidence Collection (Minutes 5-30)

```bash
#!/bin/bash
# INVESTIGATION: Preserve evidence and trace attack

NAMESPACE="prod"
POD_NAME="api-service-xyz123"
INVESTIGATION_DIR="/tmp/incident-investigation-$(date +%s)"

mkdir -p $INVESTIGATION_DIR
cd $INVESTIGATION_DIR

echo "Minute 5: Beginning forensic investigation"

# 1. Capture pod logs (before pod is deleted)
echo "Collecting pod logs..."
oc logs -n $NAMESPACE $POD_NAME --previous > $POD_NAME.logs 2>&1 || true
oc logs -n $NAMESPACE $POD_NAME > $POD_NAME.current.logs 2>&1 || true

# 2. Export pod configuration
echo "Exporting pod configuration..."
oc get pod -n $NAMESPACE $POD_NAME -o yaml > $POD_NAME.yaml
oc get pod -n $NAMESPACE $POD_NAME -o json > $POD_NAME.json

# 3. Check container image hash
POD_IMAGE=$(oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.containers[0].image}')
echo "Pod image: $POD_IMAGE"

# Scan image for known vulnerabilities
oc run image-scanner \
  --image=aquasec/trivy:latest \
  --rm -it -- image $POD_IMAGE > image-scan.txt

# 4. Check for container escapes (mount points, volumes)
oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.volumes}' > volumes.json
echo "Reviewing mounted volumes for host access..."

# 5. Database query audit logs
echo "Collecting database query logs..."
oc exec -n $NAMESPACE deployment/api-service -- \
  psql -h database.rds.amazonaws.com \
    -U admin -d postgres \
    -c "SELECT \
      query, \
      query_start, \
      state, \
      pid \
    FROM pg_stat_activity \
    WHERE query_start > NOW() - INTERVAL '30 minutes' \
    AND query ILIKE '%users%' \
    ORDER BY query_start DESC;" > db-suspicious-queries.txt

# 6. Network traffic analysis
echo "Collecting network flow data..."
oc debug node/worker-3 -- chroot /host tcpdump -i any \
  -w /tmp/traffic.pcap \
  'host 10.128.1.45' \
  -c 1000 \
  'tcp port 5432' 2>&1 | tee traffic-capture.log

# 7. Kubernetes audit logs (API calls made by pod)
echo "Extracting Kubernetes audit entries..."
oc logs -n openshift-apiserver deployment/apiserver | \
  grep "api-service-xyz123" > k8s-audit.log

# 8. Check for lateral movement (scanning other pods/services)
echo "Scanning for network reconnaissance..."
grep -r "nmap\|masscan\|zmap" $POD_NAME*.logs || echo "No port scanner detected"

# 9. Check container root filesystem for modifications
echo "Analyzing container file system..."
oc exec -n $NAMESPACE $POD_NAME -- find / -type f -newermt '1 hour ago' 2>/dev/null > modified-files.txt

# 10. Check process history
echo "Reviewing process execution..."
oc exec -n $NAMESPACE $POD_NAME -- \
  cat /proc/self/environ | tr '\0' '\n' > pod-environment.txt

# Archive all evidence
tar -czf incident-investigation-$(date +%Y%m%d-%H%M%S).tar.gz *.txt *.json *.yaml *.log 2>/dev/null

echo "Minute 30: Investigation complete, evidence archived"
echo "Evidence location: $INVESTIGATION_DIR"
```

#### Step 3: Endpoint Security Analysis (Minutes 30-40)

```bash
#!/bin/bash
# Determine compromise vector

INVESTIGATION_DIR="/tmp/incident-investigation-$1"
cd $INVESTIGATION_DIR

echo "Minute 30: Analyzing attack vector"

# 1. Check if secrets exposed in logs
grep -i "password\|secret\|token\|key" $POD_NAME*.logs | head -10

# 2. Check for code injection (unusual process execution)
echo "Unusual processes executed in pod:"
grep -E "exec|spawn|system\(" $POD_NAME*.logs | head -5

# 3. Check environment variables (hardcoded credentials?)
echo "Environment variables in pod:"
cat pod-environment.txt | grep -i "password\|secret"

# 4. Check for supply chain compromise (container image)
echo "Analyzing container image..."
# Image hash vs. registry
ACTUAL_HASH=$(sha256sum $POD_IMAGE | awk '{print $1}')
REGISTRY_HASH=$(curl -s https://registry.company.com/api/v1/images/$POD_IMAGE/manifests | jq '.config.digest')
if [[ "$ACTUAL_HASH" != "$REGISTRY_HASH" ]]; then
  echo "ALERT: Image hash mismatch! Possible tampering."
fi

# 5. Timeline reconstruction
echo ""
echo "Attack Timeline Reconstruction:"
echo "================================"
echo "T+0:00 - Pod scheduled on worker-3"
oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.metadata.creationTimestamp}'

echo "T+2:30 - Database queries spike begins"
head -1 db-suspicious-queries.txt

echo "T+5:15 - Detected by monitoring"
date

# 6. Likely infection vector
echo ""
echo "Hypothesis: Likely compromise vectors:"
echo "1. Vulnerable dependency in application code (most likely)"
echo "2. Supply chain attack in container image"
echo "3. Misconfigured RBAC allowing data access"
echo "4. Compromised node (less likely given other pods unaffected)"

echo "Minute 40: Analysis complete"
```

#### Step 4: Remediation & Recovery (Minutes 40-60)

```bash
#!/bin/bash
# REMEDIATION: Fix root cause and prevent recurrence

NAMESPACE="prod"

echo "Minute 40: Beginning remediation"

# 1. Redeploy API service with patched image
echo "Minute 41: Rolling patched image deployment"

# Build updated image with CVE fixes
podman build -t api:v1.2.3-patched .
podman push api:v1.2.3-patched registry.company.com/api:v1.2.3-patched

# Deploy patch
oc set image deployment/api-service \
  api=registry.company.com/api:v1.2.3-patched \
  -n $NAMESPACE

# Verify rollout
oc rollout status deployment/api-service -n $NAMESPACE --timeout=5m

# 2. Audit all API pods
echo "Minute 45: Auditing all API pods"

oc get pods -n $NAMESPACE -l app=api-service -o wide | while read pod; do
  POD_NAME=$(echo $pod | awk '{print $1}')
  
  # Verify running expected image
  ACTUAL_IMAGE=$(oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.containers[0].image}')
  if [[ "$ACTUAL_IMAGE" != "registry.company.com/api:v1.2.3-patched" ]]; then
    echo "ALERT: $POD_NAME running old image! Restarting..."
    oc delete pod -n $NAMESPACE $POD_NAME
  fi
done

# 3. Scan all pod images for vulnerabilities
echo "Minute 50: Scanning all container images"

kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | \
tr -s '[[:space:]]' '\n' | \
sort | uniq | \
while read image; do
  trivy image --severity HIGH,CRITICAL $image
done

# 4. Rotate all secrets
echo "Minute 52: Rotating all secrets"

oc get secret --all-namespaces | while read line; do
  NAMESPACE=$(echo $line | awk '{print $1}')
  SECRET=$(echo $line | awk '{print $2}')
  
  if [[ "$SECRET" == *"password"* ]] || [[ "$SECRET" == *"token"* ]]; then
    # Generate new secret
    NEW_VALUE=$(openssl rand -base64 32)
    oc patch secret $SECRET -n $NAMESPACE \
      --type json -p "[{\"op\":\"replace\",\"path\":\"/data/value\",\"value\":\"$(echo -n $NEW_VALUE | base64)\"}]"
  fi
done

# 5. Enable runtime security monitoring
echo "Minute 55: Enabling runtime security"

cat <<EOF | oc apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-security-labels
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet"]
  parameters:
    labels: ["security-scan: completed", "image-verified: true"]
EOF

# 6. Prepare customer notification
echo "Minute 58: Preparing incident notification"

cat > incident-notification.txt <<EOF
Subject: Security Incident Notification - Immediate Action Taken

Dear Customers,

We identified and contained a security incident in our production environment on $(date).

Incident Details:
- Compromised application pod attempting unauthorized database access
- Incident detected within 1 minute of unusual activity
- Pod immediately isolated and removed from service
- All credentials rotated, patched image deployed
- No customer payment data accessed (encrypted at-rest)
- No customer personal data exposed

Actions Taken:
- Container compromised pod forensically preserved
- Application patched and redeployed
- All secrets rotated
- Enhanced monitoring deployed
- Security audit scheduled

Impact Assessment:
- Duration: < 5 minutes
- Data Exposed: None verified
- Customers affected: Limited to internal status checks

Recommendations:
- Change any stored API tokens
- Monitor accounts for unauthorized activity

We are investigating root cause and will provide detailed analysis by EOD tomorrow.

Security Team
EOF

# 7. Update status page
curl -X POST https://status.company.com/api/incidents \
  -H "Authorization: Bearer $STATUS_PAGE_TOKEN" \
  -d '{
    "incident": {
      "title": "Security incident detected and contained",
      "status": "resolved",
      "body": "Pod with unusual database access isolated and patched. All systems operational."
    }
  }'

echo "Minute 60: INCIDENT CONTAINMENT AND REMEDIATION COMPLETE"
echo ""
echo "Timeline:"
echo "  T+0:00 - Breach detected"
echo "  T+1:00 - Pod isolated"
echo "  T+5:00 - Credentials rotated"
echo "  T+15:00 - Investigation complete"
echo "  T+45:00 - Patched image deployed"
echo "  T+60:00 - Incident resolved"
```

#### Post-Incident Review (Day 1)

```markdown
# Post-Incident Review: API Service Compromise

## Root Cause
- Vulnerable dependency: log4j Library v2.14.1 (CVE-2021-44228 - RCE)
- Attack Vector: JNDI injection through API request logs
- Initial Access: Attacker gained RCE, executed database queries

## Indicators of Compromise
- Database query rate spike (50 → 1000 QPS)
- Unusual queries reading sensitive tables
- Pod network signatures indicating reconnaissance
- Log entries showing code injection attempts

## Prevention (Implemented)
1. ✅ Automated image scanning (Trivy) in CI/CD pipeline
2. ✅ Dependency vulnerability scanning (Dependabot in GitHub)
3. ✅ Network policies: zero-trust default-deny
4. ✅ RBAC: Least privilege database accounts
5. ✅ Runtime security: suspicious process detection
6. ✅ Secrets rotation: automated every 30 days
7. ✅ Pod security: disable privilege escalation

## Detection Improvements
- Reduced MTTR: from 30 min to 1 min (monitoring dashboard)
- Automated isolation: network policies auto-applied on alert
- Evidence preservation: pod logs automatically archived

## Training
- Team security drills (quarterly)
- Code review process updates
- Log analysis training for incident response
```

---

## 2. Most Asked Interview Questions for Senior DevOps Engineers

### Question 1: Describe How You Would Design a Production OpenShift Cluster Supporting 100,000 Daily Transactions with 99.99% Uptime SLA

**Expected Senior-Level Answer:**

*"I would approach this systematically, thinking about each layer:

**Infrastructure Layer (Multi-AZ):**
- 3-5 master nodes across availability zones (quorum-based HA)
- 100-150 compute nodes with auto-scaling (scale from 100 to 150 on CPU > 75%)
- Separate infra nodes (3x) for monitoring/logging/routing (prevents noisy neighbors)
- Load balancer in front of API endpoints (distribute across AZs)

**Database Design (HA & Reliability):**
- Multi-AZ RDS master with synchronous replication (RPO = 0)
- Read replicas for analytics queries (don't impact trading queries)
- Automated daily backups + hourly snapshots
- Connection pooling (PgBouncer) to prevent saturation during traffic spikes

**Application Deployment:**
- Deployments with 3+ replicas minimum, PodDisruptionBudgets to protect during upgrades
- Blue-green deployments for zero-downtime releases
- Canary deployments with traffic shifting (catch errors on 1% before full rollout)
- Pod anti-affinity: spread across nodes to survive node failures

**Networking & Security:**
- OVN-Kubernetes SDN (modern, scalable, low latency)
- Service mesh for mTLS (pod-to-pod encryption, automatic)
- Zero-trust network policies: deny-all default, explicit allow-lists
- DDoS mitigation: rate limiting at ingress, WAF protection

**Observability (SLA enforcement):**
- Prometheus for metrics (request latency p99, error rate, throughput)
- SLOs aligned to SLA: 99.95% success rate (leaves 0.04% buffer)
- Distributed tracing (Jaeger) for transaction flows
- Centralized logging (EFK) for incident investigation

**Disaster Recovery:**
- Automated etcd backups (hourly backup, tested weekly)
- Cross-region cluster for failover (standby cluster in us-west-2)
- RTO < 15 minutes (DNS failover, database promotion)
- RPO < 5 minutes (database replication lag)

**Cost Optimization (Critical for this scale):**
- Spot instances for 60% of compute nodes (cost savings ~70%)
- Scheduled scaling: scale down during off-hours
- Reserved instances for base capacity
- Storage tiering: hot data (fast SSD), cold data (S3 archival)

**Why this design handles 100K transactions/day:**
- 100K tx/day ≈ 1.15 transactions/second average
- Peak load: 5-10x average = 10-20 tx/sec
- Each transaction touches database for ~100ms
- 20 tx/sec × 100ms = 2000 concurrent requests
- 3 API replicas × 500 QPS per pod = 1500 QPS capacity (comfortable buffer)
- Monitoring catches spikes, auto-scaling kicks in if overwhelmed

**The critical piece:** If I design for the average (1.15 tx/sec), I'd undersize during peaks. I design for the 99th percentile peak, not average.
"*

**Why This Answer Demonstrates Senior Experience:**
- Thinks about every layer (not just Kubernetes)
- Understands trade-offs (cost vs. reliability)
- Includes failure scenarios (failover, redundancy)
- Ties numbers to actual SLA requirements
- Shows operations mindset (monitoring > faith in code)

---

### Question 2: Walk Me Through Troubleshooting a "Pod Pending" Issue That Started 2 Hours Ago

**Expected Senior-Level Answer:**

*"Two hours is significant - this isn't a temporary scheduling delay. Here's my systematic approach:

**Step 1: Immediate checks (1 minute)**
```bash
oc describe pod <pod-name>  # Check events for failure reason
oc get node --no-headers    # Are nodes available/ready?
oc top nodes                # Any node full on CPU/memory?
```

**Step 2: Determine failure category**
- If events show 'Insufficient cpu': pod requesting more than available
- If events show 'Insufficient memory': same issue
- If events show 'PersistentVolumeClaim Pending': storage issue
- If no events: no node satisfies constraints (affinity/tolerations mismatch)

**Step 3: Verify pod specification**
```bash
oc get pod -o json | jq '.spec.containers[].resources.requests'
```
*(This is where I often find mistakes)*
- Requests too high? (requesting 999 CPU on 8-CPU node)
- Requests realistic but no nodes available? → Scale cluster
- Requests reasonable but nodeSelector/affinity too strict? → Fix constraints

**Step 4: Check storage (if PVC involved)**
```bash
oc get pvc <pvc-name>  # Is it Pending/Bound?
oc describe sc <storage-class>  # Provisioner healthy?
```

**Step 5: Network/Configuration issues**
- Can scheduler even see this pod? (network partition unlikely but check)
- Is the node cordoned? (`oc get nodes` shows CordonSchedulingDisabled)
- Pod topology spreading requirements impossible to meet?

**Two hours suggests...**
- This isn't transient (would have resolved)
- Likely: static misconfiguration, not infrastructure failure
- My first hypothesis: pod requests exceed any node capacity
- OR: storage provisioner stuck

**Follow-up action:**
- If pod requests realistic: scale cluster, pod should immediately schedule
- If pod requests high: reduce and reapply
- If storage issue: debug provisioner (check CSI controller logs)
- Never wait > 30 minutes for kubectl commands - investigate actively

**The senior move:** I don't just tell you the answer. I show the **diagnostic path** - this demonstrates I've debugged enough clusters to have a mental model of common failure modes.
"*

---

### Question 3: Your Cluster Upgraded Yesterday. Today, 20% of Pods Are CrashLooping. What Do You Do?

**Expected Senior-Level Answer:**

*"My first instinct is correlation: upgrade + crashes = upgrade caused issue. But I verify:

**Hypothesis Generation (30 seconds):**
1. Kubelet upgrade incompatible with container runtime version
2. Control plane API changes broke pod specifications
3. Network CNI plugin broke during upgrade
4. Security context constraints too strict for new policy version
5. Storage CSI plugin version mismatch

**Initial triage (2 minutes):**
```bash
oc get clusteroperators  # Any degraded after upgrade?
oc get events --all-namespaces --sort-by=`.lastTimestamp` | tail -30
oc logs -n openshift-kube-apiserver --tail=50  # API logs
```

**Pattern recognition:**
- All crashes in one namespace? → Likely policy/RBAC issue
- Crashes across namespaces? → Control plane/CNI/security issue
- Mix of some running, some crashing? → Resource saturation (upgrade consumed resources)

**Determine blast radius:**
```bash
oc get pods --all-namespaces | grep CrashLoopBackOff | wc -l
# 20% of 1000 pods = 200 pods crashing
```
This is **severe** - not a small issue. Warrants immediate escalation.

**Rollback decision:**
At this point, I'd ask: 'Do we have SLA implications?' 
- If yes: Immediate rollback to previous cluster version
- If no: Continue investigation while preparing rollback

**If rolling back:**
```bash
oc patch clusterversion version --type='merge' -p='{"spec":{"desiredUpdate":{"version":"4.11.1"}}}' --overwrite
# This rolls back control plane + nodes to previous version
# Expected time: 30-60 minutes
```

**If NOT rolling back, I'd investigate:**
```bash
# Pick one crashing pod
oc logs <pod> --previous
# Check if logs reveal: permission denied / config missing / versioning issue

# Check pod security context
oc get pod <pod> -o json | jq '.spec.securityContext'
# Did upgrade enforce stricter defaults?

# Check node kubelet version
oc debug node/<node> -- chroot /host kubelet --version
# Ensure all nodes same version
```

**Why senior approach:**
- I don't panic (systemic issues are often simple)
- I know **when to rollback** vs. debug (20% failure = rollback immediately)
- I document the issue (post-incident: why did upgrade break this?)
- I think about precedent: 'If this happens again...'
"*

---

### Question 4: Explain the Trade-offs Between Blue-Green, Canary, and Rolling Update Deployments. When Would You Choose Each?

**Expected Senior-Level Answer:**

*"Each has different risk/complexity profiles:

**Blue-Green Deployments**
- Run two identical environments (blue=current, green=new)
- After testing green, switch traffic instantly (single DNS change)
- Pros: Instant rollback (revert DNS), full testing before cutover, no downtime
- Cons: Doubles infrastructure cost temporarily (2x resources), requires DNS failover capability
- Choose when:
  - Cost not critical (financial system, trading platform)
  - Need instant rollback capability
  - Testing complex (database schema changes, API breaking changes)
  - Fewer, larger updates (quarterly vs. daily)

**Canary Deployments**
- New version runs alongside old, slowly increasing traffic (5% → 10% → 50% → 100%)
- Errors detected on small user base before full rollout
- Pros: Catches issues on 1% users not 100%, resource efficient, fine-grained control
- Cons: Complex to implement (service mesh required), requires good monitoring, partial rollback harder (some users on old, some on new)
- Choose when:
  - High-frequency deployments (50+ per day)
  - Can tolerate brief partial outages (1% users affected)
  - Good monitoring/alerting to detect issues
  - Cost-sensitive (incremental resource usage)

**Rolling Updates**
- Kubernetes default: gradually replace old pods with new ones
  - Example: 1 pod old → 0 pods old over 5 minutes
- Pros: Lowest overhead (k8s built-in), resource efficient, fast
- Cons: Brief window with mixed versions (some pods v1, some pods v2), harder to diagnose (didn't know which version caused error), risky for breaking changes
- Choose when:
  - Simple updates (no breaking changes)
  - High-frequency deployments (daily)
  - Resource-constrained (can't double capacity)
  - Trade-off: accept risk of partial failure for simplicity

**My Personal Decision Tree:**
```
Is this a critical service? (payment, auth, trading)
├─ YES → Blue-green (can afford cost, need instant rollback)
└─ NO → Rolling update (simple, fast, sufficient)

High-frequency deployments (50+ per day)?
├─ YES → Canary with service mesh
└─ NO → (see above)

Risky change (contract breaking, data migration)?
├─ YES → Blue-green (full testing before cutover)
└─ NO → (see above)
```

**Real-world example:**
- Payment processing: Blue-green (can't afford users paying twice or losing payments)
- Web UI: Rolling update (low risk, fast)
- API service: Canary (moderate risk, high frequency)

**The senior distinction:**
- I understand it's not 'which is best' but 'which fits our constraints'
- I consider business criticality, deployment frequency, and risk tolerance
- Running all three in same organization is normal (different tools for different purposes)
"*

---

### Question 5: Your Database Suddenly Starts Receiving 100x Connection Volume. The Connection Pool Exhausts. What Caused This and How Do You Fix It?

**Expected Senior-Level Answer:**

*"100x spike suggests either traffic spike or connection leak. Here's my diagnostic:

**Immediate (1 minute):**
```bash
# Is traffic genuinely 100x or just connection leak?
oc top pods --sort-by=cpu  # CPU high?
curl localhost:prom/api/v1/... rate(http_requests_total[5m])  # Requests actually 100x?
```

**If requests NOT 100x, connection leak diagnosis:**
```sql
SELECT application_name, COUNT(*) FROM pg_stat_activity GROUP BY application_name;
```
- If I see 95% connections in 'idle' state: connection pool not returning connections
- If I see diverse application_names: multiple services leaking

**Common causes I've seen:**
1. Connection pool misconfigured (size too small)
2. Recent deployment broke connection handling (check git history)
3. App code change leaked connections (forgot close())
4. Third-party service started polling (check logs)
5. Monitoring tool added requests (disable metrics temporarily)

**If traffic IS 100x genuinely:**
- Was there a code change? (Check deployment history)
- Was there an outage elsewhere?(Traffic redirected from secondary system?)
- Authentication service broken? (triggering retries, cascading load)
- Check CloudFront/CDN cache invalidation (everyone fetching simultaneously)

**Fix timeline:**

1. **Immediate (5 minutes):** Scale database connection pool
```yaml
# Increase from default 100 to 500
deployment:
  env:
  - name: DB_POOL_SIZE
    value: '500'
```

2. **Short-term (15 minutes):** Identify root cause by comparing:
```bash
# Pre-incident: git show HEAD~1:deployment.yaml
# Post-incident: git show HEAD:deployment.yaml
```

3. **If recent deploy caused it:**
   - Rollback immediately
   - Run integration tests (why didn't tests catch this?)

4. **If external (real traffic spike):**
   - Scale more database replicas
   - Add read replicas to distribute load
   - Implement caching (reduce database hits)

**The senior thought process:**
- I don't assume what caused it; I MEASURE
- I distinguish 'spike vs. leak' (different fixes)
- I prioritize immediate mitigation (scale) over root cause (can wait 30 minutes)
- I implement monitoring (prevent recurrence)
"*

---

### Question 6: Describe the Most Critical Security Hardening You'd Implement for a Production OpenShift Cluster Handling Payment Data

**Expected Senior-Level Answer:**

*"Payment data means PCI-DSS compliance mandatory. Here's my priority ranking:

**Tier 1 (Non-negotiable - implement first day):**

1. Network Isolation (99% of breaches via network)
```yaml
- Default deny-all network policy
- Explicit allow-list: only permitted connections
- Pod-to-pod mTLS via service mesh (encryption in transit)
- PCI requirement: no unencrypted payment data on network
```

2. Pod Security (prevent container escapes)
```yaml
- Pod Security Standards: restricted mode enforced
  - No privilege escalation (allowPrivilegeEscalation: false)
  - No root access (runAsNonRoot: true)
  - Read-only filesystem (readOnlyRootFilesystem: true)
  - Drop dangerous Linux capabilities
- PCI requirement: prevent attacker from accessing host
```

3. Secrets Management (credentials must be encrypted)
```yaml
- Secrets encrypted at rest (etcd encryption enabled)
- Don't use ConfigMaps for credentials (ever)
- Vault integration: automatic credential rotation every 7 days
- Certificate rotation: < 30 day expiry
```

**Tier 2 (Critical - implement week 1):**

4. RBAC Least Privilege
```yaml
- Developers: only 'create/update deployments' (not delete, not create roles)
- API service account: only 'read payment data' (not other namespaces)
- Principle: assume every account will be compromised, minimize damage
```

5. Image Security
```yaml
- Signed images only (prevent tampered container images)
- Scanned for CVE: reject if Critical/High severity
- Immutable container registries (can't modify pushed images)
```

6. Audit Logging
```yaml
- Every API call logged (who accessed what, when)
- Logs stored external to cluster (prevent attacker deletion)
- Long retention: minimum 1 year for compliance audit
```

**Tier 3 (Important - implement month 1):**

7. Monitoring for attacks
```yaml
- Detect privilege escalation attempts
- Alert on pod with root access (violates pod security)
- Alert on host access (volumeMounts: hostPath)
- Alert on network policy violations (attempted lateral movement)
```

8. Vulnerability Management
```yaml
- Dependency scanning: automated (Dependabot)
- Container scanning: automated (Trivy in CI/CD)
- Penetration testing: quarterly
```

**Why this priority?**
- Tier 1: Where 99% of breaches happen (network, container escape, credentials)
- Tiers 2-3: Defense-in-depth (if Tier 1 fails, these catch issues)

**PCI-DSS specific:**
- Encryption in transit ✓ (mTLS)
- Encryption at rest ✓ (Vault + etcd encryption)
- Access controls ✓ (RBAC, network policies)
- Audit trails ✓ (Kubernetes audit logs)
- Compliance posture ✓ (automated scanning + evidence collection)

**The senior distinction:**
- I don't list every security feature
- I prioritize by risk (network > secrets > other)
- I understand PCI requirements specifically
- I know trading off cost vs. security (don't secure things that aren't worth money)
"*

---

### Question 7: A New Developer Deployed Code That Accidentally Queries the Database 1000x Per Request Instead of Once. How Would You Prevent This in Future?

**Expected Senior-Level Answer:**

*"This is a classic N+1 query problem. Prevention requires multiple layers (no single layer is sufficient):

**Detection + Early Feedback (Prevent reaching prod):**

1. Query Audit in CI/CD
```yaml
buildConfig:
  postCommit:
    command: |
      # Count database queries during integration test
      count=$(grep -r 'db.query' src/ | wc -l)
      # Simple heuristic: > 1000 queries in one endpoint = suspicious
      if [[ $count -gt 1000 ]]; then
        echo "ERROR: Excessive database queries detected"
        exit 1
      fi
```

2. Integration Tests + Monitoring
```python
# Test captures query count
with assert_num_queries(1):  # Expect exactly 1 query
    response = client.get('/api/transactions')
# If 1000 queries: test fails before staging
```

3. APM (Application Performance Monitoring)
```
- Datadog/New Relic captures query performance
- Baseline: endpoint normally 50ms, 1 query
- Alert if: endpoint > 500ms OR queries > 10
- Prevents slow query from reaching production
```

**Stage-Based Prevention:**

4. Staging Environment Testing
```
- Performance regression tests (compare to baseline)
- Load test: simulate 100 concurrent users
- Catch database hammering before production
```

**Production Safety Nets:**

5. Query Rate Limiting (if somehow reaches prod)
```python
# Limit: max 10 queries per request
@rate_limit_queries(max_queries=10)
def get_transactions():
    ...
# If exceeded: return 503 (Too Many Requests)
# Alert: 'Query limit exceeded, possible N+1'
```

6. Slow Query Alerting (real-time)
```sql
SELECT query FROM pg_stat_statements 
WHERE mean_time > 100ms  # Slow query
-- Alert if sudden spike in slow queries
```

**Post-Incident:**

7. RCA + Process Improvement
- Question: Why wasn't this caught?
- Add test case: endpoint must not exceed 5 queries
- Review: do integration tests run before deploy?

**The senior approach:**
- Layered defense (no single point of failure)
- Catches at earliest possible stage (before prod)
- Automated (humans forget, systems don't)
- Updates monitoring based on what was missed
"*

---

### Question 8: Your SLA Says 99.99% Uptime. You've Had 2 Outages This Month (50 Minutes Total). How Would You Decide What To Fix?

**Expected Senior-Level Answer:**

*"99.99% uptime = 52 minutes/year downtime budget. Two 25-minute outages = 50 minutes used. I'm already OVER budget this month.

**Immediate action:**
- Escalate: 'All feature work stopped, incident response priority'
- Declare budget exhausted: 'Any new risk of downtime must be eliminated'

**Root Cause Analysis (what were the two outages?):**

Let's say:
1. Outage 1: etcd quorum lost (node failed)
2. Outage 2: Storage provisioner congestion (didn't scale with demand)

**RCA → Fix prioritization:**

| Outage | RCA | Fix | Priority | Effort | Risk |
|--------|-----|-----|----------|--------|------|
| etcd quorum lost | Single node failures | Add HA monitoring, auto-replacement | P0 | 2 hours | Low |
| Storage provisioner congestion | Single provisioner, hit limit | Horizontal scale provisioners | P0 | 4 hours | Low |

**Prioritization philosophy:**
- Both P0 (SLA already breached)
- Both low-risk fixes (existing technologies, proven patterns)
- Must complete this week (if another happens, we're at 100+ minutes downtime)

**Implementation:**

For etcd quorum:
```yaml
# Add monitoring + auto-remediation
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: etcd-quorum-check
spec:
  groups:
  - name: etcd
    rules:
    - alert: EtcdQuorumLost
      expr: count(up{job='etcd'} == 1) < 3
      for: 30s  # Less than 3 members for > 30s
      annotations:
        summary: Trigger AUTOMATIC failover
        
# Auto-remediate: restart unhealthy etcd pods
cd /var/lib/etcd && rm -rf *.snap
systemctl restart etcd
```

For storage provisioner:
```yaml
# Scale provisioner statefulset
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: storage-provisioner
spec:
  replicas: 3  # Was 1, now 3 for parallel provisioning
  # Horz scale: can provision 3 PVs in parallel vs. 1
```

**For rest of month:**
- Daily runbooks: 'If [symptom], run [fix] immediately'
- Auto-scaling: turn off new feature deployments
- Disaster recovery: test failover procedures (ensure backups work)

**The senior principle:**
- SLA breach = all hands on deck
- You don't do cost-benefit analysis when you're already in the red
- You fix the most likely failure modes FIRST
- You measure burn-down of SLA budget: 'X minutes left this month, Y outages would fail SLA'
"*

---

### Question 9: Walk Me Through Upgrading OpenShift from v4.11 to v4.12 with Zero Downtime

**Expected Senior-Level Answer:**

*"Zero downtime requires orchestration. I'd break this into phases:

**Phase 1: Pre-upgrade (Week before)**

```bash
# Health check cluster
oc adm health-checks

# Verify all workloads have PodDisruptionBudgets
oc get pods --all-namespaces -o=custom-columns=NAME:.metadata.name,HAS_PDB:'has pdb' | grep -v 'True' | wc -l
# If > 0: add PDBs (critical for zero-downtime upgrade)

# Backup etcd (just in case)
/usr/local/bin/cluster-backup.sh /backups

# Test in staging cluster first (always)
oc adm upgrade --to-image=registry.openshift.com/openshift-release-dev/ocp-release:4.12-x86_64
# If staging succeeds: confident in production upgrade
```

**Phase 2: Control Plane Upgrade (30 minutes, rolling)**

```bash
# Update cluster version
oc patch clusterversion version --overwrite -p \
  '{"spec":{"desiredUpdate":{"version":"4.12.0"}}}'

# Kubernetes upgrades one master at a time:
# Master-1 (API stops briefly)
# Master-2 (API stops briefly)  
# Master-3 (API stops briefly)

# Each transition: < 10 seconds of API disruption
# Clients reconnect automatically (transparent)
```

**Phase 3: Node Upgrade (60-90 minutes, rolling)**

```bash
# MachineConfigOperator coordinates rolling node updates
# For each node:
# 1. Drain workload pods
# 2. Check PDBs (ensure at least N pods still running)
# 3. Cordon node (no new pods)
# 4. Wait for existing pods to evict
# 5. Update node OS/kubelet
# 6. Reboot
# 7. Uncordon (resume scheduling)

# Monitoring shows this happening:
watch oc get nodes
# Each node cycles NotReady → Ready as it upgrades
```

**Phase 4: Workload Verification (continuous)**

```bash
# During upgrade, verify applications healthy
watch -n 5 'oc top pods -n prod | sort -k2 -rn | head -5'
# If any pod OOMKilled: deployment using too much memory
# During shutdown: brief spike is normal
# Persistent OOM: upgrade revealed latent bug

# Check error rates
curl 'localhost:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])'
# Expect: <= 0.1% error rate throughout upgrade
# If 5% suddenly: workload issue related to version change
```

**Example: Node-level upgrade sequence**

```
Time 0:00:  worker-1 scheduled for upgrade
Time 0:05:  Pods evicted from worker-1 to worker-2/worker-3
Time 0:10:  Check: did PDB allow eviction?
            master: yes, api-service still has 2/3 pods
Time 0:15:  Node update starts (kubelet v4.11 → v4.12)
Time 0:35:  Node reboots
Time 0:45:  Node comes up, kubelet starts
Time 0:50:  Scheduler resumes placing pods on worker-1
Time 0:55:  workload back to full capacity
```

**Zero-downtime checklist:**
- ✓ All deployments have PDBs (prevent all replicas evicted at once)
- ✓ minAvailable set correctly (usually 50% or N-1)
- ✓ Health checks configured (readiness probe ensures pod doesn't get traffic during restart)
- ✓ Monitoring during upgrade (catch issues early)
- ✓ DNS/load balancer configured (pods can reconnect to new kubelet)
- ✓ Storage not corrupted during upgrade (backup etcd beforehand)

**Failure modes I've handled:**
- etcd disk full: can't upgrade → run `etcdctl compact`
- Worker node stuck: kill hung nftables process, restart
- Operator stalled: restart problematic operator pod
- DNS failure: check CoreDNS pods healthy

**The senior distinction:**
- I understand upgrade is automated (don't manually upgrade nodes)
- Zero-downtime requires workload cooperation (PDBs, health checks)
- I verify at each phase, ready to rollback
- I monitor during, catch issues immediately
"*

---

### Question 10: Describe Your Approach to Cost Optimization for a 500-Node Production Cluster

**Expected Senior-Level Answer:**

*"500 nodes at $0.50/hr = $180K/month. Cost optimization requires looking at:

**Compute Cost Analysis (80% of budget)**

```bash
# 1. Actual vs. Requested allocations
oc top nodes | awk 'NR>1 {used+=$2; requested+=$4} END {print "Used: "used" Requested: "requested" Utilization: "(used/requested*100)"%"}'
# Assuming output: Used 50%, Requested 60%
# => 20% over-provisioned (paying for unused capacity)
```

**Fix: Right-size resources**
```
Current state:
├─ 100 nodes × 16 CPU × $0.50/hr = 500 CPU capacity
├─ Actual usage: 250 CPU (50%)
├─ Reserved system: 100 CPU (kubelet, cri-o, etc)
└─ Usable: 150 CPU (30% utilization) WAY TOO LOW

Optimization:
├─ Reduce to 250 nodes (still > 150% capacity)
├─ Resize individual nodes (smaller instances where possible)
└─ Cost reduction: 500 → 250 nodes = $180K/month → $90K/month (50% savings)
```

**Storage Cost Analysis (15% of budget)**

```bash
# 2. PV utilization
oc get pvc --all-namespaces -o json | jq '.items[] | {name: .metadata.name, storage: .spec.resources.requests.storage}'
# Sum storage requested vs. actual allocated
```

**Fix: Garbage collection**
```
Problem: Old PVCs from deleted deployments still allocated
├─ 100 PVCs × 1TB × $0.10/GB = $100K allocated but unused
├─ Actual data: 50TB (50% utilization)

Solution:
├─ Implement reclaim policy: Delete (auto-delete PVCs when pod deleted)
├─ Archive old data to S3 ($0.023/GB cheaper than EBS)
└─ Cost reduction: $100K → $30K (70% savings)
```

**Compute Optimization (Spot Instances)**

```bash
# 3. State what workloads tolerate interruption
AWS Spot instances: 70% cheaper than on-demand
├─ Batch jobs: YES (tolerant of interruption)
├─ Development: YES (can redeploy)
├─ API services: NO (needs HA)
├─ Databases: NO (state = loss of data)

Implementation:
├─ 60% of compute on Spot instances
├─ 40% on Reserved instances (base capacity)
└─ Cost reduction: 60% × $90K/month = $54K savings
```

**Reserved Instances**

```bash
# 4. Buy reserved capacity (year commitment)
Reserved Instance pricing: 30-50% cheaper than on-demand

Example:
├─ Base capacity: 100 nodes on-demand = $50K/month
├─ Buy 100-node year-long reservation = $40K/month (20% discount)
├─ Burst capacity: 150 extra nodes on-demand during peaks = $75K/month
└─ Cost reduction in peak: $125K → $115K (8% savings)
```

**Consolidated Summary:**

| Category | Before | After | Savings |
|----------|--------|-------|---------|
| Compute (right-sizing) | $90K | $45K | $45K |
| Storage (garbage collection) | $20K | $6K | $14K |
| Spot instances | $45K | $18K | $27K |
| Reserved instances | $25K | $20K | $5K |
| **Total** | **$180K** | **$89K** | **$91K (50%)** |

**Measurement & Automation:**

```bash
# Monthly cost tracking
# Alert if node utilization drops below 40% (over-provisioned)
# Alert if PVC allocated but not used
# Auto-scale: reduce cluster size if utilization drops
```

**The senior approach:**
- Don't assume: MEASURE actual utilization
- Different strategies for different workload types
- Small improvements × many areas = significant savings (not single silver bullet)
- Continuous monitoring prevents cost creep
"*

---

## Conclusion

This comprehensive four-part OpenShift study guide series provides:

✅ **27,000+ lines** of production-grade content  
✅ **Foundational concepts** through **advanced operations**  
✅ **Troubleshooting workflows** with practical scripts  
✅ **Best practices** drawn from real production experience  
✅ **Hands-on scenarios** covering high-availability, failover, performance optimization, and security  
✅ **10 senior-level interview questions** with detailed answers  

**Ready for:** Senior DevOps engineers preparing for production operations, team training programs, incident response, and career advancement.

All materials reflect **5-10+ years of operational experience** condensed into structured, actionable knowledge.
