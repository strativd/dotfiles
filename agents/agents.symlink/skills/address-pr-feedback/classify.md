# Classify PR feedback

Classify after fetch, before you choose an action. Do not make a todo for
noise. Do not merge unrelated asks into one item.

## Actionable vs noise

Treat a comment as **actionable** when it asks for a concrete code, test, docs,
behavior, or explanation change that a later commit or reply has not already
addressed.

Treat a comment as **noise** when it is:

- Praise, status, or context with no request
- A duplicate of another unresolved thread — link it to the canonical item
- A review-summary restatement of asks that already exist as threads
- A question that needs an answer before a code change is safe — rank it, then
  choose **Respond**, not an implementation option
- A broad preference with no acceptance criteria — rank it Could or Won't, and
  prefer **Respond** or **Think on implementation** over a quick fix

## Kind

For each actionable item, also label the kind:

| Kind | Meaning | Default lean |
| --- | --- | --- |
| Suggested change | Comment body has a `suggestion` code fence | Apply the fence text if current code still matches. If not, treat as Outdated diff |
| Outdated diff | Comment sits on superseded code | Verify against current code. Often already done. Reply with the current file and line if so |
| Nit | Naming, style, formatting | Fix if trivial. Push back if subjective. Never block the PR on it |
| Blocking | Bug, regression, security, broken test | Must verify and fix, or answer explicitly |
| Out of scope | Feature work this PR does not cover | Push back with scope. Offer a follow-up issue |

A Suggested change is a GitHub apply-suggestion hunk, not ordinary fenced code.
Apply the fence. Do not rewrite the patch from memory.

Outdated does **not** mean skip. Check whether the concern still applies to the
current diff. If it does, fix current code or reply with the updated location.

## Rank

Rank every actionable item:

- **Must fix**: correctness, security, broken tests, merge blockers, data loss
- **Should fix**: maintainability, missing tests, confusing behavior,
  reviewer-blocking clarity
- **Could fix**: nits, style, naming, subjective cleanup
- **Won't fix**: not worth the effort, low priority, out of scope, not
  actionable

Work Must, then Should, then Could. Skip Won't unless the user asks to include
them.

## Item record

For each actionable item record:

- Stable number (1-based, this pass)
- Reviewer login
- File and line, or `—` for top-level asks
- One-sentence ask (from the latest reviewer comment, not only the first)
- Thread or comment URL
- Kind and rank
- Whether GitHub marks the thread outdated, or the line is deleted
- Whether the latest reviewer comment has a `suggestion` fence
- Root comment `databaseId` (needed later for replies)

Do not load a mode file until every unresolved thread is either noise or has
this record.
