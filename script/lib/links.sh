#
# Symlink engine for dotfiles and config directories. Sourced, not executed.
#
# Requires DOTFILES_ROOT and HOME in the environment, and output.sh sourced
# first. Targets bash 3.2, the macOS system bash.
#
# Conventions, rooted at an entry named NAME.symlink at depth 1-2 of the repo:
#
#   Rule 1  file NAME.symlink       ->  $HOME/.NAME
#   Rule 2  dir  NAME.symlink       ->  walk into $HOME/.NAME; intermediate
#                                       directories are real, leaf files are
#                                       linked individually
#
# Only the link root gains a leading dot; nested paths map verbatim.

LINK_IGNORE=(".DS_Store" ".git" ".link-children")
: "${LINK_CONFLICT_POLICY:=prompt}"

overwrite_all=false
backup_all=false
skip_all=false

link_ignored () {
  local name=$1 ignore
  for ignore in "${LINK_IGNORE[@]}"; do
    if [ "$name" = "$ignore" ]; then
      return 0
    fi
  done
  return 1
}

# Echo the physical path of $1, following repo symlinks, so links created in
# $HOME point at real files instead of forming two-hop chains. readlink -f is
# unavailable on older macOS, hence the manual walk.
link_physical () {
  local src=$1 dir base target hops=0

  if [ -d "$src" ]; then
    (cd "$src" && pwd -P)
    return
  fi

  dir="$(cd "$(dirname "$src")" && pwd -P)"
  base="$(basename "$src")"

  while [ -L "$dir/$base" ] && [ "$hops" -lt 32 ]; do
    target="$(readlink "$dir/$base")"
    case "$target" in
      /*) dir="$(cd "$(dirname "$target")" && pwd -P)" ;;
      *)  dir="$(cd "$dir" && cd "$(dirname "$target")" && pwd -P)" ;;
    esac
    base="$(basename "$target")"
    hops=$((hops + 1))
  done

  printf '%s/%s\n' "$dir" "$base"
}

link_file () {
  local src=$1 dst=$2
  local overwrite= backup= skip= action=

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      skip=true
    elif [ "$overwrite_all" = false ] && [ "$backup_all" = false ] \
         && [ "$skip_all" = false ]; then
      case "$LINK_CONFLICT_POLICY" in
        skip)      skip=true ;;
        overwrite) overwrite=true ;;
        backup)    backup=true ;;
        *)
          user "File already exists: $dst ($(basename "$src")), what do you want to do?
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
          read -r -n 1 action
          case "$action" in
            o) overwrite=true ;;
            O) overwrite_all=true ;;
            b) backup=true ;;
            B) backup_all=true ;;
            s) skip=true ;;
            S) skip_all=true ;;
          esac
          ;;
      esac
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" = true ]; then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" = true ]; then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" = true ]; then
      return 0
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  success "linked $dst to $src"
}

# Walk a *.symlink directory. Intermediate directories are created real so the
# target can be co-owned with the tool that writes there; only leaves are
# linked.
link_tree () {
  local src_dir=$1 dst_dir=$2 entry name

  mkdir -p "$dst_dir"

  for entry in "$src_dir"/* "$src_dir"/.[!.]*; do
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
      continue
    fi

    name="$(basename "$entry")"
    if link_ignored "$name"; then
      continue
    fi

    if [ -d "$entry" ] && [ ! -L "$entry" ]; then
      link_tree "$entry" "$dst_dir/$name"
    else
      link_file "$(link_physical "$entry")" "$dst_dir/$name"
    fi
  done
}

install_dotfiles () {
  info 'installing dotfiles'

  overwrite_all=false
  backup_all=false
  skip_all=false

  local src name dst
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    dst="$HOME/.${name%.symlink}"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
      link_tree "$src" "$dst"
    else
      link_file "$(link_physical "$src")" "$dst"
    fi
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' \
    -not -path '*/.git/*' -print0)
}
