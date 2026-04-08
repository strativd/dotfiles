---
name: refactor-with-a-kiss
description: Refactoring with KISS principles. Rethinks implementations to reach the same outcome with less complexity—prefers straightforward, readable code over clever abstractions. Use when refactoring, reviewing code, the user asks for a simpler approach, or when a solution feels over-engineered relative to the problem.
---

# Refactor for simplicity (KISS)

## Follow KISS principles

- Keep it simple, stupid (KISS).
- Keep it small and focused.

## When to apply

- Refactoring existing code without changing observable behavior.
- The user (or review) asks for something **simpler**, **dumber**, or **easier to maintain**.
- A change introduces new layers, indirection, or patterns that don’t clearly pay for themselves.

## Non-negotiables

### 1. same final result

Behavior, API contracts, and outputs must stay equivalent unless the user explicitly wants a behavior change.

### 2. smaller diff when possible

Don’t rename or reformat unrelated code; don’t “clean up” outside the scope of simplification.

## Principles

### 1. prefer the boring path

Explicit conditionals, early returns, and plain data over generic frameworks-in-miniature.

### 2. fewer moving parts

Merge branches that do the same thing; delete wrappers that only pass arguments through.

### 3. local clarity beats global elegance

A reader should understand a function without hunting through three modules.

### 4. one obvious way

If two structures achieve the same thing, pick the one teammates will recognize from the rest of the codebase.

## Workflow

1. State the **observable goal** (what callers/users get).
2. List what the current code **actually does** to get there—include redundant or speculative steps.
3. Propose a **minimal** sequence that still satisfies (1); remove indirection that doesn’t reduce duplication or risk.
4. **Verify** with existing tests or the smallest new test that locks behavior; run the relevant suite before claiming equivalence.

## Red flags (consider simplifying)

- Abstractions used only once.
- Config or strategy objects where a literal or `case` would suffice.
- Deep inheritance or mixin stacks for one call site.
- “Future-proof” hooks with no current consumer.

## Avoid

- Trading simplicity for micro-optimizations that hurt readability.
- Replacing working code with a different library or pattern without user ask.
- Documenting the skill in the repo—keep guidance in this file only unless the user requests docs.
