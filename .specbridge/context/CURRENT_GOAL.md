# Current Goal

## Goal

Complete issue 113 by adding the bounded GitHub mutation operator mode after the issue 111 safe pilot merged.

The task must move SpecBridge from plan-only issue-to-merge evidence to a guarded GitHub connector action envelope that names every allowed GitHub operation, requires dry-run evidence by default, and blocks apply mode unless explicit confirmation and gate evidence are provided.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98. Issue 099 runtime launch preflight complete and merged through PR 100. Issue 101 bounded live docs slice complete and merged through PR 102. Issue 103 bounded live tests slice complete and merged through PR 104. Issue 105 bounded live status slice complete and merged through PR 106. Issue 107 post-preflight live pilot closure complete and merged through PR 108. Issue 109 governed issue-to-merge operator complete and merged through PR 110. Issue 111 issue-to-merge operator safe pilot complete and merged through PR 112.

Current phase is issue 113 bounded GitHub mutation operator mode.

## Active Work

Active contract: `.specbridge/contracts/issue-113-bounded-github-mutation-operator.execution.md`.

Issue 113 adds:

- one deterministic `issue-to-merge-github` CLI command
- dry-run default behavior for GitHub connector actions
- explicit issue, PR, CI wait, merge, issue close, and memory operations
- apply-mode blockers requiring force, confirmation, and declared evidence
- one GitHub mutation run artifact under `.specbridge/issue-to-merge-runs/`
- focused CLI coverage for success, output artifact, selected operation, missing `TaskId`, and apply-mode failure paths
- README, local CLI, and issue-to-merge operator documentation updates
- one final report
- one audit packet
- one ChatGPT/Codex audit

## Required Standard

Issue 113 completion requires:

- `scripts/specbridge.ps1` exposes `issue-to-merge-github`.
- Dry-run mode performs no GitHub calls and writes `.specbridge/issue-to-merge-runs/issue-113-bounded-github-mutation-operator.github-mutation-run.json`.
- The artifact records selected operations, connector action envelope, required evidence, preconditions, stop conditions, merge conditions, policy boundaries, and command boundary.
- Apply mode fails without `-Force`, `-ConfirmGithubMutation`, and `.specbridge/github-evidence/*.github-mutation-evidence.json`.
- README and docs record the bounded GitHub mutation standard.
- Final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Next Recommended Task

After issue 113 merges, run a small end-to-end issue-to-merge task using the new GitHub mutation dry-run artifact as the declared connector action envelope, then compare the recorded envelope with the real GitHub PR, CI, merge, and issue closure evidence.

## Completion Condition

Issue 113 is locally complete when the CLI command, tests, docs, memory, GitHub mutation run artifact, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
