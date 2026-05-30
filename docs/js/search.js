// search.js — Hybrid search for DEVBOY Lab
// Fuzzy keyword + tag matching. No build step. Pure client-side.
(function () {
  // Article index: [url, number, title, tags[], summary]
  var ARTICLES = [
    ['001-birth-of-devboy.html', '001', 'กำเนิด DEVBOY', ['devboy', 'fleet', 'identity'], 'Birth of DEVBOY R&D incubator'],
    ['002-school-ingestion.html', '002', 'อ่านห้องเรียน HUMAN SCHOOL', ['school', 'pnat', 'ingestion'], 'P\'Nat school class ingestion'],
    ['003-maw-team-engine.html', '003', 'maw team Engine', ['maw', 'team', 'multi-agent'], 'maw team orchestration engine'],
    ['004-pnat-hidden-curriculum.html', '004', 'หลักสูตรซ่อนของพี่นัท', ['pnat', 'curriculum', 'discipline'], 'Hidden curriculum structural execution'],
    ['005-esp32-power.html', '005', 'ESP32 จัดการพลังงาน', ['esp32', 'power', 'iot', 'embedded'], 'ESP32 power management'],
    ['006-discord-config.html', '006', 'Discord Config & ความซื่อสัตย์', ['discord', 'config', 'honesty'], 'Discord configuration integrity'],
    ['007-maw-js-orchestrator.html', '007', 'maw-js Orchestrator', ['maw', 'javascript', 'orchestrator'], 'maw JS orchestrator architecture'],
    ['008-maw-plugin-system.html', '008', 'Plugin System & Registry', ['maw', 'plugin', 'registry'], 'maw plugin system design'],
    ['009-arra-oracle-v3.html', '009', 'Arra Oracle v3 — MCP Memory', ['arra', 'oracle', 'mcp', 'memory'], 'Arra Oracle v3 MCP memory system'],
    ['010-thclaws-agent-harness.html', '010', 'thClaws Agent Harness', ['thclaws', 'agent', 'harness'], 'thClaws agent testing harness'],
    ['011-fleet-migration.html', '011', 'Fleet Migration — m5 → white', ['fleet', 'migration', 'infrastructure'], 'Fleet migration m5 to white'],
    ['012-soul-brews-ecosystem.html', '012', 'Soul Brews Ecosystem Map', ['soul-brews', 'ecosystem', 'map'], 'Soul Brews Studio ecosystem overview'],
    ['013-maw-ui-arra-office.html', '013', 'maw-ui ARRA Office Dashboard', ['maw', 'ui', 'dashboard', 'arra'], 'ARRA Office dashboard UI'],
    ['014-maw-plugin-registry.html', '014', 'Plugin Registry & Discord Plugin', ['maw', 'plugin', 'discord', 'registry'], 'Plugin registry and Discord integration'],
    ['015-clubsxai-cross-fleet.html', '015', 'ClubsXai Overview', ['clubsxai', 'cross-fleet', 'classroom'], 'ClubsXai cross-fleet classroom'],
    ['016-allowbots-inter-oracle.html', '016', 'allowBots & Inter-Oracle Comm', ['allowbots', 'oracle', 'communication'], 'Inter-Oracle communication protocol'],
    ['017-rtk-benchmark.html', '017', 'RTK Benchmark', ['rtk', 'benchmark', 'token', 'optimization'], 'RTK Rust Token Killer benchmark'],
    ['018-orchestrator-patterns.html', '018', 'Orchestrator Patterns', ['orchestrator', 'patterns', 'multi-agent'], 'Multi-agent orchestrator patterns'],
    ['019-cite-then-claim.html', '019', 'Cite-then-Claim', ['citation', 'discipline', 'anti-hallucination'], 'Cite-then-claim methodology'],
    ['020-oracle-voice-architecture.html', '020', 'Voice Bot Architecture', ['voice', 'bot', 'architecture', 'tts'], 'Oracle voice bot architecture'],
    ['021-thai-voice-pipeline.html', '021', 'Thai Voice Pipeline', ['voice', 'thai', 'tts', 'stt', 'pipeline'], 'Thai voice STT/TTS pipeline'],
    ['022-hermes-agent.html', '022', 'Hermes Agent (NousResearch)', ['hermes', 'agent', 'nousresearch', 'local-ai'], 'Hermes agent framework NousResearch'],
    ['023-agent-comparison.html', '023', 'Agent Framework Comparison', ['agent', 'framework', 'comparison'], 'Agent framework comparison matrix'],
    ['024-sovereign-ai.html', '024', 'Sovereign AI', ['sovereign', 'ai', 'policy', 'national'], 'Sovereign AI policy and strategy'],
    ['025-rag-retrieval-augmented-generation.html', '025', 'RAG — Retrieval-Augmented Generation', ['rag', 'retrieval', 'vector', 'embedding'], 'RAG retrieval augmented generation'],
    ['026-ollama-local-llm.html', '026', 'Ollama — Local LLM Runtime', ['ollama', 'local-ai', 'llm', 'runtime'], 'Ollama local LLM runtime'],
    ['027-dgx-spark.html', '027', 'DGX Spark', ['dgx', 'nvidia', 'gpu', 'hardware'], 'NVIDIA DGX Spark overview'],
    ['028-self-hosted-ai.html', '028', 'Self-Hosted AI', ['self-hosted', 'local-ai', 'deployment'], 'Self-hosted AI deployment guide'],
    ['029-local-ai-sovereignty.html', '029', 'Local AI & Sovereignty', ['local-ai', 'sovereign', 'privacy'], 'Local AI sovereignty and privacy'],
    ['030-gemma4.html', '030', 'Gemma 4', ['gemma', 'google', 'local-ai', 'open-source'], 'Google Gemma 4 open model'],
    ['031-team-tile-bootstrap.html', '031', 'Team-Tile Bootstrap', ['team', 'tile', 'multi-agent', 'bootstrap'], 'Team tile multi-agent bootstrap'],
    ['032-gemini-spark.html', '032', 'Gemini Spark', ['gemini', 'google', 'google-io'], 'Google I/O Gemini Spark'],
    ['033-antigravity-cli.html', '033', 'Antigravity CLI 2.0', ['antigravity', 'cli', 'google'], 'Antigravity CLI 2.0 from Google I/O'],
    ['034-claude-for-finance.html', '034', 'Claude for Finance', ['claude', 'finance', 'agents', 'mcp', 'anthropic', 'plugin'], 'Claude for Financial Services expert guide'],
    ['035-claude-for-security.html', '035', 'Claude for Security', ['claude', 'security', 'github-action', 'glasswing', 'plugin', 'anthropic'], 'Claude Security review GitHub Action plugins'],
    ['036-claude-for-law.html', '036', 'Claude for Law', ['claude', 'legal', 'contract', 'plugin', 'mcp', 'anthropic'], 'Claude for Legal practice-area plugins MCP'],
    ['037-claude-finance-quick-wins.html', '037', 'Finance: 5 Quick Wins', ['claude', 'finance', 'tutorial', 'quick-wins'], 'Finance quick wins tutorials'],
    ['038-omnivoice-thai.html', '038', 'OmniVoice-Thai', ['voice', 'thai', 'omnivoice', 'tts', 'huggingface'], 'OmniVoice-Thai voice model'],
    ['039-maw-rs.html', '039', 'maw-rs (Rust Port)', ['maw', 'rust', 'cli', 'port'], 'maw Rust port CLI'],
    ['040-arra-safety-hooks.html', '040', 'ARRA Safety Hooks', ['safety', 'hooks', 'claude-code', 'arra'], 'ARRA safety hooks enforcement'],
    ['041-discord-plugin-wiring.html', '041', 'Discord Plugin Wiring', ['discord', 'plugin', 'wiring', 'bot', 'dmpolicy'], 'Discord plugin wiring guide for Oracles'],
    // NOTE: 042-068 not yet in this search index (pre-existing gap — followup issue #22)
    ['069-consult-boardroom-skill.html', '069', '/consult Boardroom Skill', ['claude-skills', 'consult', 'boardroom', 'personas', 'thai-business', 'skill-review'], 'consult boardroom skill review 36 personas install verdict'],
    ['070-9arm-skills-engineering-discipline.html', '070', '9arm-skills', ['claude-skills', '9arm', 'post-mortem', 'debug-mantra', 'scrutinize', 'skill-review'], '9arm thananon engineering discipline skills review install verdict']
  ];

  // --- Recent articles ---
  var recentEl = document.getElementById('recent-articles');
  if (recentEl) {
    var sorted = ARTICLES.slice().sort(function (a, b) {
      return parseInt(b[1]) - parseInt(a[1]);
    });
    var recent = sorted.slice(0, 8);
    var h = '';
    for (var i = 0; i < recent.length; i++) {
      h += '<a class="chapter-tile" href="articles/' + recent[i][0] + '">'
        + '<span>' + recent[i][1] + '</span>'
        + '<strong>' + recent[i][2] + '</strong></a>';
    }
    recentEl.innerHTML = h;
  }

  // --- Hybrid search ---
  var input = document.getElementById('search-input');
  var resultsEl = document.getElementById('search-results');
  if (!input || !resultsEl) return;

  function normalize(s) {
    return s.toLowerCase().replace(/[_\-\/\.]/g, ' ').trim();
  }

  function fuzzyMatch(needle, haystack) {
    needle = normalize(needle);
    haystack = normalize(haystack);
    if (haystack.indexOf(needle) !== -1) return 1.0;
    var ni = 0;
    for (var hi = 0; hi < haystack.length && ni < needle.length; hi++) {
      if (haystack[hi] === needle[ni]) ni++;
    }
    return ni === needle.length ? 0.5 : 0;
  }

  function search(query) {
    if (!query || query.length < 2) return [];
    var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    var scored = [];

    for (var i = 0; i < ARTICLES.length; i++) {
      var a = ARTICLES[i];
      var title = a[2];
      var tags = a[3];
      var summary = a[4];
      var all = (title + ' ' + tags.join(' ') + ' ' + summary + ' ' + a[1]).toLowerCase();
      var score = 0;

      for (var t = 0; t < terms.length; t++) {
        var term = terms[t];
        // exact tag match = highest
        for (var g = 0; g < tags.length; g++) {
          if (tags[g] === term) { score += 3; break; }
          if (tags[g].indexOf(term) !== -1) { score += 1.5; break; }
        }
        // title match
        score += fuzzyMatch(term, title) * 2;
        // summary match
        score += fuzzyMatch(term, summary);
        // number match
        if (a[1] === term || a[1] === term.replace(/^0+/, '')) score += 4;
      }

      if (score > 0) scored.push({ idx: i, score: score });
    }

    scored.sort(function (a, b) { return b.score - a.score; });
    return scored.slice(0, 10);
  }

  function render(results) {
    if (results.length === 0) {
      resultsEl.innerHTML = '<div class="search-empty">ไม่พบผลลัพธ์</div>';
      resultsEl.style.display = 'block';
      return;
    }
    var h = '';
    for (var i = 0; i < results.length; i++) {
      var a = ARTICLES[results[i].idx];
      h += '<a class="search-result-item" href="articles/' + a[0] + '">'
        + '<span class="search-num">' + a[1] + '</span>'
        + '<span class="search-title">' + a[2] + '</span>'
        + '<span class="search-tags">' + a[3].slice(0, 3).join(', ') + '</span>'
        + '</a>';
    }
    resultsEl.innerHTML = h;
    resultsEl.style.display = 'block';
  }

  var debounce;
  input.addEventListener('input', function () {
    clearTimeout(debounce);
    var q = input.value.trim();
    if (q.length < 2) { resultsEl.style.display = 'none'; return; }
    debounce = setTimeout(function () { render(search(q)); }, 150);
  });

  input.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
      resultsEl.style.display = 'none';
      input.blur();
    }
  });

  document.addEventListener('click', function (e) {
    if (!input.contains(e.target) && !resultsEl.contains(e.target)) {
      resultsEl.style.display = 'none';
    }
  });

  // Keyboard shortcut: / to focus search
  document.addEventListener('keydown', function (e) {
    if (e.key === '/' && document.activeElement !== input) {
      e.preventDefault();
      input.focus();
    }
  });
})();
