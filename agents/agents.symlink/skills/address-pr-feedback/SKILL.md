---
name: address-pr-feedback
description: Work through GitHub PR review comments, unresolved review threads, inline discussions, and top-level review bodies. Use when the user asks to address PR feedback, implement review comments, just fix them, walk through comments, respond to reviewers, triage discussions, work through unresolved threads, or decide whether to fix, investigate, reply to, or skip pull request comments.
---

# Address PR Feedback

Work through open GitHub review feedback on the current PR. Verify each ask
against the current code before you change anything. Push back when the ask is
wrong. Do not perform agreement.

## NEVER

- NEVER load both mode files. Load `autonomous.md` or `interactive.md`, not
  both. They disagree on commit and post approval.
- NEVER post a GitHub reply with `gh pr comment` when the thread has an inline
  comment `databaseId`. That creates a detached PR comment and leaves the
  thread unanswered.
- NEVER implement an unclear ask. Stop and ask the user before you touch code.
- NEVER trust review feedback without reading the current code.
- NEVER add tool or agent authorship trailers to commit messages
  (`Co-authored-by: Cursor`, Claude, Copilot, or similar). They impersonate
  co-authors.
- NEVER resolve a review thread unless the user asks. Reply and leave it open.
  The reviewer resolves. Fetch already skips threads whose last reply is you.

## Required skills

- Use `gh` for every GitHub operation.
- Draft every GitHub reply from [replies.md](replies.md). Do not load
  `simple-english` for replies.
- For high-complexity code changes, instruct the subagent to use
  `coding-guidelines`.
- Apply `receiving-code-review`: verify, then act or push back. Do not agree as
  a performance. If that skill is missing, use the Reception stub in the mode
  file.

## Mode

Choose mode **once**. Do not re-ask per thread.

```text
User said "just fix them", "address all", "handle the comments"
  → autonomous. Read autonomous.md. Do NOT read interactive.md.

User said "walk me through", "triage", "ask me on each", or intent is unclear
  → interactive. Read interactive.md. Do NOT read autonomous.md.
```

Default when the user gives no extra signal: **interactive**.

## Steps

### 1. Fetch

**MANDATORY — READ ENTIRE FILE:** [fetch.md](fetch.md) (~150 lines)

Do not read a mode file yet. Do NOT load `replies.md`.

Done when: you have the PR number, the repo, and every unresolved thread with
its comments.

### 2. Classify

**MANDATORY — READ ENTIRE FILE:** [classify.md](classify.md) (~70 lines)

Done when: every unresolved item is either skipped as noise or has a rank and a
one-sentence ask.

### 3. Execute in one mode

**MANDATORY — READ ENTIRE FILE** for the chosen mode only:

- [autonomous.md](autonomous.md) (~75 lines)
- [interactive.md](interactive.md) (~95 lines)

Work one item at a time. Finish the item (change, test, reply, or skip) before
the next.

**MANDATORY — READ ENTIRE FILE before any GitHub reply:**
[replies.md](replies.md) (~80 lines)

Done when: every classified item has an action, or the user stopped the pass.

### 4. Summarize

Print:

- PR link
- Each item, action taken, commit SHA if any, whether a reply was posted
- Remaining skipped or unresolved items
- Verification commands that ran

Preserve unrelated working-tree changes. If feedback touches a dirty file,
inspect the diff and work with those changes.
