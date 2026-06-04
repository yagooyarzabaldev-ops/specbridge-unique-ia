# Current Goal

## Goal

Close the merged second V5 live autonomy pilot state and harden the live runtime runner defaults discovered during that pilot.

The task closes issue 080 repository memory after PR 81 merge, raises the bounded live runtime budget default, and makes runtime diagnostic previews deterministic when Claude output contains non-ASCII text.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged.

Current phase is V5 runner hardening completed locally, pending GitHub PR gates before merge.

## Gate Status

Local issue 082 implementation and evidence work is complete under `.specbridge/contracts/issue-082-v5-runner-hardening.execution.md`.

Completed local updates:

- mark issue 080 scope, report, audit packet, and ChatGPT/Codex audit as post-merge complete
- raise the default `prepare-runtime-launch` budget to `2.00`
- normalize non-ASCII diagnostic preview text before truncation and validation
- ignore local-only `.agents/` and `.claude/settings.local.json` without committing their contents

Remaining external gates before merge:

- GitHub CI
- deterministic review gate
- security gate
- policy-gated merge

## Required Standard

The next serious live pilot should use this hardened runner baseline and target a real multi-slice Claude Code run without coordinator remediation.

Repository completion for issue 082 requires:

- issue 080 memory reflects PR 81 merge and GitHub CI success
- runtime launch plans default to `MaxBudgetUsd 2.00`
- runtime diagnostic previews validate after non-ASCII output
- focused CLI tests cover the default budget and fake non-ASCII Claude failure artifact
- local gates, GitHub CI, review gate, security gate, audit packet, and ChatGPT/Codex audit pass

## Completion Condition

Issue 082 is complete when post-merge issue 080 evidence is closed, runner hardening is implemented and tested, all evidence validates, GitHub CI passes, and the branch is merged only under policy gates.
