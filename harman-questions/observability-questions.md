# Observability Questions

## 1. We have to setup an alert. What are the key pieces/fields of an alert?

### Answer:

A properly structured alert contains critical components that ensure actionable notifications and effective incident response.

**Essential Alert Components:**

**1. Alert Metadata**
```yaml
name: "Database Connection Pool Exhausted"
description: "Database connection pool utilization exceeded 90%"
severity: "critical"           # critical, major, minor, warning, info
environment: "production"      # dev, staging, production
team: "platform-engineering"
owner: "database-team"
ticket_category: "infrastructure"
```

**2. Detection Rule/Condition**
```yaml
query: |
  (mysql_global_status_threads_connected / mysql_global_variables_max_connections) > 0.9
condition: "value > threshold"
evaluation_period: 5m          # How long condition must be true
evaluation_window: 10m         # Time window to evaluate
threshold: 0.9
metric_source: "prometheus"
```

**3. Trigger/Threshold Settings**
```yaml
thresholds:
  critical: 90%
  warning: 70%
  info: 50%
comparison_operator: ">"       # >, <, >=, <=, ==
datapoint_aggregation: "avg"   # avg, max, min, sum, p95, p99
statistic_period: 60s
```

**4. Notification Settings**
```yaml
notification_channels:
  - type: "slack"
    channel: "#database-alerts"
    mentions: ["@database-team"]
  - type: "pagerduty"
    service_id: "service_12345"
    escalation_policy: "critical-oncall"
  - type: "email"
    recipients: ["dba@company.com"]
  - type: "opsgenie"
    team: "platform"
    priority: "critical"

repeat_interval: 5m            # Resend if unresolved
escalation_policy: "critical"
```

**5. Remediation Information**
```yaml
runbook_url: "https://wiki.company.com/runbooks/database-connection-pool"
troubleshooting_steps:
  - "Check active database connections"
  - "Identify long-running queries"
  - "Scale connection pool"
  - "Restart affected services if necessary"
context_links:
  - "Grafana Dashboard: https://grafana.company.com/d/mysql-health"
  - "CloudWatch: MySQL Connection Pool"
  - "Datadog: Database Performance"
```

**6. Suppression Rules**
```yaml
maintenance_windows:
  - day: "sunday"
    start_time: "02:00 UTC"
    end_time: "04:00 UTC"
    reason: "Weekly maintenance"

disable_conditions:
  - attribute: "environment"
    value: "development"
  - attribute: "tag"
    value: "non-critical"

duplicate_grouping:
  enabled: true
  group_by: ["alert_name", "environment", "service"]
  duration: 5m
```

**7. Context & Tags**
```yaml
tags:
  service: "user-service"
  component: "database"
  tier: "critical"
  cost_center: "platform"
  environment: "production"
  
custom_attributes:
  impact: "blocks user authentication"
  affected_regions: ["us-east-1", "eu-west-1"]
  customer_facing: true
```

**8. SLA Information**
```yaml
sla:
  response_time: 5m            # Time to respond
  resolution_time: 15m         # Time to resolve
  acknowledgment_required: true

incident_severity_mappings:
  critical: "SEV-1"
  major: "SEV-2"
  minor: "SEV-3"
```

**Complete Real-World Alert Example:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: database-alerts
  namespace: monitoring
spec:
  groups:
  - name: database.rules
    interval: 30s
    rules:
    - alert: DatabaseConnectionPoolExhausted
      expr: |
        (mysql_global_status_threads_connected / mysql_global_variables_max_connections) > 0.9
      for: 5m
      labels:
        severity: critical
        team: platform
        service: mysql
      annotations:
        summary: "Database connection pool nearly exhausted"
        description: |
          MySQL connection pool is {{ $value | humanizePercentage }} full on {{ $labels.instance }}.
          
          Current Connections: {{ $value | humanize }}
          Max Connections: {{ $labels.max_connections }}
          
          **Impact**: New database connections will be rejected
          **Action**: Increase max_connections or scale connection pool
          
          **Runbook**: https://wiki.company.com/runbooks/db-connection-pool
          **Dashboard**: https://grafana.company.com/d/mysql-health
        
        dashboard: "https://grafana.company.com/d/mysql-health"
        runbook: "https://wiki.company.com/runbooks/db-connection-pool"
        logs: "https://datadog.company.com/logs"
