---
name: eng-code-reviews-stack
description: Summarize a PR stack (stacked branches/PRs, possibly across multiple repos) into a bottom-to-top review list with per-PR TLDRs and line counts, formatted for sharing in Slack. Use when the user asks to "share the stack", "summarize the stack for review", lists stacked PRs, mentions a PR stack or gh-stack, or wants PRs ordered bottom to top.
---

# PR Stack Review Summary

Produce a shareable summary of a PR stack for reviewers who are technical but
have little context on the feature.

## Output format

1. **Feature intro** — 1–2 sentences explaining what the feature is and how it
   works, written for someone with zero context on it.
2. **PR list, bottom to top**, one PR per line — no bullet points, each
   line starts directly with the URL:

   ```
   PR_URL - `LINES_ADDED`/`LINES_REMOVED` - TLDR_SENTENCE
   PR_URL - `LINES_ADDED`/`LINES_REMOVED` - TLDR_SENTENCE
   ```

3. Optionally offer (or produce, if asked) a Slack-ready variant.

Group the list with small headers when states differ:

- **Foundation (already merged)** — stack layers already in the base branch.
- **Open, merge-intended (bottom → top)** — the main reviewable body.
- **Disposable / proof PRs (not intended to merge)** — proof-of-concept layers;
  flag them clearly so reviewers don't waste time.

  Within each group, PR lines are plain lines (no bullets/dashes).

## Workflow

### 1. Discover the stack

- `gh pr list --state open --limit 50 --json number,title,url,headRefName,baseRefName`
  in each repo of the workspace.
- Filter to branches belonging to the feature: match branch-name prefixes
  (e.g. `feat/client-tool-calls-*`, `feat/<feature>-*`), the checked-out
  branch, or branches named in `gh-stack` state.
- Stacks can span multiple repos — check every repo in the workspace.
- A PR is part of a stack when its `baseRefName` is another feature branch,
  not a default branch.

### 2. Resolve stacking order and merge state

- Build the chain from `baseRefName` → `headRefName` edges; the PR based on
  the default branch is the bottom.
- Mark each PR's state (`gh pr view <n> --json state`).
- Re-landed PRs: a CLOSED PR may have been squashed and re-landed under a new
  number. Verify with
  `git log origin/main --oneline | grep '(#<n>)'` — the PR number in the
  squash-merge title is the one that actually landed. Use the landed PR's
  numbers and mark it merged.

### 3. Collect per-PR metadata

One batch call per repo:

```bash
gh pr view <n> --json number,url,state,baseRefName,headRefName,additions,deletions,body
```

Line counts: use `additions`/`deletions` verbatim, wrapped in backticks:
`` `3354`/`0` ``.

### 4. Write TLDRs

- One line per PR by default; go longer only when the PR genuinely needs it.
- Derive each TLDR from the PR body's Motivation/Background + Detail sections —
  state what the PR adds/fixes and why it exists, not just what files change.
- Call out landmines reviewers should know up front (e.g. "large because a
  JSON Schema is vendored in").
- For proof/disposable PRs, say so explicitly in the TLDR.
- Reference sibling-stack PRs by number when a PR depends on them.

### 5. Emit and offer follow-ups

- Emit the summary in the output format above.
- Offer follow-ups: Slack-ready formatting (dropped repo prefixes, PR numbers
  as Slack links), trimming merged layers, or excluding disposable PRs.

## Checklist

- [ ] Every PR in the chain found, including cross-repo layers
- [ ] Order verified against base→head edges (bottom = based on default branch)
- [ ] Closed-but-re-landed PRs resolved to the landed PR number
- [ ] Merged, open, and disposable PRs grouped and labeled
- [ ] TLDRs derived from PR bodies, not filenames
- [ ] Feature intro present and assumes no prior context
