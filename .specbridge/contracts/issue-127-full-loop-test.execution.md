# Execution Contract: Issue 127 Full End-to-End Apply-Mode Loop Test

## Contract Metadata

- contract_id: issue-127-full-loop-test
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/127
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Implement and evidence the first full end-to-end dry-run of the `issue-to-merge-github` operator covering all six default operations (`issue_create`, `pr_open`, `ci_wait`, `merge`, `issue_close`, `post_merge_memory`) in a single governed call, and add a CLI test that validates this complete loop produces the correct connector action envelope and output artifact.

## Context

Issues 119, 123, and 126 expanded apply mode operation by operation (issue_close → pr_open → merge). Issue 127 closes the pilot loop by:
1. Verifying the full default operation set in dry-run mode via a new CLI test
2. Updating evidence for issue 125 (PR 128 merged) and marking its scope as completed
3. Updating memory files to reflect the completed three-operation apply-mode pilot
4. Creating all governance artifacts for issue 127

No code changes to `scripts/specbridge.ps1` are needed — the default 6-operation dry-run already works.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-125-post-merge-closure-issue123.execution.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/127

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- The only code change is adding a CLI test (no GitHub mutations in apply mode for this issue)
- Dry-run mode never executes `gh` commands
- All changes are bounded to test, evidence, and documentation files

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-127-full-loop-test.execution.md
.specbridge/scopes/issue-127-full-loop-test.scope.json
.specbridge/scopes/issue-125-post-merge-closure-issue123.scope.json
.specbridge/reports/issue-127-full-loop-test.final-report.json
.specbridge/audit-packets/issue-127-full-loop-test.audit-packet.json
.specbridge/audits/issue-127-full-loop-test.chatgpt-audit.json
.specbridge/github-evidence/issue-127-full-loop-test.github-mutation-evidence.json
.specbridge/github-evidence/issue-125-post-merge-closure-issue123.github-mutation-evidence.json
scripts/test-specbridge-cli.ps1
GitHub issue 127
GitHub pull request for this branch
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
scripts/specbridge.ps1 (no code changes needed)
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

- `scripts/test-specbridge-cli.ps1` includes a `issue-to-merge-github-full-loop-dry-run` test that runs with all 6 default operations, verifies `dry_run=true`, `github_calls_performed=false`, 6 operations, and 6 connector actions.
- The test writes and validates a `.specbridge/issue-to-merge-runs/issue-127-full-loop-test.github-mutation-run.json` artifact in the test fixture.
- Issue-125 evidence updated with `github_ci_passed: true` after PR 128 merged.
- Issue-125 scope marked as `completed`.
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

This task is complete when the full-loop dry-run CLI test passes, all governance artifacts are in place, evidence files are updated, local validators pass, GitHub CI passes, and the branch is policy-gated into main.
