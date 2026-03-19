#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
script_path="$repo_root/scripts/run-issue-solver.sh"

help_output="$("$script_path" --help)"
grep -q 'Usage: bash scripts/run-issue-solver.sh' <<<"$help_output"
grep -q -- '--backend BACKEND' <<<"$help_output"

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
