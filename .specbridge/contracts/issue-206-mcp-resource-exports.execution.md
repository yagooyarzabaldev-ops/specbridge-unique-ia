# Execution Contract: Issue 206 MCP Resource Exports

## Contract Metadata

- contract_id: issue-206-mcp-resource-exports
- run_id: sb-20260615-0206abcd
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/206
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Expose read-only SpecBridge operator state as deterministic, repository-backed MCP resource definitions and export artifacts for external agents, without implementing a live MCP server runtime.

## Context

SpecBridge already has local operator state that external agents need to consume without exploratory shell access: current goal memory, doctor fix-plan health, and orchestration summaries. The repository has MCP integration standards and resource contract templates, but no governed resource export surface for the current operator state.

This task should implement a local, deterministic CLI command that emits a catalog of MCP-style resources and can optionally write that catalog to a repository artifact. The catalog must be read-only, source-backed, and safe for future external agents.

## Source References

- `docs/mcp-integration-contract.md` - MCP resource contract requirements.
- `.specbridge/mcp-resource-contract-template.md` - resource contract template.
- `.specbridge/context/CURRENT_GOAL.md` - current goal source.
- `.specbridge/state/current-goal.json` - machine-readable current goal source.
- `scripts/lib/intake-doctor.ps1` - doctor and next-task state.
- `.specbridge/orchestrations/*.orchestration.json` - orchestration source artifacts.
- `scripts/specbridge.ps1` - CLI entrypoint.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. This extends the local CLI and repository artifact surface, but it must remain read-only and deterministic. It must not add a live MCP server, dependency installation, network calls, secrets, production configuration, billing, authentication, authorization, database changes, CI/CD security changes, or deployment automation.

## Allowed Scope

```text
.specbridge/contracts/issue-206-mcp-resource-exports.execution.md
.specbridge/scopes/issue-206-mcp-resource-exports.scope.json
.specbridge/reports/issue-206-mcp-resource-exports.final-report.json
.specbridge/audit-packets/issue-206-mcp-resource-exports.audit-packet.json
.specbridge/audits/issue-206-mcp-resource-exports.chatgpt-audit.json
.specbridge/mcp/specbridge-operator-state-resources.md
.specbridge/mcp-resources/operator-state.catalog.json
docs/specbridge-mcp-resource-exports.md
scripts/specbridge.ps1
scripts/lib/mcp-resources.ps1
scripts/test-specbridge-cli.ps1
docs/status-dashboard.html
docs/specbridge-studio.html
.specbridge/context/CURRENT_GOAL.md
.specbridge/state/current-goal.json
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
live MCP server runtime
network calls
production deployment
deployment automation
authentication implementation
authorization implementation
billing implementation
database changes
CI/CD security changes
operator decision registry changes
issue #194 lifecycle changes
digital twin implementation
```

## Acceptance Criteria

1. A deterministic `specbridge-mcp-resources` CLI command exists.
2. The command returns valid JSON with resource entries for current goal, doctor fix-plan, and orchestration summaries.
3. Each resource entry declares name, URI, content type, source path, refresh behavior, sensitivity, and read-only policy.
4. The command can optionally write the resource catalog to `.specbridge/mcp-resources/operator-state.catalog.json` through `-OutputPath`.
5. A resource contract document describes the exported resources and states that no live MCP server is implemented.
6. CLI regression coverage validates the command shape, required resources, output-path behavior, and no mutation when no output path is passed.
7. Required validation scripts and full smoke pass locally and in GitHub Actions.

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

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, database changes, dependency installation, deployment automation, CI/CD security changes, workflow changes, live MCP server runtime, network calls, changing operator decisions, reviving issue #194, or implementing the digital twin.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-206-mcp-resource-exports.final-report.json`, `.specbridge/audit-packets/issue-206-mcp-resource-exports.audit-packet.json`, and `.specbridge/audits/issue-206-mcp-resource-exports.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when MCP resource exports are implemented as a deterministic local CLI/artifact surface, all required local validations pass, GitHub checks pass, PR #206 closes issue #206, and post-merge closure evidence is recorded.
