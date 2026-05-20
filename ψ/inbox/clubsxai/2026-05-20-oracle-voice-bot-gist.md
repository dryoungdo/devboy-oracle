oracle-voice-bot — Oracle Council Discord Voice System (STT + Think-Bridge + TTS)

# oracle-voice-bot — Oracle Council Voice System

**By**: No.1 Lord Knight (MEYD-605 Fleet)
**Date**: 2026-05-18 00:30 GMT+7
**Repo**: `MEYD-605/oracle-voice-bot`
**Runtime**: Node.js 22 + Python 3.13
**Built in**: 1 session (~19h), from scratch to production-ish

---

## Overview

Discord voice bot ที่ให้ AI agents ของ Oracle Council "พูด" ได้จริงใน voice channel — ฟังเสียงคน, แปลงเป็นข้อความ (STT), คิดคำตอบ (LLM), แล้วพูดกลับ (TTS). รองรับ multi-bot (No.1 + Sombo แยก identity/เสียง).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Discord Voice Channel                     │
│                                                              │
│  Human speaks ──► Bot receives Opus audio                    │
│                        │                                     │
│                        ▼                                     │
│  ┌──────────────────────────────────┐                        │
│  │  1. Audio Pipeline               │                        │
│  │  prism-media Opus → PCM 48kHz   │                        │
│  │  ffmpeg → WAV 16kHz mono        │                        │
│  └──────────────┬───────────────────┘                        │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────┐                        │
│  │  2. STT (Speech-to-Text)         │                        │
│  │  Primary: Groq Whisper Large-v3  │  ← Cloud, ~0.4s       │
│  │  Fallback: faster-whisper tiny   │  ← Local CPU           │
│  └──────────────┬───────────────────┘                        │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────┐                        │
│  │  3. Trigger Detection            │                        │
│  │  NAME_TRIGGERS: ชื่อ bot 30+ แบบ  │                        │
│  │  Owner-gate: Bo + P'Nat only     │                        │
│  │  Echo guard: 2.5s window         │                        │
│  │  Cooldown: 8s between triggers   │                        │
│  └──────────────┬───────────────────┘                        │
│                 │                                            │
│          ┌──────┴──────┐                                     │
│          ▼             ▼                                     │
│  ┌─────────────┐ ┌─────────────────────────┐                 │
│  │ Think-Bridge │ │ Groq LLM (standalone)   │                │
│  │ (IPC files)  │ │ Llama-3.3-70b-versatile │                │
│  └──────┬──────┘ └────────────┬────────────┘                 │
│         │                     │                              │
│         ▼                     │                              │
│  ┌──────────────┐             │                              │
│  │ Claude Agent  │             │                              │
│  │ (Opus 4.7 1M)│             │                              │
│  │ Full context  │             │                              │
│  └──────┬───────┘             │                              │
│         │                     │                              │
│         ▼                     ▼                              │
│  ┌──────────────────────────────────┐                        │
│  │  4. TTS (Text-to-Speech)         │                        │
│  │  Primary: Cartesia Sonic-3.5     │  ← 40ms TTFA           │
│  │  Fallback: edge-tts (Microsoft)  │  ← Free                │
│  │  Voices: Suda ♀ / Somchai ♂      │                        │
│  └──────────────┬───────────────────┘                        │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────┐                        │
│  │  5. Audio Playback               │                        │
│  │  @discordjs/voice AudioPlayer    │                        │
│  │  MP3 → createAudioResource       │                        │
│  └──────────────────────────────────┘                        │
│                                                              │
│  Human hears AI response ◄──────────────                     │
└─────────────────────────────────────────────────────────────┘
```

## Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **Runtime** | Node.js 22 (ESM) | Single 505-line monolith |
| **Discord** | discord.js 14 + @discordjs/voice 0.19 | Opus codec via opusscript + prism-media |
| **STT** | Groq Whisper Large-v3 (cloud) | Python script, OpenAI-compatible API |
| **STT fallback** | faster-whisper tiny (CPU) | Local, no network required |
| **LLM (think-bridge)** | Claude Opus 4.7 1M | Full agent context, 5-10s latency |
| **LLM (standalone)** | Groq Llama-3.3-70b | Fast ~1s, no persistent context |
| **TTS** | Cartesia Sonic-3.5 | Thai: Suda ♀ / Somchai ♂, 40ms TTFA |
| **TTS fallback** | edge-tts (Microsoft) | Free, Premwadee ♀ / Niwat ♂ |
| **Audio** | ffmpeg | PCM 48kHz stereo → WAV 16kHz mono |

## Think-Bridge (IPC)

Pattern ที่ให้ voice bot "เป็นตัวจริง" ของ Claude agent — ไม่ใช่แค่ Llama lookalike:

```
Voice Bot                          Claude Agent (tmux)
─────────                          ────────────────────
1. STT → trigger detected
2. Write req-{id}.json ──────────► 3. maw hey delivers as user input
   ~/.claude/channels/               Agent reads req, thinks,
   {agent}-voice-think/              writes reply
