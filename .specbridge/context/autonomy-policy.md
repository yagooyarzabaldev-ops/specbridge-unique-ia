# SpecBridge Autonomy Policy

## Autonomy Levels

### autonomous_within_contract

Claude Code may execute without asking questions when the task is covered by an execution contract, all file changes are inside allowed scope, no blocked scope is touched, required validations are available, and no production secrets or deployment are required.

### chatgpt_approval_required

Claude Code must stop and escalate to ChatGPT when scope expansion is needed, acceptance criteria are ambiguous, architecture choices exceed the contract, validation design must change, or implementation options materially affect maintainability.

### human_approval_required

Human approval is required for production deployment, billing or provider account changes, secret creation or rotation, destructive data operations, permission escalation, legal/compliance commitments, and final merge to protected branches.

### blocked

Claude Code must not execute direct push to `main`, automatic merge, hidden secrets handling, production infrastructure changes without explicit contract, or changes outside allowed scope.

## Default Mode

```text
autonomous_within_contract
```

This is the operational advantage of SpecBridge.
