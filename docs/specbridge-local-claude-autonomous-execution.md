# SpecBridge Local Claude Code Autonomous Execution

## Pilot Purpose

This document records the first verified local execution of the SpecBridge autonomous ChatGPT-governed Claude Code execution protocol inside Antigravity.

The pilot proves that Claude Code can receive a governed task from ChatGPT, execute it autonomously inside a contract, run required validations, and produce evidence — without asking the programmer for ad-hoc permission.

## Operating Model

```text
ChatGPT
  governs intent, architecture, scope, audit

SpecBridge
  converts intent into execution contract and enforces policy

Claude Code
  executes autonomously inside allowed scope

GitHub
  validates evidence through CI and PR audit trail

Human
  retains final merge and high-risk decision authority
```

## Role: ChatGPT Developer / Governor

ChatGPT is the primary developer-governor.

ChatGPT transforms user or client intent into governed executable work.

ChatGPT owns:

- requirement interpretation
- coherence filtering
- architecture decisions
- issue decomposition
- execution contract creation
- allowed scope definition
- blocked scope definition
- acceptance criteria
- validation strategy
- escalation decisions
- audit of final execution evidence

## Role: Claude Code Executor

Claude Code is the technical executor for SpecBridge tasks inside Antigravity.

Claude Code executes the approved execution contract autonomously within allowed scope.

Claude Code must not negotiate routine implementation details with the programmer when the execution contract already authorizes the work.

Claude Code must escalate structurally to ChatGPT instead of asking the programmer for ad-hoc permission when a policy boundary is reached.

## Autonomy Principle

```text
autonomous_within_contract
```

Claude Code may execute without asking questions when:

- the task is covered by an execution contract
- all file changes are inside allowed scope
- no blocked scope is touched
- required validations are available
- no production secrets or deployment are required

## Escalation Instead of Ad-Hoc Permission

Claude Code must not ask the programmer for permission when the correct route is ChatGPT escalation.

Escalation triggers:

- scope expansion is needed
- acceptance criteria are ambiguous
- architecture choices exceed the contract
- validation design must change
- implementation options materially affect maintainability
- blocked scope is required
- critical information is missing

When triggered, Claude Code must stop, create an escalation file in `.specbridge/escalations/`, and halt execution.

## Blocked Behavior

Claude Code must never:

- push directly to `main`
- merge pull requests autonomously
- touch secrets or credentials
- modify production infrastructure
- claim completion without evidence
- ask the programmer for ad-hoc permissions when ChatGPT escalation is the correct route
- silently skip validations

## GitHub as Evidence Validator

GitHub validates evidence through:

- CI runs required validations on every push
- PR review enforces quality gates
- Commit history preserves audit trail
- Issue tracker records task state

A task is not complete because an agent says it is complete.

A task is complete when the repository evidence says it is complete.

## Human Ownership

The human retains final authority for:

- merge to protected branches
- production deployment
- secret creation or rotation
- billing or provider account changes
- destructive data operations
- permission escalation
- legal or compliance commitments

SpecBridge does not remove control. It moves control from constant human interruption to explicit policy, contract, CI, review, and auditability.

## Audit Packet

When ChatGPT audits Claude Code execution, the audit packet includes:

- GitHub issue
- execution contract
- changed files list
- final report JSON
- validation output summary
- PR review report when available
- escalation files when created
- unresolved risks
- completion status

Allowed audit outcomes: `approved`, `changes_requested`, `blocked`, `needs_human_decision`.

## Pilot Result

This document is itself the evidence artifact for GitHub issue #40.

Claude Code executed autonomously inside the contract, produced the required artifacts, ran the required validations, and stopped before push or merge — as the protocol requires.
