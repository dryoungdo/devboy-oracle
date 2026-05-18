# GitHub Actions Self-Hosted Runner Setup Recipes

Comprehensive guide for deploying runners across 8 architectures. Each recipe includes exact commands, configuration files, and explanatory notes. **Start with Recipe 1 (bare-metal systemd) for your first runner.**

---

## Recipe 1: Bare Metal Linux (Ubuntu 24.04) — systemd Service

**RECOMMENDED: Start here for your first runner.** This is the simplest, most reliable setup.

### Prerequisites
- Ubuntu 24.04 LTS server (physical or VM)
- Non-root user with sudo access
- Internet connectivity
- ~4GB RAM minimum, 2 CPU cores

### Step 1: System Setup
```bash
# Log in as non-root user. Create dedicated runner user:
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG sudo github-runner

# Install dependencies
sudo apt-get update && sudo apt-get install -y \
  curl jq build-essential libssl-dev libffi-dev python3-dev \
  libicu-dev python3-venv docker.io git

# Add runner user to docker group (optional, for container builds)
sudo usermod -aG docker github-runner

# Create runner directory
sudo mkdir -p /opt/actions-runner
sudo chown github-runner:github-runner /opt/actions-runner
```

### Step 2: Download & Extract Runner
```bash
cd /opt/actions-runner
sudo -u github-runner bash -c '
  RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".tag_name" | sed "s/v//")
  curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
  tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
  rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
'
```

### Step 3: Configure Runner
Generate a Personal Access Token (PAT) or GitHub App with admin:org scope on GitHub. Then:

```bash
cd /opt/actions-runner
sudo -u github-runner bash -c '
  ./config.sh \
    --url https://github.com/YOUR_ORG \
    --token YOUR_PAT_TOKEN \
    --name ubuntu-runner-01 \
    --work _work \
    --labels ubuntu-24.04,docker,linux \
    --runnergroup "default" \
    --unattended \
    --replace
'
```

**config.sh flags explained:**
- `--url`: Organization or repository URL
- `--token`: Short-lived registration token (expires after 1 hour)
- `--name`: Display name in GitHub Actions
- `--labels`: Comma-separated custom labels (referenced in workflows)
- `--work`: Working directory for job artifacts
- `--ephemeral`: Auto-remove runner after single job (optional flag)
- `--unattended`: Skip interactive prompts
- `--replace`: Overwrite existing config if present

### Step 4: Install systemd Service

Create systemd unit file:

```bash
sudo tee /etc/systemd/system/actions-runner.service > /dev/null << 'EOF'
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=github-runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=always
RestartSec=5
SyslogIdentifier=actions-runner
StandardOutput=journal
StandardError=journal

# Security & isolation
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/actions-runner

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable actions-runner
sudo systemctl start actions-runner

# Verify
sudo systemctl status actions-runner
sudo journalctl -u actions-runner -f  # Follow logs
```

### Step 5: Enable Ephemeral Mode (Optional)

For auto-cleanup after each job, reconfigure:
```bash
cd /opt/actions-runner
sudo -u github-runner ./config.sh \
  --url https://github.com/YOUR_ORG \
  --token YOUR_NEW_PAT_TOKEN \
  --ephemeral \
  --replace
```

Restart service:
```bash
sudo systemctl restart actions-runner
```

### Use in Workflow

```yaml
name: Test on Self-Hosted
on: [push]

jobs:
  build:
    runs-on: [self-hosted, linux, ubuntu-24.04]  # Matches labels
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on custom runner"
```

**Troubleshooting:**
- Check service logs: `sudo journalctl -u actions-runner -n 50`
- Manual test: `cd /opt/actions-runner && ./run.sh`
- Verify token: Tokens expire after 1 hour; regenerate if config fails
- Runner not appearing: Allow 30-60 seconds for registration, then refresh GitHub Actions settings page

---

## Recipe 2: Docker-Based Runner (Single Container)

**Use when:** You want isolation, reproducible environments, or temporary runners.

### Prerequisites
- Docker daemon running on host
- 2GB+ available disk for image
- PAT token with admin:org scope

### Step 1: docker-compose.yml

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  runner:
    image: myoung34/docker-github-actions-runner:latest
    container_name: github-actions-runner
    environment:
      # Authentication (choose ONE method)
      GITHUB_TOKEN: ${GITHUB_TOKEN}
      # OR
      # GITHUB_PAT: ${GITHUB_PAT}
      # OR (for GitHub App)
      # GITHUB_APP_ID: ${GITHUB_APP_ID}
      # GITHUB_APP_INSTALLATION_ID: ${GITHUB_APP_INSTALLATION_ID}
      # GITHUB_APP_PRIVATE_KEY: ${GITHUB_APP_PRIVATE_KEY}

      # Runner configuration
      REPO_URL: https://github.com/YOUR_ORG/YOUR_REPO
      RUNNER_NAME: docker-runner-01
      RUNNER_NAME_PREFIX: ""  # empty = use RUNNER_NAME, or set prefix for suffix
      RUNNER_WORKDIR: /tmp/runner-work
      RUNNER_GROUP: "default"
      
      # Labels
      RUNNER_LABELS: docker,ubuntu-24.04,container
      
      # Behavior
      EPHEMERAL: "false"         # Set to "true" for single-job runners
      DISABLE_AUTO_UPDATE: "false"
      
    volumes:
      # Mount Docker socket for docker-in-docker
      - /var/run/docker.sock:/var/run/docker.sock:rw
      # Persistent work directory
      - runner-work:/tmp/runner-work
    
    restart: unless-stopped
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

