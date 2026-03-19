# Repository-Specific Issue Solver Instructions

## Issue Selection

- Prefer open issues labeled `bug`
- Skip issues with an active automation claim from the last 24 hours

## Verification

- Run the repository's documented lint and test commands before opening a PR
- Use release-mode tests when the repository asks for them

## PR Procedure

- Follow the repository's documented PR helper if one exists
- If no helper is documented, use a normal GitHub CLI flow

## Monitoring

- Respect the repository's documented CI monitoring procedure when present
- Otherwise inspect failures that are plausibly caused by the current changes

