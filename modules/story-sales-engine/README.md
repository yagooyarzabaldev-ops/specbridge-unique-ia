# Story Sales Engine

Story Sales Engine is a governed marketing module for turning a weekly offer
into Instagram Stories that create connection, invite interaction, and route
qualified interest to a soft sale.

This module is documentation and specification only. It does not publish to
Instagram, connect to Meta, configure WhatsApp, configure Mercado Pago, or store
provider connection values.

## Purpose

The module converts one commercial focus into a seven-day Stories plan:

- two ideas per day;
- one connection story and one soft-sale story per day;
- hook, visual direction, CTA, and interaction mechanic for every story;
- lightweight production plan that fits under two hours per week;
- optional funnel concepts for DM, WhatsApp, and payment handoff.

## Inputs

- Offer name and short description.
- Target audience.
- Main pain or desire.
- Proof points or testimonials available this week.
- Primary CTA.
- DM keyword or reply trigger.
- Weekly constraint, usually under two hours.
- Brand voice.

## Outputs

- Seven-day story calendar.
- Fourteen story ideas.
- Daily connection and soft-sale pairing.
- Hooks, visuals, CTAs, and interaction mechanics.
- Optional WhatsApp and Mercado Pago funnel concept.
- Manual n8n skeleton for generating the story calendar from structured input.

## Workflow

1. Define the weekly offer and the target audience.
2. Generate a seven-day calendar with two stories per day.
3. Keep each day balanced: first connection, then soft sale.
4. Add one interaction mechanic per day.
5. Route qualified replies to DM or WhatsApp conceptually.
6. Use the examples as delivery templates for Infinite Process or client work.

## Boundaries

Allowed:

- reusable specs;
- prompt templates;
- manual workflow skeletons;
- examples with placeholder business data;
- funnel concepts.

Blocked:

- live publishing;
- Meta provider setup;
- WhatsApp provider setup;
- Mercado Pago provider setup;
- secrets or private keys;
- production automation;
- payment processing;
- CI/CD changes.

## Acceptance Criteria

- A strategist can generate a weekly story calendar from the prompts.
- A developer can import the n8n JSON as a manual starter workflow skeleton.
- The examples show both Infinite Process delivery and a WhatsApp/Mercado Pago
  funnel concept without live provider configuration.
- Every artifact stays reusable for client delivery.
- No secrets, provider connection values, or production automation are included.
