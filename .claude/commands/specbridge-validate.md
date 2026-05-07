# /specbridge-validate

Run the standard SpecBridge validation gates.

## Purpose

Use this command before reporting a foundation task as complete.

## Steps

1. Run foundation validation.
2. Run contract validation.
3. Report exact command output.
4. Do not claim success unless both validations pass.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
```

## Output Requirement

Report:

- command executed
- pass/fail status
- failure lines, if any
- files changed since last validation
