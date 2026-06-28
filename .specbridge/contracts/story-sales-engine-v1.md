# Story Sales Engine v1 Contract

## Goal

Create a reusable Story Sales Engine module for Infinite Process and client
delivery. The module turns one weekly offer into a seven-day Instagram Stories
plan with connection content, soft-sale content, interaction mechanics, and
manual handoff concepts.

## Allowed Scope

- Documentation and specification files under `modules/story-sales-engine/`.
- Manual n8n workflow skeleton with placeholder values only.
- Conceptual WhatsApp and Mercado Pago funnel examples.
- Local SpecBridge evidence for issue #263.

## Blocked Scope

- Live Instagram publishing.
- Meta provider setup.
- WhatsApp provider setup.
- Mercado Pago provider setup.
- Payment processing.
- Secrets, private keys, provider connection values, or production data.
- CI/CD changes.
- Deployment automation.

## Acceptance Criteria

- The module defines inputs, outputs, workflow, blocked scope, and acceptance criteria.
- The prompts can generate a seven-day calendar with two stories per day.
- The n8n JSON is importable as a manual starter skeleton.
- Examples are reusable and use placeholders only.
- The final report and Codex audit are recorded.

## Validation

- Required files exist.
- n8n workflow JSON parses.
- SpecBridge evidence validators pass.
- Smoke validation passes before merge.
