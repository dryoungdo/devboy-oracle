# Research — GitHub Actions Self-Hosted Runners (2026-05-09 class)

P'Nat's class assignment 2026-05-09 ~15:55 GMT+7. 5 parallel Haiku agents covering Architecture & Lifecycle · Security · Scaling · Cost · ML angle. All findings web-sourced (2025-2026 references).

## Headline

Self-hosted runners are cheaper at scale (especially macOS / GPU / heavy Linux), but the security model only works with **ephemeral runners + JIT registration + private repos**. Persistent runners on public repos = catastrophic. Modern scaling = **ARC v0.13.0 + RunnerScaleSet** (event-driven, not HPA-polled).

---

## 1. Architecture & Lifecycle

- **JIT registration**: `POST /orgs/{org}/actions/runners/generate-jitconfig` issues a **single-use token, 1-hour TTL, auto-deregisters after one job**. Replaces the long-lived registration token where exposure window matters.
- **Long-poll protocol** (Depot blog): Runner makes a 50-second long-poll to GitHub broker; server holds connection open; returns 202 if no jobs; runner loops until `RunnerJobRequest` arrives. **Pull-based, never pushed-to** — runner offline means no assignment, not job failure.
- **Ephemeral flag** (`--ephemeral`): runner unregisters after one job. Clean-slate per job.
- **Default labels**: `self-hosted`, OS (`linux`/`windows`/`macOS`), arch (`x64`/`ARM`/`ARM64`). Custom labels for routing.
- **60-second timeout cliff**: queued job that doesn't get picked up in 60s re-queues. Important for autoscaler races.
- **Workspace state persistence**: `_work` dir on persistent runners carries between jobs unless explicitly cleaned. Ephemeral kills this.
- **Runner version enforcement**: as of 2026-03-16, GitHub blocks registration from runners older than v2.329.0 (Oct 2025). Auto-update is on by default.

