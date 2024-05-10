# delete all node_modules folders within current project
alias rmnode="find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +"

# pnpm list
alias pnlg="pnpm list -g --depth=0"
alias pnll="pnpm list --depth=0"
