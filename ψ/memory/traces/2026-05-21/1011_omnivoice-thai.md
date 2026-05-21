---
query: "omnivoice-thai"
target: "huggingface.co/hotdogs/omnivoice-thai"
mode: deep-dig
timestamp: 2026-05-21 10:11
friction_score: 0.0
coverage: [oracle, files, git, cross-repo, github]
confidence: high
---

# Trace: omnivoice-thai

**Target**: huggingface.co/hotdogs/omnivoice-thai
**Mode**: deep-dig | **Friction**: 0.0 | **Confidence**: high
**Time**: 2026-05-21 10:11 GMT+7

## Oracle Results

No direct matches for "omnivoice-thai". Vector search returned related TTS content:
- wireboy retro: edge-tts TTS production (EP1/EP2, NiwatNeural Thai voice)
- wireboy retro: TTS voice cast, 8 characters, rate/pitch tuning
- CoachBoy retro: Thai TTS research for GLUEBOY Diaries

All use **edge-tts** (Microsoft) or **Cartesia Sonic-3.5** — no OmniVoice references.

## Files Found

Related Thai voice articles exist but don't mention OmniVoice:
- `docs/articles/020-oracle-voice-architecture.html` — Think-Bridge IPC (STT→LLM→TTS)
- `docs/articles/021-thai-voice-pipeline.html` — Thai STT/TTS challenges, Cartesia, Groq Whisper
- `ψ/inbox/clubsxai/2026-05-20-oracle-voice-bot-gist.md` — No.1's oracle-voice-bot (293 lines)

## Git History

One commit: `639944a feat(site): add oracle-voice-bot deep analysis articles (020-021)`. No OmniVoice mentions.

## GitHub Issues/PRs

None.

## Cross-Repo Matches

Zero matches for "omnivoice" in any local repo. GitHub ecosystem found:

| Repo | Description |
|------|-------------|
| **k2-fsa/OmniVoice** | Base model — 600+ languages, Daniel Povey's team |
| **debpalash/OmniVoice-Studio** | Desktop app for voice cloning/dubbing |
| **Saganaki22/ComfyUI-OmniVoice-TTS** | ComfyUI nodes for OmniVoice |
| **maemreyo/omnivoice-server** | OpenAI-compatible HTTP server |
| **ServeurpersoCom/omnivoice.cpp** | C++17 GGML port (CPU/CUDA/ROCm/Metal/Vulkan) |

## Oracle Memory

Voice work in fleet history:
- **2026-05-20**: 5-agent deep analysis of oracle-voice-bot (No.1 Lord Knight). Articles 020-021 published.
- **2026-03-30/31**: wireboy TTS production (GLUEBOY Diaries EP1/EP2, edge-tts, NiwatNeural)
- Current stack: Cartesia Sonic-3.5 (40ms TTFA) + edge-tts fallback. STT: Groq Whisper Large-v3.

## Session History (from /dig)

- **2026-05-20 ~16:45**: Captain shared oracle-voice-bot gist, called it "gold". 5 agents analyzed. Articles 020-021 + 3 arra learns. Commit `639944a`. ~30 min active voice work.
- **2026-05-21 ~10:09**: Captain sent `/trace --deep /dig --deep` on omnivoice-thai. This trace (current).
- **2026-03-30/31**: wireboy produced TTS audio for GLUEBOY Diaries (edge-tts, 8-character voice cast).

## Web Research: What is omnivoice-thai?

### Identity

**omnivoice-thai** is a Thai-language fine-tune of **k2-fsa/OmniVoice**, published 2026-05-21 under Apache 2.0.

- **Creator**: UKA (GitHub: nanofatdog) — independent Thai dev, AI agent/security background
- **Base model team**: Daniel Povey (Kaldi creator) + k2-fsa researchers
- **Paper**: arXiv:2604.00688
- **Parameters**: 612M (Qwen3-0.6B backbone)
- **Size**: ~7.4 GB on disk (including optimizer state)

### Architecture

Discrete masked diffusion (MaskGIT-style) non-autoregressive TTS:

1. **Direct text → acoustic tokens** — skips traditional 2-stage pipeline (text→semantic→acoustic)
2. **Full-codebook random masking** — efficient training across all codebooks
3. **Pre-trained LLM init** — starts from Qwen3-0.6B for text understanding
4. **Audio tokenizer**: eustlb/higgs-audio-v2-tokenizer @ 24kHz
5. **Base training**: 581,000 hours multilingual data, 600+ languages

### Capabilities

- **TTS** (primary) — text to Thai/English speech
- **Zero-shot voice cloning** — from short reference audio
- **Voice design** — control gender, pitch, accent, age via text instruction
- **Non-verbal symbols** — `[laughter]`, pauses
- **Pronunciation control** — via pinyin/phonemes
- **Speed**: RTF 0.025 (40x real-time, base model)

