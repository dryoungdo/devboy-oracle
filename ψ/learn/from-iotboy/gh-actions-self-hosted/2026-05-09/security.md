# GitHub Actions Self-Hosted Runner — Security

> Compiled from agent research 2026-05-09 (the agent returned prose without writing the file; this is the captured summary).

## TL;DR

Self-hosted runners default-configured on a public repo with `pull_request` triggers = **trivial RCE for anyone who can open a PR**. The fork-PR attack has been weaponized against PyTorch, TensorFlow, Microsoft DeepSpeed, Chia Networks, GitHub itself. Mandatory fix: ephemeral runners + private-repo-only OR strict approval workflow + workflow splitting.

## The fork-PR attack

1. Attacker forks public repo
2. Opens PR with malicious workflow YAML (or with repo code that the existing workflow checks out + executes)
3. Self-hosted runner executes attacker code with the runner's privileges
4. Persistence achieved (non-ephemeral runners keep state)

Notable CVEs / incidents:
- **CVE-2025-61671** — RCE via `workflow_run` + artifact poisoning (CVSS 9.3)
- **PyTorch / TensorFlow / Microsoft DeepSpeed / Chia** (2024) — Sysdig + LegitSecurity disclosed self-hosted runner backdoors
- **GitHub cryptominer campaign** (2021-22) — 1000+ repos exploited, XMRig payloads via fork-PRs

## Default GitHub mitigations and their LIMITS

- "Require approval for outside collaborators" — applies to `pull_request` only, not `pull_request_target`, `workflow_run`, `push`, `schedule`, `workflow_dispatch`
- `pull_request_target` ALWAYS runs with full secrets and write token regardless of approval — the most dangerous trigger
- Approval depends on maintainer reading the diff carefully; trivial obfuscation defeats casual review
- Pre-Feb-2023 repos have legacy default GITHUB_TOKEN with full write — audit and pin to read

## Hard mitigations (in priority order)

1. **Ephemeral runners** via Actions Runner Controller (ARC) on Kubernetes — fresh pod per job, destroyed after
2. **Private repos only** for self-hosted runner pool — eliminates fork-PR vector at the source
3. **Workflow splitting** — `pull_request` workflows are unprivileged (read-only); `workflow_run` triggered after merge handles privileged work
4. **Network egress allowlist** — Cilium/Calico CNP, nftables, or `step-security/harden-runner` Action; allow github.com + your registry only
5. **Don't run runner as root** — `RUNNER_ALLOW_RUNASROOT=1` is forbidden; use systemd `User=github-runner` + hardening (NoNewPrivileges, ProtectSystem, capability drops)
6. **Explicit minimal `permissions:`** in every workflow — never `write-all`, never inherit
7. **Secrets masking is not enough** — base64/hex/JSON-wrapped secrets bypass log redaction; minimize secret scope per job
8. **Container hardening** — runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities, user namespaces

## Tools

- **`step-security/harden-runner`** — EDR-style monitoring + egress block, audit mode → enforce mode
- **Actions Runner Controller (ARC)** — Helm chart, ephemeral pods, RBAC isolation
- **`philips-labs/terraform-aws-github-runner`** — security-hardened AWS runner module (spot, ephemeral, scale-to-zero)
- **Cilium / Tailscale ACL** — fine-grained egress
- **trufflesecurity/trufflehog** — pre-commit + log scan for accidental secret leakage

## Incident response (if compromised)

- 0–5 min: revoke runner registration tokens; rotate GITHUB_TOKEN + repo secrets
- 5–30 min: audit git log for unauthorized commits; check `.github/workflows/` modifications; pull Actions usage logs
- 1–24 h: forensics on runner host (disk image, memory dump); cloud audit logs for unauthorized API calls
- days: switch to ephemeral runners; deploy harden-runner; enforce network policies; staff training

## Sources

- Orca Security: pull_request_nightmare series
- GitHub Security Lab: Preventing PWN Requests
- Sysdig: Self-Hosted Runners as Backdoors (2024)
- Synacktiv: GitHub Actions Exploitation
- LegitSecurity: PyTorch + organization vulnerability disclosures
- Wiz, Praetorian, GitGuardian, StepSecurity hardening guides
