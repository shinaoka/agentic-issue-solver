#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
# shellcheck source=./lib.sh
source "$script_dir/lib.sh"

usage() {
  cat <<'EOF'
Usage: bash scripts/run-issue-solver.sh [options] [-- <extra backend args>]

Options:
  --backend BACKEND      Backend adapter name. Defaults to AISS_DEFAULT_BACKEND or codex.
  --target-repo PATH     Target repository root. Defaults to the current working directory.
  --prompt PATH          Base prompt file. Defaults to prompts/solve-issue.md in this repository.
  --run-dir PATH         Directory for generated prompt and backend logs. Defaults to a fresh temporary directory.
  --dry-run              Render the prompt and print a JSON summary without invoking the backend.
  -h, --help             Show this help.
EOF
}

backend="${AISS_DEFAULT_BACKEND:-codex}"
target_repo_arg="."
prompt_arg="$repo_root/prompts/solve-issue.md"
run_dir=""
dry_run=0
extra_args=()

while (($# > 0)); do
  case "$1" in
    --backend)
      backend="${2:?missing value for --backend}"
      shift 2
      ;;
    --target-repo)
      target_repo_arg="${2:?missing value for --target-repo}"
      shift 2
      ;;
    --prompt)
      prompt_arg="${2:?missing value for --prompt}"
      shift 2
      ;;
    --run-dir)
      run_dir="${2:?missing value for --run-dir}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      extra_args=("$@")
      break
      ;;
    *)
      aiss_die "unknown argument: $1"
      ;;
  esac
done

if [[ "$prompt_arg" != /* ]]; then
  prompt_arg="$repo_root/$prompt_arg"
fi
[[ -f "$prompt_arg" ]] || aiss_die "prompt file not found: $prompt_arg"

adapter_path="$script_dir/invoke-${backend}.sh"
[[ -x "$adapter_path" ]] || aiss_die "backend adapter not found or not executable: $adapter_path"

target_repo="$(aiss_resolve_target_repo_root "$target_repo_arg")"
[[ -d "$target_repo" ]] || aiss_die "target repository not found: $target_repo"

if [[ -z "$run_dir" ]]; then
  run_dir="$(mktemp -d "${TMPDIR:-/tmp}/agentic-issue-solver.XXXXXX")"
else
  mkdir -p "$run_dir"
  run_dir="$(aiss_abs_dir "$run_dir")"
fi

rendered_prompt="$run_dir/rendered-prompt.md"
aiss_render_prompt "$prompt_arg" "$target_repo" "$rendered_prompt"

if ((dry_run)); then
  aiss_emit_json \
    "status=dry_run" \
    "backend=$backend" \
    "target_repo=$target_repo" \
    "prompt_file=$rendered_prompt" \
    "run_dir=$run_dir"
  exit 0
fi

aiss_log "backend=$backend"
aiss_log "target_repo=$target_repo"
aiss_log "prompt_file=$rendered_prompt"
aiss_log "run_dir=$run_dir"

run_args=(
  run
  --target-repo "$target_repo"
  --prompt-file "$rendered_prompt"
  --run-dir "$run_dir"
)
if ((${#extra_args[@]} > 0)); then
  run_args+=(-- "${extra_args[@]}")
fi

"$adapter_path" "${run_args[@]}"

for result_candidate in \
  "$run_dir/final-message.txt" \
  "$run_dir/${backend}-output.log"
do
  result_marker="$(aiss_extract_last_marker "AISS_RESULT:" "$result_candidate" || true)"
  if [[ -n "$result_marker" ]]; then
    printf '%s\n' "$result_marker"
    break
  fi
done
