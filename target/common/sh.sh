### ================================
### POSIX SH CONFIGURATION
### ================================

### --------------------------------
### Compatibility & Parsing
### --------------------------------
unset IFS

### --------------------------------
### Line Editing
### --------------------------------
set -o emacs 2> "/dev/null" || true

### --------------------------------
### Shell History
### --------------------------------
export HISTFILE="${HOME}/.sh_history"
export HISTSIZE=10000

### --------------------------------
### Interaction & Safety
### --------------------------------
set -C

### --------------------------------
### Standard Aliases
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias history='fc -l'
