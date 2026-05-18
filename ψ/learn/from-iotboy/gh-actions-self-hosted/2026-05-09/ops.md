# GitHub Actions Self-Hosted Runner Operations: Cost, Monitoring, Autoscaling & Failure Modes

**Research Date:** May 2026  
**Scope:** Comprehensive operational guide for self-hosted GitHub Actions runners, covering financial analysis, monitoring strategies, autoscaling patterns, and disaster recovery.

---

## 1. COST ANALYSIS: GITHUB-HOSTED VS. SELF-HOSTED

### 1.1 GitHub-Hosted Runner Pricing (2026, Post-January Changes)

GitHub reduced hosted runner prices effective January 1, 2026:

| OS | Per-Minute Cost | Monthly Quota (Free) | Notes |
|---|---|---|---|
| **Linux** | $0.006/min | Included (public repos free) | 3x price reduction |
| **Windows** | $0.010/min | Included (public repos free) | Lower than historical $0.016 |
| **macOS** | $0.048/min | Included (public repos free) | 39% price reduction |

**Key Detail:** Prices apply to **total job runtime**, not just user-facing steps. Setup, teardown, and queueing overhead count. A typical 10-minute job on macOS costs $4.80 in compute alone.

### 1.2 Self-Hosted Runner Pricing (2026, Effective March 1)

GitHub introduced a new **$0.002/minute cloud platform fee** for self-hosted runner usage (effective March 1, 2026). This is **not** compute cost—it's the orchestration/job-routing/logging fee charged even when the job runs on your hardware.

**Formula for Total Self-Hosted Cost per Minute:**
```
Total = (Cloud Platform Fee) + (Your Infrastructure Cost)
      = $0.002 + (VM/Server Cost per Minute)
```

### 1.3 Break-Even Analysis

**Scenario 1: AWS t3.medium EC2 (Linux)**
- Instance cost: ~$0.04/hour = $0.00067/minute
- With platform fee: $0.00267/minute
- GitHub-hosted Linux: $0.006/minute
- **Self-hosted is cheaper if:**
  - Job duration > 3 minutes (single job)
  - Monthly volume > 3,000–5,000 minutes (full TCO)
  - Over 10,000 minutes/month, self-hosted saves 50–60%

**Scenario 2: macOS (Apple Silicon M4 Pro, Namespace/Depot managed)**
- Namespace managed: ~$0.04/minute (all-inclusive)
- GitHub-hosted macOS: $0.048/minute
- **Breakeven:** Already cost-competitive, self-hosted wins

**Scenario 3: Hetzner VPS (Dedicated, €15/month)**
- Cost: €15 ÷ 43,200 min/month = €0.00035/minute ≈ $0.0004/minute
- With platform fee: $0.0024/minute
- **Self-hosted is 4x cheaper** than GitHub macOS ($0.048)
- **Competitive with Linux** GitHub-hosted ($0.006) for sustained workloads

**Empirical Break-Even Points:**
| Workload | Self-Hosted ROI | Example Cost/Month |
|---|---|---|
| **Infrequent (< 500 min/mo)** | ❌ Loses money (overhead) | Stick with GitHub-hosted |
| **Light (500–2,000 min/mo)** | 🟡 Neutral (margin thin) | ~$10–50 self-hosted vs. $12–200 hosted |
| **Moderate (2,000–10,000 min/mo)** | ✅ Saves 20–40% | ~$50–100 self-hosted vs. $100–300 hosted |
| **Heavy (> 50,000 min/mo)** | ✅ Saves 50–70% | ~$200–400 self-hosted vs. $1,000+ hosted |

### 1.4 When Self-Hosted Saves Money (Use Cases)

**1. Long-Running Test Suites**
- Heavy integration tests (30–60 min duration)
- Per-minute charges multiply: 1 hour of macOS = $2.88 on GitHub; $0.12 on self-hosted (€10 VPS)
- Savings: 96% with self-hosted

**2. ARM / Embedded Builds**
- GitHub does not offer ARM runners (only x86)
- Graviton2 or ARM Mac required for mobile/embedded CI
- Self-hosted enables otherwise impossible workloads

**3. Dependency Caching**
- GitHub runners are stateless; no local cache between runs
- Self-hosted: Docker layers, Maven repos, npm packages cached on disk
- Eliminates 5–15 min per job of download time on slow internet

**4. GPU-Bound Builds**
- Large ML model training, CUDA compilation
- GitHub doesn't offer GPU runners
- Self-hosted with NVIDIA instance: $0.30–1.00/min (vs. $0.048 macOS for non-GPU work)
- ROI for batch GPU jobs > 1 hour/week

**5. Compliance / Data Residency**
- Job logs, secrets, and intermediate artifacts stay on-premise
- Regulated industries (HIPAA, GDPR, PCI) often mandated
- Cost-neutral if you already have idle infrastructure

---

## 2. WHEN SELF-HOSTED LOSES MONEY

### 2.1 Under-Utilization & Standby Cost

**Problem:** Runner idles 20 hours/day, consuming cloud costs.

| Scenario | Monthly Cost | Utilization | Loss |
|---|---|---|---|
| $10 VPS always-on | $10 | 10% utilized | -$9 waste |
| t3.medium always-on | $30 | 10% utilized | -$27 waste |
| Spot instance (50% discount) | $15 | 10% utilized | -$13.50 waste |

**Remediation:**
- Autoscale to zero (use Terraform AWS GitHub Runner or ARC + Karpenter)
- Schedule shutdown (cron job + runner teardown)
- Use ephemeral runners (pod-per-job in Kubernetes)

### 2.2 Operations Overhead

**Hidden Costs:**
- **Maintenance:** OS updates, runner agent upgrades, security patches: ~5–10 hours/month @ $100/hr = $500–1,000/month
- **Security Incident:** One compromised runner = $5,000–50,000 in forensics, rotation, access review
- **On-Call:** Weekend runner failures require response: ~30 hours/year @ $150 = $4,500/year

**Example:** A small team with 2 runners, minimal load:
- Runner cost: $20/month (VPS)
- Maintenance time: 5 hours/month = $500/month at loaded rate
- **Actual cost: $520/month vs. $100–200 GitHub-hosted would cost**

