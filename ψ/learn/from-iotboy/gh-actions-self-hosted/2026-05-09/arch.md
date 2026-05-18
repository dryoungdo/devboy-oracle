# GitHub Actions Self-Hosted Runner Architecture: Comprehensive Research

## Executive Summary

GitHub Actions self-hosted runners are the application that executes jobs from GitHub Actions workflows on custom infrastructure. Written primarily in C# (96.3% of codebase) and forked from the Azure Pipelines Agent, the runner implements a sophisticated polling-based architecture with distinct Listener and Worker components that handle job acquisition, execution, result reporting, and lifecycle management.

---

## Part 1: Runner Lifecycle

### 1.1 Registration Phase

Self-hosted runners register to GitHub using a time-limited token obtained through the GitHub Actions UI:

**Token Requirements:**
- **Expiration**: Registration token expires after 1 hour
- **Scope**: Tokens are generated at repository, organization, or enterprise level
- **Acquisition**: Obtained from Settings → Actions → Runners in the GitHub UI

**Registration Process:**
1. Runner downloaded and extracted to a directory (e.g., `/opt/actions-runner`)
2. `config.sh` (Linux/macOS) or `config.cmd` (Windows) executed with URL and token
3. Configuration script authenticates with GitHub and creates `.runner` file
4. Runner agent collects system information (OS, architecture: x64/ARM/ARM64)
5. Successful registration displays: "√ Connected to GitHub" and "Listening for Jobs"

**Important Note:** The `.runner` file contains registration state. Deleting it allows re-registration without redownloading the runner software, useful for recovering from failed configurations.

**Source:** https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners

### 1.2 Polling Architecture (Listener Component)

The **Listener** is the core polling engine and entry point for every GitHub Actions job. It implements a sophisticated polling mechanism:

**Long-Polling Mechanism:**
- Listener establishes an HTTPS connection to GitHub's **Broker API**
- Maintains a "keep-alive" long-poll connection that the server holds open up to **50 seconds**
- When no jobs available, server returns empty body with `202 Accepted` status
- Listener loops continuously until a job is received

**Job Acquisition Workflow:**
1. Listener sends poll request to GitHub Actions Broker Service
2. Broker holds request open (max 50 seconds) waiting for job availability
3. If job available, Broker responds with job message containing:
   - Job ID
   - Runner request ID  
   - Service URL for fetching full job details
   - Planid (required for subsequent operations)
4. Listener retrieves complete job details using planId

**Historical Note:** Prior to 2024, runners polled Azure DevOps APIs. GitHub migrated to its own Broker API with different request/response formats.

**Lock Renewal (Heartbeat):**
- Every 60 seconds, listener sends heartbeat to renew job lock
- Prevents server from timing out and canceling the job
- Continues until job completes or is canceled
- Critical for long-running jobs

**Source:** https://depot.dev/blog/github-actions-runner-architecture-part-1-the-listener

### 1.3 Job Execution Phase (Worker Component)

The **Worker** component executes job commands after listener acquires a job:

**Two-Process Architecture:**
- **Listener process**: Handles communication with GitHub, polling, job acquisition
- **Worker process**: Executes job steps, runs actions, manages workspace

**Execution Flow:**
1. Listener acquires job and passes to Worker
2. Worker clones repository using checkout action
3. Worker downloads and caches all required Actions
4. Worker executes each job step sequentially
5. Worker captures stdout/stderr and uploads logs to GitHub
6. Worker reports job completion status back through Listener

### 1.4 Result Reporting and Deregistration

**Result Upload:**
- Job logs uploaded to GitHub after step execution
- Exit codes and step status transmitted to GitHub
- Job completion status (success/failure/cancelled) reported

**Temporary Deactivation vs. Permanent Removal:**
- **Offline State**: Stop runner application → runner marked "Offline" in UI but remains registered
  - Restart runner → automatically resumes (no re-download needed)
  - Useful for maintenance without losing registration
- **Permanent Removal**: Execute removal script with time-limited token
  - Removes runner from GitHub
  - Deletes configuration files
  - Uninstalls configured services

**Automatic Cleanup:**
- Standard persistent runners: Auto-remove after 14+ days without connecting
- Ephemeral runners: Auto-remove after 1+ day without connecting
- Just-in-time (JIT) runners: Auto-remove if never execute any jobs

**Source:** https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/removing-self-hosted-runners

---

## Part 2: Persistent vs. Ephemeral/Just-In-Time Runners

### 2.1 Persistent (Durable) Runners

**Characteristics:**
- Runner remains active after executing each job
- Can process multiple jobs sequentially over time
- Stays registered in GitHub UI even when offline
- Single runner instance handles 1 job at a time (not concurrent)

