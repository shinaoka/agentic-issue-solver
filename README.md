# agentic-issue-solver

Single-run issue solver for repository-local bug fixing with headless coding agents.

This repository is intended to be the central, shared implementation. Target repositories do not vendor these scripts. They only point to this repository from `AGENTS.md` and optionally add repo-specific instructions in `ai/AGENTIC_ISSUE_SOLVER.md`.

## Status

This is an initial bootstrap. The first goal is one command that:

1. reads target-repository instructions
2. selects or defaults a backend
3. renders a hardened issue-solving prompt
4. invokes one headless agent run against exactly one target repository

Looping, campaign management, and long-lived monitoring are intentionally left to the outer AI.

## Installation

Install the repository clone under XDG data, then install both the Codex skill entrypoint and the OpenCode custom-agent entrypoint from one shared installer.

```bash
git clone https://github.com/shinaoka/agentic-issue-solver.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver"

cd "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver"
bash scripts/install.sh
```

This creates:

```text
${CODEX_HOME:-$HOME/.codex}/skills/agentic-issue-solver
  -> ${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver/skills/agentic-issue-solver

${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}/agents/agentic-issue-solver.md

${CLAUDE_HOME:-$HOME/.claude}/commands/agentic-issue-solver.md
```

Restart Codex after installation so the skill is discovered. OpenCode discovers the installed custom agent from its config directory. Claude Code discovers the command from its commands directory.

Quick install instructions for Codex also live in [.codex/INSTALL.md](./.codex/INSTALL.md).

## Core Ideas

- Centralized implementation: update one repository instead of copying scripts everywhere.
- Repo-specific customization: use `ai/AGENTIC_ISSUE_SOLVER.md` in the target repo.
- No shared model selection: each backend CLI uses its own default model and reasoning effort.
- Repo procedures over fixed filenames: if the target repository documents its own PR/CI workflow, the solver should follow that before using generic fallback behavior.
- One run, one workstream: the solver still performs a single run, but it may bundle several small issues into one PR when that is cleaner and lower-risk than splitting them apart.

## Current Layout

```text
agentic-issue-solver/
├── .codex/
├── AGENTS.md
├── docs/plans/
├── examples/
├── prompts/
├── scripts/
├── skills/
└── tests/
```

## Planned Usage

Dry run:

```bash
bash scripts/run-issue-solver.sh \
  --backend opencode \
  --target-repo /path/to/target-repo \
  --dry-run
```

Live run:

```bash
bash scripts/run-issue-solver.sh \
  --backend claude \
  --target-repo /path/to/target-repo
```

Convenience wrappers also exist at the repository root:

```bash
bash scripts/install.sh
bash scripts/check-installation.sh
bash scripts/run-solver.sh --target-repo /path/to/target-repo --backend codex
```

## Target Repository Contract

The target repository should provide:

- `AGENTS.md` with a pointer to this repository
- optional `ai/AGENTIC_ISSUE_SOLVER.md` with repo-specific issue-solver instructions

Repo-specific instructions may be natural language. They do not need to be machine-readable configuration.

## Installed Entrypoint Behavior

The installed Codex skill:

- runs one solver pass at a time
- may bundle several small issues into one PR when the agent judges that to be the best tradeoff
- checks for upstream updates on every invocation by comparing local `HEAD` with `origin/main`
- prompts the user to update when the local clone is stale
- respects target-repository instructions from `AGENTS.md` and `ai/AGENTIC_ISSUE_SOLVER.md`
- should be invoked through `${CODEX_HOME:-$HOME/.codex}/skills/agentic-issue-solver/scripts/...` from arbitrary working directories

The installed OpenCode custom agent:

- is installed at `${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}/agents/agentic-issue-solver.md`
- is meant to be used on demand with `@agentic-issue-solver`
- defaults the inner backend to `opencode`
- does not replace the user's normal default OpenCode agent

The installed Claude Code command:

- is installed at `${CLAUDE_HOME:-$HOME/.claude}/commands/agentic-issue-solver.md`
- is meant to be used on demand with `/agentic-issue-solver`
- defaults the inner backend to `claude`

## Backend Defaults

This repository keeps backend choice simple:

- Codex skill defaults to `codex`
- OpenCode custom agent defaults to `opencode`
- Claude Code command defaults to `claude`
- explicit `--backend` still overrides the default when needed
- the solver does not ask the user to choose a model

## Updating

```bash
git -C "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver" pull --ff-only
```

The installed entrypoints will remind you when this repository is behind `origin/main`.
