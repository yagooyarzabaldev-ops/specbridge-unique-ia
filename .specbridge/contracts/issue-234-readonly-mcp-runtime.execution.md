# Execution Contract: Issue 234 Read-Only MCP Runtime

## Contract Metadata

- contract_id: issue-234-readonly-mcp-runtime
- run_id: sb-20260621-0234a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/234
- created_by: ChatGPT/Codex
- created_at: 2026-06-21
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Implement a bounded read-only MCP runtime surface for existing SpecBridge operator resources and reconcile the stale research PR/backlog state without enabling destructive cleanup or mutation-capable MCP tools.

## Context

SpecBridge already exports deterministic MCP-style operator resources through `specbridge-mcp-resources`, but the current catalog reports `mcp_server_status = not_implemented`. The next standardization step is a local stdio/read harness that serves those existing resources through read-only MCP-style requests while preserving all policy boundaries.

GitHub also contains stale PR #227 for a Tango 70B research note. That PR is not an active governed task, is based on an old main, and should be reconciled as research-only backlog hygiene rather than merged without a current contract.

Branch cleanup and artifact retention remain observable but blocked. This task must not delete, prune, move, compress, upload, archive, or enforce cleanup.

## Source References

- `README.md` - current product status and MCP posture.
- `SPECBRIDGE.md` - technical contract, stop conditions, and MCP governance.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active policy and blocked paths.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next recommended task.
- `docs/mcp-integration-contract.md` - MCP tool/resource contract standard.
- `docs/mcp-server-implementation-plan.md` - planned MCP server boundaries.
- `docs/specbridge-mcp-resource-exports.md` - existing read-only resource export behavior.
- `scripts/lib/mcp-resources.ps1` - existing deterministic resource catalog builder.
- `scripts/lib/standard-readiness.ps1` - readiness reporting surface.
- `scripts/specbridge.ps1` - CLI routing.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task introduces a local MCP-style runtime/read harness and updates readiness evidence. The runtime must remain read-only, local, deterministic, and free of network calls, dependency installation, secrets, production access, billing, authentication, authorization, database changes, deployment, or CI/CD security changes.

## Allowed Scope

```text
.specbridge/contracts/issue-234-readonly-mcp-runtime.execution.md
.specbridge/scopes/issue-234-readonly-mcp-runtime.scope.json
.specbridge/reports/issue-234-readonly-mcp-runtime.final-report.json
.specbridge/audit-packets/issue-234-readonly-mcp-runtime.audit-packet.json
.specbridge/audits/issue-234-readonly-mcp-runtime.chatgpt-audit.json
.specbridge/github-evidence/issue-234-readonly-mcp-runtime.closure.json
.specbridge/github-evidence/issue-234-readonly-mcp-runtime.pr-227-reconciliation.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/standard-readiness/current.status.json
README.md
docs/mcp-server-implementation-plan.md
docs/specbridge-mcp-readonly-runtime.md
docs/specbridge-mcp-resource-exports.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/mcp-resources.ps1
scripts/lib/standard-readiness.ps1
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
raw hidden prompt export
raw chat transcript export
raw unbounded tool output export
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
mutation-capable MCP tools
network MCP transport
hosted MCP server deployment
branch deletion
branch pruning
branch renaming
branch movement
branch archival
fetch or pull for cleanup
force-push
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

1. A local read-only MCP-style runtime command exists and can list available resources.
2. The runtime can read `specbridge://operator/current-goal`, `specbridge://operator/doctor-fix-plan`, and `specbridge://operator/orchestration-summaries`.
3. Unsupported methods and mutation-like requests are rejected with deterministic JSON errors.
4. `specbridge-mcp-resources` catalog reports the bounded read-only runtime accurately instead of `not_implemented`.
5. `specbridge-standard-readiness` reflects the read-only runtime while still recording no network, no GitHub mutation, no secrets, no deployment, and no cleanup enforcement.
6. CLI regression tests cover list/read success and unsupported/mutation rejection.
7. Documentation explains runtime usage, read-only boundaries, and why cleanup debt remains blocked.
8. Stale PR #227 is reconciled as research-only backlog hygiene without merging stale branch content.
9. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
10. Required validation scripts and full smoke pass locally and in GitHub Actions.

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

Stop if the task requires secrets, provider tokens, private keys, raw hidden prompt export, raw chat transcript export, raw unbounded tool output export, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, mutation-capable MCP tools, network MCP transport, branch/artifact cleanup enforcement, changing issue #194 lifecycle, implementing the digital twin, or unbounded Claude Code token spending.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must use bounded non-interactive execution with explicit budget, no session persistence, and no dangerous permission bypass.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-234-readonly-mcp-runtime.final-report.json`, `.specbridge/audit-packets/issue-234-readonly-mcp-runtime.audit-packet.json`, and `.specbridge/audits/issue-234-readonly-mcp-runtime.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the read-only MCP runtime is implemented, stale PR #227 is reconciled, required local validations pass, GitHub checks pass, PR closes issue #234, and post-merge closure evidence is recorded.
