# 004 - Acceptance Tests

## Foundation Acceptance Tests

### AT-001 - Required foundation files exist

Required files:

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .gitattributes
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml
- .specbridge/risk-rules.yaml
- .specbridge/report-template.md
- specs/000-project-context.md
- specs/001-product-requirements.md
- specs/002-architecture.md
- specs/003-mvp-plan.md
- specs/004-acceptance-tests.md

Pass condition:

All required files exist and are non-empty.

### AT-002 - Markdown fences are balanced

Pass condition:

All Markdown files have an even number of triple-backtick code fences.

### AT-003 - Policy files are present

Pass condition:

All YAML policy files exist and are non-empty.

### AT-004 - No implementation code during foundation phase

Pass condition:

The repository contains only documentation, specs, policy, and configuration files during foundation phase.

### AT-005 - Vibe Autopilot is defined

Pass condition:

README.md, SPECBRIDGE.md, AGENTS.md, CLAUDE.md, and .specbridge/autonomy.yaml all reference or define Vibe Autopilot behavior.

### AT-006 - Stop conditions are defined

Pass condition:

SPECBRIDGE.md, AGENTS.md, CLAUDE.md, and .specbridge/policy.yaml define stop conditions or escalation boundaries.

### AT-007 - Final report template exists

Pass condition:

.specbridge/report-template.md exists and includes sections for summary, changed files, validations, policy result, risk result, merge status, deployment status, and rollback notes.

### AT-008 - MVP operating runbook exists

Pass condition:

docs/specbridge-mvp-operating-runbook.md exists and defines required inputs, operating loop, local validations, CI gates, completion standard, failure handling, and MVP boundary.

### AT-009 - Phase completion artifact exists

Pass condition:

docs/specbridge-phase-completion.md exists and records Phase 1, Phase 2, and Phase 3 status with explicit non-activation boundaries.

### AT-010 - V3 essential scope exists

Pass condition:

docs/specbridge-v3-essential-product-scope.md exists and defines essential product capabilities, runtime boundary, non-essential scope, version 4 candidates, and the gate required before runtime work starts.

### AT-011 - V4 product contract exists

Pass condition:

docs/specbridge-v4-product-contract.md exists and defines product goal, required product surfaces, local CLI scope, MCP scope, GitHub integration scope, hosted dashboard scope, data model boundary, runtime implementation gates, V4 completion criteria, and Version 5 candidates.

### AT-012 - Automatic merge policy is explicit

Pass condition:

.specbridge/policy.yaml enables autonomous merge, .specbridge/autonomy.yaml selects `full_autopilot` as the default profile, and documentation states that automatic merge requires all configured gates to pass.

### AT-013 - Negative validation suite exists

Pass condition:

scripts/test-specbridge-negative-validations.ps1 exists and verifies that foundation validation, contract validation, final report validation, and PR review gate validation fail for expected invalid fixtures.

### AT-014 - Smoke validation includes negative tests

Pass condition:

scripts/specbridge-smoke.ps1 runs scripts/test-specbridge-negative-validations.ps1 as part of the deterministic smoke chain.

### AT-015 - Test evidence is documented

Pass condition:

docs/specbridge-test-matrix.md defines positive and negative test coverage, and docs/specbridge-test-results.md records current validation evidence.

### AT-016 - Multi-agent Antigravity architecture exists

Pass condition:

docs/specbridge-multi-agent-antigravity-architecture.md exists and defines Governor, Coordinator, Executor, Reviewer, parallel execution rules, scope ownership, branching, evidence, merge model, and product requirements for multiple Claude Code executors working inside Antigravity.

### AT-017 - Contract scope validation exists

Pass condition:

scripts/validate-contract-scopes.ps1 exists, validates `.specbridge/scopes/*.scope.json`, rejects overlapping active `exclusive_write` paths, rejects duplicate final report paths, requires explicit dependencies for active read/write relationships, and is included in scripts/specbridge-smoke.ps1.

### AT-018 - Audit packet generation exists

Pass condition:

scripts/generate-audit-packet.ps1 creates deterministic `.specbridge/audit-packets/*.audit-packet.json` files, scripts/validate-audit-packets.ps1 validates the required packet fields, packets reference files by path without embedding raw diffs or file contents, and scripts/specbridge-smoke.ps1 includes audit packet validation.

### AT-019 - ChatGPT audit validation exists

Pass condition:

.specbridge/schemas/chatgpt-audit.schema.json exists, scripts/validate-chatgpt-audits.ps1 validates `.specbridge/audits/*.chatgpt-audit.json`, allowed outcomes are limited to `approved`, `changes_requested`, `blocked`, and `needs_human_decision`, every audit checks the required dimensions, blocking findings prevent merge, and scripts/specbridge-smoke.ps1 includes ChatGPT audit validation.

### AT-020 - Security review gate expansion exists

Pass condition:

scripts/validate-security-gates.ps1 exists, scripts/specbridge-smoke.ps1 includes security gate validation, the gate checks changed files for secret-like content, auth-sensitive paths, authorization-sensitive paths, CI/CD permission escalation, dependency manifest or lockfile changes, unsafe shell commands, protected path changes, and production configuration paths, and the negative validation suite proves safe and unsafe fixtures with expected security categories.

### AT-021 - Local SpecBridge CLI exists

Pass condition:

scripts/specbridge.ps1 exists and supports `status`, `validate`, `create-contract`, `create-report`, `audit-packet`, `detect-conflicts`, `decompose-task`, and `review-gate`; commands have deterministic exit codes; artifact commands use declared repository-relative output paths; commands do not require secrets; scripts/test-specbridge-cli.ps1 covers every command; and scripts/specbridge-smoke.ps1 runs the CLI validation suite.

### AT-022 - Controlled implementation pilot exists

Pass condition:

docs/specbridge-controlled-implementation-pilot.md exists; scripts/specbridge.ps1 `status` supports `-IncludeLatestArtifacts`; the output includes deterministic latest contract, scope, final report, audit packet, and ChatGPT audit paths; scripts/test-specbridge-cli.ps1 covers the feature; and issue 053 contract, scope, final report, audit packet, and ChatGPT audit artifacts validate.

### AT-023 - Multi-agent pilot exists

Pass condition:

docs/specbridge-multi-agent-pilot.md exists; issue 054 multi-agent decomposition exists; Agent A, Agent B, and Agent C each have their own execution contract, scope manifest, output artifact, and final report; scripts/test-specbridge-multi-agent-pilot.ps1 proves three disjoint slices and duplicate write-scope rejection; coordinator integration report, final report, audit packet, and ChatGPT audit artifacts validate; and scripts/specbridge-smoke.ps1 runs the multi-agent pilot validation.

### AT-024 - Antigravity executor handoff exists

Pass condition:

docs/specbridge-live-antigravity-executor-handoff.md exists; scripts/specbridge.ps1 supports `prepare-executors`; `.specbridge/executor-packets/*.executor-packet.json` files exist for Agent A, Agent B, and Agent C; scripts/validate-executor-packets.ps1 validates required packet fields; scripts/test-specbridge-executor-handoff.ps1 proves successful packet generation and duplicate branch rejection; and scripts/specbridge-smoke.ps1 runs executor packet validation and handoff tests.

### AT-025 - Branch per executor orchestration exists

Pass condition:

docs/specbridge-branch-per-executor-orchestration.md exists; scripts/specbridge.ps1 supports `plan-executor-branches` and `coordinate-executors`; `.specbridge/branch-plans/*.branch-plan.json` records one branch per executor packet; `.specbridge/orchestrations/*.executor-orchestration.json` records child PR, CI, ChatGPT audit, merge, and rollback evidence; scripts/validate-branch-orchestrations.ps1 validates branch plan and orchestration artifacts; scripts/test-specbridge-branch-orchestration.ps1 proves successful planning, simulated coordination, duplicate branch rejection, and simulation merge blocking; and scripts/specbridge-smoke.ps1 runs branch orchestration validation and tests.

### AT-026 - Controlled GitHub evidence exists

Pass condition:

docs/specbridge-controlled-github-evidence-run.md exists; `.specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json` records child PR evidence for PRs 56, 57, and 58; scripts/specbridge.ps1 supports `record-github-evidence`; `.specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json` records real child PR URLs, passed CI status, and approved ChatGPT/Codex audit status; `.specbridge/orchestrations/issue-060-controlled-github-evidence-run.executor-orchestration.json` records GitHub evidence mode and `ready_for_integration`; scripts/validate-branch-orchestrations.ps1 validates the GitHub evidence records; scripts/test-specbridge-branch-orchestration.ps1 proves GitHub evidence recording and simulation URL rejection; and child executor PRs remain unmerged evidence records unless a later contract authorizes integration.

### AT-027 - Operational autonomy cleanup exists

Pass condition:

docs/specbridge-operational-autonomy-policy-closure.md exists; `.specbridge/github-evidence/issue-042-operational-autonomy-policy-closure.cleanup.json` records PRs 56, 57, and 58 closed without merge; issue 42 is closed as completed; repository memory points to controlled Antigravity/Claude Code runtime launch as the next recommended task; and the cleanup does not merge child PRs, delete remote branches, launch Antigravity sessions, start Claude Code, or touch protected credentials.

### AT-028 - Controlled Antigravity runtime launch exists

Pass condition:

docs/specbridge-controlled-antigravity-runtime-launch.md exists; issue 061 has a dedicated execution contract, scope manifest, executor handoff input, generated executor packet, Claude runtime evidence JSON, Claude executor output artifact, final report, audit packet, and ChatGPT/Codex audit; Claude Code and Antigravity availability are recorded; Claude Code is invoked non-interactively with bounded Read/Write tools only; the executor writes only `.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md`; local validations pass; GitHub CI passes before merge; and the launch does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, access protected credentials, weaken CI/CD security, or deploy anything.

