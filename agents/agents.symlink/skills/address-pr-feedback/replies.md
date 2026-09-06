# Replies

Post in the review thread, not as a top-level PR comment, whenever the item has
an inline `databaseId`.

Interactive mode: draft, then post only after the user confirms.
Autonomous mode: post after you finish the item.

## Target

Reply to the **root** comment. The root comment has no `in_reply_to_id`. Its
id is `databaseId` from GraphQL, or `id` from REST.

Passing a reply's id creates a new orphaned thread. That fragments the
discussion.

```bash
gh api "repos/{owner}/{repo}/pulls/comments/{COMMENT_DATABASE_ID}/replies" \
  -X POST \
  -f body="<your reply>"
```

Use `gh pr comment {PR} --body "..."` only for top-level review bodies or issue
comments that have no inline thread target.

If a reply returns 403/404, you may lack write access (fork or missing
collaborator). Reply only on the upstream repo. If you still cannot post, give
the user the drafted text and the thread URL. Do not pretend the reply landed.

## Shape

Three shapes. Pick one:

- **Fixed:** what changed and where. In interactive mode, after an approved
  commit, use `Fixed <COMMIT_ID>`. In autonomous mode, a short description is
  enough. Add the SHA if the batch commit already exists.
- **Pushback:** technical reasoning. One short paragraph. No apology.
- **Question:** one focused question if you need clarification before you act.

No "Thanks!", no "Great catch!", no "You're absolutely right!". State the
action or the reasoning.

## Prose

Do not load `simple-english` for these replies. Its output is a comparison
table. Apply these rules to the reply body instead:

- Active voice, simple tenses. "The test fails on Python 3.12." — not "The
  failure is being caused by a Python 3.12 incompatibility."
- One meaning per word. Pick one verb per action and reuse it. If you say
  "rename" in the first sentence, do not switch to "update" or "change" for the
  same action in the second.
- ≤25 words per sentence, one idea per sentence. Split compound sentences. A
  pushback paragraph becomes 2–4 short sentences, not one long one.
- No 4+ word noun stacks. "the agent task queue retry handler" → "the handler
  that retries tasks from the agent task queue".
- Keep every qualifier. Simplification never drops a condition, scope limit, or
  exception.
- No hedging filler. "It might potentially be the case that..." → "X causes Y"
  or, when you do not know, "I do not know the cause yet."

Do not force this flatness onto code identifiers, quoted error text, or the
reviewer's own words. Quote those exactly. The discipline applies to your
prose, not to technical tokens.

## Reply failures

| Symptom | Cause | Fix |
| --- | --- | --- |
| Reply returns 403/404 | Not a collaborator, or PR lives in a fork | Reply on the upstream repo. If no write access, give the user the draft |
| Reply appears as a new thread | Used a reply's id instead of the root comment id | Use the root comment's `databaseId` |
| Rate limit (403) | Rapid posts | Add `sleep` between replies |
| `Fixed <SHA>` posted too early | Commit missing, mixed, or unconfirmed | Verify the commit contains only that item, then post |

## Do not

- NEVER post `Fixed <COMMIT_ID>` before the commit exists and contains only the
  intended item.
- NEVER use `gh pr comment` for an inline thread that has a `databaseId`.
- NEVER thank the reviewer or agree as a performance.
- NEVER resolve the review thread after posting. Leave it open unless the user
  asked to resolve it.
