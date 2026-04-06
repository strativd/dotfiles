# Git worktree helpers — work from any directory inside a repository.

# Parse user arg into "remote branch" (stdout: two words).
# - origin/feature/foo -> origin + feature/foo
# - feature/foo -> origin + feature/foo unless "feature" is a configured remote
# - main -> origin + main
_tree-branch_parse_ref() {
  local top="$1" arg="$2"
  local first rest
  local -a remotes

  if [[ "$arg" != */* ]]; then
    print -r -- "origin $arg"
    return 0
  fi

  first="${arg%%/*}"
  rest="${arg#*/}"
  remotes=(${(f)"$(git -C "$top" remote 2>/dev/null)"})

  if (( ${remotes[(Ie)$first]} )); then
    print -r -- "$first $rest"
  else
    print -r -- "origin $arg"
  fi
}

# Add a worktree for a branch that exists on a remote (after fetch).
#
# Usage: tree-branch <remote>/<branch> | <branch> [path]
#   Branch forms:
#     origin/feature/x   explicit remote
#     feature/x          uses origin unless the first path segment matches a remote name
#     main               shorthand for origin/main
#   path: optional checkout directory; relative paths are under the repo root.
#   Default: .worktrees/<branch-with-slashes-as-dashes> or worktrees/ if that exists.
tree-branch() {
  if [[ -z "$1" ]]; then
    print -u2 "Usage: tree-branch <remote>/<branch> | <branch> [path]"
    return 1
  fi

  local top remote branch ref worktree_path base slug parsed
  top=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 "tree-branch: not inside a git repository"
    return 1
  }

  parsed=($(_tree-branch_parse_ref "$top" "$1"))
  remote=$parsed[1]
  branch=$parsed[2]
  ref="$remote/$branch"

  if [[ -n "${2-}" ]]; then
    worktree_path="$2"
    if [[ "$worktree_path" != /* ]]; then
      worktree_path="$top/$worktree_path"
    fi
  else
    if [[ -d "$top/.worktrees" ]]; then
      base="$top/.worktrees"
    elif [[ -d "$top/worktrees" ]]; then
      base="$top/worktrees"
    else
      base="$top/.worktrees"
    fi
    slug="${branch//\//-}"
    worktree_path="$base/$slug"
  fi

  if ! git -C "$top" fetch "$remote" "$branch"; then
    print -u2 "tree-branch: fetch failed for $ref"
    return 1
  fi

  if ! git -C "$top" rev-parse --verify -q "$ref"; then
    print -u2 "tree-branch: no such ref after fetch: $ref"
    return 1
  fi

  local parent="${worktree_path:h}"
  if [[ ! -d "$parent" ]]; then
    mkdir -p "$parent" || return 1
  fi

  if [[ "$worktree_path" == "$top"/* ]]; then
    local rel="${worktree_path#$top/}"
    if ! git -C "$top" check-ignore -q "$rel" 2>/dev/null; then
      print -u2 "tree-branch: warning: '$rel' is not ignored — consider adding it to .gitignore"
    fi
  fi

  if git -C "$top" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$top" worktree add "$worktree_path" "$branch" || return 1
  else
    git -C "$top" worktree add -b "$branch" "$worktree_path" "$ref" || return 1
  fi

  print -r -- "Worktree: $worktree_path"
}
