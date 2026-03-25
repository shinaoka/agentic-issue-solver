#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/install.sh [options]

Options:
  --repo-root PATH   Repository root to install from. Defaults to the current repository root.
  --codex-only       Install only the Codex skill entrypoint.
  --opencode-only    Install only the OpenCode agent entrypoint.
  --claude-only      Install only the Claude Code command entrypoint.
  --force            Replace an existing non-matching install target.
  -h, --help         Show this help.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
force=0
install_codex=1
install_opencode=1
install_claude=1

while (($# > 0)); do
  case "$1" in
    --repo-root)
      repo_root="$(cd -- "${2:?missing value for --repo-root}" && pwd -P)"
      shift 2
      ;;
    --codex-only)
      install_opencode=0
      install_claude=0
      shift
      ;;
    --opencode-only)
      install_codex=0
      install_claude=0
      shift
      ;;
    --claude-only)
      install_codex=0
      install_opencode=0
      shift
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

if ((install_codex == 0 && install_opencode == 0 && install_claude == 0)); then
  printf 'nothing to install: choose at least one target\n' >&2
  exit 2
fi

install_codex_entrypoint() {
  local skill_target="$repo_root/skills/agentic-issue-solver"
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local install_dir="$codex_home/skills"
  local install_link="$install_dir/agentic-issue-solver"
  local existing_target

  if [[ ! -d "$skill_target" ]]; then
    printf 'skill directory not found: %s\n' "$skill_target" >&2
    exit 1
  fi

  mkdir -p "$install_dir"

  if [[ -L "$install_link" ]]; then
    existing_target="$(readlink "$install_link")"
    if [[ "$existing_target" == "$skill_target" ]]; then
      printf 'already-installed: %s -> %s\n' "$install_link" "$skill_target"
      return
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
}

render_opencode_agent() {
  local template_path="$repo_root/templates/opencode-agent.md.in"
  python3 - "$template_path" "$repo_root" <<'PY'
import pathlib
import sys

template = pathlib.Path(sys.argv[1]).read_text()
repo_root = sys.argv[2]
print(template.replace("__AISS_REPO_ROOT__", repo_root), end="")
PY
}

install_opencode_entrypoint() {
  local template_path="$repo_root/templates/opencode-agent.md.in"
  local config_root="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
  local install_dir="$config_root/agents"
  local install_path="$install_dir/agentic-issue-solver.md"
  local tmp_path

  if [[ ! -f "$template_path" ]]; then
    printf 'OpenCode agent template not found: %s\n' "$template_path" >&2
    exit 1
  fi

  mkdir -p "$install_dir"
  tmp_path="$(mktemp "${TMPDIR:-/tmp}/agentic-issue-solver-opencode.XXXXXX")"
  trap 'rm -f "$tmp_path"' RETURN
  render_opencode_agent >"$tmp_path"

  if [[ -f "$install_path" ]] && cmp -s "$tmp_path" "$install_path"; then
    printf 'already-installed: %s\n' "$install_path"
    rm -f "$tmp_path"
    trap - RETURN
    return
  fi

  if [[ -e "$install_path" && ! -f "$install_path" ]]; then
    if ((force)); then
      rm -rf "$install_path"
    else
      printf 'install path already exists and is not a regular file: %s\n' "$install_path" >&2
      printf 'rerun with --force to replace it\n' >&2
      exit 1
    fi
  elif [[ -f "$install_path" && ! -w "$install_path" && ! -w "$install_dir" ]]; then
    printf 'install path is not writable: %s\n' "$install_path" >&2
    exit 1
  elif [[ -f "$install_path" ]]; then
    if ! cmp -s "$tmp_path" "$install_path" && ((force == 0)); then
      printf 'install path already exists with different contents: %s\n' "$install_path" >&2
      printf 'rerun with --force to replace it\n' >&2
      exit 1
    fi
  fi

  mv "$tmp_path" "$install_path"
  trap - RETURN
  printf 'installed: %s\n' "$install_path"
}

render_claude_command() {
  local template_path="$repo_root/templates/claude-command.md.in"
  python3 - "$template_path" "$repo_root" <<'PY'
import pathlib
import sys

template = pathlib.Path(sys.argv[1]).read_text()
repo_root = sys.argv[2]
print(template.replace("__AISS_REPO_ROOT__", repo_root), end="")
PY
}

install_claude_entrypoint() {
  local template_path="$repo_root/templates/claude-command.md.in"
  local claude_home="${CLAUDE_HOME:-$HOME/.claude}"
  local install_dir="$claude_home/commands"
  local install_path="$install_dir/agentic-issue-solver.md"
  local tmp_path

  if [[ ! -f "$template_path" ]]; then
    printf 'Claude command template not found: %s\n' "$template_path" >&2
    exit 1
  fi

  mkdir -p "$install_dir"
  tmp_path="$(mktemp "${TMPDIR:-/tmp}/agentic-issue-solver-claude.XXXXXX")"
  trap 'rm -f "$tmp_path"' RETURN
  render_claude_command >"$tmp_path"

  if [[ -f "$install_path" ]] && cmp -s "$tmp_path" "$install_path"; then
    printf 'already-installed: %s\n' "$install_path"
    rm -f "$tmp_path"
    trap - RETURN
    return
  fi

  if [[ -e "$install_path" && ! -f "$install_path" ]]; then
    if ((force)); then
      rm -rf "$install_path"
    else
      printf 'install path already exists and is not a regular file: %s\n' "$install_path" >&2
      printf 'rerun with --force to replace it\n' >&2
      exit 1
    fi
  elif [[ -f "$install_path" && ! -w "$install_path" && ! -w "$install_dir" ]]; then
    printf 'install path is not writable: %s\n' "$install_path" >&2
    exit 1
  elif [[ -f "$install_path" ]]; then
    if ! cmp -s "$tmp_path" "$install_path" && ((force == 0)); then
      printf 'install path already exists with different contents: %s\n' "$install_path" >&2
      printf 'rerun with --force to replace it\n' >&2
      exit 1
    fi
  fi

  mv "$tmp_path" "$install_path"
  trap - RETURN
  printf 'installed: %s\n' "$install_path"
}

if ((install_codex)); then
  install_codex_entrypoint
fi

if ((install_opencode)); then
  install_opencode_entrypoint
fi

if ((install_claude)); then
  install_claude_entrypoint
fi
