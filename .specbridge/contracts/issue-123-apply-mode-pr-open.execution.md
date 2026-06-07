# Execution Contract: Issue 123 Apply-Mode pr_open Expansion

## Contract Metadata

- contract_id: issue-123-apply-mode-pr-open
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/123
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-06
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Expand `issue-to-merge-github` apply mode to support the `pr_open` operation via `gh pr create`, in addition to the existing `issue_close`. Update the pilot scope guard and tests accordingly.

## Context

Issue 119 established the first real apply-mode GitHub mutation (`issue_close`). Issue 121 fixed a bug where `$ErrorActionPreference = "Stop"` caused `NativeCommandError` on gh stderr, preventing JSON output.

Issue 123 expands the pilot to `pr_open`: when `-GithubOperation pr_open` is passed with all evidence gates true, `scripts/specbridge.ps1` calls `gh pr create` and records the PR URL, PR number, head, base, and exit code in `github_mutation_result`.

The pilot scope guard changes from `issue_close_only` to `issue_close_and_pr_open_only`, and the blocker string updates from `apply_mode_pilot_supports_issue_close_only` to `apply_mode_pilot_supports_issue_close_and_pr_open_only`.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-119-apply-mode-github-operator-pilot.execution.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- docs/specbridge-issue-to-merge-operator.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/123

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- `gh pr create` opens a real PR on GitHub, which is a visible mutation
- risk is bounded by the evidence gate requirement (all 7 boolean fields must be true)
- apply mode is not automatic: requires explicit `-Force -ConfirmGithubMutation -EvidencePath` flags
- PR creation is idempotent in practice (gh returns non-zero if PR already exists for the branch)

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-123-apply-mode-pr-open.execution.md
.specbridge/scopes/issue-123-apply-mode-pr-open.scope.json
.specbridge/reports/issue-123-apply-mode-pr-open.final-report.json
.specbridge/audit-packets/issue-123-apply-mode-pr-open.audit-packet.json
.specbridge/audits/issue-123-apply-mode-pr-open.chatgpt-audit.json
.specbridge/github-evidence/issue-123-apply-mode-pr-open.github-mutation-evidence.json
docs/specbridge-issue-to-merge-operator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 123
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

- `scripts/specbridge.ps1` apply mode executes `gh pr create` when `pr_open` is selected and all gates pass.
- Pilot scope guard allows both `issue_close` and `pr_open`; any other operation sets `apply_mode_pilot_supports_issue_close_and_pr_open_only` blocker.
- `github_mutation_result` records `operation`, `pr_url`, `pr_number`, `head`, `base`, `repository`, `gh_exit_code`, `gh_output`, `status`.
- `ErrorActionPreference` guard applied around `gh pr create` (same pattern as issue_close fix from issue 121).
- Test for `apply-unsupported-op` updated to use `merge` operation and check for `apply-pilot-supports-issue_close-and-pr_open` boundary string.
- All validators pass.
- GitHub CI passes on PR 123.

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

This task is complete when `pr_open` apply-mode executes `gh pr create`, the pilot scope guard supports both operations, tests pass, all artifacts are in place, local validators pass, GitHub CI passes, and the branch is policy-gated into main.
