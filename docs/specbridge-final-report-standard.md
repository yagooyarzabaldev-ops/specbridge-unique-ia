# SpecBridge Final Report Standard

## Purpose

Every controlled SpecBridge execution must leave a final report that can be inspected by a human and validated by automation.

The final report is the execution receipt. It records what changed, which validations ran, whether policy boundaries were respected, and whether any residual risk remains.

## File Location

Final reports must be stored under:

```text
.specbridge/reports/
```

The required filename pattern is:

```text
*.final-report.json
```

## Required Fields

Each final report must include:

```json
{
  "summary": "Short execution summary.",
  "changed_files": ["path/to/file"],
  "validations": ["validation command or validation result"],
  "policy_result": "Policy boundary result.",
  "risk_result": "Risk assessment result.",
  "completion_status": "completed"
}
```

## Optional Fields

A final report may also include:

```json
{
  "unresolved_risks": [],
  "merge_status": "merged",
  "deployment_status": "not_applicable"
}
```

## Validation Command

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
```

## Boundary

This standard does not activate live Claude Code execution, Codex review, MCP servers, production deployment, runtime application code, or secrets.

## Completion Rule

A SpecBridge task is not complete until its final report is present, valid, and consistent with the related execution contract.