**When to Use:**
- Company has stable infrastructure investment (bare metal, long-lived VMs)
- Cost optimization desired (infrastructure already paid for)
- Specific tooling/dependencies need to be installed and maintained
- Low-latency job startup important (no provisioning overhead)
- Jobs have state from previous runs they depend on

**Limitations:**
- Requires manual OS patching and updates
- Accumulates state/cache between jobs (can cause contamination)
- Infrastructure costs borne entirely by company
- Scaling requires manual provisioning

### 2.2 Ephemeral Runners (Single-Job Runners)

**Characteristics:**
- Runner processes exactly 1 workflow job then terminates
- New runner instance created per job
- Auto-deregisters after job completion or timeout
- Provides fresh environment for each job

**When to Use:**
- Multi-tenant CI/CD environments (strong isolation required)
- Unpredictable workload (cost scales with usage, not idle capacity)
- Container orchestration platform available (Kubernetes, Docker Swarm)
- Job isolation critical for security
- Want to avoid state accumulation and cache pollution

**Benefits:**
- **Isolation**: Each job runs in completely fresh environment
- **Security**: No data leakage between jobs in multi-tenant scenarios
- **Scalability**: Automatically scale compute to match demand
- **Cost Efficiency**: Only pay for compute consumed, no idle runners

**Example Autoscaling Scenario:**
```
Job enqueued → GitHub webhook notifies orchestrator
→ Orchestrator provisions new runner
→ Runner registers via JIT token (no GitHub UI registration needed)
→ Runner receives job
→ Job completes or times out
→ Runner deregisters and pod/container destroyed
```

### 2.3 Just-In-Time (JIT) Configuration Tokens

Ephemeral runners use JIT tokens instead of traditional registration tokens:

- **REST API Generated**: Created programmatically via GitHub API
- **Short-lived**: Minimal validity window
- **Single-use**: Tokens consumed during runner registration
- **Eliminates Registration**: No advance runner registration in GitHub UI needed

Used by Actions Runner Controller (ARC) and other autoscaling platforms to dynamically register runners without manual GitHub UI steps.

**Source:** https://github.blog/changelog/2021-09-20-github-actions-ephemeral-self-hosted-runners-new-webhooks-for-auto-scaling/

---

## Part 3: Runner Platforms and Architecture

### 3.1 Supported Operating Systems

Self-hosted runners officially support three platforms:

| OS | Status | Service Type | Notes |
|---|---|---|---|
| **Linux** (Ubuntu 20.04+, CentOS 7+, RHEL 7+) | Full support | systemd service | Most common platform; good Docker support |
| **macOS** (10.15+) | Full support | launchd service | Required for iOS/macOS builds; higher resource requirements |
| **Windows** (2016+, including Server Core) | Full support | Windows Service | PowerShell/Batch scripts; different path syntax |

### 3.2 Supported Architectures

Runners execute on multiple CPU architectures:

| Architecture | Default Label | Notes |
|---|---|---|
| **x64** (Intel/AMD 64-bit) | `x64` | Most common; full tool support |
| **ARM** (32-bit) | `arm` | Limited third-party tool support |
| **ARM64** (64-bit) | `arm64` | Growing support; useful for Raspberry Pi, Apple Silicon, AWS Graviton |

Runner automatically detects architecture on startup and assigns appropriate label.

**GitHub-Hosted vs Self-Hosted Comparison:**
- GitHub-hosted: Only x64 Ubuntu, Windows, macOS available
- Self-hosted: Can run on any architecture including edge devices

**Source:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions

### 3.3 Containerization Models

#### Docker-in-Runner (Runner Runs Native, Docker Available)

**Setup:**
- Runner installed natively on OS
- Docker daemon installed alongside runner
- Runner has access to docker binary via inherited PATH

**Configuration:**
```bash
# Install runner on native Linux VM
./config.sh --url <repo> --token <token>

# Install Docker on same machine
sudo apt-get install docker.io
sudo usermod -aG docker runner-user
```

**Job Usage:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    container:
      image: node:18
