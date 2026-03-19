#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
skill_root="$(cd -- "$script_dir/.." && pwd -P)"
repo_root="$(cd -- "$script_dir/../../.." && pwd -P)"

if ! git -C "$repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
  printf 'status=detached-copy\n'
  printf 'repo_root=%s\n' "$repo_root"
  printf 'message=skill is not running from a git checkout\n'
  exit 0
fi

repo_top="$(git -C "$repo_root" rev-parse --show-toplevel)"
local_hash="$(git -C "$repo_top" rev-parse HEAD)"

printf 'status=ok\n'
printf 'repo_root=%s\n' "$repo_top"
printf 'skill_root=%s\n' "$skill_root"
printf 'local_hash=%s\n' "$local_hash"
printf 'update_command=git -C %s pull --ff-only\n' "$repo_top"

remote_hash="$(git -C "$repo_top" ls-remote origin refs/heads/main 2>/dev/null | awk 'NR==1 {print $1}')"
if [[ -z "$remote_hash" ]]; then
  printf 'remote_status=unavailable\n'
  exit 0
fi

printf 'remote_status=ok\n'
printf 'remote_hash=%s\n' "$remote_hash"
if [[ "$remote_hash" != "$local_hash" ]]; then
  printf 'status=update-available\n'
fi