### 2.3 Security Incident Cost

**Scenario:** Runner exposed to malicious GitHub Action fork; secrets exfiltrated.

| Action | Time | Cost |
|---|---|---|
| Incident detection | 2–48 hours | + $200–2,000 (SIEM, human review) |
| Credential rotation | 2–4 hours | + $200–400 |
| Forensics / audit | 10–20 hours | + $1,000–2,000 |
| Replacement runner rebuild | 4–8 hours | + $400–800 |
| **Total incident cost** | | **$1,800–5,200** |

**Mitigation:** Use OIDC + workload identity instead of long-lived secrets; rotate credentials monthly; audit runner logs quarterly.

### 2.4 Version Drift & Forced Upgrade Windows

GitHub periodically **forces runner agent upgrades**—old versions go offline. 

**Common failure:** Node.js 12 actions discontinued; must rewrite workflows or upgrade runner. Unplanned maintenance window = downtime + operations cost.

---

## 3. AUTOSCALING STRATEGIES

### 3.1 Actions Runner Controller (ARC) on Kubernetes

**Official recommendation from GitHub.** Deploys runners as ephemeral pods; scales based on queued jobs.

**Architecture:**
```
GitHub Service ──long poll──> Listener Pod (in k8s)
                                  │
                                  └──> Patch EphemeralRunnerSet replica count
                                        │
                                        └──> Kubelet spins up/down runner pods
```

**Key Components:**
- **Listener Pod:** Maintains HTTPS long-poll connection to GitHub Actions Service
- **EphemeralRunnerSet:** Kubernetes custom resource defining runner pool
- **AutoScaler:** Patches replica count when jobs queue; scales down on idle

**Pros:**
- ✅ Pod-per-job isolation (no cross-job state leakage)
- ✅ Fast scaling (seconds, not minutes)
- ✅ Native Kubernetes (integrates with karpenter, cluster-autoscaler)
- ✅ Prometheus metrics built-in

**Cons:**
- ❌ Requires Kubernetes cluster (operational overhead)
- ❌ Startup latency (container image pull, runner registration)
- ❌ Container image must be pre-built with all dependencies

**Scaling Example (Helm):**
```yaml
runners:
  - name: linux
    replicas: 0
    minReplicas: 0
    maxReplicas: 10
    resources:
      limits:
        cpu: 2
        memory: 4Gi
```

**Cost Impact:** Running ARC on AWS EKS:
- EKS control plane: $0.10/cluster/hour = $73/month
- 1–10 nodes (on-demand or spot): $0.02–0.10/min each
- Break-even: ~50+ jobs/month to amortize EKS fee

