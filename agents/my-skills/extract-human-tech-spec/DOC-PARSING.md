# Doc Parsing Guide

Use this guide to turn source material into a human-readable tech spec.

## 1) Minimum input check

Look for at least one of:
- Product requirement or RFC
- Engineering plan or architecture note
- Existing code behavior references

If none are provided, ask:
1. "Do you have a PRD, RFC, or planning doc for this problem?"
2. "If not, should I infer from current code and existing docs?"

## 2) Parse sources in order

1. Read user-provided docs fully.
2. Extract problem, customer pain, and intended outcomes.
3. Identify constraints and boundaries.
4. Use codebase only to fill missing facts (current behavior, APIs, known limits).

## 3) Evidence grading

Label each key point internally as:
- **Confirmed**: directly supported by docs/code
- **Inferred**: likely from context, not explicit
- **Unknown**: missing and needs user input

Only put inferred points in final spec when useful, and mark them as assumptions.

## 4) Compression rules

To keep brevity and clarity:
- Keep each section to 3-6 bullets or 1 short paragraph.
- Prefer outcome language ("reduces setup time") over mechanism language.
- Collapse implementation detail into one sentence unless decision-critical.
- Remove repeated context across sections.

## 5) Customer-first rewrite

For each solution statement, rewrite once:
- Technical form: "Add command API and client synchronization"
- Customer form: "Users can reliably edit journeys without stale graph state"

Prioritize the customer form in final output.

## 6) Final markdown template

```markdown
# <Title>

## Problem
<3-5 sentences or 3-5 bullets>

## Customer Impact
- <who is affected>
- <current pain>
- <expected improvement>

## Goals
- <goal 1>
- <goal 2>

## Non-Goals
- <out of scope 1>
- <out of scope 2>

## Proposed Solution
<short paragraph>
- Why this approach:
  - <reason 1>
  - <reason 2>

## User Experience Changes
- Before: <current>
- After: <new>

## Risks and Tradeoffs
- <risk/tradeoff + mitigation>

## Open Questions
- <question 1>

## Success Metrics
- <metric 1 + target direction>
- <metric 2 + target direction>
```

## 7) Pre-publish validation

Verify:
- Goals and non-goals do not overlap.
- Solution explains user-visible impact.
- Language is understandable to non-engineers.
- Unknowns are listed as open questions.
- Claims are backed by docs/code or tagged as assumptions.
