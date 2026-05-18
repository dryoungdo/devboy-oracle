# GitHub Actions Self-Hosted vs Apache Airflow / Dagster / others

> Compiled 2026-05-09 in response to P'Nat's "compare with apache airflow / dagster and anything else" follow-up.

## TL;DR

These tools live in **different lanes**:

- **GitHub Actions** = git-event-triggered CI/CD with workflow YAML
- **Airflow / Dagster / Prefect** = scheduled data orchestration with DAG-as-Python
- **Argo Workflows / Tekton** = Kubernetes-native general workflow engines
- **Temporal** = durable application-level workflow execution

Picking the wrong one costs months. The honest mapping below is opinionated.

## Comparison matrix

```
Tool             Triggers              State model        Native lang     Self-host
─────────────────────────────────────────────────────────────────────────────────
GH Actions       git event, cron,      stateless per      YAML            yes (runners)
                 manual                workflow run

Apache Airflow   cron, manual, sensor  stateful (Postgres backfill,        Python DAG       yes (default)
                                       retries, lineage)

Dagster          schedule, sensor,     stateful, asset    Python (assets)  yes / Cloud
                 asset-driven          materializations

Prefect          cron, event           stateful           Python           Cloud + agent

Argo Workflows   event, cron, manual   stateful (k8s CRDs) YAML+templates  k8s native

Tekton           git event, cron       stateful           YAML+CRDs        k8s native

Jenkins          event, cron, push     stateful           Groovy DSL       yes (default)

GitLab CI        git event             stateless          YAML             native runners

Buildkite        git event             stateless          YAML             yes (agents)

Drone CI         git event             stateless          YAML             yes (containers)

Concourse        version event         stateful (resources) YAML           yes (containers)

Temporal         programmatic          durable (history)  Go / Java / TS   yes / Cloud

AWS Step Funcs   event, manual         durable            JSON             AWS managed

CircleCI         git event             stateless          YAML             limited
```

## When to reach for each

### GH Actions (self-hosted) wins when

- Trigger is a git event (push, PR, release, tag)
- You need real hardware in CI (USB-attached ESP32, GPU, ARM-native)
- Toolchain is too big for hosted (esp-idf 5+ GB cache)
- Org already on GitHub — no new infra
- Job is one-shot and small-state (build → test → publish)

### Airflow wins when

- Hourly/daily/weekly data pipelines with DAG dependencies
- Backfills matter (re-run May 3 for 30 days because schema changed)
- Lineage/audit is a compliance requirement
- Heterogeneous tasks (Python + SQL + bash + spark all in one DAG)
- SLA monitoring on pipeline freshness

### Dagster wins when

- You think in **assets** (this table depends on those tables) not tasks
- You want type-checking, software-defined assets, CI of data pipelines themselves
- Modern Python ergonomics matter (vs Airflow's pickle/serialization legacy)
- You want first-class testing of pipeline logic locally

### Argo Workflows wins when

- You're already on Kubernetes
- You want one engine for both CI and data pipelines
- You like declarative-YAML-with-templates more than Python DAGs
- Throughput needs are high (thousands of parallel workflow steps)

### Tekton wins when

- K8s-native CI specifically, not data
- You want re-usable Tasks/Pipelines as cluster CRDs
- You're building a CI platform (Jenkins X, OpenShift Pipelines)

### Jenkins wins when

- 15-year-old codebase already on Jenkins
- Plugin ecosystem covers your weird requirement
- You have a Jenkins admin team already

### Temporal wins when

- The "workflow" IS your application logic, not a CI step
- Long-running (days, weeks) with retries, timeouts, signals
- Examples: order fulfillment, user onboarding, ML training pipeline that resumes

### Step Functions / managed services win when

- Pure AWS/GCP/Azure ops
- No infra appetite at all
- Workflow density is moderate (cost scales with state transitions)

## Where they overlap and confuse

- **GH Actions for data pipelines** — works for daily ETL with cron triggers, but lacks backfill/lineage. Use for small jobs only.
- **Airflow for CI** — possible (`KubernetesPodOperator` + git triggers via webhook), but you'd be re-inventing what GH Actions gives free.
- **Dagster + GH Actions** — common pairing: GH Actions tests the Dagster code itself, Dagster runs the pipelines.
- **Argo Workflows for both** — works but the DX gap with Python-native Airflow/Dagster bites the data team.

## IoT-Watchtower decision tree (IOTBOY's specific use cases)

```
ESP32 firmware build / test / flash / release
    → GH Actions self-hosted on Pi or Linux box w/ USB attached
    Why: hardware-in-the-loop, esp-idf cache, native ARM build, OTA signing

Clinic sensor telemetry ETL (DHT22 → MQTT → Postgres → daily report)
    → Dagster (or Airflow if team prefers it)
    Why: asset model fits "raw → cleaned → aggregated"; daily schedules; backfill
        when calibration retroactively corrects

Device alerting (temperature > threshold → LINE notification)
    → MQTT broker rule + simple Hono webhook
    Why: latency sensitive; an orchestrator is overkill

OTA rollout strategy (canary 5 devices → 50 → 500)
    → Temporal (durable workflow tracking each device's bootloader state)
    OR → Argo Workflows (if k8s already)
    Why: long-running with retries, signals from devices, partial-failure handling

Fleet health daily report (which BOYs are stale, which devices haven't beaconed)
    → Dagster asset that runs nightly + GH Actions cron as backup
    Why: small DAG, regular schedule, asset framing fits ("fleet health" is the asset)
```

## The deeper insight

CI runners and data orchestrators are converging around **Kubernetes-native ephemeral execution**. Argo Workflows can do GH Actions's job; ARC (k8s self-hosted runners) can do Argo's. The right question isn't "which tool" — it's:

- **Trigger source**: git events → CI tools. Time/event/sensor → orchestrator.
- **State model**: stateless → CI. Backfill/lineage/retries → orchestrator.
- **Programming model**: YAML for config-as-code; Python for data-as-code; Go/Java/TS for app-as-workflow.

For IOTBOY's domain: the firmware lifecycle stays in GH Actions self-hosted (because git triggers it and hardware lives there). The TELEMETRY lifecycle goes to Dagster/Airflow (because schedule triggers it and data depends-on data). They meet at the **artifact handoff** — CI publishes signed firmware to a registry; Dagster's asset checks "is the latest firmware deployed across the fleet?"

## Sources

- Apache Airflow docs (https://airflow.apache.org/docs/)
- Dagster Asset documentation (https://docs.dagster.io/concepts/assets/software-defined-assets)
- Argo Workflows (https://argoproj.github.io/argo-workflows/)
- Tekton Pipelines (https://tekton.dev/docs/pipelines/)
- Temporal docs (https://docs.temporal.io/)
- Buildkite, Drone, Concourse documentation pages
