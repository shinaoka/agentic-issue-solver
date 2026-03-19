# Installing agentic-issue-solver for Codex

Install the repository clone under XDG data, then expose the bundled skill through Codex's native skill directory.

## Prerequisites

- Git
- Codex CLI

## Installation

1. Clone the repository into your user data directory:

```bash
git clone https://github.com/shinaoka/agentic-issue-solver.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver"
```

2. Create the Codex skill symlink:

```bash
cd "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver"
bash scripts/install-codex-skill.sh
```

3. Restart Codex.

## Verify

```bash
ls -la "${CODEX_HOME:-$HOME/.codex}/skills/agentic-issue-solver"
```

It should point to:

```bash
${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver/skills/agentic-issue-solver
```

## Updating

```bash
git -C "${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver" pull --ff-only
```

The installed skill checks for updates on every invocation and will remind you when `origin/main` is ahead of the local checkout.

