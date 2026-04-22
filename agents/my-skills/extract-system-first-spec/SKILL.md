---
name: extract-system-first-spec
description: Extract a system-first feature spec from code and documentation using Zachman dimensions (WHAT, HOW, WHERE, WHO, WHEN, WHY). Use when users request structured, implementation-grounded specs, architecture extraction, or system design context from an existing codebase and linked sources.
---

# Extract System-First Spec

Produce a machine-friendly, human-readable spec that describes what the system is, not just what users asked for.

This skill is inspired by the Zachman framework and emphasizes six dimensions:

- WHAT (data and entities)
- HOW (capabilities and behavior)
- WHERE (runtime locations and boundaries)
- WHO (actors and ownership)
- WHEN (events and timing)
- WHY (rules, goals, and constraints)

Include these dimensions when relevant:

- INTEGRATIONS (upstream/downstream systems, contracts, dependencies)
- OPEN QUESTIONS (questions about the system that are not yet answered)

## When to use

Use this skill when the user asks to:

- extract a spec from the current codebase
- convert docs/notes into a system-level spec
- create a feature design grounded in real implementation
- map behavior across code, services, and events
- synthesize information from links and internal docs

## Input and evidence order

Prioritize inputs in this order:

1. User-provided requirements and constraints
2. Linked artifacts (Notion, Figma, docs, API references, tickets)
3. Repo docs and architecture notes
4. Codebase evidence (source of truth when conflicts exist)

If evidence conflicts, prefer code behavior and explicitly call out mismatch.

## Link handling protocol

If the user provides links, do not ignore them. Attempt to read them with the most relevant capability first:

1. **Notion links/workspace references**
   - Use Notion-oriented skill/tooling first.
2. **Figma links**
   - Use Figma-oriented skill/tooling if available.
   - If unavailable, report the limitation and continue with other evidence.
3. **Library/framework/API documentation links**
   - Use Context7/documentation tooling first.
4. **General web links**
   - Use web search/fetch tooling.
5. **Private/unreadable links**
   - Record as blocked evidence and list required follow-up.

When a link cannot be read, continue with available evidence and mark assumptions clearly.

## Extraction workflow

1. **Collect sources**
   - Enumerate all docs, links, and code locations used.
   - Note any missing or inaccessible artifacts.
2. **Identify feature boundary**
   - Define in-scope components and explicit non-goals.
3. **Extract Zachman dimensions**
   - Pull concrete facts from code/docs for each dimension.
4. **Map events and responsibilities**
   - Tie actors to capabilities and triggering events.
5. **Capture constraints and intent**
   - Separate business rules from implementation decisions.
6. **Produce final spec**
   - Output in the required structure below.

## Required output format

Use this exact markdown structure unless the user asks otherwise:

```markdown
# <Feature/System Name> - System-First Spec

## Scope

- In scope:
- Out of scope:
- Primary sources:

## WHAT (Data Model)

- Core entities:
- Key attributes:
- Relationships:
- State model:

## HOW (Capabilities)

- Capability 1:
  - Inputs:
  - Processing:
  - Outputs:
- Capability 2:

## WHERE (System Boundaries)

- Runtime locations:
- Service/module boundaries:
- Data boundaries:
- Deployment/environment notes:

## WHO (Actors and Ownership)

- Human actors:
- System actors:
- Ownership/responsibility map:
- Authorization boundaries:

## WHEN (Events and Timing)

- Triggering events:
- Event sequence:
- Async/scheduled behavior:
- Timing/ordering guarantees:

## WHY (Goals and Constraints)

- Product/business goals:
- Invariants/business rules:
- Compliance/security constraints:
- Tradeoffs and rationale:

## INTEGRATIONS

- Upstream systems:
- Downstream systems:
- Contracts/interfaces:
- Failure modes and retries:

## Open Questions

- Question:
- Missing evidence:

## Assumptions

- Assumption:
- Confidence: High | Medium | Low
- Evidence:
```

## Quality bar

Before finalizing, verify:

- Every major claim is backed by evidence from code or docs.
- Each Zachman dimension is filled or explicitly marked unknown.
- Assumptions are separated from verified facts.
- Integrations include direction (inbound/outbound) and contract surface.
- Events include triggers and downstream effects.
- Constraints describe rules, not vague preferences.

## Style guidelines

- Keep language concrete and implementation-aware.
- Prefer short bullets over long prose.
- Avoid speculative architecture unless labeled as assumption.
- Do not hide uncertainty; show missing information explicitly.

## Minimal example

```markdown
## WHAT (Data Model)

- Core entities: Journey, JourneyNode, JourneyEdge
- Relationships: Journey has many JourneyNodes; nodes connect through JourneyEdges
- State model: draft -> active -> paused -> archived

## WHEN (Events and Timing)

- Triggering events: `journey.published`, `node.executed`
- Async behavior: execution jobs enqueued per eligible node
```
