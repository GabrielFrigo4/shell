### ================================
### KORN SHELL CONFIGURATION
### ================================

### --------------------------------
### COMPATIBILITY AND PARSING
### --------------------------------
unset IFS

### --------------------------------
### LINE EDITING & HISTORY
### --------------------------------
set -o emacs 2> "/dev/null" || true

export HISTFILE="${HOME}/.ksh_history"
export HISTSIZE=50000
[ -f "${HISTFILE}" ] || { : > "${HISTFILE}" && chmod 0600 "${HISTFILE}"; } 2> "/dev/null" || true

### --------------------------------
### INTERACTION & SAFETY
### --------------------------------
set -o noclobber 2> "/dev/null" || true

### --------------------------------
### STANDARD ALIASES
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias history='fc -l'
