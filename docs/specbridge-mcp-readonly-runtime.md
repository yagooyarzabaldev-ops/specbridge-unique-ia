# SpecBridge Read-Only MCP Runtime

## Overview

SpecBridge ships a bounded local read-only-in-effect MCP-style runtime accessible through the `specbridge-mcp-runtime` CLI command. This runtime serves the three existing operator-state resources through standard MCP read methods and exposes a narrow local tools allowlist without network transport, a server process, mutation capabilities, or dependency installation.

## Command

```powershell
# List available resources
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/list

# Read a specific resource
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/current-goal
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/doctor-fix-plan
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method resources/read -Uri specbridge://operator/orchestration-summaries

# List and call bounded local tools
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method tools/list
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-mcp-runtime -Method tools/call -ToolName specbridge.operator.status
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
| `tools/list` | Returns the local read-only tool allowlist |
| `tools/call` | Calls an allowlisted local read-only tool by `-ToolName` |

Unlisted tools are rejected with `tool_not_allowed` and exit code 1. Mutation-like MCP methods (`resources/write`, `resources/create`, `resources/delete`, `resources/update`, `resources/subscribe`, `sampling/createMessage`, `prompts/get`, etc.) are rejected with `method_not_allowed` and exit code 1.

## Error Responses

All errors are deterministic JSON on stdout with `ok: false`:

| Error | When |
|-------|------|
| `method_not_allowed` | Blocked or mutation-capable method name |
| `method_not_found` | Unrecognised method not in the blocked list |
| `resource_not_found` | `resources/read` with an unknown URI |
| `tool_name_required` | `tools/call` without `-ToolName` |
| `tool_not_allowed` | `tools/call` for a tool outside the local allowlist |

Example rejection:

```json
{
  "command": "specbridge-mcp-runtime",
  "ok": false,
  "error": "method_not_allowed",
  "method": "resources/write",
  "detail": "This method is blocked by the read-only MCP runtime policy.",
  "allowed_methods": ["resources/list", "resources/read", "tools/list", "tools/call"]
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
- Local read-only tool calls only
- No network transport (no HTTP, no WebSocket)
- No long-lived server process
- No mutation-capable or unlisted tools
- No secrets, credentials, or production configuration
- No dependency installation
- No deployment
- No GitHub mutation
- No branch or artifact cleanup enforcement

## Why Cleanup Debt Remains Blocked

Branch cleanup and artifact retention remain policy-only even though the read-only runtime is implemented. Cleanup requires explicit operator authorization through a dedicated future contract. This runtime does not change that boundary.

## MCP Server Status

`specbridge-mcp-resources` reports `mcp_server_status = "readonly_local_runtime"` and a runtime note that includes the bounded local tools allowlist.

## Implementation

The resource runtime is implemented in `scripts/lib/mcp-resources.ps1` via `Invoke-McpRuntimeCommand`. Tool behavior is implemented in `scripts/lib/mcp-tools.ps1`. Resource reads reuse the three existing resource builder functions (`Get-McpCurrentGoalResource`, `Get-McpDoctorFixPlanResource`, `Get-McpOrchestrationSummariesResource`). All data is read from repository-local files with explicit UTF-8 encoding. No external calls are made.
