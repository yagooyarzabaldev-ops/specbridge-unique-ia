# SpecBridge V4 Product Contract

## Purpose

This document defines the Version 4 product contract for SpecBridge.

Version 4 is the point where SpecBridge may move from a repository-first governance kit toward a usable product surface. This document completes the V4 scope and gates. It does not activate hosted infrastructure, production deployment, billing, or secret handling.

## V4 Product Goal

SpecBridge V4 should provide a practical operator experience for governed autonomous development.

The product should help an operator:

- capture a goal
- create structured context
- generate or validate an execution contract
- run deterministic validation
- assemble an audit packet
- prepare PR evidence
- read completion status
- coordinate multiple Claude Code executors inside Antigravity
- detect write-scope conflicts before parallel work starts
- aggregate evidence from parallel executor tasks
- preserve policy and human merge control
- allow automatic merge only after required policy, validation, review, and CI gates pass

## Required Product Surfaces

V4 should introduce these surfaces in this order:

1. Local CLI
2. Read-only MCP resources
3. Low-risk MCP artifact tools
4. GitHub PR evidence integration
5. Hosted dashboard

The hosted dashboard is last because it introduces identity, hosting, secrets, persistence, and operational risk.

## Local CLI Scope

The first V4 implementation should be a local CLI that operates only on repository files.

Required commands:

- `specbridge status`
- `specbridge validate`
- `specbridge create-contract`
- `specbridge decompose-task`
- `specbridge detect-conflicts`
- `specbridge create-report`
- `specbridge audit-packet`
- `specbridge review-gate`

The CLI must:

- read declared repository paths only
- write declared artifact paths only
- return deterministic exit codes
- produce structured JSON where useful
- preserve gate-controlled merge
- avoid network calls by default

## MCP Scope

MCP should be added after the CLI behavior is stable.

Read-only resources may expose:

- current context summary
- contract catalog
- policy summary
- validation status
- final report catalog
- review report catalog

Low-risk tools may generate:

- execution contract drafts
- final report drafts
- audit packet summaries
- PR evidence checklists

MCP tools must not:

- access secrets
- merge pull requests
- deploy environments
- mutate protected branches
- run unrestricted shell commands
- modify production configuration

## GitHub Integration Scope

GitHub integration should remain evidence-oriented.

Allowed V4 behavior:

- read issue and PR metadata
- read changed file lists
- read CI status
- publish review evidence comments after validation
- generate PR checklists

Blocked V4 behavior by default:

- autonomous merge without required gates
- direct push to protected branches
- production deployment
- repository secret creation
- branch protection weakening
- CI/CD security control changes

## Hosted Dashboard Scope

The hosted dashboard is a V4 candidate only after local CLI and MCP surfaces are proven.

Dashboard MVP screens:

- task list
- contract detail
- validation status
- review findings
- final report detail
- policy summary

Dashboard non-goals for initial V4:

- billing
- multi-tenant administration
- production deploy controls
- secret management
- provider marketplace
- production merge or deployment controls

## Data Model Boundary

The initial V4 data model should remain file-backed.

Canonical records:

- context package files
- execution contracts
- final reports
- PR review reports
- validation logs or summaries
- audit packets

A persistent database is postponed until a dedicated contract defines migration policy, backup policy, rollback policy, and test gates.

## Required Gates Before Runtime Implementation

Runtime implementation may start only after an execution contract defines:

- package/runtime choice
- source directories
- test framework
- lint command
- typecheck command
- build command
- fixture strategy
- artifact output paths
- blocked production behavior
- rollback notes

## V4 Completion Criteria

V4 is product-ready when:

- local CLI commands exist and are tested
- CLI validation passes in CI
- read-only MCP resources are contract-backed
- low-risk MCP tools are contract-backed and tested
- PR evidence integration is deterministic
- multi-agent task decomposition is contract-backed
- write-scope conflict detection is tested
- parallel executor evidence aggregation is tested
- final reports remain schema-validated
- no protected files are touched without explicit policy
- autonomous merge is enabled only after required gates pass
- hosted dashboard is either proven behind a separate contract or deferred

## Version 5 Candidates

Version 5 may consider:

- hosted multi-tenant dashboard
- billing
- organization policy administration
- production deployment orchestration
- provider marketplace
- cross-repository orchestration
- stronger identity and access control

These are not V4 requirements.
