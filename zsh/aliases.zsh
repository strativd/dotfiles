### SHORTCUTS #######################

alias cddl="cd ~/Downloads"
alias cddt="cd ~/Desktop"
alias cdc="cd ~/Code"
alias g="git "

alias habits="code ~/Code/habits/building-habits/backend && code ~/Code/habits/building-habits/frontend"

### FILES ###########################

# Easier navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# npm
alias npmlg="npm list -g --depth=0"
alias npmll="npm list --depth=0"

# List all files colorized in long format
alias l="ls -lF ${colorflag}"

# List all files colorized in long format, including dot files
alias la="ls -laF ${colorflag}"

# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always use color output for `ls`
alias ls="command ls ${colorflag}"

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

### UTILITIES #######################

# Print out file contents in terminal
alias printout='less -FX'

# Trim new lines and copy to clipboard
alias cpy="tr -d '\n' | pbcopy"

# Combine pdf files
# EX: `pdfcat doc1.pdf doc2.pdf doc3.pdf > combined.pdf`
alias pdfcat='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=-'

# Merge PDF files
# EX: `mergepdf -o output.pdf input{1,2,3}.pdf`
alias pdfmerge='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'

# Show/hide hidden files in Finder
alias show.="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide.="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Show/hide all desktop icons (useful when presenting)
alias showdt="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
alias hidedt="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

### SERVICES ########################

alias reload!='. ~/.zshrc'

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update!='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g'

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Get week number
alias week='date +%V'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Print each PATH entry on a separate line
alias paths='echo -e ${PATH//:/\\n}'

killit() {
  if [ -z "$1" ]; then
    echo "Not killin' it... No argument supplied"
  else
    kill -9 $(lsof -i tcp:$1 -t)
  fi
}
