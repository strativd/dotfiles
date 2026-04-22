---
name: extract-human-tech-spec
description: Extract a customer-focused technical spec from docs and code context in concise markdown. Use when the user asks for a readable tech spec, product-facing implementation brief, solution summary, or mixed technical/non-technical audience context document.
---

# Extract Human Tech Spec

Generate a concise markdown spec that helps humans quickly understand a problem, why it matters, and the proposed solution.

Audience: mixed technical and non-technical readers with strong product context.

## When to use

Use this skill when asked to:

- write a tech spec for humans
- summarize implementation plans into customer-facing impact
- produce a product-oriented engineering brief
- convert technical docs into a readable markdown spec

## Inputs and source priority

1. User-provided docs and notes (highest priority)
2. Existing project docs/specs/plans
3. Codebase evidence for missing details

If required docs are missing or unclear, ask for them first. If the user does not provide more docs, infer carefully from the codebase and label assumptions.

For source parsing workflow and evidence grading, read [DOC-PARSING.md](DOC-PARSING.md).

## Output requirements

- Output format: markdown only
- Keep it brief and scannable
- Prefer plain language over implementation detail
- Focus on customer and business impact
- Explicitly include goals, non-goals, and solution
- Avoid deeply technical internals unless needed for decisions

## Required output structure

Use exactly these sections (rename only if user requests):

1. `# <Spec Title>`
2. `## Problem`
3. `## Customer Impact`
4. `## Goals`
5. `## Non-Goals`
6. `## Proposed Solution`
7. `## User Experience Changes`
8. `## Risks and Tradeoffs`
9. `## Open Questions`
10. `## Success Metrics`

## Section guidance

### Problem

- What is broken, missing, or confusing today?
- Keep to 3-5 sentences.

### Customer Impact

- Who is affected and how?
- Emphasize outcomes: speed, clarity, reliability, confidence, effort.

### Goals

- 3-6 concrete bullets.
- Each goal should be testable or observable.

### Non-Goals

- Explicitly state scope boundaries.
- Prevents over-implementation and misaligned expectations.

### Proposed Solution

- Explain approach at system level, not code level.
- Answer: what changes, for whom, and why this approach.
- Include short rationale and alternatives considered (1-3 bullets).

### User Experience Changes

- Describe before/after behavior in product terms.
- Use concise bullets by user type if useful.

### Risks and Tradeoffs

- List key risks with mitigation.
- Call out tradeoffs (e.g., faster delivery vs flexibility).

### Open Questions

- Capture unresolved decisions blocking execution.

### Success Metrics

- Define 3-5 measurable indicators (adoption, reliability, time-to-complete, support load).

## Style constraints

- Use short paragraphs and bullets.
- Default to concrete language; avoid jargon.
- Do not include large architecture diagrams by default.
- Do not include implementation checklists unless asked.
- Mark assumptions explicitly when evidence is incomplete.

## Quality checklist

Before finalizing, ensure:

- Goals and non-goals are clearly separated.
- Proposed solution is understandable by non-engineers.
- Customer impact is specific, not generic.
- Technical depth is enough for confidence but not overwhelming.
- Every major claim maps to provided docs or code evidence.