```

**Advantages:**
- Simple architecture
- Docker images cached on runner between jobs
- No nested virtualization overhead

**Disadvantages:**
- Runner and job code run on same OS
- Docker socket access can be security risk if not carefully managed

#### Runner-in-Docker (Runner Container Image)

**Setup:**
- Runner packaged as OCI container image
- Image deployed to container orchestration (Kubernetes, Docker Compose, Docker Swarm)
- Container orchestrator manages runner lifecycle

**Minimal GitHub Image:**
```dockerfile
FROM ubuntu:22.04
COPY --from=ghcr.io/actions/actions-runner /home/runner /home/runner
WORKDIR /home/runner
ENTRYPOINT ["/home/runner/run.sh"]
```

**Orchestration Examples:**
- **Kubernetes**: Actions Runner Controller (ARC) manages scale sets
- **Docker Swarm**: Multiple replicas of runner container
- **Docker Compose**: Simple multi-container runner setup

**Advantages:**
- Ephemeral by nature (container destroyed after job)
- Kubernetes-native autoscaling
- Consistent environment across deployments
- Cloud-agnostic

**Disadvantages:**
- Additional complexity (need container orchestration)
- Less mature than persistent runners

#### Docker-in-Docker (DinD) Mode

**Setup:**
- Docker daemon runs inside runner container
- Runner container has access to docker binary
- Two-level Docker architecture: host docker → runner docker → job docker

**How It Works:**
```
Host Machine
├── Docker Engine (host daemon)
│   └── Runner Container
│       ├── Docker daemon (inner/guest daemon)
│       └── Job containers
```

**Challenges:**
- **Resource Overhead**: Two dockerd processes consume CPU/memory
- **Image Cache Isolation**: Each runner maintains separate image cache
  - Images pulled in one runner unavailable to others
  - Leads to redundant pulls and wasted bandwidth
- **Security**: Nested containers have weaker isolation
- **Performance**: Nested virtualization adds latency

**Better Alternative: Sysbox Runtime**
- Provides lightweight per-container virtualization
- Isolated dockerd without nested VM overhead
- Images pulled in one runner isolated from others but containers can coexist safely

**Source:** https://myoung34/docker-github-actions-runner | https://deepwiki.com/actions-runner-controller/runner-images/4.2-docker-in-docker-mode

---

## Part 4: Job Execution Model

### 4.1 Workspace and Directory Structure

**Workspace Directory (`github.workspace`):**
- **Purpose**: Repository code checked out here; default working directory for steps
- **Location**: Configured during `config.sh` setup
- **Variable**: `${{ github.workspace }}` in workflow or `$GITHUB_WORKSPACE` in shell steps
- **Typical Path**: `/home/runner/work/repo-name/repo-name`

**RUNNER_TEMP Directory:**
- **Purpose**: Temporary files for current job
- **Lifespan**: Cleaned up after job completes
- **Variable**: `${{ runner.temp }}` or `$RUNNER_TEMP`
- **Access**: Used by actions and scripts for temporary state

**Directory Structure Example (Linux):**
```
/opt/actions-runner/              # Runner application directory
├── bin/                          # Runner binaries (Run.exe, RunnerService.exe)
├── externals/                    # Third-party dependencies
├── actions/                      # Downloaded actions cache
├── _work/                        # Current job workspace
│   ├── repo-name/
│   │   └── repo-name/            # Repository clone
│   └── _temp/                    # Temporary files (RUNNER_TEMP)
├── .runner                       # Configuration state file
└── .env                          # Runner environment variables
```

### 4.2 Action Download and Cache

**Action Discovery:**
1. Runner parses all action references in job steps
2. Identifies owner, repo, and version (branch/tag/SHA)
3. If version is not SHA (e.g., `v2.5`), resolves to commit SHA

**Action Download Sequence:**
```
1. Check actions cache directory
2. If cached and hash matches → reuse cached action
3. If not cached or hash mismatches → download from GitHub
4. Extract to actions subdirectory
5. Cache for future jobs
```

**Actions Archive Cache:**
- **Purpose**: Avoid re-downloading actions used across multiple jobs
- **Location**: `<runner-root>/actions/` directory on self-hosted runner
- **Sharing**: Persistent runners share cache across jobs; ephemeral runners start fresh
- **Benefit**: Significant time savings for frequently-used actions (setup-node, setup-python, etc.)

**Source:** https://depot.dev/blog/github-actions-runner-architecture-part-1-the-listener | https://www.kenmuse.com/blog/building-github-actions-runner-images-with-an-action-archive-cache/

### 4.3 npm/pip Cache Placement

**Setup Actions with Automatic Caching:**
- `actions/setup-node`: Automatically caches npm/yarn/pnpm
- `actions/setup-python`: Automatically caches pip/Poetry dependencies
- `actions/setup-java`: Automatically caches Maven/Gradle

**Manual Caching with Actions/cache:**
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

**Cache Behavior on Self-Hosted Runners:**
- **Persistent runners**: Cache persists between jobs if path not cleaned
- **Ephemeral runners**: Cache lost after job (container destroyed)
- **Cross-OS Cache**: Windows runner cache cannot be used by Linux runner (unless `enableCrossOsArchive: true`)

**Cache Storage Limits (per repository):**
- **Total limit**: 10 GB per repository
- **Retention**: Minimum 7 days of access required (older caches auto-deleted)
- **Rate limits**: 200 uploads/min, 1500 downloads/min per repo

**Source:** https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows

### 4.4 Environment Variables and Contexts

**Runner Context Properties:**
```yaml
${{ runner.os }}        # Linux, Windows, or macOS
${{ runner.arch }}      # X86, X64, ARM, or ARM64  
${{ runner.temp }}      # Path to runner temp directory
${{ runner.tool_cache }} # Directory with preinstalled tools (GitHub-hosted only)
${{ runner.name }}      # Runner's display name from GitHub UI
${{ runner.environment }} # github-hosted or self-hosted
```

**Variable Scope Levels (applied in order of precedence):**
1. Step-level `env:` (highest priority)
2. Job-level `env:`
3. Workflow-level `env:` (lowest priority)

Example:
```yaml
env:
  GLOBAL_VAR: workflow_value
