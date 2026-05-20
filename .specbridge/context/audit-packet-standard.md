# SpecBridge Audit Packet Standard

The audit packet is the evidence bundle ChatGPT uses to audit Claude Code execution.

## Required Inputs

A complete audit packet includes GitHub issue, execution contract, changed files list, final report JSON, validation output summary, PR review report when available, escalation files when created, unresolved risks, and completion status.

## Required Packet Fields

Machine-readable audit packets must include:

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

Packets must reference files by repository-relative path.

Packets must not embed raw diffs, file contents, secrets, tokens, private keys, or credential values.

## ChatGPT Audit Outcomes

Allowed audit outcomes:

```text
approved
changes_requested
blocked
needs_human_decision
```
