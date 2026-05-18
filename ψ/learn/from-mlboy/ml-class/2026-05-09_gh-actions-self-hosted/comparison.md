# Comparison — GH Actions Self-Hosted vs Airflow vs Dagster vs Others

P'Nat asked: "compare with apache airflow / dagster and anything else?" 3 agents covered Airflow / Dagster / 8 others. All web-sourced 2025-2026.

## TL;DR

GH Actions and Airflow/Dagster solve **different problems**:
- **GH Actions** = CI/CD (code → build/test/deploy), git-triggered, ephemeral compute, scale-to-zero.
- **Airflow / Dagster** = data orchestration (data → transform/train/serve), cron+sensor-triggered, stateful, long-running.

They overlap when CI does data work (training-as-CI on GH Actions GPU runner) — and that overlap is exactly where you should consider switching.

## The matrix that actually matters

| Axis | GH Actions self-hosted | Airflow 3.x | Dagster 1.x |
|---|---|---|---|
| **Trigger** | git push / PR / tag / cron / manual | cron + sensors + backfill + event | asset-state + cron + sensors |
| **State** | stateless per job (git + cache) | metadata DB (Postgres) | run records + asset materializations |
| **Lineage** | none | manual via XComs (experimental) | **native, asset-level, first-class** |
| **Unit of deployment** | workflow file | DAG / task | **asset** (data/model/feature) |
| **Long-running** | painful (>6h timeout, ephemeral) | designed for it (8h+ DAGs normal) | designed for it |
| **Idempotency** | per-job, repo-coupled | explicit task idempotency + retries | explicit asset versioning |
| **Observability** | logs in GH UI, repo-scoped | rich UI: DAG view, lineage, retries | rich UI: asset graph, materializations |
| **Scale-to-zero** | ✅ ephemeral runners | ❌ scheduler/workers always on | ⚠️ run-based but agent stays |
| **Cost model** | per-minute (or self-host idle = ~0) | always-on cluster + workers | OSS free / Dagster+ credit-based |
| **Greenfield fit** | code CI/CD | mature data ETL | modern Python data stack |

## Apache Airflow 3.x

**Status**: Apache Airflow 3.0 GA (April 2025), 3.1+ refining. Major shift: AIP-72 (Task Execution Interface) decouples DAG processor from scheduler — client-server architecture. Astronomer is the dominant managed offering.

**Core model**: DAGs as Python → Scheduler → Workers (Celery/K8s/Local) → Metadata DB (Postgres) → Webserver UI.

**Executors** (when to use which):
- `LocalExecutor` — single-machine, dev only
- `CeleryExecutor` — frequent light tasks, needs Redis/RabbitMQ broker
- `KubernetesExecutor` — heavy isolated tasks, pod-per-task, multi-tenant
- `CeleryKubernetesExecutor` — hybrid (light → Celery, heavy → K8s)

**Strengths**: rich connector library (S3, Postgres, Kafka, Databricks, HF model registry), mature scheduling (cron + sensors + dynamic DAGs), industry-standard.
**Weaknesses**: heavy ops (scheduler + workers + DB + broker), Python DSL learning curve, metadata DB is a critical dependency.

**ML pattern**: scheduled retraining → feature pipeline → train → eval → deploy → monitor → drift-trigger retrain.

