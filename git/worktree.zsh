# Git worktree helpers — work from any directory inside a repository.

# One porcelain worktree block -> sort key, path, fzf display line (internal).
_git_checkout_worktree_row() {
  local wt_path="$1" branch_label="${2:-}"
  local y=$'\e[33m' g=$'\e[32m' b=$'\e[1m' r=$'\e[0m'
  local epoch reldate subject shortpath display

  [[ -z "$branch_label" ]] && branch_label="(no branch)"
  epoch=$(git -C "$wt_path" log -1 --format=%ct 2>/dev/null) || epoch=0
  reldate=$(git -C "$wt_path" log -1 --format=%cr 2>/dev/null) || reldate="?"
  subject=$(git -C "$wt_path" log -1 --format=%s 2>/dev/null) || subject="?"
  shortpath="${wt_path/#$HOME/~}"
  display="${y}${shortpath}${r} | (${g}${reldate}${r}) ${b}${branch_label}${r} - ${subject}"
  print -r -- "$epoch"$'\t'"$wt_path"$'\t'"$display"
}

# Print chosen worktree path to stdout (stderr for errors). Empty stdout + exit 0 = user cancelled fzf.
# Used by `git cow` ($ZSH/bin/git-cow) and by git-cow().
git_checkout_worktree() {
  if ! git rev-parse --show-toplevel &>/dev/null; then
    print -u2 "git-cow: not inside a git repository"
    return 1
  fi
  if (( ! $+commands[fzf] )); then
    print -u2 "git-cow: fzf not found"
    return 1
  fi

  local line wt_path="" branch_label="" ref
  local -a rows

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      [[ -n "$wt_path" ]] && rows+=("$(_git_checkout_worktree_row "$wt_path" "$branch_label")")
      wt_path="" branch_label=""
      continue
    fi
    case "$line" in
      worktree\ *) wt_path="${line#worktree }" ;;
      branch\ *)
        ref="${line#branch }"
        branch_label="${ref#refs/heads/}"
        [[ "$branch_label" == "$ref" ]] && branch_label="${ref#refs/remotes/}"
        ;;
      detached) branch_label="(detached)" ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)

  [[ -n "$wt_path" ]] && rows+=("$(_git_checkout_worktree_row "$wt_path" "$branch_label")")

  if (( ${#rows} == 0 )); then
    print -u2 "git-cow: no worktrees found"
    return 1
  fi

  local selected dest
  selected=$(print -l "${rows[@]}" | LC_ALL=C sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r epoch p d; do
    printf '%s\t%s\n' "$p" "$d"
  done | fzf --ansi --delimiter=$'\t' --with-nth=2)

  [[ -z "$selected" ]] && return 0
  dest="${selected%%$'\t'*}"
  if [[ ! -d "$dest" ]]; then
    print -u2 "git-cow: not a directory: $dest"
    return 1
  fi
  print -r -- "$dest"
}

# cd into fuzzy-picked worktree (current shell). With the git alias: cd "$(git cow)".
git-cow() {
  local dest
  _dest=$(git_checkout_worktree) || return 1
  [[ -z "$dest" ]] && return 0
  cd "$dest" || return 1
}

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