### AT-029 - Runtime launch plans exist

Pass condition:

docs/specbridge-runtime-launch-plans.md exists; scripts/specbridge.ps1 supports `prepare-runtime-launch`; the command reads one executor packet and writes one declared `.specbridge/runtime-launches/*.runtime-launch.json` artifact; `.specbridge/runtime-launches/issue-063-prepare-runtime-launch-plans.runtime-launch.json` validates; scripts/validate-runtime-launches.ps1 validates runtime launch plan structure and safety boundaries; standard validation and smoke validation include runtime launch validation; CLI tests cover success and unapproved tool failure; negative validation tests cover invalid runtime launch artifacts; and the command does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AT-030 - Runtime result recording exists

Pass condition:

docs/specbridge-runtime-results.md exists; scripts/specbridge.ps1 supports `record-runtime-result`; the command reads one runtime launch plan and one declared executor evidence file, then writes one declared `.specbridge/runtime-results/*.runtime-result.json` artifact; `.specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json` validates; scripts/validate-runtime-results.ps1 validates runtime result structure and safety boundaries; standard validation and smoke validation include runtime result validation; CLI tests cover success and out-of-scope evidence failure; negative validation tests cover invalid runtime result artifacts; and the command does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AT-031 - Runtime summaries exist

Pass condition:

docs/specbridge-runtime-summaries.md exists; scripts/specbridge.ps1 supports `summarize-runtime`; the command reads one runtime launch plan and one runtime result artifact, then writes one declared `.specbridge/runtime-summaries/*.runtime-summary.json` artifact; `.specbridge/runtime-summaries/issue-067-source-backed-runtime-slice.runtime-summary.json` validates; scripts/validate-runtime-summaries.ps1 validates runtime summary structure, launch/result consistency, validation totals, blockers, merge readiness, and safety boundaries; standard validation and smoke validation include runtime summary validation; CLI tests cover success and launch/result mismatch failure; negative validation tests cover invalid runtime summary artifacts; and the command does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AT-032 - Fresh executor source run exists

Pass condition:

docs/specbridge-fresh-executor-source-run.md exists; issue 069 has a dedicated execution contract, scope manifest, executor handoff input, generated executor packet, runtime launch plan, Claude run evidence, executor output evidence, runtime result, runtime summary, final report, audit packet, and ChatGPT/Codex audit; Claude Code is invoked non-interactively with bounded Read/Write tools only; the executor writes only docs/specbridge-fresh-executor-source-run.md and .specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md; local validations pass; GitHub CI passes before merge; and the task does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, access protected credentials, weaken CI/CD security, or deploy anything.

### AT-033 - Runtime-run evidence exists

Pass condition:

docs/specbridge-runtime-runner.md exists; scripts/specbridge.ps1 supports `run-runtime-launch`; the command reads one runtime launch plan and one declared executor evidence file, then writes one declared `.specbridge/runtime-runs/*.runtime-run.json` artifact; scripts/validate-runtime-runs.ps1 validates runtime-run structure, written-file scope, tool restrictions, runner mode, and safety boundaries; standard validation and smoke validation include runtime-run validation; CLI tests cover success and out-of-scope evidence failure; negative validation tests cover invalid runtime-run artifacts; and the command does not launch Claude Code, launch Antigravity, call GitHub, install dependencies, touch secrets, touch production, or deploy.

### AT-034 - Autonomy metrics exist

Pass condition:

docs/specbridge-autonomy-metrics.md exists; scripts/specbridge.ps1 supports `summarize-autonomy-metrics`; the command reads runtime summaries and runtime results, optionally filtered by task id, then writes one declared `.specbridge/metrics/*.autonomy-metrics.json` artifact; scripts/validate-autonomy-metrics.ps1 validates autonomy metrics counts, ready rate, validation totals, and source references; standard validation and smoke validation include autonomy metrics validation; CLI tests cover success and missing task failure; negative validation tests cover invalid autonomy metrics artifacts; and the command does not launch Claude Code, launch Antigravity, call GitHub, install dependencies, touch secrets, touch production, or deploy.

### AT-035 - Serious autonomous multi-executor test loop exists

Pass condition:

docs/specbridge-serious-autonomous-test-loop.md exists; issue 071 has a dedicated execution contract, scope manifest, executor handoff input, two generated executor packets, two runtime launch plans, two Claude Code executor output evidence files, two runtime-run artifacts, two runtime-result artifacts, two runtime-summary artifacts, autonomy metrics, final report, audit packet, and ChatGPT/Codex audit; Claude Code is invoked non-interactively with bounded Read/Write tools for both slices; each executor writes only its declared exclusive scope; local validations pass; GitHub CI passes before merge; and the task does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, access protected credentials, weaken CI/CD security, or deploy anything.