jobs:
  build:
    env:
      GLOBAL_VAR: job_value
    steps:
      - run: echo $GLOBAL_VAR  # Prints "job_value" (job env overrides workflow env)
        env:
          GLOBAL_VAR: step_value
          # Output would print "step_value" (step env overrides job env)
```

**Source:** https://docs.github.com/en/actions/learn-github-actions/contexts

---

## Part 5: Job Dispatch and Routing

### 5.1 Default Labels

Every self-hosted runner automatically receives default labels:

```
self-hosted      # Identifies as self-hosted (vs github-hosted)
linux            # Operating system: linux, windows, or macos
x64              # Architecture: x64, arm, or arm64
```

**Combining in Workflow:**
```yaml
runs-on: [self-hosted, linux, x64]
# OR shorthand
runs-on: self-hosted
```

### 5.2 Custom Labels

Labels enable fine-grained job routing to specific runner capabilities:

**Assignment Methods:**

*During initial configuration:*
```bash
./config.sh --url <REPOSITORY_URL> \
  --token <REGISTRATION_TOKEN> \
  --labels gpu,tensorflow,cuda-12.2
```

*Via GitHub UI (after registration):*
- Navigate to Settings → Actions → Runners
- Select runner → gear icon in Labels section
- Create or assign labels

*Via REST API:*
```bash
curl -X PATCH \
  -H "Authorization: token <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"labels":["gpu","high-memory"]}' \
  https://api.github.com/repos/owner/repo/actions/runners/runner_id
```

**Label Behavior:**
- **Case-insensitive**: `GPU` and `gpu` are treated identically
- **Unused labels auto-delete**: Removed from runner after 24 hours with no references
- **Custom labels**: No validation of actual hardware (can assign `gpu` label to non-GPU runner)
- **Default labels cannot be removed**: `self-hosted`, `linux`, `x64` always present

**Usage in Workflows:**
```yaml
jobs:
  gpu_training:
    runs-on: [self-hosted, gpu, cuda-12.2]
    steps:
      - run: nvidia-smi
      
  cpu_analysis:
    runs-on: [self-hosted, linux, x64]
    steps:
      - run: python analyze.py
```

**Source:** https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-labels-with-self-hosted-runners

### 5.3 Runner Groups (Organization/Enterprise Level)

Runner groups organize runners and control access at organization or enterprise scope:

**Hierarchy:**
```
Enterprise
├── Organization A
│   ├── Default group (all org repos can access)
│   └── Custom groups (selective repo access)
└── Organization B
    └── Groups...
```

**Group Behavior:**
- **Default group**: All repositories in organization can access
- **Custom groups**: Explicitly assign which repos/workflows can use
- **Access control**: Repository, organization, and enterprise levels

**Combining Groups and Labels:**
```yaml
runs-on:
  group: ubuntu-runners
  labels: ubuntu-24.04-16core
```
Runner must satisfy **both** criteria:
1. Be in `ubuntu-runners` group
2. Have `ubuntu-24.04-16core` label

**Source:** https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-runner-groups

### 5.4 Job Dispatch Algorithm

When a job is queued:

**Matching Process:**
1. GitHub identifies all runners matching job's `runs-on` criteria:
   - Labels specified in workflow
   - Runner group (if specified)
   - Runner status (online/offline)

2. If multiple runners match:
   - GitHub **may not select oldest queued job** (unlike GitHub-hosted)
   - Selection prioritizes availability and load
   - No guaranteed FIFO ordering

3. Broker notifies matching runner via long-poll
4. Runner's Listener receives job and confirms acceptance
5. Job moves from queue to runner

**Important Note:** Job routing selection differs from traditional queue behavior. GitHub optimizes for load distribution across available runners rather than strict job age ordering.

### 5.5 Job Queueing and Capacity

**Queueing Behavior:**
- Multiple jobs can queue while runner processes current job
- Jobs wait in queue for runner availability (no timeout during queue wait)

**Concurrency Control (Workflow Level):**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel previous running job in group
```

**Concurrency Limits per Runner:**
- **Single-job execution**: One self-hosted runner processes 1 job at a time
- **No built-in parallelism**: Runner cannot split job execution across cores
- **Implicit limit**: Workflow's concurrency config controls job queueing for runner