### Thai Fine-tuning Details

| Field | Value |
|-------|-------|
| Dataset | Thanarit/Thai-Voice-Test7 |
| Utterances | 20,000 |
| Audio hours | 12.6 |
| Speakers | 2 |
| Sources | GigaSpeech2 + ProcessedVoiceTH + MozillaCommonVoice |
| GPU | 1x NVIDIA RTX 3090 24GB (Vast.ai) |
| Training time | ~1.5 hours |
| Steps | 1,747 / 30,000 (auto-stopped at per-step loss < 3.0) |
| LR | 1e-5, cosine, 2% warmup |
| Precision | fp16, SDPA attention |
| Best loss | 2.8775 per-step; smoothed ~4.4 |

### Limitations

- **Tiny dataset** — 12.6h / 2 speakers severely limits generalization + naturalness
- ASR-generated transcripts may have errors (confidence 0.78-1.0)
- Base model trained primarily on English/Chinese — Thai is "new territory"
- Loss still fluctuating; smoothed 4.4 is relatively high
- No published evaluation (MOS, speaker similarity, WER)

### Comparison

| Model | Type | Thai Quality | Open Source | Notes |
|-------|------|-------------|-------------|-------|
| **omnivoice-thai** | TTS + clone + design | Experimental (12.6h, 2 spk) | Yes (Apache 2.0) | Very early; novel arch |
| **k2-fsa/OmniVoice** | TTS 600+ langs | Included but not specialized | Yes (Apache 2.0) | 581k hours, strong base |
| **Cartesia Sonic-3.5** | TTS | Production (Suda/Somchai) | No (API, paid) | Current fleet TTS |
| **edge-tts (Microsoft)** | TTS | Good (NiwatNeural) | Free API | Fleet fallback TTS |
| **Google Cloud TTS** | TTS | Production | No (API, paid) | Multiple Thai voices |
| **Whisper (OpenAI)** | ASR (not TTS) | Strong Thai ASR | Yes | Different task |

### Usage

```python
pip install omnivoice

from omnivoice import OmniVoice
import soundfile as sf

model = OmniVoice.from_pretrained("hotdogs/omnivoice-thai")
audio = model.generate(
    text="สวัสดีครับ วันนี้อากาศดีมากเลย",
    instruct="male, low pitch",
)
sf.write("output.wav", audio[0], 24000)
```

Colab notebook included in the HuggingFace repo.

### Key Links

- Model: https://huggingface.co/hotdogs/omnivoice-thai
- Base: https://huggingface.co/k2-fsa/OmniVoice
- Paper: https://arxiv.org/abs/2604.00688
- GitHub (base): https://github.com/k2-fsa/OmniVoice
- Dataset: https://huggingface.co/datasets/Thanarit/Thai-Voice-Test7
- Creator: https://github.com/nanofatdog
- Demo (base): https://huggingface.co/spaces/k2-fsa/OmniVoice

## Friction Analysis

**Score**: 0.0 ░░░░░░░░░░░░ Invisible — not found anywhere in Oracle/repo/git/cross-repo
**Coverage**: oracle, files, git, cross-repo, github (5/5 dimensions searched)
**Goal check**: YES — web research fully answered what this model is, who made it, architecture, capabilities, limitations, and comparison to fleet's current TTS stack. The model is new to the fleet's knowledge base.

**Action zone**: 0.0 = Create / document. This model should be indexed if Captain decides it's relevant to fleet voice strategy.

## Summary

**omnivoice-thai** is a proof-of-concept Thai fine-tune of Daniel Povey's OmniVoice (state-of-the-art non-autoregressive TTS with 581K hours base training). Made by independent Thai dev UKA on a single RTX 3090 in 1.5 hours with only 12.6 hours of Thai data. The architecture is novel (masked diffusion on Qwen3-0.6B), Apache 2.0, and supports voice cloning + voice design. However, it's very early-stage — no evaluation metrics, tiny dataset, 2 speakers.

**Relevance to fleet**: Current fleet uses Cartesia Sonic-3.5 (proprietary, paid) + edge-tts (free, Microsoft). OmniVoice-Thai is open-source + self-hostable + supports voice cloning, which fleet doesn't have yet. But quality is unproven. The base model (k2-fsa/OmniVoice) has 2.1M+ downloads and strong ecosystem (C++ port, ComfyUI, OpenAI-compatible server) — worth watching even if this Thai fine-tune isn't production-ready.

**Next steps** (Captain decides):
1. Lab experiment: run inference locally, compare output quality vs Cartesia/edge-tts
2. If promising: fine-tune with more Thai data (GigaSpeech2 has much more)
3. Monitor base model updates from k2-fsa team
