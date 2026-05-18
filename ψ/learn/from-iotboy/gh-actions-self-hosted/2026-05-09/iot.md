# GitHub Actions Self-Hosted Runners for IoT/Embedded/Hardware-in-the-Loop Workflows

## Executive Summary

Self-hosted GitHub Actions runners are essential for IoT and embedded systems CI/CD because hosted runners cannot accommodate the massive toolchain footprints, lack physical hardware for flashing and testing, and cannot detect real failure modes like brownout, flash degradation, and RF spectrum deviation. This guide covers the architectural patterns, security practices, real-world implementations, and operational concerns for running embedded firmware builds and hardware testing at scale.

---

## 1. Why Self-Hosted Runners for Embedded: The Hosted Runner Problem

### Toolchain Size and Dependency Storage

GitHub-hosted runners (ubuntu-latest, macos-latest) offer ~135 GB of storage and reasonable CPU, but embedded firmware ecosystems violate their assumptions:

- **ESP-IDF 5+**: The official Espressif IoT Development Framework alone exceeds 5 GB when fully provisioned with cross-compilers, Xtensa tools, and component caches. Installing fresh per-build defeats the purpose of CI.
- **PlatformIO packages**: A mature PlatformIO installation with multiple board support (ESP32, STM32, nRF52) accumulates 3+ GB in `~/.platformio/`, including GCC cross-toolchain variants, debugger binaries, and board description files.
- **LLVM/Clang for ARM**: Building native LLVM for ARM targets (Cortex-M, Cortex-A) is 1.5+ GB per variant.

**Solution**: Self-hosted runners mount local storage with pre-cached toolchains, eliminating hourly reinstalls. A single 500 GB SSD can persist years of build artifacts.

### Real Hardware is Required

Hosted runners are virtualized Linux/Windows/macOS—no USB, no GPIO, no serial port. Testing embedded firmware demands:

- **Flash over USB/JTAG**: Connected devices need esptool, openocd, or vendor-specific programmers to write firmware to onboard flash.
- **Serial assertions and UART output**: Reading UART console during test execution catches errors hosted runners cannot observe.
- **Power cycling and brownout injection**: Validating reset behavior and flash integrity under power loss requires relay control and power supply that hosted runners cannot provide.
- **RF/antenna isolation**: Compliance testing for 2.4 GHz Wi-Fi or Bluetooth often requires an RF chamber to avoid interference; hosted runners have zero isolation.

**Solution**: Physically collocate self-hosted runners with a hardware test rig (USB hub, serial mux, relay board, power supply).

### Native Architecture Builds Without Emulation Tax

ARM firmware (Raspberry Pi, Cortex-M, NVIDIA Jetson) typically cross-compiles on x86 CI runners using QEMU or software emulation, incurring 5-15x performance penalty. Real-world CI runs:

- Raspberry Pi OS kernel builds: 45 min on QEMU, 3 min native ARM64.
- Zephyr RTOS full test suite: 120 min on emulated ARM, 15 min on native Ampere Altra.

