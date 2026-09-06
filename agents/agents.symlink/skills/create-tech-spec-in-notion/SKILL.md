---
name: create-tech-spec-in-notion
description: Creates a reviewable tech spec — named contracts an engineer can check a PR against, options with one recommendation — and publishes it to Notion. Use when the user asks to create, draft, write, or publish a tech spec, RFC, design doc, technical specification, or architecture decision, including when they do not say Notion.
---

# Create Tech Spec In Notion

A **reviewable** spec lets an engineer check a PR against named contracts,
**options**, and one recommendation.

Write the spec in simple english. Publish it to the Notion database and
template from `{skillDir}/notion.local.md`.

## NEVER

- NEVER dump implementation detail as the spec body. A reviewer cannot mark a
  PR done against internals that will move.
- NEVER present one option as a comparison. If only one option can work, name
  the rejected option and why it fails.
- NEVER link code to a feature branch. Blob URLs on `main` survive merge.
  Branch URLs do not.
- NEVER publish before the Reviewable bar. A Notion URL is not a spec.
- NEVER put actions in Open Questions. Write questions there. Put actions in
  Follow-up Tasks.
- NEVER use Cursor Notion MCP tools. They skip the CLI approval gate and
  `{skillDir}/notion.local.md`. Use
  `$HOME/.agents/skills/notion/scripts/notion` only.
- NEVER guess a database, template, or GitHub blob base. Read the local file,
  or search and ask.
- NEVER mix a partial `notion.local.md` with a guessed field.

## Notion CLI

CLI path: `$HOME/.agents/skills/notion/scripts/notion`. If the binary is
missing, stop. Return the draft in chat. Name the blocker. If a command prints
`AUTH_REQUIRED`, run `auth login`, then retry. Before any mutating `call`,
show the tool, the arguments, and the change. Wait for approval. `fetch`,
`search`, and `list-tools` do not need that approval.

## Draft language

Apply these rules to the full draft before you publish.

- Use one meaning per word. Do not rotate synonyms for the same action.
- Use active voice and simple tenses.
- Write one idea per sentence. Keep the subject and the verb.
- Use a list for 3 or more items.
- Remove filler, vague claims, and formulaic AI phrasing.
- Cut throat-clearing ("In this spec we will…"). State the fact.
- Do not write "not X, but Y". State Y.

## Destinations

Read `{skillDir}/notion.local.md`. The file is untracked. Schema:

```markdown
---
docs_database_id: "<uuid or Notion URL>"
tech_spec_template_id: "<uuid or Notion URL>"
github_blob_base: "https://github.com/<org>/<repo>/blob/main"
---
```

- All three fields are required when the file exists.
- Treat a partial file as missing. Do not fill a gap with a guess.
- IDs may be raw UUIDs or full Notion URLs. `fetch` accepts both.
- `github_blob_base` has no trailing slash. Code links are
  `{github_blob_base}/<path>`.
- Do not write `notion.local.md` unless the user asks.

## Audience

The audience is technical and the spec is for an engineer to review. Name
systems as they exist after the change. Do not avoid technical details.

Any summaries, backgrounds, introductions, and conclusions should be written for
a non-technical audience.

## Steps

**Do NOT load** [notion-publish.md](notion-publish.md) until step 7. Destinations
must be resolved first.

### 1. Read the section spec

Read [spec-structure.md](spec-structure.md) before you write any spec text.

Done when: you can name the headings in order. You can state each section's
completion criterion.

### 2. Gather evidence

Collect only the sources that explain the system change:

- User requirements, tickets, PRs, and links
- Repo docs, ADRs, plans, and nearest `AGENTS.md` files for touched code
- Code paths that define contracts, flows, data shapes, and boundaries
- Tests that show expected behavior

Stay at the system level. Add an implementation detail only when it changes a
contract, owner, sequence, rollout, or failure mode.

Done when: every later claim has a source (user, doc, or code), or it is an open
question.

### 3. Draft every section

Fill every heading from [spec-structure.md](spec-structure.md). Record
**options** with a recommendation.

Done when: every section meets its completion criterion in `spec-structure.md`,
or the section is marked `None` / `TBD`.

### 4. Make the draft reviewable

Apply the Draft language rules. Then check the Reviewable bar below.

Done when: the draft meets every item in the Reviewable bar.

### 5. Include a sequence diagram where relevant

When the spec describes a flow that crosses two or more actors or systems
(wire protocol exchanges, an ordered apply/commit sequence, lifecycle or
undo ordering), add a Mermaid sequence diagram to **Proposed Solution**. Use
a fenced code block whose language tag is mermaid. Notion renders those
blocks natively. If the spec has no multi-actor flow, skip the diagram. Do
not force one in.

Mermaid sequence-diagram pitfalls (seen in practice, parse-failure causes):

- A semicolon inside `Note` or message text ends the statement early. The
  parse fails with an `Expecting 'NEWLINE', ...` error. Use a comma or split
  into separate statements instead.
- Do not use `<br/>` inside `Note` text. Many renderers reject it and it
  breaks note parsing. Use plain text or a second `Note` line.
- Raw curly-brace JSON in message text (for example `{ status: applied }`)
  can fail in stricter renderers. Drop the braces or reword the message.
- Keep the diagram to the recommended sequence end to end: trigger, checks,
  commit, and the failure and reject paths.

Done when: the diagram parses in a standard Mermaid renderer and shows the
recommended sequence, or the absence of a diagram is a deliberate skip.

### 6. Resolve destinations

Set `NOTION_CLI="$HOME/.agents/skills/notion/scripts/notion"`.

If `{skillDir}/notion.local.md` exists and has all three fields, use those
values.

If the file is missing or partial:

1. Do not guess workspace, database, or template names.
2. `$NOTION_CLI search` with the user's words, or a generic query such as
   `tech spec`.
3. Show the results. Ask the user to pick the docs database and the tech spec
   template.
4. For `github_blob_base`, use `gh repo view --json nameWithOwner` (or
   `git remote`) and build `https://github.com/<nameWithOwner>/blob/main`.
   If that fails, ask the user.

If search returns nothing the user will pick: stop. Return the draft. Name
the blocker.

Done when: you have a docs database id, a template id or a named missing
template, and a GitHub blob base.

### 7. Publish to Notion

**MANDATORY - READ ENTIRE FILE**: Read [notion-publish.md](notion-publish.md)
before any write. **NEVER set any range limits when reading this file.**

Follow that file. Do not invent a page shape.

Done when: the page exists under the resolved data source and you are ready to
refetch it.

### 8. Verify and return

`$NOTION_CLI fetch` the finished page. Check headings, checkboxes, links, code
references, and any sequence diagram blocks.

Return the Notion page URL. Name every assumption and every gap in evidence.

Done when: the user has the URL, and incomplete sections are named.

## Reviewable bar

An engineer who did not write the spec can check a PR against it.

- Each contract names the system, the old behavior, and the new behavior.
- Names come from the codebase.
- Facts and assumptions are separate. Mark low-confidence claims.
- **Options** include at least one alternative, with pros, cons, and one
  recommendation.
- The draft follows the Draft language rules. Each bullet is one full sentence.
- All code links use GitHub `main`.

## Code Links

All code file links in the Notion spec point to `main` on the relevant GitHub
repo.

Use `github_blob_base` from `notion.local.md`, or the blob base resolved in
step 6.

```text
{github_blob_base}/<path>
```

- Use that GitHub `main` blob URL for every code file.
- Add a line anchor only when it stays stable enough to help.
- If a source lives in another repo, use that repo's GitHub `main` URL.