Sources: [Airflow 3.0 GA](https://airflow.apache.org/blog/airflow-three-point-oh-is-here/) · [Astronomer MLOps guide](https://www.astronomer.io/docs/learn/airflow-mlops) · [Executor docs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/index.html)

## Dagster 1.x

**Status**: Dagster 1.13.4 (May 2026). Active monthly releases. Dagster Labs maintains. OSS + Dagster+ Cloud (credit-based).

**The distinguishing idea**: **software-defined assets (SDAs)**. Each data object is declared with its upstream deps + computation function. Asset-centric vs Airflow's task-centric. The unit of deployment shifts from "task" to "asset" → automatic lineage, partition-aware backfills, asset-level versioning.

**Distinctive features**:
- **IO managers** decouple data-handling from computation (storage abstracted)
- **Partitions** (time-based, static, 2D, dynamic) with declarative backfill subsets
- **dbt integration** — every dbt model is a Dagster asset, dependency graph spans dbt → ML → inference
- **Type system** with annotation propagation via `AssetIn`

**ML pattern**: dbt features → feature store asset → training asset → model asset → predictions asset, all in one lineage graph. Recomputation triggered by upstream asset changes, not schedules alone.

**Choose Dagster over Airflow** if: greenfield, asset/lineage-first, dbt-heavy, modern Python team.
**Choose Airflow over Dagster** if: mature org, lots of legacy DAGs, need broad ecosystem.

Sources: [Dagster vs Airflow](https://dagster.io/blog/dagster-airflow) · [SDAs concept](https://docs.dagster.io/concepts/assets/software-defined-assets) · [dbt integration](https://docs.dagster.io/integrations/libraries/dbt)

## The "anything else" — 8 more orchestrators

| Tool | Role | Strength | Tradeoff |
|---|---|---|---|
| **Prefect** | Python-native data pipelines | Dynamic DAGs, low friction, hybrid OSS+Cloud | Smaller ecosystem than Airflow |
| **Temporal** | Durable execution | Exactly-once, used at Netflix/Stripe/Mistral | Different mental model (event sourcing) |
| **Argo Workflows** | K8s-native workflow engine | Container-per-step, CNCF graduated | YAML verbose, K8s required |
| **Kubeflow Pipelines** | Full MLOps platform on K8s | Train + serve + tracking unified | Heavy setup, K8s lock-in |
| **Mage AI** | Data transformation, dbt-style | Low-code UI + AI codegen | Newer, smaller ecosystem |
| **Modal Labs** | Serverless GPU functions | 1-sec GPU spin-up, Python decorators | Managed-only, vendor lock-in |
| **Flyte** | ML + data, Lyft origin | Type-strong, immutable versioning, scale | K8s required, steeper curve |
| **Windmill** | Scripts + workflows + UIs | "13x faster than Airflow", multi-language | Newer, fewer integrations |
| **AWS Step Functions / GCP Cloud Workflows** | Cloud-managed | Tight integration with cloud services | Cloud lock-in |

## Decision tree (synthesis)

- **Code-triggered CI/CD** → **GH Actions** (self-host if heavy, GH-host if light or public-repo)
- **Scheduled ETL with rich connectors and a mature ecosystem** → **Airflow**
- **Asset-centric data + dbt + lineage observability** → **Dagster**
- **Mission-critical exactly-once / durable workflows** → **Temporal**
- **K8s-native, container-per-step, ML pipeline** → **Argo Workflows**
- **Full MLOps stack on K8s (train + serve + tracking)** → **Kubeflow**
- **Serverless GPU bursts (no infra)** → **Modal**
- **Python-light, dynamic, pipeline-first** → **Prefect**
- **Type-strong, very-large-scale ML** → **Flyte**
- **Already AWS/GCP, want managed** → **Step Functions / Cloud Workflows**

## What to pick for the DO fleet (my take)

For MLBOY's likely workload (clinic data → train → serve, modest scale):

1. **GH Actions self-hosted (Linux + 1× GPU)** for CI/CD: lint, unit tests, smoke training (1-batch sanity), eval-on-frozen-weights. Repo-native, no extra infra.
2. **Dagster (OSS, self-host)** for data orchestration if/when we need lineage from raw clinic data → features → model → predictions. Worth it because dbt is a likely fit for clinic SQL transforms, and asset-lineage is exactly what Captain will ask for when explaining "why does the model behave this way?"
3. **Skip Airflow** unless we inherit existing Airflow DAGs. Modern stack should default to Dagster.
4. **Modal as escape hatch** for one-off heavy GPU runs that don't fit in CI budget.

Avoid Kubeflow / Flyte until we have actual K8s ops capacity.

🔥⚗️ — MLBOY, the Crucible
