# Acceptance Criteria

## Context Package Acceptance Criteria

### AC-001

.specbridge/context/CODEX_CONTEXT.md exists and defines the structured context purpose.

### AC-002

.specbridge/context/CURRENT_GOAL.md exists and defines the current project goal.

### AC-003

.specbridge/context/ACCEPTANCE_CRITERIA.md exists and defines measurable completion criteria.

### AC-004

.specbridge/context/DO_NOT_TOUCH.md exists and defines protected areas.

### AC-005

.specbridge/context/STYLE_GUIDE.md exists and defines style rules.

### AC-006

No raw ChatGPT conversation dump is stored in the context package.

### AC-007

All context files are Markdown files and have balanced code fences.

## Phase Completion Acceptance Criteria

### AC-008

docs/specbridge-phase-completion.md exists and records foundation completion, repository-first MVP completion, and essential V3 scope status.

### AC-009

docs/specbridge-mvp-operating-runbook.md exists and defines the repository-first MVP operating loop.

### AC-010

docs/specbridge-v3-essential-product-scope.md exists and defines essential product scope, runtime boundaries, non-essential scope, and version 4 candidates.

### AC-011

.specbridge/contracts/issue-042-finish-phases-1-3.execution.md exists and defines allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-012

.specbridge/reports/issue-042-finish-phases-1-3.final-report.json exists and validates against the final report validator.

### AC-013

No secrets, production configuration, deployment automation, runtime product code, MCP server implementation, autonomous merge, or autonomous push to main are added by the phase completion task.

## Version 4 Acceptance Criteria

### AC-014

docs/specbridge-v4-product-contract.md exists and defines V4 product goal, required surfaces, local CLI scope, MCP scope, GitHub integration scope, hosted dashboard boundary, data model boundary, runtime gates, completion criteria, and Version 5 candidates.

### AC-015

.specbridge/contracts/issue-043-finish-version-4.execution.md exists and defines allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-016

.specbridge/reports/issue-043-finish-version-4.final-report.json exists and validates against the final report validator.

### AC-017

Version 4 completion does not add runtime product code, secrets, production configuration, hosted dashboard implementation, database schema implementation, MCP server implementation, GitHub App implementation, autonomous merge, or autonomous push to main.

## Automatic Merge Acceptance Criteria

### AC-018

.specbridge/policy.yaml sets `project.default_mode` to `full_autopilot` and `merge.autonomous_merge_enabled` to `true`.

### AC-019

.specbridge/autonomy.yaml sets `default_profile` to `full_autopilot`.

### AC-020

Documentation states that automatic merge is allowed only after required validation, policy, review, and CI gates pass.

### AC-021

Production deployment remains disabled.

## Test Suite Acceptance Criteria

### AC-022

scripts/test-specbridge-negative-validations.ps1 exists and verifies expected failure behavior for missing foundation files, incomplete execution contracts, incomplete final reports, and blocked PR paths.

### AC-023

scripts/specbridge-smoke.ps1 runs the negative validation suite.

### AC-024

docs/specbridge-test-matrix.md exists and defines positive and negative SpecBridge test coverage.

### AC-025

docs/specbridge-test-results.md exists and records the local validation evidence for the current test phase.

## Multi-Agent Architecture Acceptance Criteria

### AC-026

docs/specbridge-multi-agent-antigravity-architecture.md exists and defines multi-agent execution as a first-class product capability.

### AC-027

The architecture defines Governor, Coordinator, Executor, Reviewer, parallel execution rules, scope ownership, branch strategy, evidence aggregation, and merge behavior.

### AC-028

Product requirements and architecture specs mention multiple Claude Code executors working in parallel inside Antigravity.

## Autonomy Backlog Memory Acceptance Criteria

### AC-029

docs/specbridge-autonomy-backlog.md exists and records the remaining work for local CLI, contract scope validation, audit packet generation, ChatGPT audit standard, controlled implementation pilot, multi-agent pilot, and security gate expansion.

### AC-030

.specbridge/context/CURRENT_GOAL.md identifies the autonomy runtime preparation phase and names the contract scope validator as the recommended next task.

