# Execution Contract: Issue 209 Artifact Inventory Status

## Contract Metadata

- contract_id: issue-209-artifact-inventory-status
- run_id: sb-20260615-0209a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/209
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add a deterministic, read-only artifact inventory/status surface so SpecBridge can quantify repository evidence growth before any future retention or archival policy.

## Context

SpecBridge now preserves many repository-backed evidence families under `.specbridge/`, including contracts, scopes, reports, audits, GitHub evidence, runtime artifacts, orchestration manifests, executor packets, ledgers, and MCP catalogs. The current maintenance goal explicitly calls out artifact growth as infrastructure debt. This task must create a governed inventory command and artifact that reports the current evidence footprint without deleting, moving, compressing, pruning, archiving, or changing retention behavior.

## Source References

- `.specbridge/context/CURRENT_GOAL.md` - maintenance goal and next task guidance.
- `scripts/specbridge.ps1` - CLI entrypoint.
- `scripts/lib/common.ps1` - UTF-8 and path helpers.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.specbridge/` - repository evidence families to inventory.
- `docs/status-dashboard.html` and `docs/specbridge-studio.html` - regenerated operator status surfaces.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The command inspects repository evidence and may optionally write one governed inventory artifact, but it must remain read-only by default and must not enforce retention or modify historical evidence.

## Allowed Scope

```text
.specbridge/contracts/issue-209-artifact-inventory-status.execution.md
.specbridge/scopes/issue-209-artifact-inventory-status.scope.json
.specbridge/reports/issue-209-artifact-inventory-status.final-report.json
.specbridge/audit-packets/issue-209-artifact-inventory-status.audit-packet.json
.specbridge/audits/issue-209-artifact-inventory-status.chatgpt-audit.json
.specbridge/artifact-inventory/current.inventory.json
docs/specbridge-artifact-inventory.md
scripts/specbridge.ps1
scripts/lib/artifact-inventory.ps1
scripts/test-specbridge-cli.ps1
docs/status-dashboard.html
docs/specbridge-studio.html
.specbridge/context/CURRENT_GOAL.md
.specbridge/state/current-goal.json
.specbridge/mcp-resources/operator-state.catalog.json
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
artifact deletion
artifact movement
artifact compression
artifact pruning
retention enforcement
archival implementation
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

1. A deterministic `specbridge-artifact-inventory` CLI command exists.
2. The command returns valid JSON with artifact family entries for the main `.specbridge/` evidence families.
3. Each family entry declares family id, repository path, file count, total bytes, latest modified timestamp, retention posture, and cleanup permission.
4. The command returns overall totals and an explicit `retention_enforcement` value showing that no cleanup is performed.
5. The command is read-only when `-OutputPath` is omitted.
6. The command can optionally write `.specbridge/artifact-inventory/current.inventory.json` through `-OutputPath` and requires `-Force` when replacing the artifact.
7. Documentation describes the inventory surface and states that it does not delete, archive, prune, compress, or move artifacts.
8. CLI regression coverage validates command shape, required families, required fields, output-path behavior, force behavior, and no mutation without output path.
9. Required validation scripts and full smoke pass locally and in GitHub Actions.

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

Stop if the task requires deleting, moving, compressing, pruning, archiving, or enforcing retention on evidence artifacts; secrets; production configuration; billing; authentication security; authorization security; database changes; dependency installation; deployment automation; CI/CD security changes; workflow changes; network calls; changing operator decisions; reviving issue #194; or implementing the digital twin.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-209-artifact-inventory-status.final-report.json`, `.specbridge/audit-packets/issue-209-artifact-inventory-status.audit-packet.json`, and `.specbridge/audits/issue-209-artifact-inventory-status.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when artifact inventory status is implemented as a deterministic local CLI/artifact surface, all required local validations pass, GitHub checks pass, PR #209 closes issue #209, and post-merge closure evidence is recorded.
