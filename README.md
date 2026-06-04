# SpecBridge

SpecBridge is a standard connector for turning ChatGPT/Codex context into autonomous Claude Code execution.

## Core Idea

Think and define in ChatGPT.
Structure and govern with Codex.
Execute autonomously with Claude Code.
Validate with CI.
Review with Codex.
Report the final result to the user.

## Product Vision

SpecBridge allows a user to delegate software development work from ChatGPT/Codex to Claude Code without approving every individual step.

SpecBridge also supports a multi-agent product direction: one governed goal may be decomposed into multiple execution contracts so several Claude Code executors can work in parallel inside Antigravity without losing scope control, validation, review, or auditability.

The default workflow is Vibe Autopilot:

1. The user defines the goal.
2. ChatGPT/Codex creates the executable context.
3. SpecBridge creates the execution contract.
4. Claude Code implements without step-by-step permission requests.
5. CI validates the result.
6. Codex reviews the implementation.
7. SpecBridge reports the final outcome.

The default autonomy profile is now Full Autopilot:

- ordinary implementation proceeds without step-by-step approval
- validation failures are fixed automatically when inside scope
- pull requests may be updated automatically
- merge may happen automatically only when all required gates pass
- production deployment remains manual unless a future policy explicitly enables it

## Core Principle

SpecBridge does not remove control.

SpecBridge moves control from constant human interruption to explicit policy, context, tests, review, and auditability.

The system should not ask the user for permission during normal implementation work. It should stop only when a defined policy boundary is reached.

## Main Roles

### ChatGPT / Codex

Responsible for intent, context, specs, acceptance criteria, and review.

### SpecBridge

Responsible for execution contracts, policy enforcement, multi-agent coordination, GitHub orchestration, and final reports.

### Claude Code

Responsible for implementation, tests, fixes, pull requests, and autonomous execution inside the allowed scope.

### GitHub

Responsible for repository state, issues, branches, pull requests, CI, and audit trail.

## Non-Goals

SpecBridge is not:

- an unrestricted remote shell
- a random chat-to-terminal executor
- a replacement for tests
- a system that sends raw ChatGPT conversations to Claude Code
- a system that touches secrets, production, billing, or destructive infrastructure without policy authorization

## MVP Goal

The first MVP must prove this flow:

1. Store context as repository files.
2. Create an executable task.
3. Let Claude Code implement autonomously.
4. Run CI validation.
5. Let Codex review.
6. Merge only if policy allows it.
7. Produce a final report.

## Current Status

SpecBridge currently has these governed status layers:

- V1 foundation: complete and validated locally.
- Repository-first MVP: complete as a controlled loop using context files, execution contracts, validation scripts, PR gates, review artifacts, and final reports.
- V3 essential product scope: defined for the runtime phase, with source-backed runtime expansion allowed only through dedicated execution contracts that declare source paths, tests, docs, lint, typecheck, build, and review gates.
- V4 product contract: defined for local CLI, MCP, GitHub evidence integration, dashboard boundaries, data model boundaries, runtime gates, completion criteria, and Version 5 candidates.
- Branch-per-executor orchestration: implemented as deterministic branch plans, coordinator simulation evidence, and a controlled GitHub evidence run with real child PR URLs, passed child CI, and ChatGPT/Codex audit status.
- Operational autonomy cleanup: evidence-only child PRs are closed without merge, issue 42 is closed as completed, and stale GitHub evidence is resolved.
- Controlled Antigravity/Claude Code runtime launch: implemented as a bounded non-interactive Claude Code run from the Antigravity workspace, with SpecBridge executor packet evidence, one executor-written runtime artifact, validation evidence, and ChatGPT/Codex audit.
- Runtime launch plans: implemented as a deterministic CLI command that turns one executor packet into a bounded Claude Code launch plan artifact without executing Claude Code, Antigravity, shell commands, network calls, dependency installation, or deployment.
- Runtime result recording: implemented as a deterministic CLI command that records bounded executor evidence, exit code, written files, validation results, policy result, stop conditions, and completion status from a declared runtime launch plan.
- Runtime summaries: implemented as the first source-backed runtime CLI slice that links a runtime launch plan and runtime result into a validated summary with merge readiness and blockers.
- Fresh executor source run: implemented as a bounded non-interactive Claude Code run that creates fresh executor output, records the runtime result, summarizes it, and preserves coordinator evidence for audit.
- Runtime-run evidence capture: implemented as a deterministic CLI command that records bounded executor launch evidence, written files, tool restrictions, runtime status, and policy result before runtime results and summaries are produced.
- Serious autonomous multi-executor test loop: implemented as a two-slice Claude Code runtime proof from one governed goal, with non-overlapping executor write scopes, runtime launch plans, runtime-run artifacts, runtime results, runtime summaries, autonomy metrics, hardened ChatGPT/Codex audit validation, and policy-gated completion evidence.
- Standard Loop v1: implemented as the canonical path from ChatGPT/Codex goal to contract, scope, executor packet, runtime launch, controlled runner dry-run, evidence, audit, GitHub CI authority, review gate, security gate, and policy-gated merge.
- Standard templates and schemas: implemented for contracts, scope manifests, executor handoffs, runtime launches, final reports, audit packets, ChatGPT audits, executor packets, runtime launches, runtime runs, runtime results, runtime summaries, autonomy metrics, and runtime executions.
- V5 live parallel pilot boundary: defined as the next phase after Standard Loop v1, with live Antigravity parallel execution allowed only through dedicated contracts, non-overlapping executor scopes, CI authority, security gate, review gate, audit evidence, and no production, billing, secret, auth, database, CI/CD security, or deployment expansion.
- V5 pilot readiness: implemented as a deterministic `v5-pilot-status` CLI readiness gate with a two-slice dry-run evidence chain, runtime summaries, autonomy metrics, final report, audit packet, and ChatGPT/Codex audit evidence before any live parallel Antigravity expansion.
- V5 live parallel pilot: implemented as a three-slice governed pilot with bounded live Claude Code runtime attempts, `runtime-capability-status`, executor packets, launch plans, runtime execution evidence, runtime-run/result/summary artifacts, autonomy metrics, and coordinator remediation evidence. Docs and tests slices completed live; the CLI live slice failed twice and was remediated by the coordinator inside declared scope.
- V5 live status and runner diagnostics: implemented as a deterministic `v5-live-status` CLI view over the completed live pilot plus bounded redacted `execute-runtime-launch` failure diagnostics for future executor attempts.
- V5 autonomy status: implemented as a deterministic `v5-autonomy-status` CLI command that reports the no-coordinator-remediation target standard, required slices, prior and target pilot status, and policy boundary for the second V5 live pilot.
- V5 runner hardening: implemented as post-merge closure for the second V5 live autonomy pilot, a bounded `2.00` default live runtime budget, ASCII-stable runtime diagnostic previews, and local-only agent settings ignore rules.
- Default automation: Full Autopilot is enabled for autonomous merge after required gates pass; production deployment remains disabled.

See:

- `docs/specbridge-phase-completion.md`
- `docs/specbridge-mvp-operating-runbook.md`
- `docs/specbridge-v3-essential-product-scope.md`
- `docs/specbridge-v4-product-contract.md`
- `docs/specbridge-multi-agent-antigravity-architecture.md`
- `docs/specbridge-branch-per-executor-orchestration.md`
- `docs/specbridge-controlled-github-evidence-run.md`
- `docs/specbridge-operational-autonomy-policy-closure.md`
- `docs/specbridge-controlled-antigravity-runtime-launch.md`
- `docs/specbridge-runtime-launch-plans.md`
- `docs/specbridge-runtime-results.md`
- `docs/specbridge-runtime-summaries.md`
- `docs/specbridge-runtime-runner.md`
- `docs/specbridge-fresh-executor-source-run.md`
- `docs/specbridge-serious-autonomous-test-loop.md`
- `docs/specbridge-autonomy-metrics.md`
- `docs/specbridge-standard-loop-v1.md`
- `docs/specbridge-standard-loop-feature-pilot.md`
- `docs/specbridge-standard-templates.md`
- `docs/specbridge-ci-authority-standard.md`
- `docs/specbridge-v5-live-parallel-pilot-boundary.md`
- `docs/specbridge-v5-live-status.md`
- `docs/specbridge-runtime-capability-status.md`
- `docs/specbridge-autonomy-backlog.md`
- `docs/specbridge-v5-autonomy-status.md`