### AC-031

Future agents can determine the next execution order from repository files without relying on chat history.

## Contract Scope Validator Acceptance Criteria

### AC-032

scripts/validate-contract-scopes.ps1 exists and validates `.specbridge/scopes/*.scope.json` manifests.

### AC-033

Each scope manifest declares `exclusive_write`, `read_only`, `coordinator_owned`, `dependencies`, and `final_report`.

### AC-034

Active conflicting write scopes fail validation with contract ids and paths in the failure output.

### AC-035

Disjoint active scope manifests pass validation.

### AC-036

Duplicate final report paths fail validation.

### AC-037

Read/write relationships between active contracts require explicit dependencies.

### AC-038

scripts/specbridge-smoke.ps1 runs the contract scope validator.

## Audit Packet Generator Acceptance Criteria

### AC-039

scripts/generate-audit-packet.ps1 exists and creates deterministic `.specbridge/audit-packets/*.audit-packet.json` files.

### AC-040

scripts/validate-audit-packets.ps1 exists and validates required audit packet fields.

### AC-041

Audit packets include task id, execution contract path, changed files, diff summary, validation commands, validation results, final report path, CI status, PR review report path, policy result, unresolved risks, completion status, and source file references.

### AC-042

Audit packets reference source files by repository-relative path and do not embed raw diffs, file contents, secrets, tokens, private keys, or credential values.

### AC-043

Positive fixture generation passes and invalid audit packets fail for expected reasons.

### AC-044

scripts/specbridge-smoke.ps1 runs audit packet validation.

## ChatGPT Audit Standard Acceptance Criteria

### AC-045

.specbridge/schemas/chatgpt-audit.schema.json exists and defines the machine-readable ChatGPT audit output.

### AC-046

scripts/validate-chatgpt-audits.ps1 exists and validates `.specbridge/audits/*.chatgpt-audit.json`.

### AC-047

ChatGPT audit outcomes are limited to `approved`, `changes_requested`, `blocked`, and `needs_human_decision`.

### AC-048

Each audit checks spec compliance, acceptance criteria, policy boundaries, security rules, changed file scope, test evidence, CI evidence, and final report honesty.

### AC-049

Audit findings include severity, category, file, line, evidence, recommendation, and blocking status.

### AC-050

Blocking findings or dimensions prevent merge.

### AC-051

Positive audit fixtures pass and invalid audit fixtures fail for expected reasons.

### AC-052

scripts/specbridge-smoke.ps1 runs ChatGPT audit validation.

## Security Review Gate Expansion Acceptance Criteria

### AC-053

scripts/validate-security-gates.ps1 exists and validates changed files for deterministic security categories.

### AC-054

scripts/specbridge-smoke.ps1 runs security gate validation.

### AC-055

The security gate detects secret-like content, auth-sensitive paths, authorization-sensitive paths, CI/CD permission escalation, dependency manifest or lockfile changes, unsafe shell commands, protected path changes, and production configuration paths.

### AC-056

The negative validation suite includes a safe fixture that passes security gate validation.

### AC-057

The negative validation suite includes unsafe fixtures that fail for the expected security categories.

### AC-058

Security gate failures name the category in machine-readable output.

## Local SpecBridge CLI Acceptance Criteria

### AC-059

scripts/specbridge.ps1 exists and exposes the local file-backed CLI.

### AC-060

The CLI supports `status`, `validate`, `create-contract`, `create-report`, `audit-packet`, `detect-conflicts`, `decompose-task`, and `review-gate`.

### AC-061

CLI commands have deterministic exit codes and fail when required declared inputs or output paths are missing.

### AC-062

CLI artifact commands write only declared repository-relative output paths.

### AC-063

CLI commands do not require secrets and avoid network calls by default.

### AC-064

scripts/test-specbridge-cli.ps1 covers every CLI command.

### AC-065

scripts/specbridge-smoke.ps1 runs the CLI validation suite.

## Controlled Implementation Pilot Acceptance Criteria

### AC-066

docs/specbridge-controlled-implementation-pilot.md exists and records the first small implementation pilot after the local CLI.

### AC-067

