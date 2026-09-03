---
name: investigation-guidelines
description: Behavioral guidelines to reduce common LLM investigation mistakes. Use when debugging, triaging incidents, tracing root cause, analyzing unexpected behavior, or answering "why is this happening" before changing code.
license: MIT
---

# Guidelines for Investigation

Behavioral guidelines to reduce common LLM mistakes when investigating
issues, derived from the same principles as coding-guidelines
(simplicity, explicit assumptions, narrow scope, verifiable conclusions)
and [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876)
on LLM pitfalls applied to diagnosis instead of implementation.

**Tradeoff:** These guidelines bias toward evidence over speed.
For obvious one-line fixes, use judgment.

## 1. Think Before Digging

**Don't assume. Don't hide confusion. Separate facts from guesses.**

Before chasing leads:

- State what is known (symptoms, errors, timestamps, scope) vs what is inferred.
- If multiple plausible causes exist, list them with what would falsify each - do not commit to one silently.
- If the report is ambiguous, restate the minimal question you are answering. If still unclear, ask.
- Name missing data (logs, repro, version, environment) instead of speculating past it.

## 2. Simplicity First

**Minimum investigation that answers the question. Nothing theatrical.**

- No broad "audit the codebase" unless the user asked for that scope.
- No parallel deep dives on unrelated subsystems without a reason they could explain the symptom.
- No new tools or dashboards if existing evidence (logs, traces, diffs, repro) is not exhausted.
- Prefer the smallest repro or query that isolates the failure.

Ask yourself: "Would a senior engineer say this investigation is unfocused?" If yes, narrow it.

## 3. Surgical Scope

**Touch only what the investigation requires. Do not "fix" while diagnosing unless asked.**

When exploring:

- Do not refactor, reformat, or "clean up" files you open for reading.
- Do not expand the blast radius (config changes, data mutations, production commands) without explicit approval and a rollback story.
- Prefer read-only inspection (read files, run safe queries, reproduce locally) over invasive probes.

When your investigation produces noise:

- Summarize dead ends briefly so the next step is not re-tried blindly.
- Do not delete or alter unrelated artifacts; note them if they matter later.

The test: Every step should trace to a stated hypothesis or a missing piece of evidence.

## 4. Goal-Driven Investigation

**Define what "answered" means. Close the loop with evidence.**

Turn vague asks into verifiable outcomes:

- "Figure out what broke" → "Identify the failing invariant or contract; cite log line / stack / commit"
- "Is it the deploy?" → "Compare error onset to deploy time; check diff or release notes for touched surface"
- "Why slow?" → "Name bottleneck with measurement (query, lock, CPU, I/O), not a generic hunch"

For multi-step investigations, state a brief plan:

```text
1. [Step] → verify: [what evidence confirms or rules out]
2. [Step] → verify: [what evidence confirms or rules out]
3. [Step] → verify: [conclusion supported by: ...]
```

Strong exit criteria let you stop without hand-waving. Weak criteria
("probably X") invite wrong fixes and rework.
