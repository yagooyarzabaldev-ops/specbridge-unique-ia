# SpecBridge Autonomy Metrics

## Purpose

Autonomy metrics measure whether a SpecBridge runtime loop is completing inside
declared policy and scope without human interruption. They do not authorize merge
by themselves. They tell the coordinator and ChatGPT/Codex auditor whether runtime
evidence is ready to advance to policy gates.

## Source Inputs

The metrics command reads coordinator-owned runtime evidence:

```text
.specbridge/runtime-summaries/*.runtime-summary.json
.specbridge/runtime-results/*.runtime-result.json
```

It does not launch Claude Code, execute shell commands, call GitHub, install
dependencies, touch secrets, touch production, or deploy.

## Generated Output Shape

Autonomy metrics live under:

```text
.specbridge/metrics/<task>.autonomy-metrics.json
```

Each metrics artifact records:

- `schema_version` - artifact schema version.
- `metrics_id` - stable metrics identifier.
- `generated_by` - tool that created the artifact.
- `task_filter` - task id used to filter source summaries and results, when set.
- `summary_count` - runtime summaries evaluated.
- `ready_count` - summaries with `merge_readiness: ready_for_policy_gates`.
- `blocked_count` - summaries with `merge_readiness: blocked`.
- `executor_count` - unique executor slice ids represented in summaries.
- `validation_totals` - aggregate total, passed, failed, and other counts.
- `runtime_status_counts` - count map by runtime status.
- `result_status_counts` - count map by runtime result status.
- `completion_status_counts` - count map by completion status.
- `merge_readiness_counts` - count map by merge readiness.
- `policy_gate_ready_rate` - ready summaries divided by total summaries.
- `source_summaries` - runtime summary files evaluated.
- `source_results` - runtime result files available for the same task filter.
- `source_files` - combined source references.

## Readiness Interpretation

`policy_gate_ready_rate` is the primary readiness signal.

| Rate | Interpretation |
|---|---|
| `1.0` | All evaluated executor slices are ready to proceed to policy gates. |
| `< 1.0` | One or more evaluated slices are blocked or incomplete. |
| `0.0` | No evaluated slice is ready for policy gates. |

A rate of `1.0` does not authorize merge. It supports advancing to CI, security
gate, review gate, audit packet validation, and ChatGPT/Codex audit.

## Validation Totals

Validation totals are aggregated from each runtime summary's `validation_totals`
object:

- `passed` - validation records that passed.
- `failed` - validation records that failed.
- `other` - validation records that were neither passed nor failed.

The validator confirms that totals are internally consistent, counts are
non-negative, source summaries exist, source result paths exist, and the ready
rate is between `0` and `1`.

## Blocker Categories

Blockers remain in runtime summaries. The metrics artifact does not duplicate the
full blocker list; it counts readiness and preserves source summary references so
the auditor can inspect blocker details directly.

A summary with `merge_readiness: blocked` must include blockers. A summary with
`merge_readiness: ready_for_policy_gates` must have an empty blocker list.

## Policy Gate Ready Rate

The policy gate ready rate is computed as:

```text
policy_gate_ready_rate = ready_count / summary_count
```

For issue-071, the expected serious-loop result is:

```text
summary_count = 2
ready_count = 2
blocked_count = 0
executor_count = 2
policy_gate_ready_rate = 1.0
```

## Audit Usage

ChatGPT/Codex uses autonomy metrics with the execution contract, runtime launches,
runtime runs, runtime results, and runtime summaries.

The auditor checks:

- `summary_count` matches the expected executor slice count.
- `executor_count` matches the expected unique slice count.
- `validation_totals.failed` is `0`.
- `validation_totals.other` is `0` for merge-ready slices.
- `blocked_count` is `0`.
- `policy_gate_ready_rate` is `1.0`.
- Every source summary and result exists and validates.

The audit result is written to:

```text
.specbridge/audits/<task>.chatgpt-audit.json
```

The autonomy metrics artifact is referenced by the audit packet as supporting
evidence.

## Stop Conditions

Metrics generation stops if:

- the runtime summaries directory is missing
- the runtime results directory is missing
- no runtime summaries match the requested task filter
- the output path is outside `.specbridge/metrics/*.autonomy-metrics.json`
- a source summary or source result is invalid JSON

Policy stop conditions are still evaluated by the runtime summary, audit packet,
security gate, review gate, and merge policy layers.

## How ChatGPT Audits Claude Code Compliance

ChatGPT/Codex audits Claude Code compliance by comparing the metrics artifact to
the lower-level runtime evidence:

1. Scope compliance: compare `exclusive_write` in the runtime launch plan against
   `files_written` in the runtime run and runtime result.
2. Tool compliance: confirm executor evidence does not report shell execution,
   network calls, dependency installation, or tools beyond Read and Write.
3. Stop condition compliance: confirm blocked summaries include blockers and
   ready summaries do not hide stop conditions.
4. Validation compliance: confirm aggregate validation totals match runtime
   summaries and do not include failed or other results for merge-ready slices.
5. Policy compliance: confirm execution policy booleans are false in runtime
   launch, runtime run, runtime result, and runtime summary artifacts.
6. Spec compliance: compare executor outputs against the execution contract and
   acceptance criteria.
7. Security compliance: confirm protected paths such as `.env`, secrets, and
   `infra/prod` do not appear in written files or changed files.

The audit must pass `scripts/validate-chatgpt-audits.ps1` before merge is
considered.
