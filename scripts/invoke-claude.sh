#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "$script_dir/lib.sh"

usage() {
  cat <<'EOF'
Usage: bash scripts/invoke-claude.sh <command> [options]

Commands:
  list-models
  resolve-default-model
  run --target-repo PATH --prompt-file PATH --run-dir PATH [--model MODEL] [-- <extra claude args>]
EOF
}

list_models() {
  if [[ -n "${AISS_DEFAULT_CLAUDE_MODEL:-}" ]]; then
    printf '%s\n' "$AISS_DEFAULT_CLAUDE_MODEL"
  fi

  local stats_path="${CLAUDE_HOME:-$HOME/.claude}/stats-cache.json"
  if [[ ! -f "$stats_path" ]]; then
    return 0
  fi

  python3 - "$stats_path" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
usage = data.get("modelUsage", {})
for model_name in sorted(usage):
    print(model_name)
PY
}

resolve_default_model() {
  if [[ -n "${AISS_DEFAULT_CLAUDE_MODEL:-}" ]]; then
    printf '%s\n' "$AISS_DEFAULT_CLAUDE_MODEL"
    return
  fi

  # Claude Code does not expose a stable local model-listing command in the
  # current CLI. Return an empty string and allow the CLI default to apply.
  printf '%s' ""
}

run_claude() {
  local target_repo=""
  local prompt_file=""
  local run_dir=""
  local model=""
  local extra_args=()

  while (($# > 0)); do
    case "$1" in
      --target-repo)
        target_repo="${2:?missing value for --target-repo}"
        shift 2
        ;;
      --prompt-file)
        prompt_file="${2:?missing value for --prompt-file}"
        shift 2
        ;;
      --run-dir)
        run_dir="${2:?missing value for --run-dir}"
        shift 2
        ;;
      --model)
        model="${2:?missing value for --model}"
        shift 2
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      *)
        aiss_die "unknown claude run argument: $1"
        ;;
    esac
  done

  [[ -n "$target_repo" ]] || aiss_die "missing --target-repo"
  [[ -n "$prompt_file" ]] || aiss_die "missing --prompt-file"
  [[ -n "$run_dir" ]] || aiss_die "missing --run-dir"

  aiss_require_command claude

  mkdir -p "$run_dir"
  local log_path="$run_dir/claude-output.log"
  local prompt_text
  prompt_text="$(cat "$prompt_file")"
  local cmd=(
    claude
    --print
    --dangerously-skip-permissions
    --output-format text
  )
  if [[ -n "$model" ]]; then
    cmd+=(--model "$model")
  fi
  cmd+=("${extra_args[@]}" "$prompt_text")

  (
    cd "$target_repo"
    "${cmd[@]}"
  ) | tee "$log_path"
}

command_name="${1:-}"
if [[ -z "$command_name" ]]; then
  usage >&2
  exit 2
fi
shift

case "$command_name" in
  list-models)
    list_models
    ;;
  resolve-default-model)
    resolve_default_model
    ;;
  run)
    run_claude "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    aiss_die "unknown command: $command_name"
    ;;
esac