**Solution**: Native ARM64 runners (Ampere Altra, GitHub's ARM64 hosted runners, or Pi cluster) eliminate emulation overhead entirely.

---

## 2. ESP32 Build Farm Pattern: Matrix Builds with Cached Toolchains

### Architecture Overview

The canonical ESP32 CI workflow runs a matrix across board variants and caches the PlatformIO/ESP-IDF toolchain:

```yaml
name: ESP32 Build Farm

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  build:
    runs-on: [self-hosted, linux, esp32]
    strategy:
      matrix:
        board: [esp32, esp32-s3, esp32-c3, esp32-c6]
        variant: [debug, release]
    steps:
      - uses: actions/checkout@v4

      - name: Cache PlatformIO
        uses: actions/cache@v3
        with:
          path: ~/.platformio
          key: pio-${{ runner.os }}-${{ hashFiles('platformio.ini') }}
          restore-keys: pio-${{ runner.os }}-

      - name: Install dependencies
        run: |
          pip install platformio
          pio platform install espressif32

      - name: Build ${{ matrix.board }} (${{ matrix.variant }})
        run: |
          pio run -e ${{ matrix.board }}_${{ matrix.variant }}

      - name: Generate SHA256 fingerprint
        run: |
          sha256sum .pio/build/${{ matrix.board }}_${{ matrix.variant }}/firmware.bin > \
            firmware-${{ matrix.board }}-${{ matrix.variant }}.sha256

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware-${{ matrix.board }}-${{ matrix.variant }}
          path: firmware-*.sha256
          .pio/build/${{ matrix.board }}_${{ matrix.variant }}/firmware.bin
```

### Key Optimization: Shared Cache Directory

The `~/.platformio` directory grows with repeated builds:

1. **First run** (cold cache): ~12 min (downloads ESP32 SDK, cross-compiler, libraries).
2. **Subsequent runs** (warm cache): ~2 min (only rebuilds sources).

On GitHub-hosted runners, you pay the 12 min penalty every build. On self-hosted runners, the cache persists across all jobs:

```bash
# On self-hosted runner
ls -lh ~/.platformio/packages/
# toolchain-xtensa32 (450 MB), toolchain-esp32ulp (80 MB), etc.

# Action cache hit saves 150+ minutes per week on active projects
```

### Parallel Board Variants

The matrix pattern compiles for multiple MCU variants in parallel, each with distinct:

- **Toolchain targets**: Xtensa (ESP32, ESP32-S3), RISC-V (ESP32-C3, ESP32-C6).
- **Flash layouts**: ESP32-S3 has larger flash banks; ESP32-C3 is IoT-only.
- **Binary output**: Each variant produces a different `.bin` artifact.

Self-hosted runners with 4+ CPU cores handle 4 parallel matrix jobs (one per board) without contention.

### Artifact Publishing and Release Tagging

After matrix completion, a release job publishes all variants:

```yaml
  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    steps:
      - uses: actions/download-artifact@v3

      - name: Create GitHub Release
        uses: ncipollo/release-action@v1
        with:
          artifacts: 'firmware-*/*'
          bodyFile: CHANGELOG.md
```

Each artifact is tagged with board variant, version, and SHA256 hash for supply chain traceability.

---

## 3. Hardware-in-the-Loop (HIL) Testing: Physical Devices in CI

### HIL Architecture: Flashing, Testing, and Assertion Checking

A self-hosted runner equipped with physical test boards enables true hardware validation:

```yaml
name: Hardware-in-the-Loop Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  hil-test:
    runs-on: [self-hosted, linux, hil-rack-3]
    steps:
      - uses: actions/checkout@v4

      - name: Build firmware
        run: pio run -e esp32_release

      - name: Flash device via esptool
        run: |
          esptool.py --chip esp32 \
            --port /dev/ttyUSB0 \
            --baud 460800 \
            --before default_reset \
            --after hard_reset \
            write_flash -z 0x1000 \
            .pio/build/esp32_release/firmware.bin

      - name: Run serial assertions (timeout 30s)
        run: |
          timeout 30 python3 - <<'PYTHON'
          import serial
          import sys
          
          ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
          
          tests_passed = 0
          tests_failed = 0
          
          for line in iter(ser.readline, b''):
            decoded = line.decode('utf-8', errors='ignore').strip()
            print(f"[DEVICE] {decoded}")
            
            if "ASSERT PASSED:" in decoded:
              tests_passed += 1
            elif "ASSERT FAILED:" in decoded:
              tests_failed += 1
              sys.exit(1)
            elif "TEST_COMPLETE" in decoded:
              break
          
          ser.close()
          print(f"\nTests: {tests_passed} passed, {tests_failed} failed")
          sys.exit(0 if tests_failed == 0 else 1)
          PYTHON

      - name: Capture device state on failure
        if: failure()
        run: |
          esptool.py --chip esp32 read_flash 0x0 0x1000 /tmp/flash_dump.bin
          xxd /tmp/flash_dump.bin > flash_dump.txt
          
      - name: Upload debug artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: hil-debug-${{ github.run_id }}
          path: flash_dump.txt
```

### Tag System for Test Rig Management

Each self-hosted runner declares labels identifying its hardware:

```bash
# On test-rig-3.example.com
./run.sh --name hil-runner-3 \
         --labels self-hosted,linux,hil-rack-3,esp32-board-a,scope

# Workflow uses: runs-on: [self-hosted, hil-rack-3]
# Only jobs tagged hil-rack-3 execute on this runner
```

**Tag strategy**:
- `hil-rack-N`: Physical location/rack identifier.
- `esp32-board-X`: Specific device serial number (for multi-device rigs).
- `scope`: Indicates oscilloscope access (for analog testing).
- `rf-chamber`: RF testing capability.

This isolation prevents cross-device interference and allows scaling multiple independent test rigs.

### Serial Output Parsing and Log Aggregation

Embedded firmware often outputs structured logs:

```c
// firmware code
void selftest(void) {
  printf("TEST_START:memory_check\n");
  if (check_ram() == 0) {
    printf("ASSERT PASSED:memory_check\n");
  } else {
    printf("ASSERT FAILED:memory_check\n");
  }
  printf("TEST_COMPLETE\n");
}
```

The CI job parses these in real time, failing fast on unexpected output or timeout.

---

## 4. ARM Cluster Runners: Native arm64 Builds

### Why Native ARM64 is Essential

For Raspberry Pi, Cortex-A, and NVIDIA Jetson firmware:

- **Apple Silicon Macs**: Native arm64, but macOS kernel drivers differ from Linux.
- **GitHub's ARM64 hosted runners** (public preview, free tier): 4 vCPU, 16 GB, up to 40% faster than emulated ARM.
- **Ampere Altra** (cloud): 80+ cores, real ARM64 with better performance/cost than QEMU.
- **Raspberry Pi 5 cluster**: 8 Pi 5s (8 cores each) = 64 native ARM threads, costs ~$400, runs continuously.

### Pi Cluster Setup

A 4-Pi cluster (8-core Pi 5s) can handle parallel Zephyr, RIOT-OS, and Linux kernel builds:

```bash
# On each Pi:
curl https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-arm64-2.317.0.tar.gz | tar xz
./config.sh --url https://github.com/OWNER/REPO --token XXXXX --labels self-hosted,linux,arm64,pi-cluster
sudo ./svc.sh install
sudo ./svc.sh start

# All 4 Pi runners automatically join the pool under label 'pi-cluster'
```

### Example: 60-minute Zephyr Build, 2 Minutes with Native ARM64

```yaml
jobs:
  zephyr-build-arm:
    runs-on: [self-hosted, arm64, pi-cluster]
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Zephyr SDK (cached)
        run: |
          [ -d ~/zephyr-sdk ] && echo "SDK cached" || \
          wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/zephyr-sdk-0.16.5_linux-aarch64_minimal.tar.xz && \
          tar -C ~ -xf zephyr-sdk-*.tar.xz
      
      - name: Build for Raspberry Pi 5
        run: |
          west build -b rpi_pico2 samples/hello_world -p
      
      - name: Upload ELF
        uses: actions/upload-artifact@v3
        with:
          name: zephyr-rpi-elf
          path: build/zephyr/zephyr.elf
```

**Benchmark**: 3 min native (on Pi 5 cluster) vs. 45 min QEMU-emulated on x86 hosted runner.

---

## 5. OTA Firmware Signing in CI: HMAC and Constant-Time Verification

### Why Sign Firmware in CI

Over-the-air updates allow field devices to pull firmware without human intervention. An attacker who intercepts the binary can inject malicious code unless the firmware is cryptographically signed and verified by the device at runtime.

### HMAC Signing Pattern

The CI build job signs the firmware before publishing to a release bucket:

```yaml
  sign-and-release:
    needs: build
    runs-on: [self-hosted, linux, esp32]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v3

      - name: Sign firmware with HMAC-SHA256
        env:
          OTA_SIGNING_KEY: ${{ secrets.OTA_SIGNING_KEY }}
        run: |
          python3 << 'PYTHON'
          import hmac
          import hashlib
          import json
          import base64
          
          firmware = open('firmware.bin', 'rb').read()
          key = base64.b64decode('${{ secrets.OTA_SIGNING_KEY }}')
          
          sig = hmac.new(key, firmware, hashlib.sha256).digest()
          
          metadata = {
            "version": "${{ github.ref_name }}",
            "timestamp": int(datetime.now().timestamp()),
            "signature": base64.b64encode(sig).decode(),
            "algorithm": "hmac-sha256",
            "size": len(firmware)
          }
          
          with open('firmware.sig', 'w') as f:
            json.dump(metadata, f)
          PYTHON

      - name: Upload to release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            firmware.bin
            firmware.sig
```

### Critical: Constant-Time Comparison on Device

The device must verify the signature using **constant-time comparison**, not naive string equality:

```c
// WRONG: timing-safe comparison missing
if (strcmp(received_sig, computed_sig) == 0) {
  // NOT CONSTANT TIME: attacker can guess byte-by-byte
  update_allowed = true;
}

// CORRECT: constant-time comparison
#include <string.h>
int safe_cmp = crypto_verify_32((uint8_t*)received_sig, 
                                  (uint8_t*)computed_sig);
if (safe_cmp == 0) {
  // Takes same time regardless of where first mismatch occurs
  update_allowed = true;
}
```

**Why this matters**: A timing attack allows an attacker to forge signatures by measuring how long verification takes. Correct bytes take slightly longer; incorrect bytes fail fast. By measuring millions of attempts, an adversary reconstructs the signature one byte at a time.

**Languages**:
- **Python**: `hmac.compare_digest()`
- **Node.js**: `crypto.timingSafeEqual()`
- **Go**: `hmac.Equal()` from `crypto/hmac`
- **C**: `crypto_verify_*()` from libsodium or similar constant-time library

### Key Management

The OTA signing key is stored in GitHub Secrets at the repository or organization level. Only CI jobs (and trusted human signers) have access:

```yaml
# Only allow signing on release/* tags, not PRs
if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/release')
```

---

## 6. Reproducibility: Pinning Toolchains, Docker Images, and Fingerprints

### Why Reproducibility Matters

A firmware binary built at commit ABC-v1.0 must always produce the byte-for-byte identical output when rebuilt, otherwise:
- **Supply chain auditing fails**: An attacker could inject malware, and CI cannot prove it.
- **Debugging is hard**: Different binaries have different symbols and stack traces.
- **Compliance testing breaks**: Regulators demand reproducible builds for audit trails.

### Toolchain Pinning Strategy

Pin every tool to a specific version or commit hash:

```yaml
jobs:
  reproducible-build:
    runs-on: [self-hosted, linux, esp32]
    steps:
      - uses: actions/checkout@v4

      - name: Install ESP-IDF v5.3.1 (pinned)
        run: |
          export IDF_VERSION=v5.3.1
          export IDF_HOME=$HOME/esp-idf-$IDF_VERSION
          
          [ -d $IDF_HOME ] || \
          git clone --branch $IDF_VERSION --depth 1 \
            https://github.com/espressif/esp-idf.git $IDF_HOME
          
          $IDF_HOME/install.sh

      - name: Build with pinned toolchain
        run: |
          source $HOME/esp-idf-v5.3.1/export.sh
          idf.py build
```

### Hash-Locked Docker Images

Instead of using `FROM espressif/idf:latest`, pin the image digest:

```dockerfile
# WRONG: latest can change
FROM espressif/idf:latest

# CORRECT: pin the exact image hash
FROM espressif/idf@sha256:abc123def456...
```

Retrieve the digest:

```bash
docker inspect espressif/idf:5.3.1 --format='{{.RepoDigests}}'
# [espressif/idf@sha256:abc123def456...]
```

### Lockfiles for Dependencies

PlatformIO generates `platformio.lock` (if enabled):

```ini
# platformio.ini
[env]
framework_version = 4.4.2
platform = espressif32@6.7.0
```

Git-track the lockfile so rebuilds use identical versions.

### SHA256 Fingerprints per Build

Capture and track firmware hashes:

```bash
# In CI job
sha256sum firmware.bin > firmware.sha256
git-lfs track firmware.sha256  # Optional: store hashes in LFS for audit trail
```

Example artifact:
```
d4f5c8e3a1b2f9e8c7d6a5b4f3e2d1c0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5  firmware-v1.2.3.bin
```

Over time, this creates an immutable audit trail proving "this exact binary was built and signed at timestamp X".

---

## 7. Real OSS Examples: Industry Patterns

### ESPHome CI Workflow

ESPHome (home automation platform for ESP32/ESP8266) uses GitHub Actions extensively:

- **Multi-board testing**: Matrix across ESP32, ESP32-C3, ESP8266 with hardware-in-the-loop flashing.
- **Caching**: Persistent PlatformIO and pip caches reduce CI time from 30 min to 6 min.
- **Release automation**: Automatic version bumping and firmware artifact publishing.

Repository: [esphome/esphome](https://github.com/esphome/esphome)

### Espressif Arduino-ESP32 Release Workflow

The official Arduino core for ESP32 uses a comprehensive CI pipeline:

- **Self-hosted runners**: Dedicated runners for flashing boards and running hardware tests.
- **Board variants**: Matrix across ESP32, ESP32-S3, ESP32-C3, and newer ESP32-C6.
- **Release signing**: Firmware artifacts signed with HMAC before publishing to Arduino library manager.
- **OTA update testing**: Actual devices flash and verify OTA update mechanism works end-to-end.

Repository: [espressif/arduino-esp32](https://github.com/espressif/arduino-esp32)
Actions: [release.yml workflow](https://github.com/espressif/arduino-esp32/actions/workflows/release.yml)

### RIOT-OS Hardware-in-the-Loop Testing

RIOT (friendly OS for IoT) runs nightly HIL tests on a farm of boards:

- **Board pool**: STM32, nRF52, ARM Cortex-M variants.
- **Test framework**: embUnit + custom test harness that boots firmware and checks serial assertions.
- **CI Task Force (CITF)**: Dedicated team maintaining the infrastructure.

Repository: [RIOT-OS/RIOT](https://github.com/RIOT-OS/RIOT)
Wiki: [RIOT's new test system](https://github.com/RIOT-OS/RIOT/wiki/RIOT's-new-test-system:-overview-of-the-proposed-architecture)

### Zephyr RTOS Integrated Testing

Zephyr uses a mix of emulation (QEMU/Renode) and native hardware tests:

- **Emulation**: Fast unit and integration tests run in hosted CI.
- **Hardware tests**: Nightly runs on real ARM, RISC-V, and x86 boards.
- **Module caching**: west update (module fetch) cached to avoid repeated downloads.
- **Toolchain snapshots**: SDK pinned to specific releases; Docker images hash-locked.

Documentation: [Testing Zephyr RTOS software using new CMock/Unity module and Renode](https://www.zephyrproject.org/testing-zephyr-rtos-software-using-new-cmock-unity-module-and-renode/)

---

## 8. Thermal and Wear Concerns: Operating Self-Hosted Runners at Scale

### Raspberry Pi Thermal Throttling

A Raspberry Pi under sustained firmware build load will:

- **60-70°C**: Normal operation.
- **80°C+**: CPU begins throttling; build speed drops 30-50%.
- **85°C+**: Aggressive throttling; builds slow to 10% speed.
- **No heatsink in plastic case**: Routinely hits 85°C.

**Solution**: Active cooling (fan, heatsink) keeps Pi 5 below 60°C during continuous builds.

```bash
# Monitor thermal state
vcgencmd measure_temp  # Pi OS
cat /sys/class/thermal/thermal_zone0/temp  # Linux

# Install pwm fan control
sudo apt install rpi-fan-controller
```

### SD Card I/O Wear

SD cards (especially cheaper ones) have limited write cycles (~1000 full-disk rewrites). A Pi running 24/7 with log writes and build artifacts will degrade quickly:

- **Standard SD card**: 6-12 months of 24/7 self-hosted runner duty before write errors accumulate.
- **Industrial SD card (SLC NAND)**: 2-3 years.
- **SSD via USB3**: 5+ years; recommended for production runners.

**Mitigation**:
- Mount `/var/log` as tmpfs to avoid log I/O wearing the card.
- Use USB3 SSD instead of SD card for boot (Pi Compute Module 4 with NVMe, or external SSD on Pi 5).
- Schedule builds during off-peak hours (8h/day) to reduce wear.
- Monitor S.M.A.R.T. metrics with `smartctl`.

### Scheduling Night Builds and Queue Management

Avoid running all builds 24/7 to extend hardware lifetime:

```yaml
jobs:
  nightly-build:
    runs-on: [self-hosted, linux, esp32]
    if: github.event_name == 'schedule'
    
# Schedule in Actions
on:
  schedule:
    # Run at 2am UTC, avoid peak hours
    - cron: '0 2 * * *'
```

For high-volume projects, implement a queue manager:

```bash
# Example: concurrency limit to 2 simultaneous builds
concurrency:
  group: esp32-farm
  cancel-in-progress: false  # Don't kill running jobs
```

This prevents overwhelming a small Pi cluster and extends hardware life.

---

## 9. IoT Failure Modes Hosted Runners Cannot Detect

### Brownout and Power Supply Integrity

A device powered by a weak USB cable or low-quality power supply will experience voltage sag when RF transmitter fires. Real hardware connected to a real power supply catches this:

- **Hosted runner test**: Firmware compiles, all unit tests pass.
- **Self-hosted HIL test**: Device boots, starts Wi-Fi, sags to 2.8V, crashes mid-OTA.

This failure is invisible to hosted CI without physical power measurement.

### Flash Memory Bad Blocks and Degradation

NAND flash (internal to ESP32, external on some boards) degrades with erase cycles. A test that runs in QEMU or emulation never exercises the actual flash wear mechanism:

- **Hosted CI**: Code compiles; no flash write attempt.
- **Self-hosted HIL**: Flash 1000 times per test run; device detects bad block after N runs.

Modern ESP32 includes bad-block detection in ROM; only real hardware exposes it.

### RF Spectrum Deviation and Regulatory Compliance

Wi-Fi and Bluetooth are regulated by FCC, CE, and ISED. A hosted runner CI cannot measure:

- **Frequency deviation**: Is the device transmitting at exactly 2.412 GHz or off-spec?
- **Power output**: Is TX power within regulatory limits (15 dBm EU, 30 dBm US)?
- **Spectrum mask**: Does the signal envelope stay within regulatory "mask" (no adjacent-channel splatter)?

A simple self-hosted runner with an RF chamber and spectrum analyzer catches regulatory violations before field deployment.

### Real Sensor Noise and Environmental Interaction

Simulated sensor values in unit tests are clean; real sensors have:

- **ADC noise**: 1-2 LSB jitter on analog measurements.
- **Thermal drift**: Temperature sensor calibration changes over -20 to +70°C range.
- **Humidity coupling**: Some sensors exhibit hysteresis.

Only hardware-in-the-loop testing with real sensors under varied environmental conditions reveals these issues.

### Boot-Loader and OTA Integrity

A hosted CI can test firmware images, but cannot verify:

- **Bootloader resets during OTA**: Does device recover after power loss mid-update?
- **Rollback mechanism**: Can the device safely fall back to prior firmware if update fails?
- **Flash bank swapping**: Are both firmware partitions correctly managed?

Real hardware with controlled power cycling (relay, power supply, load injection) validates these critical paths.

---

## 10. Setting Up a Self-Hosted Runner: Checklist

### Hardware Prerequisites

For a small IoT project (1-2 builds/day):
- Raspberry Pi 5 (8 GB RAM), 500 GB USB SSD, active cooling. Cost: ~$200.
- USB hub with power (for multiple flashing devices).
- Relay board for power-cycling test hardware.

For active projects (10+ builds/day):
- Ampere Altra (80+ cores, real ARM64) or Graviton2 (AWS).
- Or: 4x Pi 5 cluster, redundancy via load balancing.

### Software Setup

```bash
# On Pi or ARM runner
mkdir ~/actions-runner && cd ~/actions-runner

curl -o actions-runner-linux-arm64.tar.gz \
  https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-arm64-2.317.0.tar.gz
tar xzf actions-runner-linux-arm64.tar.gz

# Configure (interactive)
./config.sh --url https://github.com/OWNER/REPO \
            --token XXXXX \
            --labels self-hosted,linux,arm64,esp32 \
            --name hil-runner-1 \
            --runnergroup default

# Install and start service
sudo ./svc.sh install
sudo ./svc.sh start

# Check status
sudo systemctl status actions.runner.OWNER-REPO.hil-runner-1.service
```

### Firewall and Network

- Self-hosted runners initiate outbound HTTPS to api.github.com (GitHub.com IP blocks).
- No incoming ports required (webhook delivery is GitHub → runner polling).
- Use a private VPN or restricted network if sensitive data is handled.

---

## 11. Cost Analysis: Self-Hosted vs. Hosted Runners

### GitHub-Hosted Runners (Paid Model)

- **Linux (ubuntu-latest)**: Free for public repos, $0.008/min for private.
- **macOS**: $0.08/min (10x Linux).
- **ARM64 (public preview)**: Free tier (limited), paid tier TBD.

For an embedded project building 10x/day, 20 min each:
- 10 builds × 20 min/day × 30 days/month × $0.008/min = ~$48/month (Linux).

### Self-Hosted Runners (Capital + Operational)

- **Raspberry Pi 5 + SSD + cooling**: ~$250 upfront, $5/month power.
- **Ampere Altra**: ~$4000/month cloud instance (overkill for most projects).
- **Fan maintenance, SD-card replacement**: ~$50/year per runner.

For the same 10 builds/day:
- Amortized over 3 years: ($250 + 5×36) / 36 = ~$12/month + labor.

**Break-even**: Self-hosted becomes cheaper after ~12 months of continuous CI usage.

---

## 12. Security Best Practices for Self-Hosted Runners

### 1. Use Private Repositories

GitHub's documentation strongly recommends self-hosted runners only for private repositories. A public repo fork can submit a PR with malicious CI steps that execute on your self-hosted runner (stealing secrets, uploading firmware artifacts).

### 2. Secrets Management

- Store OTA signing keys, API tokens, and credentials in GitHub Secrets at org/repo level.
- Restrict secret access to release workflows (`if: github.ref_name == 'release/*'`).
- Avoid logging secrets; GitHub masks known patterns, but use `::add-mask::` for custom values.

### 3. Network Isolation

- Self-hosted runners should not be exposed to public internet.
- Use VPN, private network, or DMZ if in cloud.
- Restrict outbound access to known GitHub, package registry (PyPI, npm), and artifact servers.

### 4. Runner Authentication

- Rotate runner registration tokens every 30-90 days.
- Use GitHub's Actions Runner Controller (ARC) for Kubernetes-based autoscaling with ephemeral runners.
- Monitor runner logs for unexpected activity.

### 5. Firmware Artifact Signing

Always sign firmware before publishing to release. Use constant-time comparison on devices for signature verification. Never trust unsigned firmware, even from "trusted" sources (downstream integrators, partners).

---

## 13. Troubleshooting and Monitoring

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Runner offline | Process crashed, network lost | Check systemd journal; restart service; verify firewall |
| Slow builds | Thermal throttle, cold cache | Monitor temp; pre-cache toolchains; upgrade to SSD |
| Build timeout | Hung esptool, serial port blocked | Add timeouts; release USB ports after each job; use flock |
| OOM (out of memory) | Large parallel matrix on small Pi | Reduce matrix parallelism; increase swap (wears storage) |
| Flaky tests (HIL) | Timing issues, USB glitches | Add retry logic; serial handshake; probe board health pre-test |

### Monitoring

```bash
# Install node-exporter for Prometheus metrics
curl https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-arm64.tar.gz | tar xz
sudo mv node_exporter-1.7.0.linux-arm64/node_exporter /usr/local/bin/
sudo systemctl enable node-exporter

# Prometheus scrape config:
# - job_name: 'pi-runner-1'
#   static_configs:
#     - targets: ['192.168.1.50:9100']

# Alert on metrics:
# - CPU temp > 75°C
# - Disk write latency > 100ms
# - Runner offline > 5 min
```

---

## 14. Future Directions

### Serverless Self-Hosted Runners

GitHub Actions Runner Controller (ARC) enables ephemeral, auto-scaling runners in Kubernetes. Each job gets a fresh container; no state persists between runs. This reduces security concerns and SD-card wear at the cost of cache misses.

### Hardware Test Rig as a Service

Services like Golioth and Memfault provide cloud-based hardware testing, eliminating the need to maintain physical test rigs. Cost is per-device-per-test, suitable for large fleets.

### Distributed Firmware Signing

Trusted hardware security modules (HSM, TPM) for storing OTA keys instead of GitHub Secrets. Requires on-premise signing infrastructure.

---

## Conclusion

Self-hosted GitHub Actions runners are essential for embedded IoT firmware CI/CD. They enable:

1. **Massive toolchain caching** (5-15 GB per project), reducing build time from 30 min to 2 min.
2. **Real hardware testing** via USB flashing, serial assertions, and power injection.
3. **Native ARM64 builds** eliminating QEMU emulation overhead.
4. **OTA firmware signing** with constant-time verification for supply chain security.
5. **Reproducible builds** through toolchain pinning and Docker image hashing.

The investment (Pi cluster, test rack, monitoring) pays for itself within 12-18 months through reduced CI costs and faster iteration cycles. Industry leaders like Espressif, ESPHome, and RIOT-OS rely on self-hosted runners for their embedded workflows; the pattern is proven and battle-tested.

---

## References

- [GitHub Actions: Self-Hosted Runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners)
- [Ferrous Systems: Hardware-in-the-Loop Testing with GitHub Actions](https://ferrous-systems.com/blog/gha-hil-tests/)
- [PlatformIO Documentation: GitHub Actions](https://docs.platformio.org/en/stable/integration/ci/github-actions.html)
- [Espressif ESP-IDF CI Action](https://github.com/espressif/esp-idf-ci-action)
- [Docker: Reproducible Builds with GitHub Actions](https://docs.docker.com/build/ci/github-actions/reproducible-builds/)
- [Interrupt: Secure Firmware Updates with Code Signing](https://interrupt.memfault.com/blog/secure-firmware-updates-with-code-signing)
- [Golioth: Hardware-in-the-Loop Testing](https://blog.golioth.io/golioth-hil-testing-part1/)
- [Zephyr Project: Testing with CMock/Unity and Renode](https://www.zephyrproject.org/testing-zephyr-rtos-software-using-new-cmock-unity-module-and-renode/)

