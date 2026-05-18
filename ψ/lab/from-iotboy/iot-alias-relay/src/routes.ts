// IoT Alias Relay — HTTP routes (Elysia, Bun-native)
// Ports webhook-relay-oss/src/worker.ts:255-345 alias endpoints
// Adds IoT specifics: device-kind filtering, MAC normalization, MQTT topic preview
//
// Running: bun src/routes.ts (port 3000)

import { Elysia, t } from "elysia";
import { aliases, idType, aliasTopic } from "./schema";
import { drizzle } from "drizzle-orm/bun-sqlite";
import { Database } from "bun:sqlite";
import { eq } from "drizzle-orm";

const sqlite = new Database("aliases.db");
const db = drizzle(sqlite, { schema: { aliases } });

// Normalize MAC: drop case-sensitivity, accept both colon-separated and bare
const normalizeMac = (raw: string): string =>
  raw.replace(/[^0-9A-Fa-f]/g, "").toUpperCase().match(/.{1,2}/g)?.join(":") ?? raw;

export const app = new Elysia({ prefix: "/api" })
  .get("/aliases", async () => db.select().from(aliases))

  .get("/aliases/:value", async ({ params }) =>
    db.select().from(aliases).where(eq(aliases.value, params.value)).get(),
    { params: t.Object({ value: t.String() }) }
  )

  .put("/aliases", async ({ body }) => {
    const value = idType(body.value) === "mac" ? normalizeMac(body.value) : body.value;
    const kind = idType(value);
    return db.insert(aliases)
      .values({ value, label: body.label, kind, notes: body.notes })
      .onConflictDoUpdate({ target: aliases.value, set: { label: body.label, kind } })
      .returning();
  }, {
    body: t.Object({
      value: t.String({ minLength: 1 }),
      label: t.String({ minLength: 1, maxLength: 64 }),
      notes: t.Optional(t.String()),
    }),
  })

  .delete("/aliases/:value", async ({ params }) =>
    db.delete(aliases).where(eq(aliases.value, params.value)).returning(),
    { params: t.Object({ value: t.String() }) }
  )

  // IoT-unique: render an MQTT topic with current alias substitutions applied
  // GET /api/aliases/topic-preview?topic=clinic/24:6F:28:A1:B2:C3/celsius
  .get("/aliases/topic-preview", async ({ query }) => {
    const all = await db.select().from(aliases);
    const lookup = new Map(all.map((a) => [a.value, a.label]));
    return {
      raw: query.topic,
      labeled: aliasTopic(query.topic, lookup),
      substitutions: all.length,
    };
  }, {
    query: t.Object({ topic: t.String() }),
  });

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 3000);
  app.listen(port);
  console.log(`🔭 iot-alias-relay listening on :${port}`);
}
