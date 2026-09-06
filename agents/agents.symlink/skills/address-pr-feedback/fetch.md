# Fetch unresolved PR feedback

Identify the PR, then load unresolved review threads. Prefer GraphQL because it
exposes `isResolved`. Do not treat REST review bodies as threads.

## Identify the PR

```bash
git branch --show-current
gh pr view --json number,title,headRefName,baseRefName,url,author,state
gh repo view --json nameWithOwner --jq '.nameWithOwner'
gh api user --jq '.login'
```

If `gh` cannot infer the repo, pass `-R owner/repo` on every later `gh`
command. If no PR exists for the current branch, ask the user for a PR number
or URL.

Get `{owner}/{repo}` from `nameWithOwner`. Keep `{PR}`, `{owner}`, `{repo}`,
and your GitHub login for the rest of the pass.

## Fetch review threads (source of truth)

Paginate. The first 100 threads can miss active discussions on large PRs.

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$number:Int!,$cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first:100) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              databaseId
              author { login }
              body
              url
              createdAt
            }
          }
        }
      }
    }
  }
}' \
  -F owner=OWNER -F repo=REPO -F number=PR_NUMBER
```

Repeat while `pageInfo.hasNextPage` is true. Pass `endCursor` as `$cursor` on
the next call.

If a kept thread has `comments.totalCount` greater than the nodes you have,
page that thread's comments until complete. Do not classify from a truncated
thread:

```bash
gh api graphql -f query='
query($id:ID!,$cursor:String) {
  node(id:$id) {
    ... on PullRequestReviewThread {
      comments(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          databaseId
          author { login }
          body
          url
          createdAt
        }
      }
    }
  }
}' \
  -F id=THREAD_ID
```

Start `$cursor` at the comments `endCursor` you already have. Repeat while
`hasNextPage` is true.

Keep only `isResolved == false`.

If GraphQL rejects a field such as `isOutdated`, remove that field and keep
going. Resolution state is the source of truth.

If GraphQL fails from permissions or schema differences, fall back to REST
comments and mark resolution state as best-effort. Do not pretend the list is
complete.

## REST fallback and extras

Inline comments (all threads). Use this when GraphQL is unavailable, or to
recover a `databaseId` for replies:

```bash
gh api "repos/{owner}/{repo}/pulls/{PR}/comments" \
  --paginate \
  --jq '[.[] | {id, body, path, line, in_reply_to_id, html_url, user: .user.login}]'
```

Root comments have no `in_reply_to_id`. Group replies by that chain.

Include review bodies and top-level PR comments **only** when they contain an
actionable ask that is not already in an unresolved thread. These endpoints do
not expose thread resolution:

```bash
gh api "repos/{owner}/{repo}/pulls/{PR}/reviews" \
  --jq '[.[] | select(.body != "") | {id, body, state, html_url, user: .user.login}]'
gh api "repos/{owner}/{repo}/issues/{PR}/comments" --paginate
```

## Filter before classify

Skip:

- Threads with `isResolved: true`, unless the user asks to revisit them
- Threads whose most recent reply is from **you**, unless the user asks to
  revisit them. That is the re-entry rule. Do not resolve threads to hide
  them. Reply and leave them open.

Do not skip outdated or deleted-line threads here. Classify them against the
current code in [classify.md](classify.md).

Read the **whole** thread. The last reviewer comment often narrows or reverses
the original ask.

Pending or deleted comments may have no useful line. Keep the thread URL and
note the missing location.

## Fetch failures

| Symptom | Cause | Fix |
| --- | --- | --- |
| `gh pr view` errors | Not on a PR branch | Ask for the PR number or URL, then `gh pr view {PR}` |
| Comments missing from REST | Thread resolved in the UI | Use the GraphQL query above |
| GraphQL field error | Schema or permission difference | Drop the rejected field; keep `isResolved` |
| Rate limit (403) | Paginated or rapid calls | Slow down; add `sleep` between pages. `--paginate` is still required |
| `gh` cannot infer repo | Ambiguous remotes | Compute `owner/repo` once and pass `-R` on every command |
| Thread `comments.totalCount` > nodes you have | Nested comments not paged | Repeat the `node(id: thread.id)` comments query with `after: endCursor` |
