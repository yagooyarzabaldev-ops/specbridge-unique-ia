# SpecBridge Serious Autonomous Test Loop

## Purpose

This document governs the first serious multi-executor autonomous test loop for
SpecBridge. It extends the issue-069 proof from one bounded fresh executor output
chain to two executor slices governed by one goal, each writing only inside an
exclusive non-overlapping scope, with automatic runtime evidence capture, hardened
ChatGPT/Codex audit validation, and autonomy metrics.

The loop proves this chain:

```text
ChatGPT/Codex governs -> SpecBridge contracts -> Claude Code executor slices ->
runtime evidence -> autonomy metrics -> ChatGPT/Codex audit -> policy-gated merge
```

## Preconditions

Before this loop may run:

- Issue-069 stale active memory is closed by marking its scope completed.
- The issue-071 execution contract exists and validates.
- Two non-overlapping executor packets are generated from one handoff input.
- One runtime launch plan exists per executor packet.
- `scripts/validate-contract-scopes.ps1` confirms active scope boundaries.
- `scripts/validate-executor-packets.ps1` passes for both packets.
- `scripts/validate-runtime-launches.ps1` passes for both launch plans.
- No secrets, production configuration, billing, auth security, dependency
  installation, database changes, CI/CD weakening, or deployment automation are
  involved.

## Fresh-Source Multi-Executor Shape

Issue-071 runs two executor slices from a single governed goal:

```text
SpecBridge Coordinator
  issue-071-serious-autonomous-test-loop.execution.md
  issue-071-serious-autonomous-test-loop.scope.json

Executor Slice A: claude-implementation
  packet: issue-071-serious-autonomous-test-loop-claude-implementation.executor-packet.json
  launch: issue-071-claude-implementation.runtime-launch.json
  exclusive write:
    docs/specbridge-serious-autonomous-test-loop.md
    .specbridge/runtime-evidence/issue-071-claude-implementation.executor-output.md

Executor Slice B: claude-audit
  packet: issue-071-serious-autonomous-test-loop-claude-audit.executor-packet.json
  launch: issue-071-claude-audit.runtime-launch.json
  exclusive write:
    docs/specbridge-autonomy-metrics.md
    .specbridge/runtime-evidence/issue-071-claude-audit.executor-output.md
```

Each slice runs non-interactively with `Read` and `Write` tools only. All other
repository paths are read-only for the executor.

The coordinator owns all other allowed paths: CLI scripts, validation scripts,
runtime runs, runtime results, runtime summaries, final report, audit packet,
ChatGPT/Codex audit, and scope manifests.

## Executor Isolation

Each executor must write only inside its declared exclusive write scope.

Enforcement:

- The execution contract lists one exclusive write scope per slice.
- The scope manifest declares `exclusive_write`, `read_only`, and
  `coordinator_owned` paths.
- `scripts/validate-contract-scopes.ps1` rejects active contract write overlap.
- `run-runtime-launch` records the executor evidence path and actual written files.
- `scripts/validate-runtime-runs.ps1` rejects runtime-run files whose written files
  are outside the launch plan `exclusive_write` list.

An executor that writes a file not declared in `exclusive_write` has violated the
contract. SpecBridge records that failure by refusing the runtime-run artifact or
by blocking the later runtime summary.

## Small Real Implementation Pilot

Issue-071 includes a small real implementation payload: each executor slice creates
an operational document that becomes part of the product evidence.

The pilot demonstrates:

1. One handoff input is the source of truth for both slices.
2. Each slice receives a packet derived from that input.
3. Each slice writes only its assigned output.
4. Runtime launch, runtime-run, runtime-result, and runtime-summary artifacts link
   the executor output back to the same contract.
5. The autonomy metrics artifact aggregates both slices before audit and merge.

This is intentionally small. The purpose is governance proof, not feature size.

## Runtime Launch Evidence

Before any executor is invoked:

- A launch plan is created under `.specbridge/runtime-launches/`.
- Each launch plan records `launch_id`, `packet_id`, `slice_id`, `goal`,
  `branch_name`, `exclusive_write`, `read_only`, `required_validations`,
  `allowed_tools`, `permission_mode`, `max_budget_usd`, `stop_conditions`,
  `launch_status`, and `execution_policy`.
- `execution_policy` confirms the launch artifact itself does not launch Claude,
  execute shell commands, require network, touch secrets, touch production, install
  dependencies, or deploy.
- `scripts/validate-runtime-launches.ps1` passes before the executor session is
  treated as launchable.

## Automatic Runtime-Run Evidence Capture

