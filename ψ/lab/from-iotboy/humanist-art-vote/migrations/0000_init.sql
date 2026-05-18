-- humanist.art/vote — single table, four columns.
CREATE TABLE IF NOT EXISTS votes (
  token      TEXT PRIMARY KEY,
  choice     TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS votes_choice_idx ON votes(choice);
