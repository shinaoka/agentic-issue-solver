# OpenCode Backend And Unified Install Design

## Goal

Extend `agentic-issue-solver` so that both the outer agent and the inner solver backend can run on OpenCode, while keeping the default experience simple for Codex users and preserving the repository as the single shared implementation.

## Decisions

- Keep a single shared clone under `${XDG_DATA_HOME:-$HOME/.local/share}/agentic-issue-solver`.
- Install both entrypoints from one installer:
  - Codex skill under `${CODEX_HOME:-$HOME/.codex}/skills/agentic-issue-solver`
  - OpenCode custom agent under `${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}/agents/agentic-issue-solver.md`
- Do not replace the user's default OpenCode agent. Use `@agentic-issue-solver` on demand.
- Default the inner backend to the outer environment:
  - Codex skill defaults to `codex`
  - OpenCode custom agent defaults to `opencode`
- Keep backend override possible for exceptional cases.
- Drop model selection from the shared UX. Let each backend CLI use its own default model and reasoning effort.
- Keep update checks on every invocation.
- Fix installed-entrypoint path resolution so skill and agent invocations work from arbitrary working directories.

## Why This Shape

Using one shared installer keeps the operational model simple: one clone, one update command, one place to evolve prompts and scripts. Using an OpenCode custom agent aligns with OpenCode's native natural-language workflow and avoids inventing a separate command surface.

Defaulting the inner backend to the outer environment removes a common source of friction. In the normal case, users do not need to think about backend routing at all. Explicit override remains available when a repository or a user needs a different inner engine.

Dropping shared model selection avoids backend-specific drift and brittle model-name handling. The central repository should orchestrate workflows, not reimplement provider model-management UX.

## Scope

In scope:

- new `opencode` backend adapter
- shared installer for Codex + OpenCode
- generated OpenCode custom agent file
- wrapper-path hardening
- documentation and smoke-test updates

Out of scope:

- built-in batch looping
- automatic self-update
- hardcoded backend model catalogs
- replacing repository-local instructions with structured config