```

**Alert with Webhook for Custom Automation:**

```yaml
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High memory usage on {{ $labels.node }}"
    custom_webhook: "https://automation.company.com/webhooks/vm-scaling"
    auto_remediation: "true"
    auto_action: "scale_vm"
```

---

## 2. Could you describe an alert?

### Answer:

An alert is a notification mechanism triggered when monitored metrics exceed predefined thresholds, indicating potential issues requiring investigation or action.

**Comprehensive Alert Description:**

**What is an Alert?**

An alert is an automated signal from monitoring systems that:
1. Continuously monitors metrics/logs from infrastructure and applications
2. Evaluates conditions against thresholds
3. Triggers notifications when conditions are met
4. Provides context for incident response
5. Drives operational action

**Alert Lifecycle:**

```
1. NORMAL STATE
   ↓
2. THRESHOLD EXCEEDED (entering alerting state)
   ↓
3. EVALUATION PERIOD (wait for consistency)
   ↓
4. ALERT TRIGGERED (if condition persistent)
   ↓
5. NOTIFICATION SENT (via email, Slack, PagerDuty, etc.)
   ↓
6. INCIDENT CREATED (optional, based on severity)
   ↓
7. ON-CALL ENGINEER ACKNOWLEDGED
   ↓
8. ROOT CAUSE INVESTIGATION
   ↓
9. REMEDIATION APPLIED
   ↓
10. ALERT RESOLVES (metric returns to normal)
   ↓
11. POST-INCIDENT REVIEW
```

**Alert Composition:**

**Metric-Based Alert:**
```
Query: cpu_usage_percent{job="web-server"}
Condition: > 80%
Duration: Alert if condition true for 5 minutes
Action: Send Slack message + Create incident
```

**Log-Based Alert:**
```
Query: error_count where level="ERROR" and service="auth"
Condition: > 10 errors in 5 minutes
Action: Page on-call engineer
```

**Prometheus Alert Example:**

```yaml
# Alert definition
groups:
- name: web_service_alerts
  interval: 30s
  rules:
  
  # Simple threshold alert
  - alert: HighErrorRate
    expr: rate(http_errors_total[5m]) > 0.05
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error rate detected"
  
  # Multi-condition alert
  - alert: ServiceDown
    expr: |
      (up{job="api-service"} == 0 and changes(up{job="api-service"}[5m]) > 1)
      or
      (http_requests_total{job="api-service"} == 0 and changes(http_requests_total[5m]) > 0)
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "API service is down"
      dashboard: "{{ $externalURL }}/d/api-service"
```

**Multi-Cloud Alert Correlation:**

```yaml
# Alert that correlates metrics from different sources
- alert: MultiRegionServiceDegraded
  expr: |
    count(
      (up{region=~"us-east|eu-west"} == 0) or
      (rate(http_requests_total{region=~"us-east|eu-west"}[5m]) < 10)
    ) >= 2
  for: 3m
  labels:
    severity: critical
  annotations:
    summary: "Service degradation across multiple regions"
    impact: "Multi-region failover may be required"
```

**Alert with Dynamic Thresholds:**

```yaml
# Alert using baseline calculation
- alert: AnomalousMemoryGrowth
  expr: |
    (node_memory_MemAvailable_bytes - avg_over_time(node_memory_MemAvailable_bytes[1h])) 
    > 
    (stddev_over_time(node_memory_MemAvailable_bytes[1h]) * 3)
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Memory usage exceeds baseline by 3 standard deviations"
```

**Practical Alert Scenarios:**

| Scenario | Alert | Condition |
|----------|-------|-----------|
| Server Down | ServiceUnreachable | HTTP status 5xx for 2min |
| Database Slow | QueryLatencyHigh | P99 latency > 500ms for 5min |
| Disk Full | DiskSpaceIO | Used space > 90% |
| Memory Leak | MemoryGrowth | Memory increases > 10% daily |
| API Errors | ErrorRateHigh | Error rate > 1% for 5min |
| CPU Spikes | CPUThrottling | CPU usage > 85% for 10min |

---

## 3. What is the difference between a bad alert and a good alert?

### Answer:

The distinction between bad and good alerts critically impacts operational efficiency, alert fatigue, and incident response quality.

**Bad Alert Characteristics:**

```yaml
# BAD ALERT EXAMPLE 1: Too Sensitive
alert: HighCPU
expr: node_cpu_usage_percent > 50
for: 1m
annotations:
  summary: "CPU above 50%"

