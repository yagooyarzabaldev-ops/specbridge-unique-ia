# SpecBridge Audit Packet Standard

The audit packet is the evidence bundle ChatGPT uses to audit Claude Code execution.

## Required Inputs

A complete audit packet includes GitHub issue, execution contract, changed files list, final report JSON, validation output summary, PR review report when available, escalation files when created, unresolved risks, and completion status.

## ChatGPT Audit Outcomes

Allowed audit outcomes:

```text
approved
changes_requested
blocked
needs_human_decision
```