scripts/specbridge.ps1 `status` supports `-IncludeLatestArtifacts`.

### AC-068

`status -IncludeLatestArtifacts` returns a `latest_artifacts` JSON object containing contract, scope, final report, audit packet, and ChatGPT audit paths.

### AC-069

Latest artifact selection is deterministic and orders `issue-<number>` artifact names by issue number before file name.

### AC-070

scripts/test-specbridge-cli.ps1 covers `status -IncludeLatestArtifacts`.

### AC-071

.specbridge/contracts/issue-053-controlled-implementation-pilot.execution.md exists and defines the pilot goal, scope, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-072

.specbridge/reports/issue-053-controlled-implementation-pilot.final-report.json exists and validates against the final report validator.

### AC-073

.specbridge/audit-packets/issue-053-controlled-implementation-pilot.audit-packet.json exists and validates against the audit packet validator.

### AC-074

.specbridge/audits/issue-053-controlled-implementation-pilot.chatgpt-audit.json exists and validates against the ChatGPT audit validator.

### AC-075

The controlled implementation pilot does not add secrets, production configuration, deployment automation, billing, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, authentication implementation, authorization implementation, dependency installation, CI/CD permission escalation, or CI/CD security weakening.

## Multi-Agent Pilot Acceptance Criteria

### AC-076

docs/specbridge-multi-agent-pilot.md exists and records the first file-backed multi-agent pilot.

### AC-077

.specbridge/decompositions/issue-054-multi-agent-pilot.decomposition.json exists and declares Agent A, Agent B, and Agent C slices.

### AC-078

Each pilot agent has its own execution contract.

### AC-079

Each pilot agent has its own contract scope manifest with non-overlapping write ownership.

### AC-080

scripts/test-specbridge-multi-agent-pilot.ps1 verifies a successful three-agent decomposition and deterministic duplicate write-scope rejection.

### AC-081

scripts/specbridge-smoke.ps1 runs the multi-agent pilot validation suite.

### AC-082

Each pilot agent produces a final report artifact.

### AC-083

The coordinator produces an integration report, final report, audit packet, and ChatGPT audit artifact.

### AC-084

The multi-agent pilot remains repository-first and does not launch live executor sessions, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access secrets.

## Live Antigravity Executor Handoff Acceptance Criteria

### AC-085

docs/specbridge-live-antigravity-executor-handoff.md exists and records the file-backed handoff model for Antigravity Claude Code executor sessions.

### AC-086

scripts/specbridge.ps1 supports `prepare-executors`.

### AC-087

`prepare-executors` creates `.specbridge/executor-packets/*.executor-packet.json` files from declared slice inputs.

### AC-088

Executor packets include launch mode, branch name, execution contract path, final report path, exclusive write scope, read-only scope, required validations, stop conditions, status, and source files.

### AC-089

scripts/validate-executor-packets.ps1 validates executor packet structure, repository-relative paths, launch mode, status, branch uniqueness, packet uniqueness, contract references, final report path shape, validations, stop conditions, and source files.

### AC-090

scripts/test-specbridge-executor-handoff.ps1 verifies successful three-packet generation and deterministic duplicate branch rejection.

### AC-091

scripts/specbridge-smoke.ps1 runs executor packet validation and executor handoff tests.

### AC-092

The handoff task does not launch live sessions, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access secrets.

## Branch Per Executor Orchestration Acceptance Criteria

### AC-093

docs/specbridge-branch-per-executor-orchestration.md exists and records the branch plan and coordinator evidence model.

### AC-094

scripts/specbridge.ps1 supports `plan-executor-branches`.

### AC-095

`plan-executor-branches` creates `.specbridge/branch-plans/*.branch-plan.json` files from executor packets.

### AC-096

Each branch plan declares one branch record per executor packet and records PR status, CI status, ChatGPT audit status, required validations, and rollback notes.

### AC-097

scripts/specbridge.ps1 supports `coordinate-executors`.

### AC-098

`coordinate-executors` creates `.specbridge/orchestrations/*.executor-orchestration.json` files from branch plans.

### AC-099

