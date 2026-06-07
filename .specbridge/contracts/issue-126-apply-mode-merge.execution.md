# Execution Contract: Issue 126 Apply-Mode Merge Expansion

## Contract Metadata

- contract_id: issue-126-apply-mode-merge
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/126
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Expand `issue-to-merge-github` apply mode to support the `merge` operation via `gh pr merge --squash --auto`, in addition to the existing `issue_close` and `pr_open`. Update the pilot scope guard and tests accordingly.

## Context

Issue 119 established `issue_close`. Issue 123 added `pr_open`. Issue 126 completes the three-operation pilot by adding `merge`: when `-GithubOperation merge` is passed with all evidence gates true, `scripts/specbridge.ps1` resolves the current branch's PR number via `gh pr view`, then calls `gh pr merge $prNumber --squash --auto --repo $repoSlug` and records the result in `github_mutation_result`.

The pilot scope guard changes from `issue_close_and_pr_open_only` to `issue_close_pr_open_and_merge_only`, and the `command_boundary` updates accordingly.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-123-apply-mode-pr-open.execution.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- docs/specbridge-issue-to-merge-operator.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/126

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- `gh pr merge --squash --auto` enables auto-merge on a real PR, which is a visible GitHub mutation
- risk is bounded by the evidence gate requirement (all 7 boolean fields must be true)
- apply mode is not automatic: requires explicit `-Force -ConfirmGithubMutation -EvidencePath` flags
- `--auto` enables auto-merge only; actual merge requires GitHub CI to pass

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-126-apply-mode-merge.execution.md
.specbridge/scopes/issue-126-apply-mode-merge.scope.json
.specbridge/scopes/issue-123-apply-mode-pr-open.scope.json
.specbridge/reports/issue-126-apply-mode-merge.final-report.json
.specbridge/audit-packets/issue-126-apply-mode-merge.audit-packet.json
.specbridge/audits/issue-126-apply-mode-merge.chatgpt-audit.json
.specbridge/github-evidence/issue-126-apply-mode-merge.github-mutation-evidence.json
docs/specbridge-issue-to-merge-operator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 126
GitHub pull request for this branch
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency installation
database changes
authentication implementation
authorization implementation
billing implementation
CI/CD security changes
deployment automation
production deployment
```

## Acceptance Criteria

- `scripts/specbridge.ps1` apply mode executes `gh pr merge --squash --auto` when `merge` is selected and all gates pass.
- PR number is auto-detected via `gh pr view $currentBranch --repo $repoSlug --json number`.
- Pilot scope guard allows `issue_close`, `pr_open`, and `merge`; any other operation sets `apply_mode_pilot_supports_issue_close_pr_open_and_merge_only` blocker.
- `github_mutation_result` records `operation`, `pr_number`, `head`, `repository`, `gh_exit_code`, `gh_output`, `status`.
- `ErrorActionPreference` guard applied around all gh calls (same pattern as prior operations).
- Test `apply-unsupported-op` updated to use `ci_wait` as the unsupported operation and check for `apply-pilot-supports-issue_close-pr_open-and-merge` boundary string.
- `command_boundary` updated to `apply-pilot-supports-issue_close-pr_open-and-merge`.
- All validators pass.
- GitHub CI passes on this branch's PR.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires changes outside declared scope, protected credential access, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete when `merge` apply-mode executes `gh pr merge --squash --auto`, the pilot scope guard supports all three operations, tests pass, all artifacts are in place, local validators pass, GitHub CI passes, and the branch is policy-gated into main.
