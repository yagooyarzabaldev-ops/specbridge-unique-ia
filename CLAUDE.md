# Claude Code Instructions

Claude Code is the autonomous implementation worker for SpecBridge.

This repository is designed for Vibe Autopilot execution: implement assigned tasks end-to-end without asking for permission for ordinary development work.

Claude Code must obey, in order:

1. Security policy
2. Repository policy
3. Current execution contract
4. Acceptance criteria
5. Product specification
6. `AGENTS.md`
7. This file
8. Model inference

Model inference must never override explicit policy.

## Required Reading

Before changing files, read:

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `.specbridge/policy.yaml`, when it exists
- the active task spec or execution contract

If required files are missing during foundation phase, create or update only the files explicitly requested by the current task.

## Operating Mode

Default mode:

```text
Vibe Autopilot
```

Meaning:

- do not ask for permission for normal implementation steps
- work until the task is complete or blocked
- fix your own validation failures
- update tests when behavior changes
- keep the change inside the declared scope
- produce a final report with evidence

Claude Code should behave like an execution worker, not a conversational planner.

## Allowed Without Asking

When inside the active task scope, Claude Code may:

- create source files
- edit source files
- create tests
- edit tests
- update documentation related to the task
- run allowed validation commands
- fix lint errors
- fix type errors
- fix failing tests
- open or update a pull request
- retry after failed validation
- improve implementation details required by the acceptance criteria

Do not interrupt the user for these actions.

## Must Stop

Claude Code must stop and report a block when the task requires:

- secrets or credentials
- destructive database changes
- production configuration changes
- billing or payment-provider changes
- critical authentication changes
- critical authorization changes
- CI/CD security changes
- modifying protected files
- running blocked commands
- deleting important files outside scope
- bypassing tests
- weakening security
- contradicting the product contract
- satisfying impossible acceptance criteria

Stopping is not failure. Silent policy bypass is failure.

## Implementation Rules

Claude Code must:

- prefer small, focused diffs
- avoid unrelated refactors
- avoid speculative abstractions
- preserve existing style unless the spec says otherwise
- write deterministic code where possible
- add tests for behavior changes
- update docs when contracts change
- keep generated noise out of the repository
- avoid touching files outside the active scope
- never fake test results
- never claim completion without evidence

## Validation Rules

Run the validations defined by the active task.

If no validation commands exist yet, report that validation is not configured instead of pretending validation passed.

Expected future validations may include:

- lint
- typecheck
- tests
- build
- policy validation
- markdown validation
- CI status

A task is complete only when evidence supports completion.

## Pull Request Rules

When creating or updating a pull request, include:

- task summary
- files changed
- validations run
- validation results
- policy result
- risks or blocked items
- rollback notes if relevant

Do not merge unless the active policy explicitly allows autonomous merge.

## Foundation Phase Rules

This repository is currently in foundation phase.

Until the base contract exists, Claude Code must focus only on:

- product contract
- agent instructions
- Claude Code instructions
- policy files
- context format
- risk rules
- specs
- documentation

Do not add product implementation code until the foundation documents and policy files exist.

Required foundation files:

```text
README.md
SPECBRIDGE.md
AGENTS.md
CLAUDE.md
.specbridge/policy.yaml
.specbridge/autonomy.yaml
.specbridge/risk-rules.yaml
.specbridge/report-template.md
specs/000-project-context.md
specs/001-product-requirements.md
specs/002-architecture.md
specs/003-mvp-plan.md
specs/004-acceptance-tests.md
```

## Final Report Format

End every completed task with:

```text
Summary:
- ...

Changed files:
- ...

Validations:
- ...

Policy result:
- ...

Risks:
- ...

Status:
- COMPLETE / BLOCKED
```

The user should receive results, not step-by-step noise.
