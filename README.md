# agentic-issue-solver

Single-run issue solver for repository-local bug fixing with headless coding agents.

This repository is intended to be the central, shared implementation. Target repositories do not vendor these scripts. They only point to this repository from `AGENTS.md` and optionally add repo-specific instructions in `ai/AGENTIC_ISSUE_SOLVER.md`.

## Status

This is an initial bootstrap. The first goal is one command that:

1. reads target-repository instructions
2. selects a backend and optional model
3. renders a hardened issue-solving prompt
4. invokes one headless agent run against exactly one target repository

Looping, campaign management, and long-lived monitoring are intentionally left to the outer AI.

## Core Ideas

- Centralized implementation: update one repository instead of copying scripts everywhere.
- Repo-specific customization: use `ai/AGENTIC_ISSUE_SOLVER.md` in the target repo.
- No hardcoded model defaults: if `--model` is omitted, the backend adapter uses the CLI default or a locally configured default when detectable.
- Repo procedures over fixed filenames: if the target repository documents its own PR/CI workflow, the solver should follow that before using generic fallback behavior.

## Current Layout

```text
agentic-issue-solver/
├── AGENTS.md
├── docs/plans/
├── examples/
├── prompts/
├── scripts/
└── tests/
```

## Planned Usage

Dry run:

```bash
bash scripts/run-issue-solver.sh \
  --backend codex \
  --target-repo /path/to/target-repo \
  --dry-run
```

Live run:

```bash
bash scripts/run-issue-solver.sh \
  --backend claude \
  --target-repo /path/to/target-repo \
  --model claude-sonnet-4-6
```

## Target Repository Contract

The target repository should provide:

- `AGENTS.md` with a pointer to this repository
- optional `ai/AGENTIC_ISSUE_SOLVER.md` with repo-specific issue-solver instructions

Repo-specific instructions may be natural language. They do not need to be machine-readable configuration.

## Model Resolution

Current local CLI help for `codex` and `claude` does not expose a stable structured "list models" command. This repository therefore treats model resolution as best-effort:

- explicit `--model` wins
- otherwise the adapter may use a locally configured default if it can detect one
- otherwise the adapter omits `--model` and lets the backend CLI choose its default

This avoids hardcoding model names in the shared scripts.