**Handling High Load:**
- Deploy multiple runner instances with same labels
- GitHub automatically distributes jobs across available runners
- For unpredictable load, use ephemeral runners with autoscaling (ARC)

---

## Part 6: Self-Hosted vs GitHub-Hosted Runners

### 6.1 Comparison Table

| Aspect | Self-Hosted | GitHub-Hosted |
|--------|-------------|---------------|
| **OS/Architecture** | Any (x64, ARM, ARM64; Linux, macOS, Windows) | Limited (Ubuntu/Windows/macOS x64 only) |
| **Customization** | Full control; install any software | Limited; predefined environments |
| **Cost Model** | Infrastructure you maintain | Pay-as-you-go minute billing |
| **Cold Start** | Instant (machine always ready) | ~2 seconds (VM creation) |
| **State Between Jobs** | Persists (cache, installed tools) | Fresh environment each job |
| **Job Isolation** | Shared system (security consideration) | Isolated VM per job |
| **Update Control** | You manage runner version | Automatic updates by GitHub |
| **Storage** | Unlimited (your infrastructure) | 14 GB per job |
| **Network** | Direct access to private networks | Access requires tunneling (ngrok, etc.) |

### 6.2 When to Use Each

**Use Self-Hosted When:**
- Accessing private databases, internal APIs, or on-premises infrastructure
- Requiring specialized hardware (GPU, high-memory, ARM processors)
- Needing consistent environment across many jobs
- Company infrastructure already exists (amortize investment)
- Compliance/security requires air-gapped or private networks
- Building for multiple architectures (cross-compilation)

**Use GitHub-Hosted When:**
- Simple CI/CD with standard tooling
- Want minimal operational overhead
- No access to private infrastructure needed
- Cost predictable per-job (small projects)
- Security benefits of isolated VMs critical
- Horizontal scaling automatic and transparent

**Mixed Strategy:**
Many organizations use both:
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest  # GitHub-hosted, fast, standard tools
    
  integration-test:
    runs-on: [self-hosted, private-db-access]  # Self-hosted for DB access
    
  deploy:
    runs-on: [self-hosted, gpu, high-memory]  # Self-hosted for specialized hardware
```

**Source:** https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners/about-self-hosted-runners

---

## Part 7: The Runner Agent Binary

### 7.1 Location and Installation

**Default Locations (by OS):**

| OS | Typical Location | Entry Point |
|---|---|---|
| **Linux** | `/opt/actions-runner/` or `~/actions-runner/` | `/opt/actions-runner/run.sh` |
| **macOS** | `~/actions-runner/` | `~/actions-runner/run.sh` |
| **Windows** | `C:\actions-runner\` | `C:\actions-runner\run.cmd` |

**Directory Structure:**
```
<runner-root>/
├── bin/                    # Runner executable binaries
│   ├── Runner.Listener.dll (primary listener process)
│   ├── Runner.Worker.dll   (job execution worker)
│   └── run.sh/run.cmd      (platform-specific entry point)
├── externals/              # Runtime dependencies (Node.js, .NET runtime)
├── actions/                # Downloaded actions cache
├── _work/                  # Job workspaces
├── .runner                 # Configuration metadata (encrypted)
├── .credentials            # GitHub API tokens (encrypted, file permissions restrict)
└── config.sh/config.cmd    # Configuration script
```

**File Permissions Security:**
- `.credentials` and `.runner` files have restricted permissions (0600 Linux)
- Runner process must run with sufficient privileges to read these files
- Custom service user should have exclusive read access

### 7.2 Programming Language

**Runner Implementation:**
- **Primary language**: C# (96.3% of codebase)
- **Architecture**: Forked from Azure Pipelines Agent (2016 origin)
- **Runtime**: Requires .NET runtime on runner machine
- **Platform abstraction**: C# enables cross-platform Windows/Linux/macOS support
- **Minor components**: JavaScript/Node.js for some utilities

**GitHub Repository:**
- Source: https://github.com/actions/runner
- License: MIT
- Latest Release: v2.334.0+ (continuous releases, April 2026)
- Contribution Status: Closed to external contributions (security/maintenance only)

**Source:** https://github.com/actions/runner

### 7.3 Automatic Updates

**Update Mechanism:**
- Runner checks for new versions during startup (low overhead)
- If new version available, runner downloads and installs
- Installation typically takes 5-10 seconds
- Runner automatically restarts with new version
- Current job **not interrupted** (update happens between jobs)

**Update Behavior:**
- **Automatic**: Enabled by default; no configuration needed
- **Non-blocking**: Update occurs between job acquisitions
- **Rollback**: If new version fails, reverts to previous version
- **Pinning**: GitHub Enterprise can pin runner versions for consistency

**Frequency:**
- Monthly to quarterly releases typically
- Security patches can be released immediately
- All updates backwards compatible (data schema preserved)

**No Version Lock Mechanism:**
- Unlike GitHub-hosted runners, self-hosted cannot enforce minimum version
- Recommend periodic manual update checks
- Can be built into CI/CD monitoring

---

## Part 8: Authentication and Polling Flow

### 8.1 Registration Token Authentication

**Token Lifecycle:**

```
1. User requests registration token from GitHub UI/API
   ↓ Expires after 1 hour
