# Execution Contract: Example Issue 003

## Contract Metadata

- contract_id: example-issue-003

- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/3

- created_by: ChatGPT/Codex

- created_at: 2026-05-03

- autonomy_profile: vibe_autopilot

- risk_level: low

- status: draft

## Goal

Add a standard example execution contract instance for concrete SpecBridge tasks.

## Context

SpecBridge already defines a reusable execution contract template at:

- `.specbridge/execution-contract-template.md`

The project now needs an example contract instance under:

- `.specbridge/contracts/`

This file demonstrates the expected structure of a task-specific contract that Claude Code can later consume as execution instructions.

This is foundation-phase work. No product implementation code should be added.

## Source References

- README.md

- SPECBRIDGE.md

- AGENTS.md

- CLAUDE.md

- .specbridge/policy.yaml

- .specbridge/autonomy.yaml

- .specbridge/risk-rules.yaml

- .specbridge/execution-contract-template.md

- specs/000-project-context.md

- specs/001-product-requirements.md

- specs/002-architecture.md

- specs/003-mvp-plan.md

- specs/004-acceptance-tests.md

- GitHub issue #3

## Autonomy Profile

```text

vibe_autopilot

```

Claude Code may perform ordinary foundation documentation work without asking for step-by-step permission.

## Risk Level

```text

low

```

Reason:

- documentation-only change

- no implementation code

- no secrets

- no production configuration

- no infrastructure change

- no database change

## Allowed Scope

```text

.specbridge/contracts/**

.specbridge/execution-contract-template.md

.specbridge/**

specs/**

README.md

SPECBRIDGE.md

AGENTS.md

CLAUDE.md

```

## Blocked Scope

```text

.env

.env.*

secrets/**

infra/prod/**

application source code

runtime framework setup

package installation

deployment automation

database schema implementation

```

## Acceptance Criteria

- `.specbridge/contracts/` exists.

- `.specbridge/contracts/example-issue-003.execution.md` exists.

- The contract references GitHub issue #3.

- The contract defines metadata, goal, context, source references, autonomy profile, risk level, allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, final report requirements, and completion rule.

- Foundation validation passes.

- No product implementation code is added.

## Required Validations

```powershell

powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1

```

## Stop Conditions

Execution must stop if any of the following occurs:

- secret access is required

- destructive database change is required

- production configuration change is required

- billing change is required

- critical authentication or authorization change is required

- CI/CD security change is required

- blocked scope must be modified

- acceptance criteria are contradictory

- acceptance criteria are impossible

- policy conflict is detected

- repeated validation failure cannot be resolved safely

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.

- CI passed.

- No protected files changed.

- No product implementation code added.

- PR references and closes GitHub issue #3.

## Deployment Policy

No deployment is allowed for this task.

```text

staging: disabled

production: disabled

```

## Final Report Requirements

The final report must include:

- summary

- changed files

- validation result

- policy result

- risk result

- unresolved risks

- merge status

- deployment status

- completion status

## Completion Rule

This task is complete only when the contract instance exists, validation passes, CI passes, and the PR is merged into `main`.