# Problems:
# - Normal spikes trigger constant alerts (alert fatigue)
# - No context about acceptable vs problematic usage
# - Low severity but high frequency
# - No runbook or remediation guidance
```

```yaml
# BAD ALERT EXAMPLE 2: Poorly Described
alert: Alert_001
expr: (metric_name > 100) and (other_metric < 50)
annotations:
  summary: "Condition triggered"

# Problems:
# - Vague naming makes debugging hard
# - No description of what triggered
# - No owner or escalation path
# - Missing dashboard link
# - Cannot determine urgency
```

```yaml
# BAD ALERT EXAMPLE 3: Silent and Unnotifiable
alert: HighLatency
expr: http_request_duration_seconds > 2
for: 2m
# Missing: notification channels, severity labels
# Result: Alert fires but no one gets notified

# Problems:
# - Alert exists but nobody is informed
# - No escalation if initial owner unavailable
# - Cannot track alert history or metrics
```

```yaml
# BAD ALERT EXAMPLE 4: Always Alerting
alert: ProcessMemory
expr: process_resident_memory_bytes > 100000000  # 100MB
for: 30s

# Problems:
# - Too frequently triggered (noise)
# - No consistent evaluation period
# - No business impact context
# - Threshold not based on actual service capacity
```

**Good Alert Characteristics:**

```yaml
# GOOD ALERT EXAMPLE 1: Contextual and Actionable
alert: DatabaseConnectionPoolExhausted
expr: |
  (mysql_global_status_threads_connected / mysql_global_variables_max_connections) > 0.9
for: 5m
labels:
  severity: critical
  team: platform-engineering
  service: mysql
  slo_impact: true
annotations:
  summary: "MySQL connection pool usage > 90%"
  description: |
    MySQL connection pool on {{ $labels.instance }} is {{ $value | humanizePercentage }} full.
    
    **Current**: {{ $value | humanize }} connections
    **Max**: {{ $labels.max_connections }}
    **Available**: {{ label_replace($labels.available_connections, "connections", "", ".*") }}
    
    **Impact**: New database connections will be rejected, affecting:
    - User authentication service
    - Payment processing
    - Order management
    
    **Immediate Actions**:
    1. Check for long-running queries: SHOW PROCESSLIST;
    2. Kill idle connections: SET SESSION wait_timeout=60;
    3. Scale connection pool: max_connections=500
    4. Restart affected services to clear connection leak
    
    **Prevention**:
    - Implement connection pooling (PgBouncer, ProxySQL)
    - Add connection pool monitoring
    - Set connection timeout limits
    
    **Resources**:
    - Runbook: https://wiki.company.com/runbooks/db-connection-pool
    - Dashboard: https://grafana.company.com/d/mysql-health
    - Related Alerts: DatabaseSlowQueries, DatabaseDeadlock
    - Documentation: https://docs.company.com/db/connection-management

# Strength: Complete context, clear actions, impact, escalation
```

```yaml
# GOOD ALERT EXAMPLE 2: Meaningful Threshold
alert: HighApplicationErrorRate
expr: |
  rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
for: 5m
labels:
  severity: major
  service: user-api
  component: web
annotations:
  summary: "Application error rate > 1%"
  description: |
    {{ $labels.service }} error rate is {{ $value | humanizePercentage }}
    
    **SLA Impact**: Error rate SLA is 0.1%, current: {{ $value | humanizePercentage }}
    **Customer Impact**: ~{{ $.value | multiply 100000 }} customers affected
    
    **Debug Steps**:
    - View logs: kubectl logs -f -l app={{ $labels.service }}
    - Check recent deployments: kubectl rollout history deployment/{{ $labels.service }}
    - Review error patterns: SELECT error_type, COUNT(*) FROM logs GROUP BY error_type
    
    **Escalation**:
    - L1: Check logs and dashboards (5 min)
    - L2: Contact service owner (10 min)
    - L3: Incident commander (15 min)

# Strength: Percentage-based (adapts to load), SLA-aware, escalation path
```

```yaml
# GOOD ALERT EXAMPLE 3: Smart Deduplication
alert: PodCrashLoop
expr: |
  rate(kube_pod_container_status_restarts_total[15m]) > 0
for: 5m
labels:
  severity: critical
  team: platform
annotations:
  summary: "Pod crash loop detected: {{ $labels.pod }}"
  deployment_link: "https://grafana.company.com/d/k8s-pods?pod={{ $labels.pod }}"

