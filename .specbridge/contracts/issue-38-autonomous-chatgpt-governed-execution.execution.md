# Execution Contract: Issue 38

## Contract Metadata

- contract_id: issue-38-autonomous-chatgpt-governed-execution
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/38
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: medium
- status: draft

## Goal

Add the autonomous ChatGPT-governed Claude execution protocol.

## Context

SpecBridge's product value is to reduce human friction when using Claude Code. ChatGPT should transform user intent into governed executable work. Claude Code should execute autonomously inside Antigravity when inside contract and escalate only when policy requires it.

## Source References

- GitHub issue #38
- docs/specbridge-chatgpt-governed-execution.md
- .specbridge/context/autonomy-policy.md

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
medium
```

Reason:

- defines autonomy policy
- does not execute production changes
- does not grant autonomous merge
- does not grant autonomous push to main
- keeps human ownership of high-risk decisions

## Allowed Scope

```text
.specbridge/context/**
.claude/commands/**
.claude/rules/**
docs/specbridge-chatgpt-governed-execution.md
scripts/validate-autonomous-execution-protocol.ps1
scripts/specbridge-smoke.ps1
.github/workflows/foundation-validation.yml
.specbridge/contracts/**
.specbridge/reports/**
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
application source code
runtime framework setup
package installation
deployment automation
database schema implementation
autonomous merge
autonomous push to main
MCP server implementation
removing human ownership of final merge decisions
```

## Acceptance Criteria

- ChatGPT developer/governor role document exists.
- Claude Code executor role document exists.
- Autonomy policy exists.
- Escalation policy exists.
- Audit packet standard exists.
- Claude local execution command exists.
- Claude escalation command exists.
- Claude autonomous execution rule exists.
- Main workflow validates the autonomous protocol.
- Smoke validation includes the autonomous protocol validator.
- All required validations pass.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
```

## Stop Conditions

Execution must stop if the implementation requires secrets, production deployment, runtime application code, autonomous merge, autonomous push to main, MCP implementation, or removing human ownership of final merge decisions.

## Merge Policy

Human-controlled merge.

## Deployment Policy

No deployment is allowed for this task.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include summary, changed files, validation result, policy result, risk result, unresolved risks, and completion status.

## Completion Rule

This task is complete only when the protocol exists, validation passes locally, CI passes, and the PR is merged into `main`.
