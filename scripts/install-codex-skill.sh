#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/install-codex-skill.sh [options]

Options:
  --repo-root PATH   Repository root to install from. Defaults to the current repository root.
  --force            Replace an existing non-matching skill link or directory.
  -h, --help         Show this help.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
force=0

while (($# > 0)); do
  case "$1" in
    --repo-root)
      repo_root="$(cd -- "${2:?missing value for --repo-root}" && pwd -P)"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

skill_target="$repo_root/skills/agentic-issue-solver"
if [[ ! -d "$skill_target" ]]; then
  printf 'skill directory not found: %s\n' "$skill_target" >&2
  exit 1
fi

codex_home="${CODEX_HOME:-$HOME/.codex}"
install_dir="$codex_home/skills"
install_link="$install_dir/agentic-issue-solver"

mkdir -p "$install_dir"

if [[ -L "$install_link" ]]; then
  existing_target="$(readlink "$install_link")"
  if [[ "$existing_target" == "$skill_target" ]]; then
    printf 'already-installed: %s -> %s\n' "$install_link" "$skill_target"
    exit 0
  fi
  if ((force)); then
    rm -f "$install_link"
  else
    printf 'install path already points elsewhere: %s -> %s\n' "$install_link" "$existing_target" >&2
    printf 'rerun with --force to replace it\n' >&2
    exit 1
  fi
elif [[ -e "$install_link" ]]; then
  if ((force)); then
    rm -rf "$install_link"
  else
    printf 'install path already exists and is not a symlink: %s\n' "$install_link" >&2
    printf 'rerun with --force to replace it\n' >&2
    exit 1
  fi
fi

ln -s "$skill_target" "$install_link"
printf 'installed: %s -> %s\n' "$install_link" "$skill_target"

