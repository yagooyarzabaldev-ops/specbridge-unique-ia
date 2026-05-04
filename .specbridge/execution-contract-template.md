# SpecBridge Execution Contract Template

This template defines the standard contract used to convert ChatGPT/Codex context into Claude Code execution.

An execution contract is required before autonomous implementation begins.

## Contract Metadata

- contract_id:

- related_issue:

- created_by:

- created_at:

- autonomy_profile:

- risk_level:

- status:

Allowed status values:

```text

draft

ready_for_execution

blocked

completed

cancelled

```

## Goal

Define the expected outcome clearly.

The goal must describe the final state, not the internal steps.

## Context

Provide distilled, task-relevant context.

Do not paste raw ChatGPT conversations.

Context must include only information required to execute the task safely and correctly.

## Source References

List the files, specs, issues, or decisions that define the task.

Expected references may include:

- README.md

- SPECBRIDGE.md

- AGENTS.md

- CLAUDE.md

- .specbridge/policy.yaml

- .specbridge/autonomy.yaml

- .specbridge/risk-rules.yaml

- specs/*

- related GitHub issue

## Autonomy Profile

Select one:

```text

assisted

vibe_autopilot

full_autopilot

```

Default:

```text

vibe_autopilot

```

## Risk Level

Select one:

```text

low

medium

high

critical

```

When unclear, classify as:

```text

high

```

## Allowed Scope

Define the files, directories, or areas the agent may modify.

Example:

```text

.specbridge/**

specs/**

docs/**

README.md

SPECBRIDGE.md

AGENTS.md

CLAUDE.md

```

## Blocked Scope

Define files, directories, or areas the agent must not modify.

Default blocked scope:

```text

.env

.env.*

secrets/**

infra/prod/**

application source code during foundation phase

runtime framework setup during foundation phase

package installation during foundation phase

deployment automation during foundation phase

database schema implementation during foundation phase

```

## Acceptance Criteria

Define measurable pass/fail conditions.

Each criterion must be objectively verifiable.

Example:

```text

- The required file exists.

- The required file is non-empty.

- The required file documents goal, scope, validations, stop conditions, and final report.

- Foundation validation passes.

```

## Required Validations

Define commands or checks that must run before completion.

Example:

```powershell

powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1

```

If no validation exists, the agent must report that validation is not configured.

The agent must not pretend validation passed.

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

Autonomous merge is allowed only if the selected autonomy profile and policy allow it.

Minimum conditions:

- CI passed

- required validations passed

- no protected files changed

- no policy violation detected

- risk level is allowed for autonomous merge

- review passed when configured

During foundation phase, merge should normally be human-controlled.

## Deployment Policy

Default:

```text

staging: disabled unless explicitly enabled

production: disabled unless explicitly enabled

```

Production deployment must never be assumed.

## Final Report Requirements

The final report must include:

- summary

- changed files

- validations executed

- validation result

- policy result

- risk result

- unresolved risks

- merge status

- deployment status, if applicable

- rollback notes, if applicable

## Completion Rule

A task is not complete because an agent says it is complete.

A task is complete only when the acceptance criteria are satisfied and the required validation evidence supports completion.