volumes:
  runner-work:
    driver: local
```

### Step 2: Launch Runner

```bash
# Set environment
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx  # your PAT
docker-compose up -d

# View logs
docker-compose logs -f

# Verify registration (GitHub Actions > Settings > Runners)
```

### Step 3: Multiple Runners via docker-compose (Optional)

Scale horizontally:

```yaml
version: '3.8'
services:
  runner:
    image: myoung34/docker-github-actions-runner:latest
    environment:
      GITHUB_TOKEN: ${GITHUB_TOKEN}
      REPO_URL: https://github.com/YOUR_ORG/YOUR_REPO
      RUNNER_NAME_PREFIX: docker-runner
      RUNNER_LABELS: docker,ubuntu-24.04,container,${RUNNER_INDEX}
      EPHEMERAL: "true"
      RUNNER_WORKDIR: /tmp/runner-work
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - runner-work-${RUNNER_INDEX}:/tmp/runner-work
    restart: unless-stopped

volumes:
  runner-work-1:
  runner-work-2:
  runner-work-3:
```

Deploy 3 runners:
```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
for i in 1 2 3; do
  RUNNER_INDEX=$i docker-compose -p runner-$i up -d
done
```

**Important Notes:**
- `myoung34/docker-github-actions-runner` is community-maintained (not official)
- Docker-in-Docker works (mounts `/var/run/docker.sock`), but Job Services unavailable
- Ephemeral mode automatically deregisters runner after each job
- Token must be regenerated if runner doesn't appear (tokens expire in 1 hour)

---

## Recipe 3: Kubernetes via Actions Runner Controller (ARC)

**Use when:** You have K8s cluster (EKS, GKE, self-hosted) and need cost-efficient scaling.

### Prerequisites
- Kubernetes cluster 1.24+
- Helm 3.0+
- kubectl configured
- GitHub App or PAT token with admin:org or admin:repo scope

### Step 1: Install ARC via Helm

```bash
# Add Helm repository
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Create namespace
kubectl create namespace actions-runner-system

# Install ARC controller
helm install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set github.app.id=YOUR_APP_ID \
  --set github.app.installationId=YOUR_INSTALLATION_ID \
  --set github.app.privateKey='-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----' \
  --set authSecret.create=true
```

**Alternative: Use PAT token**

```bash
helm install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set github.token=ghp_xxxxxxxxxxxx
```

### Step 2: Create RunnerDeployment (Legacy, pre-AutoscalingRunnerSet)

File: `runner-deployment.yaml`

```yaml
apiVersion: actions.summerwind.net/v1alpha1
kind: RunnerDeployment
metadata:
  name: github-runner-deployment
  namespace: actions-runner-system
spec:
  replicas: 3
  template:
    metadata:
      labels:
        runner-type: docker
    spec:
      repository: YOUR_ORG/YOUR_REPO
      labels:
        - kubernetes
        - docker
        - ubuntu-24.04
      serviceAccountName: actions-runner
      containers:
      - name: runner
        image: myoung34/docker-github-actions-runner:latest  # or ghcr.io/actions/actions-runner:latest
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 2000m
            memory: 2Gi
        env:
        - name: DOCKER_HOST
          value: unix:///var/run/docker.sock
      volumeMounts:
      - name: docker
        mountPath: /var/run/docker.sock
      volumes:
      - name: docker
        hostPath:
          path: /var/run/docker.sock
```

Deploy:
```bash
kubectl apply -f runner-deployment.yaml
```

### Step 3: Create AutoscalingRunnerSet (Modern, Recommended)

File: `autoscaling-runner-set.yaml`

```yaml
apiVersion: actions.github.io/v1alpha1
kind: AutoscalingRunnerSet
metadata:
  name: github-runner-autoscaling
  namespace: actions-runner-system
spec:
  # Target for runners
  githubConfigUrl: https://github.com/YOUR_ORG/YOUR_REPO
  
  # GitHub authentication (stored in secret created by Helm)
  githubConfigSecret:
    name: controller-manager-github-app-credentials
    key: github_app_private_key
  
  # Scaling configuration
  replicas: 2  # Minimum runners
  maxRunners: 10  # Maximum runners for autoscaling
  minRunners: 1  # Minimum runners (can scale to 0)
  
  # Scale-up strategy: runners pending jobs
  # Scale-down: cron-based or idle threshold
  scaleDownDelaySecondsAfterLastJob: 300  # 5 min
  
  # Runner labels
  labels:
    - kubernetes
    - docker
    - autoscaled
  
  # Pod template
  template:
    metadata:
      labels:
        app: runner
    spec:
      # Runner container
      containers:
      - name: runner
        image: ghcr.io/actions/actions-runner:latest
        resources:
          requests:
            cpu: 1000m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 2Gi
        volumeMounts:
        - name: docker
          mountPath: /var/run/docker.sock
      
      # Docker-in-Docker support
      volumes:
      - name: docker
        hostPath:
          path: /var/run/docker.sock
      
      # Security
      serviceAccountName: actions-runner
      securityContext:
        runAsUser: 1000
        fsGroup: 1000
