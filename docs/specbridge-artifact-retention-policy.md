# SpecBridge Artifact Retention Policy

## Overview

The `specbridge-artifact-retention-policy` command produces a deterministic, read-only evaluation of the current artifact inventory against the draft artifact retention policy. It classifies each evidence family into a family class and reports which families would be blocked from any future cleanup, even after policy activation. It does not delete, archive, prune, compress, move, or enforce retention on any artifacts.

**No retention enforcement or artifact cleanup is authorized by this command or by the draft policy.**

## Policy Status

| Field               | Value                     |
|---------------------|---------------------------|
| `status`            | `draft`                   |
| `enforcement`       | `none`                    |
| `cleanup_permission`| `none`                    |

The policy is a draft. No enforcement of any kind is allowed while `status=draft` or `enforcement=none`.

## Usage

```powershell
# Read-only: output to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-artifact-retention-policy

# Write policy evaluation artifact (requires -Force if replacing)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-artifact-retention-policy `
  -OutputPath .specbridge/artifact-retention/current.policy-evaluation.json `
  -Force
```

## Output Shape

```json
{
  "command": "specbridge-artifact-retention-policy",
  "policy_metadata": {
    "policy_id": "artifact-retention-policy",
    "schema_version": 1,
    "status": "draft",
    "enforcement": "none",
    "cleanup_permission": "none"
  },
  "enforcement_status": "none",
  "totals": {
    "total_families": 20,
    "evaluated": 20,
    "blocked_count": 15
  },
  "family_class_counts": [
    { "class": "evidence_derived", "count": 5 },
    { "class": "evidence_ledger", "count": 1 },
    { "class": "evidence_orchestration", "count": 3 },
    { "class": "evidence_primary", "count": 5 },
    { "class": "evidence_runtime", "count": 6 }
  ],
  "blocked_counts": [
    { "class": "evidence_ledger", "count": 1 },
    { "class": "evidence_orchestration", "count": 3 },
    { "class": "evidence_primary", "count": 5 },
    { "class": "evidence_runtime", "count": 6 }
  ],
  "required_future_gates": [
    "policy_status_must_be_active",
    "enforcement_must_not_be_none",
    "explicit_operator_authorization",
    "ci_must_pass",
    "review_gate_must_pass"
  ],
  "family_evaluations": [
    {
      "family_id": "contracts",
      "repository_path": ".specbridge/contracts",
      "family_class": "evidence_primary",
      "file_count": 12,
      "total_bytes": 48320,
      "cleanup_permission": "none",
      "retention_posture": "preserve",
      "future_gate": "blocked"
    }
  ],
  "read_only_note": "This command does not delete, archive, prune, compress, or move any artifacts. No retention enforcement or artifact cleanup is authorized."
}
```

## Artifact Family Classes

| Class ID                | Description                                                                                 | Cleanup Gate         |
|-------------------------|---------------------------------------------------------------------------------------------|----------------------|
| `evidence_primary`      | Core governance: contracts, scopes, reports, audit packets, ChatGPT audits                 | `blocked`            |
| `evidence_runtime`      | Runtime execution evidence: launches, preflights, results, summaries, runs, executions     | `blocked`            |
| `evidence_orchestration`| Multi-agent: orchestrations, executor packets, GitHub evidence                             | `blocked`            |
| `evidence_ledger`       | Operational ledger                                                                         | `blocked`            |
| `evidence_derived`      | Derived/index artifacts: MCP resources, inventories, policy evaluations                    | `activation_required`|

## Cleanup Gate Meanings

- `blocked`: This family may not be cleaned up even after policy activation. These artifacts are governance evidence that must be preserved.
- `activation_required`: This family may only be considered for cleanup after the policy is activated with `status=active`, `enforcement` set to a defined mode, and all required gates pass. Derived artifacts in this class can be regenerated from the repository state.

## Blocked Actions

Regardless of policy status, the following are permanently blocked by this policy:

- Deleting any artifact
- Moving any artifact
- Compressing any artifact
- Pruning any artifact
- Archiving any artifact
- Uploading any artifact
- Enforcing retention on any artifact
- Applying cleanup to any artifact
- Making network calls from the artifact retention policy command

## Future Activation Path

To activate this policy for any future retention work, **all** of the following gates must pass:

1. `policy_status_must_be_active` — the policy JSON `status` field must be changed from `draft` to `active`
2. `enforcement_must_not_be_none` — the `enforcement` field must be changed from `none` to a defined enforcement mode
3. `explicit_operator_authorization` — an explicit operator authorization must be recorded in the operator decision registry
4. `ci_must_pass` — CI must pass with the active policy in force
5. `review_gate_must_pass` — the review gate must pass before any cleanup action is taken

**None of these gates are currently open.** No retention action of any kind is authorized in the current draft state.

## Parameters

| Parameter     | Required | Description                                                                                          |
|---------------|----------|------------------------------------------------------------------------------------------------------|
| `-OutputPath` | No       | If provided, must be `.specbridge/artifact-retention/current.policy-evaluation.json`.                |
| `-Force`      | No       | Required when `-OutputPath` targets an existing file.                                                |

## Safety Guarantees

- **Read-only by default.** When `-OutputPath` is omitted the command writes nothing to disk.
- **No retention enforcement.** The command never deletes, archives, prunes, compresses, or moves artifacts.
- **No network calls.** The command is entirely local.
- **Deterministic.** Given the same repository state, the command produces the same output.
- **cleanup_permission=none for every family.** No family evaluation grants cleanup permission.
- **Explicit write boundary.** The only file the command may write is `.specbridge/artifact-retention/current.policy-evaluation.json`.
