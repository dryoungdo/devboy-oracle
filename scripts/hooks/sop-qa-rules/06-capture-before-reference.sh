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
import subprocess

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


def repo_name(repo):
    return repo.rsplit("/", 1)[-1] if repo else ""


def normalize_repo(repo):
    if not repo or not isinstance(repo, str):
        return ""
    value = repo.strip().strip("'\"")
    if not value:
        return ""
    value = value.rstrip("/")
    value = re.sub(r"\.git$", "", value)
    for pattern in (
        r"github\.com[:/]([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$",
        r"^git@github\.com:([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$",
        r"^https?://github\.com/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$",
        r"^ssh://git@github\.com/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$",
    ):
        match = re.search(pattern, value, re.I)
        if match:
            return match.group(1).lower()
    match = re.match(r"^([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$", value)
    if match:
        return match.group(1).lower()
    match = re.match(r"^[A-Za-z0-9_.-]+$", value)
    return value.lower() if match else ""


def repos_match(left, right):
    left = normalize_repo(left)
    right = normalize_repo(right)
    if not left or not right:
        return False
    if "/" in left and "/" in right:
        return left == right
    return repo_name(left) == repo_name(right)


def repo_from_github_url(text):
    if not isinstance(text, str):
        return ""
    match = re.search(
        r"github\.com[:/]([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/(?:issues|pull)/[1-9][0-9]*\b",
        text,
        re.I,
    )
    return normalize_repo("%s/%s" % match.groups()) if match else ""


def repos_from_github_urls(text, ref=""):
    if not isinstance(text, str):
        return set()
    ref_pattern = re.escape(ref) if ref else r"[1-9][0-9]*"
    repos = set()
    for match in re.finditer(
        r"github\.com[:/]([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/(?:issues|pull)/(" + ref_pattern + r")\b",
        text,
        re.I,
    ):
        repos.add(normalize_repo("%s/%s" % (match.group(1), match.group(2))))
    return {repo for repo in repos if repo}


def repo_from_git_dir(path):
    if not path:
        return ""
    try:
        completed = subprocess.run(
            ["git", "-C", path, "remote", "get-url", "origin"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=2,
            check=False,
        )
    except Exception:
        return ""
    if completed.returncode != 0:
        return ""
    return normalize_repo(completed.stdout.strip())


def hook_cwd(tool_input=None):
    try:
        payload = json.loads(RAW_INPUT)
    except Exception:
        payload = {}
    if isinstance(tool_input, dict):
        candidate = tool_input.get("cwd")
        if isinstance(candidate, str) and candidate:
            return candidate
    candidate = payload.get("cwd") if isinstance(payload, dict) else ""
    if isinstance(candidate, str) and candidate:
        return candidate
    return os.getcwd()


def resolve_path(path, cwd):
    if not path:
        return cwd
    return path if os.path.isabs(path) else os.path.abspath(os.path.join(cwd, path))


def hash_refs(text):
    return set(re.findall(r"(?<![A-Za-z0-9_/<])#[ \t]*([1-9][0-9]*)\b", text))


def closing_refs(text):
    keywords = r"(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)"
    return set(re.findall(r"\b" + keywords + r"\s+#[ \t]*([1-9][0-9]*)\b", text, re.I))


def repo_qualified_refs(text):
    refs = []
    for match in re.finditer(
        r"\b((?:[A-Za-z0-9_.-]+/)?[A-Za-z0-9_.-]+)#[ \t]*([1-9][0-9]*)\b",
        text,
    ):
        repo = normalize_repo(match.group(1))
        if repo:
            refs.append((match.group(2), repo))
    return refs


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


def issue_selector_repo(tail, start):
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
        repo = repo_from_github_url(token)
        if repo:
            return repo
    return ""


def gh_repo_from_tail(tail):
    for index, token in enumerate(tail):
        if token in BREAKS:
            break
        if token in {"--repo", "-R"} and index + 1 < len(tail):
            return normalize_repo(tail[index + 1])
        if token.startswith("--repo="):
            return normalize_repo(token.split("=", 1)[1])
        if token.startswith("-R="):
            return normalize_repo(token.split("=", 1)[1])
    return ""


def git_repo_from_tail(tail, cwd):
    workdir = cwd
    index = 0
    while index < len(tail) and tail[index] not in BREAKS:
        token = tail[index]
        if token == "commit":
            break
        if token == "-C" and index + 1 < len(tail):
            workdir = resolve_path(tail[index + 1], cwd)
            index += 2
            continue
        if token.startswith("-C") and token != "-C":
            workdir = resolve_path(token[2:], cwd)
            index += 1
            continue
        if token in GIT_FLAGS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        break
    return repo_from_git_dir(workdir) or repo_from_git_dir(cwd)


def current_repo(tool_input=None):
    return repo_from_git_dir(hook_cwd(tool_input))


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


def add_context(contexts, ref, repo):
    if ref:
        contexts.append({"ref": str(ref), "repo": normalize_repo(repo)})


def unique_contexts(contexts):
    seen = set()
    unique = []
    for context in contexts:
        key = (context.get("ref", ""), context.get("repo", ""))
        if key in seen:
            continue
        seen.add(key)
        unique.append(context)
    return unique


def command_ref_contexts(command, tool_input=None, depth=0):
    if depth > 2:
        return []
    contexts = []
    items = tokens(command)
    cwd = hook_cwd(tool_input)
    fallback_repo = current_repo(tool_input)
    for index in command_indices(items):
        token = items[index]
        if base(token) in SHELLS:
            inner = shell_inner_command(items, index)
            if inner:
                contexts.extend(command_ref_contexts(inner, tool_input, depth + 1))
        if base(token) == "git" and git_has_subcommand(items[index + 1:], "commit"):
            repo = git_repo_from_tail(items[index + 1:], cwd)
            for ref in closing_refs(command) | commit_file_refs(items[index + 1:]):
                add_context(contexts, ref, repo)
        if base(token) != "gh":
            continue
        tail = items[index + 1:]
        gh_repo = gh_repo_from_tail(tail) or fallback_repo
        for offset in range(len(tail) - 1):
            pair = (tail[offset], tail[offset + 1])
            if pair == ("pr", "create"):
                for ref in closing_refs(command) | body_file_refs(tail):
                    add_context(contexts, ref, gh_repo)
            if pair in {("issue", "close"), ("issue", "comment")}:
                repo = issue_selector_repo(tail, offset + 2) or gh_repo
                for ref in hash_refs(command) | issue_selector_refs(tail, offset + 2):
                    add_context(contexts, ref, repo)
                if pair == ("issue", "comment"):
                    for ref in body_file_refs(tail):
                        add_context(contexts, ref, repo)
    return unique_contexts(contexts)


def current_ref_contexts():
    tool_input = load_tool_input()
    if TOOL == "mcp__plugin_discord_discord__reply":
        text = json.dumps(tool_input, ensure_ascii=False)
        contexts = []
        for ref, repo in repo_qualified_refs(text):
            add_context(contexts, ref, repo)
        repo = current_repo(tool_input)
        for ref in hash_refs(text):
            add_context(contexts, ref, repo)
        return sorted(unique_contexts(contexts), key=lambda item: int(item["ref"]))
    if TOOL != "Bash":
        return []

    command = tool_input.get("command", "")
    if not isinstance(command, str):
        return []

    return sorted(command_ref_contexts(command, tool_input), key=lambda item: int(item["ref"]))


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


def gh_evidence_repos(command, depth=0):
    if depth > 2:
        return set()
    repos = repos_from_github_urls(command)
    items = tokens(command)
    for index in command_indices(items):
        token = items[index]
        if base(token) in SHELLS:
            inner = shell_inner_command(items, index)
            if inner:
                repos.update(gh_evidence_repos(inner, depth + 1))
        if base(token) != "gh":
            continue
        repo = gh_repo_from_tail(items[index + 1:])
        if repo:
            repos.add(repo)
    return {repo for repo in repos if repo}


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
        r"(?<![A-Za-z0-9_/])#\s*" + escaped + r"\b",
        r"/issues/" + escaped + r"\b",
        r"/pull/" + escaped + r"\b",
        r"\bnumber:\s*" + escaped + r"\b",
        r'"number"\s*:\s*' + escaped + r"\b",
        r"^\s*" + escaped + r"\s+(?:OPEN|CLOSED|MERGED)\b",
    ]
    return any(re.search(pattern, output, re.I | re.M) for pattern in patterns)


