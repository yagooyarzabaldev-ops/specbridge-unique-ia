# SpecBridge Fresh Executor Source Run

## Purpose

This document governs how a fresh, bounded Claude Code executor run is declared,
scoped, executed, and evidenced through the SpecBridge runtime evidence layers.

A fresh executor source run is a controlled single-purpose execution: Claude Code
operates non-interactively with Read and Write tools only, writes exactly the files
declared in its executor exclusive write scope, and produces verifiable runtime
evidence that SpecBridge can record, summarize, and audit.

The task that produced this document is issue-069-fresh-executor-source-run. It
proves that the runtime layers added in issues 063, 065, and 067 (launch plans,
result recording, runtime summaries) can accept output from a dedicated source-backed
executor contract declared after those layers exist.

## Contract Boundary

Every fresh executor source run must be backed by:

1. An execution contract at .specbridge/contracts/<task-id>.execution.md
2. An executor packet at .specbridge/executor-packets/<task-id>-<slice>.executor-packet.json
3. A runtime launch plan at .specbridge/runtime-launches/<task-id>.runtime-launch.json

The execution contract defines:
- task goal and context
- allowed scope and blocked scope
- executor exclusive write scope (maximum two paths per executor)
- required validations
- stop conditions
- merge and deployment policy
- completion rule

The executor packet carries:
- packet_id, task_id, slice_id
- agent_role: runtime_executor
- goal, launch_mode, branch_name
- exclusive_write list (must match execution contract)
- read_only list
- required_validations
- stop_conditions
- status: ready_for_handoff

The runtime launch plan confirms the executor packet is ready and records the
planned launch parameters before Claude Code is invoked.

## Executor Write Scope

For issue-069-fresh-executor-source-run the executor may write exactly:

  docs/specbridge-fresh-executor-source-run.md
  .specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md

All other files in the repository are read-only for this executor. The coordinator
owns all other allowed paths listed in the execution contract.

Rule: an executor that writes outside its exclusive write scope has violated the
contract. SpecBridge must record that violation in the runtime result and block merge.

## Runtime Evidence Flow

After the executor writes its two output files the evidence chain is:

  1. Executor output
     .specbridge/runtime-evidence/<task-id>.executor-output.md
     Written by Claude Code. Records task id, contract id, files written,
     validations requested, policy result, unresolved risks, and completion status.

  2. Claude run evidence (coordinator-owned)
     .specbridge/runtime-evidence/<task-id>.claude-run.json
     Records exit code, tool calls, scope check result, and raw executor output path.

  3. Runtime result (coordinator-owned)
     .specbridge/runtime-results/<task-id>.runtime-result.json
     Records executor evidence, validation results, scope verdict, and merge readiness.

  4. Runtime summary (coordinator-owned)
     .specbridge/runtime-summaries/<task-id>.runtime-summary.json
     Links launch plan and runtime result. Records merge readiness and blockers.

  5. Final report (coordinator-owned)
     .specbridge/reports/<task-id>.final-report.json

  6. Audit packet (coordinator-owned)
     .specbridge/audit-packets/<task-id>.audit-packet.json

  7. ChatGPT/Codex audit (coordinator-owned)
     .specbridge/audits/<task-id>.chatgpt-audit.json

The executor writes only step 1. All subsequent steps are produced by the SpecBridge
coordinator and Codex, not by Claude Code.

## Validation and Audit

Required validations for this task (to be run by SpecBridge/Codex, not by this executor):

  validate-executor-packets.ps1
  validate-runtime-launches.ps1
  validate-runtime-results.ps1
  validate-runtime-summaries.ps1
  validate-final-reports.ps1
  validate-audit-packets.ps1
  validate-chatgpt-audits.ps1
  validate-contracts.ps1
  validate-contract-scopes.ps1
  specbridge.ps1 validate -Profile standard
  specbridge-smoke.ps1
  validate-security-gates.ps1
  validate-review-gate.ps1
  git diff --check

Runtime validations listed above are delegated to SpecBridge/Codex. This executor
does not run shell commands, CI pipelines, or external tools.

The audit trail is preserved in:
- Git commit history (branch: codex/fresh-executor-source-run)
- Executor output evidence file
- Runtime result and summary artifacts produced by the coordinator

## Stop Conditions

This executor must stop and report BLOCKED if:

- Required context is missing (execution contract, executor packet)
- The task requires writing outside the declared executor exclusive write scope
- The task requires tools beyond Read and Write
- The task requires secrets, production configuration, billing changes, or auth changes
- The task requires dependency installation, database changes, or deployment automation
- The acceptance criteria are contradictory or impossible
- A policy conflict is detected between the contract and repository policy

If any stop condition is met this executor writes the reason in the executor output
completion status field and does not proceed.

## Completion Evidence

This executor's work is complete when:

1. docs/specbridge-fresh-executor-source-run.md exists and contains all required sections.
2. .specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md
   exists and records task id, contract id, files written, validations requested,
   policy result, unresolved risks, and completion status.
3. No files outside the executor exclusive write scope were written.
4. No blocked tools, commands, or resources were accessed.

SpecBridge/Codex must then complete the runtime result, runtime summary, final report,
audit packet, and ChatGPT/Codex audit before the task is considered fully complete and
eligible for policy-gated merge.
