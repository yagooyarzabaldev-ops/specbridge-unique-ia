# Claude Code Execution Boundaries

## Purpose

This policy defines boundaries for future Claude Code execution.

## Allowed Initial Scope

- documentation
- specs
- execution contracts
- validation scripts
- inactive workflow examples

## Blocked Scope

- secrets
- production configuration
- billing
- destructive infrastructure
- real deployment automation
- authentication or authorization security
- database production operations

## Stop Rule

When uncertain, stop and report the boundary.

Do not improvise beyond the execution contract.
