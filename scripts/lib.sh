#!/usr/bin/env bash
set -euo pipefail

aiss_log() {
  printf '%s\n' "$*" >&2
}

aiss_die() {
  aiss_log "$*"
  exit 1
}

aiss_require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    aiss_die "missing required command: $1"
  fi
}

aiss_abs_dir() {
  (
    cd -- "$1"
    pwd -P
  )
}

aiss_resolve_target_repo_root() {
  local input_dir="$1"
  local abs_dir
  abs_dir="$(aiss_abs_dir "$input_dir")"
  if git -C "$abs_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$abs_dir" rev-parse --show-toplevel
  else
    printf '%s\n' "$abs_dir"
  fi
}

aiss_append_file_section() {
  local label="$1"
  local file_path="$2"
  local output_path="$3"

  if [[ ! -f "$file_path" ]]; then
    return
  fi

  {
    printf '\n## %s\n\n' "$label"
    printf 'Path: `%s`\n\n' "$file_path"
    cat "$file_path"
    printf '\n'
  } >>"$output_path"
}

aiss_render_prompt() {
  local base_prompt="$1"
  local target_repo="$2"
  local output_path="$3"

  : >"$output_path"
  cat "$base_prompt" >>"$output_path"

  {
    printf '\n\n# Target Repository Context\n\n'
    printf 'Target repository root: `%s`\n' "$target_repo"
    printf '\nFollow repository-specific instructions below before applying any generic fallback procedure.\n'
  } >>"$output_path"

  aiss_append_file_section "AGENTS.md" "$target_repo/AGENTS.md" "$output_path"
  aiss_append_file_section "ai/AGENTIC_ISSUE_SOLVER.md" "$target_repo/ai/AGENTIC_ISSUE_SOLVER.md" "$output_path"
  aiss_append_file_section "README.md" "$target_repo/README.md" "$output_path"
}

aiss_emit_json() {
  python3 - "$@" <<'PY'
import json
import sys

payload = {}
for item in sys.argv[1:]:
    key, value = item.split("=", 1)
    if value == "__NULL__":
        payload[key] = None
    else:
        payload[key] = value
print(json.dumps(payload, separators=(",", ":")))
PY
}

aiss_extract_last_marker() {
  local marker="$1"
  local file_path="$2"
  if [[ ! -f "$file_path" ]]; then
    return 1
  fi
  grep -E "^${marker}" "$file_path" | tail -n 1
}