Simulation mode uses explicit simulation PR URLs and cannot authorize merge.

### AC-100

GitHub evidence mode requires real GitHub PR URLs, passed CI, and approved ChatGPT audit status before integration can be marked ready.

### AC-101

scripts/validate-branch-orchestrations.ps1 validates branch plan and coordinator orchestration artifacts.

### AC-102

scripts/test-specbridge-branch-orchestration.ps1 verifies successful branch planning, simulated coordination, validation, duplicate branch rejection, and simulation merge blocking.

### AC-103

scripts/specbridge-smoke.ps1 runs branch orchestration validation and branch orchestration tests.

### AC-104

The branch orchestration task does not launch live sessions, create live executor branches, open child PRs, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access protected credentials.

## Controlled GitHub Evidence Acceptance Criteria

### AC-105

docs/specbridge-controlled-github-evidence-run.md exists and records the controlled GitHub evidence model.

### AC-106

One real GitHub branch exists for each issue 058 executor packet.

### AC-107

One real GitHub child PR exists for each executor branch.

### AC-108

.specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json records child PR URL, PR number, PR status, head SHA, CI status, CI run ids, and ChatGPT/Codex audit status for every executor branch.

### AC-109

scripts/specbridge.ps1 supports `record-github-evidence`.

### AC-110

`record-github-evidence` reads a source branch plan and declared GitHub evidence input, rejects simulation URLs, and writes an evidence-recorded branch plan.

### AC-111

`coordinate-executors -EvidenceMode github` marks integration ready only when every child result has a real GitHub PR URL, passed CI, and approved ChatGPT/Codex audit status.

### AC-112

scripts/validate-branch-orchestrations.ps1 validates GitHub evidence mode records and rejects incomplete real evidence.

### AC-113

scripts/test-specbridge-branch-orchestration.ps1 verifies GitHub evidence recording, ready integration, and simulation URL rejection.

### AC-114

The controlled GitHub evidence run does not launch Antigravity sessions, start Claude Code, merge child executor PRs, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access protected credentials.

## Operational Autonomy Cleanup Acceptance Criteria

### AC-115

docs/specbridge-operational-autonomy-policy-closure.md exists and records the cleanup decision.

### AC-116

GitHub child evidence PRs 56, 57, and 58 are closed without merge.

### AC-117

GitHub issue 42 is closed as completed after a comment links the merged evidence chain.

### AC-118

.specbridge/github-evidence/issue-042-operational-autonomy-policy-closure.cleanup.json records the child PR and issue cleanup decisions.

### AC-119

The cleanup task does not merge child PRs, delete remote branches, launch Antigravity sessions, start Claude Code, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access protected credentials.

### AC-120

Repository memory identifies controlled Antigravity/Claude Code runtime launch as the next recommended task.

## Controlled Antigravity Runtime Launch Acceptance Criteria

### AC-121

docs/specbridge-controlled-antigravity-runtime-launch.md exists and records the first bounded Claude Code runtime launch from the Antigravity workspace.

### AC-122

.specbridge/contracts/issue-061-controlled-antigravity-runtime-launch.execution.md exists and defines goal, context, allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, final report requirements, and completion rule.

### AC-123

.specbridge/scopes/issue-061-controlled-antigravity-runtime-launch.scope.json exists and declares the issue 061 exclusive write paths, read-only paths, dependencies, and final report path.

### AC-124

.specbridge/executor-handoffs/issue-061-controlled-antigravity-runtime-launch.input.json exists and defines one bounded Claude runtime executor slice.

### AC-125

specbridge prepare-executors creates .specbridge/executor-packets/issue-061-controlled-antigravity-runtime-launch-claude-runtime.executor-packet.json.

### AC-126

Claude Code CLI availability, Antigravity CLI availability, and a Claude readiness probe are recorded in .specbridge/runtime-evidence/issue-061-controlled-antigravity-runtime-launch.claude-run.json.

### AC-127

Claude Code is invoked non-interactively with a bounded prompt and writes only .specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md.

### AC-128

The runtime evidence records the Claude invocation mode, tool restriction, executor packet path, exclusive write path, exit code, output artifact, and delegated validation responsibility.

