// IoT Alias Relay — fork of webhook-relay-oss alias pattern, IoT-shaped
// Lifts: Drizzle schema + idType regex + UI two-table pattern
// Swaps: LINE U…/C…/R… → ESP32 MAC / ESP-NOW peer / sensor-pin / mesh-node IDs
//
// Source pattern: Soul-Brews-Studio/webhook-relay-oss/frontend/src/pages/Aliases.tsx
// IoT-Watchtower angle: opaque hardware IDs (MAC, mesh peer, ADC channel) need
// human labels for ops dashboards + MQTT topic readability.

import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

// Same shape as webhook-relay-oss aliases table (3 columns + audit)
export const aliases = sqliteTable("aliases", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  value: text("value").notNull().unique(),  // raw hardware ID
  label: text("label").notNull(),           // human-readable name
  kind: text("kind").notNull(),             // mac / espnow / sensor / mesh / custom
  notes: text("notes"),                     // free-form (room, model, calibration)
  created_at: text("created_at").notNull().default("CURRENT_TIMESTAMP"),
  updated_at: text("updated_at").notNull().default("CURRENT_TIMESTAMP"),
});

// IoT-shaped idType — replaces LINE U/C/R pattern
export function idType(value: string): "mac" | "espnow" | "sensor" | "mesh" | "custom" {
  // ESP32 MAC: 24:6F:28:A1:B2:C3 (6 hex pairs, colon-separated, uppercase)
  if (/^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/.test(value)) return "mac";
  // ESP-NOW peer: 6 raw bytes hex (no colons), or MAC w/o colons
  if (/^[0-9a-fA-F]{12}$/.test(value)) return "espnow";
  // Sensor pin/channel: ADC0-ADC7, GPIO0-GPIO39, DHT-IDX, etc.
  if (/^(ADC|GPIO|DHT|DS|I2C|SPI)[A-Z0-9_-]{1,12}$/i.test(value)) return "sensor";
  // Mesh node: short hash (e.g. ESP-NOW broadcast group token)
  if (/^node_[0-9a-f]{6,8}$/i.test(value)) return "mesh";
  return "custom";
}

// Bonus: render an MQTT topic with alias substitution
// raw:    clinic/24:6F:28:A1:B2:C3/celsius
// labeled: clinic/living-room-temp/celsius
export function aliasTopic(rawTopic: string, lookup: Map<string, string>): string {
  return rawTopic.replace(
    /([0-9A-F]{2}(?::[0-9A-F]{2}){5}|[0-9a-fA-F]{12}|node_[0-9a-f]{6,8})/g,
    (match) => lookup.get(match) ?? match
  );
}
