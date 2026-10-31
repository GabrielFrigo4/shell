### ================================
### POSIX SH CONFIGURATION
### ================================

### --------------------------------
### Compatibility & Parsing
### --------------------------------
unset IFS

### --------------------------------
### LINE EDITING
### --------------------------------
set -o emacs 2> "/dev/null" || true

export HISTFILE="${HOME}/.sh_history"
export HISTSIZE=50000
[ -f "${HISTFILE}" ] || { : > "${HISTFILE}" && chmod 0600 "${HISTFILE}"; } 2> "/dev/null"

### --------------------------------
### INTERACTION & SAFETY
### --------------------------------
set -C

### --------------------------------
### STANDARD ALIASES
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias history='fc -l'
