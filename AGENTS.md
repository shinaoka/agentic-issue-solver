# AGENTS.md

Read `README.md` before changing this repository.

## Purpose

This repository is the central implementation of the issue solver. Do not vendor shared rules into target repositories. Target-repository customization belongs in `ai/AGENTIC_ISSUE_SOLVER.md` inside the target repository.

This repository also packages an installable Codex skill under `skills/agentic-issue-solver/`. The manual install flow keeps the clone under XDG data and exposes that skill through `$CODEX_HOME/skills`.

## Development Rules

- Source and docs in English
- Keep scripts in POSIX-friendly Bash where practical
- Do not hardcode backend model names as defaults
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
