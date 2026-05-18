#!/usr/bin/env bun
/**
 * Proof — read messages from a Discord channel.
 * Usage:  DISCORD_BOT_TOKEN=... bun run read-channel.ts <channel_id> [limit]
 *
 * The token is the same one used by .discord-state/.env (gitignored).
 * MLBOY runs this at runtime via the MCP plugin; this script is the
 * underlying mechanism — bot-API auth, REST GET, parse messages.
 */

const TOKEN = process.env.DISCORD_BOT_TOKEN;
if (!TOKEN) {
  console.error("missing DISCORD_BOT_TOKEN");
  process.exit(1);
}

const channel = process.argv[2] ?? "1500775333283237970"; // #road-to-dev
const limit = Number(process.argv[3] ?? 5);

const url = `https://discord.com/api/v10/channels/${channel}/messages?limit=${limit}`;
const res = await fetch(url, {
  headers: { Authorization: `Bot ${TOKEN}` },
});

if (!res.ok) {
  console.error(`HTTP ${res.status}: ${await res.text()}`);
  process.exit(2);
}

type DiscordMessage = {
  id: string;
  timestamp: string;
  content: string;
  author: { username: string; id: string };
};

const msgs = (await res.json()) as DiscordMessage[];

// Discord returns newest-first; flip to oldest-first for readability
for (const m of msgs.reverse()) {
  const ts = m.timestamp.slice(0, 19).replace("T", " ");
  const head = m.content.replace(/\n/g, " ").slice(0, 80);
  console.log(`[${ts}] ${m.author.username}: ${head}`);
}
