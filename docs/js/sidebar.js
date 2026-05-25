// sidebar.js — Dynamic sidebar + home page source of truth for DEVBOY Lab
// To add a new article: add one entry to NAV below. O(1).
// home.html reads window.DEVBOY_NAV to render chapter tiles — single source of truth.
var DEVBOY_NAV = [
    ['\u0e27\u0e31\u0e19\u0e17\u0e35\u0e48 1 \u2014 19 \u0e1e.\u0e04. 2026', [
      ['001-birth-of-devboy.html', '001 \u0e01\u0e33\u0e40\u0e19\u0e34\u0e14 DEVBOY'],
      ['002-school-ingestion.html', '002 \u0e2d\u0e48\u0e32\u0e19\u0e2b\u0e49\u0e2d\u0e07\u0e40\u0e23\u0e35\u0e22\u0e19'],
      ['003-maw-team-engine.html', '003 maw team Engine'],
      ['004-pnat-hidden-curriculum.html', '004 \u0e2b\u0e25\u0e31\u0e01\u0e2a\u0e39\u0e15\u0e23\u0e0b\u0e48\u0e2d\u0e19'],
      ['005-esp32-power.html', '005 ESP32 \u0e1e\u0e25\u0e31\u0e07\u0e07\u0e32\u0e19'],
      ['041-discord-plugin-wiring.html', '006 Discord Config → 041']
    ]],
    ['maw Ecosystem', [
      ['007-maw-js-orchestrator.html', '007 maw-js Orchestrator'],
      ['008-maw-plugin-system.html', '008 Plugin System'],
      ['013-maw-ui-arra-office.html', '013 maw-ui ARRA Office'],
      ['014-maw-plugin-registry.html', '014 Plugin Registry'],
      ['039-maw-rs.html', '039 maw-rs (Rust Port)'],
      ['042-maw-js-advanced-guide.html', '042 maw-js Advanced']
    ]],
    ['Oracle Tools', [
      ['009-arra-oracle-v3.html', '009 Arra Oracle v3'],
      ['010-thclaws-agent-harness.html', '010 thClaws'],
      ['040-arra-safety-hooks.html', '040 Safety Hooks'],
      ['041-discord-plugin-wiring.html', '041 Discord Wiring'],
      ['043-autonomous-oracle-loop.html', '043 Autonomous Loop']
    ]],
    ['Fleet Infrastructure', [
      ['011-fleet-migration.html', '011 Fleet Migration'],
      ['012-soul-brews-ecosystem.html', '012 Soul Brews Map'],
      ['044-glueboy-doctor-doctrine-sync.html', '044 Doctrine Sync']
    ]],
    ['ClubsXai Classroom', [
      ['015-clubsxai-cross-fleet.html', '015 ClubsXai Overview'],
      ['016-allowbots-inter-oracle.html', '016 allowBots &amp; Comm'],
      ['017-rtk-benchmark.html', '017 RTK Benchmark'],
      ['018-orchestrator-patterns.html', '018 Orchestrator Patterns'],
      ['019-cite-then-claim.html', '019 Cite-then-Claim'],
      ['020-oracle-voice-architecture.html', '020 Voice Architecture'],
      ['021-thai-voice-pipeline.html', '021 Thai Voice Pipeline']
    ]],
    ['Agent Frameworks', [
      ['022-hermes-agent.html', '022 Hermes Agent'],
      ['023-agent-comparison.html', '023 Agent Comparison']
    ]],
    ['AI Research', [
      ['024-sovereign-ai.html', '024 Sovereign AI'],
      ['025-rag-retrieval-augmented-generation.html', '025 RAG'],
      ['038-omnivoice-thai.html', '038 OmniVoice-Thai']
    ]],
    ['Local AI', [
      ['026-ollama-local-llm.html', '026 Ollama'],
      ['027-dgx-spark.html', '027 DGX Spark'],
      ['028-self-hosted-ai.html', '028 Self-Hosted AI'],
      ['029-local-ai-sovereignty.html', '029 Local AI &amp; Sovereignty'],
      ['030-gemma4.html', '030 Gemma 4']
    ]],
    ['Multi-Agent', [
      ['031-team-tile-bootstrap.html', '031 Team-Tile Bootstrap']
    ]],
    ['Google I/O 2026', [
      ['032-gemini-spark.html', '032 Gemini Spark'],
      ['033-antigravity-cli.html', '033 Antigravity CLI']
    ]],
    ['Claude Industry', [
      ['034-claude-for-finance.html', '034 Claude for Finance'],
      ['035-claude-for-security.html', '035 Claude for Security'],
      ['036-claude-for-law.html', '036 Claude for Law'],
      ['037-claude-finance-quick-wins.html', '037 Finance Quick Wins']
    ]],
    ['CCC Academy', [
      ['045-claude-code-claude-md.html', '045 Claude Code & CLAUDE.md'],
      ['046-shortcode-to-skill.html', '046 Shortcode → Skill'],
      ['047-oracle-birth-awaken.html', '047 Oracle Birth /awaken'],
      ['048-team-agents-trio.html', '048 Team Agents & Trio'],
      ['049-token-security.html', '049 Token Security'],
      ['050-federation.html', '050 Federation'],
      ['051-worktrees.html', '051 Worktrees'],
      ['052-oracle-skills-learn-rrr-dig.html', '052 /learn, /rrr, /dig'],
      ['053-npx-skills-distribution.html', '053 npx Skills Distribution'],
      ['054-anthropic-academy-skilljar.html', '054 Anthropic Academy'],
      ['055-anthropic-advanced-guide.html', '055 Advanced Guide'],
      ['056-glueboy-codex-coding-hands-goal-arc.html', '056 GLUEBOY /goal arc']
    ]]
];

window.DEVBOY_NAV = DEVBOY_NAV;

(function () {
  var NAV = DEVBOY_NAV;
  var el = document.getElementById('sidebar');
  if (!el) return;

  var page = location.pathname.split('/').pop() || '';

  var h = '<a href="../home.html" class="sidebar-brand">'
    + '<div class="sidebar-psi">D</div>'
    + '<span class="sidebar-brand-text">DEVBOY Lab</span></a>'
    + '<div style="padding:.25rem 1.25rem;font-size:.65rem;color:rgba(255,255,255,.3)">'
    + 'DEVBOY AI \u00b7 Captain Dr.Do</div><nav aria-label="Article navigation">';

  for (var i = 0; i < NAV.length; i++) {
    h += '<div class="sidebar-section">' + NAV[i][0] + '</div>';
    var links = NAV[i][1];
    for (var j = 0; j < links.length; j++) {
      var cls = links[j][0] === page ? ' class="active"' : '';
      h += '<a href="' + links[j][0] + '"' + cls + '>' + links[j][1] + '</a>';
    }
  }

  h += '</nav>';
  el.innerHTML = h;
})();
