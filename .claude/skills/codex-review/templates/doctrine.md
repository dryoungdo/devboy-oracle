# Codex Review Template: Doctrine

Review doctrine, AGENTS/CLAUDE instructions, workflow rules, and command docs. Focus on factual accuracy and operational safety.

Verify:

(1) Scope: identify which rule, command, workflow, or identity instruction changed.

(2) Evidence: inspect the edited text plus referenced scripts, command dispatch tables, docs, and nearby doctrine that may conflict.

(3) Risks:
- Factual errors: claiming a command/feature does not exist when it is coded but unrouted, undocumented, disabled, or available under another path.
- Rule conflicts: new instructions contradict AGENTS.md, CLAUDE.md, shared doctrine, safety rules, or existing command semantics.
- Unsafe absolutes: "always/never" rules without clear scope, escape hatch, owner, or verification step.
- Stale examples: command examples point at wrong panes, paths, branches, issue numbers, or flags.
- Operational ambiguity: reader cannot tell who acts, when to stop, what to verify, or how to report done/stuck.

(4) Verdict: list findings first with exact file/line and the corrected wording or verification needed. If clean, say `CLEAN: no doctrine accuracy or safety issue found in reviewed scope.`

Treat doctrine as executable policy: every claim should survive grep and command-path verification.
