# Execution Contract: Issue 218 Artifact Retention Policy Draft

## Contract Metadata

- contract_id: issue-218-artifact-retention-policy-draft
- run_id: sb-20260615-0218a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/218
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Create a governed artifact retention policy draft and deterministic read-only evaluator so SpecBridge can classify artifact retention candidates without deleting, moving, compressing, pruning, archiving, uploading, or enforcing retention.

## Context

Issue 209 added `specbridge-artifact-inventory`, which reports repository evidence families with cleanup permission disabled and retention enforcement set to none. The next repository health step is to define the policy layer that would govern any future artifact retention work. This task must remain policy/evaluation only: it may classify artifact families and record evidence, but it must not mutate artifacts or enforce retention.

## Source References

- `.specbridge/context/CURRENT_GOAL.md` - current maintenance goal and next-task guidance.
- `.specbridge/artifact-inventory/current.inventory.json` - latest artifact inventory evidence.
- `docs/specbridge-artifact-inventory.md` - artifact inventory contract.
- `scripts/lib/artifact-inventory.ps1` - local read-only artifact inventory builder.
- `scripts/specbridge.ps1` - CLI entrypoint.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.specbridge/policy.yaml` - repository policy.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task defines artifact retention policy and a read-only evaluation surface. Any artifact retention enforcement or cleanup operation remains blocked.

## Allowed Scope

```text
.specbridge/contracts/issue-218-artifact-retention-policy-draft.execution.md
.specbridge/scopes/issue-218-artifact-retention-policy-draft.scope.json
.specbridge/reports/issue-218-artifact-retention-policy-draft.final-report.json
.specbridge/audit-packets/issue-218-artifact-retention-policy-draft.audit-packet.json
.specbridge/audits/issue-218-artifact-retention-policy-draft.chatgpt-audit.json
.specbridge/policies/artifact-retention-policy.draft.json
.specbridge/artifact-retention/current.policy-evaluation.json
.specbridge/artifact-inventory/current.inventory.json
docs/specbridge-artifact-retention-policy.md
scripts/specbridge.ps1
scripts/lib/artifact-retention-policy.ps1
scripts/lib/artifact-inventory.ps1
scripts/lib/dashboards.ps1
scripts/test-specbridge-cli.ps1
scripts/test-specbridge-negative-validations.ps1
docs/specbridge-artifact-inventory.md
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
artifact archival implementation
artifact upload
artifact remote mutation
retention enforcement
cleanup apply mode
network calls from the artifact retention policy command
branch deletion
branch pruning
remote pruning
branch rename
branch movement
branch archival implementation
force push
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

1. A machine-readable `.specbridge/policies/artifact-retention-policy.draft.json` exists.
2. The policy draft declares `status=draft`, `enforcement=none`, `cleanup_permission=none`, artifact family classes, hard blocks, required gates, future activation requirements, and explicit blocked commands/actions.
3. A deterministic `specbridge-artifact-retention-policy` CLI command exists.
4. The command returns valid JSON and performs no network calls and no artifact mutation.
5. The command evaluates current local artifact inventory and classifies evidence families while keeping every entry `cleanup_permission=none`.
6. The command returns policy metadata, totals, family class counts, blocked counts, required future gates, family evaluations, and a clear `enforcement_status`.
7. The command is read-only when `-OutputPath` is omitted.
8. The command can optionally write `.specbridge/artifact-retention/current.policy-evaluation.json` through `-OutputPath` and requires `-Force` when replacing the artifact.
9. Documentation describes the draft policy, evaluator, family classes, blocked actions, future activation path, and states that no retention enforcement or artifact cleanup is authorized.
10. CLI regression coverage validates command shape, deterministic repeated output, required fields, policy gates, cleanup_permission=none, output-path behavior, force behavior, bad path behavior, and no mutation without output path.
11. Artifact inventory includes the artifact retention policy evidence family.
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

Stop if the task requires deleting, moving, compressing, pruning, archiving, uploading, remotely mutating, or otherwise changing artifacts; enforcing retention; secrets; production configuration; billing; authentication security; authorization security; database changes; dependency installation; deployment automation; CI/CD security changes; workflow changes; network calls from the policy command; changing operator decisions; reviving issue #194; or implementing the digital twin.

## Claude Code Delegation

Claude Code may implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must not run blocked commands and must stop rather than implement retention enforcement or artifact cleanup.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-218-artifact-retention-policy-draft.final-report.json`, `.specbridge/audit-packets/issue-218-artifact-retention-policy-draft.audit-packet.json`, and `.specbridge/audits/issue-218-artifact-retention-policy-draft.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the artifact retention policy draft and read-only evaluator are implemented, all required local validations pass, GitHub checks pass, PR closes issue #218, and post-merge closure evidence is recorded.