def evidence_repos_for_ref(evidence, ref):
    repos = repos_from_github_urls(evidence.get("output", ""), ref)
    if repos:
        return repos
    return evidence.get("command_repos", set())


def check_ref_context(context, evidences):
    ref = context.get("ref", "")
    target_repo = context.get("repo", "")
    if not target_repo:
        return ("PASS", ref, "", "")
    candidates = [evidence for evidence in evidences if mentions_ref(evidence.get("output", ""), ref)]
    if not candidates:
        return ("MISSING", ref, "", "")

    mismatched_repos = set()
    saw_unknown_repo = False
    for evidence in candidates:
        repos = evidence_repos_for_ref(evidence, ref)
        if not repos:
            saw_unknown_repo = True
            continue
        if any(repos_match(target_repo, repo) for repo in repos):
            return ("PASS", ref, "", "")
        mismatched_repos.update(repos)

    if saw_unknown_repo:
        return ("PASS", ref, "", "")
    if mismatched_repos:
        return ("MISMATCH", ref, target_repo, ",".join(sorted(mismatched_repos)))
    return ("PASS", ref, "", "")


contexts = current_ref_contexts()
refs = sorted({context["ref"] for context in contexts}, key=int)
if MODE == "refs":
    print("\n".join(refs))
    raise SystemExit(0)

if not contexts or not JSONL:
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

tool_repos = {}
evidences = []
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
                    tool_repos[tool_id] = gh_evidence_repos(command)
    if message.get("type") == "user" and isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "tool_result" and item.get("tool_use_id") in tool_repos:
                evidences.append(
                    {
                        "output": result_text(item.get("content", "")),
                        "command_repos": tool_repos.get(item.get("tool_use_id"), set()),
                    }
                )

for context in contexts:
    status, ref, target_repo, evidence_repos = check_ref_context(context, evidences)
    if status == "MISSING":
        print("MISSING " + ref)
        raise SystemExit(0)
    if status == "MISMATCH":
        print("MISMATCH " + ref + " " + target_repo + " " + evidence_repos)
        raise SystemExit(0)
print("PASS")
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
    MISMATCH*)
      local missing
      local target
      local evidence
      missing="$(printf '%s' "${status}" | awk '{print $2}')"
      target="$(printf '%s' "${status}" | awk '{print $3}')"
      evidence="$(printf '%s' "${status}" | awk '{print $4}')"
      sop_qa_emit_hint "capture-before-reference" "reference to #${missing} has recent gh capture only from a different repo.

   Target repo: ${target:-unknown}
   Captured repo: ${evidence:-unknown}

   Fix: capture the issue/PR from the same repo before referencing #${missing}
   downstream, or use an explicit repo-qualified reference after same-repo
   evidence is visible in the recent gh output.

   Override: include \`GLUEBOY_GATE_BYPASS=<reason>\` in tool input."
      return 1
      ;;
  esac

  return 0
}
