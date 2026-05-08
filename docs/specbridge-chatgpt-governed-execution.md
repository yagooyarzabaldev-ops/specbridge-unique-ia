# SpecBridge ChatGPT-Governed Claude Execution

## Product Thesis

SpecBridge exists so the human does not have to manually negotiate with Claude Code.

ChatGPT governs.

Claude Code executes.

SpecBridge controls.

GitHub audits.

## Operating Model

```text
User / client intent
  -> ChatGPT
  -> SpecBridge issue and execution contract
  -> Claude Code in Antigravity
  -> validations and final report
  -> GitHub PR and CI
  -> ChatGPT audit
  -> human final merge or decision
```

## Autonomy Principle

Claude Code should not ask for permission when the contract already grants permission.

Claude Code should ask no one directly when the contract does not grant permission.

It should escalate structurally.

## Human Role

The human intervenes for final merge, production deployment, secrets, billing/provider changes, destructive operations, and high-risk architectural decisions.
