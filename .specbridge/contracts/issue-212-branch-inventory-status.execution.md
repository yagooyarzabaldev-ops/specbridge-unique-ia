# Execution Contract: Issue 212 Branch Inventory Status

## Contract Metadata

- contract_id: issue-212-branch-inventory-status
- run_id: sb-20260615-0212c3d4
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/212
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add a deterministic, read-only branch inventory/status surface so SpecBridge can quantify local and origin branch debt before any future branch cleanup policy.

## Context

SpecBridge has paid down CI duplication and artifact-growth observability. The current repository health goal still names branch debt as infrastructure debt. This task must create a governed branch inventory command and artifact that reports branch references and branch-debt signals without deleting, pruning, force-pushing, renaming, moving, archiving, or otherwise mutating branches.

## Source References

- `.specbridge/context/CURRENT_GOAL.md` - maintenance goal and next task guidance.
- `scripts/specbridge.ps1` - CLI entrypoint.
- `scripts/lib/common.ps1` - UTF-8 and path helpers.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.git` local refs and `refs/remotes/origin/*` - branch inventory input source.
- `.specbridge/artifact-inventory/current.inventory.json` - repository evidence inventory surface.
- `docs/status-dashboard.html` and `docs/specbridge-studio.html` - regenerated operator status surfaces.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The command inspects Git branch metadata and may optionally write one governed inventory artifact, but it must remain read-only by default and must not delete, prune, rename, archive, force-push, fetch, pull, or mutate branch state.

## Allowed Scope

```text
.specbridge/contracts/issue-212-branch-inventory-status.execution.md
.specbridge/scopes/issue-212-branch-inventory-status.scope.json
.specbridge/reports/issue-212-branch-inventory-status.final-report.json
.specbridge/audit-packets/issue-212-branch-inventory-status.audit-packet.json
.specbridge/audits/issue-212-branch-inventory-status.chatgpt-audit.json
.specbridge/branch-inventory/current.inventory.json
docs/specbridge-branch-inventory.md
scripts/specbridge.ps1
scripts/lib/branch-inventory.ps1
scripts/test-specbridge-cli.ps1
scripts/lib/artifact-inventory.ps1
docs/specbridge-artifact-inventory.md
.specbridge/artifact-inventory/current.inventory.json
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
git fetch
git pull
branch deletion
branch pruning
remote pruning
branch rename
branch movement
branch archival implementation
force push
retention enforcement
artifact deletion
artifact movement
artifact compression
artifact pruning
network calls from the branch inventory command
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

1. A deterministic `specbridge-branch-inventory` CLI command exists.
2. The command returns valid JSON with local and origin branch reference entries discovered from local Git refs without network calls.
3. Each branch entry declares ref name, short branch name, ref type, object id, latest commit timestamp, prefix, merged-into-main status, retention posture, and cleanup permission.
4. The command returns totals, prefix counts, merged/unmerged counts, and an explicit `branch_mutation_policy` showing that no branch cleanup is performed.
5. The command is read-only when `-OutputPath` is omitted.
6. The command can optionally write `.specbridge/branch-inventory/current.inventory.json` through `-OutputPath` and requires `-Force` when replacing the artifact.
7. Documentation describes the inventory surface and states that it does not delete, prune, rename, move, archive, fetch, pull, or force-push branches.
8. CLI regression coverage validates command shape, deterministic repeated output, required fields, totals, output-path behavior, force behavior, bad path behavior, and no mutation without output path.
9. The artifact inventory includes the branch inventory evidence family.
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

Stop if the task requires deleting, pruning, renaming, moving, archiving, force-pushing, fetching, pulling, or otherwise mutating branches; secrets; production configuration; billing; authentication security; authorization security; database changes; dependency installation; deployment automation; CI/CD security changes; workflow changes; network calls from the inventory command; changing operator decisions; reviving issue #194; or implementing the digital twin.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-212-branch-inventory-status.final-report.json`, `.specbridge/audit-packets/issue-212-branch-inventory-status.audit-packet.json`, and `.specbridge/audits/issue-212-branch-inventory-status.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when branch inventory status is implemented as a deterministic local CLI/artifact surface, all required local validations pass, GitHub checks pass, PR closes issue #212, and post-merge closure evidence is recorded.
