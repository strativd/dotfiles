---
name: to-linear-task
description: Turn outstanding work from session docs (handoffs, todos, plans) into fully-detailed Linear issues, grouped into milestone phases.
argument-hint: "Source docs or tasks, and the Linear project URL/name"
disable-model-invocation: true
---

File outstanding work as Linear issues via the `linear` MCP server. The user supplies the source material (handoff/todo/plan docs or a task list) and the target Linear project.

## Steps

1. **Gather candidate tasks.** Read the source docs. Extract every outstanding task; drop shipped items, and flag stale premises (e.g. "blocks PR #X" when #X has merged) instead of copying them forward. Done when: every candidate has a one-line TLDR and a source.

2. **TLDR gate — no writes yet.** Present the TLDRs numbered. Get per-item decisions from the user: add / skip / already-done, plus priority and phase. Done when: every candidate has an explicit decision.

3. **Resolve anchors.** `linear_get_project` → project ID + team ID (the team lives on the project). `linear_list_milestones` → existing phases. Check the project's existing issues to avoid duplicates. Done when: team ID, project ID, and milestone names/IDs are known.

4. **Create missing milestones.** One `linear_save_milestone` per phase, with a one-paragraph scope description.

5. **Create issues** via `linear_save_issue`, one per confirmed item: `team`, `project`, `milestone`, `priority`, and `blockedBy` to wire execution order (create blockers first, then reference their identifiers). Description requirements:
   - **Standalone** — full investigation/implementation detail inline (context, what to build, field-level specs, wire rules, test plan, verify commands). A reader with no repo access understands the task.
   - **No local file links or todo references** — link source files as GitHub `main` blob URLs instead (`https://github.com/<org>/<repo>/blob/main/<path>`).
   - Markdown with literal newlines; mention users as @displayName.
   Done when: every confirmed item exists with correct milestone, priority, and relations.

6. **Report.** Numbered list: identifier, title, URL, milestone, priority, blocking relations.

## Reference

- Priority mapping: 1=Urgent, 2=High, 3=Medium, 4=Low. "Required"/"top" → Urgent or High; "optional"/"later" → Low.
- Phases map to project milestones — not labels (no roll-up), not parent issues (that's decomposition), not separate projects (too heavy).
- **Gotcha:** MCP responses wrap payloads — parse `res.data.content[0].text` as JSON to get the created issue's identifier before wiring `blockedBy`.
