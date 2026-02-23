# Monitoring Stack for CloudShop

This directory contains the Kubernetes manifests for the CloudShop monitoring infrastructure using Prometheus and Grafana with the Prometheus Operator.

## Architecture Overview

```
monitoring/
├── namespaces/              # Kubernetes namespace for monitoring
│   └── monitoring.yaml      # Namespace definition
├── servicemonitors/         # Prometheus ServiceMonitor CRDs
│   ├── api-gateway.yaml     # Metrics scraping for API Gateway
│   ├── auth-service.yaml    # Metrics scraping for Auth Service
│   ├── products-api.yaml    # Metrics scraping for Products API
│   └── orders-api.yaml      # Metrics scraping for Orders API
├── alerts/                  # Alert rules
│   └── prometheus-rules.yaml # PrometheusRule CRD with 6 alert rules
└── dashboards/              # Grafana dashboards
    ├── cloudshop-overview.json              # Overview dashboard (JSON)
    ├── cloudshop-slo.json                   # SLO monitoring dashboard (JSON)
    └── configmap-grafana-dashboards.yaml    # ConfigMap for provisioning both dashboards
```

## Prerequisites

1. **Kubernetes cluster** with Prometheus Operator installed
   - ServiceMonitor and PrometheusRule CRDs must be available
   - Prometheus instance must be configured to watch the `monitoring` namespace

2. **Prometheus instance** deployed with:
   - Configuration to discover ServiceMonitors from `monitoring` namespace
   - Storage configured for metrics persistence
   - ServiceMonitor selector with `release: prometheus` label

3. **Grafana instance** deployed in `monitoring` namespace with:
   - Prometheus datasource configured (`uid: prometheus`)
   - DashboardProvider configured to load ConfigMaps with label `grafana_dashboard: "1"`

4. **Microservices expose /metrics endpoints** in Prometheus format:
   - `http_requests_total` counter (with status labels)
   - `http_request_duration_seconds_bucket` histogram (for latency percentiles)
   - Metrics must be accessible on port `http` (port 3000 or 5000 depending on service)

## Deployment

### Option 1: Deploy all monitoring components at once

```bash
# From workspace root
kubectl apply -f monitoring/

# Verify
kubectl get servicemonitor -n monitoring
kubectl get prometheusrule -n monitoring
kubectl get configmap -n monitoring
```

### Option 2: Deploy step by step

```bash
# 1. Create namespace
kubectl apply -f monitoring/namespaces/monitoring.yaml

# 2. Deploy ServiceMonitors
kubectl apply -f monitoring/servicemonitors/

# 3. Deploy alert rules
kubectl apply -f monitoring/alerts/

# 4. Deploy Grafana dashboard ConfigMap
kubectl apply -f monitoring/dashboards/configmap-grafana-dashboards.yaml
```

## Verification

### 1. Verify ServiceMonitors are detected

```bash
# Check ServiceMonitors exist
kubectl get servicemonitor -n monitoring
# Expected output:
# NAME             AGE
# api-gateway      2m
# auth-service     2m
# orders-api       2m
# products-api     2m

# Check ServiceMonitor details
kubectl describe servicemonitor api-gateway -n monitoring
```

### 2. Verify Prometheus scraping targets

```bash
# Port-forward to Prometheus (requires Prometheus service in monitoring namespace)
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &

# Open browser: http://localhost:9090
# Navigate to: Status > Targets
# Verify targets appear with:
# - cloudshop-prod/api-gateway/http
# - cloudshop-prod/auth-service/http
# - cloudshop-prod/products-api/http
# - cloudshop-prod/orders-api/http
# 
# Status should be: UP (green)
```

### 3. Verify alert rules are loaded

```bash
# Check PrometheusRule exists
kubectl get prometheusrule -n monitoring
# Expected output:
# NAME                AGE
# cloudshop-alerts    2m

# Check rules in Prometheus UI
# Navigate to: Status > Rules
# Verify 6 alert rules are listed:
# - HighErrorRate
# - HighLatencyP95
# - PodCrashLooping
# - PodNotReady
# - HighMemoryUsage
# - SLOBreach
```

### 4. Verify Grafana dashboards are provisioned

