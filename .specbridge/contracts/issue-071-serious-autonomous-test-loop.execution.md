# Execution Contract: Issue 71 Serious Autonomous Test Loop

## Contract Metadata

- contract_id: issue-071-serious-autonomous-test-loop
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/71
- created_by: ChatGPT/Codex
- created_at: 2026-05-22
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Prepare SpecBridge for a more serious autonomous test loop in the requested order:

1. Clean stale repository memory after issue 069.
2. Run a controlled multi-executor fresh source run.
3. Add one small real implementation feature with tests.
4. Automate bounded runtime launch evidence capture.
5. Harden ChatGPT/Codex audit validation.
6. Add autonomy metrics for serious test evaluation.

## Context

Issue 069 proved one fresh bounded Claude Code executor output chain. This task must extend that proof to multiple executor slices and add the first small runtime automation and measurement features needed to evaluate ChatGPT-governed, Claude Code-implemented, ChatGPT-audited development.

The implementation must remain repository-first and evidence-backed. It must not add hosted infrastructure, MCP server runtime, GitHub App runtime, production deployment, secrets access, dependency installation, auth, billing, or database changes.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-fresh-executor-source-run.md
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-runtime-results.md
- docs/specbridge-runtime-summaries.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- scripts/test-specbridge-negative-validations.ps1
- scripts/validate-chatgpt-audits.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/71

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task runs multiple bounded Claude Code executor slices
- it changes the local CLI and validation scripts
- it adds evidence and metrics used by later policy gates
- it remains file-backed, local, non-production, and scope-validated

## Allowed Scope

```text
.specbridge/audit-packets/issue-071-serious-autonomous-test-loop.audit-packet.json
.specbridge/audits/issue-071-serious-autonomous-test-loop.chatgpt-audit.json
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-071-serious-autonomous-test-loop.execution.md
.specbridge/executor-handoffs/issue-071-serious-autonomous-test-loop.input.json
.specbridge/executor-packets/issue-071-serious-autonomous-test-loop-claude-implementation.executor-packet.json
.specbridge/executor-packets/issue-071-serious-autonomous-test-loop-claude-audit.executor-packet.json
.specbridge/metrics/issue-071-serious-autonomous-test-loop.autonomy-metrics.json
.specbridge/reports/issue-071-serious-autonomous-test-loop.final-report.json
.specbridge/runtime-evidence/issue-071-claude-implementation.executor-output.md
.specbridge/runtime-evidence/issue-071-claude-audit.executor-output.md
.specbridge/runtime-launches/issue-071-claude-implementation.runtime-launch.json
.specbridge/runtime-launches/issue-071-claude-audit.runtime-launch.json
.specbridge/runtime-results/issue-071-claude-implementation.runtime-result.json
.specbridge/runtime-results/issue-071-claude-audit.runtime-result.json
.specbridge/runtime-runs/issue-071-claude-implementation.runtime-run.json
.specbridge/runtime-runs/issue-071-claude-audit.runtime-run.json
.specbridge/runtime-summaries/issue-071-claude-implementation.runtime-summary.json
.specbridge/runtime-summaries/issue-071-claude-audit.runtime-summary.json
.specbridge/scopes/issue-069-fresh-executor-source-run.scope.json
.specbridge/scopes/issue-071-serious-autonomous-test-loop.scope.json
README.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-runtime-launch-plans.md
docs/specbridge-runtime-results.md
docs/specbridge-runtime-summaries.md
docs/specbridge-runtime-runner.md
docs/specbridge-autonomy-metrics.md
docs/specbridge-serious-autonomous-test-loop.md
docs/specbridge-test-results.md
scripts/specbridge.ps1
scripts/specbridge-smoke.ps1
scripts/test-specbridge-cli.ps1
scripts/test-specbridge-negative-validations.ps1
scripts/validate-autonomy-metrics.ps1
scripts/validate-chatgpt-audits.ps1
scripts/validate-runtime-runs.ps1
specs/004-acceptance-tests.md
GitHub issue 71
GitHub pull request for this branch
```

## Executor Exclusive Write Scope

Claude Code implementation slice may write only:

```text
docs/specbridge-serious-autonomous-test-loop.md
.specbridge/runtime-evidence/issue-071-claude-implementation.executor-output.md
```

Claude Code audit slice may write only:

```text
docs/specbridge-autonomy-metrics.md
.specbridge/runtime-evidence/issue-071-claude-audit.executor-output.md
```

All other allowed paths are coordinator-owned SpecBridge/Codex evidence, CLI, validation, docs, and report updates.

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
package installation
dependency installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD permission escalation
CI/CD security weakening
branch protection weakening
raw protected credential capture
raw file content capture
production deployment
destructive infrastructure operation
unrestricted shell execution
Claude Code tools other than Read and Write for executor slices
Claude Code writes outside each executor exclusive write scope
```

## Acceptance Criteria

- Repository memory no longer points to issue 069 as active work.
- Issue 069 scope is marked completed before issue 071 final validation.
- The task declares source, implementation, test, evidence, docs, final report, audit packet, and ChatGPT/Codex audit paths before execution.
- SpecBridge prepares two executor packets from one handoff input.
- SpecBridge prepares one runtime launch plan per executor packet.
- Claude Code is invoked separately for two executor slices with `Read` and `Write` tools only.
- Each executor writes only inside its own exclusive write scope.
- SpecBridge records one runtime run artifact per executor slice.
- SpecBridge records one runtime result artifact per executor slice.
- SpecBridge writes one runtime summary artifact per executor slice.
- `scripts/specbridge.ps1` includes a tested runtime run evidence command.
- `scripts/specbridge.ps1` includes a tested autonomy metrics command.
- ChatGPT/Codex audit validation rejects audit packets that contradict the audit's contract or final report references.
- Autonomy metrics are generated from runtime summaries/results and validate locally.
- Local validations pass for contracts, scopes, executor packets, runtime launches, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, standard profile, smoke, security gates, review gates, CLI tests, negative tests, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-autonomy-metrics.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if Claude Code needs tools beyond Read/Write, writes outside a slice exclusive write scope, requires secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, CI/CD security changes, deployment automation, protected file changes, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, multi-executor runtime evidence, runtime run evidence, runtime result evidence, runtime summary evidence, autonomy metrics, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when both executor slices, runtime runs, runtime results, runtime summaries, CLI features, audit hardening, metrics, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, and policy-gated merge have passed.
