# SpecBridge Standard Templates

## Purpose

Standard templates give future agents a consistent starting point for SpecBridge
tasks without copying raw chat history or inventing artifact shapes.

## Template Set

The official templates live under:

```text
templates/specbridge/
```

Required templates:

- `execution-contract.template.md`
- `scope-manifest.template.json`
- `executor-handoff.template.json`
- `runtime-launch.template.json`
- `final-report.template.json`
- `audit-packet.template.json`
- `chatgpt-audit.template.json`

## Rules

Templates must:

- include `{{TASK_ID}}`
- remain direct and operational
- avoid secrets and credentials
- define scope before execution
- preserve auditability
- keep merge and deployment policy explicit

JSON templates must remain parseable after placeholder substitution.

## Validation

Templates are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-standard-templates.ps1
```

The validator checks required template presence, non-empty content, `{{TASK_ID}}`
coverage, and JSON parseability after placeholder substitution.