```bash
# Port-forward to Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80 &

# Open browser: http://localhost:3000
# Navigate to: Dashboards > Browse
# Verify two dashboards appear:
# - CloudShop - Overview
# - CloudShop - SLO Monitoring
```

### 5. Test metrics queries

```bash
# Port-forward to Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &

# Open browser: http://localhost:9090/graph
# Test queries:

# Request rate
sum(rate(http_requests_total{namespace="cloudshop-prod"}[5m]))

# Error rate
sum(rate(http_requests_total{status=~"5..",namespace="cloudshop-prod"}[5m])) / sum(rate(http_requests_total{namespace="cloudshop-prod"}[5m])) * 100

# P95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace="cloudshop-prod"}[5m])) by (le))

# Availability SLO
(
  sum(rate(http_requests_total{status!~"5..",namespace="cloudshop-prod"}[30d]))
  /
  sum(rate(http_requests_total{namespace="cloudshop-prod"}[30d]))
) * 100
```

## ServiceMonitors Configuration

Each ServiceMonitor targets microservices in the `cloudshop-prod` namespace using label selectors:

| ServiceMonitor | Target Selector | Metrics Path | Scrape Interval | Port |
|---|---|---|---|---|
| api-gateway | `app: api-gateway` | `/metrics` | 30s | `http` |
| auth-service | `app: auth-service` | `/metrics` | 30s | `http` |
| products-api | `app: products-api` | `/metrics` | 30s | `http` |
| orders-api | `app: orders-api` | `/metrics` | 30s | `http` |

**Note:** ServiceMonitors use the `release: prometheus` label for Prometheus service discovery. Ensure your Prometheus instance is configured with:
```yaml
serviceMonitorSelector:
  matchLabels:
    release: prometheus
```

## Alert Rules

### Alert: HighErrorRate
- **Condition:** >5% of requests return 5xx status codes (over 5 minutes)
- **Severity:** warning
- **Component:** backend
- **Action:** Check application logs, investigate service health

### Alert: HighLatencyP95
- **Condition:** P95 latency > 1 second (sustained over 10 minutes)
- **Severity:** warning
- **Component:** performance
- **Action:** Check application performance, database queries, external API calls

### Alert: PodCrashLooping
- **Condition:** Pod restarts detected (over 15 minutes)
- **Severity:** critical
- **Component:** infrastructure
- **Action:** Check pod logs, investigate OOMKilled or CrashLoopBackOff status

### Alert: PodNotReady
- **Condition:** Pod not in Running state
- **Severity:** warning
- **Component:** infrastructure
- **Action:** Check pod events, logs, and readiness probe status

### Alert: HighMemoryUsage
- **Condition:** Container memory usage > 80% of limit (sustained over 10 minutes)
- **Severity:** warning
- **Component:** resources
- **Action:** Increase memory limits, investigate memory leaks

### Alert: SLOBreach
- **Condition:** Availability < 99.9% (over 30-minute window)
- **Severity:** critical
- **Component:** slo
- **Action:** Escalate to incident response, investigate root cause

## Grafana Dashboards

### Dashboard 1: CloudShop - Overview
**Time Range:** Last 1 hour (auto-refresh 30s)

**Panels:**
1. **Request Rate (RPS)** - Total requests per second across all services
2. **Error Rate (%)** - Percentage of 5xx errors
3. **P95 Latency (ms)** - 95th percentile request latency
4. **Pods Status** - Count of Running vs Not Running pods

### Dashboard 2: CloudShop - SLO Monitoring
**Time Range:** Last 30 days (auto-refresh 30s)

**Panels:**
1. **Availability SLO (30d)** - Current availability vs 99.9% target
2. **Error Budget Remaining** - Percentage of error budget consumed
   - 43.2 minutes allowed downtime per month
   - Turns red when <30% budget remains
3. **Burn Rate Trend (1h)** - Shows how quickly error budget is being consumed
4. **Latency SLI (P95 < 500ms)** - Latency trend against 500ms SLI target

## SLO/SLI Definitions

### SLO (Service Level Objective): 99.9% Availability

**Definition:** System is available and responding to requests 99.9% (99.9000%) of the time over a 30-day period.

