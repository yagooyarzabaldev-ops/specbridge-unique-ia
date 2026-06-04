# Current Goal

## Goal

Complete issue 093 by adding the first deterministic one-command Standard Loop orchestrator.

The task must add a file-backed CLI command that reports the governed issue-to-merge sequence from repository files without relying on chat-memory inference.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 086 is closed as superseded by issue 087 and PR 88.

Current phase is issue 093 one-command Standard Loop orchestration.

## Active Work

Active contract: `.specbridge/contracts/issue-093-standard-loop-orchestrator.execution.md`.

Issue 093 adds `standard-loop-orchestrate` to `scripts/specbridge.ps1`.

The command must:

- emit deterministic JSON
- list Standard Loop phases
- list required local and GitHub gates
- report current repository phase and next recommended action from repository files
- report latest known artifacts
- report policy boundaries
- optionally write `.specbridge/standard-loop-runs/*.standard-loop-run.json`
- avoid live launch, GitHub calls, dependency installation, deployment, and workflow changes

## Required Standard

Issue 093 completion requires:

- `standard-loop-orchestrate` exists in the CLI command set.
- The command prints deterministic JSON with phases, gates, current phase, next action, latest artifacts, missing required paths, and policy boundaries.
- The command can write an output artifact under `.specbridge/standard-loop-runs/*.standard-loop-run.json` when `-OutputPath` is supplied.
- CLI tests cover stdout and output-path behavior.
- README and docs mention the command.
- Issue 093 contract, scope, final report, audit packet, ChatGPT/Codex audit, and standard-loop-run evidence exist.
- Local standard validation, smoke validation, CLI tests, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Next Recommended Task

After issue 093 merges, run a small real feature through `standard-loop-orchestrate` as the operator entry point, then use the resulting plan artifact to drive the next governed execution contract.

## Completion Condition

Issue 093 is locally complete when the command, tests, docs, output artifact, and evidence validate. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
