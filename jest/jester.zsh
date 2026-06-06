# Jester: running jest testing library
#
#     "pnpm jest <optional/file/path>"
# -c  "pnpm jest --coverage --coverageDirectory='coverage' "
# -o  "open coverage/index.html"
#
# https://stackoverflow.com/a/45598695/6586407

function jester {
  function log() {
    echo "\n [ 🤡🤌 ] $1 \n"
  }

  function logGrey() {
    echo -e "\n [ 🤡🤌 ] \033[1;30m $1 \033[0m \n"
  }

  log "JESTER..."

  DEFAULT_DIR="coverage"

  while test $# -gt 0; do
    case "$1" in
    -o) # open test coverage file within directory
      shift
      DIR_NAME=${1:-$DEFAULT_DIR}
      logGrey "open $DIR_NAME/index.html"
      $(open $DIR_NAME/index.html)
      return 1
      ;;
    -c) # run test --coverage within directory
      shift
      DIR_NAME=${1:-$DEFAULT_DIR}
      logGrey "pnpm jest --coverage --coverageDirectory='$DIR_NAME'"
      $(pnpm jest --coverage --coverageDirectory='$DIR_NAME')
      return 1
      ;;
    *)
      break
      ;;
    esac
  done

  # no flags? run tests (on file if it's provided)
  logGrey "pnpm jest $1"
  pnpm jest $1
}
