# gtree — git worktree mini CLI
# Subcommands: switch, add, remove, lock, unlock, prune, list, move

# Internal: build one fzf display row for a worktree.
# Output: epoch TAB path TAB display_line
_gtree_row() {
  local wt_path="$1" branch_label="${2:-}"
  local y=$'\e[33m' g=$'\e[32m' b=$'\e[1m' r=$'\e[0m'

  [[ -z "$branch_label" ]] && branch_label="(no branch)"
  local epoch reldate subject shortpath
  epoch=$(git -C "$wt_path" log -1 --format=%ct 2>/dev/null) || epoch=0
  reldate=$(git -C "$wt_path" log -1 --format=%cr 2>/dev/null) || reldate="?"
  subject=$(git -C "$wt_path" log -1 --format=%s 2>/dev/null) || subject="?"
  shortpath="${wt_path/#$HOME/~}"
  print -r -- "$epoch"$'\t'"$wt_path"$'\t'"${y}${shortpath}${r} | (${g}${reldate}${r}) ${b}${branch_label}${r} - ${subject}"
}

# Internal: emit all worktrees sorted by recency as "path TAB display_line"
_gtree_rows() {
  local line wt_path="" branch_label="" ref
  local -a rows

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      [[ -n "$wt_path" ]] && rows+=("$(_gtree_row "$wt_path" "$branch_label")")
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
  [[ -n "$wt_path" ]] && rows+=("$(_gtree_row "$wt_path" "$branch_label")")

  (( ${#rows} == 0 )) && return 1
  print -l "${rows[@]}" | LC_ALL=C sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r _epoch p d; do
    printf '%s\t%s\n' "$p" "$d"
  done
}

# Internal: fzf-pick a worktree; prints path to stdout; empty = user cancelled
_gtree_pick() {
  local prompt="${1:-worktree}"
  local rows
  rows=$(_gtree_rows) || { print -u2 "gtree: no worktrees found"; return 1; }
  local selected
  selected=$(print -r -- "$rows" | fzf --ansi --delimiter=$'\t' --with-nth=2 --prompt="$prompt> ") || return 0
  [[ -z "$selected" ]] && return 0
  printf '%s' "${selected%%$'\t'*}"
}

# Internal: resolve main worktree root (always the primary repo, not a linked worktree)
_gtree_top() {
  local top
  top=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print substr($0, 10); exit }')
  if [[ -z "$top" ]]; then
    print -u2 "gtree: not inside a git repository"
    return 1
  fi
  print -r -- "$top"
}

# Internal: default worktrees base dir (prefers existing .worktrees/ or worktrees/)
_gtree_base() {
  local top="$1"
  if [[ -d "$top/.worktrees" ]]; then
    print -r -- "$top/.worktrees"
  elif [[ -d "$top/worktrees" ]]; then
    print -r -- "$top/worktrees"
  else
    print -r -- "$top/.worktrees"
  fi
}

# gtree switch [branch] — cd into a worktree
_gtree_switch() {
  local dest
  if [[ -n "${1-}" ]]; then
    local top
    top=$(_gtree_top) || return 1
    dest=$(git -C "$top" worktree list --porcelain 2>/dev/null | awk -v b="$1" '
      /^worktree / { path = substr($0, 10) }
      /^branch /   { ref = substr($0, 8); sub(/^refs\/heads\//, "", ref); if (ref == b) { print path; exit } }
    ')
    if [[ -z "$dest" ]]; then
      print -u2 "gtree switch: no worktree for branch '$1'"
      return 1
    fi
  else
    (( $+commands[fzf] )) || { print -u2 "gtree switch: fzf not found"; return 1; }
    dest=$(_gtree_pick "switch") || return 1
    [[ -z "$dest" ]] && return 0
  fi
  [[ ! -d "$dest" ]] && { print -u2 "gtree switch: not a directory: $dest"; return 1; }
  cd "$dest"
  print -u2 "gtree: switched to $dest"
}

# gtree add [branch] [--path <path>]
#   No args: fzf pick from existing branches not yet checked out
#   branch: add worktree for that branch (local, remote, or new)
_gtree_add() {
  local top custom_path="" branch
  top=$(_gtree_top) || return 1

  local -a rest=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)   shift; custom_path="$1"; shift ;;
      --path=*) custom_path="${1#--path=}"; shift ;;
      *)        rest+=("$1"); shift ;;
    esac
  done

  if [[ ${#rest} -eq 0 ]]; then
    (( $+commands[fzf] )) || { print -u2 "gtree add: fzf not found"; return 1; }
    local picked
    picked=$(git -C "$top" branch -a --format='%(refname:short)' 2>/dev/null \
      | grep -v 'HEAD' \
      | fzf --prompt="add worktree> ") || return 0
    [[ -z "$picked" ]] && return 0
    branch="$picked"
  else
    branch="${rest[1]}"
  fi

  # Determine local branch name (strip remote/ prefix if it's a remote ref)
  local local_branch="$branch"
  if [[ "$branch" == */* ]] && git -C "$top" show-ref --verify --quiet "refs/remotes/$branch" 2>/dev/null; then
    local_branch="${branch##*/}"
  fi

  # Resolve worktree path
  local worktree_path
  if [[ -n "$custom_path" ]]; then
    worktree_path="$custom_path"
    [[ "$worktree_path" != /* ]] && worktree_path="$top/$worktree_path"
  else
    local base slug
    base=$(_gtree_base "$top")
    slug="${local_branch//\//-}"
    worktree_path="$base/$slug"
  fi

  local parent="${worktree_path:h}"
  [[ ! -d "$parent" ]] && mkdir -p "$parent"

  if [[ "$worktree_path" == "$top"/* ]]; then
    local rel="${worktree_path#$top/}"
    git -C "$top" check-ignore -q "$rel" 2>/dev/null || \
      print -u2 "gtree add: warning: '$rel' is not git-ignored"
  fi

  if git -C "$top" show-ref --verify --quiet "refs/heads/$local_branch" 2>/dev/null; then
    git -C "$top" worktree add "$worktree_path" "$local_branch" || return 1
  elif [[ "$local_branch" != "$branch" ]]; then
    git -C "$top" worktree add -b "$local_branch" "$worktree_path" "refs/remotes/$branch" || return 1
  else
    git -C "$top" worktree add -b "$branch" "$worktree_path" || return 1
  fi

  print -u2 "gtree: switched to $worktree_path"
  cd "$worktree_path"
}

# gtree remove [path] — remove a worktree
_gtree_remove() {
  local top dest
  top=$(_gtree_top) || return 1
  if [[ -n "${1-}" ]]; then
    dest="$1"
  else
    (( $+commands[fzf] )) || { print -u2 "gtree remove: fzf not found"; return 1; }
    dest=$(_gtree_pick "remove") || return 1
    [[ -z "$dest" ]] && return 0
  fi
  local current_wt
  current_wt=$(git rev-parse --show-toplevel 2>/dev/null)

  git -C "$top" worktree remove "$dest" || return 1
  print -u2 "gtree: removed $dest"

  # If we just removed our own worktree, switch to main
  if [[ "$current_wt" == "$dest" ]]; then
    local main_branch
    main_branch=$(git -C "$top" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
    main_branch="${main_branch#origin/}"
    [[ -z "$main_branch" ]] && main_branch="main"
    cd "$top"
    print -u2 "gtree: switched to $top ($main_branch)"
  fi
}

# gtree lock [path] — lock a worktree
_gtree_lock() {
  local top dest
  top=$(_gtree_top) || return 1
  if [[ -n "${1-}" ]]; then
    dest="$1"
  else
    (( $+commands[fzf] )) || { print -u2 "gtree lock: fzf not found"; return 1; }
    dest=$(_gtree_pick "lock") || return 1
    [[ -z "$dest" ]] && return 0
  fi
  git -C "$top" worktree lock "$dest" || return 1
  print -u2 "gtree: locked $dest"
}

# gtree unlock [path] — unlock a worktree
_gtree_unlock() {
  local top dest
  top=$(_gtree_top) || return 1
  if [[ -n "${1-}" ]]; then
    dest="$1"
  else
    (( $+commands[fzf] )) || { print -u2 "gtree unlock: fzf not found"; return 1; }
    dest=$(_gtree_pick "unlock") || return 1
    [[ -z "$dest" ]] && return 0
  fi
  git -C "$top" worktree unlock "$dest" || return 1
  print -u2 "gtree: unlocked $dest"
}

gtree() {
  local cmd="${1-}"
  [[ -n "$cmd" ]] && shift
  case "$cmd" in
    switch)            _gtree_switch "$@" ;;
    add)               _gtree_add "$@" ;;
    remove|rm)         _gtree_remove "$@" ;;
    lock)              _gtree_lock "$@" ;;
    unlock)            _gtree_unlock "$@" ;;
    prune|list|move)   git worktree "$cmd" "$@" ;;
    '')
      print -u2 "Usage: gtree <switch|add|remove|lock|unlock|prune|list|move>"
      return 1
      ;;
    *)
      print -u2 "gtree: unknown subcommand '$cmd'"
      print -u2 "Usage: gtree <switch|add|remove|lock|unlock|prune|list|move>"
      return 1
      ;;
  esac
}
