# Current Goal

## Goal

Complete issue 099 by adding a deterministic runtime launch preflight command for prepared multi-slice launch plans.

The task must verify non-overlap, required slices, budget, tools, and plan-only execution policy before any future live operator launch, without launching Claude Code, launching Antigravity, executing runtime plans, installing dependencies, changing workflows, or deploying.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98.

Current phase is issue 099 runtime launch preflight.

## Active Work

Active contract: `.specbridge/contracts/issue-099-runtime-launch-preflight.execution.md`.

Issue 099 adds:

- `preflight-runtime-launches` CLI command
- runtime preflight JSON artifact under `.specbridge/preflights/`
- runtime preflight JSON schema
- runtime preflight validator
- CLI tests for positive and negative preflight behavior
- docs for preflight usage and no-launch boundary
- one final report
- one audit packet
- one ChatGPT/Codex audit

## Required Standard

Issue 099 completion requires:

- `standard-loop-orchestrate -TaskId issue-099-runtime-launch-preflight` returns a valid `next_contract_seed`.
- The file-backed Standard Loop run artifact exists.
- The issue 097 `status`, `tests`, and `docs` launch plans pass preflight.
- Preflight output reports required slices, non-overlap, budget, tools, execution policy, blockers, source files, and output path.
- Negative tests cover overlapping write scopes, over-budget launch plans, and unsafe execution policy.
- Runtime preflight artifacts validate.
- Docs describe preflight usage and the no-launch boundary.
- Local standard validation, smoke validation, CLI tests, runtime preflight validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Next Recommended Task

After issue 099 merges, use `preflight-runtime-launches` against the prepared issue 097 launch plans, then choose one bounded live slice for a dedicated follow-up contract if the preflight and gates pass.

## Completion Condition

Issue 099 is locally complete when the command, validator, docs, artifact, tests, and validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
