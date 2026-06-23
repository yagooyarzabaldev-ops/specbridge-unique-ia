# Execution Contract: Issue 249 Governed Branch Cleanup

## Contract Metadata

- contract_id: issue-249-governed-branch-cleanup
- run_id: sb-20260622-0249bc01
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/249
- created_by: ChatGPT/Codex
- created_at: 2026-06-22
- autonomy_profile: full_autopilot
- risk_level: high
- status: ready_for_execution

## Goal

Resolve the observed stale branch debt through a one-time governed cleanup of local and origin branch refs whose pull requests are confirmed merged, while preserving unmerged, closed-without-merge, active, unknown, and protected branches.

## Context

The repository already has a branch cleanup policy draft and branch cleanup evaluator, but the current goal records branch cleanup as policy-only with no deletion authorization. The user asked to fix that remaining branch debt. This contract creates the missing dedicated authorization for one exact branch list, executes only that bounded cleanup, records before and after evidence, regenerates repository health artifacts, and keeps general cleanup enforcement disabled after the task.

Git history uses squash merge for many pull requests, so `git merge-base` alone is insufficient to classify stale branches. This task uses GitHub PR state as the cleanup authority: a branch is eligible only when its matching PR is confirmed `MERGED`.

## Source References

- `README.md` - current product status, default autonomy, and maintenance debt.
- `SPECBRIDGE.md` - execution contract, stop conditions, quality gates, and merge rules.
- `AGENTS.md` - repository operating rules and branch cleanup restrictions.
- `.specbridge/policy.yaml` - active repository policy and protected boundaries.
- `.specbridge/context/CURRENT_GOAL.md` - maintenance debt and branch cleanup blocked status.
- `docs/specbridge-branch-cleanup-policy.md` - branch cleanup policy draft behavior and future activation path.
- `.specbridge/policies/branch-cleanup-policy.draft.json` - base cleanup policy draft.
- `.specbridge/policies/branch-cleanup-authorization.issue-249.json` - one-time exact branch cleanup authorization for this task.
- `.specbridge/branch-cleanup/issue-249-governed-branch-cleanup.evidence.json` - classification, execution, and after-state evidence.
- GitHub PR list evidence collected on 2026-06-22 with `headRefName`, `state`, `mergedAt`, and PR URLs.
- Claude Code read-only branch classification review collected on 2026-06-22.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

High. This task performs destructive branch ref cleanup on local and origin refs. The risk is bounded by exact branch-name authorization, PR merge evidence, preservation rules, blocked commands, and post-cleanup validation. The task does not touch secrets, production, billing, authentication, authorization, databases, CI/CD security, dependencies, deployments, artifacts, or code behavior.

## Allowed Scope

```text
.specbridge/contracts/issue-249-governed-branch-cleanup.execution.md
.specbridge/scopes/issue-249-governed-branch-cleanup.scope.json
.specbridge/policies/branch-cleanup-authorization.issue-249.json
.specbridge/branch-cleanup/issue-249-governed-branch-cleanup.evidence.json
.specbridge/branch-inventory/current.inventory.json
.specbridge/branch-cleanup/current.policy-evaluation.json
.specbridge/repository-health/current.summary.json
.specbridge/standard-readiness/current.status.json
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/reports/issue-249-governed-branch-cleanup.final-report.json
.specbridge/audit-packets/issue-249-governed-branch-cleanup.audit-packet.json
.specbridge/audits/issue-249-governed-branch-cleanup.chatgpt-audit.json
.specbridge/github-evidence/issue-249-governed-branch-cleanup.closure.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
README.md
docs/status-dashboard.html
docs/specbridge-studio.html
```

Authorized Git mutations are limited to:

```text
git branch -D <exact-authorized-local-branch>
git push origin --delete <exact-authorized-origin-branch>
git branch -dr origin/<exact-authorized-origin-branch>
```

Each mutation must target only a branch listed in `.specbridge/policies/branch-cleanup-authorization.issue-249.json` with a confirmed merged PR. Missing local or remote refs may be recorded as already absent and skipped.

## Blocked Scope

```text
main
origin/main
origin/HEAD
codex/visual-digital-twin-rosario-mvp
docs/tango-70b-research-20260617
branches without a confirmed merged PR
branches with closed-but-not-merged PRs
branches with unknown PR state
branches outside the exact authorization list
git fetch
git pull
git remote prune
git fetch --prune
git push --force
git push -f
branch rename
branch movement
branch archival
general cleanup apply mode
general retention enforcement
artifact deletion
artifact movement
artifact compression
artifact archival
artifact upload
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency installation
package manager files
secret access
production configuration
billing configuration
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
issue #194 lifecycle changes
digital twin implementation
```

## Acceptance Criteria

1. A dedicated execution contract and scope manifest authorize issue #249 before any branch deletion.
2. `.specbridge/policies/branch-cleanup-authorization.issue-249.json` lists every branch allowed for cleanup and every branch that must be preserved.
3. Claude Code read-only classification evidence is recorded before deletion.
4. Local branch deletion is attempted only for exact authorized branches that exist locally.
5. Origin branch deletion is attempted only for exact authorized branches that exist on origin.
6. Local remote-tracking ref deletion is attempted only for exact authorized branches after the origin delete succeeds or the remote branch is already absent.
7. `main`, `origin/main`, `codex/visual-digital-twin-rosario-mvp`, and `docs/tango-70b-research-20260617` are preserved.
8. Branch inventory, branch cleanup policy evaluation, repository health, standard readiness, MCP resource catalog, artifact inventory, status dashboard, and Studio dashboard are regenerated after cleanup.
9. Final report, audit packet, and ChatGPT/Codex audit evidence are written.
10. Required local validations and GitHub Actions pass before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command specbridge-doctor -FixPlan -OutputFormat json -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command specbridge-standard-readiness
git diff --check
```

## Stop Conditions

Stop if the task requires deleting a branch outside the authorization list, deleting an unmerged or unknown branch, deleting `main`, using force push, using fetch/prune/pull, changing workflow security, changing production, accessing secrets, changing billing, changing authentication or authorization, changing databases, installing dependencies, changing deployment automation, enforcing general cleanup apply mode, deleting artifacts, changing issue #194 lifecycle, implementing digital twin work, or bypassing failed validation.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, exact cleanup evidence, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-249-governed-branch-cleanup.final-report.json`, `.specbridge/audit-packets/issue-249-governed-branch-cleanup.audit-packet.json`, and `.specbridge/audits/issue-249-governed-branch-cleanup.chatgpt-audit.json`. The report must state changed files, branch cleanup results, preserved branches, validations, policy result, risk result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

Task is complete when the exact authorized branch cleanup is executed or skipped with evidence, protected branches are preserved, repository health artifacts are regenerated, local validations pass, GitHub checks pass, PR closes issue #249, and post-merge closure evidence is recorded.
