# Execution Contract: Issue 61 Controlled Antigravity Claude Code Runtime Launch

## Contract Metadata

- contract_id: issue-061-controlled-antigravity-runtime-launch
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/61
- created_by: ChatGPT/Codex
- created_at: 2026-05-21
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run the first controlled Claude Code executor task from the Antigravity workspace under a SpecBridge execution contract, then validate and audit the result through GitHub.

## Context

SpecBridge has completed repository-first governance, local CLI, audit packets, ChatGPT audit, security gates, executor handoff packets, branch-per-executor orchestration, controlled GitHub evidence, and cleanup of stale GitHub evidence.

The next product proof is a live executor run: ChatGPT/Codex defines the contract, SpecBridge prepares the executor packet, Claude Code executes inside the allowed scope, validations run, ChatGPT/Codex audits the evidence, and GitHub preserves the final trail.

This launch must remain low blast radius. It proves the runtime loop by asking Claude Code to write one repository evidence artifact only.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-live-antigravity-executor-handoff.md
- docs/specbridge-operational-autonomy-policy-closure.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/61

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task invokes a live Claude Code executor from the local Antigravity workspace
- executor write scope is limited to one evidence artifact
- no product runtime code, dependency installation, secrets, production configuration, billing, auth security, database, deployment, MCP server, GitHub App, or hosted dashboard work is authorized

## Allowed Scope

```text
.specbridge/contracts/issue-061-controlled-antigravity-runtime-launch.execution.md
.specbridge/scopes/issue-061-controlled-antigravity-runtime-launch.scope.json
.specbridge/executor-handoffs/issue-061-controlled-antigravity-runtime-launch.input.json
.specbridge/executor-packets/issue-061-controlled-antigravity-runtime-launch-claude-runtime.executor-packet.json
.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md
.specbridge/runtime-evidence/issue-061-controlled-antigravity-runtime-launch.claude-run.json
.specbridge/reports/issue-061-controlled-antigravity-runtime-launch.final-report.json
.specbridge/audit-packets/issue-061-controlled-antigravity-runtime-launch.audit-packet.json
.specbridge/audits/issue-061-controlled-antigravity-runtime-launch.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
docs/specbridge-controlled-antigravity-runtime-launch.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-test-results.md
README.md
specs/004-acceptance-tests.md
scripts/test-specbridge-branch-orchestration.ps1
GitHub issue 61
GitHub pull request for this branch
```

Claude Code executor exclusive write scope:

```text
.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
src/**
app/**
apps/**
packages/**
lib/**
server/**
client/**
package installation
dependency installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD permission escalation
CI/CD security weakening
branch protection weakening
raw protected credential capture
raw file content capture
production deployment
destructive infrastructure operation
unrestricted shell execution
modifying files outside the Claude Code executor exclusive write scope during the executor run
```

## Acceptance Criteria

- Claude Code CLI availability is verified.
- Antigravity workspace availability is verified.
- SpecBridge creates an executor handoff packet for issue 061.
- Claude Code is invoked non-interactively from the repository workspace.
- Claude Code modifies only `.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md`.
- The Claude executor output records task id, contract id, allowed scope, blocked scope, command evidence, validation expectation, and completion status.
- Runtime launch evidence is recorded in `.specbridge/runtime-evidence/issue-061-controlled-antigravity-runtime-launch.claude-run.json`.
- Branch orchestration smoke coverage remains deterministic when `.specbridge/executor-packets/` contains packets for more than one task id.
- Local validation passes.
- ChatGPT/Codex audit records spec compliance, acceptance criteria, policy boundaries, security rules, changed file scope, test evidence, CI evidence, and final report honesty.
- GitHub CI passes on the PR.
- Merge happens only after required gates pass.
- No secrets, production configuration, billing, auth security, dependency installation, CI/CD weakening, branch protection weakening, database change, or deployment automation are involved.

## Required Validations

```powershell
claude --version
antigravity --help
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 prepare-executors -InputPath .specbridge/executor-handoffs/issue-061-controlled-antigravity-runtime-launch.input.json -OutputDirectory .specbridge/executor-packets -BranchPrefix claude -Force
claude -p --no-session-persistence --max-budget-usd 0.25 --permission-mode acceptEdits --tools "Read,Write" --allowedTools "Read,Write" "<bounded executor prompt>"
powershell -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if Claude Code cannot run non-interactively, attempts to modify files outside its exclusive write scope, requires secrets or credentials, requires production configuration, requires billing changes, requires authentication or authorization security changes, requires dependency installation, requires CI/CD security changes, requires branch protection weakening, requires database changes, requires deployment automation, requires unrestricted shell execution, or cannot complete inside the declared contract.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, audit packet validation, ChatGPT audit validation, or scope validation.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, Claude Code launch evidence, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when Claude Code has produced the allowed executor output artifact, runtime launch evidence is recorded, local validations pass, final report and audit evidence validate, CI passes on GitHub, and the pull request is merged by policy gates.
