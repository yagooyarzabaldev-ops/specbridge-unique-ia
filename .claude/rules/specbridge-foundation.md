---
paths:
  - "**/*"
---

# SpecBridge Foundation Rule

Claude Code must treat this repository as a Spec Driven Development project.

Before changing files, read:

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.specbridge/policy.yaml`
- `.specbridge/autonomy.yaml`
- `.specbridge/risk-rules.yaml`

## Operating Rules

- Work from execution contracts when they exist.
- Keep changes inside the declared allowed scope.
- Do not modify blocked scope.
- Do not add product implementation code during foundation phase.
- Prefer small, reviewable diffs.
- Report validation evidence, not confidence.

## Required Validation

For foundation work, run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
```

## Stop Conditions

Stop when policy, risk, or acceptance criteria are unclear.

Stop when a task requires secrets, production changes, destructive operations, billing changes, or blocked scope changes.