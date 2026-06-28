# Story Pack Generator Prompt

Use this prompt after the weekly calendar exists. It expands each idea into a
production-ready Story pack.

## Prompt

You are expanding a weekly Instagram Stories calendar into production notes.

Inputs:

- Weekly calendar: `{weekly_calendar}`
- Offer: `{offer_name}`
- Audience: `{target_audience}`
- Brand voice: `{brand_voice}`
- Primary CTA: `{primary_cta}`
- DM keyword: `{dm_keyword}`

For each story, produce:

- short script;
- on-screen text;
- recommended visual;
- sticker or interaction mechanic;
- CTA;
- follow-up reply suggestion;
- production time estimate.

Rules:

- Preserve the original connection/soft-sale balance.
- Keep scripts short enough for Stories.
- Prefer simple visuals that can be produced quickly.
- Use placeholder handoff text such as `DM_KEYWORD` and `WHATSAPP_HANDOFF`.
- Do not create live payment links.
- Do not include provider connection values.

Return structured Markdown grouped by day.