```

Deploy:
```bash
kubectl apply -f autoscaling-runner-set.yaml

# Monitor pods
kubectl get pods -n actions-runner-system
kubectl logs -n actions-runner-system -f deployment/actions-runner-controller
```

### Scaling Triggers

AutoscalingRunnerSet automatically scales based on:
- **Scale UP**: Workflow jobs queued & no idle runners
- **Scale DOWN**: No pending jobs for 5 min (configurable)
- **Max runners**: Hard limit to prevent runaway costs

### Step 4: Use in Workflow

```yaml
jobs:
  build:
    runs-on: [self-hosted, kubernetes, docker]
    steps:
      - uses: actions/checkout@v4
      - run: kubectl cluster-info  # K8s API available in pod
```

**Cleanup:**
```bash
kubectl delete namespace actions-runner-system
helm uninstall actions-runner-controller -n actions-runner-system
```

---

## Recipe 4: macOS Runner (for iOS/Notarization Builds)

**Use when:** Building/signing iOS apps, macOS binaries, or using Xcode.

### Prerequisites
- macOS 12+ (Intel or Apple Silicon)
- 6GB+ free disk, 4GB RAM
- Xcode Command Line Tools: `xcode-select --install`
- Code-signing certificate + provisioning profile

### Step 1: Download & Extract Runner

```bash
# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Determine architecture
ARCH=$(uname -m)  # arm64 (Apple Silicon) or x86_64 (Intel)

# Download latest runner
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".tag_name" | sed "s/v//")

curl -o actions-runner-osx-${ARCH}-${RUNNER_VERSION}.tar.gz \
  -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-${ARCH}-${RUNNER_VERSION}.tar.gz

tar xzf actions-runner-osx-${ARCH}-${RUNNER_VERSION}.tar.gz
rm actions-runner-osx-${ARCH}-${RUNNER_VERSION}.tar.gz
```

### Step 2: Configure Runner

```bash
cd ~/actions-runner

./config.sh \
  --url https://github.com/YOUR_ORG \
  --token YOUR_PAT_TOKEN \
  --name macos-runner-01 \
  --labels macos,xcode,ios,notarization,${ARCH} \
  --unattended \
  --replace
```

### Step 3: Install & Configure launchd Plist

Create plist file (run as root to store in /Library/LaunchDaemons):

```bash
sudo bash -c 'cat > /Library/LaunchDaemons/com.github.actions-runner.plist << '\''EOF'\''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.github.actions-runner</string>
  
  <key>ProgramArguments</key>
  <array>
    <string>~/actions-runner/run.sh</string>
  </array>
  
  <key>RunAtLoad</key>
  <true/>
  
  <key>StandardOutPath</key>
  <string>/var/log/github-actions-runner.log</string>
  
  <key>StandardErrorPath</key>
  <string>/var/log/github-actions-runner.log</string>
  
  <!-- CRITICAL: This creates login session with keychain access -->
  <key>SessionCreate</key>
  <true/>
  
  <!-- User context (NOT root, to avoid privilege issues) -->
  <key>UserName</key>
  <string>$(logname)</string>
  
  <!-- Working directory -->
  <key>WorkingDirectory</key>
  <string>~/actions-runner</string>
  
  <!-- Restart on crash -->
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>
  
  <!-- Restart delay (5 sec) -->
  <key>ThrottleInterval</key>
  <integer>5</integer>
  
  <!-- Environment variables for code signing -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>RUNNER_ALLOW_RUNASROOT</key>
    <string>true</string>
  </dict>
  
</dict>
</plist>
EOF
'
```

### Step 4: Manage launchd Service

```bash
# Load plist (start daemon)
sudo launchctl load /Library/LaunchDaemons/com.github.actions-runner.plist

# Check status
sudo launchctl list | grep actions-runner

# View logs
tail -f /var/log/github-actions-runner.log

# Unload (stop daemon)
sudo launchctl unload /Library/LaunchDaemons/com.github.actions-runner.plist

# Reload after config changes
sudo launchctl unload /Library/LaunchDaemons/com.github.actions-runner.plist && \
sudo launchctl load /Library/LaunchDaemons/com.github.actions-runner.plist
```

### Step 5: Import Code-Signing Certificate

Store certificate in system keychain (accessible to daemon):

```bash
# Import .p12 certificate (obtained from Apple Developer)
security import ~/Developer/Certificates.p12 \
  -k /Library/Keychains/System.keychain \
  -P YOUR_CERTIFICATE_PASSWORD \
  -A -T /usr/bin/codesign \
  -T /usr/bin/security

# Verify import
security find-identity -v /Library/Keychains/System.keychain

# Allow daemon to use certificate (important!)
sudo security unlock-keychain -p $(security find-generic-password -w -a $USER /Library/Keychains/login.keychain 2>/dev/null || echo "") /Library/Keychains/System.keychain
```

### Step 6: Use in Workflow (iOS Build Example)

```yaml
name: Build & Sign iOS App
on: [push]

