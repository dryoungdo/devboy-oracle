# Muninn Memory คืออะไร — ฉบับ Captain (ภาษาคน ไม่ jargon)

**วันที่**: 2026-05-11
**ทีม**: IOTBOY + FORGEBOY + MLBOY (3 BOYs ตามที่ Captain แต่งตั้ง)

---

## 0. สรุปสั้นที่สุด

P'Nat ชวนเราคิดว่าจะ "ลอกเลียน" memory system สำหรับ AI agent ตัวใหม่ ชื่อ **Muninn Memory** เขียนด้วย Rust. เราค้นเสร็จแล้ว — เห็นทางเลือก 4 ทาง, แนะนำทางที่สะอาดที่สุด (ไม่ติด patent ของคนอื่น). DO fleet เพิ่มของเราเอง 3 อย่างเข้าไป.

## 1. ปัญหาที่กำลังแก้

AI ตอนนี้ "ลืม" ตลอด. คุยกับ Claude วันนี้, พรุ่งนี้กลับมาคุยใหม่, Claude จำไม่ได้ว่าเมื่อวานคุยอะไร — ต้องเล่าใหม่ทุกครั้ง (เปลือง token, เปลืองเวลา).

**Memory framework** = ระบบจดจำให้ AI. AI พูดอะไร, เห็นอะไร — เก็บเข้าตู้. ครั้งหน้ามาใหม่ AI เปิดตู้ดูได้ว่าเคยรู้อะไรมาก่อน.

## 2. ทำไมชื่อ Muninn

ตำนาน Norse: เทพ Odin มีอีกา 2 ตัว
- **Huginn** = ตัวคิด (Thought) บินไปทั่วโลก เก็บข่าว
- **Muninn** = ตัวจำ (Memory) เอาความรู้กลับมา

P'Nat อยากทำ **Muninn ฝั่งจำ** ก่อน, ฝั่งคิด (Huginn) ค่อยต่อ.

## 3. ของที่มีอยู่แล้วในตลาด (P'Nat รู้แน่อยู่แล้ว)

| ของ | ทำอะไร | จุดเด่น | ปัญหา |
|-----|--------|--------|-------|
| **mempalace** | ห้องสมุดความจำของ AI | ดาว 51,900 ⭐, MIT, ฟรี, benchmark สูง (96.6%) | Python (ช้ากว่า), ห้องคล้าย ๆ กันหมด |
| **MuninnDB** | คลัง engram (หน่วยความจำ + decay) | สด (เพิ่งออก 6 พ.ค.), MCP-native, binary เดียว | **BSL license + จด patent** = ใช้เชิงพาณิชย์ติดเงื่อนไข 4 ปี |
| **Huginn (scrypster)** | ตัวคิด คู่กับ MuninnDB | "Huginn thinks. Muninn remembers." official | BSL เหมือนกัน |
| colliery-io/muninn | Rust + context proxy | Rust อยู่แล้ว, Apache | ดาวน้อย (12 ⭐), ไม่ใช่ memory ตัวจริง |

## 4. ที่ P'Nat อยากทำ — Hard fork เป็น Rust

"Hard fork" = ลอกของเค้ามา แล้วเขียนใหม่จากศูนย์, เปลี่ยนภาษา. เหมือนเอาสูตรกะหรี่ของร้าน A มา cooking ใหม่ที่ครัวของเราเอง.

**ทำไม Rust?** เร็ว, ปลอดภัย, ขึ้น single binary (ไฟล์เดียว run ได้ทุกที่ — server, Pi, ESP32).

**ทำไม fork ไม่ใช้ของเค้า?** Patent + BSL ของ MuninnDB จำกัดเรา. ถ้าเราลอกแนวคิด (ไม่ใช่ code) แล้วเขียนใหม่ MIT/Apache, อิสระ.

## 5. 4 ทางเลือก fork ที่เราเห็น

| ทาง | สูตร | ใช้เวลา | ความเสี่ยง |
|-----|------|---------|------------|
| **A** | port Muninn + Huginn ของ scrypster มาเป็น Rust ทั้งคู่ | 3-4 เดือน | ใหญ่สุด เสี่ยงสุด แต่อิสระสุด |
| **B** | ทำ Rust Muninn อย่างเดียว, ใช้ Huginn Go ของ scrypster ต่อผ่าน MCP | 6-8 สัปดาห์ | ติด BSL ฝั่ง Huginn |
| **C** | ทำ Rust wrapper หุ้มของ scrypster ทั้งคู่ | 3-4 สัปดาห์ | เร็วสุดแต่ยังติด BSL |
| **D ⭐** | **clean-room** จาก mempalace (MIT, ดาว 51.9k) + colliery-io (Apache, Rust ตัว shell อยู่แล้ว) — ไม่แตะ code ของ scrypster เลย, ใช้แค่ตำราเก่า (Anderson 1993 ACT-R, Hebb 1949) | 8-12 สัปดาห์ | สะอาดสุด, ไม่ติด patent, license MIT/Apache |

