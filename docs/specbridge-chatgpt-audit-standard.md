# SpecBridge ChatGPT Audit Standard

## Purpose

The ChatGPT audit is the independent review result used to judge whether Claude Code output satisfies the active SpecBridge contract.

It consumes an audit packet and records a machine-readable decision before merge.

## Audit Outcomes

Allowed outcomes:

- `approved`
- `changes_requested`
- `blocked`
- `needs_human_decision`

Only `approved` may set `merge_allowed` to `true`.

Any blocking finding or blocking checked dimension must set `merge_allowed` to `false`.

## Required Dimensions

Every audit must explicitly check:

- `spec_compliance`
- `acceptance_criteria`
- `policy_boundaries`
- `security_rules`
- `changed_file_scope`
- `test_evidence`
- `ci_evidence`
- `final_report_honesty`

Each dimension records:

- `name`
- `result`
- `evidence`
- `blocking`

Allowed dimension results:

- `pass`
- `fail`
- `needs_human_decision`
- `not_applicable`

## Finding Format

Each finding records:

- `severity`
- `category`
- `file`
- `line`
- `evidence`
- `recommendation`
- `blocking`

Allowed severities:

- `info`
- `low`
- `medium`
- `high`
- `critical`

`line` may be `null` when the finding applies to a whole file or artifact.

## Merge Rules

The audit validator enforces:

- `approved` requires every dimension to pass
- `approved` requires `merge_allowed: true`
- `changes_requested`, `blocked`, and `needs_human_decision` require `merge_allowed: false`
- blocking findings or blocking dimensions always prevent merge
- `blocked` requires at least one blocking finding or dimension
- `needs_human_decision` requires at least one dimension with `needs_human_decision`

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
```

The validator checks `.specbridge/audits/*.chatgpt-audit.json`.

## Product Use

In the full SpecBridge loop:

1. SpecBridge generates an audit packet.
2. ChatGPT/Codex reviews the packet against specs, policy, security, CI, and final report evidence.
3. ChatGPT/Codex writes a ChatGPT audit artifact.
4. SpecBridge blocks merge unless the audit is approved and all required gates pass.

This turns review into repository evidence instead of conversational confidence.
