# SpecBridge Controlled E2E Pilot

## Purpose

This pilot proves that SpecBridge can run a complete controlled governance loop without activating live agent execution.

The controlled loop is:

1. Create a GitHub issue.
2. Create an execution contract.
3. Apply a branch-scoped change.
4. Produce a final report artifact.
5. Run deterministic local validations.
6. Open a pull request.
7. Require CI validation.
8. Merge only after human approval.

## Pilot Boundary

This pilot is intentionally limited to documentation and governance artifacts.

It does not activate:

- Claude Code execution workflows
- Codex review workflows
- MCP servers
- production deployment
- secrets or credentials
- application runtime code
- database schema implementation

## Pilot Inputs

- GitHub issue: `#24`
- Execution contract: `.specbridge/contracts/issue-24-controlled-e2e-pilot-task.execution.md`
- Final report: `.specbridge/reports/issue-24-controlled-e2e-pilot.final-report.json`

## Required Commands

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Expected Result

All local validations pass.

The pull request must also pass `Foundation Validation` before merge.

## Success Criteria

SpecBridge is considered ready for the next controlled phase when this pilot proves that a real task can move from issue to merge while leaving:

- a contract
- a final report
- deterministic validation output
- CI evidence
- no uncontrolled production or agentic side effects

## Next Phase After This Pilot

After this pilot, the next safe phase is to enable one non-executing or low-risk automated review path, preferably Claude/Codex review-only, not execution.

Execution automation remains blocked until review-only behavior is proven.
