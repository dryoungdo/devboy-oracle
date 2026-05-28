# sop-qa-rules/06-capture-before-reference.sh — Rule 6: capture-before-reference
# ---------------------------------------------------------------------------
# Before referencing a GitHub issue/PR number downstream, the assistant MUST
# have captured that number from a recent gh response. This catches the variant
# where parallel `gh issue create` responses arrive out of mental sequence.
#
# Applies:
#   - Bash git commit / gh pr create / gh issue close / gh issue comment with
#     closing issue refs or issue-number targets
#   - Discord reply tool calls mentioning #N
# Check: scan the last 10 assistant turns for a gh issue/pr response containing
#        the referenced number; fail-open on missing or malformed JSONL.
# ---------------------------------------------------------------------------

sop_qa_rule_capture_before_reference_py() {
  SOP_QA_RULE6_MODE="$1" \
  SOP_QA_RULE6_TOOL="${SOP_QA_TOOL:-}" \
  SOP_QA_RULE6_INPUT="${SOP_QA_INPUT:-}" \
  SOP_QA_RULE6_JSONL="${SOP_QA_JSONL:-}" \
  python3 <<'PY' 2>/dev/null || true
import json
import os
import re
import shlex

MODE = os.environ.get("SOP_QA_RULE6_MODE", "")
TOOL = os.environ.get("SOP_QA_RULE6_TOOL", "")
RAW_INPUT = os.environ.get("SOP_QA_RULE6_INPUT", "")
JSONL = os.environ.get("SOP_QA_RULE6_JSONL", "")


def tokens(command):
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()\n")
        lexer.whitespace = " \t\r"
        lexer.whitespace_split = True
        lexer.commenters = "#"
        return list(lexer)
    except ValueError:
        return []


def base(token):
    return token.rsplit("/", 1)[-1]


def hash_refs(text):
    return set(re.findall(r"(?<![A-Za-z0-9_/<])#([1-9][0-9]*)\b", text))


def closing_refs(text):
    keywords = r"(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)"
    return set(re.findall(r"\b" + keywords + r"\s+#([1-9][0-9]*)\b", text, re.I))


def load_tool_input():
    try:
        tool_input = json.loads(RAW_INPUT).get("tool_input", {})
    except Exception:
        return {}
    return tool_input if isinstance(tool_input, dict) else {}


BREAKS = {"&&", "||", ";", "|", "\n"}
GIT_FLAGS_WITH_VALUE = {
    "-C",
    "-c",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--config-env",
}
GH_FLAGS_WITH_VALUE = {
    "-R",
    "--repo",
    "-b",
    "--body",
    "--comment",
    "-t",
    "--title",
    "-a",
    "--assignee",
    "-l",
    "--label",
    "-m",
    "--milestone",
    "-p",
    "--project",
}
SHELLS = {"bash", "dash", "ksh", "sh", "zsh"}
PREFIXES = {"command", "env", "exec", "sudo", "time"}
CONTROL_WORDS = {"if", "then", "do", "else", "elif", "while", "until"}


def is_assignment(token):
    name, separator, _ = token.partition("=")
    return bool(separator and name) and all(char == "_" or char.isalnum() for char in name)


def command_indices(items):
    may_start = True
    for index, token in enumerate(items):
        if token in BREAKS:
            may_start = True
            continue
        if not may_start:
            continue
        if token in CONTROL_WORDS or token in PREFIXES or is_assignment(token) or token.startswith("-"):
            may_start = True
            continue
        yield index
        may_start = False


def git_has_subcommand(tail, subcommand):
    index = 0
    while index < len(tail) and tail[index] not in BREAKS:
        token = tail[index]
        if token == subcommand:
            return True
        if token in GIT_FLAGS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return False
    return False


def issue_selector_refs(tail, start):
    refs = set()
    skip_next = False
    for token in tail[start:]:
        if token in BREAKS:
            break
        if skip_next:
            skip_next = False
            continue
        if token in GH_FLAGS_WITH_VALUE:
            skip_next = True
            continue
        if token.startswith("-") and token != "-":
            continue
        selector = re.sub(r"(?:&&|\|\||[;|])+$", "", token)
        match = re.match(r"^#?([1-9][0-9]*)$", selector)
        if not match:
            match = re.search(r"/(?:issues|pull)/([1-9][0-9]*)(?:\b|/)?", selector)
        if match:
            refs.add(match.group(1))
            break
    return refs


def refs_from_file(path):
    refs = set()
    try:
        if os.path.isfile(path) and os.path.getsize(path) <= 1048576:
            with open(path, "r", encoding="utf-8") as handle:
                refs.update(closing_refs(handle.read()))
    except Exception:
        pass
    return refs


def body_file_refs(tail):
    refs = set()
    for index, token in enumerate(tail):
        path = ""
        if token == "--body-file" and index + 1 < len(tail):
            path = tail[index + 1]
        elif token.startswith("--body-file="):
            path = token.split("=", 1)[1]
        if not path:
            continue
        refs.update(refs_from_file(path))
    return refs


def commit_file_refs(tail):
    refs = set()
    for index, token in enumerate(tail):
        path = ""
        if token in {"-F", "--file"} and index + 1 < len(tail):
            path = tail[index + 1]
        elif token.startswith("--file="):
            path = token.split("=", 1)[1]
        if path:
            refs.update(refs_from_file(path))
    return refs


def shell_inner_command(items, start):
    index = start + 1
    while index < len(items) and items[index] not in BREAKS:
        token = items[index]
        if token == "-c" or (token.startswith("-") and "c" in token[1:]):
            next_index = index + 1
            if next_index < len(items):
                return items[next_index]
            return ""
        index += 1
    return ""


def command_refs(command, depth=0):
    if depth > 2:
        return set()
    refs = set()
    items = tokens(command)
    for index in command_indices(items):
        token = items[index]
        if base(token) in SHELLS:
            inner = shell_inner_command(items, index)
            if inner:
                refs.update(command_refs(inner, depth + 1))
        if base(token) == "git" and git_has_subcommand(items[index + 1:], "commit"):
            refs.update(closing_refs(command))
            refs.update(commit_file_refs(items[index + 1:]))
        if base(token) != "gh":
            continue
        tail = items[index + 1:]
        for offset in range(len(tail) - 1):
            pair = (tail[offset], tail[offset + 1])
            if pair == ("pr", "create"):
                refs.update(closing_refs(command))
                refs.update(body_file_refs(tail))
            if pair in {("issue", "close"), ("issue", "comment")}:
                refs.update(hash_refs(command))
                refs.update(issue_selector_refs(tail, offset + 2))
                if pair == ("issue", "comment"):
                    refs.update(body_file_refs(tail))
    return refs


def current_refs():
    tool_input = load_tool_input()
    if TOOL == "mcp__plugin_discord_discord__reply":
        return sorted(hash_refs(json.dumps(tool_input, ensure_ascii=False)), key=int)
    if TOOL != "Bash":
        return []

    command = tool_input.get("command", "")
    if not isinstance(command, str):
        return []

    return sorted(command_refs(command), key=int)


def gh_evidence_command(command, depth=0):
    if depth > 2:
        return False
    items = tokens(command)
    for index in command_indices(items):
        token = items[index]
        if base(token) in SHELLS:
            inner = shell_inner_command(items, index)
            if inner and gh_evidence_command(inner, depth + 1):
                return True
        if base(token) != "gh":
            continue
        tail = items[index + 1:]
        for offset in range(len(tail) - 1):
            if (tail[offset], tail[offset + 1]) in {
                ("issue", "create"),
                ("issue", "view"),
                ("issue", "list"),
                ("pr", "create"),
                ("pr", "view"),
                ("pr", "list"),
            }:
                return True
    return False


def result_text(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        chunks = []
        for item in value:
            if isinstance(item, str):
                chunks.append(item)
            elif isinstance(item, dict):
                text = item.get("text") or item.get("content") or ""
                if isinstance(text, str):
                    chunks.append(text)
        return "\n".join(chunks)
    return json.dumps(value, ensure_ascii=False) if isinstance(value, dict) else ""


def mentions_ref(output, ref):
    escaped = re.escape(ref)
    patterns = [
        r"(?<![A-Za-z0-9_/])#" + escaped + r"\b",
        r"/issues/" + escaped + r"\b",
        r"/pull/" + escaped + r"\b",
        r"\bnumber:\s*" + escaped + r"\b",
        r'"number"\s*:\s*' + escaped + r"\b",
        r"^\s*" + escaped + r"\s+(?:OPEN|CLOSED|MERGED)\b",
    ]
    return any(re.search(pattern, output, re.I | re.M) for pattern in patterns)


refs = current_refs()
if MODE == "refs":
    print("\n".join(refs))
    raise SystemExit(0)

if not refs or not JSONL:
    print("PASS")
    raise SystemExit(0)

messages = []
try:
    with open(JSONL, "r", encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                messages.append(json.loads(line))
except Exception:
    print("PARSE_ERROR")
    raise SystemExit(0)

if not messages:
    print("PARSE_ERROR")
    raise SystemExit(0)

seen = 0
start = 0
for index in range(len(messages) - 1, -1, -1):
    if messages[index].get("type") == "assistant":
        seen += 1
        if seen == 10:
            start = index
            break

tool_ids = set()
outputs = []
for message in messages[start:]:
    content = message.get("message", {}).get("content", [])
    if message.get("type") == "assistant" and isinstance(content, list):
        for item in content:
            if not isinstance(item, dict) or item.get("type") != "tool_use":
                continue
            if item.get("name") != "Bash":
                continue
            command = (item.get("input") or {}).get("command", "")
            if isinstance(command, str) and gh_evidence_command(command):
                tool_id = item.get("id")
                if tool_id:
                    tool_ids.add(tool_id)
    if message.get("type") == "user" and isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "tool_result" and item.get("tool_use_id") in tool_ids:
                outputs.append(result_text(item.get("content", "")))

missing = [ref for ref in refs if not any(mentions_ref(output, ref) for output in outputs)]
print("MISSING " + " ".join(missing) if missing else "PASS")
PY
}

sop_qa_rule_capture_before_reference_refs() {
  sop_qa_rule_capture_before_reference_py refs
}

sop_qa_rule_capture_before_reference_applies() {
  case "${SOP_QA_TOOL}" in
    Bash|mcp__plugin_discord_discord__reply) ;;
    *) return 1 ;;
  esac

  local refs
  refs="$(sop_qa_rule_capture_before_reference_refs)"
  [ -n "${refs}" ] || return 1
  return 0
}

sop_qa_rule_capture_before_reference_check() {
  [ -z "${SOP_QA_JSONL:-}" ] && return 0
  [ ! -f "${SOP_QA_JSONL}" ] && return 0

  local status
  status="$(sop_qa_rule_capture_before_reference_py check)"

  case "${status}" in
    PASS|PARSE_ERROR|"")
      return 0
      ;;
    MISSING*)
      local missing
      missing="$(printf '%s' "${status}" | sed 's/^MISSING[[:space:]]*//' | awk '{print $1}')"
      sop_qa_emit_hint "capture-before-reference" "reference to #${missing} without prior capture from gh response in last 10 turns.

   Per session-metrics.md recurring-pattern variant 14:
   Parallel \`gh issue create\` returns URLs in unpredictable order. Pre-assigning
   numbers in mental sequence will mismatch GitHub's actual response.

   Fix: capture URL→title mapping from gh response BEFORE referencing #${missing} anywhere
   downstream (PR body, Discord, commit message). Use sequential filing OR
   parse all responses before referencing.

   Override: include \`GLUEBOY_GATE_BYPASS=<reason>\` in tool input."
      return 1
      ;;
  esac

  return 0
}
