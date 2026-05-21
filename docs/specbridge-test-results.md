# SpecBridge Test Results

## Purpose

This document records the current local test evidence for SpecBridge.

CI evidence must still be read from GitHub pull request checks after the branch is pushed.

## Test Run

- Date: 2026-05-21
- Environment: local PowerShell workspace
- Branch: `codex/executor-pr-evidence-cleanup`
- Scope: Operational autonomy cleanup with issue 42 closure, child evidence PR closure, cleanup evidence, and repository memory updates

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
- incomplete final report fails
- blocked PR path fails

## Policy Result

Passed. The change closes stale GitHub evidence work, records cleanup evidence, updates repository memory, and adds contract, scope, final report, audit evidence, audit packet evidence, and documentation. It does not add protected credentials, production configuration, deployment automation, billing, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, authentication implementation, authorization implementation, branch protection weakening, dependency installation, live Antigravity session launch, live Claude Code process launch, child PR merge, branch deletion, or CI/CD security weakening.

## Unresolved Risks

- Cleanup PR CI evidence is pending until the branch is pushed and GitHub runs checks.
- Remote evidence branches remain available but abandoned; this cleanup does not delete branches.
- The next runtime launch remains blocked until a dedicated contract authorizes it.
