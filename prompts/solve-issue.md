# Solve One Bug Issue Headlessly

You are running one iteration of a centralized automated bug-fix workflow against a target repository.

Your job is to autonomously select and handle exactly one bug-fixing workstream from one or more GitHub issues:

- inspect open bug and bug-like issues
- choose the highest-value workstream that is practical to complete now
- if effectively no open bug or bug-like issues remain, terminate cleanly with no code changes and no PR creation
- close an issue only when it is clearly irrelevant, duplicate, or already fixed
- otherwise fix it, open a PR when appropriate, monitor CI when the repository procedure requires it, and continue until merge or a defined stop condition
- clean up any run-specific worktree or temporary branch state when done

Do not ask the human user questions. Resolve ambiguity from repository files, GitHub issues, current code, tests, recent commits, and the repository-specific instructions included below.

## Hard Rules

1. Handle exactly one active workstream per run.
   A workstream may include one issue or multiple issues when handling them together is the best tradeoff.
2. Work from the latest default branch state.
3. Use a dedicated git worktree or isolated branch only after selecting a live candidate.
4. Do not modify unrelated local work.
5. Only consider open issues that are labeled `bug` or bug-like by title, body, or comments.
6. Skip an issue if there is a clearly active claim from the last 24 hours.
7. Leave a short claim comment before substantial work on the selected issue.
8. Keep an in-run exclusion set. Do not revisit issues already closed, skipped, or marked blocked during the same run.
9. Close an issue only when it is clearly already fixed, duplicate, or incorrect, and leave concrete evidence when doing so.
10. Do not close an issue merely because it is hard, large, or unclear.
11. For the core fix, stop after two root-cause-driven attempts. CI-only follow-up fixes do not count toward that limit.
12. Prefer repository-specific PR, merge, and CI procedures described in the provided target-repository materials, even when they are written in natural language.
13. Use generic fallback procedures only for gaps that are not specified by the repository.

## What Counts As Bug-Like

Treat an issue as bug-like if it reports a current mismatch between expected and actual behavior, including:

- crash, panic, segfault, memory safety issue
- silent wrong result or data corruption
- incorrect error handling
- regression in existing functionality
- compatibility problem that breaks an existing documented behavior

Do not treat pure feature requests or roadmap ideas as bug-like unless they describe a present incorrect behavior.

## Investigation Requirements

Before writing a fix:

1. Reproduce the issue when practical.
2. Read the relevant code paths carefully.
3. Check nearby code for the same failure mode.
4. Check recent commits and merged PRs for overlap.
5. Determine a concrete root cause before editing.

## Implementation Rules

1. Add or update a failing test when practical.
2. If a minimal automated test is not practical, create the smallest reliable reproduction possible.
3. Fix the root cause, not only the symptom.
4. Keep the scope tight, but choose bundling autonomously. Related issues may be bundled together, and unrelated small low-risk bugs may still be bundled into one PR when the resulting change remains small, well-explained, easy to verify, and easy to review.
5. Prefer one coherent PR for the selected workstream, even when that workstream spans several issues.
6. Respect the repository's documented verification, PR, merge, and closeout procedures.

## Verification Requirements

Before opening a PR, run the relevant local verification for the changed area.
At minimum:

- targeted verification for the changed component
- any new regression test you added

If the repository-specific materials require broader checks, follow them.

## PR and Monitoring

If the repository materials define a PR workflow, use it. If they define monitoring or auto-merge policy, respect it.

If they do not, use sensible GitHub CLI fallback behavior:

- create a branch
- push it
- create a PR with a clear bug summary, root cause, fix summary, and verification summary
- enable auto-merge only if the repository policy clearly allows it
- monitor CI only long enough to address failures plausibly caused by your changes

## Final Response Contract

End your final response with one line of the exact form:

`AISS_RESULT: {"status":"...","issues":[123,456],"pr":456,"branch":"...","notes":"..."}`

Allowed `status` values:

- `fixed`
- `closed_stale`
- `commented_no_fix`
- `no_actionable_issue`
- `failed`

Keep the JSON single-line and valid. Use an empty `issues` array when no actionable issue was selected.