# Suppression rules prevent noise:
# - Don't alert on pods tagged "non-critical"
# - Don't alert during maintenance windows
# - Group similar pod crashes into single incident
# - Deduplicate for 10 minutes

# Strength: Smart, noise-reduced, with context links
```

**Bad vs Good Alert Comparison Table:**

| Aspect | Bad Alert | Good Alert |
|--------|-----------|-----------|
| Naming | Vague, generic | Clear, specific |
| Threshold | Arbitrary | Data-driven, SLA-based |
| Frequency | Constant noise | Only when action needed |
| Context | Missing | Complete with links |
| Runbook | None | Clear, actionable steps |
| Escalation | No path defined | Clear ownership + path |
| Description | None or unclear | Detailed with impact |
| Testing | Never tested | Validated in production |
| Metrics | Single metric | Correlated signals |
| Tuning | "Just set it high" | Continuously refined |

---

## 4. Describe what makes a good actionable alert.

### Answer:

A good actionable alert removes ambiguity and empowers on-call engineers to respond effectively without extensive investigation.

**Core Principles of Actionable Alerts:**

**1. Signal-to-Noise Ratio**

Bad (Alert Fatigue):
```
- 500 alerts per day
- Most false positives
- Team ignores alerts
- Real incidents missed
```

Good (Targeted):
```
- 5-10 critical alerts per day
- >95% true positive rate
- Team trusts and responds immediately
- Real incidents caught
```

```yaml
# Bad: Alerts on every minor CPU spike
- alert: HighCPU
  expr: node_cpu_usage_percent > 50
  for: 1m

# Good: Alert based on impact
- alert: CPUThrottlingCausingLatency
  expr: |
    (node_cpu_usage_percent > 85) and
    (http_request_duration_seconds_p99 > baseline * 1.5) and
    (rate(http_requests_total[5m]) > 100)  # Only at meaningful load
  for: 10m
```

**2. Clear Identification & Categorization**

```yaml
alert: PaymentServiceDatabaseConnectionPoolExhausted
labels:
  severity: critical
  team: payments
  service: payment-processor
  affected_service: mysql-primary
  business_impact: revenue_blocking
  slos:
    - SLO-001: "99.9% availability"
    - SLO-002: "P99 < 500ms"
  pagerduty_escalation: "payments-oncall"
  auto_escalate_minutes: 15
```

**3. Automatic Root Cause Hints**

```yaml
alert: ServiceDegradation
annotations:
  description: |
    Service {{ $labels.service }} showing {{ $value | humanizePercentage }} error rate
    
    **Likely Root Causes** (based on correlated metrics):
    {{ if gt (query "node_memory_available < 500000000") 0 }}
    ⚠️ Memory pressure detected on nodes
    {{ end }}
    
    {{ if gt (query "mysql_replication_lag_seconds > 10") 0 }}
    ⚠️ Database replication lag detected
    {{ end }}
    
    {{ if gt (query "http_request_queue_depth > 1000") 0 }}
    ⚠️ Request queue backlog growing
    {{ end }}
    
    **Recommended Immediate Actions**:
    1. Check recent deployments (past 30 min)
    2. Review database replication lag
    3. Monitor queue depth and processing rate
    4. Verify external dependency health
```

**4. Specific, Measurable, Time-Bound**

```yaml
# Bad: "Something is wrong"
alert: SystemAlert
expr: some_vague_metric > some_threshold
annotations:
  summary: "System issue detected"

# Good: SMART alert
alert: AuthenticationServiceHighLatency
expr: |
  histogram_quantile(0.99, auth_request_duration_seconds_bucket) > 1
for: 5m
labels:
  severity: major
annotations:
  summary: "Auth service P99 latency exceeded 1 second SLA"
  description: |
    Auth service P99 latency: {{ $value }}s (SLA: 1s)
    Duration: Alert for 5 minutes
    Impact: 3% of users experiencing slow login (estimated)
    
    **Measurable**: {{ $value | humanize }}s (baseline: 400ms, threshold: 1000ms)
    **Time-Bound**: Active for {{ $value | duration }}
    **Action**: Scale auth-service replicas from {{ stat_replicas }} to {{ stat_replicas * 2 }}
