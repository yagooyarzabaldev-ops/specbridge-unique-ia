# SpecBridge Repository Health Summary

## Overview

The `specbridge-repository-health-summary` command produces a deterministic,
read-only summary that aggregates four existing local evidence builders:

- `specbridge-branch-inventory` (`scripts/lib/branch-inventory.ps1`)
- `specbridge-branch-cleanup-policy` (`scripts/lib/branch-cleanup-policy.ps1`)
- `specbridge-artifact-inventory` (`scripts/lib/artifact-inventory.ps1`)
- `specbridge-artifact-retention-policy` (`scripts/lib/artifact-retention-policy.ps1`)

It gives operators one place to check branch debt, artifact growth, and
policy posture before deciding whether to pursue future governed branch
cleanup or artifact retention activation work. It performs no network
calls, branch mutations, artifact mutations, cleanup apply mode, or
retention enforcement.

## Usage

```powershell
# Read-only: output to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-repository-health-summary

# Write summary artifact (requires -Force if replacing)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-repository-health-summary `
  -OutputPath .specbridge/repository-health/current.summary.json `
  -Force
```

## Output Shape

```json
{
  "command": "specbridge-repository-health-summary",
  "generated_at": "<latest observed evidence ISO-8601 timestamp>",
  "overall_health_posture": "debt_present_cleanup_blocked",
  "branch_posture": {
    "total_refs": 0,
    "local_branch_count": 0,
    "origin_branch_count": 0,
    "merged_into_main_count": 0,
    "unmerged_into_main_count": 0,
    "unknown_merge_status_count": 0,
    "branch_mutation_policy": "none"
  },
  "artifact_posture": {
    "family_count": 0,
    "total_file_count": 0,
    "total_bytes": 0,
    "retention_enforcement": "none"
  },
  "policy_posture": {
    "branch_cleanup_policy": {
      "policy_id": "branch-cleanup-policy",
      "status": "draft",
      "enforcement": "none",
      "cleanup_permission": "none"
    },
    "artifact_retention_policy": {
      "policy_id": "artifact-retention-policy",
      "status": "draft",
      "enforcement": "none",
      "cleanup_permission": "none"
    }
  },
  "cleanup_permission": "none",
  "enforcement_status": "none",
  "blocked_action_counts": {
    "branch_cleanup_blocked": 0,
    "artifact_retention_blocked": 0,
    "total_blocked": 0
  },
  "required_future_gates": ["..."],
  "evidence_sources": [
    { "evidence_id": "branch_inventory", "source_path": "scripts/lib/branch-inventory.ps1" },
    { "evidence_id": "branch_cleanup_policy", "source_path": "scripts/lib/branch-cleanup-policy.ps1" },
    { "evidence_id": "artifact_inventory", "source_path": "scripts/lib/artifact-inventory.ps1" },
    { "evidence_id": "artifact_retention_policy", "source_path": "scripts/lib/artifact-retention-policy.ps1" }
  ],
  "non_enforcement_note": "...",
  "read_only_note": "..."
}
```

## Fields

| Field                     | Description                                                                                          |
|---------------------------|--------------------------------------------------------------------------------------------------------|
| `overall_health_posture`  | `stable_no_debt` when no blocked cleanup/retention candidates exist, otherwise `debt_present_cleanup_blocked`. |
| `branch_posture`          | Aggregated counts from `specbridge-branch-inventory`.                                                  |
| `artifact_posture`        | Aggregated counts from `specbridge-artifact-inventory`.                                                 |
| `policy_posture`          | Policy metadata (status, enforcement, cleanup_permission) from both policy evaluators.                  |
| `cleanup_permission`      | Always `none`. No cleanup is authorized by this command.                                                |
| `enforcement_status`      | Always `none`. No retention enforcement is authorized by this command.                                  |
| `blocked_action_counts`   | Counts of blocked branch cleanup and artifact retention candidates, plus their sum.                     |
| `required_future_gates`   | Union of the gates required before either policy may move from draft/none to active enforcement.        |
| `evidence_sources`        | Repository-relative source paths for the four evidence builders this command aggregates.                |
| `non_enforcement_note`    | Explicit statement that no enforcement is enabled regardless of detected debt.                          |
| `read_only_note`          | Explicit statement of all the mutating actions this command never performs.                             |

## Parameters

| Parameter     | Required | Description                                                                              |
|---------------|----------|-------------------------------------------------------------------------------------------|
| `-OutputPath` | No       | If provided, must be `.specbridge/repository-health/current.summary.json`.                |
| `-Force`      | No       | Required when `-OutputPath` targets an existing file.                                     |

## Safety Guarantees

- **Read-only by default.** When `-OutputPath` is omitted the command writes nothing to disk.
- **No cleanup or enforcement.** `cleanup_permission` and `enforcement_status` are always `none`, regardless of detected branch or artifact debt.
- **Deterministic.** Given the same repository state, the command produces the same output.
- **Explicit write boundary.** The only file the command may write is `.specbridge/repository-health/current.summary.json`.
- **No network calls.** The command only reads local evidence builders; it never fetches, pulls, or contacts GitHub.

## Future Activation Path

Branch cleanup and artifact retention enforcement remain blocked until a
dedicated policy and execution contract explicitly authorize them. This
summary command exists to make the current debt and policy posture visible
to operators; it does not itself unlock cleanup or enforcement.
