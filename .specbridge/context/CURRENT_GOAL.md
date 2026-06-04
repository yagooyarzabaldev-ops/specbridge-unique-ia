# Current Goal

## Goal

Complete issue 095 by adding a deterministic `next_contract_seed` block to `standard-loop-orchestrate`.

The task must use the issue 093 Standard Loop orchestrator as the operator entry point, then make the resulting plan more directly actionable for the next governed execution contract.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94.

Current phase is issue 095 Standard Loop contract seed pilot.

## Active Work

Active contract: `.specbridge/contracts/issue-095-standard-loop-contract-seed.execution.md`.

Issue 095 adds `next_contract_seed` to `scripts/specbridge.ps1 standard-loop-orchestrate`.

The seed must:

- emit deterministic JSON
- include task id and issue reference
- include recommended branch
- include contract, scope, final report, audit packet, ChatGPT/Codex audit, and standard-loop-run paths
- include required evidence paths
- include suggested local commands
- include completion gates
- preserve the plan-only command boundary
- avoid live launch, GitHub calls, dependency installation, deployment, and workflow changes

## Required Standard

Issue 095 completion requires:

- `standard-loop-orchestrate -TaskId <task>` returns `next_contract_seed`.
- Output-path artifacts include the seed.
- CLI tests cover stdout and output-path seed behavior.
- README and docs explain how to use the seed to start the next governed execution contract.
- Issue 095 contract, scope, final report, audit packet, ChatGPT/Codex audit, and standard-loop-run evidence exist.
- Local standard validation, smoke validation, CLI tests, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Next Recommended Task

After issue 095 merges, use `standard-loop-orchestrate -TaskId <real-feature>` and its `next_contract_seed` to create a multi-slice live pilot contract with non-overlapping executor scopes.

## Completion Condition

Issue 095 is locally complete when the command, tests, docs, output artifact, and evidence validate. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
