# Execution Contract: Issue 91 Align Agent Stage Policy

## Contract Metadata

- contract_id: issue-091-align-agent-stage-policy
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/91
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: low
- status: completed

## Goal

Update `AGENTS.md` so the repository stage matches the implemented SpecBridge phase instead of saying the repository is still foundation-only.

This task must:

- preserve Spec Driven Development rules
- preserve execution-contract requirements
- preserve policy hierarchy and stop conditions
- preserve protected areas and merge gates
- update stale current-stage guidance
- update current repository memory and closure evidence

## Context

The repository has completed the foundation, repository-first MVP, Standard Loop v1, V5 readiness, V5 live pilot evidence, V5 runner hardening, and V5 serious pilot status layers. README and repository evidence now describe a governed standardization and runtime expansion phase.

`AGENTS.md` still says the repository is in foundation phase and that no product implementation code should be added until the foundation artifacts exist. Those artifacts now exist. The stale stage guidance can mislead future agents into blocking properly contracted work.

This contract updates only the stage guidance. It must not weaken security, policy hierarchy, required contracts, scope manifests, validations, review, CI, final reports, audit packets, or ChatGPT/Codex audits.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-089-post-merge-memory-closure.execution.md
- .specbridge/reports/issue-089-post-merge-memory-closure.final-report.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/91
- https://github.com/yagooyarzabaldev-ops/specbridge/pull/90

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- this task updates documentation and repository memory only
- it does not change product code, scripts, tests, workflows, dependencies, secrets, production, billing, authentication, authorization, database, or deployment automation
- the updated guidance preserves all existing security and execution-contract controls

## Allowed Scope

```text
AGENTS.md
.specbridge/audit-packets/issue-091-align-agent-stage-policy.audit-packet.json
.specbridge/audits/issue-091-align-agent-stage-policy.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-091-align-agent-stage-policy.execution.md
.specbridge/reports/issue-091-align-agent-stage-policy.final-report.json
.specbridge/scopes/issue-091-align-agent-stage-policy.scope.json
GitHub issue 91
GitHub pull request for this branch
```

## Blocked Scope

```text
product code
scripts/**
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

- `AGENTS.md` no longer claims the repository is still foundation phase only.
- `AGENTS.md` states that the current stage is governed standardization and runtime expansion.
- `AGENTS.md` still requires active execution contracts, scope manifests, acceptance criteria, validation commands, security/review/CI gates, final reports, audit packets, and ChatGPT/Codex audits for implementation work.
- `AGENTS.md` still blocks secrets, production, billing, auth security, authorization security, destructive database changes, CI/CD security changes, dependency installation, deployment automation, and production deployment unless explicitly authorized by policy and contract.
- Issue 091 closure evidence validates locally.
- No product code, scripts, workflows, secrets, production, billing, auth, database, dependency, CI/CD security, or deployment files are changed.

## Required Validations

```powershell
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

Stop if the task requires product code changes, script changes, workflow changes, protected credential access, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete when `AGENTS.md` accurately reflects the current governed standardization and runtime expansion stage, all local evidence validators pass, GitHub CI passes, and the branch is policy-gated into main.
