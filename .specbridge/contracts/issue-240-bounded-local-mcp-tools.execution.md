# Execution Contract: Issue 240 Bounded Local MCP Tools Runtime

## Contract Metadata

- contract_id: issue-240-bounded-local-mcp-tools
- run_id: sb-20260622-0240a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/240
- created_by: ChatGPT/Codex with Claude Code implementation assistance
- created_at: 2026-06-22
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Extend the local SpecBridge MCP runtime with a bounded tools surface while preserving the existing local-only, deterministic, no-secret, no-network, no-deployment operating boundary.

## Context

Issue #234 completed the read-only MCP runtime for `resources/list` and `resources/read`. The next safe standardization step is to expose `tools/list` and `tools/call` for a deliberately small allowlist of local helper tools.

This contract authorizes only read-only local tool behavior. It does not authorize network MCP transport, hosted MCP server deployment, GitHub mutation through MCP, external resource mutation, cleanup enforcement, dependency installation, or any protected production/security/billing/authentication scope.

## Source References

- `README.md` - product status and current runtime posture.
- `SPECBRIDGE.md` - technical contract, stop conditions, and MCP governance.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active policy and blocked paths.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next recommended task.
- `docs/specbridge-mcp-readonly-runtime.md` - current local MCP runtime boundary.
- `docs/mcp-integration-contract.md` - MCP integration contract standard.
- `scripts/specbridge.ps1` - CLI routing and parameter surface.
- `scripts/lib/mcp-resources.ps1` - existing resources runtime.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task changes a local runtime command surface and adds a new allowlisted tool call path, but it remains deterministic, repository-local, read-only in effect, and explicitly blocks network transport, hosted deployment, GitHub/resource mutation, secrets, production, billing, auth/security, CI/CD security, dependency installation, and cleanup enforcement.

## Allowed Scope

```text
.specbridge/contracts/issue-240-bounded-local-mcp-tools.execution.md
.specbridge/scopes/issue-240-bounded-local-mcp-tools.scope.json
.specbridge/reports/issue-240-bounded-local-mcp-tools.final-report.json
.specbridge/audit-packets/issue-240-bounded-local-mcp-tools.audit-packet.json
.specbridge/audits/issue-240-bounded-local-mcp-tools.chatgpt-audit.json
.specbridge/github-evidence/issue-240-bounded-local-mcp-tools.closure.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/standard-readiness/current.status.json
README.md
docs/specbridge-mcp-bounded-tools.md
docs/specbridge-mcp-readonly-runtime.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/mcp-resources.ps1
scripts/lib/mcp-tools.ps1
scripts/test-specbridge-cli.ps1
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
.mcp.json
.mcp.*.json
dependency installation
package manager files
real billing configuration
provider account configuration
API key or token storage
secret access
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
network MCP transport
hosted MCP server deployment
GitHub mutation from MCP tools
external resource mutation from MCP tools
branch deletion
branch pruning
branch renaming
branch movement
branch archival
artifact deletion
artifact movement
artifact compression
artifact archival
artifact upload
cleanup apply mode
retention enforcement
issue #194 lifecycle changes
digital twin implementation
unbounded Claude Code token spending
```

## Acceptance Criteria

1. `specbridge-mcp-runtime -Method tools/list` returns deterministic JSON with a bounded local tool allowlist.
2. `specbridge-mcp-runtime -Method tools/call -ToolName specbridge.operator.status` returns deterministic JSON with a read-only local operator status summary.
3. `specbridge-mcp-runtime -Method tools/call` with an unlisted tool returns deterministic JSON with `tool_not_allowed` and performs no mutation.
4. `resources/list` and `resources/read` behavior remains compatible with issue #234.
5. Mutation-like methods such as `resources/write` remain blocked.
6. CLI regression tests cover list, allowed call, blocked call, and resources regression.
7. Documentation explains the bounded tools runtime and blocked boundaries.
8. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
9. Required local validations and GitHub Actions pass before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, provider tokens, private keys, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, network MCP transport, hosted MCP server deployment, GitHub/resource mutation through MCP tools, branch/artifact cleanup enforcement, changing issue #194 lifecycle, implementing the digital twin, or unbounded Claude Code token spending.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must keep execution bounded, local, and non-interactive. Claude must not commit, push, open pull requests, call networks, install dependencies, access secrets, or touch blocked scope.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-240-bounded-local-mcp-tools.final-report.json`, `.specbridge/audit-packets/issue-240-bounded-local-mcp-tools.audit-packet.json`, and `.specbridge/audits/issue-240-bounded-local-mcp-tools.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when bounded local MCP tools are implemented, required local validations pass, GitHub checks pass, PR closes issue #240, and post-merge closure evidence is recorded.
