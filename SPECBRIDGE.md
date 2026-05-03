# SpecBridge Technical Contract



SpecBridge is a connector and orchestration layer that converts ChatGPT/Codex context into autonomous Claude Code execution.



Its purpose is to let users delegate software development work without approving every individual implementation step, while keeping execution governed by explicit context, policy, CI, review, and auditability.



## Core Operating Model



SpecBridge operates through four main layers:



```text

ChatGPT / Codex

  defines intent, context, specs, and acceptance criteria



SpecBridge

  converts context into an execution contract and enforces policy



Claude Code

  executes implementation autonomously inside the allowed scope



GitHub + CI

  records state, validates changes, reviews output, and preserves audit trail


```

## Default Mode: Vibe Autopilot

The primary mode of SpecBridge is Vibe Autopilot.

In this mode, Claude Code must not ask the user for approval for normal implementation decisions.

Claude Code is expected to:

- create and modify files within the allowed scope
- add or update tests
- run allowed commands
- fix lint failures
- fix type errors
- fix failing tests
- update its own pull request
- continue until the task is complete or blocked by policy

## Non-Interruption Rule

The system should not interrupt the user for ordinary development work.

Do not ask the user before:

- creating a normal source file
- updating a normal source file
- adding a test
- fixing a test
- fixing lint
- fixing type errors
- updating documentation related to the current task
- opening a pull request
- updating a pull request
- retrying after a failed validation

Interrupt only when required by policy, risk, contradiction, or missing critical information.

## Stop Conditions

SpecBridge must stop autonomous execution when any of the following is required:

- access to secrets
- destructive database change
- production configuration change
- billing or payment-provider change
- critical authentication or authorization change
- CI/CD security change
- deletion of important files outside the task scope
- unclear ownership of a risky decision
- contradictory specification
- impossible acceptance criteria
- policy violation
- repeated execution failure after reasonable retries

## Control Hierarchy

When instructions conflict, the following order applies:

1. Security policy
2. Repository policy
3. Current execution contract
4. Acceptance criteria
5. Product specification
6. Agent-specific instructions
7. Model inference

A model must never override policy by inference.

## Context Package

SpecBridge must not send raw ChatGPT conversations directly to Claude Code.

Instead, context must be converted into structured repository files.

Expected context files:

```text
.specbridge/context/CODEX_CONTEXT.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/context/DO_NOT_TOUCH.md
.specbridge/context/STYLE_GUIDE.md
```

The context package must be:

- explicit
- minimal
- task-relevant
- versioned
- auditable
- free of secrets
- free of irrelevant conversation noise

## Execution Contract

Every autonomous execution must have an execution contract.

The execution contract must define:

- task goal
- allowed scope
- blocked scope
- acceptance criteria
- required validations
- stop conditions
- reporting format
- merge policy
- deployment policy, if applicable

No autonomous task should run without a clear execution contract.

## Risk Levels

### Low Risk

Examples:

- documentation
- tests
- isolated UI changes
- small bug fixes
- non-critical refactors

Low-risk tasks may run fully automatically.

### Medium Risk

Examples:

- business logic
- API endpoints
- internal data model changes
- non-destructive migrations
- integration logic

Medium-risk tasks may run automatically if policy allows.

### High Risk

Examples:

- authentication
- authorization
- infrastructure
- production configuration
- database migrations
- CI/CD changes

High-risk tasks require stricter policy gates.

### Critical Risk

Examples:

- secrets
- billing
- destructive database operations
- production data deletion
- irreversible infrastructure changes
- disabling security controls

Critical-risk tasks must not run automatically unless explicitly enabled by a dedicated policy profile.

## Quality Gates

Before a task can be considered complete, the configured quality gates must pass.

Expected gates:

- lint
- typecheck
- tests
- build
- policy validation
- Codex review
- CI status

A task is not done because an agent says it is done.

A task is done when the repository evidence says it is done.

## Merge Policy

Autonomous merge is allowed only when policy explicitly allows it.

Minimum merge conditions:

- CI passed
- required tests passed
- no protected files changed
- no policy violation detected
- Codex review passed or found no blocking issues
- task remained inside the approved scope
- risk level is allowed by the selected autonomy profile

Claude Code should not be the final authority for merging.

SpecBridge policy decides whether merge is allowed.

## Deployment Policy

Deployment must be separated by environment.

Default policy:

```text
staging: automatic if enabled and all gates pass
production: manual unless explicitly enabled
```

Production autonomy must be treated as a separate permission profile.

## Agent Responsibilities

### ChatGPT / Codex

Responsible for:

- understanding user intent
- creating structured context
- defining specs
- defining acceptance criteria
- identifying contradictions
- reviewing implementation
- detecting deviation from the agreed spec

### SpecBridge

Responsible for:

- preparing execution contracts
- enforcing policy
- coordinating GitHub state
- coordinating autonomous execution
- reading CI and review results
- deciding whether merge is allowed
- generating final reports

### Claude Code

Responsible for:

- implementing the assigned task
- following the execution contract
- respecting allowed and blocked scopes
- running allowed validations
- fixing its own implementation problems
- stopping when policy requires it
- reporting what changed and what evidence validates it

### GitHub

Responsible for:

- issue tracking
- branch state
- pull request workflow
- CI execution
- review history
- audit trail

## Final Report

At the end of an execution, SpecBridge must produce a final report.

The report should include:

- task summary
- files changed
- validations executed
- CI status
- Codex review result
- policy result
- merge status
- deployment status, if applicable
- unresolved risks
- rollback notes, if applicable

The user should receive results, not step-by-step noise.

## MVP Scope

The first MVP must prove this flow:

```text
1. Store structured ChatGPT/Codex context in the repository.
2. Create an executable task contract.
3. Trigger Claude Code execution.
4. Let Claude Code work without step-by-step permission requests.
5. Run validation through CI.
6. Review the result with Codex.
7. Merge only if policy allows it.
8. Produce a final report.
```

## Design Invariants

SpecBridge must preserve these invariants:

- no raw conversation dump as execution context
- no secret exposure
- no unrestricted shell execution
- no production changes by default
- no merge without evidence
- no autonomous execution without policy
- no silent policy bypass
- no vague acceptance criteria
- no agent self-certification as the only proof of completion

