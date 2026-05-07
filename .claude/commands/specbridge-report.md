# /specbridge-report

Generate a SpecBridge final report for the active task.

## Purpose

Use this command after validation has passed and before requesting merge.

## Required Report Sections

- summary
- changed files
- validations executed
- validation result
- policy result
- risk result
- unresolved risks
- merge status
- deployment status
- rollback notes, if applicable

## Rules

- Do not omit failed validations.
- Do not say validation passed unless command output proves it.
- Do not report deployment if no deployment occurred.
- Do not hide unresolved risks.

## Source Template

Use `.specbridge/report-template.md` as the report shape.