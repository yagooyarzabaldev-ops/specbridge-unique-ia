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
- Standard Loop orchestrator: implemented as a deterministic `standard-loop-orchestrate` CLI command that reports the governed issue-to-merge phases, required gates, current repository phase, next recommended action, next contract seed, latest artifacts, policy boundaries, and optional file-backed orchestration artifact without launching Claude Code, Antigravity, GitHub calls, dependency installation, or deployment.
- Governed issue-to-merge operator: implemented as a deterministic plan-only `issue-to-merge-plan` CLI command that records issue intake, contract package, local gates, PR, GitHub CI, policy merge, and post-merge memory closure phases with merge conditions, evidence paths, policy boundaries, and optional file-backed run artifacts without creating issues, opening PRs, waiting for CI, merging, launching runtime, installing dependencies, or deploying.
- Issue-to-merge operator safe pilot: implemented as the first repository-backed dry-run of `issue-to-merge-plan` on issue 111, with a file-backed run artifact, documentation update, final report, audit packet, and ChatGPT/Codex audit before any future GitHub-mutating operator mode.
- Bounded GitHub mutation operator mode: implemented as deterministic `issue-to-merge-github` dry-run evidence with explicit GitHub connector actions for issue creation, PR opening, CI wait, policy merge, issue closure, and post-merge memory; apply mode is blocked unless force, confirmation, and local/GitHub gate evidence are declared.
- Issue-to-merge GitHub evidence loop: complete as the first governed end-to-end pilot that used the `issue-to-merge-github` dry-run connector envelope for issue 115, compared it with real GitHub issue, PR, CI, merge, issue closure, and memory evidence, and merged through PR 116 on 2026-06-06 without changing the repository-local dry-run boundary.
- Post-merge memory closure (issue 117): complete as the evidence closure after PR 116 merged issue 115, recording CI completion, issue closure, and next task. Merged through PR 118.
- Apply-mode GitHub operator pilot (issue 119): complete as the first real GitHub mutation — `issue-to-merge-github` apply mode executes `gh issue close` when all evidence gates pass, with explicit confirmation flags and `apply_mode_pilot_supports_issue_close_only` scope guard. Merged through PR 120 on 2026-06-06.
- Post-merge memory closure and fix (issue 121): complete as the evidence closure after PR 120 merged issue 119, updating the evidence file with github_ci_passed true, confirming issue 119 closed via apply-mode, and fixing the ErrorActionPreference Stop bug that caused NativeCommandError on gh stderr. In progress on PR 121.
- Multi-slice live pilot contract preparation: implemented as a governed three-slice handoff from the Standard Loop `next_contract_seed`, with non-overlapping `status`, `tests`, and `docs` executor scopes, executor packets, plan-only runtime launch artifacts, documentation, final report, audit packet, and ChatGPT/Codex audit evidence before any future live operator launch.
- Runtime launch preflight: implemented as a deterministic `preflight-runtime-launches` CLI command and validator that read prepared launch plans, confirm required slices, non-overlapping write scopes, budget ceiling, tool allow-list, and plan-only execution policy before any future live operator launch.
- Bounded live docs slice: implemented as the first post-preflight live execution from the prepared issue 097 launch plans, with one docs-slice Claude Code run, bounded diagnostics, executor evidence, runtime-run/result/summary artifacts, final report, audit packet, and ChatGPT/Codex audit evidence.
- Bounded live tests slice: implemented as the second post-preflight live execution from the prepared issue 097 launch plans, with one tests-slice Claude Code run, focused CLI status coverage, bounded diagnostics, executor evidence, runtime-run/result/summary artifacts, final report, audit packet, and ChatGPT/Codex audit evidence.
- Bounded live status slice: implemented as the third post-preflight live execution from the prepared issue 097 launch plans, with one status-slice Claude Code run, bounded status surface expansion, bounded diagnostics, executor evidence, runtime-run/result/summary artifacts, final report, audit packet, and ChatGPT/Codex audit evidence.
- Post-preflight live pilot closure: implemented as an evidence-only closure over the issue 097 `docs`, `tests`, and `status` chain, with 3/3 runtime summaries ready for policy gates, 0 blockers, 9/9 slice validations passed, merged PR evidence for PRs 102, 104, and 106, autonomy metrics, pilot closure evidence, final report, audit packet, and ChatGPT/Codex audit.
- Standard templates and schemas: implemented for contracts, scope manifests, executor handoffs, runtime launches, final reports, audit packets, ChatGPT audits, executor packets, runtime launches, runtime runs, runtime results, runtime summaries, autonomy metrics, and runtime executions.
- V5 live parallel pilot boundary: defined as the next phase after Standard Loop v1, with live Antigravity parallel execution allowed only through dedicated contracts, non-overlapping executor scopes, CI authority, security gate, review gate, audit evidence, and no production, billing, secret, auth, database, CI/CD security, or deployment expansion.
- V5 pilot readiness: implemented as a deterministic `v5-pilot-status` CLI readiness gate with a two-slice dry-run evidence chain, runtime summaries, autonomy metrics, final report, audit packet, and ChatGPT/Codex audit evidence before any live parallel Antigravity expansion.
- V5 live parallel pilot: implemented as a three-slice governed pilot with bounded live Claude Code runtime attempts, `runtime-capability-status`, executor packets, launch plans, runtime execution evidence, runtime-run/result/summary artifacts, autonomy metrics, and coordinator remediation evidence. Docs and tests slices completed live; the CLI live slice failed twice and was remediated by the coordinator inside declared scope.
- V5 live status and runner diagnostics: implemented as a deterministic `v5-live-status` CLI view over the completed live pilot plus bounded redacted `execute-runtime-launch` failure diagnostics for future executor attempts.
- V5 autonomy status: implemented as a deterministic `v5-autonomy-status` CLI command that reports the no-coordinator-remediation target standard, required slices, prior and target pilot status, and policy boundary for the second V5 live pilot.
- V5 runner hardening: implemented as post-merge closure for the second V5 live autonomy pilot, a bounded `2.00` default live runtime budget, ASCII-stable runtime diagnostic previews, and local-only agent settings ignore rules.
- V5 serious pilot status: implemented as a deterministic `v5-serious-pilot-status` CLI command that reports the `serious_live_multi_slice_no_remediation` pilot standard, `v5_hardened_runtime_runner` baseline, required slices `[status, tests, docs]`, default `2.00` USD runtime budget, `ascii_stable_bounded_240_chars` diagnostic preview policy, no-remediation target, and policy boundary.
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
- `docs/specbridge-standard-loop-orchestrator.md`
- `docs/specbridge-issue-to-merge-operator.md`
- `docs/specbridge-multi-slice-live-pilot-contract.md`
- `docs/specbridge-runtime-launch-preflight.md`
- `docs/specbridge-standard-loop-feature-pilot.md`
- `docs/specbridge-standard-templates.md`
- `docs/specbridge-ci-authority-standard.md`
- `docs/specbridge-v5-live-parallel-pilot-boundary.md`
- `docs/specbridge-v5-live-status.md`
- `docs/specbridge-runtime-capability-status.md`
- `docs/specbridge-autonomy-backlog.md`
- `docs/specbridge-v5-autonomy-status.md`
- `docs/specbridge-v5-serious-pilot-status.md`