### AC-129

.specbridge/reports/issue-061-controlled-antigravity-runtime-launch.final-report.json exists and validates against the final report validator.

### AC-130

.specbridge/audit-packets/issue-061-controlled-antigravity-runtime-launch.audit-packet.json exists and validates against the audit packet validator.

### AC-131

.specbridge/audits/issue-061-controlled-antigravity-runtime-launch.chatgpt-audit.json exists and validates against the ChatGPT audit validator.

### AC-132

The controlled runtime launch does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, change database schema, touch production, access protected credentials, modify auth or billing surfaces, weaken CI/CD security, or deploy anything.

## Runtime Launch Plan Acceptance Criteria

### AC-133

scripts/specbridge.ps1 supports `prepare-runtime-launch`.

### AC-134

`prepare-runtime-launch` reads one `.specbridge/executor-packets/*.executor-packet.json` file and writes one declared `.specbridge/runtime-launches/*.runtime-launch.json` file.

### AC-135

Runtime launch plans record schema version, launch id, source executor packet path, task id, packet id, slice id, branch name, execution contract path, final report path, exclusive write paths, read-only context, required validations, allowed tools, permission mode, max budget, command summary, prompt sections, stop conditions, execution policy, launch status, and source files.

### AC-136

Runtime launch plans are preparation artifacts only and do not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AC-137

scripts/validate-runtime-launches.ps1 exists and validates `.specbridge/runtime-launches/*.runtime-launch.json` artifacts.

### AC-138

scripts/specbridge.ps1 `validate -Profile standard` includes runtime launch validation.

### AC-139

scripts/specbridge-smoke.ps1 includes runtime launch validation.

### AC-140

scripts/test-specbridge-cli.ps1 covers successful `prepare-runtime-launch` generation and deterministic unapproved tool failure.

### AC-141

scripts/test-specbridge-negative-validations.ps1 covers invalid runtime launch artifacts.

### AC-142

.specbridge/runtime-launches/issue-063-prepare-runtime-launch-plans.runtime-launch.json exists and validates.

### AC-143

The runtime launch plan task does not add product runtime execution, dependency installation, MCP server implementation, GitHub App implementation, hosted dashboard implementation, database changes, production configuration, protected credential access, auth or billing changes, CI/CD weakening, or deployment automation.

## Runtime Result Recording Acceptance Criteria

### AC-144

scripts/specbridge.ps1 supports `record-runtime-result`.

### AC-145

`record-runtime-result` reads one `.specbridge/runtime-launches/*.runtime-launch.json` file, reads one declared executor evidence file, and writes one declared `.specbridge/runtime-results/*.runtime-result.json` file.

### AC-146

The executor evidence path must be declared in the source runtime launch plan `exclusive_write` set.

### AC-147

Runtime result artifacts record schema version, result id, source runtime launch path, launch id, task id, packet id, slice id, branch name, executor evidence path, exit code, files written, validation results, policy result, stop conditions, completion status, runtime status, result status, execution policy, and source files.

### AC-148

Runtime result recording is evidence capture only and does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AC-149

scripts/validate-runtime-results.ps1 exists and validates `.specbridge/runtime-results/*.runtime-result.json` artifacts.

### AC-150

scripts/specbridge.ps1 `validate -Profile standard` includes runtime result validation.

### AC-151

scripts/specbridge-smoke.ps1 includes runtime result validation.

### AC-152

scripts/test-specbridge-cli.ps1 covers successful `record-runtime-result` generation and deterministic out-of-scope evidence failure.

### AC-153

scripts/test-specbridge-negative-validations.ps1 covers invalid runtime result artifacts.

### AC-154

.specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json exists and validates.

### AC-155

The runtime result recording task does not add live launch expansion, dependency installation, MCP server implementation, GitHub App implementation, hosted dashboard implementation, database changes, production configuration, protected credential access, auth or billing changes, CI/CD weakening, or deployment automation.

## Runtime Summary Acceptance Criteria

### AC-156

scripts/specbridge.ps1 supports `summarize-runtime`.

### AC-157

