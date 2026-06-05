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

## Status Slice

The `status` slice adds a `runtime-capability-status` CLI command to `scripts/specbridge.ps1`.

This command:

- reads the current runtime environment
- verifies that bounded execution requirements are met
- reports readiness for live executor launch

The `status` slice exclusive write scope is:

- `scripts/specbridge.ps1`
- `.specbridge/runtime-evidence/issue-097-status.executor-output.md`

The `status` and `tests` slices remain prepared but unlaunched until a future contract explicitly authorizes their execution.

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

## Validation

The prepared package is valid only when these local gates pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```