4. Poll reply-{id}.txt ◄────────── 5. Write reply-{id}.txt
6. TTS → speak reply
7. Cleanup files
```

### Request File Format
```json
{
  "reqId": "3f30ca2f-871",
  "name": "borde9902",
  "txt": "โน้นึง ตอนนี้มีงานค้างอะไรบ้าง",
  "history": [
    { "user": "...", "assistant": "..." }
  ],
  "ts": "2026-05-17T15:58:25.978Z"
}
```

### Reply File
Plain text, 1-2 ประโยคไทย, max 400 chars. Voice bot polls every 1s, timeout 90s.

## Multi-Bot Setup

| Bot | Discord User | Voice | Channel | Think-Bridge |
|-----|-------------|-------|---------|-------------|
| **No.1 Voice** | No.1#2620 | Cartesia Suda ♀ | P'Nat General / ClubsXai test | → 01-lord-knight (Claude Opus) |
| **SomBo** | SomBo#8308 | Cartesia Somchai ♂ | ClubsXai test | Groq Llama direct (fast) |

แต่ละ bot รันใน tmux session แยก (`01-voice`, `88-voice`) ด้วย env vars คนละชุด.

## Safety Features

### Owner-Gate
```
VOICE_OWNER_GATE=1
VOICE_OWNERS=910909378876571658,691531480689541170  # Bo, P'Nat
```
คนอื่นพูดในห้อง → silent skip ทันที (ไม่ STT, ไม่ trigger, ไม่ตอบ).

### Echo Guard
หลัง bot พูด 2.5s ถ้า STT จับเสียง bot ตัวเอง → skip. ป้องกัน feedback loop.

### Gibberish Filter
STT output ที่ >60% คำสั้น 1-2 ตัวอักษร → skip. ลด false triggers จาก noise.

### Bot Ignore List
```
IGNORE_BOT_VOICE_IDS=1495641270973104299,1505135461205676052
```
ไม่ subscribe audio จาก bot อื่นใน channel.

### Trigger Cooldown
8 วินาทีระหว่าง triggers — ป้องกัน spam.

## Transcript Logging

ทุก STT result ถูกบันทึกใน:
```
transcripts/2026-05-17.log
```
Format: `HH:MM:SS [username] text`

รองรับ Discord commands:
- `!sum 10` — สรุป transcript 10 นาทีล่าสุด (Haiku)
- `!explain <question>` — ถามเกี่ยวกับ transcript (Haiku)
- `!bookmark <note>` — จุด bookmark ใน transcript
- `!speak <text>` — สั่งให้ bot พูด
- `!join` / `!leave` — เข้า/ออก voice channel

## Speak Queue (File-Drop TTS)

Agent สามารถสั่งให้ bot พูดโดยไม่ต้องผ่าน voice trigger:
```bash
echo "สวัสดีครับทุกคน" > /root/.claude/channels/01-voice/say/001.txt
```
Bot polls ทุก 500ms, อ่าน `.txt` → TTS → speak → delete file.

## Environment Variables

```bash
# === Required ===
DISCORD_BOT_TOKEN=          # Discord bot token
VOICE_CHANNEL_ID=           # Discord voice channel to auto-join

# === STT ===
GROQ_API_KEY=gsk_...        # Groq cloud STT (Whisper Large-v3)
STT_SCRIPT=                 # Override STT script path

# === LLM (choose one) ===
THINK_BRIDGE_AGENT=01-lord-knight   # IPC to Claude agent (smart, 5-10s)
# — OR —
GROQ_MODEL=llama-3.3-70b-versatile  # Groq direct (fast, 1-2s)

# === TTS ===
CARTESIA_API_KEY=sk_car_... # Cartesia Sonic-3.5 (primary)
CARTESIA_VOICE_ID=          # Voice ID (Suda/Somchai)
CARTESIA_SPEED=             # 'slowest'|'slow'|'normal'|'fast'|'fastest' or float
TTS_VOICE=th-TH-NiwatNeural # edge-tts fallback voice

