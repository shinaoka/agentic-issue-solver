# AGENTS.md

Read `README.md` before changing this repository.

## Purpose

This repository is the central implementation of the issue solver. Do not vendor shared rules into target repositories. Target-repository customization belongs in `ai/AGENTIC_ISSUE_SOLVER.md` inside the target repository.

This repository also packages an installable Codex skill under `skills/agentic-issue-solver/`, an installable OpenCode custom agent generated from `templates/opencode-agent.md.in`, and an installable Claude Code command generated from `templates/claude-command.md.in`. The manual install flow keeps the clone under XDG data and exposes these entrypoints through the host agent's native discovery locations.

## Development Rules

- Source and docs in English
- Keep scripts in POSIX-friendly Bash where practical
- Do not add shared model-selection UX or hardcoded backend model defaults
- Respect repo-specific procedures described by the target repository before using generic fallback steps
- Prefer small shell scripts with explicit responsibilities over one large orchestrator script

## Verification

Before claiming changes work, run:

```bash
bash tests/smoke.sh
bash -n scripts/*.sh
bash -n skills/agentic-issue-solver/scripts/*.sh
```

## Scope

- Single-run solver only
- No built-in outer loop or campaign manager
- No vendored shared-rule bundle system
