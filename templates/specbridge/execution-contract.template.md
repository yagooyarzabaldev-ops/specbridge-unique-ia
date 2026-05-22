# Execution Contract: {{TASK_ID}}

## Contract Metadata

- contract_id: {{TASK_ID}}
- related_issue: {{RELATED_ISSUE_URL}}
- created_by: ChatGPT/Codex
- created_at: {{DATE}}
- autonomy_profile: full_autopilot
- risk_level: {{RISK_LEVEL}}
- status: ready_for_execution

## Goal

{{GOAL}}

## Context

{{CONTEXT}}

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml

## Allowed Scope

```text
{{ALLOWED_SCOPE}}
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
production configuration
billing
auth security
database destructive changes
CI/CD security weakening
deployment automation
```

## Acceptance Criteria

{{ACCEPTANCE_CRITERIA}}

## Required Validations

```powershell
{{REQUIRED_VALIDATIONS}}
```

## Stop Conditions

Stop on policy conflict, scope conflict, missing required context, impossible acceptance criteria, protected resources, secrets, production, billing, auth security, database destructive changes, CI/CD security changes, or deployment automation.

## Merge Policy

Automatic merge is allowed only after required local validations, GitHub CI, review gate, security gate, audit packet validation, ChatGPT/Codex audit, and policy checks pass.

## Deployment Policy

No production deployment is allowed unless a future contract explicitly authorizes it.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, review result, merge status, deployment status, unresolved risks, and rollback notes.
