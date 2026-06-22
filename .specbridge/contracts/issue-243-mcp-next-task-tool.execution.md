# Execution Contract: Issue 243 MCP Next Task Tool

## Contract Metadata

- contract_id: issue-243-mcp-next-task-tool
- run_id: sb-20260622-0243a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/243
- created_by: ChatGPT/Codex with Claude Code implementation assistance
- created_at: 2026-06-22
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Add a second bounded local MCP tool named `specbridge.next-task` that exposes the full existing next-task selector snapshot without adding network transport, hosted MCP deployment, GitHub mutation, external resource mutation, secrets, cleanup enforcement, or deployment behavior.

## Context

Issue #240 added the local MCP tools surface and the first allowlisted tool, `specbridge.operator.status`. That status tool reports next-task counts, but not the actual eligible tasks or excluded issue reasons. This contract authorizes a narrow read-only wrapper around the already existing `Get-StandardReadinessNextTaskSnapshot` helper so MCP consumers can inspect the same next-task decision currently available through `specbridge-next-task`.

## Source References

- `README.md` - product status and current runtime posture.
- `SPECBRIDGE.md` - technical contract, stop conditions, and MCP governance.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active policy and blocked paths.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next recommended task.
- `docs/specbridge-mcp-bounded-tools.md` - bounded MCP tools runtime documentation.
- `docs/specbridge-mcp-readonly-runtime.md` - local MCP runtime boundary.
- `scripts/specbridge.ps1` - CLI routing and parameter surface.
- `scripts/lib/mcp-tools.ps1` - bounded MCP tools allowlist and call handlers.
- `scripts/lib/standard-readiness.ps1` - next-task selector snapshot helper.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Low. The change exposes existing local read-only selector data through the existing bounded MCP tools surface. It does not introduce new data sources, external calls, writes, mutation authority, dependencies, or production behavior.

## Allowed Scope

```text
.specbridge/contracts/issue-243-mcp-next-task-tool.execution.md
.specbridge/scopes/issue-243-mcp-next-task-tool.scope.json
.specbridge/reports/issue-243-mcp-next-task-tool.final-report.json
.specbridge/audit-packets/issue-243-mcp-next-task-tool.audit-packet.json
.specbridge/audits/issue-243-mcp-next-task-tool.chatgpt-audit.json
.specbridge/github-evidence/issue-243-mcp-next-task-tool.closure.json
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

1. `specbridge-mcp-runtime -Method tools/list` returns deterministic JSON containing exactly the bounded local tool allowlist, including `specbridge.operator.status` and `specbridge.next-task`.
2. `specbridge-mcp-runtime -Method tools/call -ToolName specbridge.next-task` returns `ok: true` with a text content item containing valid JSON.
3. The `specbridge.next-task` JSON includes `current_goal_status`, `current_task_id`, `eligible_tasks`, `excluded_issues`, and `recommended_action`.
4. The new tool writes no files and performs no external calls.
5. Unknown tools remain blocked with `tool_not_allowed`.
6. Missing tool names remain blocked with `tool_name_required`.
7. Existing `specbridge.operator.status`, `resources/list`, and `resources/read` behavior remains compatible.
8. CLI regression tests cover the new tool list and call behavior.
9. Documentation explains the new bounded tool and blocked boundaries.
10. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
11. Required local validations and GitHub Actions pass before merge.

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

Write `.specbridge/reports/issue-243-mcp-next-task-tool.final-report.json`, `.specbridge/audit-packets/issue-243-mcp-next-task-tool.audit-packet.json`, and `.specbridge/audits/issue-243-mcp-next-task-tool.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when `specbridge.next-task` is implemented, required local validations pass, GitHub checks pass, PR closes issue #243, and post-merge closure evidence is recorded.
