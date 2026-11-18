### ================================
### POSIX SH CONFIGURATION
### ================================

### --------------------------------
### COMPATIBILITY AND PARSING
### --------------------------------
IFS=$' \t\n'

### --------------------------------
### LINE EDITING
### --------------------------------
set -o emacs 2> "/dev/null" || true

export HISTFILE="${HOME}/.sh_history"
export HISTSIZE=50000
[ -f "${HISTFILE}" ] || { : >| "${HISTFILE}" && chmod 0600 "${HISTFILE}"; } 2> "/dev/null" || true

### --------------------------------
### INTERACTION & SAFETY
### --------------------------------
set -C

### --------------------------------
### STANDARD ALIASES
### --------------------------------
alias h > "/dev/null" 2>&1 || alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias history='fc -l'
