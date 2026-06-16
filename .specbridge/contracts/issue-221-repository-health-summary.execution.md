# Execution Contract: Issue 221 Repository Health Summary Evidence

## Contract Metadata

- contract_id: issue-221-repository-health-summary
- run_id: sb-20260615-0221a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/221
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add a deterministic read-only repository health summary evidence command that aggregates the existing branch inventory, branch cleanup policy, artifact inventory, and artifact retention policy evidence layers without authorizing cleanup or enforcement.

## Context

SpecBridge now has read-only evidence for branch inventory, branch cleanup policy, artifact inventory, and artifact retention policy. The next infrastructure-hardening step is to expose a single repository health summary that operators can use before deciding future governed cleanup or retention activation work. This task is evidence-only and must not delete, move, prune, compress, archive, upload, mutate remote state, fetch, pull, force-push, run cleanup apply mode, or enforce retention.

## Source References

- `.specbridge/context/CURRENT_GOAL.md` - current maintenance goal and next-task guidance.
- `scripts/lib/branch-inventory.ps1` - local read-only branch inventory builder.
- `scripts/lib/branch-cleanup-policy.ps1` - local read-only branch cleanup policy evaluator.
- `scripts/lib/artifact-inventory.ps1` - local read-only artifact inventory builder.
- `scripts/lib/artifact-retention-policy.ps1` - local read-only artifact retention policy evaluator.
- `scripts/specbridge.ps1` - CLI entrypoint.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.specbridge/policy.yaml` - repository policy.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task aggregates repository health evidence and policy posture. Any cleanup, branch mutation, artifact mutation, or enforcement remains blocked.

## Allowed Scope

```text
.specbridge/contracts/issue-221-repository-health-summary.execution.md
.specbridge/scopes/issue-221-repository-health-summary.scope.json
.specbridge/reports/issue-221-repository-health-summary.final-report.json
.specbridge/audit-packets/issue-221-repository-health-summary.audit-packet.json
.specbridge/audits/issue-221-repository-health-summary.chatgpt-audit.json
.specbridge/repository-health/current.summary.json
.specbridge/artifact-inventory/current.inventory.json
docs/specbridge-repository-health-summary.md
docs/specbridge-artifact-inventory.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/repository-health-summary.ps1
scripts/lib/artifact-inventory.ps1
scripts/test-specbridge-cli.ps1
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
branch deletion
branch pruning
remote pruning
branch rename
branch movement
branch archival implementation
force push
git fetch from the repository health summary command
git pull from the repository health summary command
artifact deletion
artifact movement
artifact compression
artifact pruning
artifact archival implementation
artifact upload
artifact remote mutation
retention enforcement
cleanup apply mode
network calls from the repository health summary command
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

1. A deterministic `specbridge-repository-health-summary` CLI command exists.
2. The command returns valid JSON and performs no network calls, branch mutations, artifact mutations, cleanup apply mode, or retention enforcement.
3. The command consumes local read-only evidence builders for branch inventory, branch cleanup policy, artifact inventory, and artifact retention policy.
4. The command reports overall health posture, branch posture, artifact posture, policy posture, cleanup_permission status, enforcement status, blocked action counts, future gates, and evidence source paths.
5. The command keeps every cleanup and retention permission disabled and clearly states that enforcement is not authorized.
6. The command is read-only when `-OutputPath` is omitted.
7. The command can optionally write `.specbridge/repository-health/current.summary.json` through `-OutputPath` and requires `-Force` when replacing the artifact.
8. Artifact inventory includes the repository health summary evidence family.
9. Documentation describes the summary command, evidence sources, output shape, blocked actions, future activation path, and non-enforcement guarantee.
10. CLI regression coverage validates command shape, deterministic repeated output, required fields, cleanup_permission=none, enforcement disabled, output-path behavior, force behavior, bad path behavior, and no mutation without output path.
11. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
12. Required validation scripts and full smoke pass locally and in GitHub Actions.

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

Stop if the task requires deleting, pruning, renaming, moving, compressing, archiving, uploading, remotely mutating, fetching, pulling, force-pushing, or otherwise changing branches or artifacts; enforcing retention; cleanup apply mode; secrets; production configuration; billing; authentication security; authorization security; database changes; dependency installation; deployment automation; CI/CD security changes; workflow changes; network calls from the repository health summary command; changing operator decisions; reviving issue #194; or implementing the digital twin.

## Claude Code Delegation

Claude Code may implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must not run blocked commands and must stop rather than implement cleanup or enforcement.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-221-repository-health-summary.final-report.json`, `.specbridge/audit-packets/issue-221-repository-health-summary.audit-packet.json`, and `.specbridge/audits/issue-221-repository-health-summary.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the repository health summary evidence command is implemented, all required local validations pass, GitHub checks pass, PR closes issue #221, and post-merge closure evidence is recorded.
