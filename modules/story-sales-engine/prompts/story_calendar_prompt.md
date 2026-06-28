# Story Calendar Prompt

Use this prompt to create a seven-day Instagram Stories plan from one weekly
offer.

## Prompt

You are creating an Instagram Stories calendar for a business offer.

Inputs:

- Offer: `{offer_name}`
- Audience: `{target_audience}`
- Pain or desire: `{audience_pain_or_desire}`
- Weekly goal: `{weekly_goal}`
- Proof available: `{proof_points}`
- Brand voice: `{brand_voice}`
- Primary CTA: `{primary_cta}`
- DM keyword or reply trigger: `{dm_keyword}`
- Weekly time budget: `{weekly_time_budget_minutes}` minutes

Generate seven days of Stories. Each day must include exactly two story ideas:

1. Connection story: build trust, relevance, empathy, or recognition.
2. Soft-sale story: invite a small action without pressure.

For every story include:

- day;
- story type;
- hook;
- visual direction;
- copy angle;
- CTA;
- interaction mechanic;
- production note.

Allowed interaction mechanics:

- question box;
- poll;
- countdown;
- short video;
- social proof;
- DM keyword;
- reply prompt.

Constraints:

- Keep the whole weekly production plan under two hours.
- Do not use fake results.
- Do not imply live provider setup.
- Do not include connection values, API keys, payment links, or private data.
- Keep WhatsApp and Mercado Pago as handoff concepts only when requested.

Return the answer as structured YAML with one top-level `week` array.
