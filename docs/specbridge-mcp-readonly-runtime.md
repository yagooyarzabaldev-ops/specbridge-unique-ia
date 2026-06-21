# SpecBridge Read-Only MCP Runtime

## Overview

SpecBridge ships a bounded local read-only MCP-style runtime accessible through the `specbridge-mcp-runtime` CLI command. This runtime serves the three existing operator-state resources through standard MCP read methods without network transport, a server process, mutation capabilities, or dependency installation.

## Command

```powershell
# List available resources
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/list

# Read a specific resource
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/current-goal
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/doctor-fix-plan
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/orchestration-summaries
```

## Available Resources

| URI | Description |
|-----|-------------|
| `specbridge://operator/current-goal` | Machine-readable current operator goal and task status |
| `specbridge://operator/doctor-fix-plan` | Offline doctor fix-plan: detected drift, severity, repair commands |
| `specbridge://operator/orchestration-summaries` | Summarized orchestration manifests: task_id, status, run_id, created_at |

## Supported Methods

| Method | Behaviour |
|--------|-----------|
| `resources/list` | Returns all three resource descriptors (uri, name, description, mimeType) |
| `resources/read` | Returns the resource content for a known URI as a `contents` array |

All other MCP methods (`tools/call`, `resources/write`, `resources/create`, `resources/delete`, `resources/update`, `resources/subscribe`, `sampling/createMessage`, `prompts/get`, etc.) are rejected with `method_not_allowed` and exit code 1.

## Error Responses

All errors are deterministic JSON on stdout with `ok: false`:

| Error | When |
|-------|------|
| `method_not_allowed` | Blocked or mutation-capable method name |
| `method_not_found` | Unrecognised method not in the blocked list |
| `resource_not_found` | `resources/read` with an unknown URI |

Example rejection:

```json
{
  "command": "specbridge-mcp-runtime",
  "ok": false,
  "error": "method_not_allowed",
  "method": "tools/call",
  "detail": "This method is blocked by the read-only MCP runtime policy.",
  "allowed_methods": ["resources/list", "resources/read"]
}
```

## resources/list output format

```json
{
  "command": "specbridge-mcp-runtime",
  "ok": true,
  "method": "resources/list",
  "result": {
    "resources": [
      {
        "uri": "specbridge://operator/current-goal",
        "name": "specbridge://operator/current-goal",
        "description": "...",
        "mimeType": "application/json"
      }
    ]
  }
}
```

## resources/read output format

```json
{
  "command": "specbridge-mcp-runtime",
  "ok": true,
  "method": "resources/read",
  "uri": "specbridge://operator/current-goal",
  "result": {
    "contents": [
      {
        "uri": "specbridge://operator/current-goal",
        "mimeType": "application/json",
        "text": "{...}"
      }
    ]
  }
}
```

## Policy Boundaries

This runtime is bounded to:

- Local read-only access to repository files only
- No network transport (no HTTP, no WebSocket)
- No long-lived server process
- No mutation-capable tools
- No secrets, credentials, or production configuration
- No dependency installation
- No deployment
- No GitHub mutation
- No branch or artifact cleanup enforcement

## Why Cleanup Debt Remains Blocked

Branch cleanup and artifact retention remain policy-only even though the read-only runtime is implemented. Cleanup requires explicit operator authorization through a dedicated future contract. This runtime does not change that boundary.

## MCP Server Status

`specbridge-mcp-resources` now reports `mcp_server_status = "readonly_local_runtime"` instead of `"not_implemented"` to reflect that this bounded runtime is available.

## Implementation

The runtime is implemented in `scripts/lib/mcp-resources.ps1` via `Invoke-McpRuntimeCommand`. It reuses the three existing resource builder functions (`Get-McpCurrentGoalResource`, `Get-McpDoctorFixPlanResource`, `Get-McpOrchestrationSummariesResource`) from the same library. All data is read from repository-local files with explicit UTF-8 encoding. No external calls are made.
