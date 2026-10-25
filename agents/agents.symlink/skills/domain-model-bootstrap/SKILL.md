# Domain Model Bootstrap

Bootstrap a repo's `CONTEXT.md` glossary in one session, instead of waiting for it to crystallize lazily over multiple `/grill-with-docs` sessions.

Call the Skill tool for **"domain-modeling"** (the active discipline underneath: challenge terms, sharpen fuzzy language, write resolutions down immediately, ADRs sparingly) and **"grilling"** (the interview format: rounds, the frontier, facts are the agent's job and decisions are the user's).

## Process

1. **Gather candidates.** Read the repo's docs (README, PROJECT/CLAUDE.md, AGENTS.md, existing `CONTEXT.md` if present) and code. Propose 8-15 candidate domain terms, each with a one-line draft definition. Never ask the user for anything you could read yourself.
2. **Grill the boundaries.** Present the candidate list, then interview the user one round at a time: stress-test each term with concrete edge-case scenarios (is a Pick reversible? is Availability stored or derived from Picks?). Wait for answers before the next round. Use the repo's domain-doc layout (`docs/agents/domain.md`).
3. **Write as they resolve.** Each term the user confirms goes into `CONTEXT.md` immediately, using the domain-modeling skill's format file. Create the file lazily on the first resolution. Glossary only — no implementation details, no spec content.
4. **ADRs sparingly.** Only when a decision is hard to reverse, surprising without context, AND a real trade-off. Otherwise skip.
5. **Done** when every candidate is either resolved into the glossary or explicitly rejected by the user. Report both lists and any ADRs written.

One session is the ceiling: if the frontier isn't empty when context runs short, stop and let remaining terms resolve lazily in future work rather than guessing.
