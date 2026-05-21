# Execution Contract: Issue 60 Controlled GitHub Evidence Run

## Contract Metadata

- contract_id: issue-060-controlled-github-evidence-run
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/60
- created_by: ChatGPT/Codex
- created_at: 2026-05-21
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run the first controlled GitHub evidence proof for SpecBridge branch-per-executor orchestration by creating real executor branches and child pull requests, collecting CI and ChatGPT/Codex audit evidence, and coordinating those records in GitHub evidence mode.

## Context

Issue 059 implemented deterministic branch plans and coordinator simulation evidence. The next product proof must replace simulation-only records with real GitHub child PR URLs, real CI status, and explicit ChatGPT/Codex audit status without launching live Antigravity sessions or letting simulated evidence authorize integration.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json
- .specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-a-implementation.executor-packet.json
- .specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-b-tests.executor-packet.json
- .specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-c-documentation.executor-packet.json
- docs/specbridge-branch-per-executor-orchestration.md
- docs/specbridge-autonomy-backlog.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task creates controlled GitHub child branches and child PRs for already defined executor packets
- the task updates deterministic local coordination and validation behavior
- live Antigravity session launch, live Claude Code process launch, product runtime implementation, protected credential access, production deployment, dependency installation, hosted dashboard implementation, MCP runtime, GitHub App runtime, and child PR merge remain blocked

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/validate-branch-orchestrations.ps1
scripts/test-specbridge-branch-orchestration.ps1
scripts/test-specbridge-cli.ps1
.specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json
.specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json
.specbridge/orchestrations/issue-060-controlled-github-evidence-run.executor-orchestration.json
.specbridge/contracts/issue-060-controlled-github-evidence-run.execution.md
.specbridge/scopes/issue-060-controlled-github-evidence-run.scope.json
.specbridge/reports/issue-060-controlled-github-evidence-run.final-report.json
.specbridge/audit-packets/issue-060-controlled-github-evidence-run.audit-packet.json
.specbridge/audits/issue-060-controlled-github-evidence-run.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
docs/specbridge-controlled-github-evidence-run.md
docs/specbridge-local-cli.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-test-matrix.md
docs/specbridge-test-results.md
README.md
specs/004-acceptance-tests.md
GitHub branches claude/issue-058-live-antigravity-executor-handoff-agent-a-implementation, claude/issue-058-live-antigravity-executor-handoff-agent-b-tests, and claude/issue-058-live-antigravity-executor-handoff-agent-c-documentation
GitHub pull requests 56, 57, and 58
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
live Antigravity session launch
live Claude Code process launch
merging child executor PRs
merging based on simulated evidence
production deployment
```

## Acceptance Criteria

- One real GitHub branch exists for each issue 058 executor packet.
- One real GitHub child PR exists for each executor branch.
- Child PR evidence records PR URL, PR number, PR status, head SHA, CI status, CI run ids, and ChatGPT/Codex audit status.
- `scripts/specbridge.ps1` supports `record-github-evidence`.
- `record-github-evidence` reads a branch plan and declared GitHub evidence JSON, rejects simulation URLs, and writes an evidence-recorded branch plan.
- `coordinate-executors -EvidenceMode github` marks integration ready only when every child result has a real GitHub PR URL, passed CI, and approved ChatGPT/Codex audit status.
- `scripts/validate-branch-orchestrations.ps1` validates GitHub evidence mode records and rejects incomplete real evidence.
- `scripts/test-specbridge-branch-orchestration.ps1` covers GitHub evidence recording, ready integration, and simulation URL rejection.
- `scripts/test-specbridge-cli.ps1` covers the `record-github-evidence` command.
- Documentation, acceptance criteria, test matrix, test results, final report, audit packet, and ChatGPT audit are updated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-github-evidence -InputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json -EvidencePath .specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json -OutputPath .specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json -Force
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 coordinate-executors -InputPath .specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json -OutputPath .specbridge/orchestrations/issue-060-controlled-github-evidence-run.executor-orchestration.json -EvidenceMode github -Force
powershell -ExecutionPolicy Bypass -File ./scripts/validate-branch-orchestrations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-branch-orchestration.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires protected credential access, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD permission escalation, CI/CD security weakening, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, dependency installation, live Antigravity session launch, live Claude Code process launch, child PR merge, autonomous deployment, raw protected credential capture, or merge based on simulated evidence.

## Merge Policy

Gate-controlled automatic merge is allowed for the parent SpecBridge evidence PR only after required gates pass.

Child executor PRs remain evidence records and must not be merged by this contract.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, branch orchestration validation, branch orchestration tests, audit packet validation, ChatGPT audit validation, or scope validation.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, child PR evidence, policy result, risk result, unresolved risks, merge status, deployment status, rollback notes if applicable, and completion status.

## Completion Rule

This task is complete only when real child branches and child PRs are recorded, child CI and ChatGPT/Codex audit evidence are captured, GitHub evidence mode marks integration ready, local validation evidence is recorded, final report and audit evidence validate, CI passes on the parent PR, and the parent pull request is merged by policy gates.