Sources: [GitHub Changelog: JIT runners](https://github.blog/changelog/2023-06-02-github-actions-just-in-time-self-hosted-runners/) · [Depot: Listener architecture](https://depot.dev/blog/github-actions-runner-architecture-part-1-the-listener) · [GitHub Docs: labels](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-labels-with-self-hosted-runners) · [GitHub Docs: choosing the runner](https://docs.github.com/actions/using-jobs/choosing-the-runner-for-a-job)

## 2. Security Model — the heaviest dimension

**Hard rule**: do **not** run self-hosted on public repos with persistent runners. GitHub itself says so.

- **Public + persistent = RCE**: any fork contributor can submit a workflow that grabs filesystem, env vars, cached secrets, network. They don't need write access — fork + PR is enough if `pull_request_target` is in play.
- **`pull_request_target` foot-gun**: workflow runs in **base-repo context** with the write-scoped `GITHUB_TOKEN` and secrets, but if `actions/checkout` is asked to check out the PR head ref, attacker code executes with those secrets.
- **Ephemeral runners as trust boundary**: single-job-per-runner kills persistence chains. GH-hosted has this for free; self-hosted needs JIT + ephemeral pattern explicitly.
- **Scope amplification**: org/enterprise runners run jobs from many repos — compromise on any one can pivot. Use runner groups + labels to isolate.
- **Recent CVEs / incidents**:
  - **CVE-2025-30066** (Mar 2025): `tj-actions/changed-files` retroactively poisoned 23k repos; injected Python pulled secrets from runner memory and dumped to GitHub logs (which are public if the repo is public).
  - **CVE-2025-61671** (Aug-Sep 2025, CVSS 9.3): `pull_request_target` + checkout-PR-head misconfig → reverse shell → token piracy.
  - **Shai Hulud v2 (Nov 2025)**: 20k repos + 1.7k npm versions via `pull_request_target` abuse.
  - **GhostAction (Sep 2025)**: 327 accounts, 817 repos, 3,325 secrets stolen.
- **Network egress blind spot**: runner-to-attacker C2 over HTTPS:443 looks identical to legit GitHub traffic without runner-level instrumentation (Harden-Runner / step-security).

Sources: [GitHub Secure Use](https://docs.github.com/en/actions/reference/security/secure-use) · [Sysdig: backdoors](https://www.sysdig.com/blog/how-threat-actors-are-using-self-hosted-github-actions-runners-as-backdoors) · [Wiz hardening guide](https://www.wiz.io/blog/github-actions-security-guide) · [Orca: Pull Request Nightmare 1](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/) · [GitHub Security Lab: Pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/) · [GHSA mrrh-fwg8-r2c3](https://github.com/advisories/ghsa-mrrh-fwg8-r2c3)

## 3. Scaling — ARC + RunnerScaleSet

- **Actions Runner Controller (ARC) v0.13.0** released 2025-10-16: GitHub-official Kubernetes operator. Adds container lifecycle hooks (replacing ReadWriteMany volume hacks) and Red Hat OpenShift GA.
- **RunnerScaleSet** (modern) supersedes legacy **RunnerDeployment**. Architecture: GitHub API `RunnerScaleSet` + `EphemeralRunnerSet` + `AutoscalingListener`. **Event-driven via GitHub webhooks**, not Kubernetes HPA polling — sub-second queue awareness.
- **Pod-per-job ephemeral**: ARC allocates one pod per workflow job, deletes after job confirms. Clean per-job env, no state leak.
- **Roadmap**: 0.14.0 (planned March 2026) adds multi-label runner assignment; "scale set client" (Public Preview 2025) lets you build custom autoscalers without K8s.
- **Spot / preemptible**: `philips-labs/terraform-aws-github-runner` handles 2-min interrupt gracefully. AWS Spot saves 50-80%. Best for re-runable jobs (lint, unit, build), risky for customer-blocking deploys.
- **Managed alternatives**: **RunsOn** claims 90% cost reduction via hybrid orchestration; Northflank, Cirun, Ubicloud also play here.

Sources: [GitHub Changelog: ARC 0.13.0](https://github.blog/changelog/2025-10-16-actions-runner-controller-release-0-13-0/) · [Ken Muse: Two ARCs](https://www.kenmuse.com/blog/the-two-github-arcs/) · [GitHub Docs: ARC](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller) · [philips-labs/terraform-aws-github-runner](https://github.com/philips-labs/terraform-aws-github-runner) · [RunsOn](https://runs-on.com/)

## 4. Cost & Economics

- **GH-hosted prices (Jan 2026)** after the price cut: Linux **$0.006/min**, Windows **$0.010/min**, macOS **$0.048/min**.
- **macOS multiplier**: still ~8x Linux. macOS-heavy teams break even on a $400/mo Mac mini at ~100 macOS jobs/month.
- **Self-hosted platform fee (Mar 2026)**: GitHub charges **+$0.002/min on private repos**, public repos exempt. Was free until then.
- **Break-even**: at 100k min/month private = $200 platform fee + your infra. Beats $360 (100k × $0.006 Linux) once your infra is < $160/mo. Spot makes that easy.
- **Real case studies**:
  - **Featherless** (Mac CI): saved $4k+/month switching to 2 Mac minis ($398/mo rental vs $4,191/mo GH macOS).
  - **Lumafield** (Linux): 75-77% savings with EKS Auto Mode + Spot EC2.
- **Hybrid sweet spot**: GH-hosted for trivial (lint/unit/free-quota) + self-hosted for >30min compile/integration/ML.

Sources: [GitHub: pricing reduction Jan 2026](https://github.blog/changelog/2026-01-01-reduced-pricing-for-github-hosted-runners-usage/) · [GitHub: simpler pricing Mar 2026](https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/) · [Featherless: Mac mini self-host](https://jeffverkoeyen.com/blog/2025/10/17/SelfHostingMacMinis/) · [Lumafield: Spot 75%](https://barndoors.lumafield.com/maximizing-ci-speed-and-75-savings-why-we-moved-to-aws-spot-instances/)

## 5. ML Angle — GPU runners + training-as-CI

- **GPU runner pattern**: Linux runner with NVIDIA Container Toolkit + CUDA, labels `[self-hosted, linux, gpu]`. Common: 1× A10G or 1× A100 attached.
- **HF cache** (`~/.cache/huggingface/`): can exceed 50GB. Persist on runner disk for warm cache OR re-tar via `actions/cache` between jobs. Trade: warm = fast but persistent runner = security risk.
- **Training-as-CI** patterns:
  - PR triggers **smoke train** (1-5 min, 1 batch, asserts gradient/loss decreases).
  - Merge-to-main triggers **full train** with reproducibility (seed, env hash, data version).
  - PR comment from CML reports metrics on every PR (Iterative.ai pattern).
- **Reproducibility tax**: `torch.manual_seed`, `cuda.manual_seed_all`, `set_deterministic(True)`. ~10-15% overhead. PyTorch does NOT guarantee bit-exact across hardware/versions.
- **When training-as-CI breaks**: jobs > 6h timeout, GPU contention during PR bursts, OOM on multi-tenant runners.
- **Alternatives**: **Iterative CML**, **Argo Workflows** (K8s-native), **Modal Labs** (serverless GPU API), **Replicate**, **Kubeflow** (full MLOps stack — uses Argo under hood).

Sources: [Pockit: monorepo runner guide 2026](https://pockit.tools/blog/github-actions-monorepo-runners-guide-2026/) · [HF Hub: cache mgmt](https://github.com/huggingface/huggingface_hub/blob/main/docs/source/en/guides/manage-cache.md) · [Iterative CML](https://github.com/iterative/cml) · [Pipekit: Argo vs Kubeflow](https://pipekit.io/blog/kubeflow-vs-argo-workflows)

---

## Cross-cutting takeaways

1. **JIT + ephemeral + private = the safe trio**. Anything else has known exploit class.
2. **ARC RunnerScaleSet is the modern path**. Legacy RunnerDeployment + HPA still works but is not the recommended new build.
3. **macOS economics**: if you do >100 mac CI jobs/month, self-host. Period.
4. **Public repo? Use GH-hosted**. The security model on self-hosted assumes private trust boundary.
5. **ML on Actions** is great for smoke/eval + small fine-tunes. For >6h training, push to Argo / Modal / Kubeflow — Actions isn't built for long-running stateful jobs.
6. **The free era is ending** — March 2026 platform fee for self-hosted on private repos. Tiny but it's a signal: GitHub wants ARC + Larger Runners + paid platform, not unmanaged self-host.

---

🔥⚗️ — MLBOY, the Crucible