```

**5. Includes Actionable Steps**

```yaml
alert: DiskSpaceRunningOut
expr: node_filesystem_availaible_bytes{mountpoint="/"} / node_filesystem_size_bytes < 0.1
for: 5m
annotations:
  summary: "Root disk < 10% available on {{ $labels.instance }}"
  runbook_section: "disk-full"
  
  immediate_actions: |
    **Priority 1 (Execute immediately)**:
    1. Connect to {{ $labels.instance }}
    2. Check disk usage: `du -sh /*`
    3. Identify largest directories: `du -sh /* | sort -rh | head -20`
    4. Clear logs if > 50% of used space: `rm -rf /var/log/*.log*`
    5. Clear temp files: `rm -rf /tmp/* /var/tmp/*`
    
    **Priority 2 (If Priority 1 not enough)**:
    1. Check for Docker volumes/images: `docker system df`
    2. Remove unused images: `docker image prune -a`
    3. Check for stuck containers: `docker ps -a | grep -v running`
    
    **Priority 3 (Scale)**:
    1. Add new volume: AWS console → EBS → Create volume
    2. Mount volume: `sudo mount /dev/nvme0n1 /mnt/data`
    3. Expand storage: `lvextend -L +100G /dev/mapper/root-lv`
    
  dashboard: https://grafana.company.com/d/node-health?var-instance={{ $labels.instance }}
  logs_link: https://datadog.company.com/logs?host:{{ $labels.instance }}
```

**6. Service Owner & Escalation**

```yaml
alert: ElasticsearchClusterRed
expr: elasticsearch_cluster_health_status == 0  # Red = 0
for: 3m
labels:
  severity: critical
  team: platform-search
  owner: search-team-primary
  escalation_policy: |
    - Level 1: Slack notify #platform-search (immediate)
    - Level 2: PagerDuty SEV-1 (if not ack in 5 min)
    - Level 3: Incident commander (if not resolved in 15 min)
    - Level 4: VP Engineering (if duration > 1 hour)
```

**7. Business Impact Communication**

```yaml
alert: PaymentGatewayDown
expr: up{job="payment-gateway"} == 0
for: 1m
labels:
  severity: critical
  business_impact: revenue_blocking
annotations:
  summary: "Payment gateway offline - revenue at risk"
  
  business_context: |
    **📊 Financial Impact**:
    - Revenue blocked: ~$5,000/minute
    - Affected customers: ~10,000
    - SLA breach after: 2 minutes
    
    **👥 Stakeholder Communication**:
    - Customer Support: Escalate to #support-oncall
    - Finance: Report to CFO if > 15 min
    - Product: Notify #product-team
    - Marketing: Check if customer communications needed
    
    **🔧 P0 Response Required**:
    - Page primary + secondary on-call immediately
    - Conference bridge: https://meet.company.com/payment-incident
    - Status page update every 5 minutes
    
  incident_commander: "true"
```

**8. Alert Maturity Framework**

```yaml
# Stage 1: Detection (Just alerts something is wrong)
alert: ServiceDown
expr: up{job="api"} == 0
for: 1m
annotations:
  summary: "Service is down"
# Gap: No context, no fix guidance

# Stage 2: Context (Provides information)
alert: ServiceDown
expr: up{job="api"} == 0
for: 1m
annotations:
  summary: "API service down on {{ $labels.instance }}"
  instance: "{{ $labels.instance }}"
  environment: "{{ $labels.environment }}"
# Gap: Still no action guidance

# Stage 3: Actionable (Guides resolution)
alert: ServiceDown
expr: up{job="api"} == 0
for: 1m
annotations:
  summary: "API service down - health check failing"
  diagnosis: |
    1. SSH to {{ $labels.instance }}
    2. Check service status: `systemctl status api`
    3. View recent logs: `journalctl -u api -n 50`
    4. Test connectivity: `curl http://localhost:8080/health`
  resolution: |
    If service not running:
    1. Start service: `systemctl start api`
    2. Verify: `systemctl status api`
    3. Check if alert clears in 2 minutes
    
    If still failing, escalate to developer team
# Gap: No correlation with other metrics

# Stage 4: Intelligent (Correlates with context)
alert: ServiceDown
expr: |
  (up{job="api"} == 0) and
  (kube_pod_status_phase{app="api"} != "Running")
