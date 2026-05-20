# SpecBridge Audit Packet Generator

## Purpose

The audit packet generator creates the evidence bundle ChatGPT/Codex uses to audit Claude Code output against the active execution contract.

It converts existing repository evidence into a deterministic JSON packet. The packet references source files by path and summarizes diff line counts, validations, CI status, policy result, risks, and completion status.

## Command

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/generate-audit-packet.ps1 `
  -TaskId "issue-000-example" `
  -ExecutionContractPath ".specbridge/contracts/issue-000-example.execution.md" `
  -FinalReportPath ".specbridge/reports/issue-000-example.final-report.json" `
  -CiStatus "not_collected"
```

Optional inputs:

- `-PrReviewReportPath` points to `.specbridge/review-reports/*.review-report.json` when review evidence exists.
- `-OutputDirectory` defaults to `.specbridge/audit-packets`.
- `-OutputFileName` defaults to `<TaskId>.audit-packet.json`.
- `-BaseRef` and `-HeadRef` allow deterministic Git diff summaries when a comparison range is available.

## Packet Fields

Required packet fields:

- `schema_version`
- `task_id`
- `generated_by`
- `execution_contract_path`
- `changed_files`
- `diff_summary`
- `validation_commands`
- `validation_results`
- `final_report_path`
- `ci_status`
- `pr_review_report_path`
- `policy_result`
- `unresolved_risks`
- `completion_status`
- `source_files`
- `secret_omission`

## Determinism Rules

The generator avoids timestamps and raw file contents.

It sorts changed files, validation commands, and source file references so repeated generation from the same inputs produces stable output.

Diff summaries are line-count summaries only. If Git history is unavailable for a referenced file, the file remains in the packet with `null` line counts instead of embedding raw diff content.

## Secret Omission

Audit packets must not include:

- raw diffs
- file contents
- secrets
- tokens
- private keys
- credential values

The packet is an evidence index and summary, not a repository archive.

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
```

The validator checks required fields, path shape, validation summaries, CI status, diff summary structure, and forbidden raw/sensitive content fields.

## Audit Use

ChatGPT/Codex should use the audit packet to check:

- whether changed files match the execution contract
- whether validations were run and recorded
- whether CI status is present
- whether policy result and unresolved risks are explicit
- whether final report evidence is complete enough for independent review
