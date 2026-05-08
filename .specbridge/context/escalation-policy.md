# SpecBridge Escalation Policy

Escalations prevent Claude Code from asking ad-hoc permission from the programmer or improvising outside policy.

Escalations are prepared for ChatGPT review unless the policy explicitly requires human approval.

## Escalation File Location

```text
.specbridge/escalations/
```

Recommended filename:

```text
issue-XX-<short-reason>.escalation.md
```

## Required Escalation Fields

Each escalation must include issue number, contract id, reason for escalation, blocked or ambiguous item, affected files, risk level, options considered, recommended decision, required approver, and stop status.

Claude Code must stop after creating the escalation.
