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

## Quickstart

Run the `quickstart` command to see the shortest safe path:

```powershell
powershell -ExecutionPolicy Bypass -Command "& '.\scripts\specbridge.ps1' -Command quickstart -RepositoryUrl 'https://github.com/your-org/your-repo'"
```

The recommended flow is:

1. **specbridge-intake** — generate governance files and push a ready-to-execute branch
2. **issue-to-merge-github** — run all 6 operations autonomously (from the intake branch)
3. **specbridge-doctor** — verify health after merge
4. **generate-dashboard** — regenerate the HTML status dashboard

To trigger intake from outside the repo:

```bash
gh workflow run specbridge-intake.yml \
  -f task_id="my-feature" \
  -f title="My feature title" \
  -f goal="What should be done and why."
```

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
- Post-merge memory closure and fix (issue 121): complete as the evidence closure after PR 120 merged issue 119, updating the evidence file with github_ci_passed true, confirming issue 119 closed via apply-mode, and fixing the ErrorActionPreference Stop bug that caused NativeCommandError on gh stderr. Merged through PR 122.
- Apply-mode pr_open expansion (issue 123): complete as the first live `gh pr create` in apply mode. Pilot scope guard allows `issue_close` and `pr_open`. Merged through PR 124 on 2026-06-07.
- Post-merge closure and live pr_open demo (issue 125): complete as the evidence closure after PR 124 merged issue 123, demonstrating apply-mode pr_open in live execution. Merged through PR 128 on 2026-06-07.
- Apply-mode merge expansion (issue 126): complete as the first live `gh pr merge --squash --auto` in apply mode. Pilot scope guard allows `issue_close`, `pr_open`, and `merge`. apply-unsupported-op test uses `ci_wait`. Merged through PR 129 on 2026-06-07.
- Full end-to-end apply-mode loop test (issue 127): complete as the first governed dry-run of all 6 default operations, adding `issue-to-merge-github-full-loop-dry-run` CLI test. Merged through PR 130 on 2026-06-07.
- Post-merge closure for issues 126 and 127 (issue 131): complete as evidence closure after PR 130 merged issue 127, updating issue-127 evidence, marking scopes completed, and creating closure artifacts for both issues 126 and 127. Merged through PR 132 on 2026-06-07.
- Post-merge closure for issue 126 (issue 133): complete as final evidence update after PR 129 merged, confirming github_ci_passed true and pr_merged true for issue 126, and marking the apply-mode three-operation pilot fully closed. Merged through PR 133 on 2026-06-07.
- Live combined apply-mode demonstration (issue 134): complete as the first governed combined execution of pr_open, merge, and issue_close in a single apply-mode call. PR 135 merged governance package on 2026-06-07. PR 137 merged execution evidence. Combined apply-mode call opened and merged PR 137 and closed issue 134 in one run.
- Post-merge closure for issue 134 (issue 138): complete as evidence closure recording combined apply-mode success and marking issue-134 scope completed. Merged through PR 139 on 2026-06-07.
- ci_wait and post_merge_memory expansion (issue 140): complete as the first governed expansion of the apply-mode pilot to include ci_wait (polling gh pr checks until CI passes) and post_merge_memory (automated closure branch creation, scope completion, and PR open after merge). Eliminates manual post-merge closure cycle. Merged through PR 141 on 2026-06-07.
- Apply-mode issue_create operation (issue 142): complete as the implementation of issue_create as the 6th apply-mode operation, completing the full autonomous 6-operation loop. PR 143 merged 2026-06-08. First live end-to-end run of all 6 operations confirmed: issue_create → pr_open → ci_wait → merge → issue_close → post_merge_memory.
- SpecBridge intake bridge (issue 143): complete as the ChatGPT → SpecBridge entry point. A specbridge-intake CLI command generates all governance files (contract, scope, evidence with all gates true) and pushes a ready-to-execute branch. A specbridge-intake.yml GitHub Action with workflow_dispatch inputs allows ChatGPT or any external caller to trigger intake via gh workflow run without touching the repository manually. Merged through PR 147 on 2026-06-08.
- SpecBridge operator hardening (issue 149): complete as a 10-improvement batch to the apply-mode operator: ci_wait state machine (no_checks_yet distinct from failed_ci), append-only operation ledger, machine-readable current-goal.json, specbridge-doctor health command, PR type conventions, execution locks, formal idempotence status values, status dashboard HTML, apply_mode and pr_types in policy.yaml, and full 6-op golden path validation. PR 150 pending merge.
- Lifecycle guard for apply-mode ordering (issue 153): complete as lifecycle ordering correctness batch. Merged via PR 155 on 2026-06-08.
- Intake bridge end-to-end test (issue 156/157): complete as first successful end-to-end trigger of specbridge-intake.yml via gh workflow run. All 6 apply-mode operations ran autonomously: issue_create → pr_open → ci_wait → merge → issue_close → post_merge_memory. Four operator bugs fixed: validate-review-gate now respects policy.yaml path_overrides, CURRENT_GOAL.md V5 text preserved, intake contract template generates all required sections, pr_open extracts PR URL from PS5.1 stderr ErrorRecord, and [skip ci] removed from closure commits. Merged through PRs 158–163 on 2026-06-08.
- specbridge quickstart command (issue 159/166): complete as the shortest-safe-path command that emits a recommended_flow array with 4 steps (specbridge-intake, issue-to-merge-github, specbridge-doctor, generate-dashboard) and a next_command_example string. Implemented and proven via intake bridge full 6-op loop. Merged through PRs 167–169 on 2026-06-08.
- doctor --fix-plan and lifecycle debt fix (PR 170): complete as the specbridge-doctor -FixPlan diagnostic command that detects 13 classes of repo drift (active scopes without PRs, premature closure PRs, lifecycle violations, current-goal desync, stale dashboard, missing artifacts, stale locks, and branch convention violations) and returns a concrete repair plan with severity, diagnosis, recommended command, and safe_to_automate flag per action. Includes -OutputFormat human|json|both and -Offline/-Online/-RequireOnline mode flags. Dashboard lifecycle debt section now correctly shows green "No open lifecycle debt." when no ordering violations exist. Merged through PR 170 on 2026-06-08.
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
- Multi-agent orchestration manifest (issue 178): implemented as a deterministic `specbridge-orchestrate` CLI command that generates `.specbridge/orchestrations/<task>.orchestration.json` with seven governed agent roles (planner, implementer, reviewer, tester, security, docs, closure), chained input/output artifact pointers, run_id propagation, `validate-orchestrations.ps1` in smoke, a doctor `orchestration_stale` check, and a Studio dashboard orchestrations section. Merged through PR 180 on 2026-06-09.
- Agent handoff protocol (issue 179 / GitHub #184): implemented as a deterministic `specbridge-handoff -TaskId <task> -Agent <name>` CLI command that records the agent's output artifact, marks the agent completed in the orchestration manifest, activates the next agent in the chain, transitions orchestration status planned -> in_progress -> completed, appends an `agent_handoff` ledger entry with run_id, and enforces strictly sequential handoffs. `validate-orchestrations.ps1` verifies that completed agents form a sequential prefix, their output artifacts exist on disk, and orchestration status matches aggregate agent state.
- Independent review-agent report (issue 180 / GitHub #188): implemented as `specbridge-review-report -TaskId <task> -Verdict approve|block` writing machine-validated reports with typed findings; the reviewer handoff is hard-gated on an approve verdict with no blocker findings, enforced by `validate-agent-review-reports.ps1` in smoke.
- Claude Code project configuration (issue 181 / GitHub #192): `.claude/settings.json` bounded permission allowlist, `/sb-intake` `/sb-handoff` `/sb-review` `/sb-close` slash commands, and the Governed Operating Model documented in CLAUDE.md. Merge authorization is enforced by allowlist omission, never by hard deny.
- Operator queue hygiene and next-task selector (GitHub #196): an open GitHub issue is NOT automatically eligible SpecBridge work. `.specbridge/policies/operator-task-decisions.json` records authoritative operator decisions (`not_planned`, `deferred`, `superseded`, `blocked`) per issue/task; the offline, read-only `specbridge-next-task` command reports eligible tasks, excluded issues and the recommended action; `validate-operator-task-decisions.ps1` gates the registry in smoke; the Studio dashboard shows the Operator Queue. GitHub is storage; the operator decision registry is the brain that decides what runs next.
- Standard readiness status (issue 228): `specbridge-standard-readiness` aggregates doctor health, next-task posture, repository health, token/context governance, MCP resource posture, and standard execution boundaries into one deterministic read-only operator readiness snapshot before new governed task intake.
- Claude runtime capability negotiation (issue 231): `runtime-capability-status` and `execute-runtime-launch` now record whether the installed Claude CLI supports `--max-turns`; live launch command assembly applies the flag only when supported and keeps max budget, timeout, no-session, allowed-tool, and redacted-evidence boundaries intact.
- Bounded local MCP runtime (issues 234/240/243): `specbridge-mcp-runtime` exposes existing operator-state resources through local `resources/list` and `resources/read`, adds a bounded `tools/list` and allowlisted read-only `tools/call` surface for operator status and next-task selector snapshots, rejects mutation-capable or unlisted methods deterministically, and keeps network transport, GitHub/resource mutation, secrets, deployment, and cleanup enforcement blocked.
- Project starter standard (issue 237): `specbridge-project-starter` creates deterministic local starter artifacts under `.specbridge/project-starters/` so future blockchain, WhatsApp/MercadoLibre AI, marketing, or other product ideas can become auditable SpecBridge packages before implementation, dependencies, secrets, billing, deployment, or external repository mutation.
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
- `docs/specbridge-standard-readiness-status.md`
- `docs/specbridge-claude-runtime-capability-negotiation.md`
- `docs/specbridge-mcp-readonly-runtime.md`
- `docs/specbridge-project-starter-standard.md`
