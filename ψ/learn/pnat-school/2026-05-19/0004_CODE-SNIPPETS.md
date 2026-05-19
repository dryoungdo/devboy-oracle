---
type: learning
topic: Key code patterns and working examples from school
source: pnat
maturity: raw
retrieval_terms: [esp32, maw-team, vnc, flash, power-management, discord-access]
date: 2026-05-19
sister_lineage: none
---

# Code Snippets — Working Examples from School

## ESP32 Power Management (DFS)
```c
// From IOTBOY msg 1502620947 in #esp32-dev
esp_pm_config_t cfg = {
    .max_freq_mhz       = 240,    // active
    .min_freq_mhz       =  80,    // idle (down to 40 if no XTAL-locked peripherals)
    .light_sleep_enable = true,    // tickless idle drops CPU
};
esp_pm_configure(&cfg);
```

Power budget (ESP32 typical, 3.3V):
```
state                   current     notes
240 MHz active CPU       50-80 mA   poll + send
80 MHz active CPU        25-35 mA
80 MHz light sleep      0.8-2.0 mA
Deep sleep + RTC wake    8-15 µA    best for 1pkt/min sensor
```

Lock gotchas: WiFi/BLE hold APB ~80MHz, UART holds during TX, I2C during transaction.

## ESP32 Flash Command (JC3248)
```bash
# From No.3Dev — JC3248W535C VNC viewer firmware
esptool.py --chip esp32s3 -p /dev/ttyACM0 -b 921600 \
  write_flash --flash_mode dio --flash_size 16MB 0x0 jc3248-vnc-merged.bin
# NOTE: flash_mode = dio (qio = boot loop on this board)
```

## esp-rs Quick Start
```bash
# From SomBo in #esp32-dev (P'Nat requested)
cargo install espup
espup install
cargo generate esp-rs/esp-idf-template cargo
# Two approaches: esp-hal (no_std bare-metal) or esp-idf-sys (std via ESP-IDF)
```

## maw Team Full Lifecycle
```bash
# From cohort testing in #road-to-dev
maw team create my-team
maw team spawn my-team scout --exec --prompt "scan for TODOs"
maw team status my-team
maw team add "analyze codebase" --team my-team --assign scout
maw team tasks my-team
maw team done 1
maw team send my-team scout "focus on src/ directory"
maw team shutdown --merge --force   # merge knowledge to ψ/
maw team resume                      # reincarnation from vault
maw team lives scout                 # show past-life data
maw team delete my-team
```

## Claude Code Model Selection
```bash
# From No.1 Lord Knight in #road-to-dev
# For 1M context (must be at launch):
claude --model 'claude-sonnet-4-6[1m]'
# Verify: statusline shows "Sonnet 4.6 (1M context)" + "📊 xx% (xxxk/1000k)"
# WARNING: /model switch mid-session drops back to 200K
```

## Discord Access Config Pattern
```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["721061586910838804"],
  "groups": {
    "CHANNEL_ID": {
      "_name": "channel-name",
      "requireMention": true,
      "allowFrom": []
    }
  },
  "mentionPatterns": ["@everyone", "@here", "@BOTNAME"]
}
```

## Anthropic Usage Headers (SomTor Meter)
```
anthropic-ratelimit-unified-5h-utilization    → Current %
anthropic-ratelimit-unified-7d-utilization    → Weekly %
anthropic-ratelimit-unified-overage-utilization → Overage %
anthropic-ratelimit-unified-5h-reset          → reset time
anthropic-ratelimit-unified-status            → "allowed" / other
```

## Pre-publish ledger
- Sources checked: #esp32-dev, #road-to-dev, #regular-school msg_ids cited inline
- Claims made: 7 raw
- Conflicts resolved: none
- Application evidence: N/A — code from others' working examples
- Codex reviewed: no
