# /sb-review

Produce the machine-validated review-agent report required before the reviewer handoff.

## Arguments

`$ARGUMENTS` = `<task-id>` (verdict and findings come from the actual review)

## Steps

1. Review the full diff of the task branch against main (`git diff main...HEAD`).
2. Record every real finding as `severity|file|summary` where severity is `info`, `minor`, `major` or `blocker`.
3. Choose the verdict honestly: `approve` only if there are no blockers and the diff matches the contract scope; otherwise `block`.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-review-report -TaskId <task-id> -Verdict <approve|block> -Summary "<what was reviewed and the basis for the verdict>" -Validation "severity|file|summary","severity|file|summary"
```

Note: `-Validation` is an array parameter; pass multiple findings comma-separated. Repeating the flag fails in PowerShell with "parameter specified more than once". When invoking from a non-PowerShell shell (bash, cmd), `powershell -File` flattens the commas into one string; use the `-Command` form instead so the array survives:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ./scripts/specbridge.ps1 specbridge-review-report -TaskId <task-id> -Verdict approve -Summary '<summary>' -Validation @('severity|file|summary','severity|file|summary')"
```

## Rules

- A `blocker` finding with verdict `approve` fails by design; fix the code or block.
- The report is consumed by the reviewer handoff gate and validated by `validate-agent-review-reports.ps1` in smoke.
- Never write the report file by hand; the command records run_id, reviewed_commit and a ledger entry.

## Output Requirement

Report verdict, finding count, blocker count and the report path.
