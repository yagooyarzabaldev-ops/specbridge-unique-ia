# SpecBridge MCP Bounded Tools Runtime

Issue #240 extends the local MCP-style runtime with a bounded tools surface.

The runtime remains local-only and read-only in effect. It does not start a network transport, hosted server, GitHub mutation path, external resource mutation path, secret reader, billing integration, auth system, deployment workflow, branch cleanup, or artifact retention enforcement.

## Commands

List available tools:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\specbridge.ps1 specbridge-mcp-runtime -Method tools/list
```

Call the allowed local status tool:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\specbridge.ps1 specbridge-mcp-runtime -Method tools/call -ToolName specbridge.operator.status
```

The allowed tool returns a JSON content item containing:

- current goal status
- last completed task
- offline doctor health
- readiness next action
- eligible and excluded task counts

The tool writes no files and performs no external calls.

## Allowlist

The initial allowlist contains one local helper:

```text
specbridge.operator.status
```

Any other `tools/call` request returns deterministic JSON with `tool_not_allowed` and exits nonzero.

Calling `tools/call` without `-ToolName` returns deterministic JSON with `tool_name_required` and exits nonzero.

## Still Blocked

The following remain blocked:

- network MCP transport
- hosted MCP server deployment
- GitHub mutation from MCP tools
- external resource mutation from MCP tools
- secrets and credential access
- billing or payment provider configuration
- authentication or authorization changes
- CI/CD security or workflow changes
- production configuration
- destructive filesystem operations
- branch cleanup enforcement
- artifact retention enforcement
- issue #194 lifecycle changes

Future tools must receive a dedicated execution contract, explicit allowlist entry, tests, review evidence, and CI evidence before they can be enabled.
