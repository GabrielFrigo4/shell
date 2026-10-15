### ================================
### KORN SHELL CONFIGURATION
### ================================

### --------------------------------
### Compatibility & Parsing
### --------------------------------
unset IFS

### --------------------------------
### Line Editing & History
### --------------------------------
set -o emacs 2> "/dev/null" || true

export HISTFILE="${HOME}/.ksh_history"
export HISTSIZE=50000
[ -f "${HISTFILE}" ] || { : > "${HISTFILE}" && chmod 0600 "${HISTFILE}"; } 2> "/dev/null"

### --------------------------------
### Interaction & Safety
### --------------------------------
set -o noclobber 2> "/dev/null" || true

### --------------------------------
### Standard Aliases
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias history='fc -l'
