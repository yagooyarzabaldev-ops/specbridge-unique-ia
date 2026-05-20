# SpecBridge MVP Operating Runbook

## Purpose

This runbook defines the complete repository-first MVP operating loop.

It is the operational source of truth for running SpecBridge before a hosted service, real MCP server, or production automation exists.

## Required Inputs

Every MVP task requires:

- a GitHub issue or local task identifier
- structured context package under `.specbridge/context/`
- execution contract under `.specbridge/contracts/`
- declared autonomy profile
- declared risk level
- allowed scope
- blocked scope
- acceptance criteria
- required validations
- final report requirements

## Operating Loop

1. Capture the user goal in structured context.
2. Create or update an execution contract.
3. Confirm allowed scope and blocked scope.
4. Classify risk using `.specbridge/risk-rules.yaml`.
5. Execute only inside the contract.
6. Add or update evidence artifacts.
7. Run required validations.
8. Generate or update the final report.
9. Run the deterministic smoke validation.
10. Open a pull request when branch evidence is ready.
11. Require CI and review gates before merge.
12. Merge automatically only when policy explicitly allows it and all required gates pass.

## Required Local Validations

Use this command set for MVP repository validation:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## CI Gates

The MVP expects pull requests to preserve these gates:

- Foundation Validation
- SpecBridge Review Gate
- SpecBridge PR Review Report
- non-blocking Claude review when configured

CI evidence is required before merge. Local validation output is useful but does not replace CI evidence.

## Completion Standard

A task is complete only when:

- all changes stayed inside allowed scope
- no blocked scope was modified
- required validations passed
- final report exists and validates
- unresolved risks are explicitly listed
- merge status is explicit
- deployment status is explicit
- merge authority follows the active policy and all required gates

## Failure Handling

Stop and report `BLOCKED` when:

- secrets are required
- production configuration is required
- CI/CD security controls must change
- billing or payment provider configuration is required
- destructive database operations are required
- blocked files or commands are required
- acceptance criteria contradict policy
- validation cannot pass after reasonable fixes

## MVP Boundary

The MVP is repository-first.

It does not require:

- SaaS dashboard
- database
- hosted API
- production deployment
- real MCP server
- autonomous merge without required gates
- unrestricted terminal execution
