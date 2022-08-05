alias figod="code ~/Code/figment-networks/datahub"
alias figow="code ~/Code/figment-networks/datahub-web-app"
alias figok="code ~/Code/figment-networks/datahub-kong"
alias figo="figod && figow"
alias cdd="cd ~/Code/figment-networks/datahub"
alias cdw="cd ~/Code/figment-networks/datahub-web-app"

### datahub
alias dc="docker-compose "
alias figdoc="docker-compose up postgres redis"
alias figdown="docker-compose down"
alias figdb="bin/rake db:setup"
alias figdrop="bin/rake db:drop"
alias figdin="bundle && rake db:migrate && yarn install"
alias figdup="bundle exec foreman start"

### datahub-web-app
alias figgql="yarn schema"
alias figgqlw="yarn schema:watch"
alias figwin="yarn install && yarn schema"
alias figwup="yarn dev"
# npm
alias npmlogin="npm login --scope=@figment-networks --registry=https://npm.pkg.github.com"

BACKEND_ORIGIN="https://github.com/figment-networks/datahub.git"
FRONTEND_ORIGIN="https://github.com/figment-networks/datahub-web-app.git"

log () { echo "\n [ 🕸🕸🕸 ] $1 \n"}

git_origin () {
  echo $(git remote get-url origin)
}

install_deps () {
  log "Installing..."

  ORIGIN=$(git_origin)
  if [ ! "$ORIGIN" ] ; then
    log "Oops. No origin was found. Is this a git repo?"
    exit
  fi;
  if [[ $ORIGIN == $FRONTEND_ORIGIN ]] ; then
    figwin
  fi;
  if [[ $ORIGIN == $BACKEND_ORIGIN ]] ; then
    figdin
  fi;
}

start_up () {
  log "Starting up!"

  ORIGIN=$(git_origin)
  if [ ! "$ORIGIN" ] ; then
    log "Oops. No origin was found. Is this a git repo?"
  fi;
  if [[ $ORIGIN == $FRONTEND_ORIGIN ]] ; then
    figwup
  fi;
  if [[ $ORIGIN == $BACKEND_ORIGIN ]] ; then
    rails s
  fi;
}

kill_port () {
  log "Killin' it!"

  ORIGIN=$(git_origin)
  if [ ! "$ORIGIN" ] ; then
    log "Oops. No origin was found. Is this a git repo?"
  fi;
  if [[ $ORIGIN == $FRONTEND_ORIGIN ]] ; then
    killit 8000
  fi;
  if [[ $ORIGIN == $BACKEND_ORIGIN ]] ; then
    killit 3050
  fi;
}

### ✨ cross-repo scripts ✨
# install
alias figin=install_deps
# start
alias figup=start_up
# kill
alias figkill=kill_port
