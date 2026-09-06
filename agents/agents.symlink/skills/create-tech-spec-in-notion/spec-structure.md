# Spec Structure

Use these headings in this order unless the user asks for a different format.

## Template

```markdown
# Summary

# Background

# Goals

### Non-Goals

# Proposed Solution

### Options Considered

### Risks

### Milestones

### Open Questions

# Follow-up Tasks
```

## Summary

State the functional delta. Then state why now, in one sentence.

```markdown
`createChatStore` holds chat session state. Studio no longer owns that state.
Journey and Studio embeds need isolated sessions. They must not import Studio.
```

Done when: a reviewer can say what changes and why, without reading later
sections.

## Background

State current behavior. Then state the problem or gap.

Add a metric or example only when it sharpens the decision.

Done when: the reader can see the constraint that forces a change.

## Goals

State observable outcomes. A test, a metric, or a user-visible result counts.

### Non-Goals

State excluded scope. These items stay out of this change.

Done when: a reviewer can accept or reject a PR item as in-scope or
out-of-scope.

## Proposed Solution

List named system facts an implementer can check in a PR, in order:

- Responsibilities that are new, moved, or removed
- Runtime boundaries and owners
- Data or API contract deltas (old behavior to new behavior)
- Ordering, lifecycle, and state changes
- Rollout and compatibility

Name the system after the change. State the new contract, owner, and data shape.

```markdown
Outbound queue sends the context message before the user message.
`contextAcknowledged` stays false until the current `contextRevision` is acked.
```

Done when: a reviewer can walk the list and mark each item done or not done in a
PR.

## Options Considered

List at least two **options**. If only one option can work, name the option that
you rejected. State why it fails.

For each option:

- **Name:** a codebase name or a short plain name
- **How it works:** 1 to 3 full sentences
- **Pros:** outcomes this option gives
- **Cons:** costs, risks, or limits

Then one **Recommendation** block:

- Name the chosen option
- Give the reason
- Tie the reason to a goal or constraint from earlier sections

```markdown
### Options Considered

**Shared `createChatStore`**

- How it works: Each embed creates its own store from one factory.
- Pros: Sessions stay isolated. Embeds do not import Studio.
- Cons: One more module needs an owner.

**Studio singleton**

- How it works: Embeds import Studio chat state.
- Pros: No new module.
- Cons: Session state leaks across embeds.

**Recommendation:** Shared `createChatStore`.
Journey and Studio embeds need isolated sessions. The Studio singleton cannot provide that.
```

Done when: the reader can see every option you compared, the tradeoff, and why
you chose one.

## Risks

One line per risk: risk, impact, mitigation.

Done when: each risk names the impact and the mitigation.

## Milestones

Thin slices. Each slice is independently reviewable. Name dependencies.

Done when: each slice can merge without the later slices.

## Open Questions

Write only unresolved decisions. Write them as questions.

Done when: each item is a question. Put actions in Follow-up Tasks.

## Follow-up Tasks

Checkbox list of next actions.

Done when: each item is a concrete next action, or the section is `None`.
