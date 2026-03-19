# Installable Skill Packaging Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Package agentic-issue-solver as a Codex-installable skill while keeping the repository as the single source of truth.

**Architecture:** Keep the repository clone under XDG data, expose the skill itself through Codex's native `$CODEX_HOME/skills` directory, and make the installed skill check `origin/main` on every invocation.

**Tech Stack:** Bash, Git, Codex skill discovery

---

### Task 1: Add failing smoke expectations

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Assert the installable skill exists**

Check for `skills/agentic-issue-solver/SKILL.md` and `scripts/install-codex-skill.sh`.

**Step 2: Run smoke to verify it fails**

Run: `bash tests/smoke.sh`
Expected: FAIL before the new files exist.

### Task 2: Add install helper and skill package

**Files:**
- Create: `scripts/install-codex-skill.sh`
- Create: `skills/agentic-issue-solver/SKILL.md`
- Create: `skills/agentic-issue-solver/scripts/check-installation.sh`
- Create: `skills/agentic-issue-solver/scripts/run-solver.sh`

**Step 1: Implement manual install**

Create a symlink from `$CODEX_HOME/skills/agentic-issue-solver` to the cloned repo's skill directory.

**Step 2: Implement update check**

Compare local `HEAD` to `origin/main` on every invocation.

### Task 3: Add install docs

**Files:**
- Create: `.codex/INSTALL.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Step 1: Document XDG clone + Codex skill symlink**

Use `${XDG_DATA_HOME:-$HOME/.local/share}` for the clone and `${CODEX_HOME:-$HOME/.codex}/skills` for discovery.

### Task 4: Verify

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Run shell syntax checks**

Run: `bash -n scripts/*.sh skills/agentic-issue-solver/scripts/*.sh`
Expected: PASS

**Step 2: Run smoke**

Run: `bash tests/smoke.sh`
Expected: PASS

