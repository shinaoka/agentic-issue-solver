#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "$script_dir/lib.sh"

usage() {
  cat <<'EOF'
Usage: bash scripts/invoke-opencode.sh <command> [options]

Commands:
  run --target-repo PATH --prompt-file PATH --run-dir PATH [-- <extra opencode args>]
EOF
}

run_opencode() {
  local target_repo=""
  local prompt_file=""
  local run_dir=""
  local extra_args=()
  local prompt_text=""

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
      --)
        shift
        extra_args=("$@")
        break
        ;;
      *)
        aiss_die "unknown opencode run argument: $1"
        ;;
    esac
  done

  [[ -n "$target_repo" ]] || aiss_die "missing --target-repo"
  [[ -n "$prompt_file" ]] || aiss_die "missing --prompt-file"
  [[ -n "$run_dir" ]] || aiss_die "missing --run-dir"

  aiss_require_command opencode

  mkdir -p "$run_dir"
  prompt_text="$(cat "$prompt_file")"

  local log_path="$run_dir/opencode-output.log"
  local last_message_path="$run_dir/final-message.txt"
  local cmd=(
    opencode run
    --dir "$target_repo"
    --agent build
    "${extra_args[@]}"
    "$prompt_text"
  )

  "${cmd[@]}" | tee "$log_path" "$last_message_path"
}

command_name="${1:-}"
if [[ -z "$command_name" ]]; then
  usage >&2
  exit 2
fi
shift

case "$command_name" in
  run)
    run_opencode "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    aiss_die "unknown command: $command_name"
    ;;
esac