for: 1m
annotations:
  summary: "API Kubernetes pod not running"
  k8s_context: |
    Pod: {{ $labels.pod }}
    Namespace: {{ $labels.namespace }}
    Node: {{ $labels.node }}
    Status: {{ $labels.status }}
    Age: {{ $labels.created }}
  resolution: |
    1. kubectl describe pod {{ $labels.pod }} -n {{ $labels.namespace }}
    2. kubectl logs {{ $labels.pod }} -n {{ $labels.namespace }} --previous
    3. If OOMKilled: scale replicas or increase memory limits
    4. If CrashLoopBackOff: check logs for application errors
    5. kubectl rollout restart deployment/api -n {{ $labels.namespace }}
  dashboard: https://grafana.company.com/d/k8s?pod={{ $labels.pod }}

# Strength: Correlates Kubernetes metrics, provides K8s-specific actions
```

**9. Testing & Validation Checklist**

```yaml
# Before deploying alert, validate:
validation_checklist:
  - name: "True Positive Rate"
    target: "> 95%"
    method: "Review past 30 days of firings"
  
  - name: "False Positive Rate"
    target: "< 5%"
    method: "Check if issues actually needed action"
  
  - name: "Mean Time to Acknowledge (MTTR)"
    target: "< 2 minutes"
    method: "Measure from alert sent to ACK in alerts system"
  
  - name: "Runbook Completeness"
    target: "100% coverage"
    method: "Follow runbook end-to-end without additional docs"
  
  - name: "Clarity Test"
    target: "Junior engineer understands"
    method: "Have new hire read alert, summarize action"
  
  - name: "Noise Level"
    target: "Daily firing frequency"
    method: "Count firings, should be predictable"
  
  - name: "MTTR (Mean Time to Resolve)"
    target: "< 10 minutes"
    method: "Time from alert to service healthy"
  
  - name: "Escalation Path"
    target: "Tested and working"
    method: "Verify PagerDuty/Slack integration active"
```

**10. Master Alert Template**

```yaml
alert: [SERVICE]_[METRIC]_[CONDITION]
expr: |
  # Clear, well-commented PromQL expression
  (metric_name {labels}) OPERATOR threshold
for: [EVALUATION_WINDOW]
labels:
  severity: [critical|major|minor|warning|info]
  team: [owner_team]
  service: [affected_service]
  component: [component_name]
  business_impact: [revenue_blocking|customer_facing|internal]
  slo_component: [SLO_NAME]
  
annotations:
  summary: "[One-line human-readable summary]"
  
  description: |
    **What Happened**: Clear explanation in non-technical terms
    **Current Value**: {{ $value }} (Threshold: X)
    **Duration**: Alert active for {{ $value | duration }}
    
    **Immediate Impact**:
    - [ ] Feature affected: ...
    - [ ] Users affected: {{ affected_users }}
    - [ ] Revenue at risk: ${{ cost_per_minute }}/min
    - [ ] SLA violation: {{ sla_breach }}
    
    **Root Cause Indicators** (check these first):
    - Recent deployment: `kubectl rollout history -n {{ namespace }}`
    - Database issues: Check replication lag, slow queries
    - Infrastructure: Memory, CPU, disk pressure
    - External deps: Check status pages
    
    **Immediate Actions** (Do these now):
    1. Action 1 with exact command
    2. Action 2 with exact command
    3. Action 3 with exact command
    
    **If Not Resolved in 5 Minutes**:
    - Escalate to {{ escalation_team }}
    - Declare incident in PagerDuty
    - Update status page
    
    **Resources**:
    - Runbook: https://wiki.company.com/runbooks/{{ runbook_id }}
    - Dashboard: https://grafana.company.com/d/{{ dashboard_id }}
    - Logs: https://datadog.company.com/logs?service:{{ service_name }}
    - Related Alerts: {{ related_alerts }}
    
  runbook_url: https://wiki.company.com/runbooks/...
  dashboard_url: https://grafana.company.com/d/...
  owner_slack: "@{{ owner_team }}"
```

**Key Principles Summary:**

1. **Precise**: Specific metric, threshold, time window
2. **Contextual**: Business impact, recent changes, related metrics
3. **Actionable**: Clear steps an engineer can execute immediately
4. **Tested**: Validated true positive rate and resolution time
5. **Owned**: Clear owner and escalation path
6. **Tuned**: Regular review and threshold adjustments
7. **Trustworthy**: Team depends on it, low false positive rate
8. **Integrated**: Connected to dashboards, logs, runbooks
9. **Communicated**: Includes impact for all stakeholders
10. **Evolved**: Based on incident retrospectives