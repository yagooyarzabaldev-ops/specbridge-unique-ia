# SpecBridge Test Results

## Purpose

This document records the current local test evidence for SpecBridge.

CI evidence must still be read from GitHub pull request checks after the branch is pushed.

## Test Run

- Date: 2026-05-22
- Environment: local PowerShell workspace
- Branch: `codex/fresh-executor-source-run`
- Scope: Controlled fresh executor source run for issue 069 with Claude Code bounded output, runtime launch plan, runtime result, runtime summary, final report, audit packet, and ChatGPT/Codex audit

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
- incomplete final report fails
- blocked PR path fails

## Policy Result

Passed. The change adds a bounded fresh Claude Code executor source run, records runtime-result and runtime-summary evidence, updates repository memory, and adds contract, scope, final report, audit evidence, audit packet evidence, validation, and documentation. Claude Code wrote only declared executor paths and the coordinator-owned commands did not access protected credentials, touch production, install dependencies, modify auth or billing surfaces, weaken CI/CD security, change database schema, or deploy.

## Unresolved Risks

- Fresh executor source run PR CI evidence is pending until the branch is pushed and GitHub runs checks.
- Multi-executor fresh runtime evidence remains future work.