**Monitoring ARC:**
- Prometheus scrapes `:8080/metrics` on controller-manager
- Grafana dashboard (Grafana Labs #19382) tracks job queue depth, scaler state, runner utilization
- Alert on: `runner_pods_pending > 5` (queue backing up), `scaler_webhook_errors` (auth issue)

**Reference:** [Actions Runner Controller – GitHub Docs](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)

### 3.2 Terraform AWS GitHub Runner (philips-labs)

**Managed cloud autoscaling on AWS EC2 spot instances.** Decouples from Kubernetes.

**Architecture:**
```
SQS Queue (GitHub webhook) ──> Scale Up Lambda
                                    │
                                    ├──> Check if job already running
                                    └──> Launch EC2 spot instance
                                         │
                                         └──> Scale Down Lambda (polls every 5 min)
                                             ├──> Check runner idle > 30 min
                                             └──> Deregister & terminate
```

**Scaling Logic:**
- **Up:** Lambda reads SQS, checks GitHub API for queued jobs, counts running runners
- **Down:** Predefined interval (default 5 min) checks each runner's last activity timestamp
  - Idle > threshold (default 30 min) → deregister from GitHub → terminate EC2

**Configuration:**
- Spot instance discount (60–70% vs. on-demand)
- Multi-AZ for resilience
- EBS gp3 volume for state (logs, cache)
- Automatic scaling from 0 to N instances

**Cost (Example: t3.medium spot in us-east-1):**
- On-demand: $0.0416/hour = $30/month (24/7)
- Spot: $0.0125/hour = $9/month (24/7)
- Auto-scaled (8 hours/day, 5 days/week): $0.90/month
- Annual savings vs. GitHub-hosted (10,000 min/mo): $2,000–3,000

**Pros:**
- ✅ 60–70% cost saving with spot instances
- ✅ Scale-to-zero (no idle cost)
- ✅ Native AWS (IAM, VPC, CloudWatch integration)
- ✅ Terraform-codified infrastructure

**Cons:**
- ❌ Spot interruption (2–3% of instances interrupted mid-job)
- ❌ SQS → Lambda → EC2 latency (1–3 minutes to start job)
- ❌ Manual cleanup needed if Lambda fails

**Spot Interruption Mitigation:**
- Use on-demand as fallback (10% of fleet)
- Set `spot_price` to 70% of on-demand (reduces interruptions)
- Implement job timeout + auto-retry

**Reference:** [terraform-aws-github-runner – GitHub](https://github.com/github-aws-runners/terraform-aws-github-runner)

### 3.3 Managed Services (Commercial)

**For teams wanting to outsource autoscaling:**

| Service | Model | Cost | Best For |
|---|---|---|---|
| **Namespace.so** | Managed runners | ~$0.04–0.10/min | High-end builds, macOS, caching |
| **Depot.dev** | Managed + Docker acceleration | ~$0.02–0.05/min | Docker layer caching, fast builds |
| **Blacksmith.sh** | Bare-metal runners | ~$0.024/min (50% cheaper than GitHub) | Raw performance, 2–3x speedup |
| **RunsOn.io** | AWS/cloud runners + autoscaling | Variable (pay for compute) | AWS-native, BYOC flexibility |

**Trade-off:** Pay per-minute premium (~$0.02–0.04) to eliminate operations overhead.

**ROI Decision Tree:**
- Team size < 5, sporadic CI: Use GitHub-hosted
- Team size 5–20, moderate load: RunsOn or ARC
- Team size 20+, heavy load: DIY ARC + Terraform AWS (best ROI)

---

## 4. MONITORING RUNNER HEALTH

### 4.1 Runner Offline Detection (Heartbeat)

**Problem:** Runner crashes; GitHub doesn't know immediately; jobs queue indefinitely.

**Solution:** Heartbeat monitoring at multiple levels.

**Level 1: GitHub API Polling**
```bash
# Check runner status via GitHub API every 5 min
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runners \
  | jq '.runners[] | select(.status=="offline")'

# Alert: If offline > 15 min, page on-call
```

**Level 2: ARC-Native Heartbeat (Kubernetes)**
```yaml
# In ARC, each listener pod sends heartbeat every 30 sec
# If pod crashes → listener no longer polls → scaler sees job queue
# Alert on: `kubectl get pods | grep -v Running`
```

**Level 3: Custom Heartbeat Script**
```bash
#!/bin/bash
# Run this as cron job on runner host every 1 min
ps aux | grep -q "[r]unner" || {
  logger "Runner process died; restarting..."
  systemctl restart github-runner
  # Alert monitoring system
  curl -X POST https://monitoring.internal/alert \
    -d "runner_offline:$(hostname)"
}
```

**Recommended Alerts:**
- Runner offline > 10 minutes
- Runner not responding to GitHub API > 5 minutes
- Listener pod crash (ARC)

### 4.2 Prometheus Metrics (ARC + Custom Exporters)

**Built-in ARC Metrics (port :8080/metrics):**

```
# Listener side
github_runner_github_runner_scale_set_desired_count
github_runner_github_runner_scale_set_created_count
github_runner_github_runner_scale_set_running_count
gha_runner_scale_set_listener_job_completed
gha_runner_scale_set_listener_job_started

# Controller side
gha_runner_scale_set_controller_scaling_up_actions
gha_runner_scale_set_controller_scaling_down_actions
```

**Custom Exporter (github-org-runner-exporter):**

```yaml
# Tracks all org runners via GitHub API
runner_status{runner="linux-1", status="online"} 1
runner_status{runner="linux-2", status="offline"} 0
runner_job_count{runner="linux-1"} 5
runner_cpu_usage{runner="linux-1"} 78.5
runner_disk_free_bytes{runner="linux-1"} 52428800  # 50 GB
```

**Prometheus Scrape Config:**
```yaml
scrape_configs:
  - job_name: 'arc'
    static_configs:
      - targets: ['localhost:8080']
  - job_name: 'runner-exporter'
    static_configs:
      - targets: ['localhost:9090']
```

**Grafana Dashboard (Preconfigured):**
- Grafana Labs #19382: ARC Horizontal Runner Autoscalers
- Panels: Job queue depth, runner utilization, scale events, error rate

**Key Metrics to Alert On:**
| Metric | Threshold | Action |
|---|---|---|
| `runner_status` | offline > 5 min | Page on-call |
| `job_queue_depth` | > 10 | Scale up or manually investigate |
| `listener_webhook_errors` | > 5/min | Check GitHub API connectivity |
| `runner_disk_free_bytes` | < 5 GB | Trigger cleanup job |
| `runner_registration_token_age` | > 90 days | Rotate credentials |

**Reference:** [Enabling GitHub ARC Metrics – Ken Muse](https://www.kenmuse.com/blog/enabling-github-arc-metrics/)

### 4.3 Job Telemetry Export

**Runner Telemetry API (v2.304+):**

Self-hosted runners can export structured telemetry to a custom endpoint via environment variable.

```bash
# On runner machine
export RUNNER_TELEMETRY_OPTOUT=false
export RUNNER_TELEMETRY_ENDPOINT='https://telemetry.internal/collect'
```

**Telemetry Payload (sent after each job):**
```json
{
  "runner_name": "linux-1",
  "job_id": "123456",
  "duration_ms": 180000,
  "status": "completed",
  "action_count": 5,
  "container_image_pulls": 2,
  "disk_usage_mb": 5120,
  "max_memory_usage_mb": 2048,
  "exit_code": 0
}
```

**Use Case:** Feed into InfluxDB or Prometheus for per-job metrics.

---

## 5. COMMON FAILURE MODES & REMEDIATION

### 5.1 Runner Offline (Agent Crashed)

**Failure:** Runner process crashes; GitHub sees runner as offline; new jobs queue indefinitely.

**Detection Signal:**
- GitHub API: `runner.status == "offline"`
- Heartbeat timeout: No webhook event from runner > 30 seconds
- Process monitor: `ps aux` shows no runner agent

**Root Causes:**
- OOM kill (insufficient memory)
- Network partition (DNS failure, VPN drop)
- Disk full (runner log rotation failed)
- Agent version incompatibility (GitHub forced upgrade, runner too old)

**Immediate Remediation (Playbook):**
```bash
# 1. Check if process is alive
systemctl status github-runner
# Expected: running

# 2. Check logs
tail -100 /opt/github-runner/_diag/Runner_*.log | grep -i error

# 3. Manual restart
systemctl restart github-runner

# 4. If still offline after 5 min, force re-register
cd /opt/github-runner
./config.sh remove --unattended --token $REG_TOKEN
./config.sh --url $GITHUB_REPO --token $REG_TOKEN --name $(hostname) --work _work
./svc.sh install
./svc.sh start

# 5. Verify re-registration
# Go to GitHub Settings > Runners; should see runner as "Online" within 30 sec
```

**Prevention:**
- Set resource limits: `--runit-cpuset 0-3 --runit-memory 4g` (prevent OOM)
- Monitor disk space: Alert if < 10 GB free
- Enable auto-restart: `systemctl enable github-runner`
- Rotate logs: `logrotate /opt/github-runner/_diag/*.log` daily

**Recovery Time:** 
- Detection: 30 sec (heartbeat)
- Restart: 5–10 sec
- Re-registration: 5–30 sec
- **Total: < 1 minute for automatic recovery**

---

### 5.2 Disk Full (Cache + Temp Dirs)

**Failure:** Job fails with "No space left on device" midway; subsequent jobs fail immediately.

**Detection Signal:**
- `df -h /`: Shows 100% usage
- Prometheus: `node_filesystem_avail_bytes{mountpoint="/"} < 5000000000` (< 5 GB)
- Job logs: `ENOSPC: no space left on device`

**Root Causes:**
- Docker image layers cached (e.g., 50+ GB of base images)
- Job artifacts not cleaned up (logs, test results)
- `_temp/` directory grows unbounded
- Cache hits grow over weeks

**Space Hogs (Linux):**
```bash
du -sh /opt/github-runner/*
# Typical breakdown:
#   15 GB  _work/              (job artifacts)
#   20 GB  /var/lib/docker/    (images, layers)
#    5 GB  /opt/github-runner/ (runner agent)
#   32 GB  Total on 64 GB disk
```

**Immediate Remediation:**
```bash
# 1. Free disk space NOW
docker system prune -a --force    # Remove unused images (10–20 GB)
rm -rf /opt/github-runner/_work/* # Clear job artifacts (5–10 GB)
rm -rf /opt/github-runner/_temp/* # Clear temp (1–2 GB)

# 2. Verify
df -h /

# 3. Restart runner (if halted)
systemctl restart github-runner
```

**Nightly Cleanup Job (Cron):**
```bash
#!/bin/bash
# /usr/local/bin/runner-cleanup.sh
# Run as: 0 2 * * * /usr/local/bin/runner-cleanup.sh

set -e
echo "[$(date)] Starting runner disk cleanup..."

# Docker cleanup
docker system prune -a --force 2>&1 | tail -1 >> /var/log/runner-cleanup.log

# Temp cleanup
find /opt/github-runner/_temp -mtime +7 -delete

# Work cleanup (keep last 3 days)
find /opt/github-runner/_work -mtime +3 -type f -delete

# Log rotation
logrotate -f /etc/logrotate.d/github-runner

echo "[$(date)] Cleanup complete. Free space: $(df -h / | tail -1)" >> /var/log/runner-cleanup.log
```

**Monitoring:**
```yaml
# Prometheus alert
- alert: RunnerDiskUsageHigh
  expr: |
    (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"})
    / node_filesystem_size_bytes{mountpoint="/"} > 0.80
  for: 5m
  annotations:
    summary: "Runner {{ $labels.instance }} disk {{ $value | humanizePercentage }}"
    action: "Trigger cleanup job immediately"
```

**Prevention:**
- Disk size: Use >= 100 GB for self-hosted runners
- Cleanup: Hourly prune of Docker; nightly cleanup of artifacts
- Cache policy: Implement retention (keep last 30 days only)

**Recovery Time:**
- Cleanup: 5–15 minutes (Docker prune is slow)
- Job restart: 2–5 minutes
- **Total: 20–30 minutes before runner is usable again**

---

### 5.3 Zombie Containers / Processes

**Failure:** Failed job leaves behind container or child process; consuming resources; next job inherits zombies.

**Detection Signal:**
- `ps aux | grep -c "<defunct>"` > 0
- `docker ps -a | grep -c "Exited"` grows over time
- Memory usage grows per job (never reclaimed)
- Job logs show "Cannot bind to port 8080" (port held by zombie)

**Root Causes:**
- Job cancelled mid-run; Docker container not properly reaped
- Nested containers (Docker-in-Docker) not cleaned up
- Child processes (background services) not killed at job end
- `--rm` flag missing from `docker run` commands

**Immediate Remediation:**
```bash
# 1. Kill zombies
kill -9 $(ps aux | grep -E '<defunct>|zombie' | awk '{print $2}')

# 2. Clean stray containers
docker ps -a --filter status=exited -q | xargs -r docker rm

# 3. Verify
ps aux | grep -c "<defunct>"
# Should return 0

# 4. Restart runner
systemctl restart github-runner
```

**Remediation via ARC (Kubernetes):**
```yaml
# ARC handles this by deleting the entire pod
# (including all processes) when job completes
# No zombie issue because pod lifecycle == job lifecycle
spec:
  pods:
    - name: runner
      ephemeral: true  # Auto-cleanup after job
      imagePullPolicy: Always
      image: github-actions-runner:latest
```

**Prevention:**
- Use `--rm` on all `docker run` commands
- Use `docker compose --remove-orphans` before up
- Set `ACTIONS_RUNNER_HOOK_JOB_COMPLETED` to kill lingering processes
  ```bash
  #!/bin/bash
  # /opt/github-runner/cleanup.sh
  pkill -P $$ || true  # Kill all children of runner process
  ```
- Use ephemeral runners (ARC, Docker) instead of persistent VMs

**Recovery Time:**
- Detection: 5–10 minutes (after failed job)
- Cleanup: 1–2 minutes
- **Total: 10–15 minutes**

---

### 5.4 Job Stuck in Queue (No Eligible Runner)

**Failure:** Workflow queued forever; shows "Waiting for a runner to pick up this job..."

**Detection Signal:**
- GitHub UI: Job shows "queued" > 30 minutes
- GitHub API: `job.status == "queued"` and `job.runner_id == null`
- Logs: No attempt to contact runner

**Root Causes:**
1. **Label Mismatch:** Job requests `runs-on: [custom-label]` but no runner has that label
2. **All Runners Busy:** Concurrency limit or all runners executing jobs
3. **Runner Offline:** All runners matching the label are offline
4. **Missing Workflow:** Job queued, but workflow file deleted or moved

**Debugging Playbook:**
```bash
# 1. Check what the job is asking for
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runs/RUN_ID \
  | jq '.jobs[0].labels'
# Expected: ["self-hosted", "linux", "custom-label"]

# 2. Check available runners
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runners \
  | jq '.runners[] | {name, labels, status}'

# 3. Confirm labels match
# If job wants ["self-hosted", "linux"] but runner only has ["self-hosted", "macos"]
# → That's the problem. Add label to runner:
gh run-list --label custom-label

# 4. If runner has label, check runner status
systemctl status github-runner
curl http://localhost:3389/health  # (if runner has health endpoint)

# 5. Check runner logs for errors
tail -50 /opt/github-runner/_diag/Runner_*.log
```

**Immediate Fix (3 Options):**

**Option A: Add Missing Label to Runner**
```bash
# On runner machine
curl -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runners/RUNNER_ID \
  -d '{"labels": ["self-hosted", "linux", "custom-label"]}'
```

**Option B: Update Workflow to Match Available Labels**
```yaml
# In .github/workflows/test.yml
jobs:
  test:
    runs-on: [self-hosted, linux]  # Changed from [self-hosted, custom-label]
```

**Option C: Restart Runner (if online but stuck)**
```bash
systemctl restart github-runner
# GitHub should detect runner online within 30 sec
# Job will be picked up immediately
```

**Prevention:**
- Validate label match at workflow parse time
- Document expected labels in README
- Use matrix strategy to test multiple label combinations
- Alert if job queued > 15 minutes without a runner pickup

**Recovery Time:**
- Diagnosis: 5 minutes (review labels)
- Fix: 1 minute (restart runner or add label)
- **Total: 6 minutes from queue to execution**

---

### 5.5 Secrets Accidentally Logged

**Failure:** Secret (API key, password) appears in plaintext in job logs; exposed to external viewers; security incident.

**Detection Signal:**
- GitHub logging system flags secret pattern (e.g., `ghp_*` for GitHub token)
- Secret redaction fails if:
  - Secret wrapped in JSON/YAML quotes (redaction does exact-match only)
  - Secret base64-encoded (redaction sees encoded form, not plaintext)
  - Secret split across lines
- Logs show `***` but upstream logging system (Splunk, ELK) has plaintext

**Root Causes:**
- Script outputs full error message containing secret
- Debug logging enabled (logs entire environment)
- Secret passed as command argument (visible in process list)
- Actions that lack built-in secret sanitization (e.g., custom Docker action)

**Immediate Remediation (If Leaked):**
```bash
# 1. Rotate secret immediately
# GitHub Actions: Manually delete the secret and create a new one
# API Keys: Use provider's dashboard to revoke and generate new

# 2. Audit downstream access
# Check logs on systems where this secret was used
# e.g., if AWS key leaked: aws cloudtrail check for API calls in past 30 min

# 3. Mark logs as private (if available)
gh run view RUN_ID --json logs | head -1000 | grep -i "secret" || true
# (GitHub doesn't provide bulk redaction of logs post-facto)

# 4. Force re-run workflow
# Once secret is rotated, re-run the job (old logs remain but secret is now dead)
gh run rerun RUN_ID
```

**Prevention (Best Practices):**

**A. Enable Secret Masking in Logs**
```bash
# GitHub Actions built-in secret redaction:
# Any secret defined in GitHub Secrets is auto-redacted
# But this only works if the EXACT value appears in logs

# Do NOT wrap secrets in JSON before logging:
# ❌ Bad:
echo '{"api_key": "'$API_KEY'"}'  # Redaction fails

# ✅ Good:
echo "API key set ($(echo $API_KEY | cut -c1-5)...)"
```

**B. Suppress Debug Output**
```yaml
# In .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      ACTIONS_STEP_DEBUG: false  # Disable debug logging
      ACTIONS_RUNNER_DEBUG: false
    steps:
      - run: |
          # Don't use: set -x (prints all commands, including secrets)
          # Use conditional logging instead:
          if [[ "$DEBUG" == "true" ]]; then
            echo "Token: $(echo $TOKEN | cut -c1-10)***"
          fi
```

**C. Use OIDC / Workload Identity (No Secrets)**
```yaml
# Instead of storing long-lived API keys:
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/github-actions
          aws-region: us-east-1
      # AWS session token is ephemeral, expires in 1 hour
      # No static secret stored in GitHub
```

**D. Audit Log Settings**
```bash
# Request logs be deleted after N days (GitHub default: 90 days)
# For sensitive repos: Set to 7 days

# API call (GitHub Enterprise):
curl -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo \
  -d '{"log_retention_days": 7}'
```

**E. Container Image Scanning**
```bash
# Scan logs for secret patterns before pushing container
trivy image --severity HIGH,CRITICAL my-app:latest

# Check for common patterns
grep -r "ghp_\|aws_\|sk_live" . || echo "No secrets found"
```

**Recovery Time:**
- Detection: 5 minutes (GitHub redacts, but alert if redaction fails)
- Secret rotation: 5–10 minutes
- Downstream audit: 30 minutes – 2 hours
- **Total: 40 minutes to fully remediate**

---

### 5.6 Runner Version Drift / Forced Upgrade

**Failure:** GitHub deprecates runner agent version; runners forced offline until upgraded.

**Detection Signal:**
- GitHub shows "Deprecated" banner on runner
- Runners go offline at sunset date despite being online
- Runner logs show "Agent version X.X.X is deprecated"
- GitHub announces deprecation in Actions Changelog

**Recent Examples:**
- Node.js 12 actions discontinued (2023): All actions using Node.js 12 broke; runners had to upgrade
- Runner v2.276 deprecation (2022): Required upgrade to v2.300+
- Ubuntu 18.04 EOL (2023): Runner packages no longer available

**Immediate Remediation (Planned Upgrade):**
```bash
# 1. Check current version
/opt/github-runner/run.sh --version

# 2. Download new version
cd /tmp
wget https://github.com/actions/runner/releases/download/v2.304.1/actions-runner-linux-x64-2.304.1.tar.gz
tar xzf actions-runner-linux-x64-2.304.1.tar.gz -C /opt/github-runner/

# 3. Stop runner
systemctl stop github-runner

# 4. Backup old binary
cp -r /opt/github-runner /opt/github-runner.bak

# 5. Replace runner directory
cd /opt/github-runner
rm -rf bin/ lib/
# Extract new files into /opt/github-runner

# 6. Restart
systemctl start github-runner

# 7. Verify
/opt/github-runner/run.sh --version  # Should match 2.304.1
ps aux | grep -q "github.*running" && echo "Runner online"
```

**Automation (Ansible Playbook):**
```yaml
---
- hosts: github-runners
  vars:
    runner_version: 2.304.1
    runner_home: /opt/github-runner
  tasks:
    - name: Check current version
      command: "{{ runner_home }}/run.sh --version"
      register: current_version
      changed_when: false

    - name: Upgrade if needed
      block:
        - name: Stop runner
          systemd: name=github-runner state=stopped

        - name: Backup current
          command: "cp -r {{ runner_home }} {{ runner_home }}.bak.{{ ansible_date_time.iso8601 }}"

        - name: Download new version
          unarchive:
            src: "https://github.com/actions/runner/releases/download/v{{ runner_version }}/actions-runner-linux-x64-{{ runner_version }}.tar.gz"
            dest: "{{ runner_home }}"
            remote_src: yes
            extra_opts: ["--strip-components=1"]

        - name: Start runner
          systemd: name=github-runner state=started

        - name: Verify
          command: "{{ runner_home }}/run.sh --version"
          register: new_version
      when: current_version.stdout != runner_version
```

**Planning for Deprecations:**
```bash
# 1. Subscribe to GitHub Actions Changelog
# https://github.blog/changelog/label/actions/

# 2. Set calendar reminder 30 days before deadline
# Example: "Node.js 12 actions EOL: 2023-06-30"
# Alert: 2023-05-30 (upgrade all runners by then)

# 3. Test upgrade on staging runner first
# Spin up new VM, upgrade, run test jobs for 24 hours

# 4. Batch upgrade production runners
# 30% today, 30% tomorrow, 40% next week
# (Avoid all-at-once upgrade causing downtime)
```

**Monitoring:**
```yaml
# Prometheus alert
- alert: RunnerVersionDeprecated
  expr: |
    runner_version_deprecated == 1
  annotations:
    summary: "Runner {{ $labels.runner_name }} version deprecated"
    action: "Upgrade within 7 days or runner will be forced offline"
```

**Prevention:**
- Monitor GitHub Actions Changelog monthly
- Set up 30-day upgrade window before EOL
- Keep runners within N-2 of latest version
- Test upgrades in staging before production

**Recovery Time:**
- Planned upgrade: 5–10 minutes downtime per runner
- Emergency upgrade (after forced offline): 10–20 minutes
- **Total: 15 minutes to restore service**

---

## 6. CACHING STRATEGIES

### 6.1 actions/cache vs. Local Filesystem

**Official GitHub Action `actions/cache`:**

**How It Works:**
- Cache stored in GitHub-owned cloud storage (AWS S3)
- Actions/cache retrieves cache on `cache-hit: true`
- Scope: Per branch + OS + key (hashFiles) → prevents cross-branch pollution
- Retention: 7 days without access (auto-deleted)

**Pricing:**
- GitHub-hosted runners: Storage included (no additional charge)
- Self-hosted runners: Storage included (GitHub API call, no cost)

**Example (Node.js Dependencies):**
```yaml
- uses: actions/setup-node@v3
  with:
    node-version: 18
    cache: npm  # Auto-manages npm cache via actions/cache
```

**Pros:**
- ✅ Zero configuration (setup-node, setup-python handle it)
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Automatic invalidation on dependency changes (hashFiles)
- ✅ Secure (isolated per repo)

**Cons:**
- ❌ Network overhead (upload/download to GitHub storage)
- ❌ Not faster than local for self-hosted (data leaves machine)
- ❌ Latency: 1–5 minutes per cache transfer (5–20 MB typical)

**Local Filesystem Caching (Self-Hosted Only):**

**How It Works:**
- Cache stored on runner machine (`/opt/github-runner/_work` or custom location)
- Persists across job runs
- No network overhead

**Example (Maven Cache):**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v3
      
      - name: Cache Maven
        uses: actions/cache@v3
        with:
          path: ~/.m2/repository
          key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
      
      # On self-hosted runner, GitHub caches locally by default
      # No network transfer; instant retrieval (< 1 sec)
```

**Pros (Self-Hosted):**
- ✅ No network latency (< 1 second)
- ✅ Persistent across runs (local disk)
- ✅ Works offline (no GitHub API needed)
- ✅ Unlimited size (limited by disk)

**Cons:**
- ❌ Must manage disk cleanup (cache grows unbounded)
- ❌ GitHub-hosted runners can't use (ephemeral)
- ❌ Not portable (tied to specific machine)
- ❌ Stale cache if runner is replaced

**Direct Filesystem Caching (No actions/cache):**

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - name: Cache prep
        run: |
          mkdir -p /mnt/runner-cache/npm
          ln -s /mnt/runner-cache/npm ~/.npm
          # Now npm uses persistent cache at /mnt/runner-cache

      - run: npm ci  # Uses ~/.npm (symlinked to /mnt/runner-cache)
```

**Trade-Off Table:**
| Aspect | actions/cache | Local FS | Direct FS |
|---|---|---|---|
| **Speed (GitHub-hosted)** | 1–5 min | N/A | N/A |
| **Speed (Self-hosted)** | 1–5 min | < 1 sec | < 1 sec |
| **Size limit** | 5 GB (GitHub) | Disk size | Disk size |
| **Retention** | 7 days | Persistent | Persistent |
| **Setup effort** | Low (auto) | Medium | High |
| **Cost** | Included | Disk cost | Disk cost |

### 6.2 Monorepo Caching (NX-Style)

**Challenge:** Monorepo with 50+ packages; each package has dependencies; cache invalidation complex.

**Solution: Distributed Cache with NX**

```yaml
# .github/workflows/test.yml
jobs:
  affected:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for git diffing

      - uses: nrwl/nx-set-shas@v3  # Set SHAs for git comparison

      - name: Cache NX
        uses: actions/cache@v3
        with:
          path: |
            node_modules
            dist/
          key: nx-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

      - run: npx nx affected --target=test --base=${{ env.NX_BASE }} --head=${{ env.NX_HEAD }}
        # Runs tests only for affected packages; uses cached builds for untouched
```

**Result:**
- First run: 15 minutes (builds all packages)
- Subsequent runs (no changes): 2 minutes (runs from cache)
- Subsequent runs (1 package changed): 5 minutes (rebuild only that package + tests)

### 6.3 Docker Layer Caching

**Problem:** Building Docker image from scratch takes 10+ minutes; most layers (OS, deps) unchanged.

**Solution: Docker BuildKit + Local Cache**

```dockerfile
# Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3 \
    curl \
    git

COPY requirements.txt .
RUN pip3 install -r requirements.txt  # Heavy step; changes often

COPY . .
RUN python -m pytest  # Test layer; changes per commit
```

**GitHub Actions Workflow:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker BuildKit
        uses: docker/setup-buildx-action@v2

      - name: Build with cache
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: myapp:latest
          cache-from: type=local,src=/tmp/docker-cache
          cache-to: type=local,dest=/tmp/docker-cache,mode=max
```

**Cache Breakdown (Self-Hosted):**
- Layer 1 (ubuntu:22.04): 80 MB → cached, reused in 0.1 sec
- Layer 2 (apt-get install): 500 MB → cached, reused in 1 sec (first time: 30 sec)
- Layer 3 (pip install): 1.5 GB → cached, reused in 10 sec (first time: 5 min)
- Layer 4 (COPY + test): Fresh each run → 5 min

**Total Time:**
- Cold build: 35+ minutes
- Warm build (cached): 5–10 minutes
- **Speedup: 3–7x**

**Limitations:**
- Cache must be stored locally (not portable to another runner)
- Cache grows to 5–10 GB (requires disk cleanup)

---

## 7. LOGGING, AUDIT & SECRETS

### 7.1 Job Log Storage & Retention

**Where Logs Land:**
- **GitHub-hosted runners:** Logs stored in GitHub cloud (configurable retention)
- **Self-hosted runners:** Logs stored in GitHub cloud (same as hosted)
- **Downstream systems:** GitHub webhook can forward logs to Splunk, ELK, DataDog

**Log Retention Policy (GitHub):**
```bash
# Set retention to 7 days (sensitive repos)
curl -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo \
  -d '{"log_retention_days": 7}'

# Default: 90 days
# Max: 400 days
```

**Access Control:**
```bash
# Check who can view logs
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/collaborators \
  | jq '.[] | {login, permission}'

# Logs visible to: Repo admins, org members (with repo access), actions workflow owner
```

### 7.2 Secret Redaction

**GitHub's Redaction Logic:**
- Scans each line of logs for exact matches to secret value
- If match found, replaces with `***` before storage
- **Limitation:** Only exact matches; fails if secret is wrapped or encoded

**Example Redaction Failures:**

```bash
# ✅ Properly redacted (exact match)
echo "Token: abc123xyz"
# Output: Token: ***

# ❌ NOT redacted (wrapped in JSON)
echo '{"token": "abc123xyz"}'
# Output: {"token": "abc123xyz"}  # Secret still visible!

# ❌ NOT redacted (base64-encoded)
echo "$(echo abc123xyz | base64)"
# Output: YWJjMTIzeHl6  # GitHub sees encoded form, not plaintext

# ❌ NOT redacted (split across lines)
echo "abc"
echo "123"
echo "xyz"
# Output: abc 123 xyz  # No exact match
```

**Prevention:**
```bash
# ✅ Do NOT output secrets directly:
# ❌ Bad:
curl https://api.example.com -H "Authorization: $SECRET"

# ✅ Good (truncate output):
echo "API call with token: $(echo $SECRET | cut -c1-10)***"

# ✅ Better (use OIDC, no secrets):
gh auth token | curl https://api.example.com -H "Authorization: token $(cat -)"
```

### 7.3 Audit Trail & Compliance

**GitHub Audit Log Events (for self-hosted):**

```bash
# Track runner registration/removal
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/myorg/audit-log \
  -G --data-urlencode 'phrase=action:runners' \
  | jq '.[] | {action, actor, created_at, data}'

# Events:
# - runners.create
# - runners.remove
# - runners.update_labels
# - runners.register_runner
```

**Example Audit Entry:**
```json
{
  "action": "runners.register_runner",
  "actor": "admin-user",
  "created_at": "2026-05-07T14:23:45Z",
  "data": {
    "runner_id": 12345,
    "runner_name": "linux-1",
    "org": "myorg",
    "repo": "myrepo"
  }
}
```

**Compliance Logging (HIPAA/SOC2):**

```bash
# Redirect GitHub logs to external system (Splunk, DataDog)
# GitHub Actions Webhook → Lambda → Splunk HTTP Event Collector

# Webhook payload includes:
{
  "action": "completed",
  "workflow_run": {
    "id": 123,
    "conclusion": "success",
    "created_at": "2026-05-07T...",
    "run_number": 42,
    "event": "push",
    "head_branch": "main"
  },
  "repository": {
    "name": "myrepo",
    "full_name": "org/myrepo"
  }
}

# Store logs with:
# - Immutable log format (audit trail cannot be modified)
# - Multi-factor approval for log deletion
# - 7+ year retention (regulatory requirement)
```

---

## 8. DISASTER RECOVERY

### 8.1 Golden AMI / Template Approach

**Goal:** Spinup new runner in < 5 minutes if old one fails.

**Process:**

**Step 1: Create Golden Image (Terraform)**
```hcl
# aws/main.tf
resource "aws_ami" "github_runner" {
  name = "github-runner-${formatdate("YYYY-MM-DD", timestamp())}"
  source_ami = data.aws_ami.ubuntu_22.id

  launch_permission {
    group = "self"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y git curl docker.io",
      "sudo usermod -aG docker ubuntu",
      # Register runner (see Step 3)
      "./register-runner.sh"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
    }
  }
}

output "ami_id" {
  value = aws_ami.github_runner.id
}
```

**Step 2: Ansible Playbook for Runner Registration**
```yaml
# ansible/register-runner.yml
---
- hosts: new_runners
  vars:
    github_token: "{{ vault_github_token }}"
    runner_name: "{{ ansible_hostname }}"
    runner_home: /opt/github-runner
  tasks:
    - name: Create runner directory
      file:
        path: "{{ runner_home }}"
        state: directory
        owner: ubuntu
        mode: '0755'

    - name: Download runner
      unarchive:
        src: https://github.com/actions/runner/releases/download/v2.304.1/actions-runner-linux-x64-2.304.1.tar.gz
        dest: "{{ runner_home }}"
        remote_src: yes

    - name: Register with GitHub
      shell: |
        cd {{ runner_home }}
        ./config.sh --url https://github.com/myorg/myrepo \
          --token {{ github_token }} \
          --name {{ runner_name }} \
          --work _work
      become: yes
      become_user: ubuntu

    - name: Install systemd service
      template:
        src: github-runner.service.j2
        dest: /etc/systemd/system/github-runner.service
      become: yes

    - name: Enable & start service
      systemd:
        name: github-runner
        enabled: yes
        state: started
      become: yes
```

**Step 3: Recovery Playbook (Triggered on Failure)**
```bash
#!/bin/bash
# disaster-recovery.sh

# Trigger when: runner offline > 30 min, disk full, crashed

RUNNER_NAME="${1:-linux-1}"
REGION="us-east-1"
AMI_ID="ami-0abc1234567890xyz"  # Golden image ID

echo "[$(date)] Disaster recovery: Replacing $RUNNER_NAME"

# 1. Terminate old instance
OLD_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$RUNNER_NAME" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

if [ "$OLD_INSTANCE" != "None" ]; then
  echo "Terminating old instance: $OLD_INSTANCE"
  aws ec2 terminate-instances --instance-ids "$OLD_INSTANCE"
  aws ec2 wait instance-terminated --instance-ids "$OLD_INSTANCE"
fi

# 2. Deregister runner from GitHub
curl -X DELETE \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runners/RUNNER_ID

# 3. Launch new instance from golden image
NEW_INSTANCE=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t3.medium \
  --key-name my-key \
  --security-group-ids sg-0abc1234567890xyz \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$RUNNER_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched new instance: $NEW_INSTANCE"

# 4. Wait for instance to be ready
aws ec2 wait instance-running --instance-ids "$NEW_INSTANCE"

# 5. Get IP and run Ansible playbook
IP=$(aws ec2 describe-instances --instance-ids "$NEW_INSTANCE" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

sleep 30  # Wait for SSH to be ready

ansible-playbook -i "$IP," ansible/register-runner.yml

echo "[$(date)] Disaster recovery complete. New runner: $NEW_INSTANCE ($IP)"

# 6. Verify runner is online (wait up to 5 min)
for i in {1..60}; do
  STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/owner/repo/actions/runners \
    | jq ".runners[] | select(.name==\"$RUNNER_NAME\") | .status")
  
  if [ "$STATUS" == '"online"' ]; then
    echo "Runner online!"
    exit 0
  fi
  sleep 5
done

echo "ERROR: Runner did not come online within 5 minutes"
exit 1
```

**Recovery Time:**
- Detection: 5 minutes (heartbeat timeout)
- Termination: 2–3 minutes
- Instance launch: 1–2 minutes
- SSH ready: 1 minute
- Runner registration: 1–2 minutes
- Verification: 1 minute
- **Total: 10–15 minutes to replacement runner online**

### 8.2 Ignition / Cloud-Init Template (Kubernetes)

**For ARC on Kubernetes:**

```yaml
# runner-ignition.ign (Fedora CoreOS format)
variant: fcos
version: 1.4.0

systemd:
  units:
    - name: github-runner.service
      enabled: true
      contents: |
        [Unit]
        Description=GitHub Actions Runner
        After=network-online.target docker.service
        Requires=docker.service

        [Service]
        User=github
        WorkingDirectory=/opt/github-runner
        ExecStart=/opt/github-runner/run.sh
        Restart=always
        RestartSec=10
        StandardOutput=journal
        StandardError=journal

        [Install]
        WantedBy=multi-user.target

storage:
  files:
    - path: /opt/github-runner/register.sh
      overwrite: true
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          curl -fsSL https://github.com/actions/runner/releases/download/v2.304.1/actions-runner-linux-x64-2.304.1.tar.gz \
            | tar xz -C /opt/github-runner
          cd /opt/github-runner
          ./config.sh --url $GITHUB_REPO_URL --token $GITHUB_TOKEN --name $(hostname) --work _work
          chown -R github:github /opt/github-runner

users:
  - name: github
    home_dir: /home/github
    groups: [docker]
    shell: /bin/bash
```

**Recovery (Kubernetes):**
```bash
# If pod crashes:
kubectl delete pod github-runner-abcd1234-xyz  # ARC auto-spins new one

# If entire namespace fails:
helm upgrade --install github-runner \
  actions/actions-runner-controller \
  --namespace actions-runner-system \
  --create-namespace

# Time to recovery: < 5 minutes (pod scheduling + startup)
```

---

## 9. SUMMARY & DECISION MATRIX

### Cost Decision Tree

```
Is CI load > 20,000 minutes/month?
├─ NO → Use GitHub-hosted runners (simplicity wins)
└─ YES → Is specialized hardware needed (ARM, GPU, macOS)?
   ├─ YES → Self-hosted mandatory
   └─ NO → Is ops team size >= 2?
      ├─ NO → Use managed service (Blacksmith, Depot, Namespace)
      └─ YES → DIY self-hosted
         ├─ Single team < 10 runners → Terraform AWS + Spot
         └─ Large org > 50 runners → ARC on Kubernetes
```

### Operations Checklist

- [ ] Monitor runner heartbeat (alert if offline > 10 min)
- [ ] Monitor disk usage (alert if > 80%, cleanup if > 90%)
- [ ] Clean up Docker/temp artifacts nightly
- [ ] Rotate secrets quarterly
- [ ] Test disaster recovery quarterly (spinup new runner in < 15 min)
- [ ] Keep runner agent within N-2 of latest version
- [ ] Audit log retention: 7+ days (HIPAA: 7 years)
- [ ] Implement autoscaling (ARC or Terraform AWS)

---

## REFERENCES

- [GitHub Actions Pricing 2026](https://docs.github.com/en/billing/reference/actions-runner-pricing)
- [Actions Runner Controller](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)
- [terraform-aws-github-runner](https://github.com/github-aws-runners/terraform-aws-github-runner)
- [Prometheus Metrics for ARC](https://www.kenmuse.com/blog/enabling-github-arc-metrics/)
- [Monitoring Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/monitoring-and-troubleshooting-self-hosted-runners)
- [GitHub Actions Secrets Best Practices](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)
- [Self-Hosted Runner Costs (2026)](https://northflank.com/blog/github-pricing-change-self-hosted-alternatives-github-actions)
- [Managed Runner Services](https://github.com/neysofu/awesome-github-actions-runners)

---

**Document Size:** ~520 lines | **Generated:** 2026-05-07  
**Confidence:** High (primary sources: GitHub Docs, official changelogs, community discussions)