`summarize-runtime` reads one `.specbridge/runtime-launches/*.runtime-launch.json` input file and one `.specbridge/runtime-results/*.runtime-result.json` evidence file.

### AC-158

`summarize-runtime` writes one declared `.specbridge/runtime-summaries/*.runtime-summary.json` output file.

### AC-159

Runtime summary artifacts record schema version, summary id, launch path, result path, launch id, task id, packet id, slice id, branch name, completion status, runtime status, result status, validation totals, policy result, merge readiness, blockers, execution policy, and source files.

### AC-160

Runtime summary generation rejects mismatched launch and result artifacts for source runtime launch path, launch id, task id, packet id, slice id, or branch name.

### AC-161

Runtime summary generation is evidence capture only and does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy.

### AC-162

scripts/validate-runtime-summaries.ps1 exists and validates `.specbridge/runtime-summaries/*.runtime-summary.json` artifacts.

### AC-163

scripts/specbridge.ps1 `validate -Profile standard` includes runtime summary validation.

### AC-164

scripts/specbridge-smoke.ps1 includes runtime summary validation.

### AC-165

scripts/test-specbridge-cli.ps1 covers successful `summarize-runtime` generation and deterministic launch/result mismatch failure.

### AC-166

scripts/test-specbridge-negative-validations.ps1 covers invalid runtime summary artifacts.

### AC-167

.specbridge/runtime-summaries/issue-067-source-backed-runtime-slice.runtime-summary.json exists and validates.

### AC-168

The source-backed runtime summary task does not add live launch expansion, dependency installation, MCP server implementation, GitHub App implementation, hosted dashboard implementation, database changes, production configuration, protected credential access, auth or billing changes, CI/CD weakening, or deployment automation.

## Fresh Executor Source Run Acceptance Criteria

### AC-169

docs/specbridge-fresh-executor-source-run.md exists and records the governed fresh executor source run model.

### AC-170

.specbridge/contracts/issue-069-fresh-executor-source-run.execution.md exists and defines goal, context, source references, allowed scope, executor exclusive write scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and completion rule.

### AC-171

.specbridge/scopes/issue-069-fresh-executor-source-run.scope.json exists and declares non-overlapping active write scope for issue 069.

### AC-172

.specbridge/executor-handoffs/issue-069-fresh-executor-source-run.input.json exists and defines one bounded runtime executor slice.

### AC-173

specbridge prepare-executors creates .specbridge/executor-packets/issue-069-fresh-executor-source-run-claude-source.executor-packet.json.

### AC-174

specbridge prepare-runtime-launch creates .specbridge/runtime-launches/issue-069-fresh-executor-source-run.runtime-launch.json from the issue 069 executor packet.

### AC-175

Claude Code is invoked non-interactively with bounded Read and Write tools and writes only docs/specbridge-fresh-executor-source-run.md and .specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md.

### AC-176

.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.claude-run.json records Claude version, invocation mode, attempts, tool restriction, exit code, files written, policy result, and source files.

### AC-177

specbridge record-runtime-result creates .specbridge/runtime-results/issue-069-fresh-executor-source-run.runtime-result.json from the issue 069 runtime launch plan and executor output evidence.

### AC-178

specbridge summarize-runtime creates .specbridge/runtime-summaries/issue-069-fresh-executor-source-run.runtime-summary.json from the issue 069 launch and result artifacts.

### AC-179

.specbridge/reports/issue-069-fresh-executor-source-run.final-report.json, .specbridge/audit-packets/issue-069-fresh-executor-source-run.audit-packet.json, and .specbridge/audits/issue-069-fresh-executor-source-run.chatgpt-audit.json exist and validate.

### AC-180

Local validations pass for executor packets, runtime launches, runtime results, runtime summaries, final reports, audit packets, ChatGPT audits, contracts, scopes, standard validation, smoke validation, security gates, review gates, and git diff whitespace.

### AC-181

The fresh executor source run does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, change database schema, touch production, access protected credentials, modify auth or billing surfaces, weaken CI/CD security, or deploy anything.

## Runtime Run Evidence Acceptance Criteria

### AC-182

