# /learn — RecallWorks/Recall + `maw mega` (DO fleet team primitive)

**Date**: 2026-05-11 20:38 GMT+7
**Source**: P'Nat directive (msg `1503389823380230234`) — "more on this + we have maw team what is that?"
**URL**: https://github.com/RecallWorks/Recall

## 1. `maw mega` — DO fleet team command

```
$ maw mega --help
mega v1.0.0
  Manage MegaAgent multi-agent teams.
  usage: maw mega [status|stop]

$ maw mega
No teams found. Use /mega-agent or TeamCreate to start.
```

**Key finding**: `maw mega` is a wrapper around Anthropic's native **`TeamCreate`** primitive (the experimental Agent Teams feature we just learned). So `maw mega` = maw's CLI surface for `~/.claude/teams/{name}/`.

**Verdict**: NOT a separate parallel system. It's integration between maw fleet and native Agent Teams. Maw extends Anthropic's primitive with persistent peer + identity layer.

## 2. RecallWorks/Recall — MCP memory + coordination

**Repo**: github.com/RecallWorks/Recall · MIT · Python 3.11+ server

### What it is
A "better memory server for AI agents" — MCP-based persistent memory addressing cold-start problem. Append-only artifact store + vector search + multi-agent coordination primitives.

### Architecture
- Stdio MCP server (plain HTTP + MCP-over-SSE dual transport)
- Local ONNX embeddings (no external API)
- Storage: `~/.recall/` (single-user) or Docker volume (team)
- Ephemeral live store + auto-snapshot to disk
- Rebuildable from artifacts if vector index dies

### 13 MCP tools
- Memory: `remember`, `recall`, `reflect`, `checkpoint`, `anti_pattern`
- Coordination (6 primitives): `claim()`, `release()`, `who_has()`, `claims()`, `handoff()`, `pulse_others()`

### Use cases
- Solo dev with Claude/Copilot/Cursor
- Multi-agent teams dividing work
- Air-gapped offline ops

## 3. Comparison: Recall vs maw fleet vs native Teams

| Concern | Native Teams | maw mega | maw fleet | Recall |
|---|---|---|---|---|
| Scope | Single session | Wraps Teams | Multi-machine | Single host or Docker |
| Identity | Spawn-time only | Spawn-time | Per oracle (CLAUDE.md) | Stateless server |
| Memory | Per-session ctx | Per-session ctx | ψ/memory/, auto-memory | `~/.recall/` artifacts |
| Handoff | Mailbox SendMessage | SendMessage | `maw hey`, ψ/inbox/ | `handoff()` MCP tool |
| Lock | File-locked task list | Same | tmux pane lock | `claim()/release()` |
| Search | None | None | arra-search MCP | ONNX vector |
| Persistence | Dies w/ parent | Dies w/ parent | Survives crash/reboot | Disk snapshot |
| Multi-host | ❌ | ❌ | ✅ federation | ❌ (Docker only) |

## 4. Overlapping primitives across the 3 systems

```
                  native Teams   maw mega   maw fleet   Recall
spawn worker      Agent tool     same       maw bud     n/a
inter-agent msg   SendMessage    same       maw hey     handoff()
shared state      task list      same       maw pulse   claim()/who_has()
identity          spawn-time     same       CLAUDE.md   stateless
memory            none           none       ψ/, arra    remember/recall
crash recovery    no             no         yes         yes (artifacts)
```

## 5. MLBOY take

**Recall fits where DO fleet doesn't (or doesn't yet)**:
- **Vector semantic search** for stored ML experiments/papers — we have arra-oracle-v3 (Thread #2) covering similar ground, but Recall is local ONNX (offline)
- **`anti_pattern` checkpoint** — Rule 1 "Nothing is Deleted" + retrospectives already do this informally; Recall makes it a primitive
- **`claim()/release()` soft-locking** — when MLBOY + FORGEBOY both want to edit same ψ/lab notebook, we'd benefit from a lock primitive (currently relies on tmux pane discipline)

**Recall does NOT replace**:
- maw federation (multi-machine)
- per-oracle identity (CLAUDE.md, philosophy, principles)
- arra Thread (family lineage, generational memory)

**Practical: do NOT install Recall now**. Reasons:
1. ψ/memory/ + auto-memory + arra-oracle-v3 already cover memory + reflection
2. Recall = MCP server addition → MCP attack surface ↑
3. maw mega (when needed) already wraps native Teams
4. Single-machine — doesn't extend our multi-host story

**Possible future**: study Recall's `claim()/release()` semantics, **steal** if soft-locking becomes a pain point (currently isn't — tmux discipline + maw fleet routing handles it).

## 6. Direct answer to P'Nat's question

> "we have maw team what is that?"

`maw mega` — wraps Anthropic's experimental `TeamCreate` (native Agent Teams). Status: no active teams. Currently inert in our fleet (we use **maw fleet + maw hey** for peer coordination instead). When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `maw mega` becomes the CLI to manage `~/.claude/teams/{name}/`.

## Cite

- RecallWorks/Recall: github.com/RecallWorks/Recall (MIT)
- ONNX embeddings (local inference): onnxruntime.ai
- MCP spec: modelcontextprotocol.io
- maw mega plugin: /home/drdo/.maw/plugins/mega (local)

🔥⚗️ — MLBOY
