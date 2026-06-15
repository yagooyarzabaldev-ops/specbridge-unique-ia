# SpecBridge MCP Resource Exports

## Overview

SpecBridge exposes read-only operator state as a deterministic, repository-backed MCP resource catalog. The `specbridge-mcp-resources` CLI command emits this catalog to stdout or optionally writes it to a governed artifact path.

No live MCP server runtime is implemented. This is a local, file-backed export surface only.

## Command

```powershell
# Emit catalog to stdout (no disk write)
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-resources

# Write catalog to repository artifact
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-resources -OutputPath .specbridge/mcp-resources/operator-state.catalog.json
```

## Exported Resources

| Name | URI | Source |
|------|-----|--------|
| Current Goal | `specbridge://operator/current-goal` | `.specbridge/state/current-goal.json` |
| Doctor Fix-Plan | `specbridge://operator/doctor-fix-plan` | `specbridge-doctor -FixPlan -Offline` over local governance state |
| Orchestration Summaries | `specbridge://operator/orchestration-summaries` | `.specbridge/orchestrations/*.orchestration.json` |

Each resource entry includes:

- `name` — canonical resource identifier
- `uri` — MCP URI pattern
- `content_type` — always `application/json`
- `source_paths` — repository-relative paths the data is read from
- `refresh_behavior` — `on_demand` (generated fresh each CLI invocation)
- `sensitivity` — `internal`
- `read_only` — `true`
- `description` — human-readable summary
- `data` — the parsed source content or generated offline summary for the resource

## MCP Server Status

```
not_implemented
```

No live MCP server runtime exists. This command is the first step toward a governed MCP resource surface. A future dedicated contract is required before any server runtime is introduced.

## Output Path Behavior

When `-OutputPath` is omitted the command writes only to stdout and makes no disk changes.

When `-OutputPath .specbridge/mcp-resources/operator-state.catalog.json` is supplied the catalog is written to that repository-relative path using UTF-8 without BOM. This exact governed artifact path is required. If the file already exists, pass `-Force` to replace it.

## Security

- No secrets, credentials, or production configuration are included in any resource.
- The command is read-only with respect to all SpecBridge source state files.
- Catalog artifact is governed by the `exclusive_write` scope in the active execution contract.

## Resource Contract

See `.specbridge/mcp/specbridge-operator-state-resources.md` for the full resource contract with schema, safety boundaries, and limitations.
