# SpecBridge Test Results

## Purpose

This document records the current local test evidence for SpecBridge.

CI evidence must still be read from GitHub pull request checks after the branch is pushed.

## Test Run

- Date: 2026-06-04
- Environment: local PowerShell workspace
- Branch: `codex/v5-runner-hardening`
- Scope: post-merge issue 080 closure plus V5 runner hardening for default runtime budget, ASCII-stable diagnostic previews, local-only agent settings ignore rules, and focused CLI coverage

## Results

| Area | Result |
| --- | --- |
| Foundation validation | passed |
| Contract validation | passed |
| Contract scope validation | passed |
| Schema validation | passed |
| Final report validation | passed |
| Audit packet validation | passed |
| ChatGPT audit validation | passed |
| Executor packet validation | passed |
| Branch orchestration validation | passed |
| Security gate validation | passed |
| Local CLI validation | passed |
| Controlled implementation pilot CLI feature | passed |
| Multi-agent pilot validation | passed |
| Executor handoff validation | passed |
| Branch orchestration validation suite | passed |
| Controlled GitHub evidence recording | passed |
| Operational autonomy cleanup evidence | passed |
| Controlled Antigravity runtime launch | passed |
| Claude Code availability | passed |
| Antigravity CLI availability | passed |
| Claude bounded executor invocation | passed |
| Runtime launch plan validation | passed |
| Runtime launch plan CLI generation | passed |
| Runtime result validation | passed |
| Runtime result CLI recording | passed |
| Runtime summary validation | passed |
| Runtime summary CLI generation | passed |
| Fresh Claude executor source run | passed |
| Fresh runtime result recording | passed |
| Fresh runtime summary generation | passed |
| Runtime-run validation | passed |
| Runtime-run CLI evidence capture | passed |
| Serious multi-executor Claude Code slices | passed |
| Serious multi-executor runtime result recording | passed |
| Serious multi-executor runtime summary generation | passed |
| Autonomy metrics validation | passed |
| Autonomy metrics CLI generation | passed |
| Standard Loop status CLI feature | passed |
| Standard template validation | passed |
| Standard CI authority validation | passed |
| Runtime execution validation | passed |
| Runtime execution CLI dry-run | passed |
| V5 live parallel pilot boundary | passed |
| V5 pilot readiness status CLI feature | passed |
| V5 readiness executor packet generation | passed |
| V5 readiness runtime launch planning | passed |
| V5 readiness runtime dry-run evidence | passed |
| V5 readiness runtime-run recording | passed |
| V5 readiness runtime result recording | passed |
| V5 readiness runtime summary generation | passed |
| V5 readiness autonomy metrics | passed |
| Runtime capability status CLI feature | passed |
| V5 live status CLI feature | passed |
| Runtime execution failure diagnostics | passed |
| Runtime launch default budget | passed |
| Runtime execution Unicode diagnostic preview normalization | passed |
| Issue 080 post-merge repository memory closure | passed |
| Local-only agent settings ignore rules | passed |
| V5 live executor packet generation | passed |
| V5 live runtime launch planning | passed |
| V5 live docs executor attempt | passed |
| V5 live tests executor attempt | passed |
| V5 live CLI executor repeated failure recorded | passed |
| V5 live CLI coordinator remediation | passed |
| V5 live runtime-run recording | passed |
| V5 live runtime result recording | passed |
| V5 live runtime summary generation | passed |
| V5 live autonomy metrics | passed |
| Hardened ChatGPT audit cross-checks | passed |
| PR review report validation | passed |
| Claude review workflow validation | passed |
| Autonomous execution protocol validation | passed |
| Review gate validation | passed |
| Negative validation suite | passed |
| Smoke validation | passed |
| Git diff check | passed |

## Negative Test Coverage

The negative validation suite verifies:

- missing required foundation file fails
- incomplete execution contract fails
- disjoint active contract scope manifests pass
- missing contract scope `exclusive_write` fails
- conflicting active contract write paths fail
- duplicate contract scope final report paths fail
- valid audit packet fixture generation passes
- audit packet generation with missing execution contract fails
- audit packet missing required field fails
- audit packet with raw diff field fails
- valid ChatGPT audit fixture passes
- ChatGPT audit missing required dimension fails
- approved ChatGPT audit with blocking finding fails
- non-approved ChatGPT audit with merge allowed fails
- safe security gate fixture passes
- secret-like content fails with the expected security category
- auth-sensitive path fails with the expected security category
- authorization-sensitive path fails with the expected security category
- CI/CD permission escalation fails with the expected security category
- dependency manifest addition fails with the expected security category
- unsafe shell command content fails with the expected security category
- protected path change fails with the expected security category
- production configuration path fails with the expected security category
- local CLI status command passes
- local CLI status latest artifacts command passes
- local CLI validation command passes
- local CLI contract generation passes and validates
- local CLI final report generation passes and validates
- local CLI audit packet generation passes and validates
- local CLI task decomposition passes
- local CLI executor handoff packet generation passes and validates
- local CLI branch planning passes and validates
- local CLI GitHub evidence recording passes and rejects simulation URLs
- local CLI simulated executor coordination passes and validates
- local CLI conflict detection passes
- local CLI review gate passes
- local CLI missing output path fails deterministically
- multi-agent pilot three-slice decomposition passes
- multi-agent pilot duplicate write scope fails deterministically
- executor handoff three-packet generation passes
- executor handoff duplicate branch fails deterministically
- branch orchestration plan generation passes
- branch orchestration simulated coordination passes
- branch orchestration duplicate branch fails deterministically
- branch orchestration simulation evidence cannot authorize merge
- branch orchestration GitHub evidence recording passes with real-shaped PR URLs
- branch orchestration GitHub evidence mode marks integration ready with passed CI and approved audit
- branch orchestration GitHub evidence recording rejects simulation URLs
- controlled Antigravity runtime launch executor packet validates
- controlled Antigravity runtime launch records Claude Code availability, Antigravity availability, readiness probe, executor invocation, and single-file executor output evidence
- runtime launch plan validation passes
- runtime launch plan CLI generation passes
- runtime launch plan unapproved tool failure is rejected deterministically
- invalid runtime launch artifact fails validation
- runtime result validation passes
- runtime result CLI recording passes
- runtime result out-of-scope evidence failure is rejected deterministically
- invalid runtime result artifact fails validation
- runtime summary validation passes
- runtime summary CLI generation passes
- runtime summary launch/result mismatch failure is rejected deterministically
- invalid runtime summary artifact fails validation
- controlled fresh executor source run writes only declared exclusive scope paths
- controlled fresh executor source run records Claude Code invocation evidence
- fresh runtime result records executor evidence and written files from the issue 069 launch plan
- fresh runtime summary reaches `ready_for_policy_gates` with no blockers
- runtime-run validation passes
- runtime-run out-of-scope evidence failure is rejected deterministically
- autonomy metrics validation passes
- autonomy metrics invalid ready count failure is rejected deterministically
- ChatGPT audit final report mismatch against the source audit packet is rejected deterministically
- controlled serious multi-executor source run writes only declared exclusive scope paths
- issue 071 runtime-run artifacts record both Claude Code executor slices
- issue 071 runtime summaries reach `ready_for_policy_gates` with no blockers
- issue 071 autonomy metrics record `summary_count: 2`, `ready_count: 2`, `blocked_count: 0`, and `policy_gate_ready_rate: 1`
- local CLI standard-loop-status command passes
- local CLI v5-pilot-status command passes
- local CLI v5-live-status command passes
- local CLI runtime-capability-status command passes
- local CLI runtime execution dry-run command passes, writes validated evidence, and records `failure_diagnostics`
- local CLI runtime launch generation uses the default `max_budget_usd: 2.00` when no explicit budget is provided
- local CLI fake live runtime execution failure records stdout-only diagnostics and normalizes non-ASCII preview text before validation
- local CLI live runtime execution without `-Force` fails deterministically
- standard template validation passes
- standard template missing `{{TASK_ID}}` placeholder fails deterministically
- standard CI authority validation passes
- standard CI authority missing required workflow evidence fails deterministically
- runtime execution validation passes
- invalid runtime execution missing the `Write` tool fails deterministically
- incomplete final report fails
- blocked PR path fails

## Policy Result

Passed. The change closes issue 080 repository memory after PR 81 merge, keeps local-only `.agents/` and `.claude/settings.local.json` out of committed scope, raises the bounded default live runtime budget to `2.00`, and makes `execute-runtime-launch` diagnostic previews ASCII-stable before truncation. The task uses a fake local `claude` fixture for failure diagnostics and does not launch real live Claude Code or Antigravity sessions, access protected credentials, touch production, install dependencies, modify auth or billing surfaces, weaken CI/CD security, change database schema, or deploy.

## Unresolved Risks

- GitHub PR CI evidence is pending until the branch is pushed and GitHub runs checks.
- The next serious live pilot should use the hardened `2.00` default and should target live completion without coordinator remediation.
