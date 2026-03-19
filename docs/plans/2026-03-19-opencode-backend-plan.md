# OpenCode Backend And Unified Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add OpenCode support for both the outer invocation surface and the inner solver backend while simplifying the public UX to backend-only selection.

**Architecture:** Keep one XDG-managed checkout as the source of truth, install both a Codex skill and a generated OpenCode custom agent from a shared installer, add an `opencode` backend adapter, and remove shared model-selection behavior so backend CLIs use their own defaults.

**Tech Stack:** Bash, Markdown, Git, Codex skills, OpenCode custom agents

---

### Task 1: Add failing smoke expectations for the new install surface

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Assert shared install artifacts**

Check for:
- `scripts/install.sh`
- `scripts/invoke-opencode.sh`
- an OpenCode agent template or generated-install path expectation

**Step 2: Assert backend-only public UX**

Check that public help and docs no longer advertise `--model`.

**Step 3: Run smoke to verify it fails**

Run: `bash tests/smoke.sh`
Expected: FAIL because the repository still documents model selection and has no OpenCode installer path.

### Task 2: Add the shared installer and OpenCode agent support

**Files:**
- Create: `scripts/install.sh`
- Create: `scripts/install-opencode-agent.sh`
- Create: `scripts/invoke-opencode.sh`
- Create: `templates/opencode-agent.md.in`
- Modify: `scripts/install-codex-skill.sh`

**Step 1: Implement shared install flow**

Install both Codex and OpenCode entrypoints by default, with optional single-target wrappers for convenience.

**Step 2: Generate an OpenCode agent file**

Write `agentic-issue-solver.md` into the OpenCode agents directory with the repository root embedded into the command examples so invocation works from arbitrary directories.

**Step 3: Add inner backend adapter**

Support `--backend opencode` by invoking `opencode run` headlessly against the target repository.

### Task 3: Simplify backend/model behavior and harden wrapper paths

**Files:**
- Modify: `scripts/run-issue-solver.sh`
- Modify: `scripts/invoke-codex.sh`
- Modify: `scripts/invoke-claude.sh`
- Modify: `scripts/check-installation.sh`
- Modify: `scripts/run-solver.sh`
- Modify: `skills/agentic-issue-solver/SKILL.md`

**Step 1: Remove shared model-selection UX**

Make backend selection optional with a default, and stop advertising `--model` in public entrypoints.

**Step 2: Keep backend-specific defaults backend-local**

Let Codex, Claude, and OpenCode decide their own default model and effort when no explicit override is provided.

**Step 3: Make installed wrappers stable**

Ensure all installed entrypoints resolve the correct repository-root scripts regardless of the caller's working directory.

### Task 4: Update docs for Codex and OpenCode users

**Files:**
- Modify: `README.md`
- Modify: `.codex/INSTALL.md`
- Modify: `AGENTS.md`

**Step 1: Document the shared installer**

Replace Codex-only install instructions with the shared flow and describe both installed entrypoints.

**Step 2: Document OpenCode usage**

Explain that the installed OpenCode agent is invoked with `@agentic-issue-solver` and does not replace the normal default agent.

### Task 5: Verify and publish

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Run smoke**

Run: `bash tests/smoke.sh`
Expected: PASS

**Step 2: Run shell syntax checks**

Run: `bash -n scripts/*.sh skills/agentic-issue-solver/scripts/*.sh`
Expected: PASS

**Step 3: Commit**

```bash
git add \
  README.md AGENTS.md .codex/INSTALL.md \
  scripts/install.sh scripts/install-codex-skill.sh scripts/install-opencode-agent.sh \
  scripts/invoke-codex.sh scripts/invoke-claude.sh scripts/invoke-opencode.sh \
  scripts/run-issue-solver.sh scripts/run-solver.sh scripts/check-installation.sh \
  skills/agentic-issue-solver/SKILL.md templates/opencode-agent.md.in \
  tests/smoke.sh \
  docs/plans/2026-03-19-opencode-backend-design.md \
  docs/plans/2026-03-19-opencode-backend-plan.md
git commit -m "feat: add opencode backend and shared installer"
```
