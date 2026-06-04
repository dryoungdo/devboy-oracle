# 🧬 Artistic DNA — Michelangelo Buonarroti (sculpture / 3D form)

> A reusable "genome" for **3D modeling** — form that has mass, tension, and life, not a smooth box.
> Sibling to [`artistic-dna-davinci-vangogh.md`](./artistic-dna-davinci-vangogh.md) (2D viz / color / flow). **Both kept.**
> This one loads when the deliverable is a **3D model / sculpted form / CAD enclosure**, not a flat render.
> Extracted by DEVBOY (⚗️ The Lab) per Captain directive 2026-06-04 ("คิดว่าตัวเองเป็นเทพด้านปั้น Model 3D · Michelangelo", msg 1511949664570839173). Cite-then-claim — sources at bottom.

---

## Why this exists
Da Vinci/Van Gogh are **painters** — their genome fixes flat viz (sfumato glow, swirling color). But a 3D model is **sculpture**, a different problem: it must read as solid mass from every angle, hold tension, and know when to stop being polished. Michelangelo is the sculptor's genome. Where Da Vinci *observes then draws*, Michelangelo *sees the finished form already inside the block and removes everything else.* That is not a metaphor for CAD — it is literally `difference()`.

---

## 🧬 Genome — MICHELANGELO (mass, tension, the figure in the marble)

| Gene | The principle | Gene expression (3D / OpenSCAD / render translation) |
|---|---|---|
| **subtractive — "il marmo"** | *"I saw the angel in the marble and carved until I set him free."* Form is made by **removal**, not assembly. The shape is already in the block. | **Model as `difference()` from a solid block**, not additive `hull()` of primitives. Start with the full mass, carve recesses/screen/vents/ports OUT of it. CSG subtraction = the sculptor's chisel. |
| **non-finito** | The deliberately *unfinished* (the Prisoners/Slaves) — figures half-emerging from rough stone. Knowing where to **stop**; polish kills life. | Don't over-smooth. `$fn` high enough to read curved, not so high it's plastic-dead. Leave intentional texture (bevels, chamfers, tool-mark grooves). A perfectly smooth box is a corpse. |
| **terribilità** | Awesome power / emotional intensity / grandeur (the Sistine, Moses, David). Presence that *commands*. | Give the object **mass and stance** — it should look heavy, planted, important. Dramatic proportion over timid. The ARRA terminal is a small idol, not a gadget. |
| **contrapposto / figura serpentinata** | Weight-shift + spiral twist (David's hip, Victory's coil). Life = asymmetric counter-poise; never static frontal symmetry. | Build in **a lean / a twist** — the screen face *tilts up* (เงยหน้า) to meet the eye, not flat-frontal. Off-axis camera. Energy comes from the break in symmetry, exactly the "เอียงผิดด้าน" fix P'Nat flagged. |
| **disegno + anatomy** | Drawing/structure is the foundation of ALL art; obsessive anatomical study → volume that's correct from inside out. | **Underlying structure first** (the corrected 2D เขียนแบบ = the disegno), THEN the surface. Mass must read true from every turntable angle, because the volume is real, not faked on one face. |
| **chiaroscuro of carved form** | Form is revealed by **light raking across depth** — deep shadow in the recesses, bright on the high planes. | Render with a strong directional **key light raking low**, deep shadows in screen recess / vents / grille. Light is how the carving *speaks*. Flat even lighting hides the sculpture. |

---

## 🧬 The splice (breakthrough rule)
> **Stop assembling a box from parts. Start with the full block and carve the form out of it.**
> The marble (solid mass) already contains the ARRA terminal — `difference()` removes everything that isn't it.
> Then: give it a lean (contrapposto), rake the light across the carving (chiaroscuro), and stop before it goes plastic-smooth (non-finito).

Concrete recipe (OpenSCAD):
- **block first**: one solid wedge mass (the marble), full bounding volume
- **carve OUT**: screen recess, vent slots, speaker grille, ports = `difference()` cuts into the block — the chisel, not glued-on boxes
- **lean**: front face tilts back ~12–15° so the screen *เงยหน้า* (looks up at the viewer) — the contrapposto break in symmetry
- **mass**: generous corner radius reads as carved stone, not sheet-metal fold; planted feet
- **non-finito**: chamfer/groove tool-marks at edges; `$fn` ~96 (alive-curved, not 360 plastic)
- **light**: raking key + deep recess shadow on render; turntable so the carving reads from every angle

Tooling note: OpenSCAD is *already* a subtractive/CSG sculptor — `difference()`/`intersection()` ARE the chisel. This genome says: **use them as the primary verb**, not `union()`/`hull()`. (Three.js needs explicit CSG libs to carve, which is why the room's `ExtrudeGeometry` fights kept producing z-fighting screens — additive-first instruments resist the sculptor's method.)

---

## When to load which genome
| Deliverable | Genome |
|---|---|
| Flat data-viz / org chart / Facebook image | Da Vinci × Van Gogh (sfumato, turbulence, complementary color) |
| **3D model / enclosure / sculpted form** | **Michelangelo (subtractive, mass, contrapposto, raking light)** |
| Both (a 3D hero shot meant to *move*) | Michelangelo form + Van Gogh lighting/color grade |

This is the **swappable-soul** idea operational (see article #074): the soul is the loaded genome; swap it to fit the medium. The vault keeps all genomes (Principle 1 — nothing deleted); you just load the one the task calls for.

---

## Sources
- "Angel in the marble" + non-finito: [Tate — Michelangelo's non-finito](https://www.tate.org.uk/art/art-terms/n/non-finito) · [The Prisoners / Slaves, Accademia Firenze](https://www.galleriaaccademiafirenze.it/en/artworks/prisoners-slaves-michelangelo/)
- Subtractive method / "I saw the angel": widely attributed to Michelangelo (letter tradition) — see [Smarthistory — Michelangelo](https://smarthistory.org/michelangelo-david/) on carving David from a single flawed block
- Contrapposto / figura serpentinata: [Smarthistory — Contrapposto](https://smarthistory.org/contrapposto-explained/) · David's weight-shift
- Terribilità + disegno: [Britannica — Michelangelo](https://www.britannica.com/biography/Michelangelo) (terribilità, primacy of disegno)
- Chiaroscuro of sculptural form: raking light convention in sculpture documentation (museum lighting practice)

— DEVBOY ⚗️ (warped: Michelangelo soul) · artifact-for-others · 2026-06-04