2. User runs: ./config.sh --url <repo> --token <TOKEN>
   ↓
3. config.sh sends HTTP request with token to GitHub API
   ↓
4. GitHub validates token and returns credentials
   ↓
5. config.sh stores credentials locally in encrypted .credentials file
   ↓
6. Future runner invocations read .credentials (not token)
   ↓
7. Listener uses credentials for all subsequent communication
```

**Stored Credentials:**
- **Format**: Encrypted in `.credentials` file (AES encryption)
- **Content**: GitHub API bearer token + runner ID
- **Scope**: Limited to registered runner actions only
- **Lifespan**: Valid until runner deregistered

### 8.2 HTTPS Long-Polling Authentication

**Long-Poll Connection:**

```
Listener (on self-hosted runner)
    │
    ├─ Reads .credentials file
    ├─ Extracts bearer token
    │
    └─→ HTTPS to GitHub Broker API
        ├─ Authorization: Bearer <token>
        ├─ Connection: Keep-Alive
        ├─ Timeout: 50 seconds server-side
        │
        ├─ [No job] → 202 Accepted (empty body)
        │            → Loop and reconnect
        │
        └─ [Job available] → 200 OK + Job details
                             → Process job
                             → Renew connection
```

**Security Features:**
- **Mutual TLS**: Modern runners support certificate pinning
- **Token rotation**: Periodically generated new tokens (internal to GitHub)
- **Network isolation**: Can be used with HTTP proxies and certificate interception
- **Rate limiting**: GitHub monitors for suspicious patterns

### 8.3 Webhook-Based Notification (Alternative)

While self-hosted runners use polling, GitHub Actions can trigger workflows via webhooks:

**Webhook Events Supported:**
- `push`, `pull_request`, `release`, `issues`, `workflow_dispatch`, etc.
- Webhook URL delivery independent of runner polling
- Triggers job queuing; runner polling retrieves job

**Not Currently Supported for Runners:**
- Webhook-triggered runner provisioning (coming feature)
- Runners still poll for jobs; webhooks trigger job creation only

**Source:** https://github.com/orgs/community/discussions/9752

---

## Part 9: Limits and Constraints

### 9.1 Job Execution Limits

**Job Timeout:**
- **Default**: 360 minutes (6 hours)
- **Maximum**: 360 minutes (cannot be extended)
- **Minimum**: Configurable down to 1 minute
- **Applies to**: Both GitHub-hosted and self-hosted

**Step Timeout:**
- **Default**: 360 minutes (same as job)
- **Per-step control**: `timeout-minutes: 5` in step configuration
- **Enforcement**: GitHub-side timeout (runner cannot override)

**Job Concurrency per Runner:**
- **Single job at a time**: Each runner processes exactly 1 job
- **No built-in parallelism**: Cannot split job across cores/threads
- **Scaling method**: Deploy multiple runner instances for parallel jobs

**Example Concurrency Limit:**
```
4 deployed runners with label "standard"
Up to 4 jobs can run in parallel (1 job each)
5th job queues and waits for any runner to finish
```

**Source:** https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration

### 9.2 Runner Version Requirements

**Minimum Supported Version:**
- GitHub maintains backward compatibility for 1-2 years
- Older versions eventually become unsupported
- Self-hosted runners can run older versions (unlike GitHub-hosted)

**Version Pinning (Enterprise Feature):**
- GitHub Enterprise admins can enforce minimum/maximum versions
- Organization owners cannot pin versions
- Repository owners cannot pin versions

**Version Compatibility:**
- Workflow files valid for years
- Runner agent forwards compatible with multiple GitHub API versions
- Ensure at least monthly runner version updates

### 9.3 Runner Capacity and Concurrency

**Unlimited Job Count:**
- "You can run an unlimited number of jobs as long as you are within the workflow usage limits" (GitHub docs)
- Actual limit is hardware capacity of runner machine

**Practical Limits (Self-Hosted):**
- **CPU cores**: Most limiting factor for parallel job execution (deploy multiple runners)
- **Memory**: Job containers/processes may exceed available RAM (OS swaps, then OOM kill)
- **Disk**: Workspace accumulation, cache growth, temporary files
- **Network**: Bandwidth for action downloads, log uploads

**Disk Management Best Practice:**
- Run periodic disk cleanup between jobs
- Archive/rotate old workspace directories
- Monitor cache directory growth (especially with DinD)
- For persistent runners, add cron job:
```bash
# Clean up workspaces older than 7 days
find /opt/actions-runner/_work -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
```

### 9.4 Runner Limits Summary Table

| Limit | Value | Notes |
|-------|-------|-------|
| Job timeout | 360 min | Absolute maximum |
| Concurrent jobs per runner | 1 | Design constraint |
| Default registration token life | 1 hour | Must complete config within window |
| Offline runner cleanup | 14 days | Persistent runners |
| Ephemeral runner cleanup | 1 day | Isolated runners |
| JIT token expiration | ~24 hours | Typical; orchestrator-configured |
| Cache per repository | 10 GB | Soft limit; LRU deletion |
| Artifacts per job | ~500 MB | GitHub-hosted; self-hosted unlimited |

---

## Part 10: Repository vs. Organization vs. Enterprise Level Runners

### 10.1 Scope Hierarchy

```
GitHub Instance
├── Enterprise (top level)
│   ├── Organization A
│   │   ├── Repository A-1 (can access org runners + enterprise runners)
│   │   └── Repository A-2
│   └── Organization B
│
└── Organization C (non-enterprise)
    ├── Repository C-1
    └── Repository C-2
