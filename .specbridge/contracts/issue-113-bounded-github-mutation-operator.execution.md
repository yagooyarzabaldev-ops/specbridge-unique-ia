# Execution Contract: Issue 113 Bounded GitHub Mutation Operator

## Contract Metadata

- contract_id: issue-113-bounded-github-mutation-operator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/113
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Add a bounded GitHub mutation operator mode for the issue-to-merge flow.

The new command must keep dry-run as the default, make every GitHub operation explicit, produce a deterministic connector action envelope, and block apply mode unless force, explicit confirmation, and declared gate evidence are present.

## Context

Issue 109 introduced `issue-to-merge-plan` as a deterministic plan-only operator.

Issue 111 piloted that operator safely and recorded the next task: define the GitHub-mutating expansion contract in a bounded mode. Issue 113 implements that expansion as a local CLI command that can be validated without GitHub credentials while still describing the exact connector actions that a governed GitHub operator may perform.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-issue-to-merge-operator.md
- docs/specbridge-local-cli.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- .specbridge/issue-to-merge-runs/issue-111-issue-to-merge-operator-pilot.issue-to-merge-run.json
- .specbridge/reports/issue-111-issue-to-merge-operator-pilot.final-report.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/113

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task changes the local CLI product surface
- the task defines GitHub connector mutation actions
- dry-run remains the default and performs no GitHub calls
- apply mode is blocked unless force, explicit confirmation, and declared local/GitHub gate evidence are present
- secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security changes, and deployment remain blocked

## Allowed Scope

```text
README.md
docs/specbridge-issue-to-merge-operator.md
docs/specbridge-local-cli.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-113-bounded-github-mutation-operator.audit-packet.json
.specbridge/audits/issue-113-bounded-github-mutation-operator.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-113-bounded-github-mutation-operator.execution.md
.specbridge/issue-to-merge-runs/issue-113-bounded-github-mutation-operator.github-mutation-run.json
.specbridge/reports/issue-113-bounded-github-mutation-operator.final-report.json
.specbridge/scopes/issue-113-bounded-github-mutation-operator.scope.json
GitHub issue 113
GitHub pull request for this branch
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency manifests
live Claude Code launch
live Antigravity launch
runtime launch execution
secret or token access
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

- `scripts/specbridge.ps1` exposes `issue-to-merge-github`.
- The command defaults to `MutationMode` `dry_run`.
- Dry-run mode emits deterministic JSON, performs no GitHub calls, and can write `.specbridge/issue-to-merge-runs/*.github-mutation-run.json`.
- The output records task id, issue reference, repository URL, branch, selected operations, operation evidence, connector action envelope, evidence paths, local gates, GitHub gates, merge conditions, policy boundaries, stop conditions, command boundary, and output path.
- The command records explicit operations for issue creation or verification, PR opening or update, CI wait, policy-gated merge, issue close, and post-merge memory.
- Apply mode fails deterministically without `-Force`.
- Apply mode fails deterministically without `-ConfirmGithubMutation`.
- Apply mode fails deterministically without a declared `.specbridge/github-evidence/*.github-mutation-evidence.json` evidence file.
- Tests cover the success path, output artifact path, selected operation path, missing `TaskId`, apply without force, and apply without evidence.
- README, local CLI docs, dedicated operator docs, and CURRENT_GOAL record issue 113 and the bounded GitHub mutation standard.
- Final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-github -TaskId issue-113-bounded-github-mutation-operator -Title "Add bounded GitHub mutation operator mode" -Goal "Add a deterministic bounded issue-to-merge GitHub mutation operator surface with dry-run default, explicit connector action envelope, apply evidence gates, docs, tests, and audit evidence." -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/113 -OutputPath .specbridge/issue-to-merge-runs/issue-113-bounded-github-mutation-operator.github-mutation-run.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires accessing secrets, storing credentials, changing workflow security controls, changing production, changing billing, changing authentication or authorization security, installing dependencies, changing databases, launching Claude Code, launching Antigravity, deploying, or touching scope outside the declared paths.

Stop if apply mode cannot be gated by force, explicit confirmation, and declared evidence.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must use the repository final-report schema and include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete when the GitHub mutation operator command, tests, docs, memory, GitHub mutation run artifact, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