scripts/specbridge.ps1 supports `run-runtime-launch`.

### AC-183

`run-runtime-launch` reads one `.specbridge/runtime-launches/*.runtime-launch.json` input file and one declared executor evidence file.

### AC-184

`run-runtime-launch` writes one declared `.specbridge/runtime-runs/*.runtime-run.json` output file.

### AC-185

Runtime-run artifacts record schema version, run id, runtime launch path, launch id, task id, packet id, slice id, branch name, executor evidence path, exit code, files written, validation results, tool restriction, permission mode, max budget, policy result, stop conditions, completion status, runtime status, run status, runner mode, execution policy, and source files.

### AC-186

Runtime-run generation rejects executor evidence or written files that are not declared in the source runtime launch plan `exclusive_write` list.

### AC-187

scripts/validate-runtime-runs.ps1 exists and validates `.specbridge/runtime-runs/*.runtime-run.json` artifacts.

### AC-188

scripts/specbridge.ps1 `validate -Profile standard` includes runtime-run validation.

### AC-189

scripts/specbridge-smoke.ps1 includes runtime-run validation.

### AC-190

scripts/test-specbridge-cli.ps1 covers successful `run-runtime-launch` generation and deterministic out-of-scope evidence failure.

### AC-191

scripts/test-specbridge-negative-validations.ps1 covers invalid runtime-run artifacts.

## Autonomy Metrics Acceptance Criteria

### AC-192

docs/specbridge-autonomy-metrics.md exists and documents source inputs, output shape, readiness interpretation, validation totals, audit usage, and stop conditions.

### AC-193

scripts/specbridge.ps1 supports `summarize-autonomy-metrics`.

### AC-194

`summarize-autonomy-metrics` reads `.specbridge/runtime-summaries/*.runtime-summary.json` and `.specbridge/runtime-results/*.runtime-result.json` files, optionally filtered by task id.

### AC-195

`summarize-autonomy-metrics` writes one declared `.specbridge/metrics/*.autonomy-metrics.json` output file.

### AC-196

Autonomy metrics artifacts record schema version, metrics id, generated by, task filter, summary count, ready count, blocked count, executor count, validation totals, runtime status counts, result status counts, completion status counts, merge readiness counts, policy gate ready rate, source summaries, source results, and source files.

### AC-197

scripts/validate-autonomy-metrics.ps1 exists and validates `.specbridge/metrics/*.autonomy-metrics.json` artifacts.

### AC-198

scripts/specbridge.ps1 `validate -Profile standard` includes autonomy metrics validation.

### AC-199

scripts/specbridge-smoke.ps1 includes autonomy metrics validation.

### AC-200

scripts/test-specbridge-cli.ps1 covers successful `summarize-autonomy-metrics` generation and deterministic missing task failure.

### AC-201

scripts/test-specbridge-negative-validations.ps1 covers invalid autonomy metrics artifacts.

## Serious Autonomous Multi-Executor Test Loop Acceptance Criteria

### AC-202

docs/specbridge-serious-autonomous-test-loop.md exists and records the governed multi-executor test loop.

### AC-203

.specbridge/contracts/issue-071-serious-autonomous-test-loop.execution.md exists and defines goal, allowed scope, blocked scope, executor exclusive write scopes, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-204

.specbridge/scopes/issue-071-serious-autonomous-test-loop.scope.json exists and declares non-overlapping issue 071 write scopes, read-only paths, coordinator-owned paths, dependencies, and final report path.

### AC-205

.specbridge/executor-handoffs/issue-071-serious-autonomous-test-loop.input.json exists and defines two bounded Claude Code executor slices.

### AC-206

specbridge prepare-executors creates issue 071 implementation and audit executor packets.

### AC-207

specbridge prepare-runtime-launch creates one issue 071 runtime launch plan per executor packet.

### AC-208

Claude Code is invoked non-interactively with bounded Read and Write tools for both issue 071 executor slices.

### AC-209

The issue 071 implementation executor writes only docs/specbridge-serious-autonomous-test-loop.md and .specbridge/runtime-evidence/issue-071-claude-implementation.executor-output.md.

