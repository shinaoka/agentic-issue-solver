# Workstream Bundling Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let one solver run decide autonomously whether to bundle multiple small issues into a single PR, even when those issues are unrelated.

**Architecture:** Keep the existing single-run model, but redefine a workstream as one or more issues selected by the agent. Update the prompt, skill, and public docs so bundling is driven by size, risk, and reviewability rather than by shared root cause alone.

**Tech Stack:** Markdown, Bash smoke tests

---

### Task 1: Add the failing smoke assertions

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Assert the new bundling policy text**

Check that the prompt and installed skill mention:
- one workstream may include multiple issues
- unrelated small low-risk bugs may be bundled
- final result uses an `issues` array

**Step 2: Run smoke to verify it fails**

Run: `bash tests/smoke.sh`
Expected: FAIL because the current text still assumes one issue per run.

### Task 2: Update the prompt contract

**Files:**
- Modify: `prompts/solve-issue.md`

**Step 1: Redefine workstream**

State that a workstream may contain one or more issues, selected autonomously by the agent.

**Step 2: Relax bundling criteria**

Allow unrelated small bugs to be bundled when the resulting PR remains small, low-risk, and reviewable.

**Step 3: Update final result schema**

Use `issues` instead of `issue` so multi-issue runs are representable.

### Task 3: Update skill and docs

**Files:**
- Modify: `skills/agentic-issue-solver/SKILL.md`
- Modify: `README.md`

**Step 1: Align the skill wording**

Describe one run as one workstream, not one issue.

**Step 2: Align the user-facing docs**

Document that the solver may choose one PR for several small issues.

### Task 4: Verify and publish

**Files:**
- Modify: `tests/smoke.sh`

**Step 1: Run smoke**

Run: `bash tests/smoke.sh`
Expected: PASS

**Step 2: Run syntax checks**

Run: `bash -n scripts/*.sh skills/agentic-issue-solver/scripts/*.sh`
Expected: PASS

**Step 3: Commit**

```bash
git add prompts/solve-issue.md skills/agentic-issue-solver/SKILL.md README.md tests/smoke.sh docs/plans/2026-03-19-workstream-bundling.md
git commit -m "feat: allow autonomous issue bundling"
```

