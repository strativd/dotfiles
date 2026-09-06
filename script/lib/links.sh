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
#   Rule 3  nested *.symlink entry  ->  linked whole, suffix stripped, no
#                                       recursion; a nested symlink resolving
#                                       to a directory is also linked whole
#   .link-children sentinel         ->  link each child of this directory
#                                       whole; the directory itself stays real
#   .local overlay directory        ->  merge children into the parent dest;
#                                       the overlay itself is never created
#   Rule 4  nested NAME.link file   ->  symlink NAME to the path named on the
#                                       first line of the file; $HOME and
#                                       $DOTFILES are expanded
#
# Only the link root gains a leading dot; nested paths map verbatim.

LINK_IGNORE=(".DS_Store" ".git" ".link-children" ".local")
: "${LINK_CONFLICT_POLICY:=prompt}"

LINK_MANAGED_DIRS=()
LINK_DRIFT=()

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

  if [ -L "$dst" ] && [ ! -e "$dst" ]; then
    case "$(readlink "$dst")" in
      "$DOTFILES_ROOT"/*)
        rm "$dst"
        success "removed dangling $dst"
        ;;
    esac
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
      LINK_DRIFT+=("$dst")
    fi
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

# Rule 4: NAME.link is a regular file whose first line is the link target.
# Rules 1-3 can only name paths inside the repo; this reaches $HOME paths (for
# a runtime directory shared between tools) and expresses renames.
link_declared () {
  local decl=$1 dst=$2 target=

  IFS= read -r target < "$decl" || true
  target="${target%$'\r'}"

  case "$target" in
    '$HOME'/*)
      target="$HOME/${target#\$HOME/}"
      ;;
    '$DOTFILES'/*)
      target="$DOTFILES_ROOT/${target#\$DOTFILES/}"
      ;;
    /*)
      ;;
    *)
      fail "$decl: target must be absolute or start with \$HOME or \$DOTFILES (got '$target')"
      ;;
  esac

  link_file "$target" "$dst"
}

# A link is ours if it resolves under $DOTFILES_ROOT. Remove ours when the
# referent is gone; leave everything else alone.
prune_links () {
  local dst_dir=$1 link resolved

  if [ ! -d "$dst_dir" ]; then
    return 0
  fi

  for link in "$dst_dir"/* "$dst_dir"/.[!.]*; do
    if [ ! -L "$link" ]; then
      continue
    fi
    resolved="$(readlink "$link")"
    case "$resolved" in
      "$DOTFILES_ROOT"/*) ;;
      *) continue ;;
    esac
    if [ ! -e "$link" ]; then
      rm "$link"
      success "pruned stale symlink $link"
    fi
  done
}

link_report_drift () {
  local path
  if [ "${#LINK_DRIFT[@]}" -eq 0 ]; then
    return 0
  fi
  info 'managed paths that are no longer a symlink (config was rewritten in place):'
  for path in "${LINK_DRIFT[@]}"; do
    info "  $path"
  done
}

# Walk a *.symlink directory. Intermediate directories are created real so the
# target can be co-owned with the tool that writes there; only leaves are
# linked.
link_children_whole () {
  local src_dir=$1 dst_dir=$2 entry name

  for entry in "$src_dir"/* "$src_dir"/.[!.]*; do
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
      continue
    fi
    name="$(basename "$entry")"
    if link_ignored "$name"; then
      continue
    fi
    case "$name" in
      *.link)
        if [ -f "$entry" ] && [ ! -L "$entry" ]; then
          link_declared "$entry" "$dst_dir/${name%.link}"
          continue
        fi
        ;;
    esac
    link_file "$(link_physical "$entry")" "$dst_dir/$name"
  done
}

# Merge $src_dir/.local into $dst_dir. The overlay directory itself is never
# created at the target. Inherits the parent's .link-children vs recurse mode.
link_local_overlay () {
  local src_dir=$1 dst_dir=$2
  local overlay="$src_dir/.local"

  if [ ! -d "$overlay" ] || [ -L "$overlay" ]; then
    return 0
  fi

  if [ -f "$src_dir/.link-children" ]; then
    link_children_whole "$overlay" "$dst_dir"
  else
    link_tree "$overlay" "$dst_dir"
  fi
}

link_tree () {
  local src_dir=$1 dst_dir=$2 entry name

  mkdir -p "$dst_dir"

  LINK_MANAGED_DIRS+=("$dst_dir")

  if [ -f "$src_dir/.link-children" ]; then
    link_children_whole "$src_dir" "$dst_dir"
    link_local_overlay "$src_dir" "$dst_dir"
    return 0
  fi

  for entry in "$src_dir"/* "$src_dir"/.[!.]*; do
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
      continue
    fi

    name="$(basename "$entry")"
    if link_ignored "$name"; then
      continue
    fi

    case "$name" in
      *.link)
        if [ -f "$entry" ] && [ ! -L "$entry" ]; then
          link_declared "$entry" "$dst_dir/${name%.link}"
          continue
        fi
        ;;
      *.symlink)
        link_file "$(link_physical "$entry")" "$dst_dir/${name%.symlink}"
        continue
        ;;
    esac

    if [ -d "$entry" ] && [ ! -L "$entry" ]; then
      link_tree "$entry" "$dst_dir/$name"
    else
      link_file "$(link_physical "$entry")" "$dst_dir/$name"
    fi
  done

  link_local_overlay "$src_dir" "$dst_dir"
}

install_dotfiles () {
  info 'installing dotfiles'

  overwrite_all=false
  backup_all=false
  skip_all=false
  LINK_MANAGED_DIRS=()
  LINK_DRIFT=()

  local src name dst dir
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

  if [ "${#LINK_MANAGED_DIRS[@]}" -gt 0 ]; then
    for dir in "${LINK_MANAGED_DIRS[@]}"; do
      prune_links "$dir"
    done
  fi

  link_report_drift
}
