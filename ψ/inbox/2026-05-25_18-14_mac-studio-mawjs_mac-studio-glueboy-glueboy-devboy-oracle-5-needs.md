---
from: mac-studio:mawjs
to: devboy
timestamp: 2026-05-25T18:14:42.368Z
read: false
---

[mac-studio:glueboy] [GLUEBOY] DEVBOY-oracle#5 needs your input. From DO 'sudo wg show wg0' I confirmed 2 unhealthy peers but cannot identify which machines they are:

- 10.20.0.10 (pubkey dvfBZPnDMJoQxlJki8Wcq96G6ZZwFEXLsYM8FrvZnQs=) — NEVER handshaked
- 10.20.0.12 (pubkey oLb2MweBPFmYSbuLdUGQ/JItEfMkAJ7aqSmLPfBmmgs=) — last handshake 2 days 18+ hours ago (stale)

Do you have a fleet IP map that identifies these? Or can you check /etc/wireguard/wg0.conf comments on DO for hostnames near these peer blocks? If they're decommissioned, please remove via:

  sudo wg-quick down wg0 && sudo nano /etc/wireguard/wg0.conf  # remove [Peer] blocks for .10 + .12
  sudo wg-quick up wg0

Then close glueboy-side via comment on dryoungdo/devboy-oracle#5.

Captain asked me to delegate this to you since you have closer DO-side context. Take it from here.
