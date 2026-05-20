# SpecBridge V3 Essential Product Scope

## Purpose

This document defines the essential product scope to carry SpecBridge beyond the repository-first MVP.

It is a product contract, not an implementation approval. Runtime code remains blocked until a dedicated execution contract updates allowed scope and validation expectations.

## Product Shape

V3 should turn SpecBridge from a repository-first governance kit into a usable local-orchestration product.

The essential product must preserve the existing control model:

- explicit context
- execution contracts
- autonomy profiles
- risk rules
- deterministic validation
- independent review
- final reports
- gate-controlled merge by default

## Essential Capabilities

V3 should add only the minimum runtime surface needed to make the MVP loop easier to operate:

- contract creation assistant from structured context
- contract validator command
- final report generator command
- local task status reader
- audit packet assembler
- PR evidence checklist generator
- optional MCP facade after tool contracts stabilize

## Minimal Runtime Boundary

The first runtime adapter should be local and file-based.

It may read and write:

- `.specbridge/context/`
- `.specbridge/contracts/`
- `.specbridge/reports/`
- `.specbridge/review-reports/`
- `docs/`

It must not require:

- secrets
- billing configuration
- production deployment
- persistent database
- hosted dashboard
- autonomous merge without required gates
- direct writes to protected branches

## Product Interfaces

V3 should expose these interfaces in order:

1. PowerShell or Node CLI for local deterministic operations.
2. MCP resources for read-only repository state.
3. MCP tools for low-risk file artifact generation.
4. GitHub integration for PR evidence and review comments.
5. Hosted dashboard only after local workflow is stable.

## Essential Commands

The first CLI or MCP tool set should cover:

- `specbridge status`
- `specbridge validate`
- `specbridge create-contract`
- `specbridge create-report`
- `specbridge audit-packet`
- `specbridge review-gate`

Each command must have:

- declared input files
- declared output files
- no hidden side effects
- structured errors
- deterministic exit codes
- test coverage before CI enforcement

## Non-Essential For V3

Do not include in the first V3 implementation:

- SaaS billing
- multi-tenant organization model
- production deploy automation
- destructive database migrations
- secret vault integration
- autonomous merge without required gates
- unrestricted shell execution
- agent marketplace

## Version 4 Candidates

Version 4 is now defined in `docs/specbridge-v4-product-contract.md`.

Candidate V4 work:

- hosted dashboard
- GitHub App
- richer MCP server
- multi-repository support
- provider abstraction for coding agents
- organization policy profiles
- staged deployment policy automation

The V4 product contract keeps hosted dashboard, production deployment, billing, and GitHub App implementation behind explicit future execution contracts.

## Gate To Start Runtime Work

Runtime implementation may start only when a new execution contract explicitly defines:

- allowed source paths
- package or runtime choice
- test framework
- lint and typecheck commands
- build command
- blocked production behavior
- rollback notes
