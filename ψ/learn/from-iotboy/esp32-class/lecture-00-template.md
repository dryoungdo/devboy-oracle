# Lecture NN — [Topic]

**Date**: YYYY-MM-DD
**Teacher**: P'Nat (พี่นัท)
**Channel**: #esp32-dev
**Duration**: ~Xh
**Status**: live | recorded-from-history | reconstructed

---

## Verbatim (P'Nat's words)

> Paste P'Nat's messages here as he posted them. Thai stays Thai, English stays English. Quote-blocks preserve formatting. Include code blocks unedited.
>
> Cite each message with timestamp (Bangkok time) and Discord message ID:
> > **22:34** (msg `1501976434703339754`):
> > ```
> > pinMode(2, OUTPUT);
> > digitalWrite(2, HIGH);
> > ```

## Code shared

| File | Source | Notes |
|------|--------|-------|
| `code/lecture-NN/example.ino` | P'Nat msg `<id>` | original sketch, unmodified |

## IOTBOY's structured summary

What was taught, in the Watchtower's voice:

- **Concept 1**: ...
- **Concept 2**: ...
- **Concept 3**: ...

## Key concepts (for exam prep)

- [ ] Concept name — one-sentence definition
- [ ] Concept name — one-sentence definition

→ These get copied into `exam-notes.md` after lecture ends.

## Captain's hands-on

What Captain tried, what worked, what drifted:

- ✅ Wired up the LED on GPIO 2 — blinked correctly
- ⚠️ Reading on ADC pin 34 jittered ±15 mV around 1.65V — expected noise, not a fault
- ❌ `Serial.println()` flooded the UART buffer at 921600 baud — dropped chars

## Questions (for Captain to ask P'Nat next class)

- Question worth surfacing in the next session
- Edge case the lecture didn't cover

## Cross-links

- **MLBOY** — if this lecture touched on ML topics, tag here
- **WIREBOY** — if it touched MQTT/cloud
- **Previous lecture**: [lecture-NN-1](./lecture-NN-1_...md)
- **Next lecture**: TBD

## Action items

- [ ] What Captain should practice before next class
- [ ] What IOTBOY should research and report back
