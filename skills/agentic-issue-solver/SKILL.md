---
name: agentic-issue-solver
description: Use when the user wants one automated GitHub issue-solving pass against the current repository, wants to run the centralized issue solver, or wants to check whether the installed issue-solver skill is out of date
---

# Agentic Issue Solver

Run exactly one centralized issue-solving pass against the current repository.

This skill is intended for Codex installations where the skill directory is a symlink into a cloned checkout of `shinaoka/agentic-issue-solver`.

## First Step: Check Installation Freshness

At the start of every invocation, run:

```bash
bash scripts/check-installation.sh
```

Interpret the result:

- `status=ok`: continue
- `status=update-available`: tell the user an update exists and show the exact `git pull --ff-only` command
- `status=detached-copy`: tell the user the skill is not running from a git checkout and recommend reinstalling via the documented clone-plus-symlink flow
- `remote_status=unavailable`: mention that update status could not be confirmed, then continue if the task is otherwise unblocked

Do not auto-update. Prompt the user to update, but continue when the request is still actionable on the installed version.

## Scope

- One solver run only
- No built-in outer loop
- No long-lived campaign manager
- No assumption that target repositories vendor these scripts

## Target Repository Inputs

Before invoking the solver, inspect the target repository:

- `AGENTS.md`
- `ai/AGENTIC_ISSUE_SOLVER.md` if present
- `README.md` when more context is needed

Repository-specific instructions may be natural language. Respect documented repository procedures for verification, PR creation, merge, CI monitoring, and closeout before using fallback behavior.

## Choosing Backend and Model

- If the user explicitly names a backend, use it
- If the user explicitly names a model, pass it through unchanged
- Otherwise default to `codex`
- If no model is specified, omit `--model` and let the backend adapter resolve a default or defer to the backend CLI

## Running the Solver

From the target repository root, or with an explicit path, run:

```bash
bash scripts/run-solver.sh --target-repo /path/to/target-repo
```

Examples:

```bash
bash scripts/run-solver.sh --target-repo . --backend codex
```

```bash
bash scripts/run-solver.sh --target-repo . --backend codex --model gpt-5.4-mini
```

```bash
bash scripts/run-solver.sh --target-repo . --backend claude --model claude-sonnet-4-6
```

## Result Handling

The solver prints a final single-line JSON summary. Use that summary to tell the user what happened:

- `fixed`
- `closed_stale`
- `commented_no_fix`
- `no_actionable_issue`
- `failed`

If the user wants repeated runs or continuous PR/CI monitoring, that is outer orchestration. Run multiple single passes rather than inventing an internal loop.

