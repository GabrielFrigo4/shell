### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Line Editing
### --------------------------------
set -o emacs 2> "/dev/null" || true

### --------------------------------
### History
### --------------------------------
export HISTSIZE=10000
export HISTFILE="${HOME}/.sh_history"

### --------------------------------
### Standard Aliases
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias g='grep -Ei'
alias history='fc -l'

### --------------------------------
### Navigation
### --------------------------------
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

### --------------------------------
### Directory Listing
### --------------------------------
alias ls='ls --color=auto'
alias ll='ls -laF --color=auto'
alias l='ls -l --color=auto'
