# SpecBridge Branch Cleanup Policy

## Overview

The `specbridge-branch-cleanup-policy` command produces a deterministic, read-only evaluation of local branch refs against the governed branch cleanup policy draft. It classifies each branch into a candidate class and reports policy metadata, totals, candidate counts, blocked counts, required future gates, enforcement status, and per-branch evaluations.

**No branch cleanup is authorized.** Every branch entry carries `cleanup_permission=none`. The policy status is `draft` and enforcement is `none`. Branch deletion, pruning, renaming, movement, archival, fetch, pull, force-push, and retention enforcement remain blocked.

## Usage

```powershell
# Read-only: output to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-branch-cleanup-policy

# Write policy evaluation artifact (requires -Force if replacing)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-branch-cleanup-policy `
  -OutputPath .specbridge/branch-cleanup/current.policy-evaluation.json `
  -Force
```

## Output Shape

```json
{
  "command": "specbridge-branch-cleanup-policy",
  "ok": true,
  "evaluation": {
    "command": "specbridge-branch-cleanup-policy",
    "policy_metadata": {
      "policy_id": "branch-cleanup-policy",
      "schema_version": 1,
      "status": "draft",
      "enforcement": "none",
      "cleanup_permission": "none"
    },
    "enforcement_status": "none",
    "totals": {
      "total_refs": 12,
      "evaluated": 12,
      "blocked_count": 8
    },
    "candidate_counts": [
      { "class": "merged_local", "count": 2 },
      { "class": "unmerged_origin", "count": 8 }
    ],
    "blocked_counts": [
      { "class": "unmerged_origin", "count": 8 }
    ],
    "required_future_gates": [
      "policy_status_must_be_active",
      "enforcement_must_not_be_none",
      "explicit_operator_authorization",
      "ci_must_pass",
      "review_gate_must_pass"
    ],
    "branch_evaluations": [
      {
        "ref_name": "refs/heads/main",
        "branch_name": "main",
        "ref_type": "local",
        "candidate_class": "unmerged_local",
        "cleanup_permission": "none",
        "future_gate": "blocked"
      }
    ],
    "read_only_note": "This command does not delete, prune, rename, move, archive, fetch, pull, or force-push branches. No cleanup is authorized."
  }
}
```

## Candidate Classes

| Class ID             | Description                                          | Future Gate          |
|----------------------|------------------------------------------------------|----------------------|
| merged_local         | Local branches merged into main                      | activation_required  |
| merged_origin        | Origin branches merged into main                     | activation_required  |
| unmerged_local       | Local branches not yet merged into main              | blocked              |
| unmerged_origin      | Origin branches not yet merged into main             | blocked              |
| unknown_merge_status | Branches with unknown merge status relative to main  | blocked              |

Only `merged_local` and `merged_origin` classes carry `future_gate=activation_required`. All others are `blocked` regardless of policy activation.

## Policy Draft Location

The policy draft is read from `.specbridge/policies/branch-cleanup-policy.draft.json`. The draft defines candidate classes, hard blocks, required gates, future activation requirements, blocked commands, and blocked actions.

## Blocked Actions

The following are permanently blocked by the policy draft and may not be implemented without a dedicated execution contract that explicitly overrides them:

- `branch_deletion`
- `branch_pruning`
- `remote_pruning`
- `branch_rename`
- `branch_movement`
- `branch_archival`
- `retention_enforcement`
- `cleanup_apply_mode`

## Blocked Commands

The following git commands are blocked:

- `git branch -d`
- `git branch -D`
- `git push --delete`
- `git remote prune`
- `git fetch --prune`
- `git push --force`
- `git push -f`

## Future Activation Path

To activate branch cleanup in a future governed task:

1. Create a dedicated execution contract with explicit branch mutation authorization.
2. Change policy status from `draft` to `active` via the governed contract.
3. Change enforcement from `none` to one of: `local_only`, `origin_only`, `all`.
4. Change cleanup_permission from `none` to `allowed` via the contract.
5. Pass CI and review gates before any activation.
6. Hard blocks remain enforced unless individually overridden by the contract.

## Parameters

| Parameter     | Required | Description                                                                                    |
|---------------|----------|------------------------------------------------------------------------------------------------|
| `-OutputPath` | No       | If provided, must be `.specbridge/branch-cleanup/current.policy-evaluation.json`.             |
| `-Force`      | No       | Required when `-OutputPath` targets an existing file.                                          |

## Safety Guarantees

- **Read-only by default.** When `-OutputPath` is omitted the command writes nothing to disk.
- **No branch mutation.** The command never deletes, prunes, renames, moves, archives, fetches, pulls, or force-pushes branches.
- **No retention enforcement.** The command never enforces any retention policy.
- **Deterministic.** Given the same repository state, the command produces the same output.
- **Explicit write boundary.** The only file the command may write is `.specbridge/branch-cleanup/current.policy-evaluation.json`.
- **cleanup_permission=none.** Every branch evaluation entry carries `cleanup_permission=none` regardless of candidate class.