After each executor session completes, the coordinator runs:

```powershell
specbridge run-runtime-launch
```

This command writes one `.specbridge/runtime-runs/*.runtime-run.json` artifact per
slice. It records:

- `run_id`, `launch_id`, `task_id`, `packet_id`, `slice_id`, and `branch_name`
- `executor_evidence_path`
- `exit_code`
- `files_written`
- `validation_results`
- `tool_restriction`, `permission_mode`, and `max_budget_usd`
- `policy_result`
- `stop_conditions`
- `completion_status`, `runtime_status`, and `run_status`
- `runner_mode`
- `execution_policy`
- `source_files`

The runtime-run artifact is the first coordinator-owned record of what the bounded
executor session produced. It feeds the runtime result and runtime summary layers.

## ChatGPT/Codex Audit Handoff

After both slices are complete and runtime summaries are written, the coordinator
generates an audit packet at:

```text
.specbridge/audit-packets/issue-071-serious-autonomous-test-loop.audit-packet.json
```

The audit packet includes contract, final report, changed files, validations,
policy result, risk result, completion status, CI status, and source files.

ChatGPT/Codex reviews that packet against the execution contract and writes:

```text
.specbridge/audits/issue-071-serious-autonomous-test-loop.chatgpt-audit.json
```

The hardened audit validator rejects audits that mismatch the packet contract path,
mismatch the packet final report path, approve blocked completion statuses, approve
failed validation evidence, or approve with blocking findings.

## Autonomy Metrics

After both runtime summaries pass validation, the coordinator runs:

```powershell
specbridge summarize-autonomy-metrics
```

This writes:

```text
.specbridge/metrics/issue-071-serious-autonomous-test-loop.autonomy-metrics.json
```

The metrics artifact records:

- `summary_count`, `ready_count`, `blocked_count`, and `executor_count`
- aggregate `validation_totals`
- runtime, result, completion, and merge-readiness count maps
- `policy_gate_ready_rate`
- `source_summaries`, `source_results`, and `source_files`

`scripts/validate-autonomy-metrics.ps1` validates the artifact before audit and
merge gates are evaluated.

## Completion Criteria

This test loop is complete when:

1. Both executor slices write their assigned output files.
2. Both executor output evidence files record completion status.
3. Both runtime-run artifacts exist and validate.
4. Both runtime-result artifacts exist and validate.
5. Both runtime-summary artifacts record `merge_readiness:
   ready_for_policy_gates`.
6. `scripts/validate-runtime-runs.ps1` passes.
7. `scripts/validate-runtime-results.ps1` passes.
8. `scripts/validate-runtime-summaries.ps1` passes.
9. `scripts/validate-autonomy-metrics.ps1` passes.
10. The ChatGPT/Codex audit declares an approved outcome.
11. `scripts/validate-chatgpt-audits.ps1` passes.
12. GitHub CI passes on the branch.
13. The deterministic review gate passes.
14. The security gate passes.
15. No protected file was changed.
16. No policy violation was recorded in runtime evidence.
17. Policy-gated merge is allowed by the coordinator after all gates pass.

A task is done when repository evidence says it is done, not when an agent says so.

## Stop Conditions

Any executor slice must stop and report blocked status if:

- The task requires writing outside declared `exclusive_write` scope.
- The task requires tools beyond `Read` and `Write`.
- Required context is missing.
- Acceptance criteria are contradictory or impossible within scope.
- Secrets, production configuration, billing, auth security, dependency
  installation, database changes, CI/CD weakening, or deployment automation are
  required.
- A policy conflict is detected between the contract and `.specbridge/policy.yaml`.

The coordinator must stop and escalate if:

- Runtime-run generation rejects executor output as out of scope.
- A runtime summary records `merge_readiness: blocked`.
- The ChatGPT/Codex audit records a non-approved outcome with unresolved blocking
  findings.
- The security gate fails for a blocked category.

Stopping is not failure. Silent policy bypass is failure.

## Next V5-Ready Pilot

After issue-071 merges, the repository will have:

- Two-slice executor evidence chain with shared governance.
- Automatic runtime-run evidence capture via `run-runtime-launch`.
- Autonomy metrics generated and validated locally.
- Hardened ChatGPT/Codex audit rejection for contradictory audit packets.

The next pilot candidate for V5 readiness is a live parallel multi-executor run
where both slices are launched into separate Antigravity sessions, with the
coordinator tracking both runtime runs and holding the merge gate until all
executor summaries are ready for policy gates.

Until that contract explicitly authorizes simultaneous live Antigravity launch,
live parallel launch remains future runtime work.