```

### 10.2 Repository-Level Runners

**Scope:**
- Only workflows in that specific repository can access
- Cannot be shared with other repositories

**Access Control:**
- Repository owner can add/remove runners
- Any repository collaborator can trigger workflows that use runners
- No cross-repo access possible

**Use Cases:**
- Single-tenant projects
- Highly sensitive infrastructure (deploy credentials, production access)
- Small teams with isolated projects

**Configuration:**
```yaml
runs-on: [self-hosted]  # Uses any self-hosted runner in this repo
```

### 10.3 Organization-Level Runners

**Scope:**
- Accessible to all repositories within the organization
- Cannot be shared across organizations

**Access Control:**
- Organization owner can add/remove runners
- Organization policy controls which repos can use runners
- Runner groups enable fine-grained access (some repos → some runners)

**Runner Groups (Organization):**
```
Default group → all repos in org can use
Custom "production" group → only "repo-deploy", "repo-infra" can use
Custom "testing" group → all repos except those with deploy credentials
```

**Use Cases:**
- Multi-project organizations with shared infrastructure
- Cost amortization across many projects
- Consistent tooling across org repositories

**Configuration:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]  # From any org runner matching labels
```

### 10.4 Enterprise-Level Runners

**Scope (Requires Enterprise Account):**
- Accessible to organizations and repositories across enterprise
- Shared infrastructure at enterprise level

**Access Control:**
- Enterprise admin can add/remove runners
- Organization owners inherit access to enterprise runners
- Organization-level groups override enterprise groups
- Repository-level runners still isolated (cannot access org/enterprise)

**Hierarchy:**
```
Enterprise owns runner "gpu-cluster"
  ├─ Org A can use via default permissions
  │   └─ Repo A-1 can restrict/allow in org group settings
  ├─ Org B can use
  └─ Org C can restrict in org group
```

**Use Cases:**
- Very large enterprises with 50+ organizations
- Expensive hardware (GPUs, high-memory) shared across org boundaries
- Centralized infrastructure team managing compute
- Cross-org CI/CD pipelines (less common)

**Configuration (Same for Repos):**
```yaml
runs-on: [self-hosted, enterprise-gpu]  # Accesses enterprise runner pool
```

### 10.5 Access Control Comparison

| Level | Who Can Add | Who Can Use | Scope | Groups? |
|-------|------------|-----------|-------|---------|
| **Repository** | Repo owner | Same repo only | Single repo | No |
| **Organization** | Org owner | All org repos | Organization | Yes |
| **Enterprise** | Enterprise admin | All enterprises + orgs | Enterprise | Yes (org overrides) |

**Important Notes:**
- Organization runners visible/accessible to all repositories (cannot restrict at repo level, only org groups)
- Repository owners cannot restrict which runners their repo uses (set in workflow, org must control with groups)
- Enterprise runners automatically available to all orgs (can be restricted at org group level)

---

## Part 11: Actions Runner Controller (ARC) for Kubernetes

For organizations running self-hosted runners at scale, especially ephemeral runners:

### 11.1 ARC Architecture

**Components:**

```
GitHub API
    │
    ├─→ ARC Manager Pod (in Kubernetes)
    │   ├─ AutoScalingRunnerSet controller
    │   ├─ Runner scale set listener
    │   └─ Webhook server
    │
    ├─→ Kubernetes Cluster
    │   ├─ Persistent runner pods (long-lived)
    │   └─ Ephemeral runner pods (1 job then delete)
    │
    └─→ GitHub Actions Service
        (notifies of job availability)
```

