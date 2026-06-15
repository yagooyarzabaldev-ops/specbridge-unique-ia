# SpecBridge Artifact Inventory

## Overview

The `specbridge-artifact-inventory` command produces a deterministic, read-only inventory of the main `.specbridge/` evidence families. It reports file counts, byte sizes, and the latest modification timestamp for each family. Its `generated_at` value is the latest observed evidence timestamp, not the wall-clock time of command execution. It does not delete, archive, prune, compress, or move any artifacts.

## Usage

```powershell
# Read-only: output to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-artifact-inventory

# Write inventory artifact (requires -Force if replacing)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-artifact-inventory `
  -OutputPath .specbridge/artifact-inventory/current.inventory.json `
  -Force
```

## Output Shape

```json
{
  "command": "specbridge-artifact-inventory",
  "generated_at": "<latest observed evidence ISO-8601 timestamp>",
  "families": [
    {
      "family_id": "contracts",
      "repository_path": ".specbridge/contracts",
      "file_count": 12,
      "total_bytes": 48320,
      "latest_modified": "<ISO-8601 timestamp or null>",
      "retention_posture": "preserve",
      "cleanup_permission": "none"
    }
  ],
  "totals": {
    "family_count": 20,
    "total_file_count": 120,
    "total_bytes": 512000
  },
  "retention_enforcement": "none",
  "read_only_note": "This command does not delete, archive, prune, compress, or move any artifacts."
}
```

## Family IDs

| Family ID            | Repository Path                       |
|----------------------|---------------------------------------|
| contracts            | .specbridge/contracts                 |
| scopes               | .specbridge/scopes                    |
| reports              | .specbridge/reports                   |
| audit_packets        | .specbridge/audit-packets             |
| chatgpt_audits       | .specbridge/audits                    |
| runtime_launches     | .specbridge/runtime-launches          |
| runtime_preflights   | .specbridge/preflights                |
| runtime_results      | .specbridge/runtime-results           |
| runtime_summaries    | .specbridge/runtime-summaries         |
| runtime_runs         | .specbridge/runtime-runs              |
| runtime_executions   | .specbridge/runtime-executions        |
| orchestrations       | .specbridge/orchestrations            |
| executor_packets     | .specbridge/executor-packets          |
| github_evidence      | .specbridge/github-evidence           |
| ledger               | .specbridge/ledger                    |
| mcp_resources        | .specbridge/mcp-resources             |
| artifact_inventory   | .specbridge/artifact-inventory        |
| branch_inventory     | .specbridge/branch-inventory          |
| branch_cleanup_policy | .specbridge/branch-cleanup            |
| artifact_retention_policy | .specbridge/artifact-retention    |

## Parameters

| Parameter     | Required | Description                                                                         |
|---------------|----------|-------------------------------------------------------------------------------------|
| `-OutputPath` | No       | If provided, must be `.specbridge/artifact-inventory/current.inventory.json`.       |
| `-Force`      | No       | Required when `-OutputPath` targets an existing file.                               |

## Safety Guarantees

- **Read-only by default.** When `-OutputPath` is omitted the command writes nothing to disk.
- **No retention enforcement.** The command never deletes, archives, prunes, compresses, or moves artifacts.
- **Deterministic.** Given the same repository state, the command produces the same output.
- **Explicit write boundary.** The only file the command may write is `.specbridge/artifact-inventory/current.inventory.json`.
