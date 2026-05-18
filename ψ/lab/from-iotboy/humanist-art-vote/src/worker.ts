// humanist.art/vote — minimum-human backend.
// One file. No Drizzle. No KV. No fingerprint. Signed cookie + D1 + counts.
// "Simplicity first, be human." — P'Nat 2026-05-09

import { Hono } from "hono";

type Env = { DB: D1Database; ASSETS: Fetcher; VOTE_HMAC_KEY: string };

const enc = new TextEncoder();

async function sign(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(payload));
  return btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function eq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

function getCookie(req: Request, name: string): string | null {
  for (const part of (req.headers.get("cookie") ?? "").split(";")) {
    const [k, ...rest] = part.trim().split("=");
    if (k === name) return rest.join("=");
  }
  return null;
}

async function readToken(env: Env, signed: string | null): Promise<string | null> {
  if (!signed) return null;
  const [raw, sig] = signed.split(".");
  if (!raw || !sig) return null;
  return eq(sig, await sign(env.VOTE_HMAC_KEY, raw)) ? raw : null;
}

const CHOICES = [
  { key: "liberate", label: "AI liberates" },
  { key: "replace",  label: "AI replaces" },
  { key: "amplify",  label: "AI amplifies" },
  { key: "partner",  label: "AI partners" },
];

const app = new Hono<{ Bindings: Env }>();

app.get("/api/state", async (c) => {
  const me = await readToken(c.env, getCookie(c.req.raw, "hav"));
  const mine = me
    ? (await c.env.DB.prepare("SELECT choice FROM votes WHERE token=?").bind(me).first<{choice:string}>())
    : null;
  const counts = await c.env.DB.prepare(
    "SELECT choice, COUNT(*) as count FROM votes GROUP BY choice"
  ).all<{choice:string; count:number}>();
  return c.json({ choices: CHOICES, voted: !!mine, mine: mine?.choice ?? null, counts: counts.results });
});

app.post("/api/vote", async (c) => {
  const env = c.env;
  const body = await c.req.json<{ choice: string }>().catch(() => null);
  if (!body || !CHOICES.some((x) => x.key === body.choice))
    return c.json({ error: "bad-choice" }, 400);

  let token = await readToken(env, getCookie(c.req.raw, "hav"));
  let setCookie: string | null = null;
  if (!token) {
    token = crypto.randomUUID();
    const sig = await sign(env.VOTE_HMAC_KEY, token);
    setCookie = `hav=${token}.${sig}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000`;
  } else {
    const prior = await env.DB.prepare("SELECT 1 FROM votes WHERE token=?").bind(token).first();
    if (prior) return c.json({ error: "already-voted" }, 409);
  }

  await env.DB.prepare("INSERT INTO votes(token, choice, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)")
    .bind(token, body.choice).run();

  const headers = new Headers({ "content-type": "application/json" });
  if (setCookie) headers.set("set-cookie", setCookie);
  return new Response(JSON.stringify({ ok: true }), { headers });
});

app.all("*", (c) => c.env.ASSETS.fetch(c.req.raw));

export default app;
