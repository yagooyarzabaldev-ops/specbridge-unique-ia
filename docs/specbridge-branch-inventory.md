# SpecBridge Branch Inventory

## Overview

The `specbridge-branch-inventory` command produces a deterministic, read-only inventory of local branch refs and local `origin/*` remote-tracking refs. It is an observability surface for branch debt before any future cleanup policy exists.

The command does not delete, prune, rename, move, archive, fetch, pull, or force-push branches.

## Usage

```powershell
# Read-only: output to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-branch-inventory

# Write inventory artifact (requires -Force if replacing)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-branch-inventory `
  -OutputPath .specbridge/branch-inventory/current.inventory.json `
  -Force
```

## Output Shape

```json
{
  "command": "specbridge-branch-inventory",
  "generated_at": "<latest observed branch commit timestamp>",
  "base_ref": "refs/remotes/origin/main",
  "current_branch": "codex/issue-212-branch-inventory-status",
  "branches": [
    {
      "ref_name": "refs/heads/main",
      "branch_name": "main",
      "ref_type": "local",
      "object_id": "<commit sha>",
      "latest_commit_at": "<ISO-8601 commit timestamp>",
      "prefix": "main",
      "merged_into_main": true,
      "retention_posture": "preserve",
      "cleanup_permission": "none"
    }
  ],
  "totals": {
    "total_refs": 1,
    "local_branch_count": 1,
    "origin_branch_count": 0,
    "merged_into_main_count": 1,
    "unmerged_into_main_count": 0,
    "unknown_merge_status_count": 0
  },
  "prefix_counts": [
    {
      "prefix": "main",
      "count": 1
    }
  ],
  "branch_mutation_policy": "none",
  "read_only_note": "This command does not delete, prune, rename, move, archive, fetch, pull, or force-push branches."
}
```

## Fields

| Field | Description |
|-------|-------------|
| `generated_at` | Latest observed commit timestamp across inventoried refs. This is not wall-clock time. |
| `base_ref` | `refs/remotes/origin/main` when present, otherwise `refs/heads/main` when present, otherwise `null`. |
| `current_branch` | Current checked-out local branch reported by Git. |
| `branches` | Local and local `origin/*` remote-tracking refs discovered from the local repository. |
| `prefix_counts` | Counts grouped by the first path segment of each branch name. |
| `branch_mutation_policy` | Always `none` for this issue. |

## Branch Entry Fields

| Field | Description |
|-------|-------------|
| `ref_name` | Full Git ref name. |
| `branch_name` | Short branch name without `refs/heads/` or `refs/remotes/origin/`. |
| `ref_type` | `local` or `origin`. |
| `object_id` | Commit object id pointed to by the ref. |
| `latest_commit_at` | Committer timestamp for the ref target. |
| `prefix` | First slash-delimited branch-name segment. |
| `merged_into_main` | `true`, `false`, or `null` when merge status cannot be determined locally. |
| `retention_posture` | Always `preserve`. |
| `cleanup_permission` | Always `none`. |

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-OutputPath` | No | If provided, must be `.specbridge/branch-inventory/current.inventory.json`. |
| `-Force` | No | Required when `-OutputPath` targets an existing file. |

## Safety Guarantees

- **Read-only by default.** When `-OutputPath` is omitted the command writes nothing to disk.
- **Local refs only.** The command reads local Git refs and local `origin/*` remote-tracking refs; it does not call `git fetch` or `git pull`.
- **No branch cleanup.** The command never deletes, prunes, renames, moves, archives, or force-pushes branches.
- **Deterministic.** Given the same local ref state, the command produces the same output.
- **Explicit write boundary.** The only file the command may write is `.specbridge/branch-inventory/current.inventory.json`.