**Calculation:**
- Total time in 30 days: 30 × 24 × 60 = 43,200 minutes
- Allowed downtime (error budget): (1 - 0.999) × 43,200 = **43.2 minutes/month**
- Example: If availability falls below 99.9%, alert is triggered

**Error Budget Tracking:**
```
Error Budget Consumed = (1 - Availability) × 43,200 minutes
Error Budget Remaining % = (1 - Error Budget Consumed / 43.2) × 100
```

### SLI (Service Level Indicator): Measured Availability

**Definition:** Ratio of successful requests (non-5xx status) to total requests.

**PromQL Expression:**
```promql
(
  sum(rate(http_requests_total{status!~"5..",namespace="cloudshop-prod"}[30d]))
  /
  sum(rate(http_requests_total{namespace="cloudshop-prod"}[30d]))
) * 100
```

**Related Indicators:**
- **Latency SLI:** P95 latency < 500ms
- **Error Rate SLI:** Error rate < 5%
- **Availability SLI:** Status codes not in 5xx range

## Burn Rate Analysis

Burn rate indicates how quickly the error budget is being consumed:

- **Burn Rate = 1x:** Error budget exhausted in ~30 days (acceptable)
- **Burn Rate = 2x:** Error budget exhausted in ~15 days (warning)
- **Burn Rate = 10x:** Error budget exhausted in ~3 days (immediate action needed)
- **Burn Rate > 30x:** Error budget exhausted in < 24 hours (critical escalation)

**1-hour Burn Rate Query:**
```promql
(
  sum(rate(http_requests_total{status=~"5..",namespace="cloudshop-prod"}[1h]))
  /
  sum(rate(http_requests_total{namespace="cloudshop-prod"}[1h]))
) / (1 - 0.999)
```

## Troubleshooting

### ServiceMonitors not scraping

**Symptom:** Targets don't appear in Prometheus UI

**Solutions:**
1. Verify Prometheus is watching the `monitoring` namespace:
   ```bash
   kubectl describe prometheus -n monitoring
   # Look for serviceMonitorNamespaceSelector and serviceMonitorSelector
   ```

2. Verify services have correct labels in `cloudshop-prod`:
   ```bash
   kubectl get services -n cloudshop-prod --show-labels
   # Services must have: app=<service-name>
   ```

3. Check for label mismatch on services:
   ```bash
   # ServiceMonitors use matchLabels: {app: <name>}
   # Services must have matching labels
   ```

### No metrics data in dashboards

**Symptom:** "No data" or empty panels in Grafana

**Solutions:**
1. Verify microservices expose `/metrics`:
   ```bash
   kubectl port-forward svc/api-gateway -n cloudshop-prod 3000:3000
   curl http://localhost:3000/metrics
   ```

2. Verify Prometheus datasource in Grafana:
   - Grafana Settings > Data Sources
   - Datasource name must be "Prometheus" with UID "prometheus"

3. Check Prometheus targets health:
   - Prometheus UI > Status > Targets
   - All targets should show "UP" status

### Alert rules not firing

**Symptom:** Alerts don't trigger even with high error rates

**Solutions:**
1. Verify PrometheusRule is loaded:
   ```bash
   kubectl get prometheusrule -n monitoring
   kubectl describe prometheusrule cloudshop-alerts -n monitoring
   ```

2. Check Prometheus rule evaluation:
   ```bash
   # In Prometheus UI > Status > Rules
   # Verify alert group exists: cloudshop.rules
   # Check State: Firing/Inactive
   ```

3. Verify alert expressions return data:
   ```bash
   # In Prometheus UI > Graph
   # Test each alert condition manually
   sum(rate(http_requests_total{namespace="cloudshop-prod"}[5m]))
   ```

## Cleanup

To remove all monitoring components:

```bash
# Option 1: Delete entire monitoring namespace (removes all resources)
kubectl delete namespace monitoring

# Option 2: Delete monitoring manifests selectively
kubectl delete -f monitoring/
```

## Related Documentation

- [kubernetes-sigs/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator)
- [Prometheus Operator ServiceMonitor CRD](https://prometheus-operator.dev/docs/operator/api/#servicemonitorspec)
- [Grafana Dashboard Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/dashboards/)
- [SLO/SLI Best Practices](https://sre.google/sre-book/service-level-objectives/)
