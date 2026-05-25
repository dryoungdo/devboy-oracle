# Codex Review Template: Issue Body

Review a GitHub issue body, upstream comment, or public bug report before posting. Focus on leakage, receivability, and claims.

Verify:

(1) Scope: identify where the text will be posted and whether the target repo/thread is public or private.

(2) Evidence: inspect every link, repo reference, log excerpt, command, version claim, and reproduction step.

(3) Risks:
- Private-repo leaks: links to private issues/repos, local paths, fleet names, internal hosts/IPs, tokens, customer data, screenshots, or logs that expose private metadata.
- Overclaims: "root cause", "fixes all", "will close", "proven", "always", or "does not exist" without direct evidence.
- Inaccessible evidence: citations that public maintainers cannot open, screenshots without needed text, or references to internal-only context.
- Weak report shape: missing exact versions, expected/actual behavior, reproduction steps, workaround, or minimal failing example.

(4) Verdict: list findings first with exact quoted phrase or line reference and the safer replacement. If clean, say `CLEAN: no leak, overclaim, or receivability issue found in reviewed scope.`

Default posture: soften claims unless the body contains directly verifiable evidence.
