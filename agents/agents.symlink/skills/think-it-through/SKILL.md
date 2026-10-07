---
name: think-it-through
description: Assesses alternative solutions to an engineering problem and recommends a path with evidence and tradeoffs. Use when the user asks to think a problem through, compare engineering approaches, or assess a proposed solution before implementation.
---

# Think It Through

Turn an engineering problem into a concise decision brief. Scale the investigation to the decision's impact and uncertainty. Completion means the options are meaningfully different, the recommendation is supported, and the next validation step is clear.

This skill covers assessment. Keep implementation, prototypes, tracker updates, and decision records within the user's separately authorized scope; recommending a path does not authorize executing it.

## 1. Frame the decision

Read the conversation and the relevant code, project glossary, and ADRs. State:

- The problem and the observable outcome that would count as success.
- Hard constraints, scope, and the criteria that matter most to the user.
- What is established, what is assumed, and what remains unknown.

Look up facts yourself. Ask only questions whose answers could change the viable options or recommendation, grouping independent questions into one round. Continue independent investigation while awaiting answers. If a consequential preference is unanswered, present a conditional recommendation.

## 2. Gather enough evidence

Inspect the affected behavior, callers, dependencies, and existing mechanisms before proposing changes. Tie material claims to code paths, measurements, or primary sources. Verify external capabilities against current official documentation or source code.

For bugs and performance regressions, establish a reproducible signal and test competing, falsifiable causes before comparing fixes. When that evidence is unavailable, separate investigation options from possible fixes and label the recommendation provisional.

Stop investigating when further evidence is unlikely to change the ranking. Name any uncertainty that could still reverse it and the cheapest way to resolve that uncertainty.

Load a supporting skill only when its discipline is needed and it is installed:

- `grilling`: for unresolved constraints or preferences that need a deeper interview.
- `research`: for facts requiring primary-source investigation.
- `diagnosing-bugs`: for establishing the cause of a failure; keep the handoff to fixing within the authorized scope.
- `codebase-design`: for module shape, interface complexity, seam placement, and testability; its `DESIGN-IT-TWICE.md` explores alternative interfaces.
- `domain-modeling`: when alternatives change domain concepts or behavior.
- `prototype`: when a runnable logic/state demo or UI comparison would settle the decision, and that work is authorized.

The steps here work without those skills. Use one agent by default; delegate only when authorized, available, and independent investigation would materially improve the assessment.

## 3. Generate distinct options

Develop 2-4 viable approaches to the same outcome. Give each a different organizing idea or optimization goal: smallest effective change, simpler structure, easiest common case, or greater flexibility. Include keeping the current approach when it is viable. If only one approach satisfies the hard constraints, explain which constraints rule out the alternatives.

For each option, state:

- What changes and how that addresses the problem.
- The strongest benefit and the principal cost or failure mode.
- Required assumptions, dependencies, and migration work.
- How success would be verified and the change reversed.

Make each alternative credible on its own merits. Use a small code sketch or diagram only when it makes the difference easier to assess.

## 4. Compare and recommend

Filter against hard constraints first. Compare the remaining options using only criteria that distinguish them: effectiveness, implementation effort, ongoing complexity, operational risk, testability, and reversibility. For architectural changes, assess how much complexity the interface hides and where future changes concentrate.

Use a compact table with concrete reasons. Mark unknowns explicitly; give effort ranges only when evidence supports them. Avoid numeric scores that imply unsupported precision.

Choose a preferred option and explain the decisive tradeoff. State when the strongest runner-up would win. Suggest a hybrid only when its combined costs and interfaces are coherent. Express confidence and identify the evidence or assumption most likely to change your recommendation.

## 5. Deliver the decision brief

Lead with the recommendation, then provide:

1. **Problem and constraints:** the decision in a few sentences.
2. **Options:** a comparison table, with short sketches where needed.
3. **Reasoning:** why the preferred option wins and when another would.
4. **Validation:** the smallest experiment or check that could confirm or overturn the recommendation, with a concrete pass/fail condition.
5. **Open questions:** only unresolved points that could change the decision.

Keep routine assessments to a few paragraphs and one table. Expand for consequential decisions. Finish with a usable recommendation or an explicit evidence gap and the next action needed to resolve it.

Example: "Think through duplicate job execution" should distinguish an idempotent handler, a uniqueness constraint, and a coordination mechanism by their actual guarantees, then recommend one against the observed failure and required behavior.

## Sources

Adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills): the facts-versus-decisions discipline in `grilling`, primary-source evidence in `research`, competing hypotheses in `diagnosing-bugs`, and distinct designs plus an opinionated recommendation in [`Design It Twice`](https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/DESIGN-IT-TWICE.md). This workflow extends interface comparison to engineering solutions generally.
