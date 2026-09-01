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
alias history='fc -l'

