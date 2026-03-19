#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
script_path="$repo_root/scripts/run-issue-solver.sh"
root_run_wrapper="$repo_root/scripts/run-solver.sh"
root_check_wrapper="$repo_root/scripts/check-installation.sh"
skill_path="$repo_root/skills/agentic-issue-solver/SKILL.md"
install_script="$repo_root/scripts/install.sh"
legacy_codex_install_script="$repo_root/scripts/install-codex-skill.sh"
opencode_install_script="$repo_root/scripts/install-opencode-agent.sh"
opencode_adapter="$repo_root/scripts/invoke-opencode.sh"
opencode_agent_template="$repo_root/templates/opencode-agent.md.in"

test -f "$skill_path"
test -x "$install_script"
test -x "$legacy_codex_install_script"
test -x "$opencode_install_script"
test -x "$opencode_adapter"
test -x "$root_run_wrapper"
test -x "$root_check_wrapper"
test -f "$opencode_agent_template"

grep -q 'one or more GitHub issues' "$repo_root/prompts/solve-issue.md"
grep -q 'unrelated small low-risk bugs may still be bundled' "$repo_root/prompts/solve-issue.md"
grep -q '`issues` array' "$repo_root/skills/agentic-issue-solver/SKILL.md"
grep -q 'bundle several small issues into one PR' "$repo_root/README.md"
grep -q 'OpenCode' "$repo_root/README.md"
grep -q '@agentic-issue-solver' "$repo_root/README.md"
grep -q '\${CODEX_HOME:-\$HOME/.codex}/skills/agentic-issue-solver/scripts/check-installation.sh' \
  "$repo_root/skills/agentic-issue-solver/SKILL.md"
grep -q '\${CODEX_HOME:-\$HOME/.codex}/skills/agentic-issue-solver/scripts/run-solver.sh' \
  "$repo_root/skills/agentic-issue-solver/SKILL.md"
grep -q 'Do not ask the user to choose a model' "$repo_root/skills/agentic-issue-solver/SKILL.md"

help_output="$("$script_path" --help)"
grep -q 'Usage: bash scripts/run-issue-solver.sh' <<<"$help_output"
grep -q -- '--backend BACKEND' <<<"$help_output"
if grep -q -- '--model MODEL' <<<"$help_output"; then
  printf 'run-issue-solver help still exposes --model\n' >&2
  exit 1
fi

run_wrapper_help="$("$root_run_wrapper" --help)"
grep -q 'Usage: bash scripts/run-issue-solver.sh' <<<"$run_wrapper_help"
if grep -q -- '--model MODEL' <<<"$run_wrapper_help"; then
  printf 'run-solver help still exposes --model\n' >&2
  exit 1
fi

check_wrapper_output="$("$root_check_wrapper")"
grep -q '^status=' <<<"$check_wrapper_output"

install_help="$("$install_script" --help)"
grep -q 'Usage: bash scripts/install.sh' <<<"$install_help"
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

dry_run_output="$("$script_path" --backend opencode --target-repo "$target_repo" --dry-run)"
grep -q '"status":"dry_run"' <<<"$dry_run_output"
grep -q '"backend":"opencode"' <<<"$dry_run_output"
grep -q "\"target_repo\":\"$target_repo\"" <<<"$dry_run_output"

install_root="$tmp_dir/install-root"
xdg_data_home="$install_root/data"
codex_home="$install_root/codex-home"
opencode_config_dir="$install_root/opencode-config"
mkdir -p "$xdg_data_home" "$codex_home" "$opencode_config_dir"

XDG_DATA_HOME="$xdg_data_home" CODEX_HOME="$codex_home" OPENCODE_CONFIG_DIR="$opencode_config_dir" \
  "$install_script" --repo-root "$repo_root"

test -L "$codex_home/skills/agentic-issue-solver"
test "$(readlink "$codex_home/skills/agentic-issue-solver")" = \
  "$repo_root/skills/agentic-issue-solver"

test -f "$opencode_config_dir/agents/agentic-issue-solver.md"
grep -q "$repo_root/scripts/check-installation.sh" \
  "$opencode_config_dir/agents/agentic-issue-solver.md"
grep -q "$repo_root/scripts/run-solver.sh" \
  "$opencode_config_dir/agents/agentic-issue-solver.md"
grep -q -- '--backend opencode' \
  "$opencode_config_dir/agents/agentic-issue-solver.md"

installed_run_help="$("$codex_home/skills/agentic-issue-solver/scripts/run-solver.sh" --help)"
grep -q 'Usage: bash scripts/run-issue-solver.sh' <<<"$installed_run_help"
if grep -q -- '--model MODEL' <<<"$installed_run_help"; then
  printf 'installed run-solver help still exposes --model\n' >&2
  exit 1
fi

installed_check_output="$("$codex_home/skills/agentic-issue-solver/scripts/check-installation.sh")"
grep -q '^status=' <<<"$installed_check_output"
