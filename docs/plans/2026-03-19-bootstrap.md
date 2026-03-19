# Agentic Issue Solver Bootstrap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bootstrap a new public repository that can run one issue-solving agent pass against an arbitrary target repository.

**Architecture:** Keep the implementation shell-first. Use one public launcher, one hardened prompt, and one adapter per backend. Read target-repository instructions from `AGENTS.md` and `ai/AGENTIC_ISSUE_SOLVER.md`, and let repo-specific natural-language procedures override generic fallback behavior.

**Tech Stack:** Bash, GitHub CLI, Codex CLI, Claude Code CLI

---

### Task 1: Add the red-phase smoke test

**Files:**
- Create: `tests/smoke.sh`

**Step 1: Write the failing test**

Add a shell smoke test that expects `scripts/run-issue-solver.sh --help` to work and `--dry-run` to emit a JSON summary.

**Step 2: Run test to verify it fails**

Run: `bash tests/smoke.sh`
Expected: FAIL because `scripts/run-issue-solver.sh` does not exist yet.

### Task 2: Add the launcher and shared helpers

**Files:**
- Create: `scripts/lib.sh`
- Create: `scripts/run-issue-solver.sh`

**Step 1: Write minimal implementation**

Implement argument parsing, target-repo discovery, prompt rendering, backend adapter resolution, and a dry-run JSON summary.

**Step 2: Run the smoke test**

Run: `bash tests/smoke.sh`
Expected: PASS for `--help` and `--dry-run`.

### Task 3: Add backend adapters

**Files:**
- Create: `scripts/invoke-codex.sh`
- Create: `scripts/invoke-claude.sh`

**Step 1: Implement adapter commands**

Support `list-models`, `resolve-default-model`, and `run`.

**Step 2: Keep model resolution non-hardcoded**

If a configured default is detectable, return it. Otherwise emit an empty result and allow the backend CLI to choose.

### Task 4: Add the hardened prompt and examples

**Files:**
- Create: `prompts/solve-issue.md`
- Create: `examples/AGENTS.example.md`
- Create: `examples/AGENTIC_ISSUE_SOLVER.example.md`

**Step 1: Encode the runbook**

Base the prompt on the hardened issue-solving flow already proven in sibling repositories.

**Step 2: Document target-repo integration**

Show how target repositories should reference this central repository.

### Task 5: Add top-level docs and verify

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

**Step 1: Verify shell scripts**

Run: `bash -n scripts/*.sh`
Expected: PASS

**Step 2: Run the smoke test**

Run: `bash tests/smoke.sh`
Expected: PASS

**Step 3: Commit**

```bash
git add .
git commit -m "feat: bootstrap issue solver repo"
```