jobs:
  build:
    runs-on: [self-hosted, macos, xcode, arm64]
    steps:
      - uses: actions/checkout@v4
      
      # Get signing certificate from secrets
      - name: Import signing certificate
        env:
          CERTIFICATE_P12: ${{ secrets.IOS_SIGNING_CERT }}
          CERTIFICATE_PASSWORD: ${{ secrets.CERT_PASSWORD }}
        run: |
          echo "$CERTIFICATE_P12" | base64 -D > cert.p12
          security import cert.p12 -k /Library/Keychains/System.keychain \
            -P "$CERTIFICATE_PASSWORD" -A -T /usr/bin/codesign
      
      # Build and sign
      - name: Build iOS app
        run: |
          xcodebuild \
            -scheme MyApp \
            -configuration Release \
            -archivePath ./build/MyApp.xcarchive \
            archive
          
          xcodebuild \
            -exportArchive \
            -archivePath ./build/MyApp.xcarchive \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath ./build/ipa
      
      # Notarize for distribution
      - name: Notarize app
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_ID_PASSWORD: ${{ secrets.APPLE_ID_PASSWORD }}
        run: |
          xcrun notarytool submit ./build/ipa/*.ipa \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD" \
            --team-id YOUR_TEAM_ID \
            --wait
```

**Critical Notes:**
- `SessionCreate: true` is ESSENTIAL—launchd daemon cannot access login keychain otherwise
- Keep certificate in System keychain, not login keychain
- Regenerate runner token if launchd fails to start (1-hour expiry)
- Check logs: `log stream --predicate 'eventMessage contains[cd] "actions-runner"' --level debug`

---

## Recipe 5: Raspberry Pi / ARM64 Runner

**Use when:** Running CI on Raspberry Pi 4/5 or ARM64 boards; consider resource constraints.

### Prerequisites
- Raspberry Pi 4 (4GB+ RAM recommended) or Pi 5
- 32GB+ microSD card (better: USB 3.0 SSD)
- OS: Ubuntu 24.04 LTS (arm64) or Raspberry Pi OS (Bookworm 64-bit)
- Thermal case + heatsinks (Pi throttles at 80°C+)
- Network: Gigabit Ethernet (WiFi unreliable for large downloads)

### Step 1: Prepare OS

```bash
# Write Ubuntu 24.04 arm64 to SD card (on another computer)
# Download: https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04-preinstalled-server-arm64+raspi.img.xz

# Flash to SD card (macOS example; Linux use dd, Windows use Etcher)
xz -d ubuntu-24.04-preinstalled-server-arm64+raspi.img.xz
dd if=ubuntu-24.04-preinstalled-server-arm64+raspi.img of=/dev/rdiskX bs=4m

# Boot Pi, SSH in (default user: ubuntu, password: ubuntu)
ssh ubuntu@RASPBERRY_PI_IP
```

### Step 2: System Optimization (Important for ARM64!)

```bash
sudo apt-get update && sudo apt-get upgrade -y

# Install runtime dependencies (lightweight)
sudo apt-get install -y curl jq build-essential python3-dev python3-venv libffi-dev docker.io git

# Add runner user
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG docker github-runner
sudo usermod -aG sudo github-runner

# Critical: Disable swappiness to reduce SD card wear
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Enable GPU memory split (optional, for compute-heavy tasks)
# This reserves 128MB GPU memory (Pi4/Pi5 have 8GB shared memory)
# Edit /boot/firmware/config.txt: gpu_mem=128

# Reduce log verbosity (saves writes to SD card)
sudo systemctl set-default multi-user.target  # No GUI
echo "GRUB_TIMEOUT=0" | sudo tee -a /etc/default/grub
sudo update-grub2
```

### Step 3: Download ARM64 Runner

```bash
mkdir -p /opt/actions-runner
cd /opt/actions-runner

# Explicitly request ARM64 binary
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r ".tag_name" | sed "s/v//")

sudo -u github-runner bash -c '
  curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
    -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
  
  # Verify checksum (critical on Pi due to reliability issues)
  curl -s https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz.sha256 | shasum -a 256 -c
  
  tar xzf actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
  rm actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
'
```

### Step 4: Configure Runner

```bash
cd /opt/actions-runner
sudo -u github-runner bash -c '
  ./config.sh \
    --url https://github.com/YOUR_ORG \
    --token YOUR_PAT_TOKEN \
    --name raspi-runner-01 \
    --labels arm64,raspi,pi5,ubuntu-24.04 \
    --work _work \
    --unattended \
    --replace
'
```

### Step 5: Install systemd Service (ARM64-specific)

```bash
sudo tee /etc/systemd/system/actions-runner.service > /dev/null << 'EOF'
[Unit]
Description=GitHub Actions Runner (ARM64)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=github-runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh

# Critical: Auto-restart on Pi (unreliable network/thermal events)
Restart=always
RestartSec=15  # Wait 15 sec before restarting
StartLimitIntervalSec=600
StartLimitBurst=3  # Restart max 3 times per 10 min

# Thermal throttle monitoring (log temperature)
ExecStartPost=/usr/bin/logger -t actions-runner "CPU Temp: $(cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}')"

# Resource limits (Pi has limited RAM)
MemoryMax=1G
CPUQuota=300%  # Limit to 3 cores on 4-core Pi4

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable actions-runner
sudo systemctl start actions-runner
```

### Step 6: Monitor Thermal Throttling (Important!)

```bash
# Check current CPU temp
cat /sys/class/thermal/thermal_zone0/temp

# Watch real-time (should stay <80°C)
watch -n 1 'echo "CPU Temp: $(cat /sys/class/thermal/thermal_zone0/temp | awk '"'"'{print $1/1000}'"'"')°C"'

# Monitor frequency (thermal throttle causes downclocking)
watch -n 1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk '"'"'{print $1/1000 "MHz"}'"'"''

# Check for throttling events in kernel log
dmesg | grep -i throttle
```

### Step 7: Use in Workflow (with Resource Labels)

```yaml
name: Test on Raspberry Pi
on: [push]

jobs:
  build:
    runs-on: [self-hosted, arm64, raspi, pi5]
    timeout-minutes: 30  # Set timeout to avoid hung processes
    
    steps:
      - uses: actions/checkout@v4
      
      # Keep tasks lightweight!
      - name: Build lightweight binary
        run: |
          # Example: Rust binary (better than Docker on Pi)
          cargo build --release --target aarch64-unknown-linux-gnu
      
      # Monitor during build
      - name: Check CPU temp
        if: always()
        run: |
          echo "CPU Temp: $(cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}')°C"
          free -h
```

**ARM64 Special Considerations:**
- Keep single job runtime <30 min (Pi throttles under sustained load)
- Use external SSD if possible (SD card I/O is bottleneck)
- Avoid Docker-in-Docker (Pi RAM limited to ~2.5GB usable)
- Compile from source when binary unavailable (Go, Rust preferred)
- Monitor temperature: throttling cuts build time 50%+
- Disable unnecessary services (snapd, etc.) to free RAM

---

## Recipe 6: Just-in-Time (JIT) Ephemeral Runner via API

**Use when:** You want single-use, ephemeral runners without persistent infrastructure (great for untrusted PRs).

### Prerequisites
- GitHub App with `administration:self-hosted-runners` (read+write) permission
- Container runtime (Docker, Podman, or K8s)
- Runner binary (same as Recipe 1-3)

### Step 1: Get JIT Config via API

```bash
#!/bin/bash
# Script to generate JIT configuration and launch runner

ORG="YOUR_ORG"
REPO="YOUR_REPO"
RUNNER_NAME="jit-runner-$(date +%s)"
RUNNER_GROUP_ID=1  # Default group
LABELS="jit,ephemeral,api-generated"

# Get GitHub App credentials or PAT
TOKEN="ghp_xxxxxxxxxxxx"  # or JWT from GitHub App

# Call generate-jitconfig endpoint
JIT_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$ORG/$REPO/actions/runners/generate-jitconfig \
  -d "{
    \"name\": \"$RUNNER_NAME\",
    \"runner_group_id\": $RUNNER_GROUP_ID,
    \"labels\": [\"$(echo $LABELS | tr ',' '\", \"')\"],
    \"work_folder\": \"_work\"
  }")

# Extract JIT config (base64 encoded)
JIT_CONFIG=$(echo "$JIT_RESPONSE" | jq -r '.encoded_jit_config')

if [ -z "$JIT_CONFIG" ] || [ "$JIT_CONFIG" == "null" ]; then
  echo "ERROR: Failed to generate JIT config"
  echo "$JIT_RESPONSE" | jq .
  exit 1
fi

echo "JIT Config generated for: $RUNNER_NAME"
echo "$JIT_CONFIG"
```

### Step 2: Docker Container with JIT Config

```bash
#!/bin/bash
# Launch ephemeral runner in Docker from JIT config

JIT_CONFIG="$1"  # Pass JIT config from Step 1

docker run -d \
  --name jit-runner-$$\
  -e JIT_CONFIG="$JIT_CONFIG" \
  --rm \
  myoung34/docker-github-actions-runner:latest \
  /entrypoint.sh

# Wait for runner to complete job & auto-terminate (JIT cleanup)
docker wait jit-runner-$$
```

### Step 3: Full Orchestration Script (Generate + Run + Cleanup)

```bash
#!/bin/bash
set -e

ORG="YOUR_ORG"
REPO="YOUR_REPO"
TOKEN="ghp_xxxxxxxxxxxx"
RUNNER_LABELS="jit,ephemeral,untrusted-pr"

# Generate JIT config
echo "==> Generating JIT config..."
JIT_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$ORG/$REPO/actions/runners/generate-jitconfig \
  -d "{
    \"name\": \"jit-runner-$(date +%s)\",
    \"runner_group_id\": 1,
    \"labels\": [\"jit\", \"ephemeral\"],
    \"work_folder\": \"_work\"
  }")

JIT_CONFIG=$(echo "$JIT_RESPONSE" | jq -r '.encoded_jit_config')

if [ -z "$JIT_CONFIG" ] || [ "$JIT_CONFIG" == "null" ]; then
  echo "FATAL: JIT config generation failed"
  echo "$JIT_RESPONSE" | jq .
  exit 1
fi

echo "✓ JIT config generated (valid ~60 min)"

# Launch runner container
CONTAINER_ID=$(docker run -d \
  -e JIT_CONFIG="$JIT_CONFIG" \
  --rm \
  myoung34/docker-github-actions-runner:latest)

echo "✓ Container launched: $CONTAINER_ID"

# Wait for job completion & cleanup (JIT auto-deregisters)
docker logs -f "$CONTAINER_ID" &
LOG_PID=$!

# Timeout: 45 min (most jobs finish in <30 min)
if timeout 2700 docker wait "$CONTAINER_ID"; then
  echo "✓ Runner completed and auto-cleaned up"
else
  echo "WARN: Timeout; cleaning up container"
  docker kill "$CONTAINER_ID" 2>/dev/null || true
fi

kill $LOG_PID 2>/dev/null || true
exit 0
```

### Step 4: Use in Workflow (Trigger JIT Runner)

```yaml
name: Security Check (JIT Runner)
on:
  pull_request:
    paths:
      - '**.rs'
      - 'Cargo.toml'

jobs:
  # First job: Request JIT runner via API
  request-runner:
    runs-on: ubuntu-latest
    outputs:
      jit-config: ${{ steps.generate-jit.outputs.config }}
    steps:
      - name: Generate JIT runner config
        id: generate-jit
        uses: actions/github-script@v7
        with:
          script: |
            const response = await github.rest.actions.generateRunnerJitConfig({
              owner: context.repo.owner,
              repo: context.repo.repo,
              data: {
                name: `jit-${context.runId}`,
                runner_group_id: 1,
                labels: ['jit', 'ephemeral', 'security-scan']
              }
            });
            core.setOutput('config', response.data.encoded_jit_config);
  
  # Second job: Run on ephemeral JIT runner
  security-scan:
    needs: request-runner
    runs-on: [self-hosted, jit, ephemeral]  # Matches JIT labels
    steps:
      - uses: actions/checkout@v4
      - name: Run security audit
        run: cargo audit
      # Runner auto-deregisters after job completes
```

**JIT Key Benefits:**
- Single-use runners (no persistent state)
- Config valid ~60 min; auto-cleanup after job
- Labels baked into config (can't be spoofed)
- Perfect for untrusted PRs (fire-and-forget)
- Lower cost (no idle runners)

**Limitations:**
- API call required per runner (quota: 15K/hr for GitHub Apps)
- Token must be valid for entire ~60 min window
- Not suitable for long-running jobs (>45 min)

---

## Recipe 7: Tailscale-Only Runner (Private Tailnet)

**Use when:** Runner reachable ONLY via Tailscale; zero public IP/ports.

### Prerequisites
- Tailscale account + tailnet
- GitHub Action: `tailscale/github-action@v4` (or custom script)
- Tailscale auth key with tag for CI runners

### Step 1: Bare Metal Setup with Tailscale Daemon

```bash
# On runner host (private server), install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and join tailnet
sudo tailscale login

# (Or use auth key for automation)
sudo tailscale up --authkey tskey-api-xxxxxxxxxxxx --hostname ci-runner-1

# Verify Tailscale network
ip route  # Should show tailscale0 interface
tailscale status
```

### Step 2: Configure GitHub Actions Runner (same as Recipe 1)

```bash
# Follow Recipe 1 steps, then configure systemd with Tailscale awareness
```

Create systemd service (modified):

```bash
sudo tee /etc/systemd/system/actions-runner.service > /dev/null << 'EOF'
[Unit]
Description=GitHub Actions Runner (Tailscale Private)
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=simple
User=github-runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh

# Only start if Tailscale is up
ExecStartPre=/usr/bin/tailscale status

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable actions-runner
sudo systemctl start actions-runner
```

### Step 3: Firewall Rules (Restrict to Tailscale)

```bash
# Block all public interfaces except SSH for management
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from Tailscale only (100.x.x.x subnet)
sudo ufw allow from 100.64.0.0/10 to any port 22

# Allow GitHub Actions Runner API (internal only)
sudo ufw allow in on tailscale0

# Enable firewall
sudo ufw enable
```

### Step 4: GitHub Actions Workflow with Tailscale Integration

```yaml
name: Deploy to Private Server via Tailscale
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest  # GitHub-hosted runner
    
    steps:
      - uses: actions/checkout@v4
      
      # Step 1: Connect to Tailscale (ephemeral connection)
      - name: Connect to Tailscale
        uses: tailscale/github-action@v4
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}
          version: "1.72.1"
          tags: ci-runner
      
      # Step 2: SSH to private runner via Tailscale
      - name: Deploy application
        run: |
          # Tailscale creates 100.x.x.x IP for ephemeral node
          # Use hostname defined during `tailscale up`
          ssh-keyscan -H ci-runner-1 >> ~/.ssh/known_hosts
          ssh runner@ci-runner-1 << 'EOCOMMANDS'
            cd /home/runner/app
            git pull
            ./deploy.sh
          EOCOMMANDS
      
      # Step 3: Disconnect (automatic cleanup)
      - name: Disconnect Tailscale
        if: always()
        uses: tailscale/github-action@v4
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}
          args: --logout
```

### Step 5: Self-Hosted Runner on Tailscale (Alternative)

For existing self-hosted runner, register it with Tailscale label:

```bash
# On runner machine
sudo tailscale up \
  --authkey tskey-api-xxxxxxxxxxxx \
  --hostname runner-private \
  --advertise-exit-node=false

# Add to GitHub via `runs-on: [self-hosted, tailscale]`
```

Use in workflow:

```yaml
jobs:
  test:
    runs-on: [self-hosted, tailscale]  # Private runner via Tailscale
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on private network, unreachable from internet"
```

**Tailscale Advantages:**
- Zero public IPs/ports required (firewall-friendly)
- WireGuard encryption end-to-end
- Ephemeral connections (auto-cleanup after workflow)
- Scalable: multiple runners in same tailnet
- OAuth/SSO integration (MagicDNS)

**Cost:** Tailscale free tier (20 devices); $5/mo/user for enterprise scale

---

## Recipe 8: Auto-Scaling on AWS via philips-labs/terraform-aws-github-runner

**Use when:** Need cost-optimized, production-grade auto-scaling on AWS.

### Prerequisites
- AWS account + CLI configured
- Terraform 1.0+
- GitHub App with admin:org permission
- VPC with public/private subnets

### Step 1: Terraform Module Configuration

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source: Get default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Main module: GitHub Actions Runners on AWS
module "github_runners" {
  source = "philips-labs/github-runner/aws"
  version = "~> 5.0"
  
  # AWS configuration
  aws_region = var.aws_region
  environment = var.environment
  
  # GitHub configuration
  github_app = {
    id             = var.github_app_id
    client_id      = var.github_app_client_id
    client_secret  = var.github_app_client_secret
    installation_id = var.github_app_installation_id
  }
  
  # Key configuration
  key_name = aws_key_pair.runner_key.key_name
  
  # VPC/Network
  vpc_id            = data.aws_vpc.default.id
  subnet_ids        = data.aws_subnets.default.ids
  
  # GitHub organization/repo
  github_app_webhook_secret = var.webhook_secret
  
  # Runner configuration
  runner_os       = "linux"
  instance_type   = "t3.large"  # Cost-optimized
  
  # Scaling configuration (KEY COST KNOBS)
  # Min runners kept warm (scaled to 0 during idle periods)
  runners_maximum_count = 10
  runners_minimum_count = 1
  
  # Scale-up when jobs queued
  instance_launch_template = {
    ami           = data.aws_ami.runner_ami.id
    instance_type = "t3.large"
    
    # Spot instances for cost savings (~70% cheaper)
    instance_market_options = {
      market_type = "spot"
      spot_options = {
        max_price            = "0.05"  # Max bid for spot ($0.05/hr vs $0.0832/hr on-demand)
        spot_instance_type   = "one-time"
        interruption_behavior = "terminate"
      }
    }
    
    # Storage
    root_block_device = {
      volume_type           = "gp3"
      volume_size           = 50  # GB
      delete_on_termination = true
      encrypted             = true
    }
    
    # Enable monitoring
    monitoring = {
      enabled = true
    }
    
    # IAM role for runners to access AWS services if needed
    iam_instance_profile = aws_iam_instance_profile.runner_profile.name
  }
  
  # Ephemeral mode: runners auto-deregister after each job
  ephemeral = true
  
  # Enable detailed logging
  enable_cloudwatch_agent = true
  
  # Labels for workflow matching
  labels = ["aws", "linux", "ubuntu-24.04", "spot", "ephemeral"]
}

# SSH key for accessing runners (debugging)
resource "aws_key_pair" "runner_key" {
  key_name   = "github-runner-key"
  public_key = var.ssh_public_key
}

# IAM role for runners
resource "aws_iam_role" "runner_role" {
  name = "github-runner-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Basic EC2 policy (runners can describe own instances)
resource "aws_iam_role_policy" "runner_policy" {
  name = "github-runner-policy"
  role = aws_iam_role.runner_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "github-runner-profile"
  role = aws_iam_role.runner_role.name
}

# Get latest Ubuntu 24.04 LTS AMI
data "aws_ami" "runner_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# CloudWatch alarms (optional: alert on high scaling)
resource "aws_cloudwatch_metric_alarm" "runner_count_high" {
  alarm_name          = "github-runners-high-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupDesiredCapacity"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 8  # Alert if >8 runners
  alarm_actions       = [var.sns_topic_arn]
}

# Output: Lambda scale-down function (configurable via variables)
output "scale_down_cron" {
  value = "0 23 * * *"  # 11 PM UTC daily
}
```

### Step 2: Variables (variables.tf)

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
  sensitive   = true
}

variable "github_app_client_id" {
  description = "GitHub App Client ID"
  type        = string
  sensitive   = true
}

variable "github_app_client_secret" {
  description = "GitHub App Client Secret"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = number
  sensitive   = true
}

variable "webhook_secret" {
  description = "Webhook secret for GitHub App"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for runner access"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic for alerts"
  type        = string
  default     = ""
}
```

### Step 3: terraform.tfvars (Secrets)

```hcl
aws_region                   = "us-east-1"
environment                  = "prod"
github_app_id                = "123456"
github_app_client_id         = "Iv1.abc123..."
github_app_client_secret     = "ghu_abc123..."
github_app_installation_id   = 789012
webhook_secret               = "whsec_abc123..."
ssh_public_key               = "ssh-rsa AAAA..."
```

### Step 4: Deployment

```bash
# Initialize Terraform
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Monitor runners
aws ec2 describe-instances --filters "Name=tag:github:actions-runner,Values=*" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### Step 5: Cost Optimization Knobs

Key variables to control costs:

```hcl
# 1. Spot instances (save ~70%)
instance_market_options.spot_options.max_price = "0.05"  # Adjust based on region

# 2. Min/max runner counts
runners_minimum_count = 0  # Scale to zero when idle (critical for cost)
runners_maximum_count = 5  # Prevent runaway costs

# 3. Instance type (smaller = cheaper)
instance_type = "t3.small"  # Not t3.large (trade-off: slower builds)

# 4. Scale-down schedule
scale_down_lambda_cron = "0 21 * * *"  # Scale down 9 PM daily

# 5. Max concurrent runs per instance
max_runners_per_instance = 1  # Prevent resource contention
```

### Step 6: Use in Workflow

```yaml
name: Deploy on AWS Spot Runners
on: [push]

jobs:
  build:
    runs-on: [self-hosted, aws, linux, spot, ephemeral]  # Matches Terraform labels
    steps:
      - uses: actions/checkout@v4
      - run: cargo build --release
      # Runner auto-terminates after job
```

**Terraform Module Features:**
- Lambda-based autoscaling (webhook-triggered + cron scale-down)
- Ephemeral runners (security + cost)
- Spot instances (cost savings 60-70%)
- Scales to zero during idle periods
- Multi-instance distribution

**Estimated Costs (monthly):**
- 10 runners × 1 hr/day × $0.05/hr (spot) × 30 days = ~$15
- Compare: GitHub-hosted runners ~$0.008/min = ~$38/hr = $900/month for equivalent capacity

---

# Summary Table

| Recipe | Setup Time | Cost | Best For | Difficulty |
|--------|-----------|------|----------|------------|
| 1. Bare Metal (systemd) | 15 min | $0 (existing server) | Small teams, learning | **Beginner** |
| 2. Docker | 10 min | $0 (existing Docker host) | Reproducible builds, isolation | Beginner |
| 3. Kubernetes (ARC) | 30 min | $50-200/mo | Large teams, multi-region | Intermediate |
| 4. macOS (launchd) | 20 min | $0 (existing Mac) | iOS/Xcode builds, notarization | Beginner |
| 5. Raspberry Pi (ARM64) | 45 min | $50-100 (hardware) | Edge devices, IoT, cost-conscious | Intermediate |
| 6. JIT Ephemeral (API) | 30 min | ~$2-5/mo | Untrusted PRs, security | Advanced |
| 7. Tailscale Private | 25 min | $0-5 (Tailscale free/pro) | Private infrastructure, zero-trust | Intermediate |
| 8. AWS Auto-Scaling (Terraform) | 45 min | $15-100/mo (spot) | Enterprise, high volume, cost-optimized | Advanced |

---

# Quick Start Checklist

**For your first runner (Recipe 1 - Bare Metal):**

```bash
# 1. Create user & install deps (5 min)
sudo useradd -m github-runner && sudo apt-get install -y curl jq build-essential docker.io

# 2. Download runner (2 min)
cd /opt/actions-runner && curl -O ... && tar xz

# 3. Get PAT token from GitHub (Settings > Developer Settings > Personal Access Tokens)

# 4. Configure (2 min)
./config.sh --url https://github.com/YOUR_ORG --token YOUR_PAT --unattended

# 5. Install systemd service (1 min)
sudo ./svc.sh install  # Built-in script (easier than manual plist)
sudo systemctl start actions-runner

# 6. Verify
sudo systemctl status actions-runner
# Should appear in GitHub Actions > Settings > Runners within 30 sec

# Total: ~15 minutes, zero cost, fully functional.
```

---

# Sources

Research compiled from:
- [GitHub Actions Self-Hosted Runners Documentation](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/about-self-hosted-runners)
- [Actions Runner Controller (ARC) - GitHub Docs](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)
- [myoung34/docker-github-actions-runner - GitHub](https://github.com/myoung34/docker-github-actions-runner)
- [macOS Runners + Code Signing - GitHub Docs](https://docs.github.com/en/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development)
- [ARM.com: Self-Hosted ARM64 Runners](https://learn.arm.com/learning-paths/laptops-and-desktops/self_hosted_cicd_github/create-self-hosted-runner-github/)
- [JIT Runners - GitHub Blog](https://github.blog/changelog/2023-06-02-github-actions-just-in-time-self-hosted-runners/)
- [Tailscale GitHub Actions - Tailscale Docs](https://tailscale.com/docs/solutions/connect-github-CICD-workflows-to-private-infrastructure-without-public-exposure)
- [philips-labs/terraform-aws-github-runner - GitHub](https://github.com/philips-labs/terraform-aws-github-runner)
