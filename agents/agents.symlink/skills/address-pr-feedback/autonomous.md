# Autonomous mode

Load this file only when the user asked you to fix, address, or handle the
comments without a per-item menu. Do **not** load
[interactive.md](interactive.md).

You triage, verify, implement or push back, and reply. Do not wait for a
per-item choice. Still stop and ask the user when an ask is unclear.

## Reception

Follow `receiving-code-review` before you change code or reply. If that skill
is missing:

```text
FORBIDDEN:
  "You're absolutely right!"  "Great point!"  "Let me implement that now"

REQUIRED:
  1. Restate the ask in your own words
  2. Verify against the codebase — grep, read the file, check tests
  3. Evaluate: technically correct? breaks anything? YAGNI?

IF unclear → stop, ask the user before implementing anything
IF wrong   → push back with technical reasoning
IF correct → implement, then reply
```

Push back when the suggestion breaks behavior or tests, is unused (YAGNI —
grep first), lacks current context, or conflicts with an architectural
decision.

## Per item

Work one classified item at a time, Must first.

1. Display reviewer, file and line, and the full thread.
2. Verify the ask against current code.
3. If a change is warranted, make the smallest correct change. For a
   Suggested change kind, apply the `suggestion` fence text to the current
   file. Do not retype it. If the surrounding code no longer matches, treat
   it as outdated: verify the concern, then fix current code or push back.
   Preserve unrelated working-tree changes. Run the relevant tests or
   type-checks.
4. If the change is high-complexity or still ambiguous after verification,
   dispatch a subagent. Instruct it to use `coding-guidelines`. The subagent
   must not commit or post to GitHub.
5. Reply in the thread. Read [replies.md](replies.md) before you post.
   Autonomous mode **does** authorize posting the reply for that item. Do not
   ask for confirmation per reply unless the reply is a question to the user,
   not the reviewer.

Do not commit yet. Keep going.

## Commits

After all items in this pass are done, make **one** commit for all autonomous
fixes unless the user asked otherwise. Do not push per-item commits. Reviewers
re-read one diff.

Do not commit if nothing changed.

After that commit exists, you may include the SHA in replies that you have not
posted yet. If you already replied `Fixed — …` without a SHA, do not post a
second reply just to add it.

## Do not

- Do not ask the four-option menu from interactive mode.
- Do not make one commit per item.
- Do not skip verification because the user said "just fix them".
- Do not implement Won't-fix or out-of-scope asks. Reply with the pushback.
- Do not resolve the GitHub thread after you reply.
- Do not add tool or agent `Co-authored-by` trailers.