**Key Components:**
- **AutoScalingRunnerSet Controller**: Watches GitHub for job queues, scales pod replicas
- **Runner Scale Set Listener**: HTTPS connection to GitHub (like individual Listener)
- **Ephemeral RunnerSet**: Creates temporary pods per job
- **JIT Token Manager**: Generates just-in-time tokens for ephemeral runner registration

### 11.2 Deployment Flow

```
1. Org deploys ARC Helm chart to Kubernetes cluster
2. ARC creates AutoScalingRunnerSet resources:
   - Namespace: actions-runner-system
   - ConfigMap: runner image, JIT token config
   - Service: for GitHub webhook notifications
   
3. Workflow job triggered
4. GitHub notifies ARC via webhook (or ARC polls)
5. AutoScalingRunnerSet scales up runner pods
6. Ephemeral pods request JIT configuration token
7. Pods register with GitHub using JIT token
8. Pods receive jobs and execute
9. After job completion:
   - Persistent pods: stay running for next job
   - Ephemeral pods: self-destruct

10. ARC scales down unused pods
11. Cleanup: pods unregister from GitHub, k8s deletes pod
```

### 11.3 Benefits of ARC

- **Kubernetes-native**: Integrates with existing k8s infrastructure
- **Cost efficient**: Ephemeral runners only exist during job execution
- **Auto-scaling**: Respects Kubernetes HPA rules
- **JIT provisioning**: No advance runner registration needed
- **Reference implementation**: Endorsed by GitHub

**Source:** https://docs.github.com/en/actions/concepts/runners/actions-runner-controller

---

## Part 12: Troubleshooting and Monitoring

### 12.1 Log Locations

**Linux/macOS:**
```
~/.runner-logs/
├── Runner_YYYY-MM-DD-HH.log      # Listener logs
└── Worker_YYYY-MM-DD-HH.log      # Job execution logs
```

**Windows:**
```
C:\actions-runner\_diag\
├── Runner_*.log                  # Listener logs
└── Worker_*.log                  # Job execution logs
```

**Monitoring:**
- `Listener` logs: Connection issues, job acquisition, polling errors
- `Worker` logs: Step execution, action download, environment setup
- Both append to same hourly file; old logs retained for debugging

### 12.2 Common Issues

**"Offline" Status:**
- Runner process not running
- Network connectivity lost
- GitHub API unreachable
- **Fix**: Restart runner service, check network/firewall

**Long Job Wait in Queue:**
- No runners match job's `runs-on` labels
- All runners busy (processing previous jobs)
- **Fix**: Add new runner with matching labels, scale runners

**Action Download Failures:**
- Network timeout fetching action from GitHub
- Disk full (actions cache location)
- **Fix**: Check disk space, verify network, retry job

**Docker-in-Runner Issues:**
- Docker socket permissions (non-root runner user)
- Docker daemon not running
- **Fix**: `sudo usermod -aG docker runner-user`, restart docker

---

## Conclusion

GitHub Actions self-hosted runners provide sophisticated, production-grade job execution infrastructure with flexible deployment options ranging from simple persistent runners to complex ephemeral Kubernetes-based autoscaling. The polling-based architecture ensures efficient resource utilization, while support for custom labels, runner groups, and multi-level scoping provides fine-grained control over job routing and access. Organizations should carefully evaluate persistent vs. ephemeral models based on infrastructure investment, cost structure, and isolation requirements.

Key architectural decisions include:
1. **Persistent vs. Ephemeral**: Cost/isolation tradeoff
2. **Native vs. Containerized**: Operational complexity vs. consistency
3. **Scaling method**: Manual, ARC, or other orchestrator
4. **Scope level**: Repository, organization, or enterprise
5. **Platform/architecture**: x64 vs. ARM; Linux vs. others

The runner binary (C#-based, auto-updating) handles registration, polling, job execution, and result reporting transparently, allowing teams to focus on workflow definition rather than infrastructure details.

---

## References and Sources

- [GitHub Actions Self-Hosted Runners Docs](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Self-Hosted Runners Reference](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [GitHub Actions Runner Repository (C# source)](https://github.com/actions/runner)
- [GitHub Actions Runner Architecture: The Listener - Depot](https://depot.dev/blog/github-actions-runner-architecture-part-1-the-listener)
- [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)
- [Using Labels with Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-labels-with-self-hosted-runners)
- [Caching Dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Container Images in Workflows](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container)
- [Ephemeral Self-Hosted Runners](https://github.blog/changelog/2021-09-20-github-actions-ephemeral-self-hosted-runners-new-webhooks-for-auto-scaling/)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Docker GitHub Actions Runner Community Project](https://github.com/myoung34/docker-github-actions-runner)
- [Configuring Runners as Services](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service)