**ทีมแนะนำ Path D** — สะอาด, รับมรดก benchmark mempalace, ไม่ติดคดี

## 6. DO fleet เพิ่มอะไรเข้าไป (จุดที่ไม่มีใครทำ)

| BOY | scope ของแต่ละคน |
|-----|------------------|
| **IOTBOY (ผม)** | Edge ESP32 / FRAM / LoRa — เครื่องเล็กก็เก็บความจำได้ ไม่ต้องเชื่อม cloud |
| **FORGEBOY** | UI / dashboard / inspector แสดงให้คนเห็นว่า AI จำอะไร, decay ไปแค่ไหน |
| **MLBOY** | ตรวจ benchmark, vector / embedding pipeline, model affinity |
| **LEDGERBOY** | audit trail — รู้ว่าความจำตัวไหน reference จากไหน เมื่อไหร่ |
| **WIREBOY** | n8n / cloud sync — sync ระหว่าง device ↔ central memory |
| **CHATBOY** | ดูดความจำจาก LINE / chat |
| **COACHBOY** | audit ว่าระบบความจำใช้ได้ผลจริงไหม |

**RTK + pordee + Oracle ψ/memory** — DO fleet มีเครื่องมือพื้นฐานพร้อมแล้ว (RTK ประหยัด token 49.7%, pordee ตัดจำนวน token สั้นลง, Oracle ψ/memory เป็นโครงสร้างความจำเดิม). Muninn Memory เสริมจากของพื้น, ไม่ใช่แทน.

## 7. ขั้นถัดไป — ขอ Captain เคาะ

1. **เลือก path** (A/B/C/D) — แนะนำ D
2. **เลือกที่อยู่ repo** — `nazt/muninn-memory` (P'Nat's GitHub) หรือ org ใหม่ (`cmmakerclub` / `buildwithoracle`)
3. **License target** — MIT / Apache-2.0 / dual?
4. **ทีม commit** — DO fleet รับ embedded + UI + ML (ทำตามที่ผมเสนอ) หรือเปลี่ยน split?
5. **Timeline** — v0.1 ใน 8 สัปดาห์ (D) เร็วได้ไหม

ถ้า Captain เคาะ Path D + green light:
- IOTBOY clone `mempalace` + `colliery-io/muninn` ลง `ψ/learn/` ภายใน 24 ชั่วโมง
- IOTBOY draft Rust workspace `Cargo.toml` + 7 crate stubs
- IOTBOY ทำ PoC `muninn-core::hebbian_update` + `actr_activation` มี unit tests
- PR-ready commit ภายใน 24-48 ชั่วโมง

## 8. ที่ทีมยืนยันแล้วทาง technical (ไม่ใช่ marketing)

- **Hebbian formula** = สูตรคณิตศาสตร์ พิสูจน์ปี 1949 (Donald Hebb) — เก่า ใช้ได้ ไม่ติด patent
- **ACT-R decay** = สูตรปี 1993 (John Anderson) — ตำราจิตวิทยา cognitive
- **Bayesian confidence** = Thomas Bayes 1763 — เก่ามาก, ไม่มีใคร patent ได้
- **MuninnDB benchmark "+21% Recall@10"** = เคลมจากข้อมูล synthetic 2,000 ตัว ไม่ใช่ benchmark สาธารณะ
- **mempalace 96.6% LongMemEval R@5** = benchmark จริง สาธารณะ ตรวจซ้ำได้
- **mempalace 51,900 ดาว** vs MuninnDB 285 ดาว — community vote ชัด

## 9. ความเสี่ยงที่ทีมเห็น

| ความเสี่ยง | ขนาด | แก้ยังไง |
|------------|------|----------|
| ใช้เวลานานเกิน, รบกวนการเรียน ESP32 ของ Captain | กลาง | ส่งงานเข้าคน fleet อื่น (per Captain's directive) |
| License conflict ถ้าเผลอใช้ code MuninnDB | สูง | clean-room — ไม่อ่าน code BSL, ใช้แค่ docs สาธารณะ + ตำราเก่า |
| MLBOY offline ตอนเขียน report (ทุกวันนี้) | กลาง | IOTBOY ทำ technical verification เอง, post Discord เอง |
| Patent ของ scrypster อาจ overlap | ต่ำ-กลาง | cite prior art (Anderson 1993, Hebb 1949) ตรงๆ ในทุก commit/docs |

---

**Bottom line ครับ Captain**: P'Nat ถามถูกที่ที่จะถาม — เรา 3 BOYs ค้นมาเต็มที่ + เห็น path ที่สะอาด + รู้ว่า DO fleet เสริมอะไรได้. ขอ green light Path D + repo location, เริ่มลงมือใน 24 ชั่วโมง.

🔭 IOTBOY (research lead)
🔨 FORGEBOY (visual)
🧠 MLBOY (tech verify — ตอน offline, IOTBOY cover แทน)
