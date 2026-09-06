# Interactive mode

Load this file only when the user asked to triage, walk through comments, or
gave no extra signal. Do **not** load [autonomous.md](autonomous.md).

You classify, recommend, and wait. Do not edit code, commit, or post to GitHub
until the user selects that action for that item.

## Gates

- Confirm with the user before posting anything to GitHub.
- Do not edit code until the user selects an implementation option for that
  item.
- Selecting an implementation option authorizes code edits for **that item
  only**. It does not authorize commits or GitHub replies unless the user says
  so.
- If the user approves a commit, make exactly one commit for that item. Do not
  add tool or agent `Co-authored-by` trailers.
- After an approved implementation commit, draft the thread reply. Post it only
  after user confirmation. Do not resolve the thread.
- Preserve unrelated working-tree changes. If feedback touches a dirty file,
  inspect the diff and work with those changes.

## Recommend, then ask

Create a todo for every actionable item. For each item, give the four options
below, plus one recommended option and a one-sentence rationale. Then wait.

Use `AskQuestion` when it is available. Otherwise present the options in chat
and wait.

1. **Quick implementation**: implement the minor, obvious fix. Ask separately
   whether to create the one-item commit after verification, unless the user
   already granted commit approval. Recommend this only when the fix is
   small and unambiguous, including a Suggested change whose fence still
   matches the current file.

2. **Think on implementation**: dispatch a subagent to investigate and fix.
   Instruct it to use `coding-guidelines`. Recommend this for high-complexity
   changes or whenever the fix is ambiguous.

3. **Respond**: draft a GitHub comment instead of changing code. Recommend this
   when clarification is needed or the feedback should not be implemented. If
   selected, provide the recommended response and ask for confirmation before
   posting.

4. **Skip for now**: leave the feedback unresolved for this pass.

Still verify the ask against the code **before** you recommend. Do not
recommend Quick implementation for an ask you have not checked. If the ask is
wrong, recommend Respond with pushback, not a fix.

## Execute one selection

Finish the selected action before you ask about the next item.

For quick implementation, dispatch a subagent with:

```text
Implement PR feedback item <number> from <thread URL>. Make the smallest
correct change. If the item is a Suggested change, apply the suggestion fence
text; do not retype it. Preserve unrelated working-tree changes, run relevant
checks, and return the diff summary plus verification output. Do not commit
or post to GitHub unless the parent prompt explicitly says the user approved
a commit for this item.
```

For think on implementation, dispatch a subagent with:

```text
Investigate and fix PR feedback item <number> from <thread URL>. Use the
coding-guidelines skill before editing. Verify the feedback against the code,
choose the smallest correct fix, preserve unrelated working-tree changes, run
relevant checks, and return reasoning, diff summary, and verification output.
Do not commit or post to GitHub unless the parent prompt explicitly says the
user approved a commit for this item.
```

For Respond, draft the exact reply using [replies.md](replies.md). Ask the user
to confirm. Post only after confirmation.

If the user approves committing an implemented item, create exactly one commit
for that item, then draft `Fixed <COMMIT_ID>`. Ask the user to confirm posting.
Post only after confirmation.

## Do not

- Do not treat a menu selection as commit or post approval.
- Do not let a subagent commit or post unless the user approved that action for
  the item.
- Do not combine unrelated reviewer asks into one commit.
- Do not start the next item until this one is done or skipped.
- Do not resolve the GitHub thread unless the user asks.
- Do not add tool or agent `Co-authored-by` trailers.
