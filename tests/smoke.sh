#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
script_path="$repo_root/scripts/run-issue-solver.sh"
skill_path="$repo_root/skills/agentic-issue-solver/SKILL.md"
install_script="$repo_root/scripts/install-codex-skill.sh"

test -f "$skill_path"
test -x "$install_script"

grep -q 'one or more GitHub issues' "$repo_root/prompts/solve-issue.md"
grep -q 'unrelated small low-risk bugs may still be bundled' "$repo_root/prompts/solve-issue.md"
grep -q '`issues` array' "$repo_root/skills/agentic-issue-solver/SKILL.md"
grep -q 'bundle several small issues into one PR' "$repo_root/README.md"

help_output="$("$script_path" --help)"
grep -q 'Usage: bash scripts/run-issue-solver.sh' <<<"$help_output"
grep -q -- '--backend BACKEND' <<<"$help_output"

install_help="$("$install_script" --help)"
grep -q 'Usage: bash scripts/install-codex-skill.sh' <<<"$install_help"
grep -q -- '--repo-root PATH' <<<"$install_help"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

target_repo="$tmp_dir/target-repo"
mkdir -p "$target_repo/ai"
git init -q "$target_repo"

cat > "$target_repo/AGENTS.md" <<'EOF'
# AGENTS.md

If issue solving is needed, read https://github.com/shinaoka/agentic-issue-solver on `main`.
EOF

cat > "$target_repo/ai/AGENTIC_ISSUE_SOLVER.md" <<'EOF'
# Target Instructions

Use repo-specific PR workflow if one is documented.
EOF

dry_run_output="$("$script_path" --backend codex --target-repo "$target_repo" --dry-run)"
grep -q '"status":"dry_run"' <<<"$dry_run_output"
grep -q '"backend":"codex"' <<<"$dry_run_output"
grep -q "\"target_repo\":\"$target_repo\"" <<<"$dry_run_output"

install_root="$tmp_dir/install-root"
xdg_data_home="$install_root/data"
codex_home="$install_root/codex-home"
mkdir -p "$xdg_data_home" "$codex_home"

XDG_DATA_HOME="$xdg_data_home" CODEX_HOME="$codex_home" \
  "$install_script" --repo-root "$repo_root"

test -L "$codex_home/skills/agentic-issue-solver"
test "$(readlink "$codex_home/skills/agentic-issue-solver")" = \
  "$repo_root/skills/agentic-issue-solver"
