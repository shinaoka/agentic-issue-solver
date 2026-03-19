#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "$script_dir/lib.sh"

usage() {
  cat <<'EOF'
Usage: bash scripts/invoke-codex.sh <command> [options]

Commands:
  list-models
  resolve-default-model
  run --target-repo PATH --prompt-file PATH --run-dir PATH [--model MODEL] [-- <extra codex args>]
EOF
}

list_models() {
  local cache_path="${CODEX_HOME:-$HOME/.codex}/models_cache.json"
  if [[ ! -f "$cache_path" ]]; then
    return 0
  fi

  python3 - "$cache_path" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
models = data.get("models", [])
models.sort(key=lambda item: item.get("priority", 10**9))
for item in models:
    slug = item.get("slug")
    display = item.get("display_name") or slug
    priority = item.get("priority")
    if slug:
        print(f"{slug}\t{display}\t{priority}")
PY
}

resolve_default_model() {
  if [[ -n "${AISS_DEFAULT_CODEX_MODEL:-}" ]]; then
    printf '%s\n' "$AISS_DEFAULT_CODEX_MODEL"
    return
  fi

  local configured
  configured="$(aiss_read_toml_model "${CODEX_HOME:-$HOME/.codex}/config.toml" || true)"
  if [[ -n "$configured" ]]; then
    printf '%s\n' "$configured"
    return
  fi

  list_models | head -n 1 | cut -f1
}

run_codex() {
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
        aiss_die "unknown codex run argument: $1"
        ;;
    esac
  done

  [[ -n "$target_repo" ]] || aiss_die "missing --target-repo"
  [[ -n "$prompt_file" ]] || aiss_die "missing --prompt-file"
  [[ -n "$run_dir" ]] || aiss_die "missing --run-dir"

  aiss_require_command codex

  mkdir -p "$run_dir"
  local log_path="$run_dir/codex-output.log"
  local last_message_path="$run_dir/codex-final.txt"
  local cmd=(
    codex exec
    --cd "$target_repo"
    --dangerously-bypass-approvals-and-sandbox
    --output-last-message "$last_message_path"
  )
  if [[ -n "$model" ]]; then
    cmd+=(--model "$model")
  fi
  cmd+=("${extra_args[@]}" -)

  "${cmd[@]}" <"$prompt_file" | tee "$log_path"
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
    run_codex "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    aiss_die "unknown command: $command_name"
    ;;
esac