### AC-210

The issue 071 audit executor writes only docs/specbridge-autonomy-metrics.md and .specbridge/runtime-evidence/issue-071-claude-audit.executor-output.md.

### AC-211

SpecBridge records one runtime-run artifact, one runtime-result artifact, and one runtime-summary artifact for each issue 071 executor slice.

### AC-212

.specbridge/metrics/issue-071-serious-autonomous-test-loop.autonomy-metrics.json exists and records summary count 2, ready count 2, blocked count 0, executor count 2, and policy gate ready rate 1.

### AC-213

.specbridge/reports/issue-071-serious-autonomous-test-loop.final-report.json, .specbridge/audit-packets/issue-071-serious-autonomous-test-loop.audit-packet.json, and .specbridge/audits/issue-071-serious-autonomous-test-loop.chatgpt-audit.json exist and validate.

### AC-214

Local validations pass for executor packets, runtime launches, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, contracts, scopes, standard validation, smoke validation, security gates, review gates, and git diff whitespace.

### AC-215

The serious autonomous multi-executor test loop does not add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, change database schema, touch production, access protected credentials, modify auth or billing surfaces, weaken CI/CD security, or deploy anything.

## Standard Loop V1 Acceptance Criteria

### AC-216

docs/specbridge-standard-loop-v1.md exists and defines the canonical path from ChatGPT/Codex goal to contract, scope, executor packet, runtime launch, controlled execution, evidence, audit, GitHub CI, review gate, security gate, and merge.

### AC-217

docs/specbridge-standard-loop-feature-pilot.md exists and records `standard-loop-status` as the first real Standard Loop v1 feature pilot.

### AC-218

docs/specbridge-standard-templates.md exists and records the standard template set.

### AC-219

docs/specbridge-ci-authority-standard.md exists and defines GitHub CI, security gate, review gate, and CI authority without modifying `.github/workflows/**`.

### AC-220

docs/specbridge-v5-live-parallel-pilot-boundary.md exists and defines the next live parallel Antigravity pilot boundary.

### AC-221

templates/specbridge includes execution contract, scope manifest, executor handoff, runtime launch, final report, audit packet, and ChatGPT audit templates.

### AC-222

scripts/validate-standard-templates.ps1 exists and validates the standard template set.

### AC-223

scripts/validate-standard-ci-authority.ps1 exists and validates CI authority documentation and required existing workflow presence without authorizing workflow security control changes.

### AC-224

scripts/specbridge.ps1 supports `standard-loop-status`.

### AC-225

`standard-loop-status` reports template, schema, validator, existing CI workflow, latest artifact, missing path, and CI security boundary evidence.

### AC-226

scripts/specbridge.ps1 supports `execute-runtime-launch`.

### AC-227

`execute-runtime-launch -DryRun` writes one `.specbridge/runtime-executions/*.runtime-execution.json` artifact without launching Claude Code, requiring network, touching secrets, touching production, installing dependencies, or deploying.

### AC-228

scripts/validate-runtime-executions.ps1 exists and validates runtime execution artifacts, including launch references, tool restrictions, timeout bounds, stream evidence, execution policy, and launch field consistency.

### AC-229

.specbridge/executor-packets/issue-073-standard-loop-v1-standard-feature.executor-packet.json, .specbridge/runtime-launches/issue-073-standard-feature.runtime-launch.json, and .specbridge/runtime-executions/issue-073-standard-feature.runtime-execution.json exist and validate.

### AC-230

.specbridge/schemas includes schemas for executor packets, runtime launches, runtime runs, runtime results, runtime summaries, autonomy metrics, and runtime executions.

### AC-231

scripts/specbridge.ps1 `validate -Profile standard` and scripts/specbridge-smoke.ps1 include standard templates, CI authority, and runtime execution validation.

### AC-232

scripts/test-specbridge-cli.ps1 covers `standard-loop-status`, `execute-runtime-launch -DryRun`, and live execution rejection without `-Force`.

### AC-233

scripts/test-specbridge-negative-validations.ps1 covers invalid runtime execution artifacts, invalid standard templates, and missing CI authority workflow evidence.
