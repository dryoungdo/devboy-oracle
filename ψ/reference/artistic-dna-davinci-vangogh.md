# 🧬 Artistic DNA — Leonardo da Vinci × Vincent van Gogh

> A reusable "genome" for breaking data-viz out of pure-engineering aesthetics.
> Load this before rendering anything meant to move a human, not just inform one.
> Extracted by DEVBOY (⚗️ The Lab) per P'Nat directive 2026-06-04. Cite-then-claim — sources at bottom.

---

## Why this exists
Engineering viz = correct but cold (boxes, straight edges, even spacing). It informs; it doesn't *move*. The two genomes below encode how to keep the data honest while making the image **breathe**. Splice them into any render (SVG / D3 / canvas).

---

## 🧬 Genome A — DA VINCI (structure that feels alive)

| Gene | The principle | Gene expression (viz translation) |
|---|---|---|
| **sfumato** | tonal transitions with **no hard lines** — 20–40 thin translucent layers → soft luminous glow ("smoke") | dissolve node borders into glows; feathered radial gradients; `feGaussianBlur` halos; light bleeds, never clips |
| **golden ratio (φ)** | divine proportion = balanced, harmonious composition (Last Supper, Mona Lisa) | place the focal node on a φ-point, not dead-center; size/space by φ (1.618); golden-spiral arrangement |
| **art ⊗ science** | math underlies beauty; obsessive observation of nature; structure IS the art | let the *data* set the skeleton, then render it organically — accuracy and beauty are the same move, not a tradeoff |

## 🧬 Genome B — VAN GOGH (motion + emotion)

| Gene | The principle | Gene expression (viz translation) |
|---|---|---|
| **swirling turbulence** | energetic curved strokes; physicists found his brightness fluctuations match real **Kolmogorov turbulence** math | connection paths = swirling bézier curves, NOT straight edges; let flow eddy and spiral; motion that feels like wind/water |
| **impasto** | thick textured, almost-sculptural strokes | layered depth, directional stroke texture, glow stacked on glow — not flat fills |
| **emotional color** | vibrant **complementary** contrast (blue night ⟷ yellow stars); color evokes feeling, not realism | complementary palette (indigo/gold, violet/amber); saturate the focal point; color = emotion, not a legend key |
| **subjective > literal** | paint the *feeling* of the thing | render what the fleet/room *feels* like (alive, converging, restless), not just its adjacency list |

---

## 🧬 The splice (breakthrough rule)
> **Stop drawing boxes wired by straight lines. Render the system as a living, swirling field of light.**
> Van Gogh's turbulent luminous curves + Da Vinci's sfumato glow + golden-ratio composition.
> The data structures the nodes; the art renders the *flow between them*.

Concrete recipe (SVG):
- nodes = soft glowing orbs (radial gradient + blur halo), focal node on a φ-point, brightest + most saturated
- edges = `<path>` cubic béziers that **swirl** (control points offset perpendicular, varied), stroke with gradient + opacity falloff
- background = deep indigo sfumato wash (radial gradient), faint turbulent texture (`feTurbulence`)
- palette = complementary (e.g. `#0b1d51` night ⟷ `#fbbf24` star-gold), accents violet/amber
- composition = golden-spiral or off-center focal, breathing negative space — not a grid
- **format = vertical 4:5 (1080×1350) for Facebook feed**, not landscape

Tooling note: ReactFlow (rigid orthogonal boxes) is the wrong instrument for this — too engineering. Hand-crafted **SVG** or **D3.js** (bézier links, `d3.curveBasis`, force/radial layout, filters) gives the brush.

---

## Sources
- Sfumato + technique: [CyPaint — Leonardo's sfumato](https://cypaint.com/article/what-is-distinctive-about-leonardo-da-vincis-painting-style) · [Leonardo da Vinci Secrets](https://leonardodavincisecrets.wordpress.com/what-is-leonardo-da-vinci-sfumato-technique/)
- Golden ratio: [1st Art Gallery](https://www.1st-art-gallery.com/article/the-influence-of-golden-ratio-in-iconic-paintings/) · [Art & Object](https://www.artandobject.com/news/how-artists-used-golden-ratio-create-masterpieces)
- Van Gogh / Starry Night turbulence + color + impasto: [artfemdxb](https://artfemdxb.com/blogs/news/vincent-van-goghs-revolutionary-techniques-in-starry-night) · [Alma Art Prints — the science](https://almaartprints.com/blogs/news/examining-van-goghs-technique-the-science-behind-starry-night)

— DEVBOY ⚗️ · artifact-for-others · 2026-06-04
