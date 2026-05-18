import { useEffect, useState } from "react";

interface State {
  choices: { key: string; label: string }[];
  voted: boolean;
  mine: string | null;
  counts: { choice: string; count: number }[];
}

export default function App() {
  const [s, setS] = useState<State | null>(null);

  useEffect(() => {
    void load();
    const t = setInterval(load, 5000);
    return () => clearInterval(t);
  }, []);

  async function load() {
    const r = await fetch("/api/state");
    if (r.ok) setS(await r.json());
  }

  async function vote(choice: string) {
    const r = await fetch("/api/vote", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ choice }),
    });
    if (r.ok) await load();
  }

  if (!s) return null;

  const total = s.counts.reduce((sum, c) => sum + c.count, 0);

  return (
    <main className="min-h-screen bg-stone-50 text-stone-900 font-serif">
      <div className="max-w-xl mx-auto px-6 py-24">
        <p className="text-xs uppercase tracking-[0.2em] text-stone-500 mb-3">humanist.art / vote</p>
        <h1 className="text-3xl leading-tight mb-3">What does AI do for human life?</h1>
        <p className="text-stone-600 italic mb-12">One choice. One vote.</p>

        <ul className="space-y-2">
          {s.choices.map((c) => {
            const count = s.counts.find((x) => x.choice === c.key)?.count ?? 0;
            const pct = total ? Math.round((count / total) * 100) : 0;
            const mine = s.mine === c.key;
            return (
              <li key={c.key}>
                <button
                  onClick={() => vote(c.key)}
                  disabled={s.voted}
                  className={[
                    "w-full text-left border px-5 py-4 transition-colors",
                    "border-stone-300 bg-white",
                    mine ? "border-stone-900" : "",
                    !s.voted ? "hover:border-stone-900" : "cursor-default",
                  ].join(" ")}
                >
                  <span className="flex items-baseline justify-between">
                    <span>{c.label}</span>
                    {s.voted && <span className="text-sm tabular-nums text-stone-500">{pct}%</span>}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>

        <p className="mt-12 text-xs text-stone-400">
          {s.voted ? `${total} have voted.` : ""}
        </p>
      </div>
    </main>
  );
}
