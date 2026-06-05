# SpecBridge Multi-Slice Live Pilot Contract

## Purpose

Issue 097 prepares the next multi-slice live pilot contract from the
`standard-loop-orchestrate` `next_contract_seed`.

The result is a repository-backed handoff package for later operator launch.
This issue does not execute the live pilot.

## Prepared Slices

The handoff defines three non-overlapping executor slices:

| Slice | Role | Exclusive write scope |
|---|---|---|
| `status` | implementation | `scripts/specbridge.ps1`, `.specbridge/runtime-evidence/issue-097-status.executor-output.md` |
| `tests` | validation | `scripts/test-specbridge-cli.ps1`, `.specbridge/runtime-evidence/issue-097-tests.executor-output.md` |
| `docs` | documentation | `docs/specbridge-multi-slice-live-pilot-contract.md`, `.specbridge/runtime-evidence/issue-097-docs.executor-output.md` |

## Generated Artifacts

The prepared package includes:

- `.specbridge/executor-handoffs/issue-097-multi-slice-live-pilot-contract.input.json`
- `.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-status.executor-packet.json`
- `.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-tests.executor-packet.json`
- `.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-docs.executor-packet.json`
- `.specbridge/runtime-launches/issue-097-status.runtime-launch.json`
- `.specbridge/runtime-launches/issue-097-tests.runtime-launch.json`
- `.specbridge/runtime-launches/issue-097-docs.runtime-launch.json`

## Launch Boundary

The runtime launch artifacts are plan-only.

They record:

- `launches_claude=false`
- `launches_antigravity=false`
- `executes_shell=false`
- `installs_dependencies=false`
- `deploys=false`

A future live execution must use a dedicated contract and must still respect the
declared executor packet, launch plan, budget, tools, stop conditions, security
gate, review gate, and GitHub CI authority.

## Prepared Status Slice

The `status` slice is the implementation lane for one bounded SpecBridge status surface in `scripts/specbridge.ps1`.

The prepared status slice must:

- modify only the declared status surface file and executor evidence file
- stay inside the issue 097 launch plan tool, budget, and stop-condition boundary
- report changed files, validation evidence, policy result, unresolved risks, and completion status

The `status` slice exclusive write scope is:

- `scripts/specbridge.ps1`
- `.specbridge/runtime-evidence/issue-097-status.executor-output.md`

The status slice was later executed by issue 105.

## Runtime Boundary

Every slice executor is bounded by:

- non-overlapping exclusive write paths declared in the executor packet
- a `launches_claude=false`, `launches_antigravity=false`, `executes_shell=false`, `installs_dependencies=false`, `deploys=false` plan-only runtime launch artifact
- a budget ceiling declared in the launch plan
- a tool allow-list (`Read`, `Write`, `Edit`)
- stop conditions that halt execution on policy conflict, scope conflict, missing required context, impossible acceptance criteria, or protected resource requirement

A live executor must stay inside these constraints. Any write outside the declared exclusive paths is a scope violation.

## Live Docs Slice Outcome

Issue 101 authorized the first post-preflight bounded live execution of this docs slice.

The live executor ran under the executor packet `issue-097-multi-slice-live-pilot-contract-docs` and the issue 101 contract.

Files written by the live executor:

- `docs/specbridge-multi-slice-live-pilot-contract.md`
- `.specbridge/runtime-evidence/issue-097-docs.executor-output.md`

Stop conditions evaluated: none triggered.

The executor stayed within the declared exclusive write scope. No secrets, production, billing, auth, database, dependency installation, CI/CD security, or deployment paths were touched.

The coordinator recorded runtime execution, runtime-run, runtime result, runtime summary, and standard-loop-run evidence under issue 101.

## Live Tests Slice Outcome

Issue 103 authorized the second post-preflight bounded live execution of this tests slice.

The live executor ran under the executor packet `issue-097-multi-slice-live-pilot-contract-tests` and the issue 103 contract.

Files written by the live executor:

- `scripts/test-specbridge-cli.ps1`
- `.specbridge/runtime-evidence/issue-097-tests.executor-output.md`

The tests slice added focused CLI coverage for the `status` command and `status -IncludeLatestArtifacts`, including field-level checks for status metadata, counts, and latest artifact surfaces.

Stop conditions evaluated: none triggered.

The executor stayed within the declared exclusive write scope. No secrets, production, billing, auth, database, dependency installation, CI/CD security, or deployment paths were touched.

The coordinator recorded runtime execution, runtime-run, runtime result, runtime summary, and standard-loop-run evidence under issue 103.

## Live Status Slice Outcome

Issue 105 authorized the third post-preflight bounded live execution of this status slice.

The live executor ran under the executor packet `issue-097-multi-slice-live-pilot-contract-status` and the issue 105 contract.

Files written by the live executor:

- `scripts/specbridge.ps1`
- `.specbridge/runtime-evidence/issue-097-status.executor-output.md`

The status slice expanded the repository-local status surface by adding `runtime_run` and `runtime_execution` latest artifact fields, runtime run/execution counts, and a bounded `bounded-live-pilot-status` command for the issue 097 live pilot chain.

Stop conditions evaluated: none triggered.

The executor stayed within the declared exclusive write scope. No secrets, production, billing, auth, database, dependency installation, CI/CD security, or deployment paths were touched.

The coordinator recorded runtime execution, runtime-run, runtime result, runtime summary, and standard-loop-run evidence under issue 105.

## Post-Preflight Live Pilot Closure

Issue 107 closes the full issue 097 post-preflight live pilot evidence chain.

Closure evidence:

- `docs` completed through issue 101 and PR 102.
- `tests` completed through issue 103 and PR 104.
- `status` completed through issue 105 and PR 106.
- `.specbridge/metrics/issue-107-post-preflight-live-pilot-closure.autonomy-metrics.json` records 3 summaries, 3 ready, 0 blocked, 3 executors, 9/9 validation checks passed, and policy gate ready rate 1.
- `.specbridge/pilot-closures/issue-107-post-preflight-live-pilot-closure.pilot-closure.json` records the slice, issue, PR, runtime, policy, and next-standard evidence.

The next standardization target is a governed one-command issue-to-merge operator that preserves policy gates while reducing manual orchestration.

## Validation

The prepared package is valid only when these local gates pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```
