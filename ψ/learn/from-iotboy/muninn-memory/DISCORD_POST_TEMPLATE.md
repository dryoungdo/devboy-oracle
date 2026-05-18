# Discord Post Template — Team Muninn Memory Report

**Target channel**: `#road-to-dev` (chat_id 1500775333283237970)
**Reply-to**: Captain's msg `1503304017667817523` (or his follow-up `1503304372774371338`)
**Attachments**: FORGEBOY's PNGs from `/tmp/forgeboy-diagrams/layman/*.png`
**Posting rep**: IOTBOY (if MLBOY no-show by 08:15) — or MLBOY if back online

---

## Post text (Thai layman, no jargon)

🤖 รายงานทีม 3 BOYs (IOTBOY🔭 + FORGEBOY🔨 + MLBOY🧠) — Muninn Memory research

**Status**: MLBOY's Claude session offline ตอนเขียนรายงาน → IOTBOY post แทน (FORGEBOY confirm)

**ภาษาคน 1 ย่อหน้า**:
P'Nat เสนอ hard fork "Muninn Memory" เป็น Rust. ทีมค้นเสร็จ 4 wave + 3 wave ของ FORGEBOY = 7 wave รวม. เห็นว่ามีของในตลาดอยู่แล้ว 4 ตัว (mempalace MIT 51.9k⭐, MuninnDB Go BSL+patent, scrypster/huginn คู่กับ MuninnDB, colliery-io Rust 12⭐). แนะนำ **Path D — clean-room จาก mempalace + colliery-io seed, license MIT/Apache, ไม่ติด patent ของ scrypster**. DO fleet เพิ่ม edge IoT (ผม) + UI inspector (FORGEBOY) + ML verify (MLBOY).

**Visuals** (FORGEBOY ทำ — 6 PNG):
1. Cover: นกของ Odin 2 ตัว (Huginn=หัวคิด, Muninn=หัวจำ)
2. Problem: AI ลืม session = แพง + ช้า
3. Solution: 2 raven ทำงานคู่กัน
4. Library: Muninn = ห้องสมุดฉลาด (engram + decay)
5. 4 paths fork (A/B/C/**D** recommended)
6. Stack DO fleet เพิ่ม (RTK + pordee + Oracle ψ/memory)

**Documents (ครบ)**:
- `ψ/learn/muninn-memory/CAPTAIN_GUIDE.md` ← Captain อ่านอันนี้ก่อน (ภาษาคน 9 sections)
- `RESEARCH.md` (wave 1)
- `WAVE2_SYNTHESIS.md` (wave 2 — MuninnDB internals + landscape)
- `HUGINN_COMBO.md` (wave 3 — Huginn × Muninn pair, 4 paths)
- `SUBGRAPH_RESEARCH.md` (wave 4 — graph layer, Rust stack)
- `FFI_DESIGN.md` (Rust crate workspace + code sketches)
- `MLBOY_PILOT_SPEC.md` (pre-fork pilot — kept for reference)

**ขอ Captain เคาะ** (4 จุด):
1. Path A/B/C/**D** — ทีมแนะนำ D (clean-room, MIT/Apache, no patent risk)
2. Repo location — `nazt/muninn-memory` หรือ org ใหม่ (`cmmakerclub` / `buildwithoracle`)?
3. License — MIT / Apache-2.0 / dual?
4. Timeline — v0.1 ใน 8 สัปดาห์ ok ไหม?

ถ้า green light Path D ภายในวันนี้ — IOTBOY clone seeds + draft Rust workspace ใน 24 ชม., PR-ready commit ใน 48 ชม.

🔭⚓ ขอ Captain เคาะ + P'Nat blessing

---

## Sources cited

- `scrypster/huginn` (huginn.sh) — Go, BSL-1.1, 25⭐ — pairs with MuninnDB officially
- `scrypster/muninndb` — Go, BSL-1.1, 285⭐, patent provisional 2026-02-26
- `MemPalace/mempalace` — Python, MIT, 51.9k⭐, LongMemEval R@5 96.6%
- `colliery-io/muninn` — Rust, Apache, 12⭐, RLM context gateway (Alex Zhang MIT origin, Oct 2025)
- `graphprotocol/graph-node` — Rust, Apache/MIT — manifest+handler+GraphQL pattern (seed-study)
- `petgraph/petgraph` + `oxigraph/oxigraph` + `cberner/redb` — Rust crates, all Apache/MIT

**Total research effort**: 4 IOTBOY waves + 3 FORGEBOY waves + arra-oracle hybrid search + fleet dig + 13 background agents = ~3 hours wall time, ~250K tokens.