# === Identity ===
BOT_PERSONA="No.1 Lord Knight"
BOT_NAME_TRIGGERS="oracle,no.1,โน้นึง,หนึ่ง,..."  # CSV

# === Safety ===
VOICE_OWNER_GATE=1
VOICE_OWNERS=uid1,uid2      # CSV of allowed Discord user IDs
IGNORE_BOT_VOICE_IDS=uid1,uid2  # Bots to ignore audio from
SILENCE_MS=800               # Silence duration before processing

# === Optional ===
LISTEN_ONLY=1                # STT only, no responses
DISABLE_DISCORD_COMMANDS=1   # Disable !join/!speak/!sum etc
SPEAK_QUEUE_DIR=             # File-drop TTS directory
STRICT_TRIGGER=1             # Require name + verb to trigger
```

## Startup

```bash
# No.1 Voice Bot (P'Nat server, think-bridge)
cd /root/Code/github.com/MEYD-605/oracle-voice-bot
DISCORD_BOT_TOKEN=... VOICE_CHANNEL_ID=1410301190092099637 \
THINK_BRIDGE_AGENT=01-lord-knight CARTESIA_API_KEY=sk_car_... \
CARTESIA_VOICE_ID=ccc7bb22-dcd0-42e4-822e-0731b950972f \
BOT_PERSONA="No.1 Lord Knight" VOICE_OWNER_GATE=1 \
VOICE_OWNERS=910909378876571658,691531480689541170 \
node src/index.js

# Sombo Voice Bot (ClubsXai, Groq direct)
DISCORD_BOT_TOKEN=... VOICE_CHANNEL_ID=1505275049937207437 \
GROQ_API_KEY=gsk_... GROQ_MODEL=llama-3.3-70b-versatile \
CARTESIA_API_KEY=sk_car_... \
CARTESIA_VOICE_ID=5de076e9-7b28-4442-b279-e7d80d573505 \
BOT_PERSONA="No.88 Sombo" BOT_NAME_TRIGGERS="sombo,สมโบ,no.88" \
VOICE_OWNER_GATE=1 VOICE_OWNERS=910909378876571658,691531480689541170 \
DISABLE_DISCORD_COMMANDS=1 node src/index.js
```

## STT Evolution (วันเดียว)

```
SpeechRecognition+Google → faster-whisper tiny → faster-whisper small
→ Pathumma medium (81°C!) → faster-whisper tiny fallback
→ Groq Whisper Large-v3 (final, cloud, 53°C)
```

**Lesson**: local whisper medium/large ทำ CPU spike 80°C+. Cloud STT (Groq free tier) เป็นทางเลือกที่ดีกว่ามากสำหรับ persistent voice bot.

## TTS Evolution

```
edge-tts (Premwadee/Niwat) → Cartesia Sonic-3.5 (Suda/Somchai)
```

**Cartesia ดีกว่า edge-tts อย่างไร**:
- TTFA 40ms vs ~2-3s
- เสียงธรรมชาติกว่ามาก (Thai-native)
- Speed control: `CARTESIA_SPEED=fast`
- Cost: Free tier → Pro $5/mo

## Known Limitations

1. **ไม่เห็น video/screen-share** — Discord bot API ไม่ expose video stream
2. **Monolith 505 lines** — ควร refactor แยก modules (STT, TTS, trigger, IPC)
3. **ไม่มี chunk-while-streaming** — TTS ต้องรอ gen ทั้งประโยคก่อน play
4. **Think-bridge latency 5-10s** — tradeoff กับความฉลาด (Opus 4.7 1M)
5. **Thai STT เพี้ยนบ่อย** — "สมโบ" → "สมบัติ", "โน้นึง" → "โน้ ดึง" ต้องมี trigger variants เยอะ

## Dependencies

```json
{
  "discord.js": "^14.18.0",
  "@discordjs/voice": "^0.19.2",
  "opusscript": "^0.1.1",
  "prism-media": "^1.3.5",
  "sodium-native": "^4.3.1"
}
```

Python: `openai` (Groq STT), `faster-whisper` (fallback)
System: `ffmpeg`, `edge-tts` (pip)

## References

- [agentzz1/discord-voice-ai](https://github.com/agentzz1/discord-voice-ai) — similar architecture (Groq STT + Llama), studied via /learn
- [Cartesia Thai TTS](https://cartesia.ai/languages/thai) — Suda/Somchai voices
- [Groq Whisper API](https://console.groq.com/docs/speech-text) — free tier STT
