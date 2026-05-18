# gh-actions-self-hosted — /learn deep + comparison

P'Nat's class directive 2026-05-09 in #road-to-dev:
> "all learn gh actions self hosted ! github actions self hosted ultrathink /team-agents 5"
> "then compare with apache airflow / dagster and anything else?"

5 parallel agents + comparison synthesis. ~5500 lines total.

## Files

| Dim | File | Lines |
|-----|------|------:|
| Architecture | [arch.md](./arch.md) | 1107 |
| Security | [security.md](./security.md) | ~120 |
| Setup recipes | [setup.md](./setup.md) | 1588 |
| IoT patterns | [iot.md](./iot.md) | 838 |
| Operations | [ops.md](./ops.md) | 1533 |
| Comparison vs Airflow/Dagster/etc | [comparison.md](./comparison.md) | ~150 |

## Top-line takeaways

**Architecture**: Long-poll listener + per-job worker, C# binary, persistent vs ephemeral. Single concurrent job per runner. ARC on k8s is the modern path.

**Security**: Fork-PR + non-ephemeral runner = trivial RCE. PyTorch / TensorFlow / Microsoft DeepSpeed all hit. Mandatory: ephemeral runners + private-repo-only OR workflow splitting + harden-runner.

**Setup**: Bare-metal systemd is "start here". ARC for production. JIT runners via API for ephemeral. Tailscale ACL for zero-public-IP. philips-labs/terraform-aws-github-runner for AWS spot autoscale.

**IoT patterns**: Self-hosted is required (not optional) for embedded — toolchain size, real hardware, ARM-native, OTA signing. ESP32 build farm, HIL test rigs, Pi cluster runners. ESPHome / Espressif / RIOT-OS / Zephyr all use this pattern.

**Operations**: Break-even ~3000-10000 min/month vs hosted. Spot + scale-to-zero is the cost lever. Heartbeat + disk monitor + zombie cleanup are the daily ops. Harden-runner + ARC metrics + Grafana dashboard for monitoring.

**Comparison**: GH Actions = git-trigger CI. Airflow/Dagster = scheduled data orchestration. Argo/Tekton = k8s-native workflow. Temporal = durable app workflow. Picking by trigger source + state model + programming language preference, not by tool buzz.

## IOTBOY routing decision

```
firmware lifecycle  → GH Actions self-hosted (HIL + esp-idf cache)
telemetry ETL       → Dagster (asset model) or Airflow
device alerting     → MQTT broker rule + webhook (latency)
OTA rollout         → Temporal (durable per-device state)
fleet health report → Dagster nightly asset + GH cron backup
```

## Sources

See per-file source citations.
