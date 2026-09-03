---
description: "Create a draft GitHub PR for the current branch, assigned to me, with a G:: grimoire label and a template-based, reviewer-focused description"
argument-hint: "[base-branch]"
---

Create a GitHub pull request for the current branch as a **draft**, assigned to me, using the base branch `${1:-main}` (if that base does not exist, detect the repo's default branch via `gh repo view --json defaultBranchRef`).

## Steps

1. **Verify state**: confirm there are commits ahead of the base branch (`git log --oneline ${1:-main}..HEAD`). If the branch is not pushed or the remote is behind, push with `git push -u origin HEAD` first.

2. **Pick the grimoire label**:
   - Run `gh label list --limit 200 --json name --jq '.[].name | select(startswith("G::"))'` to get the available grimoire labels.
   - Based on the chat context (the task, any linked issues/PRs, commit messages, and the diff), choose the single most relevant `G::` label.
   - If none plausibly matches, use `G::NONE`.

3. **Write the description** following the repo's PR template (`.github/pull_request_template.md` — Motivation / Background, Detail, Additional information, Checklist):
   - Read and apply the `simple-english` skill (ASD-STE100 style: one meaning per word, active voice, simple tense, short sentences) to ALL prose you write.
   - Write for reviewers: focus on **why** the change exists, **what behavior changes**, **risks**, and **how it was tested**.
   - Do NOT restate the diff or implementation details in plain text (reviewers can read the code). No file-by-file or line-by-line narration.
   - Keep it short. Fill the template sections; remove sections that genuinely have nothing to say (except Checklist — check the boxes that are true).
   - Link related issues/PRs from chat context (e.g. `Closes #123`) where applicable.

4. **Create the PR**:
   ```
   gh pr create --draft --assignee @me --base ${1:-main} --label "<chosen G:: label>" --title "<concise title>" --body "<description>"
   ```
   - Title: concise, imperative, under ~70 chars.
   - If label application fails (label missing on this repo), create the PR anyway without it and note that.

5. **Report back**: give me the PR URL, the label you chose and why, and confirm it is a draft assigned to me.

If anything is ambiguous (wrong base branch, no matching label candidate, uncommitted changes that should be included), stop and ask before creating the PR.
