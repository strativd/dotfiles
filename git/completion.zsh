### GIT COMPLETIONS ###
# Uses git's autocompletion for inner commands. Assumes an install of git's
# bash `git-completion` script at $completion below (this is where Homebrew
# tosses it, at least).
completion='$(brew --prefix)/share/zsh/site-functions/_git'

if test -f $completion
then
  source $completion
fi

### GT COMPLETIONS ###

_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt

### GTREE COMPLETIONS ###

_gtree() {
  local -a subcommands=(
    'switch:cd into a worktree (fzf or branch name)'
    'add:add a worktree (fzf branch or new name)'
    'remove:remove a worktree (fzf or path)'
    'lock:lock a worktree (fzf or path)'
    'unlock:unlock a worktree (fzf or path)'
    'prune:prune stale worktree admin files'
    'list:list all worktrees'
    'move:move a worktree to a new path'
  )
  if (( CURRENT == 2 )); then
    _describe 'subcommand' subcommands
  elif (( CURRENT == 3 )); then
    case "${words[2]}" in
      switch|remove|lock|unlock)
        local -a wts
        wts=("${(@f)$(git worktree list --porcelain 2>/dev/null \
          | awk '/^branch / { sub(/^refs\/heads\//, "", $2); print $2 }')}")
        _describe 'worktree' wts
        ;;
      add)
        local -a branches
        branches=("${(@f)$(git branch -a --format='%(refname:short)' 2>/dev/null | grep -v HEAD)}")
        _describe 'branch' branches
        ;;
    esac
  fi
}
compdef _gtree gtree

### G COMPLETIONS ###
compdef g=git
